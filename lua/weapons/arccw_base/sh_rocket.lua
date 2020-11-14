function SWEP:FireRocket(ent, vel, ang)
    if CLIENT then return end

    local rocket = ents.Create(ent)

    ang = ang or self:GetOwner():EyeAngles()

    local src = self:GetShootSrc()

    if !rocket:IsValid() then print("!!! INVALID ROUND " .. ent) return end
	
	local rocketAng = Angle(ang.p, ang.y, ang.r)
	if ang and self.ShootEntityAngleCorrection then
		local up, right, forward = ang:Up(), ang:Right(), ang:Forward()
		rocketAng:RotateAroundAxis(up, self.ShootEntityAngleCorrection.y)
		rocketAng:RotateAroundAxis(right, self.ShootEntityAngleCorrection.p)
		rocketAng:RotateAroundAxis(forward, self.ShootEntityAngleCorrection.r)
	end

    rocket:SetAngles(rocketAng)
    rocket:SetPos(src)

    rocket:SetOwner(self:GetOwner())
	rocket.Owner = self.Owner
    rocket.Inflictor = self
	
	rocket.Damage = self.Damage * math.Rand(1 - self.DamageRand, 1 + self.DamageRand)
	rocket.BlastRadius = self.BlastRadius * math.Rand(1 - self.BlastRadiusRand, 1 + self.BlastRadiusRand)

	local RealVelocity = self:GetOwner():GetAbsVelocity() + ang:Forward() * vel / ArcCW.HUToM
	rocket.CurVel = RealVelocity -- for non-physical projectiles that move themselves
	
    rocket:Spawn()
    rocket:Activate()
	if not rocket.NoPhys then
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

    return rocket
end