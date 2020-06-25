function SWEP:DoLaser(wm)
    wm = wm or false

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.Laser then
            if wm then
                if !k.WElement then continue end
                cam.Start3D()
                self:DrawLaser(atttbl, k.WElement.Model, atttbl.ColorOptionsTable[k.ColorOptionIndex or 1], true)
                cam.End3D()
            else
                if !k.VElement then continue end
                self:DrawLaser(atttbl, k.VElement.Model, atttbl.ColorOptionsTable[k.ColorOptionIndex or 1])
            end
        end
    end
end

-- hook.Add("PostDrawEffects", "ArcCW_ScopeLaser", function()
--     -- if !ArcCW.LaserBehavior then return end

--     -- local wep = LocalPlayer():GetActiveWeapon()

--     -- if !wep.ArcCW then return end

--     -- wep:DoLaser(false)
-- end)

local lasermat = Material("arccw/laser")
local laserflare = Material("effects/whiteflare")

local delta = 1

function SWEP:DrawLaser(ls, lsm, lsc, wm)
    if !self:GetOwner() then return end
    if !IsValid(self:GetOwner()) then return end

    if !lsm then return end
    if !IsValid(lsm) then return end

    local attid = lsm:LookupAttachment(ls.LaserBone or "laser")

    if attid == 0 then
        attid = lsm:LookupAttachment("muzzle")
    end

    if attid == 0 then return end

    local ret = lsm:GetAttachment(attid)
    local pos = ret.Pos
    local ang = ret.Ang

    local dir = -ang:Right()

    if wm then
        if self:GetOwner():IsNPC() then
            dir = -ang:Right()
        else
            dir = self:GetOwner():EyeAngles():Forward()
        end
    else
        ang:RotateAroundAxis(ang:Up(), 90)

        dir = ang:Forward()

        local eang = self:GetOwner():EyeAngles() + (self:GetOwner():GetViewPunchAngles() * 0.5)

        if self:GetCurrentFiremode().Mode != 0 and !self:GetNWBool("reloading", 0) then
            delta = math.Approach(delta, self:GetSightDelta(), RealFrameTime() * 1 / 0.15)
        else
            delta = math.Approach(delta, 1, RealFrameTime() * 1 / 0.15)
        end

        dir = Lerp(delta, eang:Forward(), dir)
    end

    local dir2 = dir

    if wm then
        dir2 = -ang:Right()
    end

    local tpos = pos

    -- if !wm then
    --     tpos = EyePos()
    -- end

    if ArcCW.LaserBehavior and !wm then
        ang = EyeAngles() - (self:GetOwner():GetViewPunchAngles() * 0.5)

        if GetConVar("arccw_cheapscopes"):GetBool() then
            ang = EyeAngles() - (self:GetOwner():GetViewPunchAngles())
        end

        tpos = EyePos() - Vector(0, 0, 1)
        pos = tpos
        dir = ang:Forward()
        dir2 = dir
    end

    local di = 128

    local tr = util.TraceLine({
        start = tpos,
        endpos = tpos + (dir * 40000),
        filter = self:GetOwner()
    })

    local btr = util.TraceLine({
        start = tpos,
        endpos = tpos + (dir2 * di),
        filter = self:GetOwner()
    })

    local hit = tr.HitPos
    local didhit = tr.Hit
    local m = ls.LaserStrength or 1
    local col = lsc

    if tr.StartSolid then
        hit = tr.StartPos
    end

    hit = hit - (EyeAngles():Forward() * 1.5)

    -- local hte = (hit - EyePos()):Length()
    -- local htl = (pos - EyePos()):Length()

    if tr.StartSolid then return end

    local width = math.Rand(0.05, 0.1) * m

    if !ArcCW.LaserBehavior or wm then
        render.SetMaterial(lasermat)
        render.DrawBeam(pos, btr.HitPos, width, 1, 0, col)
    else
        cam.IgnoreZ(true)
    end

    if didhit then
        local sd = (tr.HitPos - EyePos()):Length()
        local mult = math.log10(sd) * m

        render.SetMaterial(laserflare)
        local r1 = math.Rand(4, 6) * mult
        local r2 = math.Rand(4, 6) * mult

        render.DrawSprite(hit, r1, r2, col)
        render.DrawSprite(hit, r1 * 0.25, r2 * 0.25, Color(255, 255, 255))
    end

    if ArcCW.LaserBehavior and !wm then
        cam.IgnoreZ(false)
    end
end