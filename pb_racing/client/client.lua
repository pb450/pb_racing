local inRace = false
local raceId = ''
local route = {}
local currentCheckpoint = 0
local laps = 0

local currentCheckpointZone = nil

local waypointBlip = 0
local nextCheckpointBlip = 0
local waypointprops = {}

local startingPointBlip = 0

local beforeracedisplay = {}

local raceprophash = 0

Citizen.CreateThread(function()
    raceprophash = GetHashKey(Config.WaypointProp)
    RequestModel(raceprophash)
end)

function Notify(x_title, ctx)
    TriggerEvent('pb_racing:public:notify', x_title, ctx)
end

function FormatSeconds(seconds)
    local minutes = math.floor(seconds / 60)
    local seconds = seconds - minutes * 60

    local m_string = (minutes < 10 and '0' or '') .. minutes
    local s_string = (seconds < 10 and '0' or '') .. seconds

    local concat = m_string .. ':' .. s_string
    return concat
end

RegisterCommand(Config.LeaveraceCommand, function (a,v,c)
    if inRace then
        EndRace(true)
    else
        Notify('Race', 'You are not in any race')
    end

end, false)

function EndRace(x)
    currentCheckpointZone:remove()
    currentCheckpointZone = nil
    RemoveBlip(waypointBlip)
    RemoveBlip(nextCheckpointBlip)

    for key, value in pairs(waypointprops) do
        DeleteEntity(value)
    end

    waypointprops = {}
    inRace = false
    route = {}

    TriggerServerEvent('pb_racing:finishRace', raceId, x)
end

function OnCheckpointEntered(x_self)
    if (not (currentCheckpointZone == nil)) then
        currentCheckpointZone:remove()
    end

    TriggerEvent('pb_racing:public:onCheckpointPassed', currentCheckpoint, #route, laps)

    currentCheckpoint = currentCheckpoint + 1

    local point = route[currentCheckpoint + 1]
    --print(currentCheckpoint, currentCheckpoint + 1, route[currentCheckpoint + 1], #route)

    if (point == nil) then
        EndRace(false)
    else
        local point1 = point[1]
        local point2 = point[2]
        local v_point1 = vector3(point1.x, point1.y, point1.z)
        local v_point2 = vector3(point2.x, point2.y, point2.z)

        local tanges = math.atan2(v_point2.y - v_point1.y, v_point2.x - v_point1.x)
        local angle = math.deg(tanges)

        local middle = (v_point1 + v_point2) / 2
        local dst = #(middle - v_point1)

        if DoesBlipExist(waypointBlip) then
            RemoveBlip(waypointBlip)
        end

        local local_blip = AddBlipForCoord(middle.x, middle.y, middle.z)
        SetBlipSprite(local_blip, Config.WaypointBlip.Sprite)
        SetBlipColour(local_blip, Config.WaypointBlip.Color)
        SetBlipRoute(local_blip, true)

        waypointBlip = local_blip

        local t = { v_point1, v_point2 }

        local next_next_blip = route[currentCheckpoint + 2]
        if not (next_next_blip == nil) then
            local next_point = route[currentCheckpoint + 2]

            local next_point1 = next_next_blip[1]
            local next_point2 = next_next_blip[2]
            local next_v_point1 = vector3(next_point1.x, next_point1.y, next_point1.z)
            local next_v_point2 = vector3(next_point2.x, next_point2.y, next_point2.z)

            if DoesBlipExist(nextCheckpointBlip) then
                RemoveBlip(nextCheckpointBlip)
            end

            local next_middle = (next_v_point1 + next_v_point2)/2

            local next_local_blip = AddBlipForCoord(next_middle.x, next_middle.y, next_middle.z)
            SetBlipSprite(next_local_blip, Config.WaypointBlip.Sprite)
            SetBlipScale(next_local_blip, 0.75)
            SetBlipColour(next_local_blip, Config.WaypointBlip.Color)

            nextCheckpointBlip = next_local_blip

            table.insert(t, next_v_point1)
            table.insert(t, next_v_point2)
        end

        
        for key, value in pairs(waypointprops) do
            DeleteEntity(value)
        end

        waypointprops = {}
        for key, value in pairs(t) do
            local prop = CreateObject(raceprophash, value.x, value.y, value.z, false, true, true)
            PlaceObjectOnGroundProperly(prop)
            FreezeEntityPosition(prop, true)
            SetEntityCollision(prop, false, false)

            if Config.WaypointPropOutline then
                SetEntityDrawOutline(prop, true)
                SetEntityDrawOutlineShader(1)
                SetEntityDrawOutlineColor(Config.WaypointPropOutlineColor.r, Config.WaypointPropOutlineColor.g, Config.WaypointPropOutlineColor.b, 255)
            end

            table.insert(waypointprops, prop)
        end

        local size_vector = vector3(dst * 2, 2, 5)
        local box = lib.zones.box({
            coords = middle,
            size = size_vector,
            rotation = angle,
            debug = Config.ZoneDebug
        })

        currentCheckpointZone = box
    end
end

function RepeatArray(arr, time)
    local whole = {}
    for i = 1, time, 1 do
        for key, value in pairs(arr) do
            table.insert(whole, value)
        end
    end

    return whole
end

function BoxContains(x_zone, x_location)
    return x_zone.contains(x_zone, x_location)
end

Citizen.CreateThread(function()
    while true do
        if inRace and not (currentCheckpointZone == nil) then

            local pped = PlayerPedId()
            local pvehicle = GetVehiclePedIsIn(pped, false)

            if pvehicle == 0 then
                EndRace(true)
            end

            if BoxContains(currentCheckpointZone, GetEntityCoords(PlayerPedId())) or BoxContains(currentCheckpointZone, GetEntityCoords(pvehicle)) then
                OnCheckpointEntered(nil)
            end
        end

        Citizen.Wait(0)
    end
end)

RegisterNetEvent('pb_racing:countdown', function(m)
    TriggerEvent('pb_racing:public:countdown', m)
end)

RegisterNetEvent('pb_racing:startrace', function(_route, _laps)
    RemoveBlip(startingPointBlip)
    currentCheckpoint = -1
    laps = _laps

    for key, value in pairs(beforeracedisplay) do
        RemoveBlip(value)
    end

    beforeracedisplay = {}

    local track = lib.callback.await('pb_racing:getTrack', false, _route)

    route = {}
    route = RepeatArray(track.checkpoints, _laps)
    inRace = true

    OnCheckpointEntered(nil)
end)

function SetupRace(track)
    lib.callback('pb_racing:isPlayerInRace', false, function(status)
        if status then
            Notify('Race', 'You can\'t create new race while being in one')
        else
            local _options = {}
            local numberOfplayer = { type = 'number', label = 'Number of players', min = 1, max = 16384 }

            table.insert(_options, numberOfplayer)

            if track.laps then
                local lapsAmount = { type = 'number', label = 'Number of laps', min = 1, max = 100000 }
                table.insert(_options, lapsAmount)
            end

            local carTypes = { 'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports', 'Super',
                'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes',
                'Service', 'Emergency', 'Military', 'Commercial', 'Trains', 'Open Wheel' }
            for key, value in pairs(carTypes) do
                local ct = { type = 'checkbox', label = value }
                table.insert(_options, ct)
            end

            local input = lib.inputDialog('Setup ' .. track.name, _options)

            if input then
                local x_players = input[1]
                local baza = 1

                local x_laps = 1
                if track.laps then
                    x_laps = input[2]
                    baza = baza + 1
                end

                local availableCarTypes = {}
                for i = 0, #carTypes - 1, 1 do
                    local t = input[baza + i + 1] == true
                    table.insert(availableCarTypes, t)
                end

                lib.callback('pb_racing:createRace', false, function(id)
                    --JoinRace(id)

                    print('Join', id)
                    if id then
                        JoinRace(id)
                    else
                        Notify('Race', 'Error - You can\'t create a race')
                    end
                end, track.id, x_laps, x_players, availableCarTypes)
            else
                print('huh')
            end
        end
    end)
end

function CreateRaceScreen()
    lib.callback('pb_racing:getAllTracks', false, function(data)
        local _options = {}

        for key, value in pairs(data) do
            local opt = {
                title = value.name,
                onSelect = function(args)
                    SetupRace(args.track)
                end,
                metadata = {
                    { label = 'Checkpoints', value = #value.checkpoints },
                    { label = 'Laps',        value = value.laps and 'Supported' or 'Unsupported' }
                },
                args = {
                    track = value
                }
            }

            table.insert(_options, opt)
        end

        lib.registerContext({
            id = 'create_race',
            title = 'Create race menu',
            options = _options
        })

        lib.showContext('create_race')
    end)
end

function DrawStartingPoint(routeId)
    lib.callback('pb_racing:getTrack', false, function (route)
        Notify('Race', string.format('You have joined race on route %s', route.name))

        local count = 0
        for key, value in pairs(route.checkpoints) do
            local m1 = value[1]
            local m2 = value[2]

            local vm1 = vector3(m1.x, m1.y, m1.z)
            local vm2 = vector3(m2.x, m2.y, m2.z)
            local middle = (vm1 + vm2)/2

            local bp = AddBlipForCoord(middle.x, middle.y, middle.z)
            SetBlipSprite(bp, 1)
            SetBlipColour(bp, Config.BeforeRaceDisplayColor)
            SetBlipRoute(bp, count == 0)
            ShowNumberOnBlip(bp, count + 1)
            table.insert(beforeracedisplay, bp)

            count = count + 1
        end
    end, routeId)
end

function JoinRace(id)
    local inveh = IsPedInAnyVehicle(PlayerPedId(), false)
    if inveh then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        lib.callback('pb_racing:joinRace', false, function(data)
            local status = data[1]
            local route = data[2]
            print(status)
            if status == 0 then
                raceId = id
                DrawStartingPoint(route)
            end
        end, id, GetVehicleClass(veh))
    else
    end
end

function JoinRaceScreen()
    local _options = {}
    lib.callback('pb_racing:getRaces', false, function(data)
        local tracks = lib.callback.await('pb_racing:getAllTracks', false)
        if not tracks then
            print('Something wrong with tracks')
        end

        for key, value in pairs(data) do
            print(value.id)
            local h = ''
            local carTypes = { 'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports', 'Super',
                'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes',
                'Service', 'Emergency', 'Military', 'Commercial', 'Trains', 'Open Wheel' }
            for i = 0, #carTypes - 1, 1 do
                local m = value.vehicles[i + 1]
                if m then
                    h = h .. carTypes[i + 1] .. ', '
                end
            end

            local opt = {
                title = tracks[value.route].name,
                metadata = {
                    { label = 'Players',  value = value.players .. '/' .. value.maxPlayers },
                    { label = 'Vehicles', value = h },
                    { label = 'Time to start', value = FormatSeconds(value.startsIn)}
                },
                args = {
                    race = value.id
                },
                onSelect = function(args)
                    JoinRace(args.race)
                end
            }

            if tracks[value.route].laps then
                table.insert(opt.metadata, { label = 'Laps', value = value.laps })
            end

            table.insert(_options, opt)
        end

        lib.registerContext({
            id = 'join_menu',
            title = 'Join menu',
            options = _options
        })
        lib.showContext('join_menu')
    end)
end

AddEventHandler('pb_racing:public:bringRaceMenu', function ()
    OpenRaceMenu()
end)

function OpenRaceMenu()
    local _options = {
        {
            title = 'Join race',
            onSelect = function()
                JoinRaceScreen()
            end
        },
        {
            title = 'Create race',
            onSelect = function()
                CreateRaceScreen()
            end
        }
    }

    lib.registerContext({
        id = 'race_menu',
        title = 'Race menu',
        options = _options
    })

    lib.showContext('race_menu')
end
