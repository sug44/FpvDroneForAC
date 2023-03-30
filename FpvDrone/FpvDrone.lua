---@diagnostic disable: param-type-mismatch
local directory = ac.getFolder(ac.FolderID.ACApps) .. "/lua/FpvDrone"
require("settings")
require("input")
require("drone")

SSettings:update()

SButtonStates = {
  toggleSleepButton = {},
  toggleDroneButton = {},
  disableAirDragButton = {},
  disableCollisionButton = {},
  savePositionButton = {},
  teleportToPositionButton = {},
  toggleActiveDofButton = {},
}

local presets = {}
local function updatePresets()
  table.clear(presets)
  io.scanDir(directory .. "/presets", "*.ini", function(fileName)
    table.insert(presets, fileName:split(".ini")[1])
    return nil
  end)
end
updatePresets()
ac.onFolderChanged(directory .. "/presets", "", false, updatePresets)

local function toggleDrone()
  SDrone.active = not SDrone.active
  if SDrone.active then
    SSettings:update()
    SDrone.camera = ac.grabCamera("Fpv Drone request")
    SDrone:updateClosestCar()
    SDrone.velocity = ac.getCar(SDrone.closestCarIndex).velocity:clone():add(vec3(0.01, 10, 0.01))
  else
    SDrone.camera:dispose()
  end
end

local function toggleSleep()
  if SDrone.active then
    if SDrone.camera:active() then
      SDrone.sleepTransform = SDrone.camera.transform:clone()
      SDrone.camera:dispose()
    else
      SDrone.camera = ac.grabCamera("Fpv Drone request")
      SDrone:updateClosestCar()
      SDrone.camera.transform = SDrone.sleepTransform
    end
  end
end

local function toggleActiveDof()
  SSettings:set("Stuff", "activeDof", not SSettings.activeDof)
  if not SSettings.activeDof and SDrone.camera then
    SDrone.camera.dofDistance = SDrone.camera.dofDistanceOriginal
    SDrone.camera.dofFactor = SDrone.camera.dofFactorOriginal
  end
end

local function test()
  -- os.execute("start https://www.google.com")
  -- print(Settings)
end

local function slider(label, section, valueName, min, max, multiplier, decimals, units, description, fn)
  local value, changed = ui.slider("##" .. valueName, SSettings[valueName] * multiplier, min, max,
    label .. ": %." .. decimals .. "f " .. units)
  if ui.itemHovered() and not ui.itemActive() and description then ui.setTooltip(description) end
  if changed then
    if fn then value = fn(value) end
    SSettings:set(section, valueName, math.round(value, decimals) / multiplier)
  end
end

local listeningAxis = {}
local axisStartValues = {}
local function controllerAxis(label, key)
  ui.alignTextToFramePadding()
  ui.text(label)
  ui.sameLine(0, 2)
  if ui.button((SSettings[key] ~= -1 and SSettings[key] + 1 or " ") .. "##" .. key, vec2(22, 22), listeningAxis[key] and ui.ButtonFlags.Active or ui.ButtonFlags.None) then
    listeningAxis[key] = not listeningAxis[key]
    if listeningAxis[key] then
      table.clear(axisStartValues)
      for i = 0, ac.getJoystickAxisCount(SSettings.inputDevice) do
        table.insert(axisStartValues, ac.getJoystickAxisValue(SSettings.inputDevice, i))
      end
    end
  end
  if ui.itemHovered() then ui.setTooltip("Click and move stick to set") end
  if SSettings[key] == -1 then ui.addIcon(ui.Icons.QuestionSign, 10, 0.5, nil, 0) end
  if listeningAxis[key] then
    for i = 0, ac.getJoystickAxisCount(SSettings.inputDevice) do
      if math.abs(axisStartValues[i + 1] - ac.getJoystickAxisValue(SSettings.inputDevice, i)) > 0.3 then
        SSettings:set("Input", key, i)
        listeningAxis[key] = false
        break
      end
    end
  end
  ui.sameLine(0, 4)
  if ui.button("##" .. key, vec2(22, 22)) then SSettings:set("Input", key, -1) end
  ui.addIcon(ui.Icons.Cancel, 10, 0.5, nil, 0)
end

local listeningKey = {}
local function keybind(label, key)
  ui.alignTextToFramePadding()
  ui.text(label)
  ui.sameLine(160)
  local btnLabel = SSettings[key]
  if btnLabel == -1 then
    btnLabel = ""
  elseif btnLabel < 1000 then
    btnLabel = table.indexOf(ui.KeyIndex, btnLabel)
  else
    btnLabel = "Controller: " .. btnLabel - 1000
  end
  if ui.button(btnLabel .. "##" .. key, vec2(100, 22), listeningKey[key] and ui.ButtonFlags.Active or ui.ButtonFlags.None) then
    listeningKey[key] = not listeningKey[key]
  end
  if SSettings[key] == -1 then ui.addIcon(ui.Icons.QuestionSign, 10, 0.5, nil, 0) end
  if listeningKey[key] then
    for name, i in pairs(ui.KeyIndex) do
      if ui.keyboardButtonDown(i) then
        SSettings:set("Keybinds", key, i)
        listeningKey[key] = false
        break
      end
    end
    for i = 0, ac.getJoystickButtonsCount(SSettings.inputDevice), 1 do
      if ac.isJoystickButtonPressed(SSettings.inputDevice, i) then
        SSettings:set("Keybinds", key, 1000 + i)
        listeningKey[key] = false
        break
      end
    end
  end
  ui.sameLine(0, 4)
  if ui.button("##" .. key, vec2(22, 22)) then SSettings:set("Keybinds", key, -1) end
  ui.addIcon(ui.Icons.Cancel, 10, 0.5, nil, 0)
end

local function fpvDroneTab()
  ui.columns(3, false)
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Batery cells", "FPV Drone", "batteryCells", 3, 6, 1, 0, "")
  slider("Prop diameter", "FPV Drone", "propDiameter", 3, 6, 1, 1, "in")
  slider("Prop pitch", "FPV Drone", "propPitch", 2, 6, 1, 1, "in")
  ui.nextColumn()
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Motor KV", "FPV Drone", "motorKv", 1000, 3000, 1, 0, "")
  slider("Camera angle", "FPV Drone", "cameraAngle", 0, 90, 1, 0, "")
  slider("Camera fov", "FPV Drone", "cameraFov", 10, 150, 1, 0, "")
  ui.nextColumn()
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Mass", "FPV Drone", "droneMass", 10, 2000, 1000, 0, "gram")
  slider("Surface Area", "FPV Drone", "droneSurfaceArea", 0, 500, 1e4, 0, "cm^2")
  slider("MinSurfAreaCoeff", "FPV Drone", "minimalSurfaceAreaCoefficient", 0, 1, 1, 1, "",
    "Coefficient by which surface area of the drone is multiplied when its going parallel to the airflow")
  ui.columns(1)
  if ui.checkbox("Linear acceleration", SSettings.linearAcceleration) then
    SSettings:set("FPV Drone", "linearAcceleration", not SSettings.linearAcceleration)
  end
end

local function ratesTab()
  ui.text("Betaflight rates")
  ui.columns(3, false)
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Roll rate", "Betaflight rates", "rollRate", 0, 1, 1, 2, "")
  slider("Roll super", "Betaflight rates", "rollSuper", 0, 0.99, 1, 2, "")
  slider("Roll expo", "Betaflight rates", "rollExpo", 0, 1, 1, 2, "")
  ui.nextColumn()
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Pitch rate", "Betaflight rates", "pitchRate", 0, 1, 1, 2, "")
  slider("Pitch super", "Betaflight rates", "pitchSuper", 0, 0.99, 1, 2, "")
  slider("Pitch expo", "Betaflight rates", "pitchExpo", 0, 1, 1, 2, "")
  ui.nextColumn()
  ui.pushItemWidth(ui.windowWidth() / 3 - 15)
  slider("Yaw rate", "Betaflight rates", "yawRate", 0, 1, 1, 2, "")
  slider("Yaw super", "Betaflight rates", "yawSuper", 0, 0.99, 1, 2, "")
  slider("Yaw expo", "Betaflight rates", "yawExpo", 0, 1, 1, 2, "")
  ui.columns(1)
end

local function physicsTab()
  ui.columns(2, false)
  ui.pushItemWidth(ui.windowWidth() / 2 - 25)
  slider("Air density", "Physics", "airDensity", 0, 3, 1, 1, "")
  slider("Air drag", "Physics", "airDrag", 0, 3, 1, 1, "")
  ui.nextColumn()
  ui.pushItemWidth(ui.windowWidth() / 2 - 25)
  slider("Gravity", "Physics", "gravity", -1, 3, 1, 1, "")
  slider("Ground height", "Physics", "groundLevel", -5000, 5000, 1, 0, "")
  ui.columns(1)
end

local function lagTab()
  ui.columns(2, false)
  if ui.checkbox("Jitter Compensation", SSettings.jitterCompensation) then
    SDrone:updateClosestCar()
    SSettings:set("Lag compensation", "jitterCompensation", not SSettings.jitterCompensation)
  end
  if ui.itemHovered() then ui.setTooltip("Compensation for high frequency jitter of the closest car") end

  ui.pushItemWidth(ui.windowWidth() / 2 - 25)
  slider("Max compensation distance", "Lag compensation", "maxCompensation", 2, 20, 1, 0, "m",
    "Filters out large lag spikes and car resets")
  ui.pushItemWidth(ui.windowWidth() / 2 - 25)
  slider("Max distance to keep compensating", "Lag compensation", "maxDistance", 10, 100, 1, 0, "m",
    "Stops compensation if there is no car closer than this distance")
  ui.nextColumn()
  if ui.checkbox("Lag Compensation", SSettings.lagCompensation) then
    SDrone:updateClosestCar()
    SSettings:set("Lag compensation", "lagCompensation", not SSettings.lagCompensation)
    if SSettings.lagCompensation then SSettings:set("Lag compensation", "jitterCompensation", true) end
  end
  if ui.itemHovered() then ui.setTooltip("EXPERIMENTAL RECOMMEND OFF") end
  ui.pushItemWidth(ui.windowWidth() / 2 - 25)
  slider("Min lag acceleration", "Lag compensation", "minLagAcceleration", 10, 300, 1, 0, "m/s^2")
  ui.columns(1)
end

local timeOffset = ""
local function stuffTab()
  if ui.button("Turn active DOF " .. (SSettings.activeDof and "off" or "on")) or SButtonStates.toggleActiveDofButton.pressed then
    toggleActiveDof()
  end
  if ui.itemHovered() then ui.setTooltip("Actively updates DOF distance to focus on the closest car") end
  ui.setNextItemWidth(40) --
  timeOffset = ui.inputText("##offsetTime", timeOffset)
  ui.sameLine()
  if ui.button("Set time offset in hours") and tonumber(timeOffset) ~= nil then
    ac.setTrackTimezoneOffset(tonumber(timeOffset) * 60 * 60)
  end
  if ui.itemHovered() then ui.setTooltip("Requires WeatherFX") end
end

local function keybindsTab()
  ui.columns(2, false)
  keybind("Toggle drone:", "toggleDroneButton")
  keybind("Disable air drag (hold):", "disableAirDragButton")
  keybind("Save positon:", "savePositionButton")
  ui.nextColumn()
  keybind("Toggle sleep:", "toggleSleepButton")
  keybind("Disable collision (hold):", "disableCollisionButton")
  keybind("Teleport to position:", "teleportToPositionButton")
  ui.nextColumn()
  keybind("Toggle active DOF", "toggleActiveDofButton")
  ui.columns(1)
end

local function inputTab()
  ui.columns(2, false)
  ui.setNextItemWidth(160)
  ui.combo("Input device", ac.getJoystickName(SSettings.inputDevice), function()
    for i = 0, ac.getJoystickCount() do
      if ui.selectable(ac.getJoystickName(i)) then
        SSettings:set("Input", "inputDeviceName", ac.getJoystickName(i))
        SSettings.inputDevice = i
      end
    end
  end)
  ui.nextColumn()
  if ui.checkbox("3D Mode", SSettings.mode3d) then SSettings:set("Input", "mode3d", not SSettings.mode3d) end
  ui.separator()

  ui.columns(4, false)
  ui.pushItemWidth(ui.windowWidth() / 4 - 15)
  ui.setNextItemWidth(50)
  controllerAxis("Throttle axis:", "throttleAxis")
  if ui.checkbox("Invert throttle", SSettings.invertThrottle) then
    SSettings:set("Input", "invertThrottle",
      not SSettings.invertThrottle)
  end
  slider("Throttle from", "Input", "throttleFrom", -1, 1, 1, 1, "", nil,
    function(value) return math.min(value, SSettings.throttleTo - 0.1) end)
  slider("Throttle to", "Input", "throttleTo", -1, 1, 1, 1, "", nil,
    function(value) return math.max(value, SSettings.throttleFrom + 0.1) end)
  ui.nextColumn()

  ui.pushItemWidth(ui.windowWidth() / 4 - 15)
  ui.setNextItemWidth(50)
  controllerAxis("Roll axis:", "rollAxis")
  if ui.checkbox("Invert roll", SSettings.invertRoll) then SSettings:set("Input", "invertRoll", not SSettings.invertRoll) end
  slider("Roll from", "Input", "rollFrom", -1, 1, 1, 1, "", nil,
    function(value) return math.min(value, SSettings.rollTo - 0.1) end)
  slider("Roll to", "Input", "rollTo", -1, 1, 1, 1, "", nil,
    function(value) return math.max(value, SSettings.rollFrom + 0.1) end)
  ui.nextColumn()

  ui.pushItemWidth(ui.windowWidth() / 4 - 15)
  ui.setNextItemWidth(50)
  controllerAxis("Pitch axis:", "pitchAxis")
  if ui.checkbox("Invert pitch", SSettings.invertPitch) then
    SSettings:set("Input", "invertPitch", not SSettings
      .invertPitch)
  end
  slider("Pitch from", "Input", "pitchFrom", -1, 1, 1, 1, "", nil,
    function(value) return math.min(value, SSettings.pitchTo - 0.1) end)
  slider("Pitch to", "Input", "pitchTo", -1, 1, 1, 1, "", nil,
    function(value) return math.max(value, SSettings.pitchFrom + 0.1) end)
  ui.nextColumn()

  ui.pushItemWidth(ui.windowWidth() / 4 - 15)
  ui.setNextItemWidth(50)
  controllerAxis("Yaw axis:", "yawAxis")
  if ui.checkbox("Invert yaw", SSettings.invertYaw) then SSettings:set("Input", "invertYaw", not SSettings.invertYaw) end
  slider("Yaw from", "Input", "yawFrom", -1, 1, 1, 1, "", nil,
    function(value) return math.min(value, SSettings.yawTo - 0.1) end)
  slider("Yaw to", "Input", "yawTo", -1, 1, 1, 1, "", nil,
    function(value) return math.max(value, SSettings.yawFrom + 0.1) end)
  ui.columns(1)
end

local savePresetName = ""
function script.sFpvDrone()
  ui.columns(2, false)
  ui.setColumnWidth(0, ui.windowWidth() - 207)
  ui.setColumnWidth(1, 207)
  if ui.button(SDrone.active and "Turn off" or "Turn on", vec2(60, 0)) or SButtonStates.toggleDroneButton.pressed then
    toggleDrone()
  end
  if ui.button("Sleep", vec2(60, 0)) or SButtonStates.toggleSleepButton.pressed then toggleSleep() end

  local square0pos = vec2(vec2(ui.windowWidth() / 2 - 26, 54))
  local square1pos = vec2(vec2(ui.windowWidth() / 2 + 27, 54))
  local squareSize, circleRadius = 48, 4
  local squareColor = rgbm(tonumber(SSettings.squareColor[1]), tonumber(SSettings.squareColor[2]),
    tonumber(SSettings.squareColor[3]), tonumber(SSettings.squareColor[4]))
  local circleColor = rgbm(tonumber(SSettings.circleColor[1]), tonumber(SSettings.circleColor[2]),
    tonumber(SSettings.circleColor[3]), tonumber(SSettings.circleColor[4]))
  ui.drawRectFilled(square0pos + vec2(-squareSize / 2, -squareSize / 2),
    square0pos + vec2(squareSize / 2, squareSize / 2), squareColor)
  ui.drawRectFilled(square1pos + vec2(-squareSize / 2, -squareSize / 2),
    square1pos + vec2(squareSize / 2, squareSize / 2), squareColor)
  ui.drawCircleFilled(square0pos + vec2(SInput.yaw, -SInput.throttle):scale(squareSize / 2 - circleRadius), circleRadius,
    circleColor)
  ui.drawCircleFilled(square1pos + vec2(SInput.roll, -SInput.pitch):scale(squareSize / 2 - circleRadius), circleRadius,
    circleColor)
  ui.nextColumn()

  ui.setNextItemWidth(148)
  ui.combo("##Presets", "Load preset", function()
    for i, presetName in pairs(presets) do
      if ui.selectable(presetName) then SSettings:loadFrom(presetName) end
    end
  end)
  ui.sameLine(0, 4)
  if ui.button("##openPresetFolder", vec2(22, 22)) then os.openInExplorer(directory .. "/presets") end
  if ui.itemHovered() then ui.setTooltip("Open presets folder") end
  ui.addIcon(ui.Icons.Folder, 13, 0.5, nil, 0)

  ui.setNextItemWidth(148)
  savePresetName = ui.inputText("##savePreset", savePresetName)
  ui.sameLine(0, 4)
  if ui.button("##savePresetBtn", vec2(22, 22)) then
    SSettings:saveTo(savePresetName)
    savePresetName = ""
  end
  if ui.itemHovered() then ui.setTooltip("Save preset as") end
  ui.addIcon(ui.Icons.Save, 13, 0.5, nil, 0)
  ui.columns(1)

  ui.tabBar("fpvDroneTabBar", function()
    ui.tabItem("FPV Drone", fpvDroneTab)
    ui.tabItem("Rates", ratesTab)
    ui.tabItem("Physics", physicsTab)
    ui.tabItem("Lag compensation", lagTab)
    ui.tabItem("Stuff", stuffTab)
    ui.tabItem("Keybinds", keybindsTab)
    ui.tabItem("Input", inputTab)
  end)
end

function script.droneUpdate(dt)
  SInput:update()
  if SDrone.active and SDrone.camera:active() then
    Physics(dt)
  end
end

function script.update()
  for button, state in pairs(SButtonStates) do
    if SSettings[button] ~= -1 then
      if (ac.isKeyDown(SSettings[button]) or ac.isJoystickButtonPressed(SSettings.inputDevice, SSettings[button] - 1000)) and not SButtonStates[button].down then
        SButtonStates[button].pressed = true
      else
        SButtonStates[button].pressed = false
      end
      SButtonStates[button].down = ac.isKeyDown(SSettings[button]) or
          ac.isJoystickButtonPressed(SSettings.inputDevice, SSettings[button] - 1000)
    end
  end
end

function script.sFpvDroneInputDisplay()
  local squareColor = rgbm(tonumber(SSettings.squareColor[1]), tonumber(SSettings.squareColor[2]),
    tonumber(SSettings.squareColor[3]), tonumber(SSettings.squareColor[4]))
  local circleColor = rgbm(tonumber(SSettings.circleColor[1]), tonumber(SSettings.circleColor[2]),
    tonumber(SSettings.circleColor[3]), tonumber(SSettings.circleColor[4]))
  local square0pos = vec2(vec2(ui.windowWidth() / 2 - (SSettings.squareSize + SSettings.squareGap) / 2,
    ui.windowHeight() - SSettings.squareGap - SSettings.squareSize / 2))
  local square1pos = vec2(vec2(ui.windowWidth() / 2 + (SSettings.squareSize + SSettings.squareGap) / 2,
    ui.windowHeight() - SSettings.squareGap - SSettings.squareSize / 2))
  ui.drawRectFilled(square0pos + vec2(-SSettings.squareSize / 2, -SSettings.squareSize / 2),
    square0pos + vec2(SSettings.squareSize / 2, SSettings.squareSize / 2), squareColor)
  ui.drawRectFilled(square1pos + vec2(-SSettings.squareSize / 2, -SSettings.squareSize / 2),
    square1pos + vec2(SSettings.squareSize / 2, SSettings.squareSize / 2), squareColor)
  ui.drawCircleFilled(
    square0pos + vec2(SInput.yaw, -SInput.throttle):scale(SSettings.squareSize / 2 - SSettings.circleRadius),
    SSettings.circleRadius, circleColor)
  ui.drawCircleFilled(
    square1pos + vec2(SInput.roll, -SInput.pitch):scale(SSettings.squareSize / 2 - SSettings.circleRadius),
    SSettings.circleRadius, circleColor)
end

function script.sFpvDroneInputDisplaySettings()
  slider("Square size", "App", "squareSize", 1, 500, 1, 0, "px")
  slider("Square gap", "App", "squareGap", 0, 500, 1, 0, "px")
  ui.text("Square color")
  ui.setNextItemWidth(150)
  local squareColorS = rgbm(tonumber(SSettings.squareColor[1]), tonumber(SSettings.squareColor[2]),
    tonumber(SSettings.squareColor[3]), tonumber(SSettings.squareColor[4]))
  if ui.colorPicker("##squareColor", squareColorS) then
    SSettings:set("App", "squareColor",
      { [1] = squareColorS.r,[2] = squareColorS.g,[3] = squareColorS.b,[4] = squareColorS.mult })
  end
  local squareOpacity, soChanged = ui.slider('##squareOpacity', squareColorS.mult, 0, 1, "Square opacity: %.2f ")
  if soChanged then
    SSettings:set("App", "squareColor",
      { [1] = squareColorS.r,[2] = squareColorS.g,[3] = squareColorS.b,[4] = squareOpacity })
  end
  slider("Circle radius", "App", "circleRadius", 1, 100, 1, 0, "px")
  ui.text("Circle color")
  ui.setNextItemWidth(150)
  local circleColorS = rgbm(tonumber(SSettings.circleColor[1]), tonumber(SSettings.circleColor[2]),
    tonumber(SSettings.circleColor[3]), tonumber(SSettings.circleColor[4]))
  if ui.colorPicker("##circleColor", circleColorS) then
    SSettings:set("App", "circleColor",
      { [1] = circleColorS.r,[2] = circleColorS.g,[3] = circleColorS.b,[4] = circleColorS.mult })
  end
  local circleOpacity, coChanged = ui.slider('##circleOpacity', circleColorS.mult, 0, 1, "Circle opacity: %.2f ")
  if coChanged then
    SSettings:set("App", "circleColor",
      { [1] = circleColorS.r,[2] = circleColorS.g,[3] = circleColorS.b,[4] = circleOpacity })
  end
end
