function SWEP:DoHolosight()

    -- In VRMod, we draw all holosights all the time
    if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
        for i, asight in pairs(self.SightTable) do
            local aslot = self.Attachments[asight.Slot] or {}
            local atttbl = asight.HolosightData

            if !atttbl and aslot.Installed then
                atttbl = ArcCW.AttachmentTable[aslot.Installed]

                if !atttbl.Holosight then return end
            end

            if atttbl then
                local hsp = asight.HolosightPiece or self.HSPElement
                local hsm = asight.HolosightModel

                if !hsp and !hsm then
                    self:SetupActiveSights()
                    return
                end

                self:DrawHolosight(atttbl, hsm, hsp, asight)
            end
        end

        return
    end

    local asight = self:GetActiveSights()
    if !asight then return end
    local aslot = self.Attachments[asight.Slot] or {}

    local atttbl = asight.HolosightData

    if !atttbl and aslot.Installed then
        atttbl = ArcCW.AttachmentTable[aslot.Installed]

        if !atttbl.Holosight then return end
    end

    if atttbl then
        local hsp = asight.HolosightPiece or self.HSPElement
        local hsm = asight.HolosightModel

        if !hsp and !hsm then
            self:SetupActiveSights()
            return
        end

        self:DrawHolosight(atttbl, hsm, hsp)
    end
end

local rtsize = ScrH()

local rtmat = GetRenderTarget("arccw_rtmat", rtsize, rtsize, false)
local rtmat_cheap = GetRenderTarget("arccw_rtmat_cheap", ScrW(), ScrH(), false)
local rtmat_spare = GetRenderTarget("arccw_rtmat_spare", ScrW(), ScrH(), false)

-- local shadow = Material("hud/scopes/shadow.png")

local thermal = Material("models/debug/debugwhite")
local colormod = Material("pp/colour")
-- local warp = Material("models/props_c17/fisheyelens2")
local coldtime = 30

-- shamelessly robbed from Jackarunda
local function IsWHOT(ent)
    if !ent:IsValid() then return false end
    if (ent:IsWorld()) then return false end
    if (ent.Health and (ent:Health() <= 0)) then return false end
    if ((ent:IsPlayer()) or (ent:IsOnFire())) then return true end
    if ent:IsNextBot() then return true end
    if (ent:IsNPC()) then
        if ent.ArcCWCLHealth and ent.ArcCWCLHealth <= 0 then return false end
        if (ent.Health and (ent:Health() > 0)) then return true end
    elseif (ent:IsRagdoll()) then
        local Time = CurTime()
        if !ent.ArcCW_ColdTime then ent.ArcCW_ColdTime = Time + coldtime end
        return ent.ArcCW_ColdTime > Time
    elseif (ent:IsVehicle()) then
        return ent:GetVelocity():Length() >= 100
    end
    return false
end

function SWEP:FormThermalImaging(tex)
    if !tex then
        tex = render.GetRenderTarget()
    end

    render.PushRenderTarget(tex)

    cam.Start3D()

    if tex then
        colormod:SetTexture("$fbtexture", tex)
    else
        colormod:SetTexture("$fbtexture", render.GetScreenEffectTexture())
    end

    local asight = self:GetActiveSights()

    local nvsc = asight.ThermalScopeColor or Color(255, 255, 255)
    local tvsc = asight.ThermalHighlightColor or Color(255, 255, 255)

    local tab = ents.GetAll()

    -- table.Add(tab, player.GetAll())
    -- table.Add(tab, ents.FindByClass("npc_*"))

    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.ClearStencil()

    local sw = ScrH()
    local sh = sw

    local sx = (ScrW() - sw) / 2
    local sy = (ScrH() - sh) / 2

    render.SetScissorRect( sx, sy, sx + sw, sy + sh, true )

    render.SetStencilReferenceValue(64)

    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)

    for _, v in pairs(tab) do

        if !IsWHOT(v) then continue end

        local Br = 0.9
        if v.ArcCW_ColdTime then
            Br = (0.75 * v.ArcCW_ColdTime - CurTime()) / coldtime
        end

        if v:IsVehicle() then
            Br = math.Clamp(v:GetVelocity():Length() / 400, 0, 1)
        end

        if Br > 0 then

            if !asight.ThermalScopeSimple then
                render.SetBlend(0.5)
                render.SuppressEngineLighting(true)

                Br = Br * 250

                -- render.MaterialOverride(thermal)

                render.SetColorModulation(Br, Br, Br)
            end

            v:DrawModel()

        end
    end

    render.SetColorModulation(1, 1, 1)

    render.SuppressEngineLighting(false)

    render.MaterialOverride()

    render.SetBlend(1)

    render.SetStencilCompareFunction(STENCIL_EQUAL)

    if asight.ThermalScopeSimple then
        surface.SetDrawColor(Color(255, 255, 255))
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    DrawColorModify({
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 0,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    DrawColorModify({
        ["$pp_colour_addr"] = tvsc.r - 255,
        ["$pp_colour_addg"] = tvsc.g - 255,
        ["$pp_colour_addb"] = tvsc.b - 255,
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    if !asight.ThermalNoCC then
        render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
        render.SetStencilPassOperation(STENCIL_KEEP)

        if !asight.ThermalFullColor then
            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 0,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        end

        DrawColorModify({
            ["$pp_colour_addr"] = nvsc.r - 255,
            ["$pp_colour_addg"] = nvsc.g - 255,
            ["$pp_colour_addb"] = nvsc.b - 255,
            -- ["$pp_colour_addr"] = 0,
            -- ["$pp_colour_addg"] = 0,
            -- ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = asight.Brightness or 0.1,
            ["$pp_colour_contrast"] = asight.Contrast or 0.5,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end

    render.SetScissorRect( sx, sy, sx + sw, sy + sh, false )

    render.SetStencilEnable(false)

    colormod:SetTexture("$fbtexture", render.GetScreenEffectTexture())

    cam.End3D()

    render.PopRenderTarget()
end

function SWEP:FormNightVision(tex)
    local asight = self:GetActiveSights()

    local orig = colormod:GetTexture("$fbtexture")

    colormod:SetTexture("$fbtexture", tex)

    render.PushRenderTarget(tex)

    local nvsc = asight.NVScopeColor or Color(0, 255, 0)

    if !asight.NVFullColor then
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 0,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end

    DrawColorModify({
        ["$pp_colour_addr"] = nvsc.r - 255,
        ["$pp_colour_addg"] = nvsc.g - 255,
        ["$pp_colour_addb"] = nvsc.b - 255,
        ["$pp_colour_brightness"] = asight.Brightness or -0.05,
        ["$pp_colour_contrast"] = asight.Contrast or 4,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    render.PopRenderTarget()

    colormod:SetTexture("$fbtexture", orig)
end

function SWEP:FormCheapScope()
    local screen = render.GetRenderTarget()

    render.CopyTexture( screen, rtmat_spare )

    render.PushRenderTarget(screen)
        cam.Start3D(EyePos(), EyeAngles(), nil, nil, nil, nil, nil, 0, nil)
        ArcCW.LaserBehavior = true
        self:DoLaser(false)
        ArcCW.LaserBehavior = false
        cam.End3D()
    render.PopRenderTarget()

    -- so, in order to avoid the fact that copying RTs doesn't transfer depth buffer data, we just take the screen texture and...
    -- redraw it to cover up the thermal scope stuff. Don't think too hard about this. You have plenty of VRAM.

    local asight = self:GetActiveSights()

    if asight.Thermal then
        self:FormThermalImaging(screen)
    end

    if asight.SpecialScopeFunction then
        asight.SpecialScopeFunction(screen)
    end

    render.CopyTexture( screen, rtmat_cheap )

    render.DrawTextureToScreen(rtmat_spare)

    render.UpdateFullScreenDepthTexture()
end

function SWEP:FormRTScope()
    local asight = self:GetActiveSights()

    if !asight then return end

    if !asight.MagnifiedOptic then return end

    local mag = asight.ScopeMagnification

    cam.Start3D()

    ArcCW.Overdraw = true
    ArcCW.LaserBehavior = true

    local rt = {
        w = rtsize,
        h = rtsize,
        angles = LocalPlayer():EyeAngles() + (self:GetOwner():GetViewPunchAngles() * 0.5),
        origin = LocalPlayer():EyePos(),
        drawviewmodel = false,
        fov = self:GetOwner():GetFOV() / mag / 1.2,
    }

    rtsize = ScrH()

    if ScrH() > ScrW() then rtsize = ScrW() end

    rtmat = GetRenderTarget("arccw_rtmat", rtsize, rtsize, false)

    render.PushRenderTarget(rtmat, 0, 0, rtsize, rtsize)

    render.ClearRenderTarget(rt, Color(0, 0, 0))

    if self:GetSightDelta() < 1 then
        render.RenderView(rt)
        cam.Start3D(EyePos(), EyeAngles(), rt.fov, 0, 0, nil, nil, 0, nil)
            self:DoLaser(false)
        cam.End3D()
    end

    ArcCW.Overdraw = false
    ArcCW.LaserBehavior = false

    render.PopRenderTarget()

    cam.End3D()

    if asight.Thermal then
        self:FormThermalImaging(rtmat)
    end

    if asight.SpecialScopeFunction then
        asight.SpecialScopeFunction(rtmat)
    end
end

hook.Add("RenderScene", "ArcCW", function()
    if GetConVar("arccw_cheapscopes"):GetBool() then return end

    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn.ArcCW then return end

    wpn:FormRTScope()
end)

local black = Material("hud/black.png")
local defaultdot = Material("hud/scopes/dot.png")

function SWEP:DrawHolosight(hs, hsm, hsp, asight)
    -- holosight structure
    -- holosight model

    asight = asight or self:GetActiveSights()
    local delta = self:GetSightDelta()

    if asight.HolosightData then
        hs = asight.HolosightData
    end

    if delta == 1 then return end

    if !hs then return end

    local hsc = Color(255, 255, 255)

    if hs.Colorable then
        hsc.r = GetConVar("arccw_scope_r"):GetInt()
        hsc.g = GetConVar("arccw_scope_g"):GetInt()
        hsc.b = GetConVar("arccw_scope_b"):GetInt()
    else
        hsc = hs.HolosightColor or hsc
    end

    local attid = 0

    if hsm then

        attid = hsm:LookupAttachment(asight.HolosightBone or hs.HolosightBone or "holosight")

        if attid == 0 then
            attid = hsm:LookupAttachment("holosight")
        end

    end

    local ret, pos, ang

    if attid != 0 then

        ret = hsm:GetAttachment(attid)
        pos = ret.Pos
        ang = ret.Ang

    else

        pos = EyePos()
        ang = EyeAngles()

    end

    local size = hs.HolosightSize or 1

    if self:ShouldFlatScope() then
        render.UpdateScreenEffectTexture()
        local screen = render.GetScreenEffectTexture()

        if asight.NVScope then
            self:FormNightVision(screen)
        end

        if asight.Thermal then
            self:FormThermalImaging(screen)
        end

        if asight.SpecialScopeFunction then
            asight.SpecialScopeFunction(screen)
        end

        render.DrawTextureToScreen(screen)

        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_REPLACE)
        render.SetStencilWriteMask(255)
        render.SetStencilTestMask(255)

        render.SetStencilReferenceValue(55)

        local spos = EyePos() + ((EyeAngles() + (Angle(0.1, 0, 0) * delta) + (self:GetOwner():GetViewPunchAngles() * 0.25)):Forward() * 2048)

        cam.IgnoreZ(true)

        render.SetMaterial(hs.HolosightReticle or defaultdot)
        render.DrawSprite(spos, 3 * (1 - delta), 3 * (1 - delta), hsc or Color(255, 255, 255))

        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

        render.SetMaterial(black)
        render.DrawScreenQuad()

        render.SetStencilEnable(false)
        cam.IgnoreZ(false)
        return
    end

    local hsmag = asight.ScopeMagnification or 1

    -- if asight.NightVision then

    if hsmag and hsmag > 1 and delta < 1 and asight.NVScope then
        local screen = rtmat

        if GetConVar("arccw_cheapscopes"):GetBool() then
            screen = rtmat_cheap
        end

        if asight.NVScope then
            self:FormNightVision(screen)
        end
    end

    render.UpdateScreenEffectTexture()
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)

    render.SetBlend(0)

        render.SetStencilReferenceValue(55)

        ArcCW.Overdraw = true

        render.OverrideDepthEnable( true, true )

        if !hsm then
            hsp:DrawModel()
        else

            if !hsp or hs.HolosightNoHSP then
                hsm:DrawModel()
            end

            render.MaterialOverride()

            render.SetStencilReferenceValue(0)

            hsm:SetBodygroup(1, 1)
            -- hsm:SetSubMaterial(0, "dev/no_pixel_write")
            hsm:DrawModel()
            -- hsm:SetSubMaterial()
            hsm:SetBodygroup(1, 0)

            -- local vm = self:GetOwner():GetViewModel()

            -- ArcCW.Overdraw = true
            -- vm:DrawModel()

            -- ArcCW.Overdraw = false

            render.SetStencilReferenceValue(55)

            if hsp then
                hsp:DrawModel()
            end
        end

        render.MaterialOverride()

        render.OverrideDepthEnable( false, true )

        ArcCW.Overdraw = false

    render.SetBlend(1)

    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilCompareFunction(STENCIL_EQUAL)

    -- local pos = EyePos()
    -- local ang = EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), -90)

    ang = ang + (self:GetOwner():GetViewPunchAngles() * 0.25)

    local dir = ang:Up()

    local pdiff = (pos - EyePos()):Length()

    pos = LerpVector(delta, EyePos(), pos)

    local eyeangs = self:GetOwner():EyeAngles() - (self:GetOwner():GetViewPunchAngles() * 0.25)

    -- local vm = hsm or hsp

    -- eyeangs = eyeangs + (eyeangs - vm:GetAngles())

    dir = LerpVector(delta, eyeangs:Forward(), dir:GetNormalized())

    pdiff = Lerp(delta, pdiff, 0)

    local d = (8 + pdiff)

    d = hs.HolosightConstDist or d

    local vmscale = (self.Attachments[asight.Slot] or {}).VMScale or Vector(1, 1, 1)

    if hs.HolosightConstDist then
        vmscale = Vector(1, 1, 1)
    end

    local hsx = vmscale[2] or 1
    local hsy = vmscale[3] or 1

    pos = pos + (dir * d)

    -- local corner1, corner2, corner3, corner4

    -- corner2 = pos + (ang:Right() * (-0.5 * size)) + (ang:Forward() * (0.5 * size))
    -- corner1 = pos + (ang:Right() * (-0.5 * size)) + (ang:Forward() * (-0.5 * size))
    -- corner4 = pos + (ang:Right() * (0.5 * size)) + (ang:Forward() * (-0.5 * size))
    -- corner3 = pos + (ang:Right() * (0.5 * size)) + (ang:Forward() * (0.5 * size))

    -- render.SetColorMaterialIgnoreZ()
    -- render.DrawScreenQuad()

    -- render.SetStencilEnable( false )
    -- local fovmag = asight.Magnification or 1

    if hsmag and hsmag > 1 and delta < 1 then
        local screen = rtmat

        -- local sw2 = ScrH()
        -- local sh2 = sw2

        -- local sx2 = (ScrW() - sw2) / 2
        -- local sy2 = (ScrH() - sh2) / 2

        -- render.SetScissorRect( sx2, sy2, sx2 + sw2, sy2 + sh2, true )

        if GetConVar("arccw_cheapscopes"):GetBool() then

            screen = rtmat_cheap

            local ssmag = hsmag

            local sw = ScrW() * ssmag
            local sh = ScrH() * ssmag

            -- local sx = -(sw - ScrW()) / 2
            -- local sy = -(sh - ScrH()) / 2

            local cpos = self.Owner:EyePos() + ((EyeAngles() + (self:GetOwner():GetViewPunchAngles() * 0.5)):Forward() * 2048)

            local ts = cpos:ToScreen()

            local sx = ts.x - (sw / 2)
            local sy = ts.y - (sh / 2)

            render.SetMaterial(black)
            render.DrawScreenQuad()

            render.DrawTextureToScreenRect(screen, sx, sy, sw, sh)

        else

            local sw = ScrH()
            local sh = sw

            local sx = (ScrW() - sw) / 2
            local sy = (ScrH() - sh) / 2

            render.SetMaterial(black)
            render.DrawScreenQuad()

            render.DrawTextureToScreenRect(screen, sx, sy, sw, sh)

        end

        -- warp:SetFloat("$refractamount", -0.015)
        -- render.UpdateRefractTexture()
        -- render.SetMaterial(warp)
        -- render.DrawScreenQuad()

        -- render.SetScissorRect( sx2, sy2, sx2 + sw2, sy2 + sh2, false )
    end

    cam.Start3D()

    -- render.SetColorMaterialIgnoreZ()
    -- render.DrawScreenQuad()

    -- render.DrawQuad( corner1, corner2, corner3, corner4, hsc or hs.HolosightColor )
    cam.IgnoreZ( true )

    if hs.HolosightBlackbox then
        render.SetStencilPassOperation(STENCIL_ZERO)
        render.SetStencilCompareFunction(STENCIL_EQUAL)

        render.SetStencilReferenceValue(55)

        render.SetMaterial(hs.HolosightReticle or defaultdot)
        render.DrawSprite(pos, size * hsx, size * hsy, hsc or Color(255, 255, 255))

        if !hs.HolosightNoFlare then
            render.SetMaterial(hs.HolosightFlare or hs.HolosightReticle)
            render.DrawSprite(pos, size * 0.5 * hsx, size * 0.5 * hsy, Color(255, 255, 255))
        end

        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilCompareFunction(STENCIL_EQUAL)

        render.SetMaterial(black)
        render.DrawScreenQuad()
    else
        render.SetStencilReferenceValue(55)

        render.SetMaterial(hs.HolosightReticle or defaultdot)
        render.DrawSprite( pos, size * hsx, size * hsy, hsc or Color(255, 255, 255) )
        if !hs.HolosightNoFlare then
            render.SetMaterial(hs.HolosightFlare or hs.HolosightReticle or defaultdot)
            local hss = 0.75
            if hs.HolosightFlare then
                hss = 1
            end
            render.DrawSprite( pos, size * hss * hsx, size * hss * hsy, Color(255, 255, 255, 255) )
        end
    end

    render.SetStencilEnable( false )

    cam.IgnoreZ( false )

    cam.End3D()

    if hsp then

        cam.IgnoreZ(true)

        if GetConVar("arccw_glare"):GetBool() then
            render.SetBlend(delta + 0.1)
        else
            render.SetBlend(delta)
        end
        hsp:DrawModel()
        render.SetBlend(1)

        cam.IgnoreZ( false )

    end
end