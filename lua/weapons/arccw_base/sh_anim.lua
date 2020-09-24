if SERVER then

function SWEP:DoLHIKAnimation(key, time)
    if game.SinglePlayer() then
        net.Start("arccw_sp_lhikanim")
        net.WriteString(key)
        net.WriteFloat(time)
        net.Send(self:GetOwner())
    end
end

end

function SWEP:SelectAnimation(anim)
    if self:Clip1() == 0 and self.Animations[anim .. "_empty"] then
        anim = anim .. "_empty"
    end

    if !self.Animations[anim] then return end

    return anim
end

SWEP.LastAnimStartTime = 0

function SWEP:PlayAnimation(key, mult, pred, startfrom, tt, skipholster, ignorereload, absolute)
    mult = mult or 1
    pred = pred or false
    startfrom = startfrom or 0
    tt = tt or false
    skipholster = skipholster or false
    ignorereload = ignorereload or false
    absolute = absolute or false

    if !self.Animations[key] then return end

    if self:GetNWBool("reloading", false) and !ignorereload then return end

    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local anim = self.Animations[key]

    local tranim = self:GetBuff_Hook("Hook_TranslateAnimation", key)

    if !tranim then return end

    if self.Animations[tranim] then
        anim = self.Animations[tranim]
    end

    if anim.Mult then
        mult = mult * anim.Mult
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

            if isnumber(v.t) then
                if st < 0 then continue end
                if self:GetOwner():IsPlayer() then
                    self:SetTimer(st, function() if !game.SinglePlayer() and !IsFirstTimePredicted() then return end self:OurViewPunch(v.p or Vector(0, 0, 0)) end, id)
                end
            end
        end
    end

    if isnumber(anim.ShellEjectAt) then
        self:SetTimer(anim.ShellEjectAt * mult, function()
            self:DoShellEject()
        end)
    end

    local vm = self:GetOwner():GetViewModel()

    if !vm then return end
    if !IsValid(vm) then return end

    self:KillTimer("idlereset")

    self:GetAnimKeyTime(key)

    local time = anim.Time

    if absolute then
        time = 1
    end

    local ttime = (time * mult) - startfrom

    if startfrom > (time * mult) then return end

    if tt then
        self:SetNextArcCWPrimaryFire(CurTime() + ((anim.MinProgress or time) * mult) - startfrom)
    end

    if anim.LHIK then
        self.LHIKTimeline = {
            CurTime() - startfrom,
            CurTime() - startfrom + ((anim.LHIKIn or 0.1) * mult),
            CurTime() - startfrom + ttime - ((anim.LHIKOut or 0.1) * mult),
            CurTime() - startfrom + ttime
        }

        if anim.LHIKIn == 0 then
            self.LHIKTimeline[1] = -math.huge
            self.LHIKTimeline[2] = -math.huge
        end

        if anim.LHIKOut == 0 then
            self.LHIKTimeline[3] = math.huge
            self.LHIKTimeline[4] = math.huge
        end
    else
        self.LHIKTimeline = nil
    end

    if anim.LastClip1OutTime then
        self.LastClipOutTime = CurTime() + ((anim.LastClip1OutTime * mult) - startfrom)
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
        -- Hack to fix an issue with playing one anim multiple times in a row
        -- Provided by Jackarunda
        local resetSeq = anim.HardResetAnim and vm:LookupSequence(anim.HardResetAnim)
        if resetSeq then
            vm:SendViewModelMatchingSequence(resetSeq)
            vm:SetPlaybackRate(.1)
            timer.Simple(0,function()
                vm:SendViewModelMatchingSequence(seq)
                local dur = vm:SequenceDuration()
                vm:SetPlaybackRate(dur / (ttime + startfrom))
            end)
        else
            vm:SendViewModelMatchingSequence(seq)
            local dur = vm:SequenceDuration()
            vm:SetPlaybackRate(dur / (ttime + startfrom))
        end
    end

    -- :(
    -- unfortunately, gmod seems to have broken the features required for this to work.
    -- as such, I'm reverting to a more traditional reload system.

    -- local framestorealtime = 1

    -- if anim.FrameRate then
    --     framestorealtime = 1 / anim.FrameRate
    -- end

    -- local dur = vm:SequenceDuration()
    -- vm:SetPlaybackRate(dur / (ttime + startfrom))

    -- if anim.Checkpoints then
    --     self.CheckpointAnimation = key
    --     self.CheckpointTime = startfrom

    --     for i, k in pairs(anim.Checkpoints) do
    --         if !k then continue end
    --         if istable(k) then continue end
    --         local realtime = k * framestorealtime

    --         if realtime > startfrom then
    --             self:SetTimer((realtime * mult) - startfrom, function()
    --                 self.CheckpointAnimation = key
    --                 self.CheckpointTime = realtime
    --             end)
    --         end
    --     end
    -- end

    if CLIENT then
        vm:SetAnimTime(CurTime() - startfrom)
    end

    if anim.TPAnim then
        if anim.TPAnimStartTime then
            local aseq = self:GetOwner():SelectWeightedSequence(anim.TPAnim)
            if aseq then
                self:GetOwner():AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, anim.TPAnimStartTime, true )
            end
        else
            local aseq = self:GetOwner():SelectWeightedSequence(anim.TPAnim)
            self:GetOwner():AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, aseq, 0, true )
        end
    end

    self:PlaySoundTable(anim.SoundTable or {}, 1 / mult, startfrom)

    self:SetTimer(ttime, function()
        self:NextAnimation()

        self:ResetCheckpoints()
    end, key)

    if key != "idle" then
        self:SetTimer(ttime, function()
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
            if self:GetBuff_Override("UBGL_BaseAnims") and self:GetNWBool("ubgl") 
                    and self.Animations.idle_ubgl_empty and self:Clip2() <= 0 then
                ianim = "idle_ubgl_empty"
            elseif self:GetBuff_Override("UBGL_BaseAnims") and self:GetNWBool("ubgl") and self.Animations.idle_ubgl then
                ianim = "idle_ubgl"
            elseif (self:Clip1() == 0 or self:GetNWBool("cycle")) and self.Animations.idle_empty then
                ianim = ianim or "idle_empty"
            else
                ianim = ianim or "idle"
            end
            self:PlayAnimation(ianim, 1, pred, nil, nil, nil, true)
        end, "idlereset")
    end
end

function SWEP:GetAnimKeyTime(key)
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

    return anim.Time
end

function SWEP:QueueAnimation(key, mult, pred, sf)
    pred = pred or false
    sf = sf or false
    table.insert(self.AnimQueue, {k = key, m = mult, p = pred, sf = sf})

    if table.Count(self.AnimQueue) == 0 then
        self:NextAnimation()
    end
end

function SWEP:NextAnimation()
    if table.Count(self.AnimQueue) == 0 then return end

    local anim = table.remove(self.AnimQueue, 1)

    self:PlayAnimation(anim.k, anim.m, anim.p, 0, anim.sf)
end