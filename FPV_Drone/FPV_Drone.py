import ac 
import acsys
import values
import controller
import drone

def console(val1, val2, val3):
  ac.console(str("{:.2f}".format(val1))+" "+str("{:.2f}".format(val2))+" "+str("{:.2f}".format(val3)))

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

prevCamMode = 0
prevF7state = False
resetButton = 0
confirmReset = False
droneLabel = 0
asleepLabel = 0
throttleAccelerationSlider = 0
airDragSlider = 0
droneMassSlider = 0
droneSurfaceAreaSlider = 0
minimalSurfaceAreaCoefficientSlider = 0
gravitySlider = 0
cameraAngleSlider = 0
cameraFovSlider = 0
groundLevelSlider = 0
pitchRateSlider = 0
pitchSuperSlider = 0
pitchExpoSlider = 0
yawRateSlider = 0
yawSuperSlider = 0
yawExpoSlider = 0
rollRateSlider = 0
rollSuperSlider = 0
rollExpoSlider = 0

def onOffFunction(*args):
  global prevCamMode
  if values.toggleDrone:
    values.toggleDrone = False
    if ac.getCameraMode() != prevCamMode:
      ac.setCameraMode(prevCamMode)
  else:
    camPos = ac.ext_getCameraPosition()
    drone.startDrone(camPos)

def onF7Down():
  global prevCamMode
  if ac.getCameraMode() != prevCamMode:
    ac.setCameraMode(prevCamMode)
  if ac.ext_isAltPressed():
    onOffFunction()
  else:
    if not values.toggleDrone:
      onOffFunction()
    else:
      ac.setCameraMode(6)

def acMain(ac_version):
  global droneLabel
  global asleepLabel
  global resetButton
  global throttleAccelerationSlider
  global airDragSlider
  global droneMassSlider
  global droneSurfaceAreaSlider
  global minimalSurfaceAreaCoefficientSlider
  global gravitySlider
  global cameraAngleSlider
  global cameraFovSlider
  global groundLevelSlider
  global pitchRateSlider
  global pitchSuperSlider
  global pitchExpoSlider
  global yawRateSlider
  global yawSuperSlider
  global yawExpoSlider
  global rollRateSlider
  global rollSuperSlider
  global rollExpoSlider

  app = ac.newApp("FPV Drone")
  ac.setIconPosition(app, 120, 0)
  ac.setTitle(app, "")
  ac.setSize(app, 280, 350)

  resetButton = addButton("Reset settings", app, [190, 10], [80, 20], resetSettings, 13)
  addButton("On/Off", app, [10, 50], [80, 20], onOffFunction)
  addSlider("3D/Acro mode", app, [100, 50], [80,20], 1 if values.mode=="acro" else 0, [0,1], values.changeMode)
  addSlider("Input device", app, [190, 50], [80,20], values.inputDevice, [0,9], values.changeInputDevice)
  throttleAccelerationSlider = addSlider("Throttle accel", app, [10, 95], [80,20], values.throttleAcceleration, [0,100], values.changeThrottleAcceleration)
  airDragSlider = addSlider("Air drag", app, [100, 95], [80,20], values.airDrag, [0,100], values.changeAirDrag)
  droneMassSlider = addSlider("Drone mass", app, [190, 95], [80,20], values.droneMass, [1,5000], values.changeDroneMass)
  droneSurfaceAreaSlider = addSlider("SurfArea", app, [10, 140], [80,20], values.droneSurfaceArea, [0,500], values.changeDroneSurfaceArea)
  minimalSurfaceAreaCoefficientSlider = addSlider("MinSurfAreaCoeff", app, [100, 140], [80,20], values.minimalSurfaceAreaCoefficient*100, [0,100], values.changeMinimalSurfaceAreaCoefficient)
  gravitySlider = addSlider("Gravity", app, [190, 140], [80,20], values.gravity*100, [-3000,3000], values.changeGravity)
  cameraAngleSlider = addSlider("Camera angle", app, [10, 185], [80, 20], values.cameraAngle, [0,60], values.changeCameraAngle)
  cameraFovSlider = addSlider("Camera fov", app, [100, 185], [80,20], values.cameraFov, [10,150], values.changeCameraFov)
  groundLevelSlider = addSlider("Ground level", app, [190, 185], [80,20], values.groundLevel, [-1000,1000], values.changeGroundLevel)
  pitchRateSlider = addSlider("Pitch rate", app, [10, 230], [80,20], values.pitchRate, [0,300], values.changePitchRate)
  pitchSuperSlider = addSlider("Pitch super", app, [10, 275], [80,20], values.pitchSuper, [0,99], values.changePitchSuper)
  pitchExpoSlider = addSlider("Pitch expo", app, [10, 320], [80,20], values.pitchExpo, [0,100], values.changePitchExpo)
  yawRateSlider = addSlider("Yaw rate", app, [100, 230], [80,20], values.yawRate, [0,300], values.changeYawRate)
  yawSuperSlider = addSlider("Yaw super", app, [100, 275], [80,20], values.yawSuper, [0,99], values.changeYawSuper)
  yawExpoSlider = addSlider("Yaw expo", app, [100, 320], [80,20], values.yawExpo, [0,100], values.changeYawExpo)
  rollRateSlider = addSlider("Roll rate", app, [190, 230], [80,20], values.rollRate, [0,300], values.changeRollRate)
  rollSuperSlider = addSlider("Roll super", app, [190, 275], [80,20], values.rollSuper, [0,99], values.changeRollSuper)
  rollExpoSlider = addSlider("Roll expo", app, [190, 320], [80,20], values.rollExpo, [0,100], values.changeRollExpo)
  
  droneLabel = addLabel("Drone is off", app, [15, 31], [0,0], 13)
  asleepLabel = addLabel("", app, [10, 7], [0,0])
  return "FPV Drone"

def acUpdate(deltaT):
  global prevCamMode
  global prevF7state
  global droneLabel
  global asleepLabel
  controller.getInput()
  camMode = ac.getCameraMode()
  if camMode != 6:
    prevCamMode = camMode

  if values.toggleDrone:
    drone.dronePhysics(deltaT)
    ac.setText(droneLabel, "Drone is on") 
    if drone.isAsleep:
      ac.setText(asleepLabel, "(Asleep)")
    else:
      ac.setText(asleepLabel, "")
  else:
    ac.setText(droneLabel, "Drone is off")
    ac.setText(asleepLabel, "")

  if ac.ext_isButtonPressed(118) != prevF7state: #118 - F7
    if prevF7state == False: # on key down
      onF7Down()
    prevF7state = not prevF7state

def acShutdown(*args):
  values.config.write(open(values.configDirectory, 'w'))

def resetSettings(*args):
  global resetButton
  global confirmReset
  if not confirmReset:
    ac.setText(resetButton, "Confirm reset")
    confirmReset = True
    return
  if confirmReset:
    confirmReset = False
    ac.setText(resetButton, "Reset settings")
    values.resetFpvValues()
    global throttleAccelerationSlider
    global airDragSlider
    global droneMassSlider
    global droneSurfaceAreaSlider
    global minimalSurfaceAreaCoefficientSlider
    global gravitySlider
    global cameraAngleSlider
    global cameraFovSlider
    global groundLevelSlider
    global pitchRateSlider
    global pitchSuperSlider
    global pitchExpoSlider
    global yawRateSlider
    global yawSuperSlider
    global yawExpoSlider
    global rollRateSlider
    global rollSuperSlider
    global rollExpoSlider
    ac.setValue(throttleAccelerationSlider, values.throttleAcceleration)
    ac.setValue(airDragSlider, values.airDrag)
    ac.setValue(droneMassSlider, values.droneMass)
    ac.setValue(droneSurfaceAreaSlider, values.droneSurfaceArea)
    ac.setValue(minimalSurfaceAreaCoefficientSlider, values.minimalSurfaceAreaCoefficient*100)
    ac.setValue(gravitySlider, values.gravity*100)
    ac.setValue(cameraAngleSlider, values.cameraAngle)
    ac.setValue(cameraFovSlider, values.cameraFov)
    ac.setValue(groundLevelSlider, values.groundLevel)
    ac.setValue(pitchRateSlider, values.pitchRate)
    ac.setValue(pitchSuperSlider, values.pitchSuper)
    ac.setValue(pitchExpoSlider, values.pitchExpo)
    ac.setValue(yawRateSlider, values.yawRate)
    ac.setValue(yawSuperSlider, values.yawSuper)
    ac.setValue(yawExpoSlider, values.yawExpo)
    ac.setValue(rollRateSlider, values.rollRate)
    ac.setValue(rollSuperSlider, values.rollSuper)
    ac.setValue(rollExpoSlider, values.rollExpo)