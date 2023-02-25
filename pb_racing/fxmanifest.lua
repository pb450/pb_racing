-- Generated automaticly by RB Generator.
fx_version('cerulean')
games({ 'gta5' })
lua54 'yes'

shared_scripts({'@ox_lib/init.lua', 'config/config.lua'});

server_scripts({
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'config/server_functions.lua'
});

client_scripts({
    'client/client.lua',
    'client/creator.lua',
    'addons/player.lua'
});