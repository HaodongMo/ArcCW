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

function SWEP:PlayAnimation(key, mult, pred, startfrom, tt, skipholster, ignorereload, absolute)
    mult = mult or 1
    pred = pred or false
    startfrom = startfrom or 0
    tt = tt or false
    skipholster = skipholster or false
    ignorereload = ignorereload or false
    absolute = absolute or false

    local ct = CurTime() --pred and CurTime() or UnPredictedCurTime()

    if !self.Animations[key] then return end

    if self:GetReloading() and !ignorereload then return end

    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local anim = self.Animations[key]

    local tranim = self:GetBuff_Hook("Hook_TranslateAnimation", key)

    if !tranim then return end

    if self.Animations[tranim] then
        anim = self.Animations[tranim]
    end

    if game.SinglePlayer() and SERVER and pred then
        net.Start("arccw_sp_anim")
        net.WriteString(key)
        net.WriteFloat(mult)
        net.WriteFloat(startfrom)
        net.WriteBool(tt)
        net.WriteBool(skipholster)
        net.WriteBool(ignorereload)
        net.Send(self:GetOwner())
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

    self:KillTimer("idlereset")

    self:GetAnimKeyTime(key)

    local time = anim.Time

    -- stoled from getanimkeytime
    if !anim.Time then
        local tseq = anim.Source
        if istable(tseq) then
            tseq["BaseClass"] = nil -- god I hate Lua inheritance
            tseq = tseq[1]
        end
        if !tseq then return end
        tseq = vm:LookupSequence(tseq)
        time = vm:SequenceDuration(tseq) or 1
    end

    if anim.Time == 0 then return end

    if absolute then
        time = 1
    end

    local ttime = (time * mult) - startfrom

    if startfrom > (time * mult) then return end

    if tt then
        self:SetNextPrimaryFire(ct + ((anim.MinProgress or time) * mult) - startfrom)
    end

    --if CLIENT then
    --    vm:SetAnimTime(ct - startfrom)
    --end

    if anim.LHIK then
        -- self.LHIKTimeline = {
        --     CurTime() - startfrom,
        --     CurTime() - startfrom + ((anim.LHIKIn or 0.1) * mult),
        --     CurTime() - startfrom + ttime - ((anim.LHIKOut or 0.1) * mult),
        --     CurTime() - startfrom + ttime
        -- }

        -- if anim.LHIKIn == 0 then
        --     self.LHIKTimeline[1] = -math.huge
        --     self.LHIKTimeline[2] = -math.huge
        -- end

        -- if anim.LHIKOut == 0 then
        --     self.LHIKTimeline[3] = math.huge
        --     self.LHIKTimeline[4] = math.huge
        -- end
        self.LHIKStartTime = ct
        self.LHIKEndTime = ct + ttime

        if anim.LHIKTimeline then
            self.LHIKTimeline = {}

            for i, k in pairs(anim.LHIKTimeline) do
                table.Add(self.LHIKTimeline, {t = (k.t or 0) * mult, lhik = k.lhik or 1})
            end
        else
            self.LHIKTimeline = {
                {t = 0, lhik = 1},
                {t = ((anim.LHIKIn or 0.1) - (anim.LHIKEaseIn or anim.LHIKIn or 0.1)) * mult, lhik = 1},
                {t = (anim.LHIKIn or 0.1) * mult, lhik = 0},
                {t = ttime - ((anim.LHIKOut or 0.1) * mult), lhik = 0},
                {t = ttime - (((anim.LHIKOut or 0.1) - (anim.LHIKEaseOut or anim.LHIKOut or 0.1)) * mult), lhik = 1},
                {t = ttime, lhik = 1}
            }

            if anim.LHIKIn == 0 then
                self.LHIKTimeline[1].lhik = 0
                self.LHIKTimeline[2].lhik = 0
            end

            if anim.LHIKOut == 0 then
                self.LHIKTimeline[#self.LHIKTimeline - 1].lhik = 0
                self.LHIKTimeline[#self.LHIKTimeline].lhik = 0
            end
        end
    else
        self.LHIKTimeline = nil
    end

    if anim.LastClip1OutTime then
        self.LastClipOutTime = ct + ((anim.LastClip1OutTime * mult) - startfrom)
    end

    local seq = anim.Source

    if anim.RareSource and math.random(1, anim.RareSourceChance or 100) <= 1 then
        seq = anim.RareSource
    end

    seq = self:GetBuff_Hook("Hook_TranslateSequence", seq)

    if !seq then return end

    if istable(seq) then
        seq["BaseClass"] = nil

        seq = table.Random(seq)
    end

    if isstring(seq) then
        seq = vm:LookupSequence(seq)
    end


    if seq then --!game.SinglePlayer() and CLIENT

        --local lastseq = self:GetLastSequence()
        --self:SetLastSequence(seq)
        --local lastkey = self:GetLastAnim()
        --self:SetLastAnim(key)

        -- Hack to fix an issue with playing one anim multiple times in a row
        -- Provided by Jackarunda
        local resetSeq = anim.HardResetAnim and vm:LookupSequence(anim.HardResetAnim)
        if resetSeq then
            vm:SendViewModelMatchingSequence(resetSeq)
            vm:SetPlaybackRate(0.1)
            timer.Simple(0, function()
                vm:SendViewModelMatchingSequence(seq)
                local dur = vm:SequenceDuration()
                vm:SetPlaybackRate(math.Clamp(dur / (ttime + startfrom), -4, 12))
            end)
        else
            vm:SendViewModelMatchingSequence(seq)
            local dur = vm:SequenceDuration()
            vm:SetPlaybackRate(math.Clamp(dur / (ttime + startfrom), -4, 12))
            self.LastAnimStartTime = ct
            self.LastAnimFinishTime = ct + (dur * mult)
        end
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

    local att = self:GetBuff_Override("Override_CamAttachment") or self.CamAttachment

    if att and vm:GetAttachment(att) then
        local ang = vm:GetAttachment(att).Ang
        ang = vm:WorldToLocalAngles(ang)
        self.Cam_Offset_Ang = Angle(ang)
    end

    self:PlaySoundTable(anim.SoundTable or {}, 1 / mult, startfrom)

    self:SetNextIdle(CurTime() + ttime)
end

function SWEP:PlayIdleAnimation(pred)
    local ianim
    local s = self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint
    if self:GetState() == ArcCW.STATE_SPRINT and !s then
        ianim = self:SelectAnimation(ianim .. "_sprint") or ianim
    end

    if self:InBipod() then
        ianim = self:SelectAnimation(ianim .. "_bipod") or ianim
    end

    if (self.Sighted or self:GetState() == ArcCW.STATE_SIGHTS) then
        ianim = self:SelectAnimation(ianim .. "_sight") or self:SelectAnimation(ianim .. "_sights") or ianim
    end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then
        ianim = self:SelectAnimation(ianim .. "_inspect") or ianim
    end

    if self:GetBuff_Override("UBGL_BaseAnims") and self:GetInUBGL()
            and self.Animations.idle_ubgl_empty and self:Clip2() <= 0 then
        ianim = self:SelectAnimation(ianim .. "_ubgl_empty") or ianim
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self:GetInUBGL() and self.Animations.idle_ubgl then
        ianim = self:SelectAnimation(ianim .. "_ubgl") or ianim
    end

    if (self:Clip1() == 0 or self:GetNeedCycle()) and self.Animations.idle_empty then
        ianim = ianim or "idle_empty"
    else
        ianim = ianim or "idle"
    end

    -- (key, mult, pred, startfrom, tt, skipholster, ignorereload)
    self:PlayAnimation(ianim, 1, pred, nil, nil, nil, true)
end

function SWEP:GetAnimKeyTime(key, min)
    if !self:GetOwner() then return 1 end

    local anim = self.Animations[key]

    if !anim then return 1 end

    if self:GetOwner():IsNPC() then return anim.Time or 1 end

    local vm = self:GetOwner():GetViewModel()

    if !vm or !IsValid(vm) then return 1 end

    if !anim.Time then
        local tseq = anim.Source

        if istable(tseq) then
            tseq["BaseClass"] = nil -- god I hate Lua inheritance
            tseq = tseq[1]
        end

        if !tseq then return 1 end

        tseq = vm:LookupSequence(tseq)

        anim.Time = vm:SequenceDuration(tseq) or 1
    end

    local t = anim.Time

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