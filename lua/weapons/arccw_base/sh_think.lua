if CLIENT then
    ArcCW.LastWeapon = nil
end

local vec1 = Vector(1, 1, 1)
local vec0 = vec1 * 0
local ang0 = Angle(0, 0, 0)

local lastUBGL = 0
function SWEP:Think()
    if IsValid(self:GetOwner()) and self:GetClass() == "arccw_base" then
        self:Remove()
        return
    end

    local owner = self:GetOwner()

    if !IsValid(owner) or owner:IsNPC() then return end

    if self:GetState() == ArcCW.STATE_DISABLE and !self:GetPriorityAnim() then
        self:SetState(ArcCW.STATE_IDLE)
    end

    for i, v in ipairs(self.EventTable) do
        for ed, bz in pairs(v) do
            if ed <= CurTime() then
                if bz.AnimKey and (bz.AnimKey != self.LastAnimKey or bz.StartTime != self.LastAnimStartTime) then
                    continue
                end
                self:PlayEvent(bz)
                self.EventTable[i][ed] = nil
                --print(CurTime(), "Event completed at " .. i, ed)
                if table.IsEmpty(v) and i != 1 then self.EventTable[i] = nil --[[print(CurTime(), "No more events at " .. i .. ", killing")]] end
            end
        end
    end

    if CLIENT and (!game.SinglePlayer() and IsFirstTimePredicted() or true)
            and self:GetOwner() == LocalPlayer() and ArcCW.InvHUD
            and !ArcCW.Inv_Hidden and ArcCW.Inv_Fade == 0 then
        ArcCW.InvHUD:Remove()
        ArcCW.Inv_Fade = 0.01
    end

    local vm = owner:GetViewModel()

    self.BurstCount = self:GetBurstCount()

    local sg = self:GetShotgunReloading()
    if (sg == 2 or sg == 4) and owner:KeyPressed(IN_ATTACK) then
        self:SetShotgunReloading(sg + 1)
    elseif (sg >= 2) and self:GetReloadingREAL() <= CurTime() then
        self:ReloadInsert((sg >= 4) and true or false)
    end

    self:InBipod()

    if self:GetNeedCycle() and !self.Throwing and !self:GetReloading() and self:GetWeaponOpDelay() < CurTime() and self:GetNextPrimaryFire() < CurTime() and -- Adding this delays bolting if the RPM is too low, but removing it may reintroduce the double pump bug. Increasing the RPM allows you to shoot twice on many multiplayer servers. Sure would be convenient if everything just worked nicely
            (!GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 or !owner:KeyDown(IN_ATTACK))
            or GetConVar("arccw_clicktocycle"):GetBool() and (self:GetCurrentFiremode().Mode == 2 or owner:KeyPressed(IN_ATTACK))) then
        local anim = self:SelectAnimation("cycle")
        anim = self:GetBuff_Hook("Hook_SelectCycleAnimation", anim) or anim
        local mult = self:GetBuff_Mult("Mult_CycleTime")
        local p = self:PlayAnimation(anim, mult, true, 0, true)
        if p then
            self:SetNeedCycle(false)
            self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime(anim, true) * mult)
        end
    end

    if self:GetGrenadePrimed() and !(owner:KeyDown(IN_ATTACK) or owner:KeyDown(IN_ATTACK2)) and (!game.SinglePlayer() or SERVER) then
        self:Throw()
    end

    if self:GetGrenadePrimed() and self.GrenadePrimeTime > 0 and self.isCooked then
        local heldtime = (CurTime() - self.GrenadePrimeTime)

        local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

        if ft and (heldtime >= ft) and (!game.SinglePlayer() or SERVER) then
            self:Throw()
        end
    end

    if IsFirstTimePredicted() and self:GetNextPrimaryFire() < CurTime() and owner:KeyReleased(IN_USE) then
        if self:InBipod() then
            self:ExitBipod()
        else
            self:EnterBipod()
        end
    end

    if ((game.SinglePlayer() and SERVER) or (!game.SinglePlayer() and true)) and self:GetBuff_Override("Override_TriggerDelay", self.TriggerDelay) then
        if owner:KeyReleased(IN_ATTACK) and self:GetBuff_Override("Override_TriggerCharge", self.TriggerCharge) and self:GetTriggerDelta(true) >= 1 then
            self:PrimaryAttack()
        else
            self:DoTriggerDelay()
        end
    end

    if self:GetCurrentFiremode().RunawayBurst then

        if self:GetBurstCount() > 0 and ((game.SinglePlayer() and SERVER) or (!game.SinglePlayer() and true)) then
            self:PrimaryAttack()
        end

        if self:Clip1() < self:GetBuff("AmmoPerShot") or self:GetBurstCount() == self:GetBurstLength() then
            self:SetBurstCount(0)
            if !self:GetCurrentFiremode().AutoBurst then
                self.Primary.Automatic = false
            end
        end
    end

    if owner:KeyReleased(IN_ATTACK) then

        if !self:GetCurrentFiremode().RunawayBurst then
            self:SetBurstCount(0)
            self.LastTriggerTime = -1 -- Cannot fire again until trigger released
            self.LastTriggerDuration = 0
        end

        if self:GetCurrentFiremode().Mode < 0 and !self:GetCurrentFiremode().RunawayBurst then
            local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

            if (CurTime() + postburst) > self:GetWeaponOpDelay() then
                --self:SetNextPrimaryFire(CurTime() + postburst)
                self:SetWeaponOpDelay(CurTime() + postburst * self:GetBuff_Mult("Mult_PostBurstDelay") + self:GetBuff_Add("Add_PostBurstDelay"))
            end
        end
    end

    if owner and owner:GetInfoNum("arccw_automaticreload", 0) == 1 and self:Clip1() == 0 and !self:GetReloading() and CurTime() > self:GetNextPrimaryFire() + 0.2 then
        self:Reload()
    end

    if (!(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and (self:GetReloading() or owner:KeyDown(IN_RELOAD))) then
        if !(self:GetBuff_Override("Override_ReloadInSights") or self.ReloadInSights) and self:GetReloading() then
            self:ExitSights()
        end
    end


    if self:GetBuff_Hook("Hook_ShouldNotSight") and (self.Sighted or self:GetState() == ArcCW.STATE_SIGHTS) then
        self:ExitSights()
    elseif self:GetHolster_Time() > 0 then
        self:ExitSights()
    else

        -- no it really doesn't, past me
        local sighted = self:GetState() == ArcCW.STATE_SIGHTS
        local toggle = owner:GetInfoNum("arccw_toggleads", 0) >= 1
        local suitzoom = owner:KeyDown(IN_ZOOM)
        local sp_cl = game.SinglePlayer() and CLIENT

        -- if in singleplayer, client realm should be completely ignored
        if toggle and !sp_cl then
            if owner:KeyPressed(IN_ATTACK2) then
                if sighted then
                    self:ExitSights()
                elseif !suitzoom then
                    self:EnterSights()
                end
            elseif suitzoom and sighted then
                self:ExitSights()
            end
        elseif !toggle then
            if (owner:KeyDown(IN_ATTACK2) and !suitzoom) and !sighted then
                self:EnterSights()
            elseif (!owner:KeyDown(IN_ATTACK2) or suitzoom) and sighted then
                self:ExitSights()
            end
        end

    end

    if (!game.SinglePlayer() and IsFirstTimePredicted()) or (game.SinglePlayer() and true) then
        if self:InSprint() and (self:GetState() != ArcCW.STATE_SPRINT) then
            self:EnterSprint()
        elseif !self:InSprint() and (self:GetState() == ArcCW.STATE_SPRINT) then
            self:ExitSprint()
        end
    end

    if game.SinglePlayer() or IsFirstTimePredicted() then
        self:SetSightDelta(math.Approach(self:GetSightDelta(), self:GetState() == ArcCW.STATE_SIGHTS and 0 or 1, FrameTime() / self:GetSightTime()))
        self:SetSprintDelta(math.Approach(self:GetSprintDelta(), self:GetState() == ArcCW.STATE_SPRINT and 1 or 0, FrameTime() / self:GetSprintTime()))
    end

    if CLIENT and (game.SinglePlayer() or IsFirstTimePredicted()) then
        self:ProcessRecoil()
    end

    if CLIENT and IsValid(vm) then

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

    self:ThinkFreeAim()

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
        self:ReloadTimed()
        self:SetMagUpIn( 0 )
    end

    if self:HasBottomlessClip() and self:Clip1() != ArcCW.BottomlessMagicNumber then
        self:Unload()
        self:SetClip1(ArcCW.BottomlessMagicNumber)
    elseif !self:HasBottomlessClip() and self:Clip1() == ArcCW.BottomlessMagicNumber then
        self:SetClip1(0)
    end

    -- Performing traces in rendering contexts seem to cause flickering with c_hands that have QC attachments(?)
    -- Since we need to run the trace every tick anyways, do it here instead
    if CLIENT then
        self:BarrelHitWall()
    end

    self:GetBuff_Hook("Hook_Think")

    -- Running this only serverside in SP breaks animation processing and causes CheckpointAnimation to !reset.
    --if SERVER or !game.SinglePlayer() then
        self:ProcessTimers()
    --end

    -- Only reset to idle if we don't need cycle. empty idle animation usually doesn't play nice
    if self:GetNextIdle() != 0 and self:GetNextIdle() <= CurTime() and !self:GetNeedCycle()
            and self:GetHolster_Time() == 0 and self:GetShotgunReloading() == 0 then
        self:SetNextIdle(0)
        self:PlayIdleAnimation(true)
    end

    if self:GetUBGLDebounce() and !self:GetOwner():KeyDown(IN_RELOAD) then
        self:SetUBGLDebounce( false )
    end
end

local lst = SysTime()

function SWEP:ProcessRecoil()
    local owner = self:GetOwner()
    local ft = (SysTime() - (lst or SysTime())) * GetConVar("host_timescale"):GetFloat()
    local newang = owner:EyeAngles()
    -- local r = self.RecoilAmount -- self:GetNWFloat("recoil", 0)
    -- local rs = self.RecoilAmountSide -- self:GetNWFloat("recoilside", 0)

    local ra = Angle(ang0)

    ra = ra + (self:GetBuff_Override("Override_RecoilDirection", self.RecoilDirection) * self.RecoilAmount * 0.5)
    ra = ra + (self:GetBuff_Override("Override_RecoilDirectionSide", self.RecoilDirectionSide) * self.RecoilAmountSide * 0.5)

    newang = newang - ra

    local rpb = self.RecoilPunchBack
    local rps = self.RecoilPunchSide
    local rpu = self.RecoilPunchUp

    if rpb != 0 then
        self.RecoilPunchBack = math.Approach(rpb, 0, ft * rpb * 10)
    end

    if rps != 0 then
        self.RecoilPunchSide = math.Approach(rps, 0, ft * rps * 5)
    end

    if rpu != 0 then
        self.RecoilPunchUp = math.Approach(rpu, 0, ft * rpu * 5)
    end

    lst = SysTime()
end

function SWEP:InSprint()
    local owner = self:GetOwner()

    local sm = self.SpeedMult * self:GetBuff_Mult("Mult_SpeedMult") * self:GetBuff_Mult("Mult_MoveSpeed")

    sm = math.Clamp(sm, 0, 1)

    local sprintspeed = owner:GetRunSpeed() * sm
    local walkspeed = owner:GetWalkSpeed() * sm

    local curspeed = owner:GetVelocity():Length()

    if TTT2 and owner.isSprinting == true then
        return (owner.sprintProgress or 0) > 0 and owner:KeyDown(IN_SPEED) and !owner:Crouching() and curspeed > walkspeed and owner:OnGround()
    end

    if !owner:KeyDown(IN_SPEED) or !owner:KeyDown(IN_FORWARD+IN_MOVELEFT+IN_MOVERIGHT+IN_BACK) then return false end
    if !owner:OnGround() then return false end
    if owner:Crouching() then return false end
    if curspeed < Lerp(0.5, walkspeed, sprintspeed) then
        -- provide some grace time so changing directions won't immediately exit sprint
        self.LastExitSprintCheck = self.LastExitSprintCheck or CurTime()
        if self.LastExitSprintCheck < CurTime() - 0.25 then
            return false
        end
    else
        self.LastExitSprintCheck = nil
    end

    return true
end

function SWEP:IsTriggerHeld()
    return self:GetOwner():KeyDown(IN_ATTACK) and (self:CanShootWhileSprint() or (!self.Sprinted or self:GetState() != ArcCW.STATE_SPRINT)) and (self:GetHolster_Time() < CurTime()) and !self:GetPriorityAnim()
end

SWEP.LastTriggerTime = 0
SWEP.LastTriggerDuration = 0
function SWEP:GetTriggerDelta(noheldcheck)
    if self.LastTriggerTime <= 0 or (!noheldcheck and !self:IsTriggerHeld()) then return 0 end
    return math.Clamp((CurTime() - self.LastTriggerTime) / self.LastTriggerDuration, 0, 1)
end

function SWEP:DoTriggerDelay()
    local shouldHold = self:IsTriggerHeld()

    local reserve = self:HasBottomlessClip() and self:Ammo1() or self:Clip1()
    if self.LastTriggerTime == -1 or (!self.TriggerPullWhenEmpty and (reserve < self:GetBuff("AmmoPerShot"))) and self:GetNextPrimaryFire() < CurTime() then
        if !shouldHold then
            self.LastTriggerTime = 0 -- Good to fire again
            self.LastTriggerDuration = 0
        end
        return
    end

    if self:GetBurstCount() > 0 and self:GetCurrentFiremode().Mode == 1 then
        self.LastTriggerTime = -1 -- Cannot fire again until trigger released
        self.LastTriggerDuration = 0
    elseif self:GetNextPrimaryFire() < CurTime() and self.LastTriggerTime > 0 and !shouldHold then
        -- Attack key is released. Stop the animation and clear progress
        local anim = self:SelectAnimation("untrigger")
        if anim then
            self:PlayAnimation(anim, self:GetBuff_Mult("Mult_TriggerDelayTime"), true, 0)
        end
        self.LastTriggerTime = 0
        self.LastTriggerDuration = 0
        self:GetBuff_Hook("Hook_OnTriggerRelease")
    elseif self:GetNextPrimaryFire() < CurTime() and self.LastTriggerTime == 0 and shouldHold then
        -- We haven't played the animation yet. Pull it!
        local anim = self:SelectAnimation("trigger")
        self:PlayAnimation(anim, self:GetBuff_Mult("Mult_TriggerDelayTime"), true, 0, nil, nil, true) -- need to overwrite sprint up
        self.LastTriggerTime = CurTime()
        self.LastTriggerDuration = self:GetAnimKeyTime(anim, true) * self:GetBuff_Mult("Mult_TriggerDelayTime")
        self:GetBuff_Hook("Hook_OnTriggerHeld")
    end
end
