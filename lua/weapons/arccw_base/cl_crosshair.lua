local delta = 0
local size = 0
local cw = nil
local clump_inner = Material("hud/clump_inner.png", "mips smooth")
local clump_outer = Material("hud/clump_outer.png", "mips smooth")
local aimtr_result = {}
local aimtr = {}


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

    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return false end
    if self:GetCurrentFiremode().Mode == 0 then return false end
    if self:GetBuff_Hook("Hook_ShouldNotFire") then return false end
    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return false end

    return true
end


function SWEP:DoDrawCrosshair(x, y)
    local ply = LocalPlayer()
    local pos = ply:EyePos()
    local ang = ply:EyeAngles() - self:GetOurViewPunchAngles()
    local dot = true
    local prong_top = true
    local prong_left = true
    local prong_right = true
    local prong_down = true

    local prong_len = GetConVar("arccw_crosshair_length"):GetFloat()
    local prong_wid = GetConVar("arccw_crosshair_thickness"):GetFloat()
    local prong_out = GetConVar("arccw_crosshair_outline"):GetInt()

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

    local gap = ScreenScale(24)
            * (GetConVar("arccw_crosshair_static"):GetBool() and 0.25 or math.Clamp(self:GetDispersion() / 1000, 0.1, 100))
            * GetConVar("arccw_crosshair_gap"):GetFloat()
    gap = gap + ScreenScale(8) * math.Clamp(self.RecoilAmount, 0, 1)

    local prong = ScreenScale(prong_len)
    local p_w = ScreenScale(prong_wid)
    local p_w2 = p_w + prong_out

    cw = cw or self

    local sp
    if self:GetOwner():ShouldDrawLocalPlayer() then
        local tr = util.GetPlayerTrace( self:GetOwner() )
        local trace = util.TraceLine( tr )

        cam.Start3D()
        local coords = trace.HitPos:ToScreen()
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

    aimtr.endpos = aimtr.start + (ply:GetAimVector() * 100000)
    aimtr.filter = {self:GetOwner()}
    aimtr.output = aimtr_result

    local veh = self:GetOwner():GetVehicle()

    if veh:IsValid() then
        local va = veh:GetAngles()
        -- va.p = -va.p * 2
        aimtr.endpos = aimtr.start + (ply:EyeAngles() + va):Forward() * 100000
        table.Add(aimtr.filter, {veh})
    end

    util.TraceLine(aimtr)

    cam.Start3D()
    local w2s = aimtr_result.HitPos:ToScreen()
    cam.End3D()

    sp.x = w2s.x sp.y = w2s.y
    x, y = sp.x, sp.y

    local st = self:GetSightTime() / 4

    if self:ShouldDrawCrosshair() then
        delta = math.Approach(delta, 1, FrameTime() * 1 / st)
    else
        delta = math.Approach(delta, 0, FrameTime() * 1 / st)
    end

    if GetConVar("arccw_crosshair_equip"):GetBool() and self:GetBuff("ShootEntity", true) then
        gap = gap * 1.5
        prong = ScreenScale(prong_wid)
        p_w = ScreenScale(prong_wid)
        p_w2 = p_w + prong_out
    end

    if GetConVar("arccw_crosshair_equip"):GetBool() and self.PrimaryBash then
        dot = false
        gap = gap * 2
        prong = ScreenScale(prong_wid)
        p_w = ScreenScale(prong_wid)
        p_w2 = p_w + prong_out
    end

    if GetConVar("arccw_crosshair_dot"):GetBool() and dot then

        surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * delta)
        surface.DrawRect(x - p_w2 / 2, y - p_w2 / 2, p_w2, p_w2)

        surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * delta)
        surface.DrawRect(x - p_w / 2, y - p_w / 2, p_w, p_w)

    end

    local num = (self:GetBuff_Override("Override_Num") or self.Num) + self:GetBuff_Add("Add_Num")

    size = math.Approach(size, gap, FrameTime() * 32 * gap)

    if cw != self then
        delta = 0
        size = gap
    end

    cw = self

    gap = size

    if GetConVar("arccw_crosshair_shotgun"):GetBool() and num > 1 then
        dot = false
        gap = gap * 2.5
        prong = ScreenScale(prong_wid)
        p_w = ScreenScale(prong_len)
        p_w2 = p_w + prong_out
    end

    local prong2 = prong + prong_out

    surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * delta)

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

    surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * delta)

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

    if GetConVar("arccw_crosshair_clump"):GetBool() and (GetConVar("arccw_crosshair_clump_always"):GetBool() or num > 1) then
        local spread = ArcCW.MOAToAcc * self:GetBuff("AccuracyMOA")
        local clumpSize = math.Clamp(2048 * spread, 8, 1024)

        if GetConVar("arccw_crosshair_clump_outline"):GetBool() then
            surface.SetDrawColor(outlineClr.r, outlineClr.g, outlineClr.b, outlineClr.a * delta)
            surface.SetMaterial(clump_outer)
            surface.DrawTexturedRect(x - clumpSize / 2, y - clumpSize / 2, clumpSize, clumpSize)
        end

        surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a * delta)
        surface.SetMaterial(clump_inner)
        surface.DrawTexturedRect(x - clumpSize / 2, y - clumpSize / 2, clumpSize, clumpSize)
    end


    return true
end
