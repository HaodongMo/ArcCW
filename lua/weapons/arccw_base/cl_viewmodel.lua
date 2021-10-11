local mth = math
local m_sin = mth.sin
local m_cos = mth.cos
local m_min = mth.min
local m_appor = mth.Approach
local m_clamp = mth.Clamp
local m_angdif = mth.AngleDifference
local f_lerp = Lerp
local srf = surface
SWEP.ActualVMData = false
local swayxmult, swayymult, swayzmult, swayspeed = 1, 1, 1, 1
local lookxmult, lookymult = 1, 1
SWEP.VMPos = Vector()
SWEP.VMAng = Angle()
SWEP.VMPosOffset = Vector()
SWEP.VMAngOffset = Angle()
SWEP.VMPosOffset_Lerp = Vector()
SWEP.VMAngOffset_Lerp = Angle()
SWEP.VMLookLerp = Angle()
SWEP.StepBob = 0
SWEP.StepBobLerp = 0
SWEP.StepRandomX = 1
SWEP.StepRandomY = 1
SWEP.LastEyeAng = Angle()
SWEP.SmoothEyeAng = Angle()
SWEP.LastVelocity = Vector()
SWEP.Velocity_Lerp = Vector()
SWEP.VelocityLastDiff = 0
SWEP.Breath_Intensity = 1
SWEP.Breath_Rate = 1

local lst = SysTime()
local function scrunkly()
    local ret = (SysTime() - (lst or SysTime())) * GetConVar("host_timescale"):GetFloat()
    return ret
end

local function LerpC(t, a, b, powa)
    return a + (b - a) * math.pow(t, powa)
end

function SWEP:Move_Process(EyePos, EyeAng, velocity)
    local VMPos, VMAng = self.VMPos, self.VMAng
    local VMPosOffset, VMAngOffset = self.VMPosOffset, self.VMAngOffset
    local VMPosOffset_Lerp, VMAngOffset_Lerp = self.VMPosOffset_Lerp, self.VMAngOffset_Lerp
    local FT = scrunkly()
    local sightedmult = (self:GetState() == ArcCW.STATE_SIGHTS and 0.05) or 1
    local sg = self:GetSightDelta()
    VMPos:Set(EyePos)
    VMAng:Set(EyeAng)
    VMPosOffset.x = self:GetOwner():GetVelocity().z * 0.0025 * sightedmult
    VMPosOffset.x = VMPosOffset.x + (velocity.x * 0.001 * sg)
    VMPosOffset.y = math.Clamp(velocity.y * -0.002, -1, 1) * sightedmult
    VMPosOffset.z = math.Clamp(VMPosOffset.x * -2, -4, 4)
    VMPosOffset_Lerp.x = Lerp(8 * FT, VMPosOffset_Lerp.x, VMPosOffset.x)
    VMPosOffset_Lerp.y = Lerp(8 * FT, VMPosOffset_Lerp.y, VMPosOffset.y)
    VMPosOffset_Lerp.z = Lerp(8 * FT, VMPosOffset_Lerp.z, VMPosOffset.z)
    --VMAngOffset.x = math.Clamp(VMPosOffset.x * 8, -4, 4)
    VMAngOffset.y = VMPosOffset.y
    VMAngOffset.z = VMPosOffset.y * 0.5 + (VMPosOffset.x * -5) + (velocity.x * -0.005 * sg)
    VMAngOffset_Lerp.x = LerpC(10 * FT, VMAngOffset_Lerp.x, VMAngOffset.x, 0.75)
    VMAngOffset_Lerp.y = LerpC(5 * FT, VMAngOffset_Lerp.y, VMAngOffset.y, 0.6)
    VMAngOffset_Lerp.z = Lerp(25 * FT, VMAngOffset_Lerp.z, VMAngOffset.z)
    VMPos:Add(VMAng:Up() * VMPosOffset_Lerp.x)
    VMPos:Add(VMAng:Right() * VMPosOffset_Lerp.y)
    VMPos:Add(VMAng:Forward() * VMPosOffset_Lerp.z)
    VMAngOffset_Lerp:Normalize()
    VMAng:Add(VMAngOffset_Lerp)
end

local stepend = math.pi * 4

function SWEP:Step_Process(EyePos, EyeAng, velocity)

    local VMPos, VMAng = self.VMPos, self.VMAng
    local VMPosOffset, VMAngOffset = self.VMPosOffset, self.VMAngOffset
    local VMPosOffset_Lerp, VMAngOffset_Lerp = self.VMPosOffset_Lerp, self.VMAngOffset_Lerp
    velocity = math.min(velocity:Length(), 400)

    if self:GetState() == ArcCW.STATE_SPRINT and self:SelectAnimation("idle_sprint") then
        velocity = 0
    else
        velocity = velocity * Lerp(self:GetSprintDelta(), 1, 1.25)
    end

    local delta = math.abs(self.StepBob * 2 / stepend - 1)
    local FT = scrunkly() --FrameTime()
    local FTMult = 300 * FT
    local sightedmult = (self:GetState() == ArcCW.STATE_SIGHTS and 0.25) or 1
    local sprintmult = (self:GetState() == ArcCW.STATE_SPRINT and 2) or 1
    local onground = self:GetOwner():OnGround()
    self.StepBob = self.StepBob + (velocity * 0.00015 + (math.pow(delta, 0.01) * 0.03)) * swayspeed * FTMult

    if self.StepBob >= stepend then
        self.StepBob = 0
        self.StepRandomX = math.Rand(1, 1.5)
        self.StepRandomY = math.Rand(1, 1.5)
    end

    if velocity == 0 then
        self.StepBob = 0
    end

    if onground then
        -- oh no it says sex tra
        local sextra = Vector()
        if (self:GetState() == ArcCW.STATE_SPRINT and !self:SelectAnimation("idle_sprint")) or true then
            sextra = LerpVector(self:GetSprintDelta(), vector_origin, Vector(0.0002, 0.001, 0.005))
        end

        VMPosOffset.x = (math.sin(self.StepBob) * velocity * (0.000375 + sextra.x) * sightedmult * swayxmult) * self.StepRandomX
        VMPosOffset.y = (math.sin(self.StepBob * 0.5) * velocity * (0.0005 + sextra.y) * sightedmult * sprintmult * swayymult) * self.StepRandomY
        VMPosOffset.z = math.sin(self.StepBob * 0.75) * velocity * (0.002 + sextra.z) * sightedmult * swayzmult
    end

    VMPosOffset_Lerp.x = Lerp(32 * FT, VMPosOffset_Lerp.x, VMPosOffset.x)
    VMPosOffset_Lerp.y = Lerp(4 * FT, VMPosOffset_Lerp.y, VMPosOffset.y)
    VMPosOffset_Lerp.z = Lerp(2 * FT, VMPosOffset_Lerp.z, VMPosOffset.z)
    VMAngOffset.x = VMPosOffset_Lerp.x * 2
    VMAngOffset.y = VMPosOffset_Lerp.y * -7.5
    VMAngOffset.z = VMPosOffset_Lerp.y * 10
    VMPos:Add(VMAng:Up() * VMPosOffset_Lerp.x)
    VMPos:Add(VMAng:Right() * VMPosOffset_Lerp.y)
    VMPos:Add(VMAng:Forward() * VMPosOffset_Lerp.z)
    VMAng:Add(VMAngOffset)
end

function SWEP:Breath_Health()
    local owner = self:GetOwner()
    if !IsValid(owner) then return end
    local health = owner:Health()
    local maxhealth = owner:GetMaxHealth()
    self.Breath_Intensity = math.Clamp(maxhealth / health, 0, 2)
    self.Breath_Rate = math.Clamp((maxhealth * 0.5) / health, 1, 1.5)
end

function SWEP:Breath_StateMult()
    local owner = self:GetOwner()
    if !IsValid(owner) then return end
    local sightedmult = (self:GetState() == ArcCW.STATE_SIGHTS and 0.05) or 1
    self.Breath_Intensity = self.Breath_Intensity * sightedmult
end

function SWEP:Breath_Process(EyePos, EyeAng)
    local VMPos, VMAng = self.VMPos, self.VMAng
    local VMPosOffset, VMAngOffset = self.VMPosOffset, self.VMAngOffset
    self:Breath_Health()
    self:Breath_StateMult()
    VMPosOffset.x = (math.sin(CurTime() * 2 * self.Breath_Rate) * 0.1) * self.Breath_Intensity
    VMPosOffset.y = (math.sin(CurTime() * 2.5 * self.Breath_Rate) * 0.025) * self.Breath_Intensity
    VMAngOffset.x = VMPosOffset.x * 1.5
    VMAngOffset.y = VMPosOffset.y * 2
    VMAngOffset.z = VMPosOffset.y * VMPosOffset.x * -40
    VMPos:Add(VMAng:Up() * VMPosOffset.x)
    VMPos:Add(VMAng:Right() * VMPosOffset.y)
    VMAng:Add(VMAngOffset)
end

function SWEP:Look_Process(EyePos, EyeAng, velocity)
    local VMPos, VMAng = self.VMPos, self.VMAng
    local VMPosOffset, VMAngOffset = self.VMPosOffset, self.VMAngOffset
    local FT = scrunkly()
    local sightedmult = (self:GetState() == ArcCW.STATE_SIGHTS and 0.25) or 1
    self.SmoothEyeAng = LerpAngle(0.05, self.SmoothEyeAng, EyeAng - self.LastEyeAng)
    local xd, yd = (velocity.z/10), (velocity.y/200)
    VMPosOffset.x = (-self.SmoothEyeAng.x) * -0.5 * sightedmult * lookxmult
    VMPosOffset.y = (self.SmoothEyeAng.y) * 0.5 * sightedmult * lookymult
    VMAngOffset.x = VMPosOffset.x * 0.75
    VMAngOffset.y = VMPosOffset.y * 2.5
    VMAngOffset.z = (VMPosOffset.x * 2) + (VMPosOffset.y * -2)
    self.VMLookLerp.y = Lerp(FT * 10, self.VMLookLerp.y, VMAngOffset.y * -1.5 + self.SmoothEyeAng.y)
    VMAng.y = VMAng.y - self.VMLookLerp.y
    VMPos:Add(VMAng:Up() * VMPosOffset.x)
    VMPos:Add(VMAng:Right() * VMPosOffset.y)
    VMAng:Add(VMAngOffset)
end

function SWEP:GetVMPosition(EyePos, EyeAng)
    local velocity = self:GetOwner():GetVelocity()
    velocity = WorldToLocal(velocity, angle_zero, vector_origin, EyeAng)
    self:Move_Process(EyePos, EyeAng, velocity)
    self:Step_Process(EyePos, EyeAng, velocity)
    self:Breath_Process(EyePos, EyeAng)
    self:Look_Process(EyePos, EyeAng, velocity)
    self.LastEyeAng = EyeAng
    self.LastEyePos = EyePos
    self.LastVelocity = velocity

    return self.VMPos, self.VMAng
end

local function ApprVecAng(from, to, dlt)
    local ret = (isangle(from) and isangle(to)) and Angle() or Vector()
    ret[1] = m_appor(from[1], to[1], dlt)
    ret[2] = m_appor(from[2], to[2], dlt)
    ret[3] = m_appor(from[3], to[3], dlt)

    return ret
end

SWEP.TheJ = {posa = Vector(), anga = Angle()}

function SWEP:GetViewModelPosition(pos, ang)
    if GetConVar("arccw_dev_benchgun"):GetBool() then
        if GetConVar("arccw_dev_benchgun_custom"):GetString() then
            local bgc = GetConVar("arccw_dev_benchgun_custom"):GetString()
            if string.Left(bgc, 6) != "setpos" then return Vector(0, 0, 0), Angle(0, 0, 0) end

            bgc = string.TrimLeft(bgc, "setpos ")
            bgc = string.Replace(bgc, ";setang", "")
            bgc = string.Explode(" ", bgc)

            return Vector(bgc[1], bgc[2], bgc[3]), Angle(bgc[4], bgc[5], bgc[6])
        else
            return Vector(0, 0, 0), Angle(0, 0, 0)
        end
    end

    local owner = self:GetOwner()
    if !IsValid(owner) or !owner:Alive() then return end
    local SP = game.SinglePlayer()
    local FT = scrunkly()
    local CT = CurTime()
    local TargetTick = (1 / FT) / 66.66

    if TargetTick < 1 then
        FT = FT * TargetTick
    end

    local gunbone, gbslot = self:GetBuff_Override("LHIK_GunDriver")
    local FT5, FT10 = FT * 5, FT * 10
    local oldpos, oldang = Vector(), Angle()
    local asight = self:GetActiveSights()
    local state = self:GetState()
    local sgtd = self:GetSightDelta()
    local sprd = self:GetSprintDelta()

    oldpos:Set(pos)
    oldang:Set(ang)
    ang = ang - self:GetOurViewPunchAngles()

    actual = self.ActualVMData or {
        pos = Vector(),
        ang = Angle(),
        down = 1,
        sway = 1,
        bob = 1
    }

    local target = {}
    target.pos = self:GetBuff_Override("Override_ActivePos") or self.ActivePos
    target.ang = self:GetBuff_Override("Override_ActiveAng") or self.ActiveAng
    target.down = 1
    target.sway = 2
    target.bob = 2

    if self:GetReloading() then
        if self:GetBuff_Override("Override_ReloadPos") or self.ReloadPos then
            target.pos = self.ReloadPos
        end

        if self:GetBuff_Override("Override_ReloadAng") or self.ReloadAng then
            target.ang = self.ReloadAng
        end
    end

    local vm_right = GetConVar("arccw_vm_right"):GetFloat()
    local vm_up = GetConVar("arccw_vm_up"):GetFloat()
    local vm_forward = GetConVar("arccw_vm_forward"):GetFloat()
    local vm_fov = GetConVar("arccw_vm_fov"):GetFloat()

    if owner:Crouching() or owner:KeyDown(IN_DUCK) then
        target.down = 0

        if self:GetBuff("CrouchPos", true) then
            target.pos = self.CrouchPos
        end

        if self:GetBuff("CrouchAng", true) then
            target.ang = self.CrouchAng
        end
    end

    if self:InBipod() then
        if !self:GetBipodAngle() then
            self:SetBipodPos(self:GetOwner():EyePos())
            self:SetBipodAngle(self:GetOwner():EyeAngles())
        end

        local BEA = self:GetBipodAngle() - owner:EyeAngles()
        local bpos = self:GetBuff_Override("Override_InBipodPos", self.InBipodPos)
        target.pos = asight and asight.Pos or target.pos
        target.ang = asight and asight.Ang or target.ang
        target.pos = target.pos + ((BEA):Right() * bpos.x * self.InBipodMult.x)
        target.pos = target.pos + ((BEA):Forward() * bpos.y * self.InBipodMult.y)
        target.pos = target.pos + ((BEA):Up() * bpos.z * self.InBipodMult.z)
        target.sway = 0.2
    end

    target.pos = target.pos + Vector(vm_right, vm_forward, vm_up)
    local sprinted = self.Sprinted or state == ArcCW.STATE_SPRINT
    local sighted = self.Sighted or state == ArcCW.STATE_SIGHTS
    local holstered = self:GetCurrentFiremode().Mode == 0

    if SP then
        sprinted = state == ArcCW.STATE_SPRINT
        sighted = state == ArcCW.STATE_SIGHTS
    end

    if state == ArcCW.STATE_CUSTOMIZE then
        target.pos = Vector()
        target.ang = Angle()
        target.down = 1
        target.sway = 3
        target.bob = 1
        local mx, my = input.GetCursorPos()
        mx = 2 * mx / ScrW()
        my = 2 * my / ScrH()
        target.pos:Set(self:GetBuff("CustomizePos"))
        target.ang:Set(self:GetBuff("CustomizeAng"))
        target.pos = target.pos + Vector(mx, 0, my)
        target.ang = target.ang + Angle(0, my * 2, mx * 2)

        if self.InAttMenu then
            target.ang = target.ang + Angle(0, -5, 0)
        end
    end

    -- Sprinting
    do
        local hpos, spos = self:GetBuff("HolsterPos", true), self:GetBuff("SprintPos", true)
        local hang, sang = self:GetBuff("HolsterAng", true), self:GetBuff("SprintAng", true)
        local aaaapos = holstered and (hpos or spos) or (spos or hpos)
        local aaaaang = holstered and (hang or sang) or (sang or hang)

        local sd = (holstered and 1) or (!(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) and self:GetSprintDelta()) or 0
        sd = math.pow(math.sin(sd * math.pi * 0.5), 2)
        target.pos = f_lerp(sd, target.pos, aaaapos)
        target.ang = f_lerp(sd, target.ang, aaaaang)

        local fu_sprint = (self:GetState() == ArcCW.STATE_SPRINT and self:SelectAnimation("idle_sprint"))

        target.sway = target.sway * f_lerp(sd, 1, fu_sprint and 0 or 2)
        target.bob = target.bob * f_lerp(sd, 1, fu_sprint and 0 or 2)

        --[[if ang.p < -15 then
            target.ang.p = target.ang.p + ang.p + 15
        end
        target.ang.p = m_clamp(target.ang.p, -80, 80)]]
    end

    -- Sighting
    if asight then
        local delta = sgtd
        delta = math.pow(math.sin(delta * math.pi * 0.5), math.pi)
        local im = asight.Midpoint

        local coolilove = delta * math.cos(delta * math.pi * 0.5)
        local joffset = (im and im.Pos or Vector(0, 15, -4)) * coolilove
        local jaffset = (im and im.Ang or Angle(0, 0, -45)) * coolilove

        if !sighted then
            joffset = Vector(1, 5, -1) * coolilove
            jaffset = Angle(-5, 0, -10) * coolilove
        end

        target.pos = f_lerp(delta, asight.Pos, target.pos + Vector(0, 0, -1)) + joffset
        target.ang = f_lerp(delta, asight.Ang, target.ang) + jaffset
        target.evpos = f_lerp(delta, asight.EVPos or Vector(), Vector(0, 0, 0))
        target.evang = f_lerp(delta, asight.EVAng or Angle(), Angle(0, 0, 0))
        target.down = 0
        target.sway = target.sway * f_lerp(delta, 0.1, 1)
        target.bob = target.bob * f_lerp(delta, 0.1, 1)

        -- wtf is this?
        local sightroll = self:GetBuff_Override("Override_AddSightRoll")

        if sightroll then
            target.ang = Angle()
            target.ang:Set(asight.Ang)
            target.ang.r = sightroll
        end
    end

    -- busts shit
    --[[local deg = self:BarrelHitWall()

    if deg > 0 then
        target.pos = LerpVector(deg, target.pos, self.HolsterPos)
        target.ang = LerpAngle(deg, target.ang, self.HolsterAng)
        target.down = 2
        target.sway = 2
        target.bob = 2
    end]]

    if !isangle(target.ang) then
        target.ang = Angle(target.ang)
    end

    if self.InProcDraw then
        self.InProcHolster = false
        local delta = m_clamp((CT - self.ProcDrawTime) / (0.25 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)
        target.pos = LerpVector(delta, Vector(0, 0, -5), target.pos)
        target.ang = LerpAngle(delta, Angle(-70, 30, 0), target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob
    end

    if self.InProcHolster then
        self.InProcDraw = false
        local delta = 1 - m_clamp((CT - self.ProcHolsterTime) / (0.25 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)
        target.pos = LerpVector(delta, Vector(0, 0, -5), target.pos)
        target.ang = LerpAngle(delta, Angle(-70, 30, 10), target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob
    end

    if self.InProcBash then
        self.InProcDraw = false
        local mult = self:GetBuff_Mult("Mult_MeleeTime")
        local mtime = self.MeleeTime * mult
        local delta = 1 - m_clamp((CT - self.ProcBashTime) / mtime, 0, 1)
        local bp, ba = self.BashPos, self.BashAng
        bp = self:GetBuff_Override("Override_BashPos") or bp
        ba = self:GetBuff_Override("Override_BashAng") or ba

        if delta > 0.3 then
            bp, ba = self.BashPreparePos, self.BashPrepareAng
            bp = self:GetBuff_Override("Override_BashPreparePos") or bp
            ba = self:GetBuff_Override("Override_BashPrepareAng") or ba
            delta = (delta - 0.5) * 2
        else
            delta = delta * 2
        end

        target.pos = LerpVector(delta, bp, target.pos)
        target.ang = LerpAngle(delta, ba, target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob
        target.speed = 10

        if delta == 0 then
            self.InProcBash = false
        end
    end

    if self.ViewModel_Hit then
        local nap = Vector()
        nap[1] = self.ViewModel_Hit[1]
        nap[2] = self.ViewModel_Hit[2]
        nap[3] = self.ViewModel_Hit[3]
        nap[1] = m_clamp(nap[2], -1, 1) * 0.25
        nap[3] = m_clamp(nap[1], -1, 1) * 1
        target.pos = target.pos + nap

        if !self.ViewModel_Hit:IsZero() then
            local naa = Angle()
            naa[1] = self.ViewModel_Hit[1]
            naa[2] = self.ViewModel_Hit[2]
            naa[3] = self.ViewModel_Hit[3]
            naa[1] = m_clamp(naa[1], -1, 1) * 5
            naa[2] = m_clamp(naa[2], -1, 1) * -2
            naa[3] = m_clamp(naa[3], -1, 1) * 12.5
            target.ang = target.ang + naa
        end

        local nvmh = Vector()
        local spd = self.ViewModel_Hit:Length()
        nvmh[1] = m_appor(self.ViewModel_Hit[1], 0, FT5 * spd)
        nvmh[2] = m_appor(self.ViewModel_Hit[2], 0, FT5 * spd)
        nvmh[3] = m_appor(self.ViewModel_Hit[3], 0, FT5 * spd)
        self.ViewModel_Hit = nvmh
    end

    if GetConVar("arccw_shakevm"):GetBool() and !engine.IsRecordingDemo() then target.pos = target.pos + (VectorRand() * self.RecoilAmount * 0.2) * self.RecoilVMShake end
    local speed = target.speed or 3
    -- For some reason, in multiplayer the sighting speed is twice as fast
    -- speed = 1 / self:GetSightTime() * speed * FT * (SP and 1 or 0.5)
    -- speed = ( 40 / ( self:GetState() == ArcCW.STATE_SIGHTS and self:GetSightTime() or 1 ) ) * FT * (SP and 1 or 0.5)
    -- WHAT THE FUCK IS WRONG WITH YOU
    speed = 15 * FT * (SP and 1 or 2)
    actual.pos = LerpVector(speed, actual.pos, target.pos)
    actual.ang = LerpAngle(speed, actual.ang, target.ang)
    actual.down = f_lerp(speed, actual.down, target.down)
    actual.sway = f_lerp(speed, actual.sway, target.sway)
    actual.bob = f_lerp(speed, actual.bob, target.bob)
    actual.evpos = f_lerp(speed, actual.evpos or Vector(), target.evpos or Vector())
    actual.evang = f_lerp(speed, actual.evang or Angle(), target.evang or Angle())
    actual.pos = ApprVecAng(actual.pos, target.pos, speed * 0.1)
    actual.ang = ApprVecAng(actual.ang, target.ang, speed * 0.1)
    actual.down = m_appor(actual.down, target.down, speed * 0.1)
    local coolsway = GetConVar("arccw_vm_coolsway"):GetBool()
    self.SwayScale = (coolsway and 0) or actual.sway
    self.BobScale = (coolsway and 0) or actual.bob

    if coolsway then
        swayxmult = GetConVar("arccw_vm_sway_zmult"):GetFloat() or 1
        swayymult = GetConVar("arccw_vm_sway_xmult"):GetFloat() or 1
        swayzmult = GetConVar("arccw_vm_sway_ymult"):GetFloat() or 1
        swayspeed = GetConVar("arccw_vm_sway_speedmult"):GetFloat() or 1
        lookxmult = GetConVar("arccw_vm_look_xmult"):GetFloat() or 1
        lookymult = GetConVar("arccw_vm_look_ymult"):GetFloat() or 1
        local npos, nang = self:GetVMPosition(oldpos, oldang)
        pos:Set(npos)
        ang:Set(nang)
    end

    pos = pos + math.min(self.RecoilPunchBack, Lerp(self:GetSightDelta(), self.RecoilPunchBackMaxSights or 1, self.RecoilPunchBackMax)) * -oldang:Forward()
    ang:RotateAroundAxis(oldang:Right(), actual.ang.x)
    ang:RotateAroundAxis(oldang:Up(), actual.ang.y)
    ang:RotateAroundAxis(oldang:Forward(), actual.ang.z)
    ang:RotateAroundAxis(oldang:Right(), actual.evang.x)
    ang:RotateAroundAxis(oldang:Up(), actual.evang.y)
    ang:RotateAroundAxis(oldang:Forward(), actual.evang.z)
    pos = pos + (oldang:Right() * actual.evpos.x)
    pos = pos + (oldang:Forward() * actual.evpos.y)
    pos = pos + (oldang:Up() * actual.evpos.z)
    pos = pos + actual.pos.x * ang:Right()
    pos = pos + actual.pos.y * ang:Forward()
    pos = pos + actual.pos.z * ang:Up()
    pos = pos - Vector(0, 0, actual.down)
    -- if asight and asight.Holosight then ang = ang - self:GetOurViewPunchAngles() end
    ang = ang + self:GetOurViewPunchAngles() * Lerp(sgtd, 1, -1)
    -- if IsFirstTimePredicted() then
    self.ActualVMData = actual

    -- end
    if gunbone then
        local magnitude = Lerp(sgtd, 0.1, 1)
        local lhik_model = self.Attachments[gbslot].VElement.Model
        local att = lhik_model:LookupAttachment(gunbone)
        local attang = lhik_model:GetAttachment(att).Ang
        local attpos = lhik_model:GetAttachment(att).Pos
        attang = lhik_model:WorldToLocalAngles(attang)
        attpos = lhik_model:WorldToLocal(attpos)
        attang = attang - self.LHIKGunAng
        attpos = attpos - self.LHIKGunPos
        attang = attang * magnitude
        attpos = attpos * magnitude
        -- attang = vm:LocalToWorldAngles(attang)
        ang = ang + attang
        pos = pos + attpos
    end

    lst = SysTime()
    return pos, ang
end

function SWEP:ShouldCheapWorldModel()
    local lp = LocalPlayer()
    if lp:GetObserverMode() == OBS_MODE_IN_EYE and lp:GetObserverTarget() == self:GetOwner() then return true end
    if !IsValid(self:GetOwner()) and !GetConVar("arccw_att_showground"):GetBool() then return true end

    return !GetConVar("arccw_att_showothers"):GetBool()
end

function SWEP:DrawWorldModel()
    -- 512^2
    if !IsValid(self:GetOwner()) and !TTT2 and GetConVar("arccw_2d3d"):GetBool() and (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 then
        local ang = LocalPlayer():EyeAngles()
        ang:RotateAroundAxis(ang:Forward(), 180)
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)
        cam.Start3D2D(self:WorldSpaceCenter() + Vector(0, 0, 16), ang, 0.1)
        srf.SetFont("ArcCW_32_Unscaled")
        local w = srf.GetTextSize(self.PrintName)
        srf.SetTextPos(-w / 2, 0)
        srf.SetTextColor(255, 255, 255, 255)
        srf.DrawText(self.PrintName)
        srf.SetFont("ArcCW_24_Unscaled")
        local count = self:CountAttachments()

        if count > 0 then
            local t = tostring(count) .. " Attachments"
            w = srf.GetTextSize(t)
            srf.SetTextPos(-w / 2, 32)
            srf.SetTextColor(255, 255, 255, 255)
            srf.DrawText(t)
        end

        cam.End3D2D()
    end

    self:DrawCustomModel(true)
    self:DoLaser(true)

    if self:ShouldGlint() then
        self:DoScopeGlint()
    end

    if !self.CertainAboutAtts then
        net.Start("arccw_rqwpnnet")
        net.WriteEntity(self)
        net.SendToServer()
    end
end

function SWEP:ShouldCheapScope()
    if !self:GetConVar("arccw_cheapscopes"):GetBool() then return end
end

local lst2 = SysTime()
function SWEP:PreDrawViewModel(vm)
    if ArcCW.VM_OverDraw then return end
    if !vm then return end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then
        self:BlurNotWeapon()
    end

    if GetConVar("arccw_cheapscopesautoconfig"):GetBool() then
        local fps = 1 / (SysTime() - lst2)
        lst2 = SysTime()
        local lowfps = fps <= 45
        GetConVar("arccw_cheapscopes"):SetBool(lowfps)
        GetConVar("arccw_cheapscopesautoconfig"):SetBool(false)
    end

    local asight = self:GetActiveSights()

    if asight then
        if self:GetSightDelta() < 1 and asight.Holosight then
            ArcCW:DrawPhysBullets()
        end

        if GetConVar("arccw_cheapscopes"):GetBool() and self:GetSightDelta() < 1 and asight.MagnifiedOptic then
            self:FormCheapScope()
        end

        if self:GetSightDelta() < 1 and asight.ScopeTexture then
            self:FormCheapScope()
        end
    end

    cam.Start3D(EyePos(), EyeAngles(), self.CurrentViewModelFOV or self.ViewModelFOV, nil, nil, nil, nil, 1.5, 15000)
    cam.IgnoreZ(true)
    self:DrawCustomModel(false)
    self:DoLHIK()
end

function SWEP:PostDrawViewModel()
    if ArcCW.VM_OverDraw then return end
    render.SetBlend(1)
    cam.End3D()
    cam.Start3D(EyePos(), EyeAngles(), self.CurrentViewModelFOV or self.ViewModelFOV, nil, nil, nil, nil, 0.1, 15000)
    cam.IgnoreZ(true)

    if ArcCW.Overdraw then
        ArcCW.Overdraw = false
    else
        self:DoLaser()
        self:DoHolosight()
    end

    cam.End3D()
end