SWEP.NextHeatDissipateTime = 0
SWEP.Heat = 0

function SWEP:AddHeat()
    local single = game.SinglePlayer()

    if !single and !IsFirstTimePredicted() then return end

    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("AddHeat") end

    if !(self.Jamming or self:GetBuff_Override("Override_Jamming")) then return end
    local max = self.HeatCapacity * self:GetBuff_Mult("Mult_HeatCapacity")
    local mult = 1 * self:GetBuff_Mult("Mult_FixTime")
    self.Heat = math.Clamp(self.Heat + 1, 0, max)
    self.NextHeatDissipateTime = CurTime() + 0.5

    if self.Heat >= max then
        local anim = self:SelectAnimation("fix")

        if anim then
            self:PlayAnimation(anim, mult, true, 0, true)
        end
    end
end

function SWEP:DoHeat()
    if self.NextHeatDissipateTime > CurTime() then return end

    local diss = self.HeatDissipation or 2
    diss = diss * self:GetBuff_Mult("Mult_HeatDissipation")
    self.Heat = self.Heat - (FrameTime() * diss)
end

function SWEP:HeatEnabled()
    return (self.Jamming or self:GetBuff_Override("Override_Jamming")) and self.Animations["fix"]
end