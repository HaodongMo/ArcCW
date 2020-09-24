
function SWEP:SelectUBGL()
    self:SetNWBool("ubgl", true)

    if !IsFirstTimePredicted() then return end

    self:MyEmitSound(self.SelectUBGLSound)
    self:SetNWInt("firemode", 1)

    if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint("Selected " .. self:GetBuff_Override("UBGL_PrintName") or "UBGL")
        end
        if !self:GetLHIKAnim() then
            self:DoLHIKAnimation("enter")
        end
    end

    if self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.enter_ubgl_empty and self:Clip2() == 0 then
        self:PlayAnimation("enter_ubgl_empty", 1, false, 0, true)
        self:SetNextSecondaryFire(CurTime() + self:GetAnimKeyTime("enter_ubgl_empty"))
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.enter_ubgl then
        self:PlayAnimation("enter_ubgl", 1, false, 0, true)
        self:SetNextSecondaryFire(CurTime() + self:GetAnimKeyTime("enter_ubgl"))
    end

    self:GetBuff_Hook("Hook_OnSelectUBGL")
end

function SWEP:DeselectUBGL()
    if !self:GetNWBool("ubgl", false) then return end
    self:SetNWBool("ubgl", false)

    if !IsFirstTimePredicted() then return end

    self:MyEmitSound(self.ExitUBGLSound)

    if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint("Deselected " .. self:GetBuff_Override("UBGL_PrintName") or "UBGL")
        end
        if !self:GetLHIKAnim() then
            self:DoLHIKAnimation("exit")
        end
    end

    if self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.exit_ubgl_empty and self:Clip2() == 0 then
        self:PlayAnimation("exit_ubgl_empty", 1, false, 0, true)
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.exit_ubgl then
        self:PlayAnimation("exit_ubgl", 1, false, 0, true)
    end

    self:GetBuff_Hook("Hook_OnDeselectUBGL")
end

function SWEP:RecoilUBGL()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end
    if game.SinglePlayer() and self:GetOwner():IsValid() and SERVER then
        self:CallOnClient("RecoilUBGL")
    end

    local amt = self:GetBuff_Override("UBGL_Recoil")
    local amtside = self:GetBuff_Override("UBGL_RecoilSide") or (self:GetBuff_Override("UBGL_Recoil") * 0.5)
    local amtrise = self:GetBuff_Override("UBGL_RecoilRise") or 1

    local r = math.Rand(-1, 1)
    local ru = math.Rand(0.75, 1.25)

    local m = 1 * amt
    local rs = 1 * amtside
    local vsm = 1

    local vpa = Angle(0, 0, 0)

    vpa = vpa + (Angle(1, 0, 0) * amt * m * vsm)

    vpa = vpa + (Angle(0, 1, 0) * r * amtside * m * vsm)

    if CLIENT then
        self:OurViewPunch(vpa)
    end
    -- self:SetNWFloat("recoil", self.Recoil * m)
    -- self:SetNWFloat("recoilside", r * self.RecoilSide * m)

    if CLIENT or game.SinglePlayer() then

        self.RecoilAmount = self.RecoilAmount + (amt * m)
        self.RecoilAmountSide = self.RecoilAmountSide + (r * amtside * m * rs)

        self.RecoilPunchBack = amt * 2.5 * m

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = r * rs * m * 0.1 * vsm
        self.RecoilPunchUp = math.Clamp(ru * amt * m * 0.6 * vsm * amtrise, 0, 0.1)
    end
end

function SWEP:ShootUBGL()
    if self:GetNextSecondaryFire() > CurTime() then return end
    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return false end

    self.Primary.Automatic = self:GetBuff_Override("UBGL_Automatic")

    local ubglammo = self:GetBuff_Override("UBGL_Ammo")

    if self:Clip2() <= 0 and self:GetOwner():GetAmmoCount(ubglammo) <= 0 then
        self.Primary.Automatic = false
        self:DeselectUBGL()
        return
    end

    if self:Clip2() <= 0 then
        return
    end

    self:RecoilUBGL()

    local func, slot = self:GetBuff_Override("UBGL_Fire")

    if func then
        func(self, self.Attachments[slot].VElement)
    end

    self:SetNextSecondaryFire(CurTime() + (60 / self:GetBuff_Override("UBGL_RPM")))
end

function SWEP:ReloadUBGL()
    if self:GetNextSecondaryFire() > CurTime() then return end

    local reloadfunc, slot = self:GetBuff_Override("UBGL_Reload")

    if reloadfunc then
        reloadfunc(self, self.Attachments[slot].VElement)
    end
end