local function betaflightRates(x, a, b, c) -- a-rate, b-super, c-expo
    local p = 1 / (1 - (math.abs(x) * b))
    local q = (x ^ 4 * c) + math.abs(x) * (1 - c)
    local r = 200 * q * a
    local t = r * p * (x < 0 and -1 or 1)
    return t
end

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

Drone = {
    previousCameraMode = nil,
    active = false,
    sleep = false,
    position = vec3(),
    rotation = { look = vec3(), up = vec3() },
    velocity = vec3(),
    savedState = nil,
    previousJitterClosestCar = nil,
    jitter = vec3(),
}

function Drone:toggle()
    if not self.active then
        self.position = ac.getCameraPosition()
        local cameraAngleQuat = quat.fromAngleAxis(-math.rad(Settings.cameraAngle), ac.getCameraSide())
        self.rotation.look = ac.getCameraForward():rotate(cameraAngleQuat)
        self.rotation.up = ac.getCameraUp():rotate(cameraAngleQuat)
        self.velocity = getClosestCar(self.position).velocity:clone():add(vec3(0, 10, 0))
        self.jitter = vec3()

        -- couldnt find a way to change camera near clip distance,
        -- so change camera mode to one with near clip distance I need.
        -- also shadows look better in "drivable" camera mode
        self.previousCameraMode = ac.getSim().cameraMode
        ac.setCurrentCamera(ac.CameraMode.Drivable)

        self.active = true
        self.sleep = false
    else
        if self.previousCameraMode then ac.setCurrentCamera(self.previousCameraMode) end
        self.active = false
    end
end

function Drone:toggleSleep()
    self.sleep = not self.sleep
end

function Drone:physics(dt)
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
    if not ButtonStates.disableAirDragButton.down then
        airDragForce = airDragForceFn(1.2 * Settings.airDensity, self.velocity, Settings.airDrag,
            Settings.droneSurfaceArea, Settings.minimalSurfaceAreaCoefficient, inflowCoefficient)
    end

    local force = thrustForce + airDragForce
    local acceleration = force / Settings.droneMass + vec3(0, -9.8 * Settings.gravity, 0)
    self.velocity:addScaled(acceleration, dt)

    self.position:addScaled(self.velocity, dt)

    if self.position.y < Settings.groundLevel + 0.1 then
        self.position.y = Settings.groundLevel + 0.1
        self.velocity.y = 0.01
    end

    local rotation = {
        roll = math.rad(betaflightRates(Input.roll, Settings.rollRate, Settings.rollSuper, Settings.rollExpo)) * dt,
        pitch = math.rad(betaflightRates(Input.pitch, Settings.pitchRate, Settings.pitchSuper, Settings.pitchExpo)) * dt,
        yaw = math.rad(betaflightRates(Input.yaw, Settings.yawRate, Settings.yawSuper, Settings.yawExpo)) * dt
    }

    local rotationQuat =
        quat.fromAngleAxis(-rotation.pitch, sideVector) *
        quat.fromAngleAxis(rotation.roll, lookVector) *
        quat.fromAngleAxis(-rotation.yaw, upVector)

    self.rotation.look:rotate(rotationQuat):normalize()
    -- this is to make sure look and up are 90 degrees apart
    sideVector:rotate(rotationQuat):normalize()
    self.rotation.up = self.rotation.look:clone():rotate(quat.fromAngleAxis(90, sideVector))

    local cameraPosition = self.position:clone()
    local cameraAngleQuat = quat.fromAngleAxis(math.rad(Settings.cameraAngle), sideVector)

    -- "Jitter" explanation:
    -- Car positions are updated every physics tick, but the drone is moved every frame.
    -- This creates a jitter effect, especially noticeable when flying close to cars.
    -- Jitter compensation jitters the drone with the car so the effect is not visible.
    if Settings.jitterCompensation and not ac.isInReplayMode() then
        self:updateJitter()
        cameraPosition:add(self.jitter)
    else
        self.jitter, self.previousJitterClosestCar = vec3(), nil
    end

    -- ac.GrabbedCamera has a delay when updating position from CSP v0.1.80-preview115 to at least v0.2.11
    -- There needs to be no delay for jitter compensation to work, so use these functions instead.
    -- If fixed GrabbedCamera approach might be better for multiple mods controlling camera, and for the currently removed "Active DOF" feature
    ac.setCameraPosition(cameraPosition)
    ac.setCameraDirection(self.rotation.look:clone():rotate(cameraAngleQuat), self.rotation.up:clone():rotate(cameraAngleQuat))
    ac.setCameraFOV(Settings.cameraFov)

    if self.jitter:length() > 0.1 then self.jitter:scale(1-0.1/self.jitter:length()*dt) end

    if ButtonStates.savePositionButton.pressed then
        self.savedState = {
            position = self.position:clone(),
            look = self.rotation.look:clone(),
            up = self.rotation.up:clone(),
            velocity = self.velocity:clone(),
        }
    end
    if ButtonStates.teleportToPositionButton.pressed and self.savedState then
        self.position = self.savedState.position:clone()
        self.rotation.look = self.savedState.look:clone()
        self.rotation.up = self.savedState.up:clone()
        self.velocity = self.savedState.velocity:clone()
    end
end

function Drone:updateJitter()
    local closestCar = getClosestCar(self.position)

    if closestCar and self.previousJitterClosestCar and closestCar.index == self.previousJitterClosestCar.index and
        (closestCar.position-self.position):length() < Settings.maxDistance then

        local posDiff = closestCar.position - self.previousJitterClosestCar.position
        local velocity = posDiff / ((closestCar.timestamp-self.previousJitterClosestCar.timestamp) / 1000)

        if velocity ~= velocity then velocity = vec3() end

        if posDiff:length() < Settings.maxCompensation then
            self.jitter:add(posDiff - velocity * ac.getSim().dt )
        end
    end

    self.previousJitterClosestCar = {
        timestamp = closestCar.timestamp,
        position = closestCar.position:clone(),
        index = closestCar.index
    }
end
