# pb_racing

Features:
- Track editor (with saving to MySQL)
- Basic race creator and join menu
- Racing system with zone checkpoints (You have to pass in area between two edges)
- Possibility to do most things (starting, joining etc) to be done from other scripts (thanks to ox_lib callbacks and triggers)
- As much configuration as possible

Dependecies:
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_mysql](https://github.com/overextended/oxmysql)
- [freecam](https://github.com/Deltanic/fivem-freecam)

Installation:
- Download relase
- Unzip pb_racing folder into resources folder
- Execute setup.sql in your database where ox_mysql is linked to
- Setup permissions in config/ServerFunctions.lua and settings in config/config.lua
- Add start/ ensure in your .cfg file

Remember to setup triggers/callbacks in your script if you want to operate this script from yours. If you do this remove addons/player.lua from fxmanifest.lua. More about them can be found [here](https://github.com/pb450/pb_racing/wiki/Script-events-and-callbacks---Permission)

See showcase [here](https://youtu.be/vQpSyQABEcg) and [here](https://youtu.be/ebEtwXBmJ00)
