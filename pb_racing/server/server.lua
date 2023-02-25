local tracks = {}
local races = {}

RegisterNetEvent('pb_racing:saveRace', function (jsoned)
    local data = json.decode(jsoned)

    local name = data.name
    local areLapsSupported = not (data.laps == nil)
    local checkpointsJson = json.encode(data.points)
    local userIdentifier = ServerFunctions.GetPlayerLongIdentificator(source)

    MySQL.insert('INSERT INTO pb_racing (id, name, data, laps, creator) VALUES (?, ?, ?, ?, ?)', {'NULL', name, checkpointsJson, areLapsSupported, userIdentifier}, function(id)
    end)
end)

function IsPlayerInRace(id)
    local r = false
    for key, value in pairs(races) do
        for k, v in pairs(value.players) do
            if v.networkId == id then
                r = true
            end
        end
    end

    return r
end

function GetPlayerRace(id)
    local r = ''
    for key, value in pairs(races) do
        for k, v in pairs(value.players) do
            if v.networkId == id then
                r = value.id
            end
        end
    end

    return r
end

Citizen.CreateThread(function ()
    while true do

        tracks = {}

        MySQL.query('SELECT * FROM pb_racing', {}, function(result)
            for key, value in pairs(result) do
                local _id = value.id
                local _name = value.name
                local _laps = value.laps
                local _creator = value.creator

                local _checkpoints = json.decode(value.data)
                local track = {id = _id, name = _name, laps = _laps, checkpoints = _checkpoints, creator = _creator}

                tracks[_id] = track
            end
        end)

        Citizen.Wait(Config.SecondsBetweenRouteUpdates * 1000)
    end
end)

function Countdown(race, x)
    Citizen.CreateThread(function ()
        for i = 1, Config.CountBase, 1 do
            local count = Config.CountBase - i + 1
            
            for key, value in pairs(race.players) do
                TriggerClientEvent('pb_racing:countdown', value.networkId, count)
            end

            Citizen.Wait(Config.CountInterval)
        end

        races[x].phase = 2
        races[x].times.started = os.time()

        for key, value in pairs(race.players) do
            TriggerClientEvent('pb_racing:startrace', value.networkId, race.route, race.laps)
        end
    end)
end


function AllPlayersFinished(race)
    local x = true

    for key, value in pairs(race.players) do
        if value.finishTime < 0 then
            x = false
        end
    end

    return x
end

function TerminateRace(id)
    print('Race', id, ' is terminated')
    races[id] = nil
end

function SendResultEvent(race)
    local basetime = race.times.started

    local results = {}
    for key, value in pairs(race.players) do
        local _id = value.networkId
        local _finishTime = value.finishTime - basetime
        table.insert(results, {id = _id, time = _finishTime})
    end

    table.sort(results, function (a, b)
        return a.time < b.time
    end)

    TriggerEvent('pb_racing:public:onRaceEnded', results, race.playerNotFinished, race.route, race.laps, race.vehicles)
end

Citizen.CreateThread(function ()
    while true do
        for key, value in pairs(races) do
            if value.phase == 0 and (os.time() - value.times.created) > Config.TimeFromCreationToStart then
                value.phase = 1
                print('Race', key, 'is starting')
                Countdown(value, key)
            end

            if value.phase == 2 and AllPlayersFinished(value) then
                SendResultEvent(value)
                TerminateRace(key)
            end

            if value.phase == 2 and GetPlayerCount(value) == 0 then
                TerminateRace(key)
            end 
        end

        Citizen.Wait(0)
    end
end)

--Quick note
--Phases are:
--0: Waiting for players
--1: Starting
--2: Race in progress
--3: Race ended

lib.callback.register('pb_racing:createRace', function (source, _routeId, _laps, _players, _vehicles)
    local _id = ''

    local can = ServerFunctions.CanCreateRace(source)
    if (not (_routeId == nil) and not (_laps == nil) and not (_players == nil) and not (_vehicles == nil)) and can then
        --print(json.encode(_vehicles))
    local race_object = {
        id = _id,
        phase = 0,
        creator = source,
        route = _routeId,
        laps = _laps or 1,
        vehicles = _vehicles,
        players = {},
        playerNotFinished = {},
        maxPlayers = _players,
        times = {created = os.time(), started = -1, firstfinish = -1, ended = -1}
    }

    _id = RandomString(8)
    print('Creating race', _id)
    races[_id] = race_object
    else

    end

    return _id
end)

function GetPlayerCount(race)
    local count = 0
    for key, value in pairs(race.players) do
        count = count + 1
    end

    return count
end

AddEventHandler('playerDropped', function (reason)
    if IsPlayerInRace(source) then
        FinishRace(source, GetPlayerRace(source), true)
    end
end)

lib.callback.register('pb_racing:getRaces', function (source)
    local racesData = {}
    for key, value in pairs(races) do
        local construction = {id = value.id, route = value.route, players = GetPlayerCount(value), maxPlayers = value.maxPlayers, vehicles = value.vehicles, laps = value.laps, startsIn = (value.times.created + Config.TimeFromCreationToStart) - os.time()}
        table.insert(racesData, construction)
    end

    return racesData
end)


--Statuses are:
-- 0 => Can join the race and will be
-- 1 => Race with this id does not exist
-- 2 => Race is full
-- 3 => Player has bad vehicles type
-- 4 => Race already in progress
-- 5 => Player is in other race
-- 6 => ServerFunctions.lua does not allow to join

lib.callback.register('pb_racing:joinRace', function (source, raceId, carclass)
    local status = 0

    local s_race = races[raceId]

    if s_race == nil then
        status = 1
    else
        if IsPlayerInRace(source) then
            status = 5
        else
            if GetPlayerCount(s_race) == s_race.maxPlayers then
               status = 2 
            else
                if s_race.phase == 0 then
                        --if not lib.table.contains(s_race.vehicles, carclass) then
                    if not s_race.vehicles[carclass + 1] then
                        status = 3
                    else

                        if ServerFunctions.CanJoinRace(source) then

                        local playerConstruction = {
                            networkId = source,
                            checkpoints = 0,
                            finishTime = -1
                        }

                      table.insert(s_race.players, playerConstruction)
                    else
                        status = 6
                    end

                    end
            else
                status = 4
            end
        end
    end
    end

    --local chc = tracks[races[raceId].track].checkpoints[1]
    --print(chc)
    return {status, races[raceId].route}

end)

RegisterNetEvent('pb_racing:finishRace', function(raceId, notReachFinishLine)
    FinishRace(source, raceId, notReachFinishLine)
end)

function FinishRace(src, raceId, notReachFinishLine)
    local thisRace = races[raceId]

    if thisRace == nil then
        print(src, 'requested race that do not exist', raceId)
    else
        local playerExist = false
        local playerKey = 0

        for key, value in pairs(thisRace.players) do
            if value.networkId == src then
                playerKey = key
                playerExist = true
            end
        end

        if playerExist then
            if notReachFinishLine then
                table.insert(races[raceId].playerNotFinished, playerKey)
                races[raceId].players[playerKey] = nil
            else
                races[raceId].players[playerKey].finishTime = os.time()


                local a1 = races[raceId].players[playerKey].networkId
                local a2 = races[raceId].players[playerKey].finishTime - races[raceId].times.started

                TriggerClientEvent('pb_racing:public:onFinishLineReached', a1, a2)

                if races[raceId].times.firstfinish < 0 then
                    races[raceId].times.firstfinish = os.time()
                end
            end
        else
            print('Race', raceId, 'exists but player', src, 'is not registered as player')
        end
    end
end

lib.callback.register('pb_racing:getTrack', function (source, trackId)
    return tracks[trackId]
end)

lib.callback.register('pb_racing:getAllTracks', function (source)
    return tracks
end)

lib.callback.register('pb_racing:isPlayerInRace', function (source)
    return IsPlayerInRace(source)
end)

lib.callback.register('pb_racing:openCreator', function (source)
    return not IsPlayerInRace(source) and ServerFunctions.CanOpenCreator(source)
end)

--misc functions
function RandomString(len)
    local chars = {'a', 'b', 'c', 'd', 'e', 'f', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'}
    local result = ""
    for i=1, len,1 do
        result = result .. chars[math.random(#chars)]
    end
    return result
end