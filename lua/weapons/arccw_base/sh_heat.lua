SWEP.NextHeatDissipateTime = 0
SWEP.Heat = 0

function SWEP:GetMaxHeat()
    return self:GetBuff("HeatCapacity")
end

function SWEP:AddHeat(a)
    local single = game.SinglePlayer()
    a = tonumber(a)

    if !(self.Jamming or self:GetBuff_Override("Override_Jamming")) then return end

    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("AddHeat", a) end
    -- if !single and !IsFirstTimePredicted() then return end

    local max = self:GetBuff("HeatCapacity")
    local mult = 1 * self:GetBuff_Mult("Mult_FixTime")
    local heat = self:GetHeat()
    local anim = self:SelectAnimation("fix")
    anim = self:GetBuff_Hook("Hook_SelectFixAnim", anim) or anim
    local amount = a or 1
    local t = CurTime() + self:GetAnimKeyTime(anim) * mult
    self.Heat = math.max(0, heat + amount * GetConVar("arccw_mult_heat"):GetFloat())

    self.NextHeatDissipateTime = CurTime() + (self:GetBuff("HeatDelayTime"))
    local overheat = self.Heat >= max
    if overheat then
        local h = self:GetBuff_Hook("Hook_Overheat", self.Heat)
        if h == true then overheat = false end
    end
    if overheat then
        self.Heat = math.min(self.Heat, max)
        if self:GetBuff_Override("Override_HeatFix", self.HeatFix) then
            self.NextHeatDissipateTime = t
        elseif self:GetBuff_Override("Override_HeatLockout", self.HeatLockout) then
            self.NextHeatDissipateTime = t
        end
    elseif !self:GetBuff_Override("Override_HeatOverflow", self.HeatOverflow) then
        self.Heat = math.min(self.Heat, max)
    end

    if single and CLIENT then return end

    self:SetHeat(self.Heat)

    if overheat then

        local ret = self:GetBuff_Hook("Hook_OnOverheat")
        if ret then return end

        if anim then
            self:PlayAnimation(anim, mult, true, 0, true)
            self:SetPriorityAnim(t)
            self:SetNextPrimaryFire(t)

            if self:GetBuff_Override("Override_HeatFix", self.HeatFix) then
                self:SetTimer(t - CurTime(),
                function()
                    self:SetHeat(0)
                end)
            end
        end

        if self.HeatLockout or self:GetBuff_Override("Override_HeatLockout") then
            self:SetHeatLocked(true)
        end

        self:GetBuff_Hook("Hook_PostOverheat")
    end
end

function SWEP:DoHeat()
    if self.NextHeatDissipateTime > CurTime() then return end

    --local diss = self.HeatDissipation or 2
    --diss = diss * self:GetBuff_Mult("Mult_HeatDissipation")
    local diss = self:GetBuff("HeatDissipation") or 2
    local ft = FrameTime()
    self.Heat = self:GetHeat() - (ft * diss)

    self.Heat = math.max(self.Heat, 0)

    self:SetHeat(self.Heat)

    if self.Heat <= 0 and self:GetHeatLocked() then
        self:SetHeatLocked(false)
    end
end

function SWEP:HeatEnabled()
    return self.Jamming or self:GetBuff_Override("Override_Jamming")
end

function SWEP:MalfunctionEnabled()
    local cvar = GetConVar("arccw_malfunction"):GetInt()
    return cvar == 2 or (cvar == 1 and self:GetBuff_Override("Override_Malfunction", self.Malfunction))
end

function SWEP:GetMalfunctionAnimation()
    local anim = self:SelectAnimation("unjam")
    if !self.Animations[anim] then
        anim = self:SelectAnimation("fix")
        anim = self:GetBuff_Hook("Hook_SelectFixAnim", anim) or anim
    end
    if !self.Animations[anim] then anim = self:SelectAnimation("cycle") end
    if !self.Animations[anim] then anim = nil end
    return anim
end

function SWEP:DoMalfunction(post)

    if !IsFirstTimePredicted() then return end
    if !self:MalfunctionEnabled() then return false end
    local shouldpost = self:GetBuff_Override("Override_MalfunctionPostFire", self.MalfunctionPostFire)
    if post != shouldpost then return false end

    -- Auto calculated malfunction mean
    if self.MalfunctionMean == nil then
        local mm
        if self.Jamming then mm = self.HeatCapacity * 4
        else mm = self.Primary.ClipSize * 8 end

        if self.ManualAction then
            -- Manual guns are less likely to jam
            mm = mm * 2
        else
            -- Burst and semi only guns are less likely to jam
            local a, b = false, false
            for k, v in pairs(self.Firemodes) do
                if !v.Mode then continue end
                if v.Mode == 2 then a = true
                elseif v.Mode < 0 then b = true end
            end
            if !a and b then
                mm = mm * 1.25
            elseif !a and !b then
                mm = mm * 1.5
            end
        end
        self.MalfunctionMean = mm
    end

    local cvar = math.max(GetConVar("arccw_mult_malfunction"):GetFloat(), 0.00000001)
    local mean = self:GetBuff("MalfunctionMean") / cvar
    local var = mean * math.Clamp(self:GetBuff("MalfunctionVariance") * math.max(1, math.sqrt(cvar)), 0, 1)
    local count = (self.ShotsSinceMalfunction or 0)

    if !self.NextMalfunction then
        math.randomseed(math.Round(util.SharedRandom(count, -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)))
        self.NextMalfunction = math.ceil(math.sqrt(-2 * var * math.log(math.random())) * math.cos(2 * math.pi * math.random()))
    end

    local ret = self:GetBuff_Hook("Hook_Malfunction", count, true)
    if ret != nil then return ret end

    if self:Clip1() <= 1 then return false end

    --print(mean, var, count, self.NextMalfunction)
    if count >= self.NextMalfunction + mean then
        local ret2 = self:GetBuff_Hook("Hook_OnMalfunction", count, true)
        if ret2 then return false end

        self:MyEmitSound(self:GetBuff_Override("Override_MalfunctionSound") or self.MalfunctionSound, 75, 100, 1, CHAN_ITEM)

        local wait = self:GetBuff("MalfunctionWait")
        self:SetNextPrimaryFire(CurTime() + wait)

        local anim = self:GetMalfunctionAnimation()
        if !anim or self:GetBuff_Override("Override_MalfunctionJam", self.MalfunctionJam) then
            self:SetMalfunctionJam(true)
        else
            self:SetTimer(wait,
            function()
                self:MalfunctionClear()
            end)
        end

        self:GetBuff_Hook("Hook_PostMalfunction")
        self.ShotsSinceMalfunction = 0
        self.NextMalfunction = nil

        self:SetBurstCount(0)

        return true
    else
        self.ShotsSinceMalfunction = (self.ShotsSinceMalfunction or 0) + 1
        return false
    end
end

function SWEP:MalfunctionClear()

    if self:GetBuff_Override("Override_MalfunctionTakeRound", self.MalfunctionTakeRound) then
        self:TakePrimaryAmmo(self:GetBuff("AmmoPerShot"))
    end

    local anim = self:GetMalfunctionAnimation()
    if anim then
        self:PlayAnimation(anim, self:GetBuff_Mult("Mult_MalfunctionFixTime"), true, 0, true)
        local wait = self:GetAnimKeyTime(anim) - 0.01
        self:SetTimer(wait,
        function()
            self:SetMalfunctionJam(false)
            self:PlayIdleAnimation(true)
        end)
        return true
    else
        self:SetMalfunctionJam(false)
        return false
    end
end