local function qerp(delta, a, b)
    local qdelta = -(delta ^ 2) + (delta * 2)

    qdelta = math.Clamp(qdelta, 0, 1)

    return Lerp(qdelta, a, b)
end

SWEP.LHIKAnimation_IsIdle = false
SWEP.LHIKAnimation = nil
SWEP.LHIKAnimationStart = 0
SWEP.LHIKAnimationTime = 0

SWEP.LHIKCamAng = Angle(0, 0, 0)
SWEP.LHIKGunAng = Angle(0, 0, 0)

function SWEP:DoLHIKAnimation(key, time)
    local lhik_model
    local LHIK_GunDriver
    local LHIK_CamDriver

    local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

    key = tranim or key

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        if !k.VElement then continue end

        if self:GetBuff_Stat("LHIK", i) then
            lhik_model = k.VElement.Model

            if self:GetBuff_Stat("LHIK_GunDriver", i) then
                LHIK_GunDriver = self:GetBuff_Stat("LHIK_GunDriver", i)
            end

            if self:GetBuff_Stat("LHIK_CamDriver", i) then
                LHIK_CamDriver = self:GetBuff_Stat("LHIK_CamDriver", i)
            end
        end
    end

    if !lhik_model then return false end

    local seq = lhik_model:LookupSequence(key)

    if !seq then return false end
    if seq == -1 then return false end

    lhik_model:ResetSequence(seq)

    if !time then time = lhik_model:SequenceDuration(seq) end

    self.LHIKAnimation = seq
    self.LHIKAnimationStart = UnPredictedCurTime()
    self.LHIKAnimationTime = time

    self.LHIKAnimation_IsIdle = false

    if LHIK_GunDriver then
        local att = lhik_model:LookupAttachment(LHIK_GunDriver)
        local ang = lhik_model:GetAttachment(att).Ang
        local pos = lhik_model:GetAttachment(att).Pos

        self.LHIKGunAng = lhik_model:WorldToLocalAngles(ang)
        self.LHIKGunPos = lhik_model:WorldToLocal(pos)
    end

    if LHIK_CamDriver then
        local att = lhik_model:LookupAttachment(LHIK_CamDriver)
        local ang = lhik_model:GetAttachment(att).Ang

        self.LHIKCamAng = lhik_model:WorldToLocalAngles(ang)
    end

    -- lhik_model:SetCycle(0)
    -- lhik_model:SetPlaybackRate(dur / time)

    return true
end

SWEP.LHIKDelta = {}
SWEP.LHIKDeltaAng = {}
SWEP.ViewModel_Hit = Vector(0, 0, 0)
SWEP.Customize_Hide = 0

function SWEP:GetLHIKAnim()
    local cyc = (UnPredictedCurTime() - self.LHIKAnimationStart) / self.LHIKAnimationTime

    if cyc > 1 then return nil end
    if self.LHIKAnimation_IsIdle then return nil end

    return self.LHIKAnimation
end

function SWEP:DoLHIK()
    local justhide = false
    local lhik_model = nil
    local hide_component = false
    local delta = 1

    local vm = self:GetOwner():GetViewModel()

    if !self.NoHideLeftHandInCustomization and !self:GetBuff_Override("Override_NoHideLeftHandInCustomization") then
        if self:GetState() == ArcCW.STATE_CUSTOMIZE then
            self.Customize_Hide = math.Approach(self.Customize_Hide, 1, FrameTime() / 0.25)
        else
            self.Customize_Hide = math.Approach(self.Customize_Hide, 0, FrameTime() / 0.25)
        end
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        -- local atttbl = ArcCW.AttachmentTable[k.Installed]

        -- if atttbl.LHIKHide then
        if self:GetBuff_Stat("LHIKHide", i) then
            justhide = true
        end

        if !k.VElement then continue end

        -- if atttbl.LHIK then
        if self:GetBuff_Stat("LHIK", i) then
            lhik_model = k.VElement.Model
        end
    end

    if self.LHIKTimeline then
        local tl = self.LHIKTimeline

        local stage, next_stage, next_stage_index

        for i, k in pairs(tl) do
            if !k or !k.t then continue end
            if k.t + self.LHIKStartTime > CurTime() then
                next_stage_index = i
                break
            end
        end

        if next_stage_index then
            if next_stage_index == 1 then
                -- we are on the first stage.
                stage = {t = 0, lhik = 0}
                next_stage = self.LHIKTimeline[next_stage_index]
            else
                stage = self.LHIKTimeline[next_stage_index - 1]
                next_stage = self.LHIKTimeline[next_stage_index]
            end
        else
            stage = self.LHIKTimeline[#self.LHIKTimeline]
            next_stage = {t = self.LHIKEndTime, lhik = self.LHIKTimeline[#self.LHIKTimeline].lhik}
        end

        local local_time = CurTime() - self.LHIKStartTime

        local delta_time = next_stage.t - stage.t
        delta_time = (local_time - stage.t) / delta_time

        delta = qerp(delta_time, stage.lhik, next_stage.lhik)

        if lhik_model and IsValid(lhik_model) then
            local key

            if stage.lhik > next_stage.lhik then
                key = "in"
            elseif next_stage.lhik > stage.lhik then
                key = "out"
            end

            if key then
                local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

                key = tranim or key

                local seq = lhik_model:LookupSequence(key)

                if seq and seq > 0 then
                    lhik_model:SetSequence(seq)
                    lhik_model:SetCycle(delta)
                end
            end
        end

        -- if tl[4] <= UnPredictedCurTime() then
        --     -- it's over
        --     delta = 1
        -- elseif tl[3] <= UnPredictedCurTime() then
        --     -- transition back to 1
        --     delta = (UnPredictedCurTime() - tl[3]) / (tl[4] - tl[3])
        --     delta = qerp(delta, 0, 1)

        --     if lhik_model and IsValid(lhik_model) then
        --         local key = "out"

        --         local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        --         key = tranim or key

        --         local seq = lhik_model:LookupSequence(key)

        --         if seq and seq > 0 then
        --             lhik_model:SetSequence(seq)
        --             lhik_model:SetCycle(delta)
        --         end
        --     end
        -- elseif tl[2] <= UnPredictedCurTime() then
        --     -- hold 0
        --     delta = 0
        -- elseif tl[1] <= UnPredictedCurTime() then
        --     -- transition to 0
        --     delta = (UnPredictedCurTime() - tl[1]) / (tl[2] - tl[1])
        --     delta = qerp(delta, 1, 0)

        --     if lhik_model and IsValid(lhik_model) then
        --         local key = "in"

        --         local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        --         key = tranim or key

        --         local seq = lhik_model:LookupSequence(key)

        --         if seq and seq > 0 then
        --             lhik_model:SetSequence(seq)
        --             lhik_model:SetCycle(delta)
        --         end
        --     end
    else
        -- hasn't started yet
        delta = 1
    end

    if delta == 1 and self.Customize_Hide > 0 then
        if !lhik_model or !IsValid(lhik_model) then
            justhide = true
            delta = math.min(self.Customize_Hide, delta)
        else
            hide_component = true
        end
    end

    if justhide then
        for _, bone in pairs(ArcCW.LHIKBones) do
            local vmbone = vm:LookupBone(bone)

            if !vmbone then continue end -- Happens when spectating someone prolly

            local vmtransform = vm:GetBoneMatrix(vmbone)

            if !vmtransform then continue end -- something very bad has happened

            local vm_pos = vmtransform:GetTranslation()
            local vm_ang = vmtransform:GetAngles()

            local newtransform = Matrix()

            newtransform:SetTranslation(LerpVector(delta, vm_pos, vm_pos - (EyeAngles():Up() * 12) - (EyeAngles():Forward() * 12) - (EyeAngles():Right() * 4)))
            newtransform:SetAngles(vm_ang)

            vm:SetBoneMatrix(vmbone, newtransform)
        end
    end

    if !lhik_model or !IsValid(lhik_model) then return end

    lhik_model:SetupBones()

    if justhide then return end

    local cyc = (UnPredictedCurTime() - self.LHIKAnimationStart) / self.LHIKAnimationTime

    if self.LHIKAnimation and cyc < 1 then
        lhik_model:SetSequence(self.LHIKAnimation)
        lhik_model:SetCycle(cyc)
    else
        local key = "idle"

        local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        key = tranim or key

        self:DoLHIKAnimation(key, 1)

        self.LHIKAnimation_IsIdle = true
    end

    local cf_deltapos = Vector(0, 0, 0)
    local cf = 0

    for _, bone in pairs(ArcCW.LHIKBones) do
        local vmbone = vm:LookupBone(bone)
        local lhikbone = lhik_model:LookupBone(bone)

        if !vmbone then continue end
        if !lhikbone then continue end

        local vmtransform = vm:GetBoneMatrix(vmbone)
        local lhiktransform = lhik_model:GetBoneMatrix(lhikbone)

        if !vmtransform then continue end
        if !lhiktransform then continue end

        local vm_pos = vmtransform:GetTranslation()
        local vm_ang = vmtransform:GetAngles()
        local lhik_pos = lhiktransform:GetTranslation()
        local lhik_ang = lhiktransform:GetAngles()

        local newtransform = Matrix()

        newtransform:SetTranslation(LerpVector(delta, vm_pos, lhik_pos))
        newtransform:SetAngles(LerpAngle(delta, vm_ang, lhik_ang))

        if !self:GetBuff_Override("LHIK_GunDriver") and self.LHIKDelta[lhikbone] and self.LHIKAnimation and cyc < 1 then
            local deltapos = lhik_model:WorldToLocal(lhik_pos) - self.LHIKDelta[lhikbone]

            if !deltapos:IsZero() then
                cf_deltapos = cf_deltapos + deltapos
                cf = cf + 1
            end
        end

        self.LHIKDelta[lhikbone] = lhik_model:WorldToLocal(lhik_pos)

        if hide_component then
            local new_pos = newtransform:GetTranslation()
            newtransform:SetTranslation(LerpVector(self.Customize_Hide, new_pos, new_pos - (EyeAngles():Up() * 12) - (EyeAngles():Forward() * 12) - (EyeAngles():Right() * 4)))
        end

        local matrix = Matrix(newtransform)

        vm:SetBoneMatrix(vmbone, matrix)

        -- local vm_pos, vm_ang = vm:GetBonePosition(vmbone)
        -- local lhik_pos, lhik_ang = lhik_model:GetBonePosition(lhikbone)

        -- local pos = LerpVector(delta, vm_pos, lhik_pos)
        -- local ang = LerpAngle(delta, vm_ang, lhik_ang)

        -- vm:SetBonePosition(vmbone, pos, ang)
    end

    if !cf_deltapos:IsZero() and cf > 0 and self:GetBuff_Override("LHIK_Animation") then
        local new = Vector(0, 0, 0)
        local viewmult = self:GetBuff_Override("LHIK_MovementMult") or 1

        new[1] = cf_deltapos[2] * viewmult
        new[2] = cf_deltapos[1] * viewmult
        new[3] = cf_deltapos[3] * viewmult

        self.ViewModel_Hit = LerpVector(0.25, self.ViewModel_Hit, new / cf):GetNormalized()
    end
end