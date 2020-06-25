local delta = 0
local size = 0
local cw = nil

function SWEP:ShouldDrawCrosshair()
    if !GetConVar("arccw_override_crosshair_off") then return false end
    if !GetConVar("arccw_crosshair"):GetBool() then return false end
    if self:GetNWBool("reloading") then return false end
    local asight = self:GetActiveSights()
    if self:GetState() == ArcCW.STATE_SIGHTS and !asight.CrosshairInSights then return false end
    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return false end
    if self:GetCurrentFiremode().Mode == 0 then return false end
    if self:GetBuff_Hook("Hook_ShouldNotFire") then return false end

    return true
end

function SWEP:DoDrawCrosshair(x, y)
    local pos = EyePos()
    local ang = EyeAngles() - LocalPlayer():GetViewPunchAngles()
    local dot = true
    local prong_top = true
    local prong_left = true
    local prong_right = true
    local prong_down = true

    local gap = ScreenScale(24) * math.Clamp(self:GetDispersion() / 1000, 0.1, 100)

    gap = gap + ScreenScale(8) * math.Clamp(self.RecoilAmount, 0, 1)

    local prong = ScreenScale(4)

    cw = cw or self

    cam.Start3D()
    local sp = (pos + (ang:Forward() * 3200)):ToScreen()
    cam.End3D()

    x, y = sp.x, sp.y

    local st = self:GetSightTime() / 4

    if self:ShouldDrawCrosshair() then
        delta = math.Approach(delta, 1, RealFrameTime() * 1 / st)
    else
        delta = math.Approach(delta, 0, RealFrameTime() * 1 / st)
    end

    local p_w = ScreenScale(1)
    local p_w2 = p_w + 2

    if self:GetBuff_Override("Override_ShootEntity") or self.ShootEntity then
        gap = gap * 1.5
        prong = ScreenScale(1)
        p_w = ScreenScale(1)
        p_w2 = p_w + 2
    end

    if self.PrimaryBash then
        dot = false
        gap = gap * 2
        prong = ScreenScale(1)
        p_w = ScreenScale(1)
        p_w2 = p_w + 2
    end

    if dot then

        surface.SetDrawColor(0, 0, 0, 150 * delta)
        surface.DrawRect(x - p_w2 / 2, y - p_w2 / 2, p_w2, p_w2)

        surface.SetDrawColor(255, 255, 255, 255 * delta)
        surface.DrawRect(x - p_w / 2, y - p_w / 2, p_w, p_w)

    end

    local num = (self:GetBuff_Override("Override_Num") or self.Num) + self:GetBuff_Add("Add_Num")

    size = math.Approach(size, gap, RealFrameTime() * 32 * gap)

    if cw != self then
        delta = 0
        size = gap
    end

    cw = self

    gap = size

    if num > 1 then
        dot = false
        gap = gap * 2.5
        prong = ScreenScale(1)
        p_w = ScreenScale(10)
        p_w2 = p_w + 2
    end

    local prong2 = prong + 2

    surface.SetDrawColor(0, 0, 0, 150 * delta)

    if prong_left then
        surface.DrawRect(x - gap - prong2 + 1, y - p_w2 / 2, prong2, p_w2)
    end

    if prong_right then
        surface.DrawRect(x + gap - 1, y - p_w2 / 2, prong2, p_w2)
    end

    if prong_top then
    surface.DrawRect(x - p_w2 / 2, y - gap - prong2 + 1, p_w2, prong2)
    end

    if prong_down then
        surface.DrawRect(x - p_w2 / 2, y + gap - 1, p_w2, prong2)
    end

    surface.SetDrawColor(255, 255, 255, 255 * delta)

    if prong_left then
        surface.DrawRect(x - gap - prong, y - p_w / 2, prong, p_w)
    end

    if prong_right then
        surface.DrawRect(x + gap, y - p_w / 2, prong, p_w)
    end

    if prong_top then
    surface.DrawRect(x - p_w / 2, y - gap - prong, p_w, prong)
    end

    if prong_down then
        surface.DrawRect(x - p_w / 2, y + gap, p_w, prong)
    end

    return true
end
