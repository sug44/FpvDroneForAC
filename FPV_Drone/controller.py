import ac
import acsys
import values

throttle = 0
pitch = 0
yaw = 0
roll = 0

throttle_axis = values.throttleAxis
pitch_axis = values.pitchAxis
yaw_axis = values.yawAxis
roll_axis = values.rollAxis
invert_throttle = values.invertThrottle
invert_pitch = values.invertPitch
invert_yaw = values.invertYaw
invert_roll = values.invertRoll

def betaflightRates(x, a, b, c): #a-rate, b-super, c-expo
    p = 1/(1-(abs(x)*b))
    q = (x**4*c)+abs(x)*(1-c)
    r=200*q*a
    t=r*p
    if x<0: t*=-1
    return t

def getInput():
    global throttle
    global pitch
    global yaw
    global roll
    throttle = ac.ext_getJoystickAxisValue(values.inputDevice, throttle_axis)
    if invert_throttle: throttle *= -1
    if values.mode == "acro":
        throttle = (throttle+1)/2
    pitch = betaflightRates(ac.ext_getJoystickAxisValue(values.inputDevice, pitch_axis), values.pitchRate/100, values.pitchSuper/100, values.pitchExpo/100)
    yaw = betaflightRates(ac.ext_getJoystickAxisValue(values.inputDevice, yaw_axis), values.yawRate/100, values.yawSuper/100, values.yawExpo/100)
    roll = betaflightRates(ac.ext_getJoystickAxisValue(values.inputDevice, roll_axis), values.rollRate/100, values.rollSuper/100, values.rollExpo/100)
    if invert_pitch: pitch *= -1
    if invert_yaw: yaw *= -1
    if invert_roll: roll *= -1
