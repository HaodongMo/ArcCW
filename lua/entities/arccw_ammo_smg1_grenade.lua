AddCSLuaFile()

ENT.Base 					= "arccw_ammo"

ENT.PrintName 				= "Rifle Grenade"
ENT.Category 				= "ArcCW - Ammo"

ENT.Spawnable 				= true
ENT.Model 					= "models/Items/AR2_Grenade.mdl"
ENT.Health = 15

ENT.AmmoType = "smg1_grenade"
ENT.AmmoCount = 1

ENT.DetonationDamage = 50 -- Per-round damage
ENT.DetonationRadius = 300

function ENT:DetonateRound(attacker)
    local nade = ents.Create("arccw_gl_ammodet")
    nade:SetPos(self:GetPos())
    nade:SetAngles(self:GetAngles() + AngleRand(-10, 10))
    nade:Spawn()
    nade:GetPhysicsObject():AddVelocity(self:GetVelocity() + self:GetForward() * math.random(500, 2000))
    nade:SetOwner(attacker or self.Burner)
    self:Remove()
end

function ENT:Detonate(wet, attacker)
    if wet then
        self:DetonateRound(attacker)
    else
        local e = EffectData()
        e:SetOrigin(self:GetPos())
        util.Effect("Explosion", e)

        util.BlastDamage(self, attacker, self:GetPos(), self.DetonationRadius, self.DetonationDamage)
        self:Remove()
    end
end