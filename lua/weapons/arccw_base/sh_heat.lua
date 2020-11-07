SWEP.NextHeatDissipateTime = 0
SWEP.Heat = 0

function SWEP:GetMaxHeat()
    return self:GetBuff("HeatCapacity")
end

function SWEP:AddHeat()
    local single = game.SinglePlayer()

    if !(self.Jamming or self:GetBuff_Override("Override_Jamming")) then return end

    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("AddHeat") end
    -- if !single and !IsFirstTimePredicted() then return end

    local max = self:GetBuff("HeatCapacity")
    local mult = 1 * self:GetBuff_Mult("Mult_FixTime")
    local heat = self:GetHeat()
    local anim = self:SelectAnimation("fix")
    self.Heat = math.Clamp(heat + 1 * GetConVar("arccw_mult_heat"):GetFloat(), 0, max)

    self.NextHeatDissipateTime = CurTime() + (self:GetBuff("HeatDelayTime"))
    if self.Heat >= max then
        if self.HeatFix or self:GetBuff_Override("Override_HeatFix") then
            self.NextHeatDissipateTime = CurTime() + self:GetAnimKeyTime(anim) * mult
        elseif self.HeatLockout or self:GetBuff_Override("Override_HeatLockout") then
            self.NextHeatDissipateTime = CurTime() + (self:GetAnimKeyTime(anim) or 1) * mult
        end
    end

    if single and CLIENT then return end

    self:SetHeat(self.Heat)

    if self.Heat >= max then
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

    local diss = self.HeatDissipation or 2
    diss = diss * self:GetBuff_Mult("Mult_HeatDissipation")
    local ft = FrameTime()
    if CLIENT then
        ft = math.min(ft, RealFrameTime())
    end
    self.Heat = self:GetHeat() - (ft * diss)

    self.Heat = math.Clamp(self.Heat, 0, self:GetMaxHeat())

    self:SetHeat(self.Heat)

    if self.Heat <= 0 and self:GetHeatLocked() then
        self:SetHeatLocked(false)
    end
end

function SWEP:HeatEnabled()
    return self.Jamming or self:GetBuff_Override("Override_Jamming")
end