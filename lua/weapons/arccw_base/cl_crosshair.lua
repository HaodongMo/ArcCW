local size = 0
local clump_inner = Material("arccw/hud/clump_inner.png", "mips smooth")
local clump_outer = Material("arccw/hud/clump_outer.png", "mips smooth")
local aimtr_result = {}
local aimtr = {}
local square_mat = Material("color")

function SWEP:ShouldDrawCrosshair()
    if GetConVar("arccw_override_crosshair_off"):GetBool() then return false end
    if !GetConVar("arccw_crosshair"):GetBool() then return false end
    if self:GetReloading() then return false end
    if self:BarrelHitWall() > 0 then return false end
    local asight = self:GetActiveSights()

    if !self:GetOwner():ShouldDrawLocalPlayer()
            and self:GetState() == ArcCW.STATE_SIGHTS and !asight.CrosshairInSights then
        return false
    end

    if self:GetNWState() == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint() then return false end
    if self:GetCurrentFiremode().Mode == 0 then return false end
    if self:GetBuff_Hook("Hook_ShouldNotFire") then return false end
    if self:GetNWState() == ArcCW.STATE_CUSTOMIZE then return false end
    if self:GetNWState() == ArcCW.STATE_DISABLE then return false end
    return true
end

local cr_main = Color( 0, 255, 0 )
local cr_shad = Color( 0, 0, 0, 127 )

local gaA = 0
local gaD = 0

function SWEP:GetFOVAcc( acc, disp )
    cam.Start3D()
        local lool = ( EyePos() + ( EyeAngles():Forward() ) + ( ( ArcCW.MOAToAcc * (acc or self:GetBuff("AccuracyMOA")) ) * EyeAngles():Up() ) ):ToScreen()
        local lool2 = ( EyePos() + ( EyeAngles():Forward() ) + ( ( (disp or self:GetDispersion()) * ArcCW.MOAToAcc / 10 ) * EyeAngles():Up() ) ):ToScreen()
    cam.End3D()

    local gau = 0
    gau = ( (ScrH()/2) - lool.y )
    gaA = math.Approach(gaA, gau, (ScrH()/2)*FrameTime())
    gau = 0
    gau = ( (ScrH()/2) - lool2.y )
    gaD = math.Approach(gaD, gau, (ScrH()/2)*FrameTime())

    return gaA, gaD
end

function SWEP:DoDrawCrosshair(x, y)
    local ply = LocalPlayer()
    local pos = ply:EyePos()
    local ang = ply:EyeAngles() - self:GetOurViewPunchAngles() + self:GetFreeAimOffset()

    if self:GetBuff_Hook("Hook_PreDrawCrosshair") then return end

    local static = GetConVar("arccw_crosshair_static"):GetBool()

    local prong_dot = GetConVar("arccw_crosshair_dot"):GetBool()
    local prong_top = GetConVar("arccw_crosshair_prong_top"):GetBool()
    local prong_left = GetConVar("arccw_crosshair_prong_left"):GetBool()
    local prong_right = GetConVar("arccw_crosshair_prong_right"):GetBool()
    local prong_down = GetConVar("arccw_crosshair_prong_bottom"):GetBool()

    local prong_len = GetConVar("arccw_crosshair_length"):GetFloat()
    local prong_wid = GetConVar("arccw_crosshair_thickness"):GetFloat()
    local prong_out = GetConVar("arccw_crosshair_outline"):GetInt()
    local prong_tilt = GetConVar("arccw_crosshair_tilt"):GetBool()

    local clr = Color(GetConVar("arccw_crosshair_clr_r"):GetInt(),
            GetConVar("arccw_crosshair_clr_g"):GetInt(),
            GetConVar("arccw_crosshair_clr_b"):GetInt())
    if GetConVar("arccw_ttt_rolecrosshair") and GetConVar("arccw_ttt_rolecrosshair"):GetBool() then
        if GetRoundState() == ROUND_PREP or GetRoundState() == ROUND_POST then
            clr = Color(255, 255, 255)
        elseif ply.GetRoleColor and ply:GetRoleColor() then
            clr = ply:GetRoleColor() -- TTT2 feature
        elseif ply:IsActiveTraitor() then
            clr = Color(255, 50, 50)
        elseif ply:IsActiveDetective() then
            clr = Color(50, 50, 255)
        else
            clr = Color(50, 255, 50)
        end
    end
    if GetConVar("arccw_crosshair_aa"):GetBool() and ply.ArcCW_AATarget != nil and GetConVar("arccw_aimassist"):GetBool() and GetConVar("arccw_aimassist_cl"):GetBool() then
            -- whooie
        clr = Color(255, 0, 0)
    end
    clr.a = GetConVar("arccw_crosshair_clr_a"):GetInt()

    local outlineClr = Color(GetConVar("arccw_crosshair_outline_r"):GetInt(),
            GetConVar("arccw_crosshair_outline_g"):GetInt(),
            GetConVar("arccw_crosshair_outline_b"):GetInt(),
            GetConVar("arccw_crosshair_outline_a"):GetInt())

    local gA, gD = self:GetFOVAcc( self:GetBuff("AccuracyMOA"), self:GetDispersion() )
    local gap = (static and 8 or gD) * GetConVar("arccw_crosshair_gap"):GetFloat()

    gap = gap + ( ScreenScale(8) * math.Clamp(self.RecoilAmount, 0, 1) )

    local prong = ScreenScale(prong_len)
    local p_w = ScreenScale(prong_wid)
    local p_w2 = p_w + prong_out

    local sp
    if self:GetOwner():ShouldDrawLocalPlayer() then
        local tr = util.GetPlayerTrace(self:GetOwner())
        local trace = util.TraceLine( tr )

        cam.Start3D()
        local coords = trace.HitPos:ToScreen()
        coords.x = math.Round(coords.x)
        coords.y = math.Round(coords.y)
        cam.End3D()
        sp = { visible = true, x = coords.x, y = coords.y }
    end

    cam.Start3D()
    sp = (pos + (ang:Forward() * 3200)):ToScreen()
    cam.End3D()

    if GetConVar("arccw_crosshair_trueaim"):GetBool() then
        aimtr.start = self:GetShootSrc()
    else
        aimtr.start = pos
    end

    aimtr.endpos = aimtr.start + ((ply:EyeAngles() + self:GetFreeAimOffset()):Forward() * 100000)
    aimtr.filter = {ply}
    aimtr.output = aimtr_result

    table.Add(aimtr.filter, ArcCW:GetVehicleFilter(ply) or {})

    util.TraceLine(aimtr)

    cam.Start3D()
    local w2s = aimtr_result.HitPos:ToScreen()
    w2s.x = math.Round(w2s.x)
    w2s.y = math.Round(w2s.y)
    cam.End3D()

    sp.x = w2s.x sp.y = w2s.y
    x, y = sp.x, sp.y

    local st = self:GetSightTime() / 2

    if self:ShouldDrawCrosshair() then
        self.CrosshairDelta = math.Approach(self.CrosshairDelta or 0, 1, FrameTime() * 1 / st)
    else
        self.CrosshairDelta = math.Approach(self.CrosshairDelta or 0, 0, FrameTime() * 1 / st)
    end

    if GetConVar("arccw_crosshair_equip"):GetBool() and (self:GetBuff("ShootEntity", true) or self.PrimaryBash) then
        prong = ScreenScale(prong_wid)
        p_w = ScreenScale(prong_wid)
        p_w2 = p_w + prong_out
    end

    if prong_dot then
        surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * self.CrosshairDelta)
        surface.DrawRect(x - p_w2 / 2, y - p_w2 / 2, p_w2, p_w2)

        surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * self.CrosshairDelta)
        surface.DrawRect(x - p_w / 2, y - p_w / 2, p_w, p_w)
    end


    size = math.Approach(size, gap, FrameTime() * 32 * gap)
    gap = size
    if !static then gap = gap * self.CrosshairDelta end
    gap = math.max(4, gap)

    local num = self:GetBuff("Num")
    if GetConVar("arccw_crosshair_shotgun"):GetBool() and num > 1 then
        prong = ScreenScale(prong_wid)
        p_w = ScreenScale(prong_len)
        p_w2 = p_w + prong_out
    end

    local prong2 = prong + prong_out
    if prong_tilt then
        local angle = (prong_left and prong_top and prong_right and prong_down) and 45 or 30
        local rad = math.rad(angle)
        local dx = gap * math.cos(rad) + prong * math.cos(rad) / 2
        local dy = gap * math.sin(rad) + prong * math.sin(rad) / 2
        surface.SetMaterial(square_mat)
        -- Shade
        surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * self.CrosshairDelta)
        if prong_left and prong_top then
            surface.DrawTexturedRectRotated(x - dx, y - dy, prong2, p_w2, -angle)
            surface.DrawTexturedRectRotated(x + dx, y - dy, prong2, p_w2, angle)
        elseif prong_left or prong_top then
            surface.DrawRect(x - p_w2 / 2, y - gap - prong2 + prong_out / 2, p_w2, prong2)
        end
        if prong_right and prong_down then
            surface.DrawTexturedRectRotated(x + dx, y + dy, prong2, p_w2, -angle)
            surface.DrawTexturedRectRotated(x - dx, y + dy, prong2, p_w2, angle)
        elseif prong_right or prong_down then
            surface.DrawRect(x - p_w2 / 2, y + gap - prong_out / 2, p_w2, prong2)
        end
        -- Fill
        surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * self.CrosshairDelta)
        if prong_left and prong_top then
            surface.DrawTexturedRectRotated(x - dx, y - dy, prong, p_w, -angle)
            surface.DrawTexturedRectRotated(x + dx, y - dy, prong, p_w, angle)
        elseif prong_left or prong_top then
            surface.DrawRect(x - p_w / 2, y - gap - prong, p_w, prong)
        end
        if prong_right and prong_down then
            surface.DrawTexturedRectRotated(x + dx, y + dy, prong, p_w, -angle)
            surface.DrawTexturedRectRotated(x - dx, y + dy, prong, p_w, angle)
        elseif prong_right or prong_down then
            surface.DrawRect(x - p_w / 2, y + gap, p_w, prong)
        end
    else
        -- Shade
        surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * self.CrosshairDelta)
        if prong_left then
            surface.DrawRect(x - gap - prong2 + prong_out / 2, y - p_w2 / 2, prong2, p_w2)
        end
        if prong_right then
            surface.DrawRect(x + gap - prong_out / 2, y - p_w2 / 2, prong2, p_w2)
        end
        if prong_top then
            surface.DrawRect(x - p_w2 / 2, y - gap - prong2 + prong_out / 2, p_w2, prong2)
        end
        if prong_down then
            surface.DrawRect(x - p_w2 / 2, y + gap - prong_out / 2, p_w2, prong2)
        end
        -- Fill
        surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * self.CrosshairDelta)
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
    end

    if GetConVar("arccw_crosshair_clump"):GetBool() and (GetConVar("arccw_crosshair_clump_always"):GetBool() or num > 1) then
        local acc = math.max(1, gA)
        if GetConVar("arccw_crosshair_clump_outline"):GetBool() then
            surface.SetMaterial(clump_outer)

            for i=1, prong_out do
                surface.DrawCircle(x-1, y-0, acc + math.ceil(i*0.5) * (i % 2 == 1 and 1 or -1), outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * self.CrosshairDelta)
            end
            surface.DrawCircle(x-1, y-0, acc, outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * self.CrosshairDelta)
        end

        surface.DrawCircle(x-1, y-0, acc, clr.r, clr.g, clr.b, clr.a * self.CrosshairDelta)
    end

    self:GetBuff_Hook("Hook_PostDrawCrosshair", w2s)

    return true
end