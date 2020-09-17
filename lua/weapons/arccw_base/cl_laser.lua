local mth        = math
local m_log10    = mth.log10
local m_rand     = mth.Rand
local rnd        = render
local SetMat     = rnd.SetMaterial
local DrawBeam   = rnd.DrawBeam
local DrawSprite = rnd.DrawSprite
local cam        = cam
local IgnoreZ    = cam.IgnoreZ

local lasermat = Material("arccw/laser")
local flaremat = Material("effects/whiteflare")
local delta    = 1

function SWEP:DoLaser(world)
    local toworld = world or false

    if not self:GetNWBool("laserenabled", true) then return end

    for _, k in pairs(self.Attachments) do
        if not k.Installed then continue end

        local attach = ArcCW.AttachmentTable[k.Installed]

        if attach.Laser then
            local color = attach.ColorOptionsTable[k.ColorOptionIndex or 1]

            if toworld then
                if not k.WElement then continue end

                cam.Start3D()
                    self:DrawLaser(attach, k.WElement.Model, color, true)
                cam.End3D()
            else
                if not k.VElement then continue end
                self:DrawLaser(attach, k.VElement.Model, color)
            end
        end
    end
end

function SWEP:DrawLaser(laser, model, color, world)
    local owner = self:GetOwner()
    local behav = ArcCW.LaserBehavior

    if not owner then return end

    if not IsValid(owner) then return end

    if not model then return end

    if not IsValid(model) then return end

    local att = model:LookupAttachment(laser.LaserBone or "laser")

    att = att == 0 and model:LookupAttachment("muzzle") or att

    if att == 0 then return end

    local attdata  = model:GetAttachment(att)
    local pos, ang = attdata.Pos, attdata.Ang
    local dir      = -ang:Right()

    if world then
        dir = owner:IsNPC() and (-ang:Right()) or dir
    else
        ang:RotateAroundAxis(ang:Up(), 90)

        dir = ang:Forward()

        local eyeang   = owner:EyeAngles() + (owner:GetViewPunchAngles() * 0.5)
        local canlaser = self:GetCurrentFiremode().Mode ~= 0 and not self:GetNWBool("reloading", 0) and self:BarrelHitWall() <= 0

        delta = Lerp(0, delta, canlaser and self:GetSightDelta() or 1)

        if self.GuaranteeLaser then delta = 1 end

        dir = Lerp(delta, eyeang:Forward(), dir)
    end

    local beamdir, tracepos = dir, pos

    beamdir = world and (-ang:Right()) or beamdir

    if behav and not world then
        local cheap = GetConVar("arccw_cheapscopes"):GetBool()
        if self:ShouldFlatScope() then
            cheap = true
        end
        local punch = owner:GetViewPunchAngles()

        ang = EyeAngles() - (punch * (cheap and 0.5 or 1))

        tracepos = EyePos() - Vector(0, 0, 1)
        pos, dir = tracepos, ang:Forward()
        beamdir  = dir
    end

    local dist = 128

    local tl = {}
    tl.start  = tracepos
    tl.endpos = tracepos + (dir * 33000)
    tl.filter = owner

    local tr = util.TraceLine(tl)

    tl.endpos = tracepos + (beamdir * dist)

    local btr = util.TraceLine(tl)

    local hit    = tr.Hit
    local hitpos = tr.HitPos
    local solid  = tr.StartSolid

    local strength = laser.LaserStrength or 1
    local laserpos = solid and tr.StartPos or hitpos

    laserpos = laserpos - (EyeAngles():Forward())

    if solid then return end

    local width = m_rand(0.05, 0.1) * strength

    if self:ShouldFlatScope() then
        cam.Start3D()
    end

    if not behav or world then
        if hit then
            SetMat(lasermat)
            DrawBeam(pos, btr.HitPos, width, 1, 0, color)
        end
    else
        IgnoreZ(true)
    end

    if hit and not tr.HitSky then
        local mul = 1 * strength
        -- if !self:ShouldFlatScope() then
            mul = m_log10((hitpos - EyePos()):Length()) * strength
        -- end
        local rad = m_rand(4, 6) * mul
        local glr = rad * m_rand(0.2, 0.3)

        SetMat(flaremat)
        DrawSprite(laserpos, rad, rad, color)
        DrawSprite(laserpos, glr, glr, color_white)
    end

    IgnoreZ(false)

    if self:ShouldFlatScope() then
        cam.End3D()
    end
end