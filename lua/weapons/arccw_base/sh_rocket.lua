function SWEP:FireRocket(ent, vel, ang, dontinheritvel)
    if CLIENT then return end

    local rocket = ents.Create(ent)

    ang = ang or self:GetOwner():EyeAngles()

    local src = self:GetShootSrc()

    if !rocket:IsValid() then print("!!! INVALID ROUND " .. ent) return end

    local rocketAng = Angle(ang.p, ang.y, ang.r)
    if ang and self.ShootEntityAngleCorrection then
        local up = ang:Up()
        local right = ang:Right()
        local forward = ang:Forward()
        rocketAng:RotateAroundAxis(up, self.ShootEntityAngleCorrection.y)
        rocketAng:RotateAroundAxis(right, self.ShootEntityAngleCorrection.p)
        rocketAng:RotateAroundAxis(forward, self.ShootEntityAngleCorrection.r)
    end

    rocket:SetAngles(rocketAng)
    rocket:SetPos(src)

    rocket:SetOwner(self:GetOwner())
    rocket.Owner = self:GetOwner()
    rocket.Inflictor = self

    rocket.Damage = self.Damage * math.Rand(1 - self.DamageRand, 1 + self.DamageRand)
    if self.BlastRadius then
        rocket.BlastRadius = self.BlastRadius * math.Rand(1 - (self.BlastRadiusRand or 0), 1 + (self.BlastRadiusRand or 0))
    end

    local RealVelocity = (!dontinheritvel and self:GetOwner():GetAbsVelocity() or Vector(0, 0, 0)) + ang:Forward() * vel / ArcCW.HUToM
    rocket.CurVel = RealVelocity -- for non-physical projectiles that move themselves

    rocket:Spawn()
    rocket:Activate()
    if !rocket.NoPhys and rocket:GetPhysicsObject():IsValid() then
        rocket:SetCollisionGroup(rocket.CollisionGroup or COLLISION_GROUP_DEBRIS)
        rocket:GetPhysicsObject():SetVelocityInstantaneous(RealVelocity)
    end

    if rocket.Launch and rocket.SetState then
        rocket:SetState(1)
        rocket:Launch()
    end

    if rocket.ArcCW_Killable == nil then
        rocket.ArcCW_Killable = true
    end

    rocket.ArcCWProjectile = true

    self:GetBuff_Hook("Hook_PostFireRocket", rocket)

    return rocket
end