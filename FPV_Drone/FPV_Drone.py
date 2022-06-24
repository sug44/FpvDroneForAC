import ac 
import values
from values import AppState, Values
import controller
import drone
from drone import DroneState

def console(*args):
  string = ""
  for arg in args:
    if type(arg) == float:
      string += str("{:.2f}".format(arg))
    else:
      string += str(arg) + " "
  ac.console(string)

def addSlider(label, app, pos, size, value, range, onChangeFunction):
  slider = ac.addSpinner(app,label)
  ac.setPosition(slider, pos[0], pos[1])
  ac.setSize(slider, size[0], size[1])
  ac.setRange(slider, range[0], range[1])
  ac.setValue(slider, value)
  ac.addOnValueChangeListener(slider, onChangeFunction)
  return slider

def addButton(label, app, pos, size, onClickFunction, *args):
  button = ac.addButton(app, label)
  ac.setPosition(button, pos[0], pos[1])
  ac.setSize(button, size[0], size[1])
  ac.addOnClickedListener(button, onClickFunction)
  if args:
    ac.setFontSize(button, args[0])
  return button

def addLabel(labelName, app, pos, size, *args):
  label = ac.addLabel(app, labelName)
  ac.setPosition(label, pos[0], pos[1])
  ac.setSize(label, size[0], size[1])
  if args:
    ac.setFontSize(label, args[0])
  return label

def onOffFunction(*args):
  if AppState.toggleDrone:
    AppState.toggleDrone = False
    if ac.getCameraMode() != AppState.prevCamMode:
      ac.setCameraMode(AppState.prevCamMode)
  else:
    camPos = ac.ext_getCameraPosition()
    drone.startDrone(camPos)

def onF7Down():
  if ac.getCameraMode() != AppState.prevCamMode:
    ac.setCameraMode(AppState.prevCamMode)
  if ac.ext_isAltPressed():
    onOffFunction()
  else:
    if not AppState.toggleDrone:
      onOffFunction()
    else:
      ac.setCameraMode(6)

class UIElements:
  def draw(app):
    UIElements.resetButton = addButton("Reset settings", app, [190, 10], [80, 20], resetSettings, 13)
    UIElements.onOffButton = addButton("On/Off", app, [10, 50], [80, 20], onOffFunction)
    UIElements.modeSlider = addSlider("3D/Acro mode", app, [100, 50], [80,20], 1 if Values.mode=="acro" else 0, [0,1], Values.changeMode)
    UIElements.inputSlider = addSlider("Input device", app, [190, 50], [80,20], Values.inputDevice, [0,9], Values.changeInputDevice)
    UIElements.throttleAccelerationSlider = addSlider("Throttle accel", app, [10, 95], [80,20], Values.throttleAcceleration, [0,100], Values.changeThrottleAcceleration)
    UIElements.airDragSlider = addSlider("Air drag", app, [100, 95], [80,20], Values.airDrag, [0,100], Values.changeAirDrag)
    UIElements.droneMassSlider = addSlider("Drone mass", app, [190, 95], [80,20], Values.droneMass, [1,5000], Values.changeDroneMass)
    UIElements.droneSurfaceAreaSlider = addSlider("SurfArea", app, [10, 140], [80,20], Values.droneSurfaceArea, [0,500], Values.changeDroneSurfaceArea)
    UIElements.minimalSurfaceAreaCoefficientSlider = addSlider("MinSurfAreaCoeff", app, [100, 140], [80,20], Values.minimalSurfaceAreaCoefficient*100, [0,100], Values.changeMinimalSurfaceAreaCoefficient)
    UIElements.gravitySlider = addSlider("Gravity", app, [190, 140], [80,20], Values.gravity*100, [-3000,3000], Values.changeGravity)
    UIElements.cameraAngleSlider = addSlider("Camera angle", app, [10, 185], [80, 20], Values.cameraAngle, [0,60], Values.changeCameraAngle)
    UIElements.cameraFovSlider = addSlider("Camera fov", app, [100, 185], [80,20], Values.cameraFov, [10,150], Values.changeCameraFov)
    UIElements.groundLevelSlider = addSlider("Ground level", app, [190, 185], [80,20], Values.groundLevel, [-1000,1000], Values.changeGroundLevel)
    UIElements.pitchRateSlider = addSlider("Pitch rate", app, [10, 230], [80,20], Values.pitchRate, [0,300], Values.changePitchRate)
    UIElements.pitchSuperSlider = addSlider("Pitch super", app, [10, 275], [80,20], Values.pitchSuper, [0,99], Values.changePitchSuper)
    UIElements.pitchExpoSlider = addSlider("Pitch expo", app, [10, 320], [80,20], Values.pitchExpo, [0,100], Values.changePitchExpo)
    UIElements.yawRateSlider = addSlider("Yaw rate", app, [100, 230], [80,20], Values.yawRate, [0,300], Values.changeYawRate)
    UIElements.yawSuperSlider = addSlider("Yaw super", app, [100, 275], [80,20], Values.yawSuper, [0,99], Values.changeYawSuper)
    UIElements.yawExpoSlider = addSlider("Yaw expo", app, [100, 320], [80,20], Values.yawExpo, [0,100], Values.changeYawExpo)
    UIElements.rollRateSlider = addSlider("Roll rate", app, [190, 230], [80,20], Values.rollRate, [0,300], Values.changeRollRate)
    UIElements.rollSuperSlider = addSlider("Roll super", app, [190, 275], [80,20], Values.rollSuper, [0,99], Values.changeRollSuper)
    UIElements.rollExpoSlider = addSlider("Roll expo", app, [190, 320], [80,20], Values.rollExpo, [0,100], Values.changeRollExpo)
    UIElements.droneLabel = addLabel("Drone is off", app, [15, 31], [0,0], 13)
    UIElements.asleepLabel = addLabel("", app, [10, 7], [0,0])


def acMain(ac_version):
  app = ac.newApp("FPV Drone")
  ac.setIconPosition(app, 120, 0)
  ac.setTitle(app, "")
  ac.setSize(app, 280, 350)

  UIElements.draw(app)  

  return "FPV Drone"

def acUpdate(deltaT):
  controller.getInput()

  camMode = ac.getCameraMode()
  if camMode != 6:
    AppState.prevCamMode = camMode

  if AppState.toggleDrone:
    drone.dronePhysics(deltaT)
    ac.setText(UIElements.droneLabel, "Drone is on") 
    if DroneState.isAsleep:
      ac.setText(UIElements.asleepLabel, "(Asleep)")
    else:
      ac.setText(UIElements.asleepLabel, "")
  else:
    ac.setText(UIElements.droneLabel, "Drone is off")
    ac.setText(UIElements.asleepLabel, "")

  if ac.ext_isButtonPressed(118) != AppState.prevF7state: #118 - F7
    if AppState.prevF7state == False: # on key down
      onF7Down()
    AppState.prevF7state = not AppState.prevF7state

def acShutdown(*args):
  values.config.write(open(values.configDirectory, 'w'))

def resetSettings(*args):
  if not AppState.confirmReset:
    ac.setText(UIElements.resetButton, "Confirm reset")
    AppState.confirmReset = True
    return
  if AppState.confirmReset:
    AppState.confirmReset = False
    ac.setText(UIElements.resetButton, "Reset settings")
    Values.resetValues()
    ac.setValue(UIElements.throttleAccelerationSlider, Values.throttleAcceleration)
    ac.setValue(UIElements.airDragSlider, Values.airDrag)
    ac.setValue(UIElements.droneMassSlider, Values.droneMass)
    ac.setValue(UIElements.droneSurfaceAreaSlider, Values.droneSurfaceArea)
    ac.setValue(UIElements.minimalSurfaceAreaCoefficientSlider, Values.minimalSurfaceAreaCoefficient*100)
    ac.setValue(UIElements.gravitySlider, Values.gravity*100)
    ac.setValue(UIElements.cameraAngleSlider, Values.cameraAngle)
    ac.setValue(UIElements.cameraFovSlider, Values.cameraFov)
    ac.setValue(UIElements.groundLevelSlider, Values.groundLevel)
    ac.setValue(UIElements.pitchRateSlider, Values.pitchRate)
    ac.setValue(UIElements.pitchSuperSlider, Values.pitchSuper)
    ac.setValue(UIElements.pitchExpoSlider, Values.pitchExpo)
    ac.setValue(UIElements.yawRateSlider, Values.yawRate)
    ac.setValue(UIElements.yawSuperSlider, Values.yawSuper)
    ac.setValue(UIElements.yawExpoSlider, Values.yawExpo)
    ac.setValue(UIElements.rollRateSlider, Values.rollRate)
    ac.setValue(UIElements.rollSuperSlider, Values.rollSuper)
    ac.setValue(UIElements.rollExpoSlider, Values.rollExpo)