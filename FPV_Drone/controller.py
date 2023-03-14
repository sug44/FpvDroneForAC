import ac
from values import Values

class Input:
    throttle = 0
    pitch = 0
    yaw = 0
    roll = 0

def betaflightRates(x, a, b, c): #a-rate, b-super, c-expo
    p = 1/(1-(abs(x)*b))
    q = (x**4*c)+abs(x)*(1-c)
    r=200*q*a
    t=r*p
    if x<0: t*=-1
    return t

def getInput():
    throttleAxisValue = ac.ext_getJoystickAxisValue(Values.inputDevice, Values.throttleAxis)
    pitchAxisValue = ac.ext_getJoystickAxisValue(Values.inputDevice, Values.pitchAxis)
    yawAxisValue = ac.ext_getJoystickAxisValue(Values.inputDevice, Values.yawAxis)
    rollAxisValue = ac.ext_getJoystickAxisValue(Values.inputDevice, Values.rollAxis)
    if Values.throttleRangeOfMotionIs0to1: throttleAxisValue = throttleAxisValue*2-1
    if Values.pitchRangeOfMotionIs0to1: pitchAxisValue = pitchAxisValue*2-1
    if Values.yawRangeOfMotionIs0to1: yawAxisValue = yawAxisValue*2-1
    if Values.rollRangeOfMotionIs0to1: rollAxisValue = rollAxisValue*2-1
    if Values.invertThrottle: throttleAxisValue *= -1
    if Values.invertPitch: pitchAxisValue *= -1
    if Values.invertYaw: yawAxisValue *= -1
    if Values.invertRoll: rollAxisValue *= -1
    if Values.mode == "acro": throttleAxisValue = (throttleAxisValue+1)/2
    Input.throttle = throttleAxisValue
    Input.pitch = betaflightRates(pitchAxisValue, Values.pitchRate/100, Values.pitchSuper/100, Values.pitchExpo/100)
    Input.yaw = betaflightRates(yawAxisValue, Values.yawRate/100, Values.yawSuper/100, Values.yawExpo/100)
    Input.roll = betaflightRates(rollAxisValue, Values.rollRate/100, Values.rollSuper/100, Values.rollExpo/100)
