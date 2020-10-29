-- This will simply load a script CHARACTER_NAME.lua, you don't have to add '.lua' at the end, it already knows
-- you can make it load things from folders, if you want to clear up your code
-- example: module.load(header.id, 'CHAMPIONS/' .. player.charName)
module.load(header.id, player.charName)