--This script handles as example events sent by client and server scripts
--Feel free to change it of remove it completly (if you do edit fxmanifest.lua)
--You can do it all of above and other things stated in github wiki in completly independent script

RegisterNetEvent('pb_racing:countdown', function (number)
    TriggerEvent('pb_racing:public:notify', 'Race countdown', number)
end)

AddEventHandler('pb_racing:public:notify', function (_title, _content)
    lib.notify({
        title = _title,
        description = _content,
        type = 'success'
    })
end)

RegisterNetEvent('pb_racing:public:onFinishLineReached', function(time)
    
    local msg = 'You have finished the race with time of %s'

    local time_str = FormatSeconds(time)
    TriggerEvent('pb_racing:public:notify', 'Race', string.format(msg, time_str))
end)

RegisterCommand("createtrack", function (a,b,c)
    TriggerEvent('pb_racing:public:openCreator')
end, false)

function FormatSeconds(seconds)
    local minutes = math.floor(seconds / 60)
    local seconds = seconds - minutes * 60

    local m_string = (minutes < 10 and '0' or '') .. minutes
    local s_string = (seconds < 10 and '0' or '') .. seconds

    local concat = m_string .. ':' .. s_string
    return concat
end