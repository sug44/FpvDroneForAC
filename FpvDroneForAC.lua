require("settings")
require("input")
require("drone")

local directory = ac.dirname()

ButtonStates = {
    toggleSleepButton = {},
    toggleDroneButton = {},
    disableAirDragButton = {},
    disableCollisionButton = {},
    savePositionButton = {},
    teleportToPositionButton = {},
}

function script.droneUpdate(dt)
    Input:update()
    Drone:physics(dt)
end

function script.update()
    for button, state in pairs(ButtonStates) do
        if Settings[button] ~= -1 and Settings[button] ~= nil then
            if (ac.isKeyDown(Settings[button]) or ac.isJoystickButtonPressed(Settings.inputDevice, Settings[button] - 1000)) and not state.down then
                state.pressed = true
            else
                state.pressed = false
            end
            state.down = ac.isKeyDown(Settings[button]) or ac.isJoystickButtonPressed(Settings.inputDevice, Settings[button] - 1000)
        end
    end
    if ButtonStates.toggleSleepButton.pressed then Drone:toggleSleep() end
    if ButtonStates.toggleDroneButton.pressed then Drone:toggle() end
end

local presets = {}
local function updatePresets()
    table.clear(presets)
    io.scanDir(directory .. "/presets", "*.ini", function (fileName)
        table.insert(presets, fileName:split(".ini")[1])
        return nil
    end)
end
updatePresets()
ac.onFolderChanged(directory .. "/presets", nil, false, updatePresets)

local function slider(label, section, valueName, min, max, multiplier, decimals, units, description, fn)
    local value, changed = ui.slider("##" .. valueName, (section and Settings[valueName] or valueName) * multiplier, min, max, label .. ": %." .. decimals .. "f " .. units)
    if ui.itemHovered() and not ui.itemActive() and description then ui.setTooltip(description) end
    if changed then
        if fn then value = fn(value) end
        if section and valueName then Settings:set(section, valueName, math.round(value, decimals) / multiplier) end
    end
    return value, changed
end

local listeningAxis = {}
local axisStartValues = {}
local function controllerAxis(label, key)
    ui.alignTextToFramePadding()
    ui.text(label)
    ui.sameLine(0, 2)
    if ui.button((Settings[key] ~= -1 and Settings[key] + 1 or " ") .. "##" .. key, vec2(22, 22), listeningAxis[key] and ui.ButtonFlags.Active or ui.ButtonFlags.None) then
        listeningAxis[key] = not listeningAxis[key]
        if listeningAxis[key] then
            table.clear(axisStartValues)
            for i = 0, ac.getJoystickAxisCount(Settings.inputDevice) do
                table.insert(axisStartValues, ac.getJoystickAxisValue(Settings.inputDevice, i))
            end
        end
    end
    if ui.itemHovered() then ui.setTooltip("Click and move stick to set") end
    if Settings[key] == -1 then ui.addIcon(ui.Icons.QuestionSign, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0)) end
    if listeningAxis[key] then
        for i = 0, ac.getJoystickAxisCount(Settings.inputDevice) do
            if math.abs(axisStartValues[i + 1] - ac.getJoystickAxisValue(Settings.inputDevice, i)) > 0.3 then
                Settings:set("Input", key, i)
                listeningAxis[key] = false
                break
            end
        end
    end
    ui.sameLine(0, 4)
    if ui.button("##" .. key, vec2(22, 22)) then Settings:set("Input", key, -1) end
    ui.addIcon(ui.Icons.Cancel, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0))
end

local listeningKey = {}
local function keybind(label, key)
    ui.alignTextToFramePadding()
    ui.text(label)
    ui.sameLine(160)
    local btnLabel = Settings[key]
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
    if Settings[key] == -1 then ui.addIcon(ui.Icons.QuestionSign, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0)) end
    if listeningKey[key] then
        for _, i in pairs(ui.KeyIndex) do
            if ui.keyboardButtonDown(i) then
                Settings:set("Keybinds", key, i)
                listeningKey[key] = false
                break
            end
        end
        for i = 0, ac.getJoystickButtonsCount(Settings.inputDevice), 1 do
            if ac.isJoystickButtonPressed(Settings.inputDevice, i) then
                Settings:set("Keybinds", key, 1000 + i)
                listeningKey[key] = false
                break
            end
        end
    end
    ui.sameLine(0, 4)
    if ui.button("##" .. key, vec2(22, 22)) then Settings:set("Keybinds", key, -1) end
    ui.addIcon(ui.Icons.Cancel, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0))
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
    if ui.checkbox("Linear acceleration", Settings.linearAcceleration) then
        Settings:set("FPV Drone", "linearAcceleration", not Settings.linearAcceleration)
    end
end

local function ratesTab()
    ui.text("Betaflight rates")
    ui.columns(3, false)
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Roll rate", "Betaflight rates", "rollRate", 0, 3, 1, 2, "")
    slider("Roll super", "Betaflight rates", "rollSuper", 0, 0.99, 1, 2, "")
    slider("Roll expo", "Betaflight rates", "rollExpo", 0, 1, 1, 2, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Pitch rate", "Betaflight rates", "pitchRate", 0, 3, 1, 2, "")
    slider("Pitch super", "Betaflight rates", "pitchSuper", 0, 0.99, 1, 2, "")
    slider("Pitch expo", "Betaflight rates", "pitchExpo", 0, 1, 1, 2, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Yaw rate", "Betaflight rates", "yawRate", 0, 3, 1, 2, "")
    slider("Yaw super", "Betaflight rates", "yawSuper", 0, 0.99, 1, 2, "")
    slider("Yaw expo", "Betaflight rates", "yawExpo", 0, 1, 1, 2, "")
    ui.columns(1)
end

local function physicsTab()
    ui.columns(2, false)
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Air density", "Physics", "airDensity", 0, 3, 1, 1, "")
    slider("Air drag", "Physics", "airDrag", 0, 3, 1, 1, "")
    slider("Time multiplier", "Physics", "time", 0.05, 2, 1, 1, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Gravity", "Physics", "gravity", -1, 3, 1, 1, "")
    slider("Ground height", "Physics", "groundLevel", -5000, 5000, 1, 0, "")
    ui.columns(1)
end

local time = nil
local function stuffTab()
    ui.columns(2, false)
    if ui.checkbox("Jitter Compensation", Settings.jitterCompensation) then
        Settings:set("Lag compensation", "jitterCompensation", not Settings.jitterCompensation)
        Drone.jitters = vec3()
    end
    if ui.itemHovered() then ui.setTooltip("Compensation for high frequency jitter of the closest car") end
    ui.nextColumn()
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Max compensation distance", "Lag compensation", "maxCompensation", 2, 20, 1, 0, "m", "Filters out large lag spikes and car resets")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Max distance to keep compensating", "Lag compensation", "maxDistance", 10, 100, 1, 0, "m", "Stops compensation if there is no car closer than this distance")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 2 - 25 - 55)
    time, _ = ui.slider("##timeSlider", time, 0, 24, "Time: " .. "%.1f hours")
    ui.sameLine(0, 4)
    ui.pushItemWidth(66)
    if ui.button("Apply") then ac.setTrackTimezoneOffset(time * 60 * 60) end
    if ui.itemHovered() then ui.setTooltip("Requires WeatherFX") end
    ui.columns(1)
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
    ui.columns(1)
end

local function inputTab()
    ui.columns(2, false)
    ui.setNextItemWidth(160)
    ui.combo("Input device", ac.getJoystickName(Settings.inputDevice), function ()
        for i = 0, ac.getJoystickCount()-1 do
            local name = ac.getJoystickName(i)
            if name and ui.selectable(name) then
                Settings:set("Input", "inputDeviceName", ac.getJoystickName(i))
                Settings.inputDevice = i
            end
        end
    end)
    ui.nextColumn()
    if ui.checkbox("3D Mode", Settings.mode3d) then Settings:set("Input", "mode3d", not Settings.mode3d) end
    ui.separator()

    ui.columns(4, false)
    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Throttle axis:", "throttleAxis")
    if ui.checkbox("Invert throttle", Settings.invertThrottle) then
        Settings:set("Input", "invertThrottle", not Settings.invertThrottle)
    end
    slider("Throttle from", "Input", "throttleFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.throttleTo - 0.1) end)
    slider("Throttle to", "Input", "throttleTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.throttleFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Roll axis:", "rollAxis")
    if ui.checkbox("Invert roll", Settings.invertRoll) then Settings:set("Input", "invertRoll", not Settings.invertRoll) end
    slider("Roll from", "Input", "rollFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.rollTo - 0.1) end)
    slider("Roll to", "Input", "rollTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.rollFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Pitch axis:", "pitchAxis")
    if ui.checkbox("Invert pitch", Settings.invertPitch) then
        Settings:set("Input", "invertPitch", not Settings.invertPitch)
    end
    slider("Pitch from", "Input", "pitchFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.pitchTo - 0.1) end)
    slider("Pitch to", "Input", "pitchTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.pitchFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Yaw axis:", "yawAxis")
    if ui.checkbox("Invert yaw", Settings.invertYaw) then Settings:set("Input", "invertYaw", not Settings.invertYaw) end
    slider("Yaw from", "Input", "yawFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.yawTo - 0.1) end)
    slider("Yaw to", "Input", "yawTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.yawFrom + 0.1) end)
    ui.columns(1)
end

local savePresetName = ""
function script.sFpvDrone()
    ui.columns(2, false)
    ui.setColumnWidth(0, ui.windowWidth() - 207)
    ui.setColumnWidth(1, 207)
    if ui.button(Drone.active and "Turn off" or "Turn on", vec2(60, 0)) then
        Drone:toggle()
    end
    if Drone.active then
        if ui.button(Drone.sleep and "Sleep off" or "Sleep on", vec2(70, 0)) then Drone:toggleSleep() end
    end

    local square0pos = vec2(ui.windowWidth() / 2 - 26, 54)
    local square1pos = vec2(ui.windowWidth() / 2 + 27, 54)
    local squareSize, circleRadius = 48, 4
    local squareColor = rgbm(tonumber(Settings.squareColor[1]), tonumber(Settings.squareColor[2]), tonumber(Settings.squareColor[3]), tonumber(Settings.squareColor[4]))
    local circleColor = rgbm(tonumber(Settings.circleColor[1]), tonumber(Settings.circleColor[2]), tonumber(Settings.circleColor[3]), tonumber(Settings.circleColor[4]))
    ui.drawRectFilled(square0pos + vec2(-squareSize / 2, -squareSize / 2), square0pos + vec2(squareSize / 2, squareSize / 2), squareColor)
    ui.drawRectFilled(square1pos + vec2(-squareSize / 2, -squareSize / 2), square1pos + vec2(squareSize / 2, squareSize / 2), squareColor)
    ui.drawCircleFilled(square0pos + vec2(Input.yaw, -Input.throttle):scale(squareSize / 2 - circleRadius), circleRadius, circleColor)
    ui.drawCircleFilled(square1pos + vec2(Input.roll, -Input.pitch):scale(squareSize / 2 - circleRadius), circleRadius, circleColor)
    ui.nextColumn()

    ui.setNextItemWidth(148)
    ui.combo("##Presets", "Load preset", function ()
        for _, presetName in pairs(presets) do
            if ui.selectable(presetName) then Settings:loadFrom(presetName) end
        end
    end)
    ui.sameLine(0, 4)
    if ui.button("##openPresetFolder", vec2(22, 22)) then os.openInExplorer(directory .. "/presets") end
    if ui.itemHovered() then ui.setTooltip("Open presets folder") end
    ui.addIcon(ui.Icons.Folder, vec2(13, 13), vec2(0.5, 0.5), nil, vec2(0, 0))

    ui.setNextItemWidth(148)
    savePresetName = ui.inputText("Save preset", savePresetName, ui.InputTextFlags.Placeholder)
    ui.sameLine(0, 4)
    if ui.button("##savePresetBtn", vec2(22, 22)) then
        Settings:saveTo(savePresetName)
        savePresetName = ""
    end
    if ui.itemHovered() then ui.setTooltip("Save preset as") end
    ui.addIcon(ui.Icons.Save, vec2(13, 13), vec2(0.5, 0.5), nil, vec2(0, 0))
    ui.columns(1)

    ui.tabBar("fpvDroneTabBar", function ()
        ui.tabItem("FPV Drone", fpvDroneTab)
        ui.tabItem("Rates", ratesTab)
        ui.tabItem("Physics", physicsTab)
        ui.tabItem("Keybinds", keybindsTab)
        ui.tabItem("Input", inputTab)
        ui.tabItem("Stuff", stuffTab)
    end)
end

function script.sFpvDroneInputDisplay()
    local squareColor = rgbm(tonumber(Settings.squareColor[1]), tonumber(Settings.squareColor[2]), tonumber(Settings.squareColor[3]), tonumber(Settings.squareColor[4]))
    local circleColor = rgbm(tonumber(Settings.circleColor[1]), tonumber(Settings.circleColor[2]), tonumber(Settings.circleColor[3]), tonumber(Settings.circleColor[4]))
    local square0pos = vec2(ui.windowWidth() / 2 - (Settings.squareSize + Settings.squareGap) / 2, ui.windowHeight() - Settings.squareGap - Settings.squareSize / 2)
    local square1pos = vec2(ui.windowWidth() / 2 + (Settings.squareSize + Settings.squareGap) / 2, ui.windowHeight() - Settings.squareGap - Settings.squareSize / 2)
    ui.drawRectFilled(square0pos + vec2(-Settings.squareSize / 2, -Settings.squareSize / 2), square0pos + vec2(Settings.squareSize / 2, Settings.squareSize / 2), squareColor)
    ui.drawRectFilled(square1pos + vec2(-Settings.squareSize / 2, -Settings.squareSize / 2), square1pos + vec2(Settings.squareSize / 2, Settings.squareSize / 2), squareColor)
    ui.drawCircleFilled(square0pos + vec2(Input.yaw, -Input.throttle):scale(Settings.squareSize / 2 - Settings.circleRadius), Settings.circleRadius, circleColor)
    ui.drawCircleFilled(square1pos + vec2(Input.roll, -Input.pitch):scale(Settings.squareSize / 2 - Settings.circleRadius), Settings.circleRadius, circleColor)
end

function script.sFpvDroneInputDisplaySettings()
    slider("Square size", "App", "squareSize", 1, 500, 1, 0, "px")
    slider("Square gap", "App", "squareGap", 0, 500, 1, 0, "px")
    ui.text("Square color")
    ui.setNextItemWidth(150)
    local squareColorS = rgbm(tonumber(Settings.squareColor[1]), tonumber(Settings.squareColor[2]), tonumber(Settings.squareColor[3]), tonumber(Settings.squareColor[4]))
    if ui.colorPicker("##squareColor", squareColorS) then
        Settings:set("App", "squareColor", { [1] = squareColorS.r, [2] = squareColorS.g, [3] = squareColorS.b, [4] = squareColorS.mult })
    end
    local squareOpacity, soChanged = ui.slider('##squareOpacity', squareColorS.mult, 0, 1, "Square opacity: %.2f ")
    if soChanged then
        Settings:set("App", "squareColor", { [1] = squareColorS.r, [2] = squareColorS.g, [3] = squareColorS.b, [4] = squareOpacity })
    end
    slider("Circle radius", "App", "circleRadius", 1, 100, 1, 0, "px")
    ui.text("Circle color")
    ui.setNextItemWidth(150)
    local circleColorS = rgbm(tonumber(Settings.circleColor[1]), tonumber(Settings.circleColor[2]), tonumber(Settings.circleColor[3]), tonumber(Settings.circleColor[4]))
    if ui.colorPicker("##circleColor", circleColorS) then
        Settings:set("App", "circleColor", { [1] = circleColorS.r, [2] = circleColorS.g, [3] = circleColorS.b, [4] = circleColorS.mult })
    end
    local circleOpacity, coChanged = ui.slider('##circleOpacity', circleColorS.mult, 0, 1, "Circle opacity: %.2f ")
    if coChanged then
        Settings:set("App", "circleColor", { [1] = circleColorS.r, [2] = circleColorS.g, [3] = circleColorS.b, [4] = circleOpacity })
    end
end
