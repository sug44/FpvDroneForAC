import ac
import acsys
import math
import values
import controller
# import FPV_Drone

def dot(v1, v2):
    return v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2]

def mag(v1):
    return math.sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2])

density = values.airDensity
position = [0, 0, 0]
velocity = [0, 0, 0]
force = [0, 0, 0]
forwardVector = [0,0,0]
upVector = [0,0,0]
isAsleep = False

def airDrag(density, speed, coefficient, area, minAreaCoeff, vec1, vec2):
    global velocity
    angle = math.degrees(math.acos(dot(vec1,vec2)/(mag(vec1)*mag(vec2))))
    c = abs(-1*(1-minAreaCoeff)/90*angle+(1-minAreaCoeff))+minAreaCoeff # c=1 at 0 and 180 degrees and c=minAreaCoeff at 90 degrees
    # FPV_Drone.console(angle, c, mag(velocity))
    return 0.5*density*speed*abs(speed)*coefficient*area*c

def startDrone(startPos):
    global position
    global velocity
    position = [startPos[0], startPos[1], startPos[2]]
    velocity = [0, 10, 0]
    ac.setCameraMode(6)
    ac.ext_setCameraFov(float(values.cameraFov))
    values.toggleDrone = True

def dronePhysics(deltaT):
    global isAsleep
    global position
    global velocity
    global forwardVector
    global upVector
    air_drag_coefficient = values.airDrag/100
    droneSurfaceArea = values.droneSurfaceArea
    minimalSurfaceAreaCoefficient = values.minimalSurfaceAreaCoefficient
    gravity = values.gravity
    
    if ac.getCameraMode() != 6:
        isAsleep = True
        return

    if isAsleep: # just woke up
        isAsleep = False
        ac.ext_setCameraFov(float(values.cameraFov))

    ac.freeCameraRotatePitch(-math.radians(values.cameraAngle))
    cameraMatrix = ac.ext_getCameraMatrix()
    upVector = [cameraMatrix[4], cameraMatrix[5], cameraMatrix[6]]
    thrustVector = upVector

    force[0] = -airDrag(density, velocity[0], air_drag_coefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, velocity)
    force[1] = -airDrag(density, velocity[1], air_drag_coefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, velocity)
    force[2] = -airDrag(density, velocity[2], air_drag_coefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, velocity)

    acceleration = [force[0]/values.droneMass, force[1]/values.droneMass, force[2]/values.droneMass]

    velocity[0] += (thrustVector[0]*controller.throttle*values.throttleAcceleration + acceleration[0]) * deltaT
    velocity[1] += (thrustVector[1]*controller.throttle*values.throttleAcceleration + acceleration[1] - gravity) * deltaT
    velocity[2] += (thrustVector[2]*controller.throttle*values.throttleAcceleration + acceleration[2]) * deltaT

    position[0] += velocity[0]*deltaT
    position[1] += velocity[1]*deltaT
    position[2] += velocity[2]*deltaT

    if position[1] < values.groundLevel+0.1:
        position[1] = values.groundLevel+0.1
        velocity[1] = 0

    ac.ext_setCameraPosition(tuple(position))

    ac.freeCameraRotatePitch(math.radians(controller.pitch*-1)*deltaT)
    ac.freeCameraRotateHeading(math.radians(controller.yaw*-1)*deltaT)
    ac.freeCameraRotateRoll(math.radians(controller.roll*-1)*deltaT)
    ac.freeCameraRotatePitch(math.radians(values.cameraAngle))
