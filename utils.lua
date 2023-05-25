function Print(...)
    local printSum = ""
    for i, v in pairs({...}) do
        printSum = printSum .. tostring(v) .. (i ~= table.nkeys({...}) and ", " or "")
    end
    print(printSum)
end

function GetClosestCar()
    local closestCarIndex = 0
    local minDistance = 1e9
    for i = 0, ac.getSim().carsCount - 1 do
        local car = ac.getCar(i)
        if car and car.isActive then
            if car.distanceToCamera < minDistance then
                closestCarIndex = i
                minDistance = car.distanceToCamera
            end
        end
    end
    return ac.getCar(closestCarIndex)
end

function Jitter(prevClosestCar)
    local closestCar = GetClosestCar()

    if not ac.isInReplayMode() and closestCar and prevClosestCar and closestCar.distanceToCamera < Settings.maxDistance and closestCar.index == prevClosestCar.index then
        local posDiff = closestCar.position:clone():addScaled(prevClosestCar.position, -1)
        local velocity = posDiff:clone():scale(1 / ((closestCar.timestamp - prevClosestCar.timestamp) / 1e3))
        if velocity ~= velocity then velocity = vec3() end
        if posDiff:clone():length() < Settings.maxCompensation then
            return posDiff:clone():addScaled(velocity, -ac.getSim().dt), { timestamp = closestCar.timestamp, position = closestCar.position:clone(), index = closestCar.index }
        end
    end

    return vec3(), { timestamp = closestCar.timestamp, position = closestCar.position:clone(), index = closestCar.index }
end
