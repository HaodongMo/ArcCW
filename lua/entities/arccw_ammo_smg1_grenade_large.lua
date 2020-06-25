AddCSLuaFile()

ENT.Base 					= "arccw_ammo"

ENT.PrintName 				= "Rifle Grenade Box"
ENT.Category 				= "ArcCW - Ammo"

ENT.Spawnable 				= true
ENT.Model 					= "models/items/arccw/riflegrenade_ammo.mdl"
ENT.Health = 70

ENT.AmmoType = "smg1_grenade"
ENT.AmmoCount = 5

ENT.DetonationDamage = 100 -- Per-round damage
ENT.DetonationRadius = 300

function ENT:DetonateRound(attacker)
    local nade = ents.Create("arccw_gl_ammodet")
    nade:SetPos(self:GetPos())
    local v = self:GetUp():Angle() + AngleRand(-60, 60)
    nade:SetAngles(v)
    nade:Spawn()
    nade:GetPhysicsObject():AddVelocity(self:GetVelocity() + self:GetForward() * math.random(2000, 3000))
    nade:SetOwner(attacker or self.Burner)

    self.AmmoCount = self.AmmoCount - 1

    self:GetPhysicsObject():AddVelocity(VectorRand() * math.random(5, 10) * self:GetPhysicsObject():GetMass())
    self:GetPhysicsObject():AddAngleVelocity(VectorRand() * math.random(60, 300))

    self:EmitSound("weapons/ar2/ar2_altfire.wav", 80, 150)
end

function ENT:Detonate(wet, attacker)
    if wet then
        for i = 1, math.random(1, 3) do
            self:DetonateRound(attacker)
        end
    end

    local e = EffectData()
    e:SetOrigin(self:GetPos())
    util.Effect("Explosion", e)

    util.BlastDamage(self, attacker, self:GetPos(), self.DetonationRadius, self.DetonationDamage * (wet and 1 or 2))
    self:Remove()
end