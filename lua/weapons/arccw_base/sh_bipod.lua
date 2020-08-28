function SWEP:InBipod()
    local bip = self:GetNWBool("bipod", false)

    -- if !self:CanBipod() then
    --     self:ExitBipod()
    -- end

    if self.BipodPos != self:GetOwner():EyePos() then
        self:ExitBipod()
    end

    return bip
end

SWEP.BipodAngle = Angle(0, 0, 0)
SWEP.CachedCanBipod = true
SWEP.CachedCanBipodTime = 0

function SWEP:CanBipod()
    if !(self:GetBuff_Override("Bipod") or self.Bipod_Integral) then return false end

    if self.CachedCanBipodTime >= CurTime() then return self.CachedCanBipod end

    -- local bip = self:GetNWBool("bipod", false)

    local maxs = Vector(2, 2, 2)
    local mins = Vector(-2, -2, -2)

    local pos = self:GetOwner():EyePos()
    local angle = self:GetOwner():EyeAngles()

    if self:GetOwner():GetVelocity():Length() > 0 then
        return false
    end

    local rangemult = 2

    if self:IsProne() then
        rangemult = 2.5
    end

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + (angle:Forward() * 48 * rangemult),
        filter = self:GetOwner(),
        mask = MASK_PLAYERSOLID
    })

    if tr.Hit then -- check for stuff in front of us
        return false
    end

    maxs = Vector(8, 8, 0)
    mins = Vector(-8, -8, -16)

    angle.p = angle.p + 15

    tr = util.TraceHull({
        start = pos,
        endpos = pos + (angle:Forward() * 24 * rangemult),
        filter = self:GetOwner(),
        maxs = maxs,
        mins = mins,
        mask = MASK_PLAYERSOLID
    })

    self.CachedCanBipodTime = CurTime()

    if tr.Hit then
        self.CachedCanBipod = true
        return true
    else
        self.CachedCanBipod = false
        return false
    end
end

function SWEP:EnterBipod()
    if self:GetNWBool("bipod", false) then return end
    if !self:CanBipod() then return end
    --if CurTime() < self:GetNextSecondaryFire() then return end

    if self.Animations.enter_bipod then
        self:PlayAnimation("enter_bipod")
    end

    self:MyEmitSound(self.EnterBipodSound)
    self:DoLHIKAnimation("enter", 0.5)

    self.BipodPos = self:GetOwner():EyePos()
    self.BipodAngle = self:GetOwner():EyeAngles()

    self:SetNextSecondaryFire(CurTime() + 0.075)

    self:SetNWBool("bipod", true)
end

function SWEP:ExitBipod()
    if !self:GetNWBool("bipod", false) then return end
    if CurTime() < self:GetNextSecondaryFire() then return end

    if self.Animations.exit_bipod then
        self:PlayAnimation("exit_bipod")
    end

    self:MyEmitSound(self.ExitBipodSound)
    self:DoLHIKAnimation("exit", 0.5)

    self:SetNextSecondaryFire(CurTime() + 0.075)

    self:SetNWBool("bipod", false)
end