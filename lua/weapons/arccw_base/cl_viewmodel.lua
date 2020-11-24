local mth      = math
local m_sin    = mth.sin
local m_cos    = mth.cos
local m_min    = mth.min
local m_appor  = mth.Approach
local m_clamp  = mth.Clamp
local m_angdif = mth.AngleDifference
local f_lerp   = Lerp
local srf      = surface

SWEP.ActualVMData = false

local coolxang, coolyang, coolyangcomp, coolxangcomp = 0, 0, 0, 0
local eyeangles, lasteyeangles, coolswayang = Angle(), Angle(), Angle()
local swayxmult, swayymult, swayzmult = -0.1, 0.1, -0.3
local coolswaypos, vector_noup = Vector(), Vector(1, 1, 0)

local function ApprVecAng(from, to, dlt)
    local ret = (isangle(from) and isangle(to)) and Angle() or Vector()

    ret[1] = m_appor(from[1], to[1], dlt)
    ret[2] = m_appor(from[2], to[2], dlt)
    ret[3] = m_appor(from[3], to[3], dlt)

    return ret
end

function SWEP:GetViewModelPosition(pos, ang)
    local owner = self:GetOwner()

    if !IsValid(owner) or !owner:Alive() then return end
	
	local proceduralRecoilMult = 1

    local SP = game.SinglePlayer()
    -- local FT = m_min(FrameTime(), RealFrameTime())
    local CT = CurTime()
    local FT = RealFrameTime()

    local FT5, FT10 = FT * 5, FT * 10

    local oldpos, oldang = Vector(), Angle()

    local asight = self:GetActiveSights()
    local state  = self:GetState()

    oldpos:Set(pos)
    oldang:Set(ang)

    ang = ang - (owner:GetViewPunchAngles() * 0.5)

    actual = self.ActualVMData or { pos = Vector(), ang = Angle(), down = 1, sway = 1, bob = 1 }

    local target = {}
    target.pos  = self:GetBuff_Override("Override_ActivePos") or self.ActivePos
    target.ang  = self:GetBuff_Override("Override_ActiveAng") or self.ActiveAng
    target.down = 1
    target.sway = 2
    target.bob  = 2

    local vm_right   = GetConVar("arccw_vm_right"):GetFloat()
    local vm_up      = GetConVar("arccw_vm_up"):GetFloat()
    local vm_forward = GetConVar("arccw_vm_forward"):GetFloat()

    if owner:Crouching() or owner:KeyDown(IN_DUCK) then
        target.down = 0

        if self.CrouchPos then
            target.pos = self.CrouchPos
        end
        if self.CrouchAng then
            target.ang = self.CrouchAng
        end
    end

    if self:InBipod() then
        local BEA = self.BipodAngle - owner:EyeAngles()

        target.pos = target.pos + ((BEA):Right()   * self.InBipodPos.x * self.InBipodMult.x)
        target.pos = target.pos + ((BEA):Forward() * self.InBipodPos.y * self.InBipodMult.y)
        target.pos = target.pos + ((BEA):Up()      * self.InBipodPos.z * self.InBipodMult.z)
        target.sway = 0.2
    end

    target.pos = target.pos + Vector(vm_right, vm_forward, vm_up)

    local sprinted  = self.Sprinted or state == ArcCW.STATE_SPRINT
    local sighted   = self.Sighted or state == ArcCW.STATE_SIGHTS
    local holstered = self:GetCurrentFiremode().Mode == 0

    if SP then
        sprinted = state == ArcCW.STATE_SPRINT
        sighted  = state == ArcCW.STATE_SIGHTS
    end

    if state == ArcCW.STATE_CUSTOMIZE then
        target.pos  = Vector()
        target.ang  = Angle()
        target.down = 1
        target.sway = 3
        target.bob  = 1

        local mx, my = input.GetCursorPos()

        mx = 2 * mx / ScrW()
        my = 2 * my / ScrH()

        target.pos:Set(self.CustomizePos)
        target.ang:Set(self.CustomizeAng)

        target.pos = target.pos + Vector(mx, 0, my)
        target.ang = target.ang + Angle(0, my * 2, mx * 2)

        if self.InAttMenu then target.ang = target.ang + Angle(0, -5, 0) end
    elseif (sprinted and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint)) or holstered then
        target.pos  = Vector()
        target.ang  = Angle()
        target.down = 1
        target.sway = GetConVar("arccw_vm_sway_sprint"):GetInt()
        target.bob  = GetConVar("arccw_vm_bob_sprint"):GetInt()

        target.pos:Set(holstered and (self.HolsterPos or self.SprintPos) or (self.SprintPos or self.HolsterPos))

        target.pos = target.pos + Vector(vm_right, vm_forward, vm_up)

        target.ang:Set(holstered and (self.HolsterAng or self.SprintAng) or (self.SprintAng or self.HolsterAng))

        if ang.p < -15 then target.ang.p = target.ang.p + ang.p + 15 end

        target.ang.p = m_clamp(target.ang.p, -80, 80)
    elseif sighted then
		proceduralRecoilMult = proceduralRecoilMult * .7
	
        local irons = self:GetActiveSights()

        target.pos   = irons.Pos
        target.ang   = irons.Ang
        target.evpos = irons.EVPos or Vector()
        target.evang = irons.EVAng or Angle()
        target.down  = 0
        target.sway  = 0.1
        target.bob   = 0.1

        local sightroll = self:GetBuff_Override("Override_AddSightRoll")

        if sightroll then
            target.ang = Angle()

            target.ang:Set(irons.Ang)
            target.ang.r = sightroll
        end
    end

    local deg = self:BarrelHitWall()

    if deg > 0 then
        target.pos  = LerpVector(deg, target.pos, self.HolsterPos)
        target.ang  = LerpAngle(deg, target.ang, self.HolsterAng)
        target.down = 2
        target.sway = 2
        target.bob  = 2
    end

    if !isangle(target.ang) then target.ang = Angle(target.ang) end

    if self.InProcDraw then
        self.InProcHolster = false

        local delta = m_clamp((CT - self.ProcDrawTime) / (0.25 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)

        targetpos  = LerpVector(delta, Vector(0, -30, -30), target.pos)
        targetang  = LerpAngle(delta, Angle(40, 30, 0), target.ang)
        targetdown = target.down
        targetsway = target.sway
        targetbob  = target.bob

        if delta == 1 then self.InProcDraw = false end
    end

    if self.InProcHolster then
        self.InProcDraw = false

        local delta = 1 - m_clamp((CT - self.ProcHolsterTime) / (0.25 * self:GetBuff_Mult("Mult_DrawTime")), 0, 1)

        target.pos = LerpVector(delta, Vector(0, -30, -30), target.pos)
        target.ang = LerpAngle(delta, Angle(40, 30, 0), target.ang)
        target.down = target.down
        target.sway = target.sway
        target.bob = target.bob

        if delta == 0 then self.InProcHolster = false end
    end

    if self.InProcBash then
        self.InProcDraw = false

        local mult  = self:GetBuff_Mult("Mult_MeleeTime")
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

        if delta == 0 then self.InProcBash = false end
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

    target.pos = target.pos + (VectorRand() * self.RecoilAmount * 0.2)

    local speed = target.speed or 3

    local coolsway = GetConVar("arccw_vm_coolsway"):GetBool()

    lookxmult = GetConVar("arccw_vm_lookxmult"):GetFloat()
    lookymult = GetConVar("arccw_vm_lookymult"):GetFloat()

    accelmult = GetConVar("arccw_vm_accelmult"):GetFloat()

    swayxmult = GetConVar("arccw_vm_swayxmult"):GetFloat()
    swayymult = GetConVar("arccw_vm_swayymult"):GetFloat()
    swayzmult = GetConVar("arccw_vm_swayzmult"):GetFloat()
    swaywiggle = GetConVar("arccw_vm_swaywigglemult"):GetFloat()
    swayspeed 	= GetConVar("arccw_vm_swayspeedmult"):GetFloat()
    swayrotate = GetConVar("arccw_vm_swayrotatemult"):GetFloat()

    if coolsway then
        eyeangles = owner:EyeAngles()

        local sprintmult, sprintnull = (self:InSprint() and 2) or 1, 1
        local airnull = (owner:OnGround() and 1) or 0.1

        local swaymodifier = (target.sway / ((self:InSprint() and target.bob) or 2))
        local vel = m_min((owner:GetVelocity() * vector_noup):Length() * swaymodifier, 600)

        if self:GetState() != ArcCW.STATE_SIGHTS then vel = mth.max(vel, 10) end

        local movespeed = self.SpeedMult * self:GetBuff_Mult("Mult_SpeedMult") * self:GetBuff_Mult("Mult_MoveSpeed")
        movespeed = m_clamp(movespeed, 0.01, 1)

        vel = vel / movespeed

        vel = vel * self.BobMult or 1

        local velmult  = m_min(vel / 600 * (actual.bob / 2), 3) * swaywiggle
        local swaymult = actual.sway / 2 * swayrotate

        local xangdiff = m_angdif(eyeangles.x, lasteyeangles.x)
        local yangdiff = m_angdif(eyeangles.y, lasteyeangles.y) * 0.3

        coolyang = f_lerp(FT10, coolyang, yangdiff)
        coolxang = f_lerp(FT10, coolxang, xangdiff)

        coolyangcomp = f_lerp(10 * FT, coolyangcomp, -coolyang * 5)
        coolxangcomp = f_lerp(50 * FT, coolxangcomp, (self:GetState() == ArcCW.STATE_SIGHTS and 0) or -xangdiff)

        local xang = coolxang * swaymult
        local yang = coolyang * swaymult

        local ctpower = CT * 5 * swayspeed
        local ctsin = m_sin(ctpower * sprintmult)

        local mag = 0.01
        coolswaypos.x = ctsin * swayxmult * (vel * mag) * sprintnull
        coolswaypos.y = ctsin * swayymult * (vel * mag) * sprintnull
        coolswaypos.z = m_sin(ctpower * 2 * sprintmult) * swayzmult * velmult * (vel * mag) * sprintnull * airnull

        coolswayang.x = ((m_cos(ctpower * 0.5) * velmult) + coolxangcomp + xang * lookxmult) * sprintnull
        coolswayang.y = ((m_cos(ctpower * 0.6) * velmult) + yang * lookymult) * sprintnull
        coolswayang.z = (m_sin(ctpower) * velmult) + (yang * 4 + xang * 2 + coolyangcomp) * sprintmult

        target.ang = target.ang - coolswayang
        target.pos = target.pos + coolswaypos
    end

    speed = 1 / self:GetSightTime() * speed * FT

    actual.pos   = LerpVector(speed, actual.pos, target.pos)
    actual.ang   = LerpAngle(speed, actual.ang, target.ang)
    actual.down  = f_lerp(speed, actual.down, target.down)
    actual.sway  = f_lerp(speed, actual.sway, target.sway)
    actual.bob   = f_lerp(speed, actual.bob, target.bob)
    actual.evpos = f_lerp(speed, actual.evpos or Vector(), target.evpos or Vector())
    actual.evang = f_lerp(speed, actual.evang or Angle(), target.evang or Angle())

    actual.pos  = ApprVecAng(actual.pos, target.pos, speed * 0.1)
    actual.ang  = ApprVecAng(actual.ang, target.ang, speed * 0.1)
    actual.down = m_appor(actual.down, target.down, speed * 0.1)

    self.SwayScale = (coolsway and 0) or actual.sway
    self.BobScale  = (coolsway and 0) or actual.bob

    pos = pos + self.RecoilPunchBack * -oldang:Forward() * proceduralRecoilMult
    pos = pos + self.RecoilPunchSide * oldang:Right()
    pos = pos + self.RecoilPunchUp   * -oldang:Up()

    ang:RotateAroundAxis(oldang:Right(),   actual.ang.x)
    ang:RotateAroundAxis(oldang:Up(),      actual.ang.y)
    ang:RotateAroundAxis(oldang:Forward(), actual.ang.z)

    ang:RotateAroundAxis(oldang:Right(),   actual.evang.x)
    ang:RotateAroundAxis(oldang:Up(),      actual.evang.y)
    ang:RotateAroundAxis(oldang:Forward(), actual.evang.z)

    pos = pos + (oldang:Right()   * actual.evpos.x)
    pos = pos + (oldang:Forward() * actual.evpos.y)
    pos = pos + (oldang:Up()      * actual.evpos.z)

    pos = pos + actual.pos.x * ang:Right()
    pos = pos + actual.pos.y * ang:Forward()
    pos = pos + actual.pos.z * ang:Up()

    pos = pos - Vector(0, 0, actual.down)

    if asight and asight.Holosight then ang = ang - (owner:GetViewPunchAngles() * 0.5) end

    self.ActualVMData = actual

    if coolsway then lasteyeangles = LerpAngle(m_min(FT * 100 * accelmult, 1), lasteyeangles, eyeangles) end

    return pos, ang
end

local function ShouldCheapWorldModel(wep)
    local lp = LocalPlayer()

    if lp:GetObserverMode() == OBS_MODE_IN_EYE and lp:GetObserverTarget() == wep:GetOwner() then
        return true
    end

    return !GetConVar("arccw_att_showothers"):GetBool()
end

function SWEP:DrawWorldModel()
    if !IsValid(self:GetOwner()) and !TTT2 and GetConVar("arccw_2d3d"):GetBool() and (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 then -- 512^2
        local ang = LocalPlayer():EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 180)
        ang:RotateAroundAxis(ang:Right(),   90)
        ang:RotateAroundAxis(ang:Up(),      90)

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

    if ShouldCheapWorldModel(self) then
        self:DrawModel()
    else
        self:DrawCustomModel(true)
    end

    self:DoLaser(true)

    if self:ShouldGlint() then self:DoScopeGlint()  end

    if !self.CertainAboutAtts then
        net.Start("arccw_rqwpnnet")
        net.WriteEntity(self)
        net.SendToServer()
    end
end

function SWEP:ShouldCheapScope()
    if !self:GetConVar("arccw_cheapscopes"):GetBool() then return end
end

function SWEP:ShouldFlatScope()
    if self:GetState() != ArcCW.STATE_SIGHTS then return false end

    local irons = self:GetActiveSights()

    if irons.FlatScope or (irons.MagnifiedOptic and GetConVar("arccw_flatscopes"):GetBool()) then
        return true
    end
end

function SWEP:PreDrawViewModel(vm)
    if ArcCW.VM_OverDraw then return end
    if !vm then return end

    if self:ShouldFlatScope() then
        render.SetBlend(0)
    else
        if self:GetState() == ArcCW.STATE_CUSTOMIZE then self:BlurNotWeapon() end

        if GetConVar("arccw_cheapscopesautoconfig"):GetBool() then
            local fps    = 1 / m_min(FrameTime(), RealFrameTime())
            local lowfps = fps <= 45

            GetConVar("arccw_cheapscopes"):SetBool(lowfps and true or false)

            GetConVar("arccw_cheapscopesautoconfig"):SetBool(false)
        end

        local asight = self:GetActiveSights()

        if GetConVar("arccw_cheapscopes"):GetBool() and self:GetSightDelta() < 1 and asight.MagnifiedOptic then
            self:FormCheapScope()
        end

        if self:GetSightDelta() < 1 and asight.ScopeTexture then
            self:FormCheapScope()
        end
    end

    self:DrawCustomModel(false)

    self:DoLHIK()
end

function SWEP:PostDrawViewModel()
    if ArcCW.VM_OverDraw then return end
    render.SetBlend(1)

    if ArcCW.Overdraw then
        ArcCW.Overdraw = false
    else
        self:DoLaser()
        self:DoHolosight()
    end
end