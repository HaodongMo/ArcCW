local ang0 = Angle(0, 0, 0)
SWEP.ClientFreeAimAng = Angle(ang0)

function SWEP:ShouldFreeAim()
    if self:GetOwner():IsNPC() then return false end
    if (GetConVar("arccw_freeaim"):GetInt() == 0 or self:GetBuff_Override("NeverFreeAim", self.NeverFreeAim))  and !self:GetBuff_Override("AlwaysFreeAim", self.AlwaysFreeAim) then return false end
    return true
end

function SWEP:FreeAimMaxAngle()
    local ang = self.FreeAimAngle and self:GetBuff("FreeAimAngle") or math.Clamp(self:GetBuff("HipDispersion") / 80, 3, 10)
    return ang
end

function SWEP:ThinkFreeAim()
    if self:ShouldFreeAim() then
        local diff = self:GetOwner():EyeAngles() - self:GetLastAimAngle()
        --diff = diff * 2

        local freeaimang = Angle(self:GetFreeAimAngle())

        local max = self:FreeAimMaxAngle()

        local delta = math.min(self:GetSightDelta(),
                self:CanShootWhileSprint() and 1 or (1 - self:GetSprintDelta()),
                self:GetState() == ArcCW.STATE_CUSTOMIZE and 0 or 1)

        max = max * delta

        diff.p = math.NormalizeAngle(diff.p)
        diff.y = math.NormalizeAngle(diff.y)

        diff = diff * Lerp(delta, 1, 0.25)

        freeaimang.p = math.Clamp(math.NormalizeAngle(freeaimang.p) + math.NormalizeAngle(diff.p), -max, max)
        freeaimang.y = math.Clamp(math.NormalizeAngle(freeaimang.y) + math.NormalizeAngle(diff.y), -max, max)

        local ang2d = math.atan2(freeaimang.p, freeaimang.y)
        local mag2d = math.sqrt(math.pow(freeaimang.p, 2) + math.pow(freeaimang.y, 2))

        mag2d = math.min(mag2d, max)

        freeaimang.p = mag2d * math.sin(ang2d)
        freeaimang.y = mag2d * math.cos(ang2d)

        self:SetFreeAimAngle(freeaimang)

        if CLIENT then
            self.ClientFreeAimAng = freeaimang
        end
    end

    self:SetLastAimAngle(self:GetOwner():EyeAngles())
end

function SWEP:GetFreeAimOffset()
    if !self:ShouldFreeAim() then return ang0 end
    if CLIENT then
        return self.ClientFreeAimAng
    else
        return self:GetFreeAimAngle()
    end
end