--[[
    Please, for the love of god, don't create objects in functions that are called multiple times per frame.
    The garbage collector will explode and so will players' comptuters.

    That means minimize usage of things that generate new objects, including:
        calls to Vector() or Angle(); use vector_origin and angle_zero if the value isn't modified
        arithmetic using +, -, * and / on Vectors and Angles; modifying individual parameters is fine
        functions like Angle:Right() and Vector:Angle(); however functions like Vector:Add() and Angle:Add() are fine

    Cache them if you use them more than one time!
]]

local mth = math
local m_appor = mth.Approach
local m_clamp = mth.Clamp
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

-- magic variables
local sprint_vec1 = Vector(-2, 5, 2)
local sprint_vec2 = Vector(0, 7, 3)
local sprint_ang1 = Angle(-15, -15, 0)
local spring_ang2 = Angle(-15, 15, -22)
local sight_vec1 = Vector(0, 15, -4)
local sight_vec2 = Vector(1, 5, -1)
local sight_ang1 = Angle(0, 0, -45)
local sight_ang2 = Angle(-5, 0, -10)
local sextra_vec = Vector(0.0002, 0.001, 0.005)

local procdraw_vec = Vector(0, 0, -5)
local procdraw_ang = Angle(-70, 30, 0)
local prochol_ang = Angle(-70, 30, 10)

local lst = SysTime()
local function scrunkly()
    local ret = (SysTime() - (lst or SysTime())) * GetConVar("host_timescale"):GetFloat()
    return ret
end

local function LerpC(t, a, b, powa)
    return a + (b - a) * math.pow(t, powa)
end

local function ApproachMod(usrobj, to, dlt)
    usrobj[1] = m_appor(usrobj[1], to[1], dlt)
    usrobj[2] = m_appor(usrobj[2], to[2], dlt)
    usrobj[3] = m_appor(usrobj[3], to[3], dlt)
end

local function LerpMod(usrobj, to, dlt, clamp_ang)
    usrobj[1] = f_lerp(dlt, usrobj[1], to[1])
    usrobj[2] = f_lerp(dlt, usrobj[2], to[2])
    usrobj[3] = f_lerp(dlt, usrobj[3], to[3])
    if clamp_ang then
        for i = 1, 3 do usrobj[i] = math.NormalizeAngle(usrobj[i]) end
    end
end

local function LerpMod2(from, usrobj, dlt, clamp_ang)
    usrobj[1] = f_lerp(dlt, from[1], usrobj[1])
    usrobj[2] = f_lerp(dlt, from[2], usrobj[2])
    usrobj[3] = f_lerp(dlt, from[3], usrobj[3])
    if clamp_ang then
        for i = 1, 3 do usrobj[i] = math.NormalizeAngle(usrobj[i]) end
    end
end

-- debug for testing garbage count
-- TODO: comment this out or something before actually going into main branch
local sw = false
local tries = {}
local totaltries = 1000
local sw_start = 0
local sw_orig = 0
concommand.Add("arccw_dev_stopwatch", function() tries = {} sw = true end)

local function stopwatch(name)
    if !sw then return end
    if name == true then
        local d = (collectgarbage("count") - sw_orig)
        if #tries == 0 then print("    total garbage: " .. d) end
        table.insert(tries, d)
        if #tries == totaltries then
            sw = false
            local average = 0
            for _, v in ipairs(tries) do average = average + v end
            average = average / totaltries
            print("----------------------------------")
            print("average over " .. totaltries .. " tries: " .. average)
        end
        return
    end
    local gb = collectgarbage("count")
    if name then
        if #tries == 0 then print(name .. ": " .. (gb - sw_start)) end
    else
        if #tries == 0 then print("----------------------------------") end
        sw_orig = gb
    end
    sw_start = gb
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
    VMPosOffset.x = math.Clamp(velocity.z * 0.0025, -1, 1) * sightedmult
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
    local VMPosOffset_Lerp = self.VMPosOffset_Lerp
    local state = self:GetState()
    local sprd = self:GetSprintDelta()

    if state == ArcCW.STATE_SPRINT and self:SelectAnimation("idle_sprint") and !self:GetReloading() and !self:CanShootWhileSprint() then
        velocity = 0
    else
        velocity = math.min(velocity:Length(), 400) * Lerp(sprd, 1, 1.25)
    end

    local delta = math.abs(self.StepBob * 2 / stepend - 1)
    local FT = scrunkly() --FrameTime()
    local sightedmult = (state == ArcCW.STATE_SIGHTS and 0.25) or 1
    local sprintmult = (state == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint() and 2) or 1
    local pronemult = (self:IsProne() and 10) or 1
    local onground = self:GetOwner():OnGround()
    self.StepBob = self.StepBob + (velocity * 0.00015 + (math.pow(delta, 0.01) * 0.03)) * swayspeed * FT * 300

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
        local sextra = vector_origin
        if (state == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint() and !self:SelectAnimation("idle_sprint")) or true then
            sextra = LerpVector(sprd, vector_origin, sextra_vec)
        end

        VMPosOffset.x = (math.sin(self.StepBob) * velocity * (0.000375 + sextra.x) * sightedmult * swayxmult) * self.StepRandomX
        VMPosOffset.y = (math.sin(self.StepBob * 0.5) * velocity * (0.0005 + sextra.y) * sightedmult * sprintmult * pronemult * swayymult) * self.StepRandomY
        VMPosOffset.z = math.sin(self.StepBob * 0.75) * velocity * (0.002 + sextra.z) * sightedmult * pronemult * swayzmult
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
    -- self:Breath_Health() Snaps around when regenerating
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
    -- local xd, yd = (velocity.z / 10), (velocity.y / 200)
    VMPosOffset.x = -self.SmoothEyeAng.x * -0.5 * sightedmult * lookxmult
    VMPosOffset.y = self.SmoothEyeAng.y * 0.5 * sightedmult * lookymult
    VMAngOffset.x = VMPosOffset.x * 0.75
    VMAngOffset.y = VMPosOffset.y * 2.5
    VMAngOffset.z = VMPosOffset.x * 2 + VMPosOffset.y * -2
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
    stopwatch("Move_Process")
    self:Step_Process(EyePos, EyeAng, velocity)
    stopwatch("Step_Process")
    self:Breath_Process(EyePos, EyeAng)
    stopwatch("Breath_Process")
    self:Look_Process(EyePos, EyeAng, velocity)
    stopwatch("Look_Process")
    self.LastEyeAng = EyeAng
    self.LastEyePos = EyePos
    self.LastVelocity = velocity

    return self.VMPos, self.VMAng
end

SWEP.TheJ = {posa = Vector(), anga = Angle()}
local rap_pos = Vector()
local rap_ang = Angle()

local actual
local target = {pos = Vector(), ang = Angle()}

local GunDriverFix = Angle( 0, 90, 90 )

function SWEP:GetViewModelPosition(pos, ang)
    if GetConVar("arccw_dev_benchgun"):GetBool() then
        if GetConVar("arccw_dev_benchgun_custom"):GetString() then
            local bgc = GetConVar("arccw_dev_benchgun_custom"):GetString()
            if string.Left(bgc, 6) != "setpos" then return vector_origin, angle_zero end

            bgc = string.TrimLeft(bgc, "setpos ")
            bgc = string.Replace(bgc, ";setang", "")
            bgc = string.Explode(" ", bgc)

            return Vector(bgc[1], bgc[2], bgc[3]), Angle(bgc[4], bgc[5], bgc[6])
        else
            return vector_origin, angle_zero
        end
    end

    stopwatch()

    local owner = self:GetOwner()
    if !IsValid(owner) or !owner:Alive() then return end
    local FT = scrunkly()
    local CT = CurTime()
    local TargetTick = (1 / FT) / 66.66
    local cdelta = math.Clamp(math.ease.InOutSine((owner:GetViewOffset().z - owner:GetCurrentViewOffset().z) / (owner:GetViewOffset().z - owner:GetViewOffsetDucked().z)),0,1)

    if TargetTick < 1 then
        FT = FT * TargetTick
    end

    local vm = LocalPlayer():GetViewModel()

    local asight = self:GetActiveSights()
    local state = self:GetState()
    local sgtd = self:GetSightDelta()
    local sprd = self:GetSprintDelta()

    local sprinted = self.Sprinted or state == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint()
    local sighted = self.Sighted or state == ArcCW.STATE_SIGHTS
    local holstered = self:GetCurrentFiremode().Mode == 0

    if game.SinglePlayer() then
        sprinted = state == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint()
        sighted = state == ArcCW.STATE_SIGHTS
    end

    local oldpos, oldang = Vector(), Angle()
    oldpos:Set(pos)
    oldang:Set(ang)
    ang:Sub(self:GetOurViewPunchAngles())

    actual = self.ActualVMData or {
        pos = Vector(),
        ang = Angle(),
        down = 1,
        sway = 1,
        bob = 1,
        evpos = Vector(),
        evang = Angle(),
    }

    local apos, aang = self:GetBuff_Override("Override_ActivePos", self.ActivePos), self:GetBuff_Override("Override_ActiveAng", self.ActiveAng)
    local cpos, cang = self:GetBuff("CrouchPos", true) or apos, self:GetBuff("CrouchAng", true) or aang
    target.down = 1
    target.sway = 2
    target.bob = 2

    stopwatch("set")

    if self:InBipod() and self:GetBipodAngle() then
        local bpos = self:GetBuff_Override("Override_InBipodPos", self.InBipodPos)
        target.pos:Set(asight and asight.Pos or apos)
        target.ang:Set(asight and asight.Ang or aang)

        local BEA = (self.BipodStartAngle or self:GetBipodAngle()) - owner:EyeAngles()
        target.pos:Add(BEA:Right() * bpos.x * self.InBipodMult.x)
        target.pos:Add(BEA:Forward() * bpos.y * self.InBipodMult.y)
        target.pos:Add(BEA:Up() * bpos.z * self.InBipodMult.z)
        target.sway = 0.2
    -- elseif (owner:Crouching() or owner:KeyDown(IN_DUCK)) and !self:GetReloading() then
        -- target.pos:Set(self:GetBuff("CrouchPos", true) or apos)
        -- target.ang:Set(self:GetBuff("CrouchAng", true) or aang)
    elseif self:GetReloading() then
        target.pos:Set(self:GetBuff("ReloadPos", true) or apos)
        target.ang:Set(self:GetBuff("ReloadAng", true) or aang)
    else
        target.pos:Set(apos)
        target.ang:Set(aang)
        LerpMod(target.pos, cpos, cdelta)
        LerpMod(target.ang, cang, cdelta, true)
    end
    if (owner:Crouching() or owner:KeyDown(IN_DUCK)) then target.down = 0 end

    stopwatch("reload, crouch, bipod")

    target.pos.x = target.pos.x + GetConVar("arccw_vm_right"):GetFloat()
    target.pos.y = target.pos.y + GetConVar("arccw_vm_forward"):GetFloat()
    target.pos.z = target.pos.z + GetConVar("arccw_vm_up"):GetFloat()

    target.ang.p = target.ang.p + GetConVar("arccw_vm_pitch"):GetFloat()
    target.ang.y = target.ang.y + GetConVar("arccw_vm_yaw"):GetFloat()
    target.ang.r = target.ang.r + GetConVar("arccw_vm_roll"):GetFloat()

    if state == ArcCW.STATE_CUSTOMIZE then
        target.down = 1
        target.sway = 3
        target.bob = 1
        local mx, my = input.GetCursorPos()
        mx = 2 * mx / ScrW()
        my = 2 * my / ScrH()
        target.pos:Set(self:GetBuff_Override("Override_CustomizePos", self.CustomizePos))
        target.ang:Set(self:GetBuff_Override("Override_CustomizeAng", self.CustomizeAng))
        target.pos.x = target.pos.x + mx
        target.pos.z = target.pos.z + my
        target.ang.y = target.ang.y + my * 2
        target.ang.r = target.ang.r + mx * 2
        if self.InAttMenu then
            target.ang.y = target.ang.y - 5
        end
    end

    stopwatch("cust")

    -- Sprinting
    local hpos, spos = self:GetBuff("HolsterPos", true), self:GetBuff("SprintPos", true)
    local hang, sang = self:GetBuff("HolsterAng", true), self:GetBuff("SprintAng", true)
    do
        local aaaapos = holstered and (hpos or spos) or (spos or hpos)
        local aaaaang = holstered and (hang or sang) or (sang or hang)

        local sd = (self:GetReloading() and 0) or (self:IsProne() and math.Clamp(owner:GetVelocity():Length() / prone.Config.MoveSpeed, 0, 1)) or (holstered and 1) or (!self:CanShootWhileSprint() and sprd) or 0
        sd = math.pow(math.sin(sd * math.pi * 0.5), 2)

        local d = math.pow(math.sin(sd * math.pi * 0.5), math.pi)
        local coolilove = d * math.cos(d * math.pi * 0.5)

        local joffset, jaffset
        if !sprinted then
            joffset = sprint_vec2
            jaffset = spring_ang2
        else
            joffset = sprint_vec1
            jaffset = sprint_ang1
        end

        LerpMod(target.pos, aaaapos, sd)
        LerpMod(target.ang, aaaaang, sd, true)
        for i = 1, 3 do
            target.pos[i] = target.pos[i] + joffset[i] * coolilove
            target.ang[i] = target.ang[i] + jaffset[i] * coolilove
        end

        local fu_sprint = (sprinted and self:SelectAnimation("idle_sprint"))

        target.sway = target.sway * f_lerp(sd, 1, fu_sprint and 0 or 2)
        target.bob = target.bob * f_lerp(sd, 1, fu_sprint and 0 or 2)
    end

    stopwatch("sprint")

    -- Sighting
    if asight then
        local delta = sgtd
        delta = math.pow(math.sin(delta * math.pi * 0.5), math.pi)
        local im = asight.Midpoint
        local coolilove = delta * math.cos(delta * math.pi * 0.5)

        local joffset, jaffset
        if !sighted then
            joffset = sight_vec2
            jaffset = sight_ang2
        else
            joffset = (im and im.Pos or sight_vec1)
            jaffset = (im and im.Ang or sight_ang1)
        end

        target.pos.z = target.pos.z - 1
        LerpMod2(asight.Pos, target.pos, delta)
        LerpMod2(asight.Ang, target.ang, delta)
        for i = 1, 3 do
            target.pos[i] = target.pos[i] + joffset[i] * coolilove
            target.ang[i] = target.ang[i] + jaffset[i] * coolilove
        end

        target.evpos = f_lerp(delta, asight.EVPos or vector_origin, vector_origin)
        target.evang = f_lerp(delta, asight.EVAng or angle_zero, angle_zero)

        target.down = 0
        target.sway = target.sway * f_lerp(delta, 0.1, 1)
        target.bob = target.bob * f_lerp(delta, 0.1, 1)
    end

    stopwatch("sight")

    local deg = self:GetBarrelNearWall()
    if deg > 0 and GetConVar("arccw_vm_nearwall"):GetBool() then
        LerpMod(target.pos, hpos, deg)
        LerpMod(target.ang, hang, deg)
        target.down = 2 * math.max(sgtd, 0.5)
    end

    if !isangle(target.ang) then
        target.ang = Angle(target.ang)
    end

    target.ang.y = target.ang.y + (self:GetFreeAimOffset().y * 0.5)
    target.ang.p = target.ang.p - (self:GetFreeAimOffset().p * 0.5)

    if self.InProcDraw then
        self.InProcHolster = false
        local delta = m_clamp((CT - self.ProcDrawTime) / (0.5 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)
        target.pos = LerpVector(delta, procdraw_vec, target.pos)
        target.ang = LerpAngle(delta, procdraw_ang, target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob
    end

    if self.InProcHolster then
        self.InProcDraw = false
        local delta = 1 - m_clamp((CT - self.ProcHolsterTime) / (0.25 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)
        target.pos = LerpVector(delta, procdraw_vec, target.pos)
        target.ang = LerpAngle(delta, prochol_ang, target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob
    end

    if self.InProcBash then
        self.InProcDraw = false
        local mult = self:GetBuff_Mult("Mult_MeleeTime")
        local mtime = self.MeleeTime * mult
        local delta = 1 - m_clamp((CT - self.ProcBashTime) / mtime, 0, 1)

        local bp, ba

        if delta > 0.3 then
            bp = self:GetBuff_Override("Override_BashPreparePos", self.BashPreparePos)
            ba = self:GetBuff_Override("Override_BashPrepareAng", self.BashPrepareAng)
            delta = (delta - 0.5) * 2
        else
            bp = self:GetBuff_Override("Override_BashPos", self.BashPos)
            ba = self:GetBuff_Override("Override_BashAng", self.BashAng)
            delta = delta * 2
        end

        LerpMod2(bp, target.pos, delta)
        LerpMod2(ba, target.ang, delta)

        target.speed = 10

        if delta == 0 then
            self.InProcBash = false
        end
    end

    stopwatch("proc")

    -- local gunbone, gbslot = self:GetBuff_Override("LHIK_GunDriver")
    -- if gunbone and IsValid(self.Attachments[gbslot].VElement.Model) and self.LHIKGunPos and self.LHIKGunAng then
    --     local magnitude = 1 --Lerp(sgtd, 0.1, 1)
    --     local lhik_model = self.Attachments[gbslot].VElement.Model
    --     local att = lhik_model:GetAttachment(lhik_model:LookupAttachment(gunbone))
    --     local attang = att.Ang
    --     local attpos = att.Pos
    --     attang = lhik_model:WorldToLocalAngles(attang)
    --     attpos = lhik_model:WorldToLocal(attpos)
    --     attang:Sub(self.LHIKGunAng)
    --     attpos:Sub(self.LHIKGunPos)
    --     attang:Mul(magnitude)
    --     attpos:Mul(magnitude)
    --     --target.ang:Add(attang)
    --     --target.pos:Add(attpos)
    --     --debugoverlay.Axis(lhik_model:GetPos() + attpos, att.Ang, 8, FrameTime() * 3, true)
    --     debugoverlay.Axis(lhik_model:GetPos(), att.Ang, 8, FrameTime() * 3, true)
    -- end

    -- stopwatch("gunbone")

    local vmhit = self.ViewModel_Hit
    if vmhit then
        if !vmhit:IsZero() then
            target.pos.x = target.pos.x + m_clamp(vmhit.y, -1, 1) * 0.25
            target.pos.y = target.pos.y + vmhit.y
            target.pos.z = target.pos.z + m_clamp(vmhit.x, -1, 1) * 1
            target.ang.x = target.ang.x + m_clamp(vmhit.x, -1, 1) * 5
            target.ang.y = target.ang.y + m_clamp(vmhit.y, -1, 1) * -2
            target.ang.z = target.ang.z + m_clamp(vmhit.z, -1, 1) * 12.5
        end

        local spd = vmhit:Length() * 5
        vmhit.x = m_appor(vmhit.x, 0, FT * spd)
        vmhit.y = m_appor(vmhit.y, 0, FT * spd)
        vmhit.z = m_appor(vmhit.z, 0, FT * spd)
    end

    if GetConVar("arccw_shakevm"):GetBool() and !engine.IsRecordingDemo() then
        target.pos:Add(VectorRand() * self.RecoilAmount * 0.2 * self.RecoilVMShake)
    end

    stopwatch("vmhit")

    local speed = 15 * FT * (game.SinglePlayer() and 1 or 2)

    LerpMod(actual.pos, target.pos, speed)
    LerpMod(actual.ang, target.ang, speed, true)
    LerpMod(actual.evpos, target.evpos or vector_origin, speed)
    LerpMod(actual.evang, target.evang or angle_zero, speed, true)
    actual.down = f_lerp(speed, actual.down, target.down)
    actual.sway = f_lerp(speed, actual.sway, target.sway)
    actual.bob = f_lerp(speed, actual.bob, target.bob)

    ApproachMod(actual.pos, target.pos, speed * 0.1)
    ApproachMod(actual.ang, target.ang, speed * 0.1)
    actual.down = m_appor(actual.down, target.down, speed * 0.1)

    stopwatch("actual -> target")

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

        local sd = self:GetSightDelta()
        lookxmult = Lerp(sd, 0, lookxmult)
        lookymult = Lerp(sd, 0, lookymult)
        swayxmult = Lerp(sd, 0, swayxmult)
        swayymult = Lerp(sd, 0, swayymult)
        swayzmult = Lerp(sd, 0, swayzmult)
        swayspeed = Lerp(sd, 0, swayspeed)

        stopwatch("before vmposition")
        local npos, nang = self:GetVMPosition(oldpos, oldang)
        pos:Set(npos)
        ang:Set(nang)
    end

    local old_r, old_f, old_u = oldang:Right(), oldang:Forward(), oldang:Up()
    pos:Add(math.min(self.RecoilPunchBack, Lerp(sgtd, self.RecoilPunchBackMaxSights or 1, self.RecoilPunchBackMax)) * -old_f)

    ang:RotateAroundAxis(old_r, actual.ang.x)
    ang:RotateAroundAxis(old_u, actual.ang.y)
    ang:RotateAroundAxis(old_f, actual.ang.z)
    ang:RotateAroundAxis(old_r, actual.evang.x)
    ang:RotateAroundAxis(old_u, actual.evang.y)
    ang:RotateAroundAxis(old_f, actual.evang.z)

    local new_r, new_f, new_u = ang:Right(), ang:Forward(), ang:Up()
    old_r:Mul(actual.evpos.x)
    old_f:Mul(actual.evpos.y)
    old_u:Mul(actual.evpos.z)
    pos:Add(old_r)
    pos:Add(old_f)
    pos:Add(old_u)
    new_r:Mul(actual.pos.x)
    new_f:Mul(actual.pos.y)
    new_u:Mul(actual.pos.z)
    pos:Add(new_r)
    pos:Add(new_f)
    pos:Add(new_u)

    pos.z = pos.z - actual.down

    ang:Add(self:GetOurViewPunchAngles() * Lerp(sgtd, 1, -1))

    local gunbone, gbslot = self:GetBuff_Override("LHIK_GunDriver")
    local lhik_model = gbslot and self.Attachments[gbslot].VElement and self.Attachments[gbslot].VElement.Model -- Visual M203 attachment
    local lhik_anim_model = gbslot and self.Attachments[gbslot].GodDriver and self.Attachments[gbslot].GodDriver.Model -- M203 anim and camera
    local lhik_refl_model = gbslot and self.Attachments[gbslot].ReflectDriver and self.Attachments[gbslot].ReflectDriver.Model -- Rifle
    if IsValid(lhik_model) and IsValid(lhik_anim_model) and IsValid(lhik_refl_model) and lhik_anim_model:GetAttachment(lhik_anim_model:LookupAttachment(gunbone)) then
        local att = lhik_anim_model:LookupAttachment(gunbone)
        local offset = lhik_anim_model:GetAttachment(att).Pos
        local affset = lhik_anim_model:GetAttachment(att).Ang

        affset:Sub( GunDriverFix )
        local r = affset.r
        affset.r = affset.p
        affset.p = -r
        affset.y = -affset.y

        local anchor = self.Attachments[gbslot].VMOffsetPos

        local looku = lhik_refl_model:LookupBone( self.Attachments[gbslot].Bone )
        local bonp, bona = lhik_refl_model:GetBonePosition( looku )
        if bonp == lhik_refl_model:GetPos() then
            bonp = lhik_refl_model:GetBoneMatrix( looku ):GetTranslation()
            bona = lhik_refl_model:GetBoneMatrix( looku ):GetAngles()
        end

        if anchor and bonp then -- Not ready / deploying
            anchor = ( bonp + ( (bona:Forward()*anchor.x) + (bona:Right()*anchor.y) + (bona:Up()*anchor.z) ) )

			debugoverlay.Axis(anchor, angle_zero, 4, FrameTime(), true)

            rap_pos, rap_ang = ArcCW.RotateAroundPoint2(pos, ang, anchor, offset, affset)
            rap_pos:Sub(pos)
            rap_ang:Sub(ang)

            pos:Add(rap_pos)
            ang:Add(rap_ang)
        end
    end

    self.ActualVMData = actual

    stopwatch("apply actual")

    stopwatch(true)

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

    if !self.CertainAboutAtts and !self.AttReqSent and IsValid(self:GetOwner()) then
        self.AttReqSent = true
        net.Start("arccw_rqwpnnet")
            net.WriteEntity(self)
        net.SendToServer()
    end
end

function SWEP:ShouldCheapScope()
    if !self:GetConVar("arccw_cheapscopes"):GetBool() then return end
end

local POSTVMDONE = nil
local POSTVMDONE_TIME = 0

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

    if asight and ((GetConVar("arccw_cheapscopes"):GetBool() and self:GetSightDelta() < 1 and asight.MagnifiedOptic)
            or (self:GetSightDelta() < 1 and asight.ScopeTexture)) then
        -- Necessary to call here since physbullets are not drawn until PreDrawEffects; cheap scope implementation will not allow them to be visible
        -- Introduces a bug when we try to call GetAttachment on the viewmodel in DrawPhysBullets here, so set a workaround variable to not call it
        ArcCW:DrawPhysBullets(true)
        self:FormCheapScope()
    end

    local coolFOV = self.CurrentViewModelFOV or self.ViewModelFOV

    if ArcCW.VMInRT then
        local mag = asight.ScopeMagnification
        coolFOV = self.ViewModelFOV - mag * 4 - (GetConVar("arccw_vm_add_ads"):GetFloat() * 3 or 0)
        ArcCW.VMInRT = false
    end

    cam.Start3D(EyePos(), EyeAngles(), self:QuickFOVix(coolFOV), nil, nil, nil, nil, 0.5, 1000)
    cam.IgnoreZ(true)
    self:DrawCustomModel(false)
    self:DoLHIK()

    if !ArcCW.Overdraw then
        self:DoLaser(false, true)
    end

    -- patrol
    if POSTVMDONE == false and POSTVMDONE_TIME <= CurTime() then
        POSTVMDONE_TIME = CurTime() + 1
        print( "[ArcCW] Warning: PostDrawViewModel failed response!! cam.End3D errors may be inbound!! You may have an addon conflict!!")
        print( "[ArcCW] Follow the troubleshooting guide at https://github.com/HaodongMo/ArcCW/wiki/Help-&-Troubleshooting#camend3d-errors")
    end
    POSTVMDONE = false
end

function SWEP:PostDrawViewModel()
    POSTVMDONE = true
    if ArcCW.VM_OverDraw then return end
    render.SetBlend(1)
    cam.End3D()
    cam.Start3D(EyePos(), EyeAngles(), self:QuickFOVix(self.CurrentViewModelFOV or self.ViewModelFOV), nil, nil, nil, nil, 0.5, 1000)
    cam.IgnoreZ(true)

    if ArcCW.Overdraw then
        ArcCW.Overdraw = false
    else
        --self:DoLaser()
        self:DoHolosight()
    end

    cam.End3D()
end
