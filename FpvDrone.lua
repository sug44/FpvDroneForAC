Ui = require("src/ui")
Settings = require("src/settings")
Input = require("src/input")
Drone = require("src/drone")

script.droneUpdate = function(dt) Drone:update(dt) end
script.fpvDroneWindow = Ui.fpvDroneWindow
script.inputDisplayWindow= Ui.inputDisplayWindow
script.inputDisplaySettingsWindow = Ui.inputDisplaySettingsWindow


-- create presets with filled input settings for common devices if they dont exist
for name, changes in pairs({
    dualshock4 = {
        inputDeviceName = "Wireless Controller",
        mode3d = true,
        throttleAxis = 1,
        yawAxis = 0,
        pitchAxis = 5,
        rollAxis = 2,
        invertThrottle = true,
        invertPitch = true,
    },
    xbox360 = {
        inputDeviceName = "Controller (XBOX 360 For Windows)",
        mode3d = true,
        throttleAxis = 1,
        yawAxis = 0,
        pitchAxis = 4,
        rollAxis = 3,
        invertThrottle = true,
        invertPitch = true,
    }
}) do
    local newPresetPath = Settings.presetsPath..name..".json"

    if not io.fileExists(newPresetPath) then
        local defaultSettings = JSON.parse(io.load(Settings.presetsPath.."defaultNoInput.json"))
        if defaultSettings then
            for k,v in pairs(changes) do
                defaultSettings[k] = v
            end
            io.save(newPresetPath, JSON.stringify(defaultSettings), true)
        end
    end
end
