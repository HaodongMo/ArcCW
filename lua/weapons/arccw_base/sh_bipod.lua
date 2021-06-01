function SWEP:InBipod()
    local bip = self:GetInBipod()

    -- if !self:CanBipod() then
    --     self:ExitBipod()
    -- end

    if IsValid(self:GetOwner()) and self:GetBipodPos() != self:GetOwner():EyePos() then
        self:ExitBipod()
    end

    return bip
end

SWEP.CachedCanBipod = true
SWEP.CachedCanBipodTime = 0

function SWEP:CanBipod()
    if !(self:GetBuff_Override("Bipod") or self.Bipod_Integral) then return false end

    if self.CachedCanBipodTime >= CurTime() then return self.CachedCanBipod end

    -- local bip = self:GetInBipod()

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
    if self:GetInBipod() then return end
    if !self:CanBipod() then return end
    --if CurTime() < self:GetNextSecondaryFire() then return end

    if self.Animations.enter_bipod then
        self:PlayAnimation("enter_bipod")
    end

    if CLIENT and self:GetBuff_Override("LHIK") then
        self:DoLHIKAnimation("enter", 0.5)
    end

    self:SetBipodPos(self:GetOwner():EyePos())
    self:SetBipodAngle(self:GetOwner():EyeAngles())

    self:SetNextSecondaryFire(CurTime() + 0.075)

    if game.SinglePlayer() and CLIENT then return end

    self:MyEmitSound(self.EnterBipodSound)
    self:SetInBipod(true)
end

function SWEP:ExitBipod()
    if !self:GetInBipod() then return end
    if CurTime() < self:GetNextSecondaryFire() then return end

    if self.Animations.exit_bipod then
        self:PlayAnimation("exit_bipod")
    end

    if CLIENT and self:GetBuff_Override("LHIK") then
        self:DoLHIKAnimation("exit", 0.5)
    end

    self:SetNextSecondaryFire(CurTime() + 0.075)

    self:SetBipodPos(Vector(0, 0, 0))
    self:SetBipodAngle(Angle(0, 0, 0))

    if game.SinglePlayer() and CLIENT then return end

    self:MyEmitSound(self.ExitBipodSound)
    self:SetInBipod(false)
end