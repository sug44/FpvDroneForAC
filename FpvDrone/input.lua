require("settings")

SInput = {
  throttle = 0,
  roll = 0,
  pitch = 0,
  yaw = 0,
}

function SInput:update()
  self.throttle = SSettings.throttleAxis == -1 and -1 or
      ac.getJoystickAxisValue(SSettings.inputDevice, SSettings.throttleAxis)
  self.roll = ac.getJoystickAxisValue(SSettings.inputDevice, SSettings.rollAxis)
  self.pitch = ac.getJoystickAxisValue(SSettings.inputDevice, SSettings.pitchAxis)
  self.yaw = ac.getJoystickAxisValue(SSettings.inputDevice, SSettings.yawAxis)
  self.throttle = (2 * self.throttle - (SSettings.throttleFrom + SSettings.throttleTo)) /
      (SSettings.throttleTo - SSettings.throttleFrom)
  self.roll = (2 * self.roll - (SSettings.rollFrom + SSettings.rollTo)) / (SSettings.rollTo - SSettings.rollFrom)
  self.pitch = (2 * self.pitch - (SSettings.pitchFrom + SSettings.pitchTo)) / (SSettings.pitchTo - SSettings.pitchFrom)
  self.yaw = (2 * self.yaw - (SSettings.yawFrom + SSettings.yawTo)) / (SSettings.yawTo - SSettings.yawFrom)
  if SSettings.invertThrottle then self.throttle = self.throttle * -1 end
  if SSettings.invertRoll then self.roll = self.roll * -1 end
  if SSettings.invertPitch then self.pitch = self.pitch * -1 end
  if SSettings.invertYaw then self.yaw = self.yaw * -1 end
end
