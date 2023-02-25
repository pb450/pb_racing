local freecam = exports['fivem-freecam']
local mode = false
local modifiedpoint = nil

local checkpoints = {}

AddEventHandler('pb_racing:public:openCreator', function ()
    SwitchMode(true)
end)

function SwitchMode(_mode)
    lib.callback('pb_racing:openCreator', false, function (status)
        if status or (not _mode) then
            mode = _mode
            freecam:SetActive(mode)

            checkpoints = {}
            modifiedpoint = nil
        end
    end)
end

function SaveRace()
    local options = {
        {type = "input", label = "Race name"},
        {type = "checkbox", label = "Support laps"}
    }

    local result = lib.inputDialog('Save race', options)

    local data = {name = result[1], laps = result[2], points = checkpoints}
    TriggerServerEvent("pb_racing:saveRace", json.encode(data))

    SwitchMode(false)
end



--RegisterCommand("saverace", function (a,b,c)
--    SaveRace()
--end, false)

RegisterCommand('pb_racing_editor_removelastcheckpoint', function (a,b,c)
    if #checkpoints >= 1 and mode then
        table.remove(checkpoints, #checkpoints)
    end
end, false)

RegisterCommand('pb_racing_editor_saverace', function (a,b,c)
    if mode then
        SaveRace()
    end
end, false)

RegisterCommand('pb_racing_editor_exit', function (a,b,c)
    if mode then
        SwitchMode(false)
    end
end, false)

Citizen.CreateThread(function ()
    RegisterKeyMapping('pb_racing_editor_removelastcheckpoint', '(Creator) Remove last checkpoint', 'keyboard', 'x')
    RegisterKeyMapping('pb_racing_editor_saverace', '(Creator) Save track', 'keyboard', 'return')
    RegisterKeyMapping('pb_racing_editor_exit', '(Creator) Exit without saving', 'keyboard', 'c')
end)


function GetRaycast()
    local wd, nw = GetWorldCoordFromScreenCoord(0.5, 0.5)
    local dest = wd + 50 * nw

    local pped = PlayerPedId()
    local test_id = StartExpensiveSynchronousShapeTestLosProbe(wd.x, wd.y, wd.z, dest.x, dest.y, dest.z, -1, pped, 7)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(test_id)

    return retval, hit, endCoords, surfaceNormal, entityHit
end

function MyDrawMarker(x, y, z, r, g, b)
    DrawMarker(1, x, y, z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 1.0, 1.0, 1.0, r, g, b, 255, false, true, 2, nil, nil, false)
end

Citizen.CreateThread(function ()
    while true do
        if mode then
            local retval, hit, endCoords, surfaceNormal, entityHit = GetRaycast()

            if hit then
                --print(endCoords.x, endCoords.y, endCoords.z)
                DrawSphere(endCoords.x, endCoords.y, endCoords.z, 2, 0, 0, 255, 0.2)
                MyDrawMarker(endCoords.x, endCoords.y, endCoords.z, 255, 215, 0)
            end

            if not (modifiedpoint == nil) then
                MyDrawMarker(modifiedpoint.x, modifiedpoint.y, modifiedpoint.z, 14, 120, 21)
            end

            for key, value in pairs(checkpoints) do
                local firstPos = value[1]
                local secondPos = value[2]

                local dist = freecam:GetPosition() - ((firstPos + secondPos)/2)

                if #dist < 80 then
                    MyDrawMarker(firstPos.x, firstPos.y, firstPos.z, 194, 34, 10)
                    MyDrawMarker(secondPos.x, secondPos.y, secondPos.z, 194, 34, 10)
                end
            end

            if IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24) then
                if hit then
                    if modifiedpoint == nil then
                        modifiedpoint = endCoords
                    else
                        local l_m = {endCoords, modifiedpoint}
                        table.insert(checkpoints, l_m)

                       modifiedpoint = nil
                end
            end

            
        end

        
    end

    Citizen.Wait(0)
end
end)