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

    if engine.ActiveGamemode() == "terrortown" and GetRoundState and GetRoundState() == ROUND_PREP and
        ((GetConVar("ttt_no_nade_throw_during_prep") and GetConVar("ttt_no_nade_throw_during_prep"):GetBool())
            or (GetConVar("ttt_nade_throw_during_prep") and !GetConVar("ttt_nade_throw_during_prep"):GetBool())) then
        return
    end

    self.GrenadePrimeTime = CurTime()
    local alt = self:GetOwner():KeyDown(IN_ATTACK2)
    self:SetGrenadeAlt(alt)
    self:SetGrenadePrimed(true)

    local pulltime = self:GetBuff("PullPinTime")
    local anim = alt and self:SelectAnimation("pre_throw_alt") or self:SelectAnimation("pre_throw")
    self:PlayAnimation(anim, self.PullPinTime / pulltime, true, 0, true, nil, true)

    self.isCooked = (!alt and self:GetBuff("CookPrimFire", true)) or (alt and self:GetBuff("CookAltFire", true)) or nil

    self:SetNextPrimaryFire(CurTime() + pulltime)
    self:SetPriorityAnim(CurTime() + pulltime)

    self:SetShouldHoldType()

    self:GetBuff_Hook("Hook_PreThrow")

    if pulltime == 0 then
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
    self:PlayAnimation(anim, self:GetBuff_Mult("Mult_ThrowTime"), false, 0, true)

    local animevent = alt and self:GetBuff_Override("Override_AnimShootAlt", self.AnimShootAlt) or self:GetBuff_Override("Override_AnimShoot", self.AnimShoot)
    self:GetOwner():DoAnimationEvent(animevent)

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

    self:SetTimer(self:GetBuff("ShootEntityDelay"), function()

        local ft = self:GetBuff("FuseTime", true)
        local data = {
            dodefault = true,
            force = force,
            shootentity = self:GetBuff_Override("Override_ShootEntity", self.ShootEntity),
            fusetime = ft and (ft - (isCooked and heldtime or 0)),
        }
        local ovr = self:GetBuff_Hook("Hook_Throw", data)
        if !ovr or ovr.dodefault then
            local rocket = self:FireRocket(self:GetBuff_Override("Override_ShootEntity", self.ShootEntity), force / ArcCW.HUToM)
            if !rocket then return end

            if ft then
                if isCooked then
                    rocket.FuseTime = ft - heldtime
                else
                    rocket.FuseTime = ft
                end
            else
                rocket.FuseTime = math.huge
            end

            local phys = rocket:GetPhysicsObject()

            local inertia = self:GetBuff_Override("Override_ThrowInertia", self.ThrowInertia)
            if inertia == nil then inertia = GetConVar("arccw_throwinertia"):GetBool() end
            if inertia and mv > 100 then
                phys:AddVelocity(self:GetOwner():GetVelocity())
            end

            phys:AddAngleVelocity( Vector(0, 750, 0) )
        end
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
    local t = self:GetAnimKeyTime(anim) * self:GetBuff_Mult("Mult_ThrowTime")
    self:SetPriorityAnim(CurTime() + t)
    self:SetTimer(t, function()
        if !self:IsValid() then return end
        local a = self:SelectAnimation("reload") or self:SelectAnimation("draw")
        self:PlayAnimation(a, self:GetBuff_Mult("Mult_ReloadTime"), true, 0, nil, nil, true)
        self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime(a, true) * self:GetBuff_Mult("Mult_ReloadTime"))
    end)

    self:SetNextPrimaryFire(CurTime() + self:GetFiringDelay())

    self:SetGrenadeAlt(false)

    self:SetShouldHoldType()

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