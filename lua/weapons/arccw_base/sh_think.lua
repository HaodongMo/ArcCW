if CLIENT then
    ArcCW.LastWeapon = nil
end

local lastUBGL = 0

function SWEP:Think()
    local owner = self:GetOwner()

    if !IsValid(owner) or owner:IsNPC() then return end

    local vm = owner:GetViewModel()

    if owner:KeyPressed(IN_ATTACK) then
        self:SetNWBool("reqend", true)
    end

    if CLIENT then
        if ArcCW.LastWeapon != self then
            self:LoadPreset("autosave")
        end

        ArcCW.LastWeapon = self
    end

    self:InBipod()

    if IsFirstTimePredicted() and self:GetNWBool("cycle", false) and !self:GetNWBool("reloading", false) and
            (!GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 or !owner:KeyDown(IN_ATTACK))
            or GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 and owner:KeyDown(IN_ATTACK) or owner:KeyPressed(IN_ATTACK))) then
        local anim = "cycle"
        if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations.cycle_iron then
            anim = "cycle_iron"
        end
        anim = self:GetBuff_Hook("Hook_SelectCycleAnimation", anim) or anim
        local mult = self:GetBuff_Mult("Mult_CycleTime")
        self:PlayAnimation(anim, mult, true, 0, true)
        self:SetNWBool("cycle", false)
    end

    if self:GetNWBool("grenadeprimed") and !owner:KeyDown(IN_ATTACK) then
        self:Throw()
    end

    if self:GetNWBool("grenadeprimed") and self.GrenadePrimeTime > 0 then
        local heldtime = (CurTime() - self.GrenadePrimeTime)

        if self.FuseTime and (heldtime >= self.FuseTime) then
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

    if self:GetCurrentFiremode().RunawayBurst and self:Clip1() > 0 then
        if self.BurstCount > 0 then
            self:PrimaryAttack()
        end

        if self.BurstCount == self:GetBurstLength() then
            self.Primary.Automatic = false
            self.BurstCount = 0
        end
    end

    if owner:KeyReleased(IN_ATTACK) then
        if !self:GetCurrentFiremode().RunawayBurst then
            self.BurstCount = 0
        end

        if self:GetCurrentFiremode().Mode < 0 and !self:GetCurrentFiremode().RunawayBurst then
            local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

            if (CurTime() + postburst) > self:GetNextPrimaryFire() then
            self:SetNextPrimaryFire(CurTime() + postburst)
            end
        end
    end

    if game.SinglePlayer() or IsFirstTimePredicted() then
        if self:InSprint() and (!self.Sprinted or self:GetState() != ArcCW.STATE_SPRINT) then
            self:EnterSprint()
        elseif !self:InSprint() and (self.Sprinted or self:GetState() == ArcCW.STATE_SPRINT) then
            self:ExitSprint()
        end
    end

    -- That seems a good way to do such things
    -- local altlaser = owner:GetInfoNum("arccw_altlaserkey", 0) == 1
    -- local laserdown, laserpress = altlaser and IN_USE or IN_WALK, altlaser and IN_WALK or IN_USE -- Can't find good alt keys

    -- if owner:KeyDown(laserdown) and owner:KeyPressed(laserpress) then
    --     self:SetNWBool("laserenabled", not self:GetNWBool("laserenabled", true))
    -- end

    -- Yeah, this would be OP unless we can also turn off the laser stats, too.

    if owner:GetInfoNum("arccw_altfcgkey", 0) == 1 and owner:KeyPressed(IN_RELOAD) and owner:KeyDown(IN_USE) then
        if (lastfiremode or 0) + 0.1 < CurTime() then
            lastfiremode = CurTime()
            if CLIENT then
                net.Start("arccw_firemode")
                net.SendToServer()
                self:ChangeFiremode()
            end
        end
    elseif (!(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and (self:GetNWBool("reloading", false) or owner:KeyDown(IN_RELOAD))) then
        if !(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and self:GetNWBool("reloading", false) then
            self:ExitSights()
        end
    end

    if owner:GetInfoNum("arccw_altubglkey", 0) == 1 and self:GetBuff_Override("UBGL") and owner:KeyDown(IN_USE) then
        if owner:KeyDown(IN_ATTACK2) and CLIENT then
            if (lastUBGL or 0) + 0.25 > CurTime() then return end
            lastUBGL = CurTime()
            if self:GetNWBool("ubgl") then
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

        if game.SinglePlayer() or IsFirstTimePredicted() then
            -- everything here has to be predicted for the first time
            if owner:GetInfoNum("arccw_toggleads", 0) == 0 then
                if owner:KeyDown(IN_ATTACK2) and (!self.Sighted or self:GetState() != ArcCW.STATE_SIGHTS) then
                    self:EnterSights()
                elseif !owner:KeyDown(IN_ATTACK2) and (self.Sighted or self:GetState() == ArcCW.STATE_SIGHTS) then
                    self:ExitSights()
                end
            else
                if owner:KeyDown(IN_ATTACK2) then
                    if !self.Sighted or self:GetState() != ArcCW.STATE_SIGHTS then
                        self:EnterSights()
                    else
                        self:ExitSights()
                    end
                end
            end
        end

    end

    if (CLIENT or game.SinglePlayer()) and (IsFirstTimePredicted() or game.SinglePlayer()) then
        local ft = FrameTime()
        -- if CLIENT then
        --    ft = RealFrameTime()
        -- end

        local newang = owner:EyeAngles()
        local r = self.RecoilAmount -- self:GetNWFloat("recoil", 0)
        local rs = self.RecoilAmountSide -- self:GetNWFloat("recoilside", 0)

        local ra = Angle(0, 0, 0)

        ra = ra + ((self:GetBuff_Override("Override_RecoilDirection") or self.RecoilDirection) * self.RecoilAmount * 0.5)
        ra = ra + ((self:GetBuff_Override("Override_RecoilDirectionSide") or self.RecoilDirectionSide) * self.RecoilAmountSide * 0.5)

        newang = newang - ra

        self.RecoilAmount = r - (ft * r * 20)
        self.RecoilAmountSide = rs - (ft * rs * 20)

        self.RecoilAmount = math.Approach(self.RecoilAmount, 0, ft * 0.1)
        self.RecoilAmountSide = math.Approach(self.RecoilAmountSide, 0, ft * 0.1)

        -- self:SetNWFloat("recoil", r - (FrameTime() * r * 50))
        -- self:SetNWFloat("recoilside", rs - (FrameTime() * rs * 50))

        owner:SetEyeAngles(newang)

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

        if IsValid(vm) then
            local vec1 = Vector(1, 1, 1)
            local vec0 = vec1 * 0

            for i = 1, vm:GetBoneCount() do
                vm:ManipulateBoneScale(i, vec1 )
            end

            for i, k in pairs(self.CaseBones or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                vm:ManipulateBoneScale(bone, vec0)
            end

            for i, k in pairs(self.BulletBones or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                vm:ManipulateBoneScale(bone, vec0)
            end

            for i, k in pairs(self.CaseBones or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualClip() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                end
            end

            for i, k in pairs(self.BulletBones or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualBullets() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                end
            end

            for i, k in pairs(self.StripperClipBones or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualLoadAmount() >= i then
                    vm:ManipulateBoneScale(bone, vec1)
                else
                    vm:ManipulateBoneScale(bone, vec0)
                end
            end

        end
    end

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

    if SERVER and self.Throwing and self:Clip1() == 0 and self:Ammo1() > 0 then
        self:SetClip1(1)
        owner:SetAmmo(self:Ammo1() - 1, self.Primary.Ammo)
    end

    -- self:RefreshBGs()

    self:GetBuff_Hook("Hook_Think")

    -- Running this only serverside in SP breaks animation processing and causes CheckpointAnimation to not reset.
    --if SERVER or !game.SinglePlayer() then
        self:ProcessTimers()
    --end
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