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

function SWEP:ShouldFlatScope()
    return false -- this system was removed, but we need to keep this function
end

local rtsize = ScrH()

local rtmat = GetRenderTarget("arccw_rtmat", rtsize, rtsize, false)
local rtmat_cheap = GetRenderTarget("arccw_rtmat_cheap", ScrW(), ScrH(), false)
local rtmat_spare = GetRenderTarget("arccw_rtmat_spare", ScrW(), ScrH(), false)


local thermal = Material("models/debug/debugwhite")
local colormod = Material("pp/colour")
local coldtime = 30

local additionalFOVconvar = GetConVar("arccw_vm_add_ads")

local matRefract = Material("pp/arccw/refract_rt")
local matRefract_cheap = Material("pp/arccw/refract_cs") -- cheap scopes stretches square overlays so i need to make it 16x9

matRefract:SetTexture("$fbtexture", render.GetScreenEffectTexture())
matRefract_cheap:SetTexture("$fbtexture", render.GetScreenEffectTexture())

timer.Create("ihategmod", 5, 0, function() -- i really dont know what the fucking problem with cheap scopes they dont want to set texture as not cheap ones
    matRefract_cheap:SetTexture("$fbtexture", render.GetScreenEffectTexture())
    matRefract:SetTexture("$fbtexture", render.GetScreenEffectTexture()) -- not cheap scope here why not
end)

local pp_ca_base, pp_ca_r, pp_ca_g, pp_ca_b = Material("pp/arccw/ca_base"), Material("pp/arccw/ca_r"), Material("pp/arccw/ca_g"), Material("pp/arccw/ca_b")
local pp_ca_r_thermal, pp_ca_g_thermal, pp_ca_b_thermal = Material("pp/arccw/ca_r_thermal"), Material("pp/arccw/ca_g_thermal"), Material("pp/arccw/ca_b_thermal")

pp_ca_r:SetTexture("$basetexture", render.GetScreenEffectTexture())
pp_ca_g:SetTexture("$basetexture", render.GetScreenEffectTexture())
pp_ca_b:SetTexture("$basetexture", render.GetScreenEffectTexture())

pp_ca_r_thermal:SetTexture("$basetexture", render.GetScreenEffectTexture())
pp_ca_g_thermal:SetTexture("$basetexture", render.GetScreenEffectTexture())
pp_ca_b_thermal:SetTexture("$basetexture", render.GetScreenEffectTexture())

local greenColor = Color(0, 255, 0)  -- optimized +10000fps
local whiteColor = Color(255, 255, 255)
local blackColor = Color(0, 0, 0)

local function DrawTexturedRectRotatedPoint( x, y, w, h, rot, x0, y0 ) -- stolen from gmod wiki
    local c = math.cos( math.rad( rot ) )
    local s = math.sin( math.rad( rot ) )

    local newx = y0 * s - x0 * c
    local newy = y0 * c + x0 * s

    surface.DrawTexturedRectRotated( x + newx, y + newy, w, h, rot )
end


local function IsWHOT(ent)
    if !ent:IsValid() or ent:IsWorld() then return false end

    if ent:IsPlayer() then -- balling
        if ent.ArcticMedShots_ActiveEffects and ent.ArcticMedShots_ActiveEffects["coldblooded"] or ent:Health() <= 0 then return false end -- arc stims
        return true
    end

    if ent:IsNPC() or ent:IsNextBot() then -- npcs
        if ent.ArcCWCLHealth and ent.ArcCWCLHealth <= 0 or ent:Health() <= 0 then return false end
        return true
    end

    if ent:IsRagdoll() then -- ragdolling
        if !ent.ArcCW_ColdTime then ent.ArcCW_ColdTime = CurTime() + coldtime end
        return ent.ArcCW_ColdTime > CurTime()
    end

    if ent:IsVehicle() or ent:IsOnFire() or ent.ArcCW_Hot or ent:IsScripted() and !ent:GetOwner():IsValid() then -- vroom vroom + :fire: + ents but not guns (guns on ground will be fine)
        return true
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

    local nvsc = asight.ThermalScopeColor or whiteColor
    local tvsc = asight.ThermalHighlightColor or whiteColor

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

        if !asight.ThermalScopeSimple then
            render.SetBlend(0.5)
            render.SuppressEngineLighting(true)

            render.SetColorModulation(250, 250, 250)

            v:DrawModel()
        end
    end

    render.SetColorModulation(1, 1, 1)

    render.SuppressEngineLighting(false)

    render.MaterialOverride()

    render.SetBlend(1)

    render.SetStencilCompareFunction(STENCIL_EQUAL)

    if asight.ThermalScopeSimple then
        surface.SetDrawColor(255, 255, 255, 255)
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

        if GetConVar("arccw_thermalpp"):GetBool() and GetConVar("arccw_scopepp"):GetBool() then
            -- chromatic abberation

            render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())

            render.SetMaterial( pp_ca_base )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_r_thermal )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_g_thermal )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_b_thermal )
            render.DrawScreenQuad()
            -- pasted here cause otherwise either target colors will get fucked either pp either motion blur
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
            ["$pp_colour_colour"] = asight.Colormult or 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end

    render.SetScissorRect( sx, sy, sx + sw, sy + sh, false )

    render.SetStencilEnable(false)

    colormod:SetTexture("$fbtexture", render.GetScreenEffectTexture())

    cam.End3D()

    if GetConVar("arccw_thermalpp"):GetBool() then
        if !render.SupportsPixelShaders_2_0() then return end

        DrawSharpen(0.3,0.9)
        DrawBloom(0,0.3,5,5,3,0.5,1,1,1)
        -- DrawMotionBlur(0.7,1,1/(asight.FPSLock or 45)) -- upd i changed order and it fucking worked lmao     //////i cant fucking understand why motionblur fucks render target
    end

    render.PopRenderTarget()
end

function SWEP:FormNightVision(tex)
    local asight = self:GetActiveSights()

    local orig = colormod:GetTexture("$fbtexture")

    colormod:SetTexture("$fbtexture", tex)

    render.PushRenderTarget(tex)

    local nvsc = asight.NVScopeColor or greenColor

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

local pp_cc_tab = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0, -- why nothing works hh
    ["$pp_colour_contrast"] = 0.9,  -- but same time chroma dont work without calling it
    ["$pp_colour_colour"] = 1,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

function SWEP:FormPP(tex)
    if !render.SupportsPixelShaders_2_0() then return end

    local asight = self:GetActiveSights()

    if asight.Thermal then return end -- eyah

    local cs = GetConVar("arccw_cheapscopes"):GetBool()
    local refract = GetConVar("arccw_scopepp_refract"):GetBool()
    local pp = GetConVar("arccw_scopepp"):GetBool()


    if refract or pp then
        if !cs then render.PushRenderTarget(tex) end
        render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())

        if pp then
            render.SetMaterial( pp_ca_base )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_r )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_g )
            render.DrawScreenQuad()
            render.SetMaterial( pp_ca_b )
            render.DrawScreenQuad()
                -- Color modify

            DrawColorModify( pp_cc_tab )
                -- Sharpen
            DrawSharpen(-0.1, 5) -- dont work for some reason
        end

        if refract then
            local addads = math.Clamp(additionalFOVconvar:GetFloat(), -2, 14)
            local refractratio = GetConVar("arccw_scopepp_refract_ratio"):GetFloat() or 0
            local refractamount = (-0.6 + addads / 30) * refractratio
            local refractmat = cs and matRefract_cheap or matRefract

            refractmat:SetFloat( "$refractamount", refractamount )

            render.SetMaterial(refractmat)
            render.DrawScreenQuad()
        end

        if !cs then render.PopRenderTarget() end
    end
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

    self:FormPP(screen)

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

    -- integrated render delay for better optimization
    if asight.FPSLock then
        asight.fpsdelay = CurTime() + 1 / (asight.FPSLock or 45)
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
    ArcCW.VMInRT = true

    local rtangles, rtpos, rtdrawvm

    if self:GetState() == ArcCW.STATE_SIGHTS then
        if GetConVar("arccw_drawbarrel"):GetBool() and GetConVar("arccw_vm_coolsway"):GetBool() and asight.Slot and asight.Slot == 1 then -- slot check to ignore integrated
            rtangles = self.VMAng - self.VMAngOffset - (self:GetOurViewPunchAngles() * mag * 0.1)
            rtangles.x = rtangles.x - self.VMPosOffset_Lerp.z * 10
            rtangles.y = rtangles.y + self.VMPosOffset_Lerp.y * 10

            rtpos = self.VMPos + self.VMAng:Forward() * (asight.EVPos.y + 7 + (asight.ScopeMagnificationMax and asight.ScopeMagnificationMax / 3 or asight.HolosightData.HolosightMagnification / 3)) -- eh
            rtdrawvm = true
        else
            rtangles = EyeAngles()
            rtpos = EyePos()
            rtdrawvm = false

            -- HACK HACK HACK HACK HACK
            -- If we do not draw the viewmodel in RT scope, calling GetAttachment on the vm seems to break LHIK.
            -- So... just draw it! The results gets drawn over again so it doesn't affect the outcome
            render.RenderView({drawviewmodel = true}) -- ?????
        end
    end

    local addads = math.Clamp(additionalFOVconvar:GetFloat(), -2, 14)

    local rt = {
        w = rtsize,
        h = rtsize,
        angles = rtangles,
        origin = rtpos,
        drawviewmodel = rtdrawvm,
        fov = self:GetOwner():GetFOV() / mag / 1.2 - (addads or 0) / 4,
    }

    rtsize = ScrH()

    if ScrH() > ScrW() then rtsize = ScrW() end

    local rtres = asight.ForceLowRes and ScrH() * 0.6 or ScrH() -- we can emit low res lcd displays for scopes

    rtmat = GetRenderTarget("arccw_rtmat" .. rtres, rtres, rtres, false)

    render.PushRenderTarget(rtmat, 0, 0, rtsize, rtsize)

    render.ClearRenderTarget(rt, blackColor)

    if self:GetState() == ArcCW.STATE_SIGHTS then
        render.RenderView(rt)
        cam.Start3D(EyePos(), EyeAngles(), rt.fov, 0, 0, nil, nil, 0, nil)
            self:DoLaser(false)
        cam.End3D()
    end

    ArcCW.Overdraw = false
    ArcCW.LaserBehavior = false
    ArcCW.VMInRT = false

    self:FormPP(rtmat)

    render.PopRenderTarget()

    cam.End3D()

    if asight.Thermal then
        self:FormThermalImaging(rtmat)
    end

    if asight.SpecialScopeFunction then
        asight.SpecialScopeFunction(rtmat)
    end

    -- integrated render delay for better optimization
    if asight.FPSLock then
        asight.fpsdelay = CurTime() + 1 / (asight.FPSLock or 45)
    end

end

-- local fpsdelay = CurTime()

hook.Add("RenderScene", "ArcCW", function()
    if GetConVar("arccw_cheapscopes"):GetBool() then return end

    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn.ArcCW then return end
    if wpn:GetActiveSights() and wpn:GetActiveSights().FPSLock
            and (wpn:GetActiveSights().fpsdelay or 0) > CurTime() then
        return
    end
    wpn:FormRTScope()
end)

local black = Material("arccw/hud/black.png")
local defaultdot = Material("arccw/hud/hit_dot.png")

function SWEP:DrawHolosight(hs, hsm, hsp, asight)
    -- holosight structure
    -- holosight model

    local ref = 32

    asight = asight or self:GetActiveSights()
    local delta = self:GetSightDelta()

    if asight.HolosightData then
        hs = asight.HolosightData
    end

    if self:GetState() != ArcCW.STATE_SIGHTS and delta > 0.5 or self:GetBarrelNearWall() > 0 then return end

    if !hs then return end

    if delta != 0 and GetConVar("arccw_scopepp"):GetBool() then
        pp_ca_r:SetVector("$color2", Vector(1-delta, 0, 0))
        pp_ca_g:SetVector("$color2", Vector(0, 1-delta, 0))
        pp_ca_b:SetVector("$color2", Vector(0, 0, 1-delta))
        pp_ca_base:SetFloat("$alpha", 1-delta)
    end

    local hsc = Color(255, 255, 255) -- putting here global or white local SOMEHOW FUCKS IT EVEN GLOBAL BEING FUCKED WTF I HATE

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

    local hsmag = asight.ScopeMagnification or 1

    local size = hs.HolosightSize or 1

    local addads = math.Clamp(additionalFOVconvar:GetFloat(), -2, 14)

    local addconvar = asight.MagnifiedOptic and (addads or 0) or 0

    size = size + addconvar + (addconvar > 5.5 and (addconvar-5.5) * 2 or 0)


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

        render.SetStencilReferenceValue(ref)

        ArcCW.Overdraw = true

        render.OverrideDepthEnable( true, true )

        if !hsm then
            hsp:DrawModel()
        else

            hsm:SetBodygroup(1, 0)

            if !hsp or hs.HolosightNoHSP then
                hsm:DrawModel()
            end

            -- render.MaterialOverride()

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

            render.SetStencilReferenceValue(ref)

            if hsp then
                hsp:DrawModel()
            end
        end

        -- render.MaterialOverride()

        render.OverrideDepthEnable( false, true )

        ArcCW.Overdraw = false

    render.SetBlend(1)

    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilCompareFunction(STENCIL_EQUAL)

    -- local pos = EyePos()
    -- local ang = EyeAngles()

    ang:RotateAroundAxis(ang:Forward(), -90)

    local dir = ang:Up()

    local pdiff = (pos - EyePos()):Length()

    pos = LerpVector(delta, EyePos(), pos)

    local eyeangs = self:GetOwner():EyeAngles() - self:GetOurViewPunchAngles() * hsmag * 0.1

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

    local pos2 = pos + (dir * -8)

    local a = self:GetOwner():InVehicle() and {x = ScrW() / 2, y = ScrH() / 2} or pos:ToScreen()
    local x = a.x - (self.VMAngOffset.y - self.VMPosOffset_Lerp.y * 10) * (hsmag * 1.5) ^ 2
    local y = a.y + (self.VMAngOffset.x * 5 + self.VMPosOffset_Lerp.z * 10) * (hsmag * 1.5) ^ 2

    local a2 = self:GetOwner():InVehicle() and {x = ScrW() / 2, y = ScrH() / 2} or pos2:ToScreen()

    local off_x = a2.x - (ScrW() / 2)
    local off_y = a2.y - (ScrH() / 2)

    --pos = pos + Vector(ArcCW.StrafeTilt(self), 0, 0)

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

        if render.GetHDREnabled() and delta < 0.07 then
            render.SetToneMappingScaleLinear(Vector(1,1,1)) -- hdr fix
        end

        if GetConVar("arccw_cheapscopes"):GetBool() then

            screen = rtmat_cheap

            local addads = math.Clamp(additionalFOVconvar:GetFloat(), -2, 14)
            local csratio = math.Clamp(GetConVar("arccw_cheapscopesv2_ratio"):GetFloat(), 0, 1)

            local ssmag = 1 + csratio * hsmag + (addads or 0) / 20 -- idk why 20
            local sw = ScrW() * ssmag
            local sh = ScrH() * ssmag

            -- local sx = -(sw - ScrW()) / 2
            -- local sy = -(sh - ScrH()) / 2

            local cpos = self:GetOwner():EyePos() + ((EyeAngles() + (self:GetOurViewPunchAngles() * 0.5)):Forward() * 2048)

            --cpos:Rotate(Angle(0, -ArcCW.StrafeTilt(self), 0))

            local ts = self:GetOwner():InVehicle() and {x = ScrW() / 2, y = ScrH() / 2} or cpos:ToScreen()

            local sx = ts.x - (sw / 2) - off_x - (self.VMAngOffset.y - self.VMPosOffset_Lerp.y * 15) * (hsmag * 1) ^ 2
            local sy = ts.y - (sh / 2) - off_y + (self.VMAngOffset.x * 5 + self.VMPosOffset_Lerp.z * 15) * (hsmag * 1) ^ 2

            render.SetMaterial(black)
            render.DrawScreenQuad()

            render.DrawTextureToScreenRect(screen, sx, sy, sw, sh)

        else

            local sw = ScrH()
            local sh = sw

            local sx = ((ScrW() - sw) / 2) - off_x
            local sy = ((ScrH() - sh) / 2) - off_x

            render.SetMaterial(black)
            render.DrawScreenQuad()

            render.DrawTextureToScreenRect(screen, sx, sy, sw, sh)

        end
    end

    -- cam.Start3D()

    -- render.SetColorMaterialIgnoreZ()
    -- render.DrawScreenQuad()

    -- render.DrawQuad( corner1, corner2, corner3, corner4, hsc or hs.HolosightColor )
    cam.IgnoreZ( true )

    render.SetStencilReferenceValue(ref)

    -- render.SetMaterial(hs.HolosightReticle or defaultdot)
    -- render.DrawSprite( pos, size * hsx, size * hsy, hsc or Color(255, 255, 255) )
    -- if !hs.HolosightNoFlare then
    --     render.SetMaterial(hs.HolosightFlare or hs.HolosightReticle or defaultdot)
    --     local hss = 0.75
    --     if hs.HolosightFlare then
    --         hss = 1
    --     end
    --     render.DrawSprite( pos, size * hss * hsx, size * hss * hsy, Color(255, 255, 255, 255) )
    -- end

    cam.Start2D()

    if hs.HolosightBlackbox then
        render.SetStencilPassOperation(STENCIL_KEEP)

        surface.SetDrawColor(0, 0, 0, 255 * delta)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    render.SetStencilPassOperation(STENCIL_DECR)
    render.SetStencilCompareFunction(STENCIL_EQUAL)

    local hss = size * 32 * math.min(ScrW(), ScrH()) / 800

    --local thej = self.TheJ.anga + LocalPlayer():GetViewPunchAngles() + self:GetOurViewPunchAngles()
                    -- AYE, UR ACTIVE ANG BEIN TWISTED DUNT GIVE AUH SHET

    surface.SetMaterial(hs.HolosightReticle or defaultdot)
    surface.SetDrawColor(hsc or 255, 255, 255)
    -- surface.DrawTexturedRect(x - (hss / 2), y - (hss / 2), hss, hss)

    DrawTexturedRectRotatedPoint(x, y, hss, hss, -(self.VMAngOffset.r+self.VMAngOffset_Lerp.r+self:GetOurViewPunchAngles().r)*5 , 0, 0)

    if !hs.HolosightNoFlare then
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilReferenceValue(ref - 1)
        surface.SetMaterial(hs.HolosightFlare or hs.HolosightReticle or defaultdot)
        surface.SetDrawColor(255, 255, 255, 150)

        local hss2 = hss

        if !hs.HolosightFlare then
            hss2 = hss - 2
        end

        surface.DrawTexturedRect(x - (hss2 / 2), y - (hss2 / 2), hss2, hss2)
        --surface.DrawTexturedRectRotated(x, y, hss2, hss2, -thej.r or 0)

        render.SetStencilReferenceValue(ref)
    end

    if hs.HolosightBlackbox then
        -- render.SetColorMaterialIgnoreZ()
        -- render.DrawScreenQuad()

        surface.SetDrawColor(0, 0, 0)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        -- surface.DrawRect(0, (ScrH() - hss) / 2, ScrW(), (ScrH() - hss) / 2)
    end

    cam.End2D()

    render.SetStencilEnable( false )

    cam.IgnoreZ( false )

    -- cam.End3D()

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


--           I wanted to make here procedural normal map for refract using rt but steamsnooze


-- local TEX_SIZE = 512

-- local tex = GetRenderTarget( "ExampleRT", TEX_SIZE, TEX_SIZE )

-- local txBackground = surface.GetTextureID( "pp/arccw/lense_nrm2" )
-- local myMat = CreateMaterial( "ExampleRTMat3", "UnlitGeneric", {
-- 	["$basetexture"] = tex:GetName() -- Make the material use our render target texture
-- } )

-- hook.Add( "HUDPaint", "DrawExampleMat", function()
    -- render.PushRenderTarget( tex )
    -- cam.Start2D()

    --     surface.SetDrawColor( 128,128,255 )
    --     surface.DrawRect(0,0,TEX_SIZE, TEX_SIZE)
    --     surface.SetDrawColor( color_white )
    --     surface.SetTexture( txBackground )
        -- local joke = math.sin(CurTime()*5)/4

    --     surface.DrawTexturedRect( TEX_SIZE/4-joke/2, TEX_SIZE/4-joke/2, TEX_SIZE/2+joke, TEX_SIZE/2+joke )

    -- cam.End2D()
    -- render.PopRenderTarget()
    -- surface.SetDrawColor( color_white )
    -- surface.SetMaterial( myMat )
    -- surface.DrawTexturedRect( 25, 25, TEX_SIZE, TEX_SIZE )
    -- print()
    -- DrawTexturedRectRotatedPoint(250+250/2,250+250/2,250,250,(CurTime()%360)*50,0,0)
    -- surface.DrawRect(250,250,250,250)

-- end )
