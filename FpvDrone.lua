Ui = require("src/ui")
Settings = require("src/settings")
Input = require("src/input")
Drone = require("src/drone")

script.droneUpdate = function(dt) Drone:update(dt) end
script.fpvDroneWindow = Ui.fpvDroneWindow
script.inputDisplayWindow= Ui.inputDisplayWindow
script.inputDisplaySettingsWindow = Ui.inputDisplaySettingsWindow
