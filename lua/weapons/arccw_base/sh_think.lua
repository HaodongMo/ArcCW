if CLIENT then
    ArcCW.LastWeapon = nil
end

local lastUBGL = 0
local LastAttack2 = false

function SWEP:Think()
    local owner = self:GetOwner()

    if !IsValid(owner) or owner:IsNPC() then return end

    local vm = owner:GetViewModel()

    self.BurstCount = self:GetBurstCount()

    if owner:KeyPressed(IN_ATTACK) then
        self:SetReqEnd(true)
    end

    if CLIENT then
        if ArcCW.LastWeapon != self then
            self:LoadPreset("autosave")
        end

        ArcCW.LastWeapon = self
    end

    self:InBipod()

    if self:GetNeedCycle() and !self:GetReloading() and self:GetWeaponOpDelay() < CurTime() and self:GetNextPrimaryFire() < CurTime() and -- Adding this delays bolting if the RPM is too low, but removing it may reintroduce the double pump bug. Increasing the RPM allows you to shoot twice on many multiplayer servers. Sure would be convenient if everything just worked nicely
            (!GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 or !owner:KeyDown(IN_ATTACK))
            or GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 or owner:KeyPressed(IN_ATTACK))) then
        local anim = self:SelectAnimation("cycle")
        anim = self:GetBuff_Hook("Hook_SelectCycleAnimation", anim) or anim
        local mult = self:GetBuff_Mult("Mult_CycleTime")
        self:PlayAnimation(anim, mult, true, 0, true)
        self:SetNeedCycle(false)
    end

    if self:GetGrenadePrimed() and !owner:KeyDown(IN_ATTACK) and (!game.SinglePlayer() or SERVER) then
        self:Throw()
    end

    if self:GetGrenadePrimed() and self.GrenadePrimeTime > 0 then
        local heldtime = (CurTime() - self.GrenadePrimeTime)

        local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

        if ft and (heldtime >= ft) and (!game.SinglePlayer() or SERVER) then
            self:Throw()
        end
    end

    if owner:KeyReleased(IN_USE) then
        if self:InBipod() then
            self:ExitBipod()
        else
            self:EnterBipod()
        end
    end

    if self:GetBuff_Override("Override_TriggerDelay", self.TriggerDelay) then
        self:DoTriggerDelay()
    end

    if self:GetCurrentFiremode().RunawayBurst and self:Clip1() > 0 then
        if self:GetBurstCount() > 0 then
            self:PrimaryAttack()
        end

        if self:GetBurstCount() == self:GetBurstLength() then
            self:SetBurstCount(0)
            if !self:GetCurrentFiremode().AutoBurst then
                self.Primary.Automatic = false
            end
        end
    end

    if owner:KeyReleased(IN_ATTACK) then
        if !self:GetCurrentFiremode().RunawayBurst then
            self:SetBurstCount(0)
        end

        if self:GetCurrentFiremode().Mode < 0 and !self:GetCurrentFiremode().RunawayBurst then
            local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

            if (CurTime() + postburst) > self:GetWeaponOpDelay() then
                --self:SetNextPrimaryFire(CurTime() + postburst)
                self:SetWeaponOpDelay(CurTime() + postburst * self:GetBuff_Mult("Mult_PostBurstDelay") + self:GetBuff_Add("Add_PostBurstDelay"))
            end
        end
    end

    if IsFirstTimePredicted() then
        if self:InSprint() and (!self.Sprinted or self:GetState() != ArcCW.STATE_SPRINT) then
            self:EnterSprint()
        elseif !self:InSprint() and (self.Sprinted or self:GetState() == ArcCW.STATE_SPRINT) then
            self:ExitSprint()
        end
    end

    if owner and owner:GetInfoNum("arccw_automaticreload", 0) == 1 and self:Clip1() == 0 and !self:GetReloading() and CurTime() > self:GetNextPrimaryFire() + 0.2 then
        self:Reload()
    end

    if owner:GetInfoNum("arccw_altfcgkey", 0) == 1 and owner:KeyPressed(IN_RELOAD) and owner:KeyDown(IN_USE) then
        if (lastfiremode or 0) + 0.1 < CurTime() then
            lastfiremode = CurTime()
            if CLIENT then
                net.Start("arccw_firemode")
                net.SendToServer()
                self:ChangeFiremode()
            end
        end
    elseif (!(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and (self:GetReloading() or owner:KeyDown(IN_RELOAD))) then
        if !(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and self:GetReloading() then
            self:ExitSights()
        end
    end

    if owner:GetInfoNum("arccw_altubglkey", 0) == 1 and self:GetBuff_Override("UBGL") and owner:KeyDown(IN_USE) then
        if owner:KeyDown(IN_ATTACK2) and CLIENT then
            if (lastUBGL or 0) + 0.25 > CurTime() then return end
            lastUBGL = CurTime()
            if self:GetInUBGL() then
                net.Start("arccw_ubgl")
                net.WriteBool(false)
                net.SendToServer()

                self:DeselectUBGL()
            else
                net.Start("arccw_ubgl")
                net.WriteBool(true)
                net.SendToServer()

                self:SelectUBGL()
            end
        end
    elseif self:GetBuff_Hook("Hook_ShouldNotSight") and (self.Sighted or self:GetState() == ArcCW.STATE_SIGHTS) then
        self:ExitSights()
    else

        -- no it really doesn't, past me
        local sighted = self:GetState() == ArcCW.STATE_SIGHTS
        local toggle = self:GetOwner():GetInfoNum("arccw_toggleads", 0) >= 1
        local sp_cl = game.SinglePlayer() and CLIENT

        -- if in singleplayer, client realm should be completely ignored
        if toggle and !sp_cl then
            if owner:KeyPressed(IN_ATTACK2) then
                if sighted then
                    self:ExitSights()
                else
                    self:EnterSights()
                end
            end
        elseif !toggle then
            if owner:KeyDown(IN_ATTACK2) and !sighted then
                self:EnterSights()
            elseif !owner:KeyDown(IN_ATTACK2) and sighted then
                self:ExitSights()
            end
        end

    end

    if (CLIENT or game.SinglePlayer()) and (IsFirstTimePredicted() or game.SinglePlayer()) then
        self:ProcessRecoil()
    end

    if CLIENT and IsValid(vm) then
        local vec1 = Vector(1, 1, 1)
        local vec0 = vec1 * 0

        for i = 1, vm:GetBoneCount() do
            vm:ManipulateBoneScale(i, vec1)
        end

        for i, k in pairs(self:GetBuff_Override("Override_CaseBones", self.CaseBones) or {}) do
            if !isnumber(i) then continue end
            for _, b in pairs(istable(k) and k or {k}) do
                local bone = vm:LookupBone(b)

                if !bone then continue end

                if self:GetVisualClip() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                else
                    vm:ManipulateBoneScale(bone, vec0)
                end
            end
        end

        for i, k in pairs(self:GetBuff_Override("Override_BulletBones", self.BulletBones) or {}) do
            if !isnumber(i) then continue end
            for _, b in pairs(istable(k) and k or {k}) do
                local bone = vm:LookupBone(b)

                if !bone then continue end

                if self:GetVisualBullets() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                else
                    vm:ManipulateBoneScale(bone, vec0)
                end
            end
        end

        for i, k in pairs(self:GetBuff_Override("Override_StripperClipBones", self.StripperClipBones) or {}) do
            if !isnumber(i) then continue end
            for _, b in pairs(istable(k) and k or {k}) do
                local bone = vm:LookupBone(b)

                if !bone then continue end

                if self:GetVisualLoadAmount() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                else
                    vm:ManipulateBoneScale(bone, vec0)
                end
            end
        end
    end

    self:DoHeat()

    -- if CLIENT then
        -- if !IsValid(ArcCW.InvHUD) then
        --     gui.EnableScreenClicker(false)
        -- end

        -- if self:GetState() != ArcCW.STATE_CUSTOMIZE then
        --     self:CloseCustomizeHUD()
        -- else
        --     self:OpenCustomizeHUD()
        -- end
    -- end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.DamagePerSecond then
            local dmg = atttbl.DamagePerSecond * FrameTime()

            self:DamageAttachment(i, dmg)
        end
    end

    if CLIENT then
        self:DoOurViewPunch()
    end

    if self.Throwing and self:Clip1() == 0 and self:Ammo1() > 0 then
        self:SetClip1(1)
        owner:SetAmmo(self:Ammo1() - 1, self.Primary.Ammo)
    end

    -- self:RefreshBGs()

    if self:GetMagUpIn() != 0 and CurTime() > self:GetMagUpIn() then
        self:WhenTheMagUpIn()
        self:SetMagUpIn( 0 )
    end

    self:GetBuff_Hook("Hook_Think")

    -- Running this only serverside in SP breaks animation processing and causes CheckpointAnimation to !reset.
    --if SERVER or !game.SinglePlayer() then
        self:ProcessTimers()
    --end
end

function SWEP:ProcessRecoil()
    local owner = self:GetOwner()
    local ft = FrameTime()
    local newang = owner:EyeAngles()
    local r = self.RecoilAmount -- self:GetNWFloat("recoil", 0)
    local rs = self.RecoilAmountSide -- self:GetNWFloat("recoilside", 0)

    local ra = Angle(0, 0, 0)

    ra = ra + ((self:GetBuff_Override("Override_RecoilDirection") or self.RecoilDirection) * self.RecoilAmount * 0.5)
    ra = ra + ((self:GetBuff_Override("Override_RecoilDirectionSide") or self.RecoilDirectionSide) * self.RecoilAmountSide * 0.5)

    newang = newang - ra

    -- self.RecoilAmount = r - math.Clamp(ft * 20, 0, r)
    -- self.RecoilAmountSide = rs - math.Clamp(ft * 20, 0, rs)

    self.RecoilAmount = math.Approach(self.RecoilAmount, 0, ft * 20 * r)
    self.RecoilAmountSide = math.Approach(self.RecoilAmountSide, 0, ft * 20 * rs)

    -- self:SetNWFloat("recoil", r - (FrameTime() * r * 50))
    -- self:SetNWFloat("recoilside", rs - (FrameTime() * rs * 50))

    local rpb = self.RecoilPunchBack
    local rps = self.RecoilPunchSide
    local rpu = self.RecoilPunchUp

    if rpb != 0 then
        self.RecoilPunchBack = math.Approach(rpb, 0, ft * rpb * 2.5)
    end

    if rps != 0 then
        self.RecoilPunchSide = math.Approach(rps, 0, ft * rps * 5)
    end

    if rpu != 0 then
        self.RecoilPunchUp = math.Approach(rpu, 0, ft * rpu * 5)
    end
end

function SWEP:InSprint()
    local owner = self:GetOwner()

    local sm = self.SpeedMult * self:GetBuff_Mult("Mult_SpeedMult") * self:GetBuff_Mult("Mult_MoveSpeed")

    sm = math.Clamp(sm, 0, 1)

    local sprintspeed = owner:GetRunSpeed() * sm
    local walkspeed = owner:GetWalkSpeed() * sm

    local curspeed = owner:GetVelocity():Length()

    if TTT2 and owner.isSprinting == true then
        return (owner.sprintProgress or 0) > 0 and owner:KeyDown(IN_SPEED) and curspeed > walkspeed and owner:OnGround()
    end

    if !owner:KeyDown(IN_SPEED) then return false end
    if curspeed < Lerp(0.5, walkspeed, sprintspeed) then return false end
    if !owner:OnGround() then return false end

    return true
end

SWEP.LastTriggerTime = 0
SWEP.LastTriggerDuration = 0
function SWEP:GetTriggerDelta()
    if self.LastTriggerTime == -1 then return 0 end
    return math.Clamp((CurTime() - self.LastTriggerTime) / self.LastTriggerDuration, 0, 1)
end

function SWEP:DoTriggerDelay()
    local shouldHold = self:GetOwner():KeyDown(IN_ATTACK) and (!self.Sprinted or self:GetState() != ArcCW.STATE_SPRINT)

    if self.LastTriggerTime == -1 then
        if !shouldHold then
            self.LastTriggerTime = 0 -- Good to fire again
            self.LastTriggerDuration = 0
        end
        return
    end

    if self:GetBurstCount() > 0 and self:GetCurrentFiremode().Mode == 1 then
        self.LastTriggerTime = -1 -- Cannot fire again until trigger released
        self.LastTriggerDuration = 0
    elseif self.LastTriggerTime > 0 and !shouldHold then
        -- Attack key is released. Stop the animation and clear progress
        local anim = self:SelectAnimation("untrigger")
        if anim then
            self:PlayAnimation(anim, self:GetBuff_Mult("Mult_TriggerDelayTime"), true, 0)
            --self:SetNextPrimaryFire(CurTime() + self:GetAnimKeyTime(anim))
        else
            self:PlayIdleAnimation(true)
        end
        self.LastTriggerTime = 0
        self.LastTriggerDuration = 0
        return
    elseif self:GetNextPrimaryFire() < CurTime() and self.LastTriggerTime == 0 and shouldHold then
        -- We haven't played the animation yet. Pull it!
        local anim = self:SelectAnimation("trigger")
        self:PlayAnimation(anim, self:GetBuff_Mult("Mult_TriggerDelayTime"), true, 0)
        self.LastTriggerTime = CurTime()
        self.LastTriggerDuration = self:GetAnimKeyTime(anim, true) * self:GetBuff_Mult("Mult_TriggerDelayTime")
    end
end
