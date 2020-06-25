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

SWEP.LastAnimStartTime = 0

function SWEP:PlayAnimation(key, mult, pred, startfrom, tt, skipholster)
    mult = mult or 1
    pred = pred or false
    startfrom = startfrom or 0
    tt = tt or false
    skipholster = skipholster or false

    if !self.Animations[key] then return end

    if self:GetNWBool("reloading", false) then return end

    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    print(key)

    local anim = self.Animations[key]

    local tranim = self:GetBuff_Hook("Hook_TranslateAnimation", key)

    if tranim == false then return end

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
        net.Send(self:GetOwner())
    end

    if anim.ProcHolster and !skipholster then
        self:ProceduralHolster()
        self:SetTimer(0.25, function()
            self:PlayAnimation(anim, mult, true, startfrom, tt, true)
        end)
        if tt then
            self:SetNextPrimaryFire(CurTime() + 0.25)
        end
        return
    end

    if anim.ViewPunchTable then
        for k, v in pairs(anim.ViewPunchTable) do

            if !v.t then continue end

            local st = (v.t * mult) - startfrom

            if isnumber(v.t) then
                if st < 0 then continue end
                if self:GetOwner():IsPlayer() then
                    self:SetTimer(st, function() if !game.SinglePlayer() and !IsFirstTimePredicted() then return end self:GetOwner():ViewPunch(v.p or Vector(0, 0, 0)) end, id)
                end
            end
        end
    end

    if isnumber(anim.ShellEjectAt) then
        self:SetTimer(anim.ShellEjectAt, function()
            self:DoShellEject()
        end)
    end

    local vm = self:GetOwner():GetViewModel()

    if !vm then return end
    if !IsValid(vm) then return end

    self:KillTimer("idlereset")

    self:GetAnimKeyTime(key)

    local ttime = (anim.Time * mult) - startfrom

    if startfrom > (anim.Time * mult) then return end

    if tt then
        self:SetNextPrimaryFire(CurTime() + ttime)
    end

    if anim.LHIK then
        self.LHIKTimeline = {
            CurTime() - startfrom,
            CurTime() - startfrom + ((anim.LHIKIn or 0.1) * mult),
            CurTime() - startfrom + ttime - ((anim.LHIKOut or 0.1) * mult),
            CurTime() - startfrom + ttime
        }

        if anim.LHIKIn == 0 then
            self.LHIKTimeline[1] = 0
            self.LHIKTimeline[2] = 0
        end

        if anim.LHIKOut == 0 then
            self.LHIKTimeline[3] = math.huge
            self.LHIKTimeline[4] = math.huge
        end
    end

    if anim.LastClip1OutTime then
        self.LastClipOutTime = CurTime() + ((anim.LastClip1OutTime * mult) - startfrom)
    end

    local seq = anim.Source

    if anim.RareSource and math.random(1, 100) <= 1 then
        seq = anim.RareSource
    end

    if istable(seq) then
        seq["BaseClass"] = nil

        seq = table.Random(seq)
    end

    if isstring(seq) then
        seq = vm:LookupSequence(seq)
    end

    -- if !game.SinglePlayer() and CLIENT then
        vm:SendViewModelMatchingSequence(seq)
    -- end

    local framestorealtime = 1

    if anim.FrameRate then
        framestorealtime = 1 / anim.FrameRate
    end

    local dur = vm:SequenceDuration()

    vm:SetPlaybackRate(dur / (ttime + startfrom))

    if anim.Checkpoints then
        self.CheckpointAnimation = key
        self.CheckpointTime = startfrom

        for i, k in pairs(anim.Checkpoints) do
            if !k then continue end
            if istable(k) then continue end
            local realtime = k * framestorealtime

            if realtime > startfrom then
                self:SetTimer((realtime * mult) - startfrom, function()
                    self.CheckpointAnimation = key
                    self.CheckpointTime = realtime
                end)
            end
        end
    end

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
            self:GetOwner():DoAnimationEvent(anim.TPAnim)
        end
    end

    self:PlaySoundTable(anim.SoundTable or {}, 1 / mult, startfrom)

    self:SetTimer(ttime, function()
        self:NextAnimation()

        if anim.Checkpoints then
            self.CheckpointAnimation = nil
            self.CheckpointTime = 0
        end
    end, key)
    if key != "idle" then
        self:SetTimer(ttime, function()
            if self:GetState() == ArcCW.STATE_SPRINT and self.Animations.idle_sprint then
                if self:Clip1() == 0 and self.Animations.idle_sprint_empty then
                    self:PlayAnimation("idle_sprint_empty", 1, pred)
                else
                    self:PlayAnimation("idle_sprint", 1, pred)
                end

                return
            end

            if self:InBipod() and self.Animations.idle_bipod then
                if self:Clip1() == 0 and self.Animations.idle_bipod_empty then
                    self:PlayAnimation("idle_bipod_empty", 1, pred)
                else
                    self:PlayAnimation("idle_bipod", 1, pred)
                end

                return
            end

            if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations.idle_sights then
                if self:Clip1() == 0 and self.Animations.idle_sights_empty then
                    self:PlayAnimation("idle_sights_empty", 1, pred)
                else
                    self:PlayAnimation("idle_sights", 1, pred)
                end

                return
            end

            if self:Clip1() == 0 and self.Animations.idle_empty then
                self:PlayAnimation("idle_empty", 1, pred)
            else
                self:PlayAnimation("idle", 1, pred)
            end
        end, "idlereset")
    end
end

function SWEP:GetAnimKeyTime(key)
    local vm = self:GetOwner():GetViewModel()
    local anim = self.Animations[key]

    if !anim then anim.Time = 1 return 1 end

    if !anim.Time then
        local tseq = anim.Source

        if istable(tseq) then
            tseq["BaseClass"] = nil -- god I hate Lua inheritance
            tseq = tseq[1]
        end

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