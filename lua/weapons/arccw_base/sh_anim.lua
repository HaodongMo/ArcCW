SWEP.Cam_Offset_Ang = Angle(0, 0, 0)

function SWEP:SelectAnimation(anim)
    if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations[anim .. "_iron"] then
        anim = anim .. "_iron"
    end

    if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations[anim .. "_sights"] then
        anim = anim .. "_sights"
    end

    if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations[anim .. "_sight"] then
        anim = anim .. "_sight"
    end

    if self:GetState() == ArcCW.STATE_SPRINT and self.Animations[anim .. "_sprint"] then
        anim = anim .. "_sprint"
    end

    if self:InBipod() and self.Animations[anim .. "_bipod"] then
        anim = anim .. "_bipod"
    end

    if self:Clip1() == 0 and self.Animations[anim .. "_empty"] then
        anim = anim .. "_empty"
    end

    if self:GetMalfunctionJam() and self.Animations[anim .. "_jammed"] then
        anim = anim .. "_jammed"
    end

    if !self.Animations[anim] then return end

    return anim
end

SWEP.LastAnimStartTime = 0
SWEP.LastAnimFinishTime = 0

function SWEP:PlayAnimationEZ(key, mult, ignorereload)
    self:PlayAnimation(key, mult, true, 0, false, false, ignorereload, false)
end

function SWEP:PlayAnimation(key, mult, pred, startfrom, tt, skipholster, ignorereload, absolute)
    mult = mult or 1
    pred = pred or false
    startfrom = startfrom or 0
    tt = tt or false
    --skipholster = skipholster or false Unused
    ignorereload = ignorereload or false
    absolute = absolute or false
    if !key then return end

    local ct = CurTime() --pred and CurTime() or UnPredictedCurTime()

    if self:GetReloading() and !ignorereload then return end

    if game.SinglePlayer() and SERVER and pred then
        net.Start("arccw_sp_anim")
        net.WriteString(key)
        net.WriteFloat(mult)
        net.WriteFloat(startfrom)
        net.WriteBool(tt)
        --net.WriteBool(skipholster) Unused
        net.WriteBool(ignorereload)
        net.Send(self:GetOwner())
    end

    local anim = self.Animations[key]
    if !anim then return end
    local tranim = self:GetBuff_Hook("Hook_TranslateAnimation", key)
    if self.Animations[tranim] then
        key = tranim
        anim = self.Animations[tranim]
    --[[elseif self.Animations[key] then -- Can't do due to backwards compatibility... unless you have a better idea?
        anim = self.Animations[key]
    else
        return]]
    end

    if anim.ViewPunchTable and CLIENT then
        for k, v in pairs(anim.ViewPunchTable) do

            if !v.t then continue end

            local st = (v.t * mult) - startfrom

            if isnumber(v.t) and st >= 0 and self:GetOwner():IsPlayer() and (game.SinglePlayer() or IsFirstTimePredicted()) then
                self:SetTimer(st, function() self:OurViewPunch(v.p or Vector(0, 0, 0)) end, id)
            end
        end
    end

    if isnumber(anim.ShellEjectAt) then
        self:SetTimer(anim.ShellEjectAt * mult, function()
            local num = 1
            if self.RevolverReload then
                num = self.Primary.ClipSize - self:Clip1()
            end
            for i = 1,num do
                self:DoShellEject()
            end
        end)
    end

    if !self:GetOwner() then return end
    if !self:GetOwner().GetViewModel then return end
    local vm = self:GetOwner():GetViewModel()

    if !vm then return end
    if !IsValid(vm) then return end

    local seq = anim.Source
    if anim.RareSource and util.SharedRandom("raresource", 1, anim.RareSourceChance or 100, CurTime()/13) <= 1 then
        seq = anim.RareSource
    end
    seq = self:GetBuff_Hook("Hook_TranslateSequence", seq)
    
    if istable(seq) then
        seq["BaseClass"] = nil
        seq = seq[math.Round(util.SharedRandom("randomseq" .. CurTime(), 1, #seq))]
    end

    if isstring(seq) then
        seq = vm:LookupSequence(seq)
    end

    local time = absolute and 1 or self:GetAnimKeyTime(key)
    --if time == 0 then return end

    local ttime = (time * mult) - startfrom
    if startfrom > (time * mult) then return end

    if tt then
        self:SetNextPrimaryFire(ct + ((anim.MinProgress or time) * mult) - startfrom)
    end

    if anim.LHIK then
        self.LHIKStartTime = ct
        self.LHIKEndTime = ct + ttime

        if anim.LHIKTimeline then
            self.LHIKTimeline = {}

            for i, k in pairs(anim.LHIKTimeline) do
                table.Add(self.LHIKTimeline, {t = (k.t or 0) * mult, lhik = k.lhik or 1})
            end
        else
            self.LHIKTimeline = {
                {t = -math.huge, lhik = 1},
                {t = ((anim.LHIKIn or 0.1) - (anim.LHIKEaseIn or anim.LHIKIn or 0.1)) * mult, lhik = 1},
                {t = (anim.LHIKIn or 0.1) * mult, lhik = 0},
                {t = ttime - ((anim.LHIKOut or 0.1) * mult), lhik = 0},
                {t = ttime - (((anim.LHIKOut or 0.1) - (anim.LHIKEaseOut or anim.LHIKOut or 0.1)) * mult), lhik = 1},
                {t = math.huge, lhik = 1}
            }

            if anim.LHIKIn == 0 then
                self.LHIKTimeline[1].lhik = -math.huge
                self.LHIKTimeline[2].lhik = -math.huge
            end

            if anim.LHIKOut == 0 then
                self.LHIKTimeline[#self.LHIKTimeline - 1].lhik = math.huge
                self.LHIKTimeline[#self.LHIKTimeline].lhik = math.huge
            end
        end
    else
        self.LHIKTimeline = nil
    end

    if anim.LastClip1OutTime then
        self.LastClipOutTime = ct + ((anim.LastClip1OutTime * mult) - startfrom)
    end

    if anim.TPAnim then
        local aseq = self:GetOwner():SelectWeightedSequence(anim.TPAnim)
        if aseq then
            self:GetOwner():AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, anim.TPAnimStartTime or 0, true )
            if !game.SinglePlayer() and SERVER then
                net.Start("arccw_networktpanim")
                    net.WriteEntity(self:GetOwner())
                    net.WriteUInt(aseq, 16)
                    net.WriteFloat(anim.TPAnimStartTime or 0)
                net.SendPVS(self:GetOwner():GetPos())
            end
        end
    end

    if !(game.SinglePlayer() and CLIENT) then
        self:PlaySoundTable(anim.SoundTable or {}, 1 / mult, startfrom)
    end

    if seq then
        vm:SendViewModelMatchingSequence(seq)
        local dur = vm:SequenceDuration()
        vm:SetPlaybackRate(math.Clamp(dur / (ttime + startfrom), -4, 12))
        self.LastAnimStartTime = ct
        self.LastAnimFinishTime = ct + dur
    end

    local att = self:GetBuff_Override("Override_CamAttachment") or self.CamAttachment -- why is this here if we just... do cool stuff elsewhere?
    if att and vm:GetAttachment(att) then
        local ang = vm:GetAttachment(att).Ang
        ang = vm:WorldToLocalAngles(ang)
        self.Cam_Offset_Ang = Angle(ang)
    end

    self:SetNextIdle(CurTime() + ttime)
end

function SWEP:PlayIdleAnimation(pred)
    local ianim
    local s = self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint
    if self:GetState() == ArcCW.STATE_SPRINT and !s then
        ianim = self:SelectAnimation("idle_sprint") or ianim
    end

    if self:InBipod() then
        ianim = self:SelectAnimation("idle_bipod") or ianim
    end

    if (self.Sighted or self:GetState() == ArcCW.STATE_SIGHTS) then
        ianim = self:SelectAnimation("idle_sight") or self:SelectAnimation("idle_sights") or ianim
    end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then
        ianim = self:SelectAnimation("idle_inspect") or ianim
    end

    -- (key, mult, pred, startfrom, tt, skipholster, ignorereload)
    if self:GetBuff_Override("UBGL_BaseAnims") and self:GetInUBGL()
            and self.Animations.idle_ubgl_empty and self:Clip2() <= 0 then
        ianim = "idle_ubgl_empty"
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self:GetInUBGL() and self.Animations.idle_ubgl then
        ianim = "idle_ubgl"
    elseif (self:Clip1() == 0 or self:GetNeedCycle()) and self.Animations.idle_empty then
        ianim = ianim or "idle_empty"
    else
        ianim = ianim or "idle"
    end
    self:PlayAnimation(ianim, 1, pred, nil, nil, nil, true)
end

function SWEP:GetAnimKeyTime(key, min)
    if !self:GetOwner() then return 1 end

    local anim = self.Animations[key]

    if !anim then return 1 end

    if self:GetOwner():IsNPC() then return anim.Time or 1 end

    local vm = self:GetOwner():GetViewModel()

    if !vm or !IsValid(vm) then return 1 end

    local t = anim.Time
    if !t then
        local tseq = anim.Source

        if istable(tseq) then
            tseq["BaseClass"] = nil -- god I hate Lua inheritance
            tseq = tseq[1]
        end

        if !tseq then return 1 end
        tseq = vm:LookupSequence(tseq)

		-- to hell with it, just spits wrong on draw sometimes
        t = vm:SequenceDuration(tseq) or 1
    end

    if min and anim.MinProgress then
        t = anim.MinProgress
    end

    if anim.Mult then
        t = t * anim.Mult
    end

    return t
end

if CLIENT then
    net.Receive("arccw_networktpanim", function()
        local ent = net.ReadEntity()
        local aseq = net.ReadUInt(16)
        local starttime = net.ReadFloat()
        if ent ~= LocalPlayer() then
            ent:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, starttime, true )
        end
    end)
end

function SWEP:QueueAnimation() end
function SWEP:NextAnimation() end