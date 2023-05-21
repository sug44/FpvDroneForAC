require("input")
require("settings")

local function betaflightRates(x, a, b, c) -- a-rate, b-super, c-expo
    local p = 1 / (1 - (math.abs(x) * b))
    local q = (x ^ 4 * c) + math.abs(x) * (1 - c)
    local r = 200 * q * a
    local t = r * p * (x < 0 and -1 or 1)
    return t
end

local function thrust(isLinearAcceleration, airDensity, propDiameter, propPitch, motorKv, batteryCells, throttle,
                      inflowVelocity)
  local force
  if not isLinearAcceleration then
    local a = airDensity * (3.14 * ((0.0254 * propDiameter) ^ 2) / 4) *
        ((propDiameter / (3.29547 * (propPitch + 0.5))) ^ 1.5) * 1.5 * 4
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
  return velocity:clone():normalize():scale(-0.5 * density * velocity:length() ^ 2 * (2.5 * coefficient) *
    (area * areaCoeff))
end

local function vectorAngle(vec1, vec2)
  return math.acos(vec1:clone():dot(vec2:clone()) / (vec1:clone():length() * vec2:clone():length()))
end

SDrone = {
  active = false,
  camera = ac.grabbedCamera,
  velocity = vec3(),
  sleepTransform = mat4x4.identity(),
  savedTransform = mat4x4.identity(),
  savedVelocity = vec3(),
  closestCar = 0,
  prevClosestCarState = ac.StateCar,
}

function SDrone:updateClosestCar()
  if self.active and self.camera:active() then
    local closestCarIndex = 0
    local minDistance = 1e9
    for i = 0, ac.getSim().carsCount - 1 do
      local car = ac.getCar(i)
      if car then
        if car.distanceToCamera < minDistance then
          closestCarIndex = i
          minDistance = car.distanceToCamera
        end
      end
    end
    self.closestCar = ac.getCar(closestCarIndex)
  end
end

function Physics(dt)
  local tempPos = SDrone.camera.transform.position:clone()
  SDrone.camera.transform
      :mulSelf(mat4x4.translation(tempPos:clone():scale(-1)))
      :mulSelf(mat4x4.rotation(-math.rad(SSettings.cameraAngle), SDrone.camera.transform.side))
      :mulSelf(mat4x4.translation(tempPos:clone()))

  local camTransform = SDrone.camera.transform:clone()
  local lookVector = camTransform.look:clone()
  local sideVector = camTransform.side:clone()
  local upVector = camTransform.up:clone()

  local inflowCoefficient = 1 - math.sin(vectorAngle(upVector:clone(), SDrone.velocity:clone()))
  local inflowVelocity = SDrone.velocity:length() * inflowCoefficient
  -- print(math.round(DroneState.velocity:length()) .. " " .. math.round(inflowVelocity) .. " " .. math.round(inflowCoefficient, 3)) --

  local thrustForce = upVector:clone():scale(thrust(SSettings.linearAcceleration, SSettings.airDensity,
    SSettings.propDiameter, SSettings.propPitch, SSettings.motorKv, SSettings.batteryCells,
    SSettings.mode3d and SInput.throttle or (SInput.throttle + 1) / 2,
    inflowVelocity))

  local airDragForce = vec3()
  if not SButtonStates.disableAirDragButton.down then
    airDragForce = airDragForceFn(1.2 * SSettings.airDensity, SDrone.velocity, SSettings.airDrag,
      SSettings.droneSurfaceArea,
      SSettings.minimalSurfaceAreaCoefficient, inflowCoefficient)
  end

  local force = thrustForce + airDragForce

  local acceleration = force / SSettings.droneMass + vec3(0, -9.8 * SSettings.gravity, 0)

  SDrone.velocity:addScaled(acceleration:clone(), dt)

  local lag = vec3()
  if SSettings.jitterCompensation and SDrone.closestCar and SDrone.prevClosestCarState and SDrone.closestCar.distanceToCamera < SSettings.maxDistance and not ac.isInReplayMode() then
    local posDiff = SDrone.closestCar.position:clone():addScaled(SDrone.prevClosestCarState.position, -1)
    local velocity = posDiff:clone():scale(1 /
      ((SDrone.closestCar.timestamp - SDrone.prevClosestCarState.timestamp) / 1e3))
    if velocity ~= velocity then velocity = vec3() end
    if posDiff:clone():length() < SSettings.maxCompensation then
      lag = posDiff:clone():addScaled(velocity, -dt) -- jitter
      if SSettings.lagCompensation and math.abs((SDrone.closestCar.velocity - velocity):length()) > SSettings.minLagAcceleration then
        print("LAG")
        lag = posDiff:clone()
      end
    end
  end

  if SButtonStates.savePositionButton.pressed then
    SDrone.savedTransform = SDrone.camera.transform:clone()
    SDrone.savedVelocity = SDrone.velocity:clone()
  end
  if SButtonStates.teleportToPositionButton.pressed then
    SDrone.camera.transform = SDrone.savedTransform:clone()
    camTransform = SDrone.savedTransform:clone()
    SDrone.velocity = SDrone.savedVelocity:clone()
  end

  local newPosition = camTransform:clone().position:addScaled(SDrone.velocity:clone(), dt):add(lag)

  if newPosition.y < SSettings.groundLevel + 0.1 then
    newPosition.y = SSettings.groundLevel + 0.1
    SDrone.velocity.y = 0.01
  end

  local rotation = {
    roll = math.rad(betaflightRates(SInput.roll, SSettings.rollRate, SSettings.rollSuper, SSettings.rollExpo)) * dt,
    pitch = math.rad(betaflightRates(SInput.pitch, SSettings.pitchRate, SSettings.pitchSuper, SSettings.pitchExpo)) * dt,
    yaw = math.rad(betaflightRates(SInput.yaw, SSettings.yawRate, SSettings.yawSuper, SSettings.yawExpo)) * dt
  }

  if SSettings.activeDof then
    SDrone.camera.dofDistance = SDrone.closestCar.distanceToCamera
    SDrone.camera.dofFactor = 1
  end
  SDrone.camera.fov = SSettings.cameraFov
  SDrone.camera.transform
      :mulSelf(mat4x4.translation(camTransform.position:clone():scale(-1)))
      :mulSelf(mat4x4.rotation(-rotation.pitch + math.rad(SSettings.cameraAngle), sideVector))
      :mulSelf(mat4x4.rotation(rotation.roll, lookVector))
      :mulSelf(mat4x4.rotation(-rotation.yaw, upVector))
      :mulSelf(mat4x4.translation(newPosition))

  SDrone:updateClosestCar()
  SDrone.prevClosestCarState = {
    position = SDrone.closestCar.position:clone(),
    timestamp = SDrone.closestCar.timestamp,
  }
end
