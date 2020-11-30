AddCSLuaFile()

ENT.Base                      = "arccw_ammo"

ENT.PrintName                 = "Carbine Ammo"
ENT.Category                  = "ArcCW - Ammo"

ENT.Spawnable                 = true
ENT.Model                     = "models/items/arccw/smg_ammo.mdl"

ENT.AmmoType = "smg1"
ENT.AmmoCount = 60
if engine.ActiveGamemode() == "terrortown" then
    ENT.AmmoCount = 30
end

ENT.DetonationDamage = 30
ENT.DetonationRadius = 256
ENT.DetonationSound = "weapons/smg1/npc_smg1_fire1.wav"