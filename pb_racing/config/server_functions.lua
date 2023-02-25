ServerFunctions = {}

--Here should be a way to get player identifier/char id/ etc - it will be added to mysql record when creating a new track
--It is currently only an info, it is not displayed anywhere in the game
ServerFunctions.GetPlayerLongIdentificator = function (source)
    return 'test'
end

ServerFunctions.CanCreateRace = function (source)
    return true
end

ServerFunctions.CanJoinRace = function (source)
    return true
end

ServerFunctions.CanOpenCreator = function (source)
    return true
end