local M = {}

local function slider(label, settingsValueName, min, max, multiplier, decimals, units, description, fn)
    local value, changed = ui.slider("##" .. settingsValueName, Settings[settingsValueName] * multiplier, min, max, label .. ": %." .. decimals .. "f " .. units)
    if ui.itemHovered() and not ui.itemActive() and description then ui.setTooltip(description) end
    if changed then
        if fn then value = fn(value) end
        Settings[settingsValueName] = math.round(value, decimals) / multiplier
    end
    return value, changed
end

local listeningAxis = -1
local axisStartValues = {}
local function controllerAxis(label, key)
    ui.alignTextToFramePadding()
    ui.text(label)
    ui.sameLine(0, 2)
    if ui.button((Settings[key] ~= -1 and Settings[key] + 1 or " ") .. "##" .. key, vec2(22, 22), listeningAxis == key and ui.ButtonFlags.Active or ui.ButtonFlags.None) then
        listeningAxis = listeningAxis == key and -1 or key
        if listeningAxis == key then
            table.clear(axisStartValues)
            for i = 0, ac.getJoystickAxisCount(Input.inputDevice) do
                table.insert(axisStartValues, ac.getJoystickAxisValue(Input.inputDevice, i))
            end
        end
    end
    if ui.itemHovered() then ui.setTooltip("Click and move stick to set") end
    if Settings[key] == -1 then ui.addIcon(ui.Icons.QuestionSign, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0)) end
    if listeningAxis == key then
        for i = 0, ac.getJoystickAxisCount(Input.inputDevice) do
            if math.abs(axisStartValues[i + 1] - ac.getJoystickAxisValue(Input.inputDevice, i)) > 0.3 then
                Settings[key] = i
                listeningAxis = -1
                break
            end
        end
    end
    ui.sameLine(0, 4)
    if ui.button("##" .. key, vec2(22, 22)) then Settings[key] = -1 end
    ui.addIcon(ui.Icons.Cancel, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0))
end

local listeningKey = -1
local function keybind(label, key)
    ui.alignTextToFramePadding()
    ui.text(label)
    ui.sameLine(160)
    local buttonSettings = Settings[key]
    local buttonLabel = ""
    if buttonSettings.type == "keyboard" then
        buttonLabel = table.indexOf(ui.KeyIndex, buttonSettings.key) or tostring(buttonSettings.key)
    elseif buttonSettings.type == "controller" then
        buttonLabel = "Controller: " .. buttonSettings.key
    end
    if ui.button(buttonLabel .. "##" .. key, vec2(100, 22), listeningKey == key and ui.ButtonFlags.Active or ui.ButtonFlags.None) then
        listeningKey = listeningKey == key and -1 or key
    end
    if Settings[key].type == "none" then ui.addIcon(ui.Icons.QuestionSign, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0)) end
    if listeningKey == key then
        for _, i in pairs(ui.KeyIndex) do
            if ui.keyboardButtonDown(i) then
                Settings[key] = { type = "keyboard", key = i }
                listeningKey = -1
                break
            end
        end
        for i = 0, ac.getJoystickButtonsCount(Input.inputDevice), 1 do
            if ac.isJoystickButtonPressed(Input.inputDevice, i) then
                Settings[key] = { type = "controller", key = i }
                listeningKey = -1
                break
            end
        end
    end
    ui.sameLine(0, 4)
    if ui.button("##" .. key, vec2(22, 22)) then Settings[key] = { type = "none", key = -1 } end
    ui.addIcon(ui.Icons.Cancel, vec2(10, 10), vec2(0.5, 0.5), nil, vec2(0, 0))
end

local function fpvDroneTab()
    ui.columns(3, false)
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Batery cells", "batteryCells", 3, 6, 1, 0, "")
    slider("Prop diameter", "propDiameter", 3, 6, 1, 1, "in")
    slider("Prop pitch", "propPitch", 2, 6, 1, 1, "in")
    if ui.checkbox("Linear acceleration", Settings.linearAcceleration) then
        Settings.linearAcceleration = not Settings.linearAcceleration
    end
    if ui.itemHovered() then ui.setTooltip("Make thrust linear to throttle. Motor KV is multiplier") end
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Motor KV", "motorKv", 1000, 3000, 1, 0, "")
    slider("Camera angle", "cameraAngle", 0, 90, 1, 0, "")
    slider("Camera fov", "cameraFov", 10, 150, 1, 0, "")
    if ui.checkbox("Collision", Settings.collision) then
        Settings.collision = not Settings.collision
    end
    if ui.itemHovered() then ui.setTooltip("If you need to temporarily disable collision use \"Disable collision\" keybind") end
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Mass", "droneMass", 10, 2000, 1000, 0, "gram")
    slider("Surface Area", "droneSurfaceArea", 0, 500, 1e4, 0, "cm^2")
    slider("MinSurfAreaCoeff", "minimalSurfaceAreaCoefficient", 0, 1, 1, 1, "",
        "Coefficient by which surface area of the drone is multiplied when its going parallel to the airflow")
    ui.columns(1)
end

local function ratesTab()
    ui.text("Betaflight rates")
    ui.columns(3, false)
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Roll rate", "rollRate", 0, 3, 1, 2, "")
    slider("Roll super", "rollSuper", 0, 0.99, 1, 2, "")
    slider("Roll expo", "rollExpo", 0, 1, 1, 2, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Pitch rate", "pitchRate", 0, 3, 1, 2, "")
    slider("Pitch super", "pitchSuper", 0, 0.99, 1, 2, "")
    slider("Pitch expo", "pitchExpo", 0, 1, 1, 2, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 3 - 15)
    slider("Yaw rate", "yawRate", 0, 3, 1, 2, "")
    slider("Yaw super", "yawSuper", 0, 0.99, 1, 2, "")
    slider("Yaw expo", "yawExpo", 0, 1, 1, 2, "")
    ui.columns(1)
end

local function physicsTab()
    ui.columns(2, false)
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Air density", "airDensity", 0, 3, 1, 1, "")
    slider("Air drag", "airDrag", 0, 3, 1, 1, "")
    slider("Time multiplier", "time", 0.05, 2, 1, 1, "")
    slider("Gravity", "gravity", -1, 3, 1, 1, "")
    ui.nextColumn()
    ui.pushItemWidth(ui.windowWidth() / 2 - 25)
    slider("Ground height", "groundLevel", -5000, 5000, 1, 0, "m", "Height of simulated ground. Prevents the drone from falling under the map forever")
    slider("Drone friction", "groundFriction", 0, 1, 1, 2, "")
    slider("Bounciness", "bounciness", 0, 1, 1, 2, "")
    ui.columns(1)
end

local function keybindsTab()
    ui.columns(2, false)
    keybind("Toggle drone", "toggleDroneButton")
    keybind("Disable drag and friction", "disableAirDragAndFrictionButton")
    keybind("Save positon", "savePositionButton")
    ui.nextColumn()
    keybind("Toggle sleep", "toggleSleepButton")
    keybind("Disable collision", "disableCollisionButton")
    keybind("Teleport to position", "teleportToPositionButton")
    ui.nextColumn()
    ui.columns(1)
end

local function inputTab()
    ui.columns(2, false)
    ui.setNextItemWidth(160)
    ui.combo("Input device", ac.getJoystickName(Input.inputDevice), function ()
        for i = 0, ac.getJoystickCount()-1 do
            local name = ac.getJoystickName(i)
            if name and ui.selectable(name) then
                Settings.inputDeviceName = ac.getJoystickName(i)
                Settings.inputDeviceGUID = ac.getJoystickInstanceGUID(i)
                Input:updateInputDevice()
            end
        end
    end)
    if ui.itemHovered() then ui.setTooltip("Only controllers plugged in at AC launch can be used") end
    ui.nextColumn()
    if ui.checkbox("3D Mode", Settings.mode3d) then Settings.mode3d = not Settings.mode3d end
    if ui.itemHovered() then ui.setTooltip("Lower half of throttle range will spin the motors backwards. Recommended for game controllers") end
    ui.separator()

    ui.columns(4, false)
    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Throttle axis:", "throttleAxis")
    if ui.checkbox("Invert throttle", Settings.invertThrottle) then
        Settings.invertThrottle = not Settings.invertThrottle
    end
    slider("Throttle from", "throttleFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.throttleTo - 0.1) end)
    slider("Throttle to", "throttleTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.throttleFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Roll axis:", "rollAxis")
    if ui.checkbox("Invert roll", Settings.invertRoll) then Settings.invertRoll = not Settings.invertRoll end
    slider("Roll from", "rollFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.rollTo - 0.1) end)
    slider("Roll to", "rollTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.rollFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Pitch axis:", "pitchAxis")
    if ui.checkbox("Invert pitch", Settings.invertPitch) then
        Settings.invertPitch = not Settings.invertPitch
    end
    slider("Pitch from", "pitchFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.pitchTo - 0.1) end)
    slider("Pitch to", "pitchTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.pitchFrom + 0.1) end)
    ui.nextColumn()

    ui.pushItemWidth(ui.windowWidth() / 4 - 15)
    ui.setNextItemWidth(50)
    controllerAxis("Yaw axis:", "yawAxis")
    if ui.checkbox("Invert yaw", Settings.invertYaw) then Settings.invertYaw = not Settings.invertYaw end
    slider("Yaw from", "yawFrom", -1, 1, 1, 1, "", nil, function (value) return math.min(value, Settings.yawTo - 0.1) end)
    slider("Yaw to", "yawTo", -1, 1, 1, 1, "", nil, function (value) return math.max(value, Settings.yawFrom + 0.1) end)
    ui.columns(1)
end

local savePresetName = ""
local readmeText = io.load(ac.dirname().."/README.md")
function M.fpvDroneWindow()
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
    local squareColor = rgbm(table.unpack(Settings.squareColor))
    local circleColor = rgbm(table.unpack(Settings.circleColor))
    ui.drawRectFilled(square0pos + vec2(-squareSize / 2, -squareSize / 2), square0pos + vec2(squareSize / 2, squareSize / 2), squareColor)
    ui.drawRectFilled(square1pos + vec2(-squareSize / 2, -squareSize / 2), square1pos + vec2(squareSize / 2, squareSize / 2), squareColor)
    ui.drawCircleFilled(square0pos + vec2(Input.yaw, -Input.throttle):scale(squareSize / 2 - circleRadius), circleRadius, circleColor)
    ui.drawCircleFilled(square1pos + vec2(Input.roll, -Input.pitch):scale(squareSize / 2 - circleRadius), circleRadius, circleColor)
    ui.nextColumn()

    ui.setNextItemWidth(148)
    ui.combo("##Presets", "Load preset", function ()
        for _, presetName in ipairs(Settings.presets) do
            local defaultPreset = Settings.notDeletablePresetsMap[presetName]
            if ui.selectable(presetName, nil, ui.SelectableFlags.None, defaultPreset and vec2(128, 20) or vec2(108, 20)) then
                Settings:loadPreset(presetName)
            end
            if not defaultPreset then
                ui.sameLine(0, 4)
                if ui.button("##deletePresetButton"..presetName, vec2(20, 20)) then
                    Settings:deletePreset(presetName)
                end
                ui.addIcon(ui.Icons.Delete, vec2(13, 13), vec2(0.5, 0.5), nil, vec2(0, 0))
            end
        end
    end)
    ui.sameLine(0, 4)
    if ui.button("##openPresetFolder", vec2(22, 22)) then os.openInExplorer(Settings.presetsPath) end
    if ui.itemHovered() then ui.setTooltip("Open presets folder") end
    ui.addIcon(ui.Icons.Folder, vec2(13, 13), vec2(0.5, 0.5), nil, vec2(0, 0))

    ui.setNextItemWidth(148)
    savePresetName = ui.inputText("Save preset", savePresetName, ui.InputTextFlags.Placeholder)
    ui.sameLine(0, 4)
    if ui.button("##savePresetBtn", vec2(22, 22)) then
        Settings:savePreset(savePresetName)
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
        if readmeText then
            ui.tabItem("README", function() ui.textWrapped(readmeText) end)
        end
    end)
end

function M.inputDisplayWindow()
    local squareColor = rgbm(table.unpack(Settings.squareColor))
    local circleColor = rgbm(table.unpack(Settings.circleColor))
    local square0pos = vec2(ui.windowWidth() / 2 - (Settings.squareSize + Settings.squareGap) / 2, ui.windowHeight() - Settings.squareGap - Settings.squareSize / 2)
    local square1pos = vec2(ui.windowWidth() / 2 + (Settings.squareSize + Settings.squareGap) / 2, ui.windowHeight() - Settings.squareGap - Settings.squareSize / 2)
    ui.drawRectFilled(square0pos + vec2(-Settings.squareSize / 2, -Settings.squareSize / 2), square0pos + vec2(Settings.squareSize / 2, Settings.squareSize / 2), squareColor)
    ui.drawRectFilled(square1pos + vec2(-Settings.squareSize / 2, -Settings.squareSize / 2), square1pos + vec2(Settings.squareSize / 2, Settings.squareSize / 2), squareColor)
    ui.drawCircleFilled(square0pos + vec2(Input.yaw, -Input.throttle):scale(Settings.squareSize / 2 - Settings.circleRadius), Settings.circleRadius, circleColor)
    ui.drawCircleFilled(square1pos + vec2(Input.roll, -Input.pitch):scale(Settings.squareSize / 2 - Settings.circleRadius), Settings.circleRadius, circleColor)
end

function M.inputDisplaySettingsWindow()
    slider("Square size", "squareSize", 1, 500, 1, 0, "px")
    slider("Square gap", "squareGap", 0, 500, 1, 0, "px")
    ui.text("Square color")
    ui.setNextItemWidth(150)
    local squareColorS = rgbm(table.unpack(Settings.squareColor))
    if ui.colorPicker("##squareColor", squareColorS) then
        Settings.squareColor = { squareColorS.r, squareColorS.g, squareColorS.b, squareColorS.mult }
    end
    local squareOpacity, soChanged = ui.slider('##squareOpacity', squareColorS.mult, 0, 1, "Square opacity: %.2f ")
    if soChanged then
        Settings.squareColor = { squareColorS.r, squareColorS.g, squareColorS.b, squareOpacity }
    end
    slider("Circle radius", "circleRadius", 1, 100, 1, 0, "px")
    ui.text("Circle color")
    ui.setNextItemWidth(150)
    local circleColorS = rgbm(table.unpack(Settings.circleColor))
    if ui.colorPicker("##circleColor", circleColorS) then
        Settings.circleColor = { circleColorS.r, circleColorS.g, circleColorS.b, circleColorS.mult }
    end
    local circleOpacity, coChanged = ui.slider('##circleOpacity', circleColorS.mult, 0, 1, "Circle opacity: %.2f ")
    if coChanged then
        Settings.circleColor = { circleColorS.r, circleColorS.g, circleColorS.b, circleOpacity }
    end
end

return M
