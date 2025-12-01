local function thrust(isLinearAcceleration, airDensity, propDiameter, propPitch, motorKv, batteryCells, throttle, inflowVelocity)
    local force
    if not isLinearAcceleration then
        local a = airDensity * (3.14 * ((0.0254 * propDiameter) ^ 2) / 4) * ((propDiameter / (3.29547 * (propPitch + 0.5))) ^ 1.5) * 1.5 * 4
        local maxRPM = math.min(motorKv * batteryCells * 3.7 * (5.4 / (propDiameter ^ 1.1)), motorKv * batteryCells * 3.7)
        local rpm = throttle * maxRPM
        local maxVe = maxRPM * 0.0254 * (propPitch + 0.5) / 60
        local Ve = rpm * 0.0254 * (propPitch + 0.5) / 60
        local ic = math.max(0.2, (maxVe - math.abs(inflowVelocity)) / maxVe)
        force = a * (math.abs(Ve) * Ve) * ic
    else
        force = throttle * motorKv / 30
    end
    return force
end

local function airDragForceFn(density, velocity, coefficient, area, minAreaCoeff, inflowCoefficient)
    local areaCoeff = inflowCoefficient + minAreaCoeff * (1 - inflowCoefficient)
    return velocity:clone():normalize():scale(-0.5 * density * velocity:length() ^ 2 * (2.5 * coefficient) * (area * areaCoeff))
end

local function vectorAngle(vec1, vec2)
    local angle = math.acos(vec1:dot(vec2) / (vec1:length() * vec2:length()))
    return angle == angle and angle or 0
end

local function excludeVector(v, vectorToExclude)
    return v - vectorToExclude * v:dot(vectorToExclude)
end

local function getClosestCar(toPosition)
    local closestCarIndex = 0
    local minDistance = 1e9
    for i = 0, ac.getSim().carsCount - 1 do
        local car = ac.getCar(i)
        if car and car.isActive then
            local distanceToPosition = (car.position-toPosition):length()
            if distanceToPosition < minDistance then
                closestCarIndex = i
                minDistance = distanceToPosition
            end
        end
    end
    return ac.getCar(closestCarIndex)
end

local M = {
    camera = nil, ---@type ac.GrabbedCamera
    previousCameraMode = nil,
    active = false,
    sleep = false,
    position = vec3(),
    rotation = { look = vec3(), up = vec3() },
    velocity = vec3(),
    savedState = nil,
}

function M:toggle()
    if not self.active then
        self.camera, self.errorMessage = ac.grabCamera("Fpv Drone")
        if not self.camera then return end

        self.position = ac.getCameraPosition()
        local cameraAngleQuat = quat.fromAngleAxis(-math.rad(Settings.cameraAngle), ac.getCameraSide())
        self.rotation.look = ac.getCameraForward():rotate(cameraAngleQuat)
        self.rotation.up = ac.getCameraUp():rotate(cameraAngleQuat)
        self.velocity = getClosestCar(self.position).velocity:clone():add(vec3(0, 10, 0))

        -- couldnt find a way to change camera near clip distance,
        -- so change camera mode to one with near clip distance I need.
        -- also shadows look better in "drivable" camera mode
        self.previousCameraMode = ac.getSim().cameraMode
        ac.setCurrentCamera(ac.CameraMode.Drivable)

        self.active = true
        self.sleep = false
        self.lastPosition = nil
    else
        if self.previousCameraMode then ac.setCurrentCamera(self.previousCameraMode) end
        self.active = false
        self.camera:dispose()
    end
end

function M:toggleSleep()
    self.sleep = not self.sleep
end

function M:update(dt)
    Input:update()
    if Input.toggleSleepButton.pressed then self:toggleSleep() end
    if Input.toggleDroneButton.pressed then self:toggle() end

    if not self.active or self.sleep then return end

    dt = dt * Settings.time

    local sideVector = math.cross(self.rotation.look, self.rotation.up)
    local lookVector = self.rotation.look
    local upVector = self.rotation.up

    local inflowCoefficient = 1 - math.sin(vectorAngle(upVector:clone(), self.velocity:clone()))
    local inflowVelocity = self.velocity:length() * inflowCoefficient

    local thrustForce = upVector:clone():scale(thrust(Settings.linearAcceleration, Settings.airDensity,
        Settings.propDiameter, Settings.propPitch, Settings.motorKv, Settings.batteryCells,
        Settings.mode3d and Input.throttle or (Input.throttle + 1) / 2, inflowVelocity))

    local airDragForce = vec3()
    if not Input.disableAirDragAndFrictionButton.down then
        airDragForce = airDragForceFn(1.2 * Settings.airDensity, self.velocity, Settings.airDrag,
            Settings.droneSurfaceArea, Settings.minimalSurfaceAreaCoefficient, inflowCoefficient)
    end

    local force = thrustForce + airDragForce
    local acceleration = force / Settings.droneMass + vec3(0, -9.8 * Settings.gravity, 0)
    self.velocity:addScaled(acceleration, dt)

    local positionDt = dt
    local closestCar = getClosestCar(self.position)
    if self.lastClosestCarTimestamp and not closestCar.extrapolatedMovement then
        -- sync drone position updates with car position updates so there is no car jitter effect
        positionDt = (closestCar.timestamp-self.lastClosestCarTimestamp)/1000
    end
    self.lastClosestCarTimestamp = closestCar.timestamp

    self.position:addScaled(self.velocity, positionDt)

    if self.position.y < Settings.groundLevel + 0.1 then
        self.position.y = Settings.groundLevel + 0.1
        self.velocity.y = 0.01
    end

    self:collision()

    local rateFunction = self.rateFunctions[Settings.rates.type]
    local rotation = {
        roll = math.rad(rateFunction(Input.roll, Settings.rates.roll)) * dt,
        pitch = math.rad(rateFunction(Input.pitch, Settings.rates.pitch)) * dt,
        yaw = math.rad(rateFunction(Input.yaw, Settings.rates.yaw)) * dt
    }

    local rotationQuat =
        quat.fromAngleAxis(-rotation.pitch, sideVector) *
        quat.fromAngleAxis(rotation.roll, lookVector) *
        quat.fromAngleAxis(-rotation.yaw, upVector)

    self.rotation.look:rotate(rotationQuat):normalize()
    -- this is to make sure look and up are 90 degrees apart
    sideVector:rotate(rotationQuat):normalize()
    self.rotation.up = self.rotation.look:clone():rotate(quat.fromAngleAxis(math.rad(90), sideVector))

    local cameraPosition = self.position + self.rotation.up * 0.1
    local cameraAngleQuat = quat.fromAngleAxis(math.rad(Settings.cameraAngle), sideVector)

    -- this fixes the issue of car models being low quality when far away, actual camera control is below
    self.camera.transform.position = cameraPosition

    -- ac.GrabbedCamera has a delay when updating position from CSP v0.1.80-preview115 to at least v0.2.11
    -- There needs to be no delay for jitter compensation to work, so use these functions instead.
    -- If fixed GrabbedCamera approach might be better for multiple mods controlling camera, and for the currently removed "Active DOF" feature
    ac.setCameraPosition(cameraPosition)
    ac.setCameraDirection(self.rotation.look:clone():rotate(cameraAngleQuat), self.rotation.up:clone():rotate(cameraAngleQuat))
    ac.setCameraFOV(Settings.cameraFov)

    if Input.savePositionButton.pressed then
        self.savedState = {
            position = self.position:clone(),
            look = self.rotation.look:clone(),
            up = self.rotation.up:clone(),
            velocity = self.velocity:clone(),
        }
    end
    if Input.teleportToPositionButton.pressed and self.savedState then
        self.position = self.savedState.position:clone()
        self.rotation.look = self.savedState.look:clone()
        self.rotation.up = self.savedState.up:clone()
        self.velocity = self.savedState.velocity:clone()
        self.lastPosition = nil
    end
end

local trackRoot = ac.findNodes("trackRoot:yes")
local hitMesh = ac.emptySceneReference()

local function collisionRaycast(fromPos, toPos, scene)
    local vec, point, normal = toPos-fromPos, vec3(), vec3()
    local distance = scene:raycast(render.createRay(fromPos, vec, vec:length()), hitMesh, point, normal, nil, 0)
    -- with backface culling disabled raycast still returns distance of the hit when it hits a backface.
    -- it changes the point vector reference only when the ray hits a front face, so use that
    local hit = point:length() ~= 0

    if hit then
        local meshTransform = hitMesh:getWorldTransformationRaw()
        point = fromPos+vec:clone():normalize():scale(distance)
        normal = mat4x4.translation(normal):mulSelf(mat4x4.look(vec3(), -meshTransform.look, meshTransform.up):inverseSelf()).position

        -- hack together a normal because normal from the raycast function is inaccurate
        local v0 = point:clone():addScaled(normal, 0.05)
        local r1 = point:clone():sub(v0):rotate(quat.fromAngleAxis(math.pi/4, math.cross(normal, vec3(0,1,0)):normalize())):normalize()
        local r2 = r1:clone():rotate(quat.fromAngleAxis(math.pi/2, normal))
        local d1 = hitMesh:raycast(render.createRay(v0, r1, 0.2))
        local d2 = hitMesh:raycast(render.createRay(v0, r2, 0.2))
        if d1~=-1 and d2~=-1 then
            local p1 = v0:clone():addScaled(r1, d1)
            local p2 = v0:clone():addScaled(r2, d2)
            normal = math.cross(point:clone():sub(p1), point:clone():sub(p2)):normalize()
        end
    end

    return hit, point, normal
end

function M:collision()
    if self.lastPosition and Settings.collision and not Input.disableCollisionButton.down then
        for i=1,2 do
            local hit, point, normal = collisionRaycast(self.lastPosition, self.position, trackRoot)

            if not hit then
                break
            else
                self.velocity = self.velocity - normal * self.velocity:dot(normal) * (1+Settings.bounciness)

                if not Input.disableAirDragAndFrictionButton.down then
                    self.velocity = self.velocity - excludeVector(self.velocity:clone():normalize(), normal)
                        * math.min(1, self.velocity:length() * Settings.groundFriction * 0.5)
                end

                if i == 1 then
                    self.position = point + excludeVector(self.position - point, normal) + normal/500
                else
                    self.position = self.lastPosition + (point-self.lastPosition) * 0.2
                end
            end
        end
    end
    self.lastPosition = self.position:clone()
end

-- https://github.com/betaflight/betaflight/blob/master/src/main/fc/rc.c
M.rateFunctions = {
    betaflight = function(input, parameters)
        local inputAbs = math.abs(input)
        local rcCommandf = input * inputAbs^3 * parameters.expo + input * (1 - parameters.expo);
        local rcRate = parameters.rate
        if rcRate > 2 then
            rcRate = rcRate + 14.54 * (rcRate - 2)
        end
        local rcSuperfactor = 1 / (math.clamp(1 - (inputAbs * parameters.super), 0.01, 1))
        local angleRate = 200 * rcRate * rcCommandf * rcSuperfactor
        return angleRate
    end,
    actual = function(input, parameters)
        local inputAbs = math.abs(input)
        local expo = inputAbs * (input^5 * parameters.expo + input * (1 - parameters.expo))
        local stickMovement = math.max(0, parameters.maxRate - parameters.centerSensitivity);
        local angleRate = input * parameters.centerSensitivity + stickMovement * expo;
        return angleRate
    end,
    kiss = function(input, parameters)
        local inputAbs = math.abs(input)
        local kissRpyUseRates = 1 / math.clamp(1 - (inputAbs * parameters.super), 0.01, 1)
        local kissRcCommandf = (input^3 * parameters.curve + input * (1 - parameters.curve)) * (parameters.rate/10)
        local kissAngle = math.clamp(2000 * kissRpyUseRates * kissRcCommandf, -1998, 1998)
        return kissAngle
    end,
}

return M
