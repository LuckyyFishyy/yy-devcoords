local Config = Config or {}
local active = false
local lastSend = 0
local lastVec3 = 'vec3(0.00, 0.00, 0.00)'
local lastVec4 = 'vec4(0.00, 0.00, 0.00, 0.00)'

local function notify(message, nType)
    if lib and lib.notify then
        lib.notify({
            title = 'Dev Coords',
            description = message or '',
            type = nType or 'inform'
        })
    end
end

local function rotationToDirection(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosX = math.cos(rotX)
    return vector3(-math.sin(rotZ) * cosX, math.cos(rotZ) * cosX, math.sin(rotX))
end

local function raycastFromCamera(maxDistance)
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = rotationToDirection(camRot)
    local dest = vector3(
        camCoord.x + direction.x * maxDistance,
        camCoord.y + direction.y * maxDistance,
        camCoord.z + direction.z * maxDistance
    )
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(ray)
    if hit == 1 then
        return endCoords, true
    end
    return dest, false
end

local function formatVec3(coords)
    return ('vec3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z)
end

local function formatVec4(coords, heading)
    return ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, heading)
end

local function setActive(state)
    if active == state then return end
    active = state
    if state then
        SendNUIMessage({ action = 'open' })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        CreateThread(function()
            while active do
                local coords = raycastFromCamera(Config.MaxDistance or 80.0)
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                lastVec3 = formatVec3(coords)
                lastVec4 = formatVec4(coords, heading)
                local lineColor = Config.LineColor or { r = 120, g = 200, b = 255, a = 200 }
                DrawLine(pedCoords.x, pedCoords.y, pedCoords.z + 0.2, coords.x, coords.y, coords.z, lineColor.r, lineColor.g, lineColor.b, lineColor.a)

                if Config.DrawMarker then
                    local markerColor = Config.MarkerColor or lineColor
                    DrawMarker(
                        28,
                        coords.x, coords.y, coords.z + 0.05,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.MarkerScale or 0.18,
                        Config.MarkerScale or 0.18,
                        Config.MarkerScale or 0.18,
                        markerColor.r, markerColor.g, markerColor.b, markerColor.a,
                        false, false, 2, nil, nil, false
                    )
                end

                local now = GetGameTimer()
                if now - lastSend > 120 then
                    lastSend = now
                    SendNUIMessage({
                        action = 'update',
                        vec3 = lastVec3,
                        vec4 = lastVec4,
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        h = heading
                    })
                end
                Wait(0)
            end
        end)
    else
        SendNUIMessage({ action = 'close' })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end

RegisterNetEvent('yy-devcoords:client:Toggle', function()
    setActive(not active)
end)

RegisterNetEvent('yy-devcoords:client:Notify', function(message, nType)
    notify(message, nType)
end)

RegisterNUICallback('devcoords_close', function(_, cb)
    setActive(false)
    cb({})
end)

RegisterCommand('devcoords_copy_vec3', function()
    if not active then return end
    SendNUIMessage({ action = 'copy', text = lastVec3 })
end, false)

RegisterCommand('devcoords_copy_vec4', function()
    if not active then return end
    SendNUIMessage({ action = 'copy', text = lastVec4 })
end, false)

RegisterKeyMapping('devcoords_copy_vec3', 'Dev Coords: Copy vec3', 'keyboard', 'J')
RegisterKeyMapping('devcoords_copy_vec4', 'Dev Coords: Copy vec4', 'keyboard', 'K')

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    setActive(false)
end)
