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
    return math.acos(vec1:clone():dot(vec2:clone()) / (vec1:clone():length() * vec2:clone():length()))
end

Drone = {
    previousCameraMode = nil,
    changingCameraMode = false,
    active = false,
    camera = nil,
    transform = mat4x4.identity(),
    velocity = vec3(),
    sleepTransform = mat4x4.identity(),
    savedTransform = mat4x4.identity(),
    savedVelocity = vec3(),
    prevClosestCar = nil,
    jitter = vec3(),
    jitters = vec3(),
}

function Drone:toggle()
    if not self.active then
        if not self.changingCameraMode then -- sets near clip to a reasonable value for the drone. waits for 1 frame
            self.previousCameraMode = ac.getSim().cameraMode
            if ac.getSim().cameraClipNear > 0.1 then
                ac.setCurrentCamera(ac.CameraMode.Cockpit)
                self.changingCameraMode = true
                return
            end
        else
            self.changingCameraMode = false
        end

        local error
        self.camera, error = ac.grabCamera("Drone")
        if error then
            print(error)
            return
        end
        self.transform = self.camera.transform:clone()
        self.velocity = GetClosestCar().velocity:clone():add(vec3(0.01, 10, 0.01))
        self.jitters = vec3()
        self.active = true
    else
        if self.camera and self.camera:active() then self.camera:dispose() end
        if self.previousCameraMode then ac.setCurrentCamera(self.previousCameraMode) end
        self.active = false
    end
end

function Drone:toggleSleep()
    if self.active and self.camera then
        if self.camera:active() then
            self.sleepTransform = self.transform:clone()
            self.camera:dispose()
        else
            self.camera = ac.grabCamera("Drone")
            self.transform = self.sleepTransform:clone()
        end
    end
end

function Drone:toggleActiveDof()
    Settings:set("Stuff", "activeDof", not Settings.activeDof)
    if not Settings.activeDof and self.camera then
        self.camera.dofDistance = self.camera.dofDistanceOriginal
        self.camera.dofFactor = self.camera.dofFactorOriginal
    end
end

function Drone:physics(dt)
    dt = dt * Settings.time

    local sideVector = self.transform.side:clone()
    local lookVector = self.transform.look:clone():rotate(quat.fromAngleAxis(-math.rad(Settings.cameraAngle), sideVector))
    local upVector = self.transform.up:clone():rotate(quat.fromAngleAxis(-math.rad(Settings.cameraAngle), sideVector))

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

    if Settings.jitterCompensation then
        self.jitter, self.prevClosestCar = Jitter(self.prevClosestCar)
        self.jitters:add(self.jitter)
    else
        self.jitter, self.prevClosestCar = vec3(), nil
    end

    self.transform.position:addScaled(self.velocity, dt)

    if ButtonStates.savePositionButton.pressed then
        self.savedTransform = self.transform:clone()
        self.savedVelocity = self.velocity:clone()
    end
    if ButtonStates.teleportToPositionButton.pressed then
        self.transform = self.savedTransform:clone()
        self.velocity = self.savedVelocity:clone()
    end

    if self.transform.position.y < Settings.groundLevel + 0.1 then
        self.transform.position.y = Settings.groundLevel + 0.1
        self.velocity.y = 0.01
    end

    local rotation = {
        roll = math.rad(betaflightRates(Input.roll, Settings.rollRate, Settings.rollSuper, Settings.rollExpo)) * dt,
        pitch = math.rad(betaflightRates(Input.pitch, Settings.pitchRate, Settings.pitchSuper, Settings.pitchExpo)) * dt,
        yaw = math.rad(betaflightRates(Input.yaw, Settings.yawRate, Settings.yawSuper, Settings.yawExpo)) * dt
    }

    self.transform:mulSelf(mat4x4.identity()
        :mulSelf(mat4x4.translation(self.transform.position*-1))
        :mulSelf(mat4x4.rotation(-rotation.pitch , sideVector))
        :mulSelf(mat4x4.rotation(rotation.roll, lookVector))
        :mulSelf(mat4x4.rotation(-rotation.yaw, upVector))
        :mulSelf(mat4x4.translation(self.transform.position))
    )

    self.camera.transform:set(self.transform:clone():mulSelf(mat4x4.translation(self.jitters)))

    if self.jitters:length() > 0.1 then self.jitters:scale(1-0.1/self.jitters:length()*dt) end

    if Settings.activeDof then
        self.camera.dofDistance = self.prevClosestCar.distanceToCamera
        self.camera.dofFactor = 1
    end
    self.camera.fov = Settings.cameraFov
end
