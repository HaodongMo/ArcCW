SWEP.GrenadePrimeTime = 0

function SWEP:PreThrow()
    if self:Clip1() == 0 then
        if self:Ammo1() == 0 then
            return
        else
            self:SetClip1(1)
            self:GetOwner():SetAmmo(self:Ammo1() - 1, self.Primary.Ammo)
        end
    end
    if self:GetGrenadePrimed() then return end

    if engine.ActiveGamemode() == "terrortown" and GetRoundState() == ROUND_PREP and GetConVar("ttt_no_nade_throw_during_prep"):GetBool() then
        return
    end

    self:PlayAnimation("pre_throw", 1, false, 0, true)

    self:SetNextPrimaryFire(CurTime() + self.PullPinTime)

    self:SetGrenadePrimed(true)

    self.GrenadePrimeTime = CurTime()
    self.GrenadePrimeAlt = self:GetOwner():KeyDown(IN_ATTACK2)

    self:GetBuff_Hook("Hook_PreThrow")
end

function SWEP:Throw()
    if self:GetNextPrimaryFire() > CurTime() then return end

    self:SetGrenadePrimed(false)

    self:PlayAnimation("throw", 1, false, 0, true)

    local heldtime = (CurTime() - self.GrenadePrimeTime)

    local windup = heldtime / 0.5

    windup = math.Clamp(windup, 0, 1)

    local mv = self:GetBuff("MuzzleVelocity") * ArcCW.HUToM
    local force = Lerp(windup, mv * 0.25, mv)

    if self.GrenadePrimeAlt and self:GetBuff("MuzzleVelocityAlt", true) then
        force = self:GetBuff("MuzzleVelocityAlt") * ArcCW.HUToM
    end

    self:SetTimer(0.25, function()

        local rocket = self:FireRocket(self.ShootEntity, force)

        if !rocket then return end

        local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

        if ft then
            rocket.FuseTime = ft - heldtime
        end

        local phys = rocket:GetPhysicsObject()

        if GetConVar("arccw_throwinertia"):GetBool() and mv > 100 then
            phys:AddVelocity(self:GetOwner():GetVelocity())
        end

        phys:AddAngleVelocity( Vector(0, 750, 0) )

        self:TakePrimaryAmmo(1)

        if self:Clip1() == 0 and self:Ammo1() >= 1 and !self.Singleton then
            self:SetClip1(1)
            self:GetOwner():SetAmmo(self:Ammo1() - 1, self.Primary.Ammo)
        else
            self:GetOwner():StripWeapon(self:GetClass())
        end
    end)
    self:SetTimer(self:GetAnimKeyTime("throw"), function()
        if !self:IsValid() then return end
        self:PlayAnimation("draw")
    end)

    self:SetNextPrimaryFire(CurTime() + 1)
    self.GrenadePrimeAlt = nil

    self:GetBuff_Hook("Hook_PostThrow")
end