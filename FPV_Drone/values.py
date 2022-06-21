import ac
import acsys
import configparser
import os 

config = configparser.ConfigParser()
config.optionxform=str
configDirectory=os.path.join(os.path.dirname(__file__), 'config.ini')
config.read(configDirectory)
defaultConfig = configparser.ConfigParser()
defaultConfig.optionxform=str
defaultConfigDirectory=os.path.join(os.path.dirname(__file__), 'config_defaults.ini')
defaultConfig.read(defaultConfigDirectory)

toggleDrone = False

inputDevice = config.getint("General input", "inputDevice")

throttleAxis = config.getint("FPV input", "throttleAxis")-1
pitchAxis = config.getint("FPV input", "pitchAxis")-1
yawAxis = config.getint("FPV input", "yawAxis")-1
rollAxis = config.getint("FPV input", "rollAxis")-1
mode = config.get("FPV input", "mode")
invertThrottle = config.getint("FPV input", "invertThrottle")
invertPitch = config.getint("FPV input", "invertPitch")
invertYaw = config.getint("FPV input", "invertYaw")
invertRoll = config.getint("FPV input", "invertRoll")

pitchRate = config.getint("FPV Betaflight rates", "pitchRate")
pitchSuper = config.getint("FPV Betaflight rates", "pitchSuper")
pitchExpo = config.getint("FPV Betaflight rates", "pitchExpo")
yawRate = config.getint("FPV Betaflight rates", "yawRate")
yawSuper = config.getint("FPV Betaflight rates", "yawSuper")
yawExpo = config.getint("FPV Betaflight rates", "yawExpo")
rollRate = config.getint("FPV Betaflight rates", "rollRate")
rollSuper = config.getint("FPV Betaflight rates", "rollSuper")
rollExpo = config.getint("FPV Betaflight rates", "rollExpo")

throttleAcceleration = config.getint("FPV settings", "throttleAcceleration")
cameraAngle = config.getint("FPV settings", "cameraAngle")
cameraFov = config.getint("FPV settings", "cameraFov")
droneMass = config.getint("FPV settings", "droneMass")
airDrag = config.getint("FPV settings", "airDrag")
airDensity = config.getfloat("FPV settings", "airDensity")
droneSurfaceArea = config.getint("FPV settings", "droneSurfaceArea")
minimalSurfaceAreaCoefficient = config.getfloat("FPV settings", "minimalSurfaceAreaCoefficient")
gravity = config.getfloat("FPV settings", "gravity")
groundLevel = config.getint("FPV settings", "groundLevel")

def changeMode(value): 
    global mode
    if value:
        mode = "acro"
    else:
        mode = "3d"
    config.set("FPV input", "mode", str(mode))
def changeInputDevice(value): 
    global inputDevice
    inputDevice = value
    config.set("General input", "inputDevice", str(value))
def changeThrottleAcceleration(value): 
    global throttleAcceleration
    throttleAcceleration = value
    config.set("FPV settings", "throttleAcceleration", str(value))
def changePitchRate(value): 
    global pitchRate
    pitchRate = value
    config.set("FPV Betaflight rates", "pitchRate", str(value))
def changePitchSuper(value): 
    global pitchSuper
    pitchSuper = value
    config.set("FPV Betaflight rates", "pitchSuper", str(value))
def changePitchExpo(value): 
    global pitchExpo
    pitchExpo = value
    config.set("FPV Betaflight rates", "pitchExpo", str(value))
def changeYawRate(value): 
    global yawRate
    yawRate = value
    config.set("FPV Betaflight rates", "yawRate", str(value))
def changeYawSuper(value): 
    global yawSuper
    yawSuper = value
    config.set("FPV Betaflight rates", "yawSuper", str(value))
def changeYawExpo(value): 
    global yawExpo
    yawExpo = value
    config.set("FPV Betaflight rates", "yawExpo", str(value))
def changeRollRate(value): 
    global rollRate
    rollRate = value
    config.set("FPV Betaflight rates", "rollRate", str(value))
def changeRollSuper(value): 
    global rollSuper
    rollSuper = value
    config.set("FPV Betaflight rates", "rollSuper", str(value))
def changeRollExpo(value): 
    global rollExpo
    rollExpo = value
    config.set("FPV Betaflight rates", "rollExpo", str(value))
def changeDroneMass(value): 
    global droneMass
    droneMass = value
    config.set("FPV settings", "droneMass", str(value))
def changeDroneSurfaceArea(value): 
    global droneSurfaceArea
    droneSurfaceArea = value
    config.set("FPV settings", "droneSurfaceArea", str(value))
def changeMinimalSurfaceAreaCoefficient(value): 
    global minimalSurfaceAreaCoefficient
    minimalSurfaceAreaCoefficient = value/100
    config.set("FPV settings", "minimalSurfaceAreaCoefficient", str(value/100))
def changeGravity(value): 
    global gravity
    gravity = value/100
    config.set("FPV settings", "gravity", str(value/100))
def changeAirDrag(value): 
    global airDrag
    airDrag = value
    config.set("FPV settings", "airDrag", str(value))
def changeGroundLevel(value): 
    global groundLevel
    groundLevel = value
    config.set("FPV settings", "groundLevel", str(value))
def changeCameraAngle(value): 
    global cameraAngle
    cameraAngle = value
    config.set("FPV settings", "cameraAngle", str(value))
def changeCameraFov(value): 
    global cameraFov
    cameraFov = value
    ac.ext_setCameraFov(float(value))
    config.set("FPV settings", "cameraFov", str(value))

def removeComments(string, type):
    if type == "int":
        return int(string.split(";")[0])
    if type == "float":
        return float(string.split(";")[0])
    if type == "str":
        return str(string.split(";")[0])
    return -1

def resetFpvValues(*args):
    global defaultConfig
    global pitchRate
    global pitchSuper
    global pitchExpo
    global yawRate
    global yawSuper
    global yawExpo
    global rollRate
    global rollSuper
    global rollExpo
    global throttleAcceleration
    global cameraAngle
    global cameraFov
    global droneMass
    global airDrag
    global airDensity
    global droneSurfaceArea
    global minimalSurfaceAreaCoefficient
    global gravity
    global groundLevel

    pitchRate = removeComments(defaultConfig.get("FPV Betaflight rates", "pitchRate"), "int")
    pitchSuper = removeComments(defaultConfig.get("FPV Betaflight rates", "pitchSuper"), "int")
    pitchExpo = removeComments(defaultConfig.get("FPV Betaflight rates", "pitchExpo"), "int")
    yawRate = removeComments(defaultConfig.get("FPV Betaflight rates", "yawRate"), "int")
    yawSuper = removeComments(defaultConfig.get("FPV Betaflight rates", "yawSuper"), "int")
    yawExpo = removeComments(defaultConfig.get("FPV Betaflight rates", "yawExpo"), "int")
    rollRate = removeComments(defaultConfig.get("FPV Betaflight rates", "rollRate"), "int")
    rollSuper = removeComments(defaultConfig.get("FPV Betaflight rates", "rollSuper"), "int")
    rollExpo = removeComments(defaultConfig.get("FPV Betaflight rates", "rollExpo"), "int")
    throttleAcceleration = removeComments(defaultConfig.get("FPV settings", "throttleAcceleration"), "int")
    cameraAngle = removeComments(defaultConfig.get("FPV settings", "cameraAngle"), "int")
    cameraFov = removeComments(defaultConfig.get("FPV settings", "cameraFov"), "int")
    droneMass = removeComments(defaultConfig.get("FPV settings", "droneMass"), "int")
    airDrag = removeComments(defaultConfig.get("FPV settings", "airDrag"), "int")
    airDensity = removeComments(defaultConfig.get("FPV settings", "airDensity"), "float")
    droneSurfaceArea = removeComments(defaultConfig.get("FPV settings", "droneSurfaceArea"), "int")
    minimalSurfaceAreaCoefficient = removeComments(defaultConfig.get("FPV settings", "minimalSurfaceAreaCoefficient"), "float")
    gravity = removeComments(defaultConfig.get("FPV settings", "gravity"), "float")
    groundLevel = removeComments(defaultConfig.get("FPV settings", "groundLevel"), "int")