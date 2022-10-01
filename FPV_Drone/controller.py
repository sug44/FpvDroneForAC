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
    Input.throttle = ac.ext_getJoystickAxisValue(Values.inputDevice, Values.throttleAxis)
    if Values.invertThrottle: Input.throttle *= -1
    if Values.throttleRangeOfMotionIs0to1:
        Input.throttle = Input.throttle*2-1
    if Values.mode == "acro":
        Input.throttle = (Input.throttle+1)/2
    Input.pitch = betaflightRates(ac.ext_getJoystickAxisValue(Values.inputDevice, Values.pitchAxis), Values.pitchRate/100, Values.pitchSuper/100, Values.pitchExpo/100)
    Input.yaw = betaflightRates(ac.ext_getJoystickAxisValue(Values.inputDevice, Values.yawAxis), Values.yawRate/100, Values.yawSuper/100, Values.yawExpo/100)
    Input.roll = betaflightRates(ac.ext_getJoystickAxisValue(Values.inputDevice, Values.rollAxis), Values.rollRate/100, Values.rollSuper/100, Values.rollExpo/100)
    if Values.invertPitch: Input.pitch *= -1
    if Values.invertYaw: Input.yaw *= -1
    if Values.invertRoll: Input.roll *= -1
