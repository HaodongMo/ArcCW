SWEP.GrenadePrimeTime = 0

function SWEP:PreThrow()

    if self:GetNWState() == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint() then return end

    local bot, inf = self:HasBottomlessClip(), self:HasInfiniteAmmo()
    local aps = self:GetBuff("AmmoPerShot")

    if !inf and (bot and self:Ammo1() or self:Clip1()) < aps then
        if self:Ammo1() == 0 and self:Clip1() == 0 and !self:GetBuff_Override("Override_KeepIfEmpty", self.KeepIfEmpty) then
            self:GetOwner():StripWeapon(self:GetClass())
        end
        return
    end

    if self:GetGrenadePrimed() then return end

    if engine.ActiveGamemode() == "terrortown" and GetRoundState() == ROUND_PREP and GetConVar("ttt_no_nade_throw_during_prep"):GetBool() then
        return
    end

    self:SetNextPrimaryFire(CurTime() + self.PullPinTime)

    self.GrenadePrimeTime = CurTime()
    local alt = self:GetOwner():KeyDown(IN_ATTACK2)
    self:SetGrenadeAlt(alt)
    self:SetGrenadePrimed(true)

    local anim = alt and self:SelectAnimation("pre_throw_alt") or self:SelectAnimation("pre_throw")
    self:PlayAnimation(anim, 1, false, 0, true)

    self.isCooked = (!alt and self:GetBuff("CookPrimFire", true)) or (alt and self:GetBuff("CookAltFire", true)) or nil

    self:GetBuff_Hook("Hook_PreThrow")

    if self.PullPinTime == 0 then
        self:Throw()
        return
    end
end

function SWEP:Throw()
    if self:GetNextPrimaryFire() > CurTime() then return end

    local isCooked = self.isCooked
    self:SetGrenadePrimed(false)
    self.isCooked = nil

    local alt = self:GetGrenadeAlt()

    local anim = alt and self:SelectAnimation("throw_alt") or self:SelectAnimation("throw")
    self:PlayAnimation(anim, 1, false, 0, true)

    local heldtime = CurTime() - self.GrenadePrimeTime

    local mv = 0

    if alt then
        mv = self:GetBuff("MuzzleVelocityAlt", true) or self:GetBuff("MuzzleVelocity")
    else
        mv = self:GetBuff("MuzzleVelocity")
        local chg = self:GetBuff("WindupTime")
        if chg > 0 then
            mv = Lerp(math.Clamp(heldtime / chg, 0, 1), mv * self:GetBuff("WindupMinimum"), mv)
        end
    end

    local force = mv * ArcCW.HUToM

    self:SetTimer(0.25, function()

        local rocket = self:FireRocket(self.ShootEntity, force)

        if !rocket then return end

        local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

        if ft then
            if isCooked then
                rocket.FuseTime = ft - heldtime
            else
                rocket.FuseTime = ft
            end
        end

        local phys = rocket:GetPhysicsObject()

        if GetConVar("arccw_throwinertia"):GetBool() and mv > 100 then
            phys:AddVelocity(self:GetOwner():GetVelocity())
        end

        phys:AddAngleVelocity( Vector(0, 750, 0) )

        if !self:HasInfiniteAmmo() then
            local aps = self:GetBuff("AmmoPerShot")
            local a1 = self:Ammo1()
            if self:HasBottomlessClip() or a1 >= aps then
                self:TakePrimaryAmmo(aps)
            elseif a1 < aps then
                self:SetClip1(math.min(self:GetCapacity() + self:GetChamberSize(), self:Clip1() + a1))
                self:TakePrimaryAmmo(a1)
            end

            if (self.Singleton or self:Ammo1() == 0) and !self:GetBuff_Override("Override_KeepIfEmpty", self.KeepIfEmpty) then
                self:GetOwner():StripWeapon(self:GetClass())
                return
            end
        end
    end)
    self:SetTimer(self:GetAnimKeyTime(anim), function()
        if !self:IsValid() then return end
        self:PlayAnimation("draw")
    end)

    self:SetNextPrimaryFire(CurTime() + 1)
    self:SetGrenadeAlt(false)

    self:GetBuff_Hook("Hook_PostThrow")
end

function SWEP:GrenadeDrop(doammo)
    local rocket = self:FireRocket(self.ShootEntity, 0)

    if IsValid(rocket) then
        local phys = rocket:GetPhysicsObject()

        if GetConVar("arccw_throwinertia"):GetBool() then
            phys:AddVelocity(self:GetOwner():GetVelocity())
        end

        local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

        if ft then
            if self.isCooked then
                rocket.FuseTime = ft - (CurTime() - self.GrenadePrimeTime)
            else
                rocket.FuseTime = ft
            end
        end
    end

    if doammo then
        if !self:HasInfiniteAmmo() then
            local aps = self:GetBuff("AmmoPerShot")
            local a1 = self:Ammo1()
            if self:HasBottomlessClip() or a1 >= aps then
                self:TakePrimaryAmmo(aps)
            elseif a1 < aps then
                self:SetClip1(math.min(self:GetCapacity() + self:GetChamberSize(), self:Clip1() + a1))
                self:TakePrimaryAmmo(a1)
            end

            if (self.Singleton or self:Ammo1() == 0) and !self:GetBuff_Override("Override_KeepIfEmpty", self.KeepIfEmpty) then
                self:GetOwner():StripWeapon(self:GetClass())
                return
            end
        end

        self:SetNextPrimaryFire(CurTime() + 1)
        self:SetGrenadePrimed(false)
    end
end