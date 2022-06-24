import ac
import math
from values import AppState, Values
from controller import Input
# import FPV_Drone

def dot(v1, v2):
    return v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2]

def mag(v1):
    return math.sqrt(v1[0]*v1[0]+v1[1]*v1[1]+v1[2]*v1[2])

class DroneState:
    position = [0, 0, 0]
    velocity = [0, 0, 0]
    force = [0, 0, 0]
    forwardVector = [0,0,0]
    upVector = [0,0,0]
    isAsleep = False

def airDrag(density, speed, coefficient, area, minAreaCoeff, vec1, vec2):
    angle = math.degrees(math.acos(dot(vec1,vec2)/(mag(vec1)*mag(vec2))))
    c = abs(-1*(1-minAreaCoeff)/90*angle+(1-minAreaCoeff))+minAreaCoeff # c=1 at 0 and 180 degrees and c=minAreaCoeff at 90 degrees
    # FPV_Drone.console(angle, c, mag(velocity))
    return 0.5*density*speed*abs(speed)*coefficient*area*c

def startDrone(startPos):
    DroneState.position = [startPos[0], startPos[1], startPos[2]]
    DroneState.velocity = [0, 10, 0]
    ac.setCameraMode(6)
    ac.ext_setCameraFov(float(Values.cameraFov))
    AppState.toggleDrone = True

def dronePhysics(deltaT):
    airDragCoefficient = Values.airDrag/100
    droneSurfaceArea = Values.droneSurfaceArea
    minimalSurfaceAreaCoefficient = Values.minimalSurfaceAreaCoefficient
    gravity = Values.gravity
    
    if ac.getCameraMode() != 6:
        DroneState.isAsleep = True
        return

    if DroneState.isAsleep: # just woke up
        DroneState.isAsleep = False
        ac.ext_setCameraFov(float(Values.cameraFov))

    ac.freeCameraRotatePitch(-math.radians(Values.cameraAngle))
    cameraMatrix = ac.ext_getCameraMatrix()
    upVector = [cameraMatrix[4], cameraMatrix[5], cameraMatrix[6]]
    thrustVector = upVector

    DroneState.force[0] = -airDrag(Values.airDensity, DroneState.velocity[0], airDragCoefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, DroneState.velocity)
    DroneState.force[1] = -airDrag(Values.airDensity, DroneState.velocity[1], airDragCoefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, DroneState.velocity)
    DroneState.force[2] = -airDrag(Values.airDensity, DroneState.velocity[2], airDragCoefficient, droneSurfaceArea, minimalSurfaceAreaCoefficient, thrustVector, DroneState.velocity)

    acceleration = [DroneState.force[0]/Values.droneMass, DroneState.force[1]/Values.droneMass, DroneState.force[2]/Values.droneMass]

    DroneState.velocity[0] += (thrustVector[0]*Input.throttle*Values.throttleAcceleration + acceleration[0]) * deltaT
    DroneState.velocity[1] += (thrustVector[1]*Input.throttle*Values.throttleAcceleration + acceleration[1] - gravity) * deltaT
    DroneState.velocity[2] += (thrustVector[2]*Input.throttle*Values.throttleAcceleration + acceleration[2]) * deltaT

    DroneState.position[0] += DroneState.velocity[0]*deltaT
    DroneState.position[1] += DroneState.velocity[1]*deltaT
    DroneState.position[2] += DroneState.velocity[2]*deltaT

    if DroneState.position[1] < Values.groundLevel+0.1:
        DroneState.position[1] = Values.groundLevel+0.1
        DroneState.velocity[1] = 0

    ac.ext_setCameraPosition(tuple(DroneState.position))

    ac.freeCameraRotatePitch(math.radians(Input.pitch*-1)*deltaT)
    ac.freeCameraRotateHeading(math.radians(Input.yaw*-1)*deltaT)
    ac.freeCameraRotateRoll(math.radians(Input.roll*-1)*deltaT)
    ac.freeCameraRotatePitch(math.radians(Values.cameraAngle))
