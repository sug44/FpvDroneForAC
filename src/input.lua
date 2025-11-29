local M = {
    inputDevice = -1,
    throttle = 0,
    roll = 0,
    pitch = 0,
    yaw = 0,
    buttons = {
        toggleSleepButton = {},
        toggleDroneButton = {},
        disableAirDragAndFrictionButton = {},
        disableCollisionButton = {},
        savePositionButton = {},
        teleportToPositionButton = {},
    }
}
setmetatable(M, { __index = M.buttons })

function M:updateInputDevice()
    self.inputDevice = tonumber(ac.getJoystickIndexByInstanceGUID(Settings.inputDeviceGUID)) or -1
    -- if cant find device update device guid by looking for a saved device name
    -- this makes input presets work right away, provided there is a device with the name specified in the preset
    if self.inputDevice == -1 then
        for i = 0, ac.getJoystickCount()-1 do
            if ac.getJoystickName(i) == Settings.inputDeviceName then
                self.inputDevice = i
                Settings.inputDeviceGUID = ac.getJoystickInstanceGUID(i)
                break
            end
        end
    end
end

function M:update()
    self.throttle = ac.getJoystickAxisValue(self.inputDevice, Settings.throttleAxis)
    self.roll = ac.getJoystickAxisValue(self.inputDevice, Settings.rollAxis)
    self.pitch = ac.getJoystickAxisValue(self.inputDevice, Settings.pitchAxis)
    self.yaw = ac.getJoystickAxisValue(self.inputDevice, Settings.yawAxis)
    self.throttle = (2 * self.throttle - (Settings.throttleFrom + Settings.throttleTo)) / (Settings.throttleTo - Settings.throttleFrom)
    self.roll = (2 * self.roll - (Settings.rollFrom + Settings.rollTo)) / (Settings.rollTo - Settings.rollFrom)
    self.pitch = (2 * self.pitch - (Settings.pitchFrom + Settings.pitchTo)) / (Settings.pitchTo - Settings.pitchFrom)
    self.yaw = (2 * self.yaw - (Settings.yawFrom + Settings.yawTo)) / (Settings.yawTo - Settings.yawFrom)
    if Settings.invertThrottle then self.throttle = self.throttle * -1 end
    if Settings.invertRoll then self.roll = self.roll * -1 end
    if Settings.invertPitch then self.pitch = self.pitch * -1 end
    if Settings.invertYaw then self.yaw = self.yaw * -1 end

    for button, state in pairs(self.buttons) do
        local buttonSettings = Settings[button]

        local buttonDown
        if buttonSettings.type == "keyboard" then
            buttonDown = ac.isKeyDown(buttonSettings.key)
        elseif buttonSettings.type == "controller" then
            buttonDown = ac.isJoystickButtonPressed(self.inputDevice, buttonSettings.key)
        end

        state.pressed = buttonDown and not state.down
        state.down = buttonDown
    end
end

return M
