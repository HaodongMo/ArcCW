AddCSLuaFile()

ENT.Base 					= "arccw_ammo"
ENT.RenderGroup             = RENDERGROUP_TRANSLUCENT

ENT.PrintName 				= "Magnum Ammo"
ENT.Category 				= "ArcCW - Ammo"

ENT.Spawnable 				= true
ENT.Model 					= "models/items/arccw/magnum_ammo.mdl"

ENT.AmmoType = "357"
ENT.AmmoCount = 12
if engine.ActiveGamemode() == "terrortown" then
    ENT.AmmoType = "AlyxGun"
    ENT.AmmoCount = 18
end


ENT.DetonationDamage = 50
ENT.DetonationRadius = 128
ENT.DetonationSound = "weapons/arccw/deagle/deagle-1.wav"