function SWEP:AdjustMouseSensitivity()
    if self:GetState() != ArcCW.STATE_SIGHTS then return end

    local irons = self:GetActiveSights()

    return 1 / (irons.Magnification + (irons.ScopeMagnification or 0))
end

function SWEP:Scroll(var)
    local irons = self:GetActiveSights()

    if irons.ScrollFunc == ArcCW.SCROLL_ZOOM then
        if !irons.ScopeMagnificationMin then return end
        if !irons.ScopeMagnificationMax then return end

        local old = irons.ScopeMagnification

        local minus = var < 0

        var = math.abs(irons.ScopeMagnificationMax - irons.ScopeMagnificationMin)

        var = var / (irons.ZoomLevels or 5)

        if minus then
            var = var * -1
        end

        irons.ScopeMagnification = irons.ScopeMagnification - var

        irons.ScopeMagnification = math.Clamp(irons.ScopeMagnification, irons.ScopeMagnificationMin, irons.ScopeMagnificationMax)

        self.SightMagnifications[irons.Slot or 0] = irons.ScopeMagnification

        if old != irons.ScopeMagnification then
            self:EmitSound(irons.ZoomSound or "", 75, math.Rand(95, 105), 1, CHAN_ITEM)
        end

        -- if !irons.MinZoom then return end
        -- if !irons.MaxZoom then return end

        -- local old = irons.Magnification

        -- irons.Magnification = irons.Magnification - var

        -- irons.Magnification = math.Clamp(irons.Magnification, irons.MinZoom, irons.MaxZoom)

        -- if old != irons.Magnification then
        --     self:EmitSound(irons.ZoomSound or "", 75, 100, 1, CHAN_ITEM)
        -- end
    end

end

-- viewbob during reload and firing shake
SWEP.ProceduralViewOffset = Angle(0, 0, 0)
local procedural_spdlimit = 5
local oldangtmp
local mzang_fixed,mzang_fixed_last
local mzang_velocity = Angle()
local progress = 0
local targint,targbool
function SWEP:CalcView(ply, pos, ang, fov)
    if !CLIENT then return end
    if !ang then return end
    if ply != LocalPlayer() then return end
    if ply:ShouldDrawLocalPlayer() then return end
    local vm = ply:GetViewModel()
    if !IsValid(vm) then return end
    if !GetConVar("arccw_vm_coolview"):GetBool() then return end
    local ftv = math.max(FrameTime(), 0.001)
    local viewbobintensity = 0.2

    oldpostmp = pos * 1
    oldangtmp = ang * 1

    targbool = self:GetNextPrimaryFire() - .1 > CurTime()
    targint = targbool and 1 or 0
    targint = math.min(targint, 1-math.pow( vm:GetCycle(), 2 ) )
    progress = Lerp(ftv * 15, progress, targint)

    local angpos = vm:GetAttachment(self.ProceduralViewBobAttachment or self.MuzzleEffectAttachment or 1)

    if angpos then
        mzang_fixed = vm:WorldToLocalAngles(angpos.Ang)
        mzang_fixed:Normalize()
    else return
    end

    self.ProceduralViewOffset:Normalize()

    if mzang_fixed_last then
        local delta = mzang_fixed - mzang_fixed_last
        delta:Normalize()
        mzang_velocity = mzang_velocity + delta * 2
        mzang_velocity.p = math.Approach(mzang_velocity.p, -self.ProceduralViewOffset.p * 2, ftv * 20)
        mzang_velocity.p = math.Clamp(mzang_velocity.p, -procedural_spdlimit, procedural_spdlimit)
        self.ProceduralViewOffset.p = self.ProceduralViewOffset.p + mzang_velocity.p * ftv
        self.ProceduralViewOffset.p = math.Clamp(self.ProceduralViewOffset.p, -90, 90)
        mzang_velocity.y = math.Approach(mzang_velocity.y, -self.ProceduralViewOffset.y * 2, ftv * 20)
        mzang_velocity.y = math.Clamp(mzang_velocity.y, -procedural_spdlimit, procedural_spdlimit)
        self.ProceduralViewOffset.y = self.ProceduralViewOffset.y + mzang_velocity.y * ftv
        self.ProceduralViewOffset.y = math.Clamp(self.ProceduralViewOffset.y, -90, 90)
        mzang_velocity.r = math.Approach(mzang_velocity.r, -self.ProceduralViewOffset.r * 2, ftv * 20)
        mzang_velocity.r = math.Clamp(mzang_velocity.r, -procedural_spdlimit, procedural_spdlimit)
        self.ProceduralViewOffset.r = self.ProceduralViewOffset.r + mzang_velocity.r * ftv
        self.ProceduralViewOffset.r = math.Clamp(self.ProceduralViewOffset.r, -90, 90)
    end

    self.ProceduralViewOffset.p = math.Approach(self.ProceduralViewOffset.p, 0, (1 - progress) * ftv * -self.ProceduralViewOffset.p)
    self.ProceduralViewOffset.y = math.Approach(self.ProceduralViewOffset.y, 0, (1 - progress) * ftv * -self.ProceduralViewOffset.y)
    self.ProceduralViewOffset.r = math.Approach(self.ProceduralViewOffset.r, 0, (1 - progress) * ftv * -self.ProceduralViewOffset.r)
    mzang_fixed_last = mzang_fixed
    local ints = 3 * -viewbobintensity
    ang:RotateAroundAxis(ang:Right(), Lerp(progress, 0, -self.ProceduralViewOffset.p) * ints)
    ang:RotateAroundAxis(ang:Up(), Lerp(progress, 0, self.ProceduralViewOffset.y / 2) * ints)
    ang:RotateAroundAxis(ang:Forward(), Lerp(progress, 0, self.ProceduralViewOffset.r / 3) * ints)

    return pos, LerpAngle(0, ang, oldangtmp) + (AngleRand() * self.RecoilAmount * 0.008), fov
end

function SWEP:ShouldGlint()
    return self:GetBuff_Override("ScopeGlint") and self:GetNWBool("state") == ArcCW.STATE_SIGHTS
end

function SWEP:DoScopeGlint()
end