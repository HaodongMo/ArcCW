AddCSLuaFile()

ENT.Base 					= "arccw_ammo"

ENT.PrintName 				= "Pistol Ammo"
ENT.Category 				= "ArcCW - Ammo"

ENT.Spawnable 				= true
ENT.Model 					= "models/items/arccw/pistol_ammo.mdl"

ENT.AmmoType = "pistol"
ENT.AmmoCount = 40
if engine.ActiveGamemode() == "terrortown" then
    ENT.AmmoCount = 20
end

ENT.DetonationDamage = 10
ENT.DetonationRadius = 256
ENT.DetonationSound = "weapons/arccw/glock18/glock18-1.wav"