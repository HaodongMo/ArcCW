AddCSLuaFile()

-- the main object
ArcCW = {}

ArcCWInstalled = true

ArcCW.GenerateAttEntities = true

for _, v in pairs(file.Find("arccw/shared/*", "LUA")) do
    include("arccw/shared/" .. v)
    AddCSLuaFile("arccw/shared/" .. v)
end

for _, v in pairs(file.Find("arccw/client/*", "LUA")) do
    AddCSLuaFile("arccw/client/" .. v)
    if CLIENT then
        include("arccw/client/" .. v)
    end
end

if SERVER or game.SinglePlayer() then
    for _, v in pairs(file.Find("arccw/server/*", "LUA")) do
        include("arccw/server/" .. v)
    end
end

-- if you want to override arccw functions, put your override files in the arccw/mods directory so it will be guaranteed to override the base

for _, v in pairs(file.Find("arccw/mods/shared/*", "LUA")) do
    include("arccw/mods/shared/" .. v)
    AddCSLuaFile("arccw/mods/shared/" .. v)
end

for _, v in pairs(file.Find("arccw/mods/client/*", "LUA")) do
    AddCSLuaFile("arccw/mods/client/" .. v)
    if CLIENT then
        include("arccw/mods/client/" .. v)
    end
end

if SERVER or game.SinglePlayer() then
    for _, v in pairs(file.Find("arccw/mods/server/*", "LUA")) do
        include("arccw/mods/server/" .. v)
    end
end