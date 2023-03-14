import ac
import configparser
import math
import os 

config = configparser.ConfigParser()
config.optionxform=str
configDirectory=os.path.join(os.path.dirname(__file__), 'config.ini')
config.read(configDirectory)
defaultConfig = configparser.ConfigParser()
defaultConfig.optionxform=str
defaultConfigDirectory=os.path.join(os.path.dirname(__file__), 'config_defaults.ini')
defaultConfig.read(defaultConfigDirectory)

class AppState:
    prevCamMode = 0
    prevF7state = False
    toggleDrone = False
    confirmReset = False

class Values:
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
    throttleRangeOfMotionIs0to1 = config.getint("FPV input", "throttleRangeOfMotionIs0To1")
    pitchRangeOfMotionIs0to1 = config.getint("FPV input", "pitchRangeOfMotionIs0To1")
    yawRangeOfMotionIs0to1 = config.getint("FPV input", "yawRangeOfMotionIs0To1")
    rollRangeOfMotionIs0to1 = config.getint("FPV input", "rollRangeOfMotionIs0To1")
    linearAcceleration = config.getint("Other", "linearAcceleration")
    pitchRate = config.getint("FPV Betaflight rates", "pitchRate")
    pitchSuper = config.getint("FPV Betaflight rates", "pitchSuper")
    pitchExpo = config.getint("FPV Betaflight rates", "pitchExpo")
    yawRate = config.getint("FPV Betaflight rates", "yawRate")
    yawSuper = config.getint("FPV Betaflight rates", "yawSuper")
    yawExpo = config.getint("FPV Betaflight rates", "yawExpo")
    rollRate = config.getint("FPV Betaflight rates", "rollRate")
    rollSuper = config.getint("FPV Betaflight rates", "rollSuper")
    rollExpo = config.getint("FPV Betaflight rates", "rollExpo")
    batteryCells = math.floor(config.getfloat("FPV settings", "batteryCells"))
    motorKv = config.getint("FPV settings", "motorKv")
    propDiameter = config.getfloat("FPV settings", "propDiameter")
    propPitch = config.getfloat("FPV settings", "propPitch")
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
        if value:
            Values.mode = "acro"
        else:
            Values.mode = "3d"
        config.set("FPV input", "mode", str(Values.mode))
    def changeInputDevice(value): 
        Values.inputDevice = value
        config.set("General input", "inputDevice", str(value))
    def changeBatteryCells(value): 
        Values.batteryCells = value
        config.set("FPV settings", "batteryCells", str(value))
    def changeMotorKv(value): 
        Values.motorKv = value
        config.set("FPV settings", "motorKv", str(value))
    def changePropDiameter(value): 
        Values.propDiameter = value/10
        config.set("FPV settings", "propDiameter", str(value/10))
    def changePropPitch(value): 
        Values.propPitch = value/10
        config.set("FPV settings", "propPitch", str(value/10))
    def changePitchRate(value): 
        Values.pitchRate = value
        config.set("FPV Betaflight rates", "pitchRate", str(value))
    def changePitchSuper(value): 
        Values.pitchSuper = value
        config.set("FPV Betaflight rates", "pitchSuper", str(value))
    def changePitchExpo(value): 
        Values.pitchExpo = value
        config.set("FPV Betaflight rates", "pitchExpo", str(value))
    def changeYawRate(value): 
        Values.yawRate = value
        config.set("FPV Betaflight rates", "yawRate", str(value))
    def changeYawSuper(value): 
        Values.yawSuper = value
        config.set("FPV Betaflight rates", "yawSuper", str(value))
    def changeYawExpo(value): 
        Values.yawExpo = value
        config.set("FPV Betaflight rates", "yawExpo", str(value))
    def changeRollRate(value): 
        Values.rollRate = value
        config.set("FPV Betaflight rates", "rollRate", str(value))
    def changeRollSuper(value): 
        Values.rollSuper = value
        config.set("FPV Betaflight rates", "rollSuper", str(value))
    def changeRollExpo(value): 
        Values.rollExpo = value
        config.set("FPV Betaflight rates", "rollExpo", str(value))
    def changeDroneMass(value): 
        Values.droneMass = value
        config.set("FPV settings", "droneMass", str(value))
    def changeDroneSurfaceArea(value): 
        Values.droneSurfaceArea = value
        config.set("FPV settings", "droneSurfaceArea", str(value))
    def changeMinimalSurfaceAreaCoefficient(value): 
        Values.minimalSurfaceAreaCoefficient = value/100
        config.set("FPV settings", "minimalSurfaceAreaCoefficient", str(value/100))
    def changeGravity(value): 
        Values.gravity = value/100
        config.set("FPV settings", "gravity", str(value/100))
    def changeAirDrag(value): 
        Values.airDrag = value
        config.set("FPV settings", "airDrag", str(value))
    def changeGroundLevel(value): 
        Values.groundLevel = value
        config.set("FPV settings", "groundLevel", str(value))
    def changeCameraAngle(value): 
        Values.cameraAngle = value
        config.set("FPV settings", "cameraAngle", str(value))
    def changeCameraFov(value): 
        Values.cameraFov = value
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

    def resetValues(*args):
        Values.pitchRate = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "pitchRate"), "int")
        Values.pitchSuper = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "pitchSuper"), "int")
        Values.pitchExpo = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "pitchExpo"), "int")
        Values.yawRate = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "yawRate"), "int")
        Values.yawSuper = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "yawSuper"), "int")
        Values.yawExpo = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "yawExpo"), "int")
        Values.rollRate = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "rollRate"), "int")
        Values.rollSuper = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "rollSuper"), "int")
        Values.rollExpo = Values.removeComments(defaultConfig.get("FPV Betaflight rates", "rollExpo"), "int")
        Values.batteryCells = math.floor(Values.removeComments(defaultConfig.get("FPV settings", "batteryCells"), "float"))
        Values.motorKv = Values.removeComments(defaultConfig.get("FPV settings", "motorKv"), "int")
        Values.propDiameter = Values.removeComments(defaultConfig.get("FPV settings", "propDiameter"), "float")
        Values.propPitch = Values.removeComments(defaultConfig.get("FPV settings", "propPitch"), "float")
        Values.cameraAngle = Values.removeComments(defaultConfig.get("FPV settings", "cameraAngle"), "int")
        Values.cameraFov = Values.removeComments(defaultConfig.get("FPV settings", "cameraFov"), "int")
        Values.droneMass = Values.removeComments(defaultConfig.get("FPV settings", "droneMass"), "int")
        Values.airDrag = Values.removeComments(defaultConfig.get("FPV settings", "airDrag"), "int")
        Values.airDensity = Values.removeComments(defaultConfig.get("FPV settings", "airDensity"), "float")
        Values.droneSurfaceArea = Values.removeComments(defaultConfig.get("FPV settings", "droneSurfaceArea"), "int")
        Values.minimalSurfaceAreaCoefficient = Values.removeComments(defaultConfig.get("FPV settings", "minimalSurfaceAreaCoefficient"), "float")
        Values.gravity = Values.removeComments(defaultConfig.get("FPV settings", "gravity"), "float")
        Values.groundLevel = Values.removeComments(defaultConfig.get("FPV settings", "groundLevel"), "int")