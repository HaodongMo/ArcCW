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
    local amount = a or 1
    self.Heat = heat + amount * GetConVar("arccw_mult_heat"):GetFloat()

    self.NextHeatDissipateTime = CurTime() + (self:GetBuff("HeatDelayTime"))
    local overheat = self.Heat >= max
    if overheat then
        local h = self:GetBuff_Hook("Hook_Overheat", self.Heat)
        if h == true then overheat = false end
    end
    if overheat then
        self.Heat = math.min(self.Heat, max)
        if self.HeatFix or self:GetBuff_Override("Override_HeatFix") then
            self.NextHeatDissipateTime = CurTime() + self:GetAnimKeyTime(anim) * mult
        elseif self.HeatLockout or self:GetBuff_Override("Override_HeatLockout") then
            self.NextHeatDissipateTime = CurTime() + (self:GetAnimKeyTime(anim) or 1) * mult
        end
    end

    if single and CLIENT then return end

    self:SetHeat(self.Heat)

    if overheat then
        if anim then
            self:PlayAnimation(anim, mult, true, 0, true)

            if self.HeatFix or self:GetBuff_Override("Override_HeatFix") then
                self:SetTimer(self:GetAnimKeyTime(anim) * mult,
                function()
                    self:SetHeat(0)
                end)
            end
        end

        if self.HeatLockout or self:GetBuff_Override("Override_HeatLockout") then
            self:SetHeatLocked(true)
        end
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