function SWEP:FireRocket(ent, vel, ang, dontinheritvel)
    if CLIENT then return end

    local rocket = ents.Create(ent)

    ang = ang or (self:GetOwner():EyeAngles() + self:GetFreeAimOffset())

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

    rocket.Inflictor = self

    local randfactor = self:GetBuff("DamageRand")
    local mul = 1
    if randfactor > 0 then
        mul = mul * math.Rand(1 - randfactor, 1 + randfactor)
    end
    rocket.Damage = self:GetBuff("Damage") * mul

    if self.BlastRadius then
        local r_randfactor = self:GetBuff("DamageRand")
        local r_mul = 1
        if r_randfactor > 0 then
            r_mul = r_mul * math.Rand(1 - r_randfactor, 1 + r_randfactor)
        end
        rocket.BlastRadius = self:GetBuff("BlastRadius") * r_mul
    end

    local RealVelocity = (!dontinheritvel and self:GetOwner():GetAbsVelocity() or Vector(0, 0, 0)) + ang:Forward() * vel
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