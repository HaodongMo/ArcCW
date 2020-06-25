AddCSLuaFile()

ENT.Type 					= "anim"
ENT.Base 					= "base_gmodentity"

ENT.PrintName 				= "Sniper Ammo (Large)"

ENT.Category 				= "ArcCW - Ammo"

ENT.Spawnable 				= true

ENT.Model 					= "models/items/sniper_round_box.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)
    self:UseTriggerBounds(true, 24)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
    end
end

function ENT:Touch(ply)
    if !ply:IsPlayer() then return end

    ply:GiveAmmo(20, "SniperPenetratedRound")

    self:Remove()
end