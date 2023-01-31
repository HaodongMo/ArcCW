local translate = ArcCW.GetTranslation

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local cvar_deadzonex, cvar_deadzoney
local function CopeX()
    if !cvar_deadzonex then cvar_deadzonex = GetConVar("arccw_hud_deadzone_x") end
    return cvar_deadzonex:GetFloat() * ScrW() / 2
end

local function CopeY()
    if !cvar_deadzoney then cvar_deadzoney = GetConVar("arccw_hud_deadzone_y") end
    return cvar_deadzoney:GetFloat() * ScrH() / 2
end

local function MyDrawText(tbl)
    local x = tbl.x
    local y = tbl.y
    local dontbust = Color(tbl.col.r, tbl.col.g, tbl.col.b, tbl.col.a)
    surface.SetFont(tbl.font)

    if tbl.alpha then
        dontbust.a = tbl.alpha
    else
        dontbust.a = 255
    end

    if tbl.align or tbl.yalign then
        local w, h = surface.GetTextSize(tbl.text)
        if tbl.align == 1 then
            x = x - w
        elseif tbl.align == 2 then
            x = x - (w / 2)
        end
        if tbl.yalign == 1 then
            y = y - h
        elseif tbl.yalign == 2 then
            y = y - h / 2
        end
    end

    if tbl.shadow then
        surface.SetTextColor(Color(0, 0, 0, tbl.alpha or 255))
        surface.SetTextPos(x, y)
        surface.SetFont(tbl.font .. "_Glow")
        surface.DrawText(tbl.text)
    end

    surface.SetTextColor(dontbust)
    surface.SetTextPos(x, y)
    surface.SetFont(tbl.font)
    surface.DrawText(tbl.text)
end

local vhp = 0
local varmor = 0
local vclip = 0
local vreserve = 0
local vclip2 = 0
local vreserve2 = 0
local vubgl = 0
local lastwpn = ""
local lastinfo = {ammo = 0, clip = 0, firemode = "", plus = 0}
local lastinfotime = 0

function SWEP:GetHUDData()
    local data = {
        clip = math.Round(vclip or self:Clip1()),
        ammo = math.Round(vreserve or self:Ammo1()),
        bars = self:GetFiremodeBars(),
        mode = self:GetFiremodeName(),
        ammotype = self.Primary.Ammo,
        ammotype2 = self.Secondary.Ammo,
        heat_enabled        = self:HeatEnabled(),
        heat_name           = translate("ui.heat"),
        heat_level          = self:GetHeat(),
        heat_maxlevel       = self:GetMaxHeat(),
        heat_locked         = self:GetHeatLocked(),
    }

    if data.clip > self:GetCapacity() then
        data.plus = data.clip - self:GetCapacity()
        data.clip = self:GetCapacity()
    end

    local infammo, btmless = self:HasInfiniteAmmo(), self:HasBottomlessClip()
    data.infammo = infammo
    data.btmless = btmless

    if self.PrimaryBash or self:Clip1() == -1 or self:GetCapacity() == 0 or self.Primary.ClipSize == -1 then
        data.clip = "-"
    end
    if self.PrimaryBash then
        data.ammo = "-"
    end

    if self:GetBuff_Override("UBGL") then
        data.clip2 = math.Round(vclip2 or self:Clip2())

        local ubglammo = self:GetBuff_Override("UBGL_Ammo")
        if ubglammo then
            data.ammo2 = tostring(math.Round(vreserve2 or self:GetOwner():GetAmmoCount(ubglammo)))
        end

        if data.clip2 > self:GetBuff_Override("UBGL_Capacity") then
            data.plus2 = (data.clip2 - self:GetBuff_Override("UBGL_Capacity"))
            data.clip2 = self:GetBuff_Override("UBGL_Capacity")
        end
    end

    do
        if infammo then
            data.ammo = btmless and data.ammo or "-"
            data.clip = self.Throwing and "∞" or data.clip
        end
        if btmless then
            data.clip = infammo and "∞" or data.ammo
            data.ammo = "-"
        end

        local ubglammo = self:GetBuff_Override("UBGL_Ammo")
        if ubglammo then
            data.ubgl = self:Clip2() + self:GetOwner():GetAmmoCount(ubglammo)
        end
    end

    data = self:GetBuff_Hook("Hook_GetHUDData", data) or data

    return data
end

local t_states = {
    [0] = "STATE_IDLE",
    [1] = "STATE_SIGHTS",
    [2] = "STATE_SPRINT",
    [3] = "STATE_DISABLE",
    [4] = "STATE_CUSTOMIZE",
    [5] = "STATE_BIPOD"
}

local mr = math.Round
local bird = Material("arccw/hud/really cool bird.png", "mips smooth")
local statlocked = Material("arccw/hud/locked_32.png", "mips smooth")

local bar_fill = Material("arccw/hud/fmbar_filled.png",           "mips smooth")
local bar_outl = Material("arccw/hud/fmbar_outlined.png",         "mips smooth")
local bar_shad = Material("arccw/hud/fmbar_shadow.png",           "mips smooth")
local bar_shou = Material("arccw/hud/fmbar_outlined_shadow.png",  "mips smooth")

local hp = Material("arccw/hud/hp.png", "smooth")
local hp_shad = Material("arccw/hud/hp_shadow.png", "mips smooth")

local armor = Material("arccw/hud/armor.png", "mips smooth")
local armor_shad = Material("arccw/hud/armor_shadow.png", "mips smooth")
local ubgl_mat = Material("arccw/hud/ubgl.png", "smooth")
local bipod_mat = Material("arccw/hud/bipod.png", "smooth")

local function debug_panel(self)
    local reloadtime = self:GetReloadTime()
    local s = ScreenScaleMulti(1)
    local thestate = self:GetState()
    local ecksy = s * 64

    if thestate == ArcCW.STATE_CUSTOMIZE then
        ecksy = s * 256
    elseif thestate == ArcCW.STATE_SIGHTS then
        surface.SetDrawColor(255, 50, 50, 150)
        surface.DrawLine(ScrW() / 2, ScrH() * 0.5 - 256, ScrW() / 2, ScrH() * 0.5 + 256)
        surface.DrawLine(ScrW() * 0.5 - 256, ScrH() / 2, ScrW() * 0.5 + 256, ScrH() / 2)
    end

    surface.SetFont("ArcCW_26")
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetDrawColor(0, 0, 0, 63)

    -- it's for contrast, i promise
    surface.SetMaterial(bird)
    surface.DrawTexturedRect(ecksy - s-400, s-320, s * 512, s * 512)

    surface.SetDrawColor(255, 255, 255, 255)
    if reloadtime then
        surface.SetTextPos(ecksy, 26 * s * 1)
        surface.DrawText(math.Round(reloadtime[1], 2))

        surface.SetTextPos(ecksy, 26 * s * 2)
        surface.DrawText(math.Round(reloadtime[2], 2))

        surface.SetTextPos(ecksy, 26 * s * 3)
        if self:GetMagUpIn() - CurTime() > 0 then
            surface.SetTextColor(255, 127, 127, 255)
        end
        surface.DrawText( mr( math.max( self:GetMagUpIn() - CurTime(), 0 ), 2) )
    else
        surface.SetFont("ArcCW_20")
        surface.SetTextPos(ecksy, 26 * s * 2)
        surface.DrawText("NO RELOAD ANIMATION")

        surface.SetFont("ArcCW_12")
        surface.SetTextPos(ecksy, 26 * s * 2.66)
        surface.DrawText("not a mag fed one, at least...")
    end
    surface.SetTextPos(ecksy + (s*36*3), 26 * s * 3)
    if self:GetReloadingREAL() - CurTime() > 0 then
        surface.SetTextColor(255, 127, 127, 255)
    end
    surface.DrawText( mr( math.max( self:GetReloadingREAL() - CurTime(), 0 ), 2) )
    surface.SetFont("ArcCW_26")
    surface.SetTextColor(255, 255, 255, 255)

    local delay = math.max(self:GetReloadingREAL(), self:GetNWPriorityAnim())
    if delay - CurTime() > 0 then
        surface.SetTextColor(255, 127, 127, 255)
    end
    surface.SetTextPos(ecksy, 26 * s * 4)
    surface.DrawText( mr( math.max( delay - CurTime(), 0 ), 2 ) )
    surface.SetTextColor(255, 255, 255, 255)

    if self:GetWeaponOpDelay() - CurTime() > 0 then
        surface.SetTextColor(255, 127, 127, 255)
    end
    surface.SetTextPos(ecksy, 26 * s * 5)
    surface.DrawText( mr( math.max( self:GetWeaponOpDelay() - CurTime(), 0 ), 2 ) )
    surface.SetTextColor(255, 255, 255, 255)

    if self:GetNextPrimaryFire() - CurTime() > 0 then
        surface.SetTextColor(255, 127, 127, 255)
    end
    surface.SetTextPos(ecksy, 26 * s * 6)
    surface.DrawText( mr( math.max( self:GetNextPrimaryFire() * 1000 - CurTime() * 1000, 0 ), 0 ) .. "ms" )
    surface.SetTextColor(255, 255, 255, 255)

    local seq = self:GetSequenceInfo( self:GetOwner():GetViewModel():GetSequence() )
    local seq2 = self:GetOwner():GetViewModel():GetSequence()
    local seq3 = self:GetOwner():GetViewModel()
    surface.SetFont("ArcCW_20")
    surface.SetTextPos(ecksy, 26 * s * 7)
    surface.DrawText( seq2 .. ", " .. seq.label )

    local proggers = 1 - ( self.LastAnimFinishTime - CurTime() ) / seq3:SequenceDuration()

    surface.SetTextPos(ecksy, 26 * s * 8)
    surface.SetFont("ArcCW_12")
    surface.DrawText( mr( seq3:SequenceDuration() * proggers, 2 ) )

    surface.SetTextPos(ecksy + s * 30, 26 * s * 8)
    surface.DrawText( "-" )

    surface.SetTextPos(ecksy + s * 48, 26 * s * 8)
    surface.DrawText( mr( self:SequenceDuration( seq2 ), 2 ) )

    surface.SetTextPos(ecksy + s * 132, 26 * s * 7.6)
    surface.DrawText( mr(proggers * 100) .. "%" )

    -- welcome to the bar
    surface.DrawOutlinedRect(ecksy, 26 * s * 7.7, s * 128, s * 8, s)
    surface.DrawRect(ecksy, 26 * s * 7.7 + s * 2, s * 128 * math.Clamp(proggers, 0, 1), s * 8-s * 4, s)

    surface.SetFont("ArcCW_20")
    surface.SetTextPos(ecksy, 26 * s * 8.5)
    surface.DrawText( t_states[thestate] )

    surface.SetTextPos(ecksy, 26 * s * 9.25)
    surface.DrawText( mr(self:GetSightDelta() * 100) .. "%" )

    surface.DrawOutlinedRect(ecksy, 26 * s * 10, s * 64, s * 4, s / 2)
    surface.DrawRect(ecksy, 26 * s * 10 + s * 1, s * 64 * self:GetSightDelta(), s * 4-s * 2)

    surface.DrawOutlinedRect(ecksy, 26 * s * 10.25, s * 64, s * 4, s / 2)
    surface.DrawRect(ecksy, 26 * s * 10.25 + s * 1, s * 64 * self:GetSprintDelta(), s * 4-s * 2)


    surface.SetTextPos(ecksy, 26 * s * 11)
    surface.DrawText( mr(self:GetHolster_Time(), 1) )

    surface.SetTextPos(ecksy, 26 * s * 12)
    surface.DrawText( tostring(self:GetHolster_Entity()) )

    -- Labels
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("ArcCW_8")

    if reloadtime then
        surface.SetTextPos(ecksy, 26 * s * 1)
        surface.DrawText("RELOAD")

        surface.SetTextPos(ecksy- s * 36, s * 26 * 1.33)
        surface.DrawText("FULL")

        surface.SetTextPos(ecksy- s * 36, s * 26 * 2.33)
        surface.DrawText("MAGIN")

        surface.SetTextPos(ecksy- s * 36, s * 26 * 3.33)
        surface.DrawText("MAG LOAD")
    end

    surface.SetTextPos(ecksy- s * (36 * -2), s * 26 * 3.33)
    surface.DrawText("RELOAD TIME")

    surface.SetTextPos(ecksy, 26 * s * 4)
    surface.DrawText("PRIORITY DELAY")

    surface.SetTextPos(ecksy, 26 * s * 5)
    surface.DrawText("WEAPON OPERATION DELAY")

    surface.SetTextPos(ecksy, 26 * s * 6)
    surface.DrawText("NEXT PRIMARY FIRE")

    surface.SetTextPos(ecksy, 26 * s * 7)
    surface.DrawText("CURRENT ANIMATION")

    surface.SetTextPos(ecksy, 26 * s * 8.5)
    surface.DrawText("WEAPON STATE")

    surface.SetTextPos(ecksy, 26 * s * 9.25)
    surface.DrawText("SIGHT DELTA")

    surface.SetTextPos(ecksy, 26 * s * 11)
    surface.DrawText("HOLSTER TIME")

    surface.SetTextPos(ecksy, 26 * s * 12)
    surface.DrawText("HOLSTER ENT")

    -- lhik timeline
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("ArcCW_8")
    surface.SetDrawColor(255, 255, 255, 11)
    surface.DrawRect(s * 8, s * 8, ScrW() - (s * 16), s * 2)

    local texy = math.Round(CurTime(),1)
    local a, b = surface.GetTextSize(texy)
    surface.SetTextPos((ScrW() / 2) - (a / 2), (s * 16) - (b / 2))
    surface.DrawText(texy)

    surface.SetDrawColor(255, 255, 255, 127)
    if self.LHIKTimeline then for i, v in pairs(self.LHIKTimeline) do

        local pox = ScrW() / 2
        local poy = (s * 7)

        local zo = s * 0.01

        local dist = self.LHIKStartTime + v.t

        surface.DrawRect(pox + (dist * zo), poy, s * 8, s * 4)

        texy = math.Round(dist,1)
        a, b = surface.GetTextSize(texy)
        surface.SetTextPos(pox + (dist * zo) - (a / 2), (s * 16) - (b / 2) )
        surface.DrawText(texy)
    end end
end

function SWEP:DrawHUD()
    if GetConVar("arccw_dev_debug"):GetBool() then
        debug_panel(self)
    end

    if !GetConVar("cl_drawhud"):GetBool() then return false end

    if self:GetState() != ArcCW.STATE_CUSTOMIZE then
        self:GetBuff_Hook("Hook_DrawHUD")
    end

    local col2 = Color(255, 255, 255, 255)
    local col3 = Color(255, 0, 0, 255)

    local airgap = ScreenScaleMulti(8)

    local apan_bg = {
        w = ScreenScaleMulti(128),
        h = ScreenScaleMulti(48),
    }

    local data = self:GetHUDData()

    if data.heat_locked then
        col2 = col3
    end

    local curTime = CurTime()
    --local mode = self:GetFiremodeName()

    local muzz = self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1

    local fmbars = GetConVar("arccw_hud_fcgbars"):GetBool() and string.len( self:GetFiremodeBars() or "-----" ) != 0

    if ArcCW:ShouldDrawHUDElement("CHudAmmo") then
        local decaytime = GetConVar("arccw_hud_3dfun_decaytime"):GetFloat()
        if decaytime == 0 then decaytime = math.huge end
        local visible = (lastinfotime + decaytime + 1 > curTime or lastinfotime - 0.5 > curTime)

        -- Detect changes to stuff drawn in HUD
        local curInfo = {
            ammo = data.ammo,
            clip = data.clip,
            plus = data.plus or "0", -- data.plus is nil when it doesnt exist
            ammo2 = data.ammo2,
            clip2 = data.clip2,
            plus2 = data.plus2 or "0", -- data.plus is nil when it doesnt exist
            ammotype = data.ammotype,
            firemode = data.mode,
            heat = data.heat_level,
            self:GetInUBGL(),
            self:GetInBipod(),
            self:CanBipod(),
        }
        if GetConVar("arccw_hud_3dfun_lite"):GetBool() then
            curInfo.clip = nil
            curInfo.plus = nil
            curInfo.clip2 = nil
            curInfo.plus2 = nil
            curInfo.heat = nil
        end
        for i, v in pairs(curInfo) do
            if v != lastinfo[i] then
                lastinfotime = visible and (curTime - 0.5) or curTime
                lastinfo = curInfo
                break
            end
        end
        local qss = ScreenScaleMulti(24)
        local correct_y = 28
        local correct_x = 0
        if !GetConVar("arccw_hud_3dfun"):GetBool() then
            qss = ScreenScaleMulti(-24)
            correct_y = -36
            correct_x = 52
        end

        -- TODO: There's an issue where this won't ping the HUD when switching in from non-ArcCW weapons
        if LocalPlayer():KeyDown(IN_RELOAD) or lastwpn != self then lastinfotime = visible and (curTime - 0.5) or curTime end

        local alpha
        if lastinfotime + decaytime < curTime then
            alpha = 255 - (curTime - lastinfotime - decaytime) * 255
        elseif lastinfotime + 0.5 > curTime then
            alpha = 255 - (lastinfotime + 0.5 - curTime) * 255
        else
            alpha = 255
        end

        if alpha > 0 then

            local EyeAng = EyeAngles()

            local angpos
            if GetConVar("arccw_hud_3dfun"):GetBool() and self:GetOwner():ShouldDrawLocalPlayer() then
                local bone = "ValveBiped.Bip01_R_Hand"
                local ind = self:GetOwner():LookupBone(bone)

                if ind and ind > -1 then
                    local p, a = self:GetOwner():GetBonePosition(ind)
                    angpos = {Ang = a, Pos = p}
                end
            elseif GetConVar("arccw_hud_3dfun"):GetBool() then
                local vm = self:GetOwner():GetViewModel()

                if vm and vm:IsValid() then
                    angpos = vm:GetAttachment(muzz)
                end
            end

            if GetConVar("arccw_hud_3dfun"):GetBool() and angpos then

                angpos.Pos = angpos.Pos - EyeAng:Up() * GetConVar("arccw_hud_3dfun_up"):GetFloat() - EyeAng:Right() * GetConVar("arccw_hud_3dfun_right"):GetFloat() - EyeAng:Forward() * GetConVar("arccw_hud_3dfun_forward"):GetFloat()
                cam.Start3D()
                    local toscreen = angpos.Pos:ToScreen()
                cam.End3D()

                apan_bg.x = toscreen.x - apan_bg.w - ScreenScaleMulti(8)
                apan_bg.y = toscreen.y - apan_bg.h * 0.5
            else
                apan_bg.x = ScrW() - CopeX() - ScreenScaleMulti(128 + 8)
                apan_bg.y = ScrH() - CopeY() - ScreenScaleMulti(48)
            end

            apan_bg.x = math.Clamp(apan_bg.x, ScreenScaleMulti(8), ScrW() - CopeX() - ScreenScaleMulti(128 + 8))
            apan_bg.y = math.Clamp(apan_bg.y, ScreenScaleMulti(8), ScrH() - CopeY() - ScreenScaleMulti(48))

            if !fmbars then
                apan_bg.y = apan_bg.y + ScreenScaleMulti(6)
            end

            local corny = 22 * math.ease.OutSine(math.sin(vubgl * math.pi)) * (self:GetInUBGL() and -1 or 1)
            local ngap = 22 * vubgl
            local wammo = {
                x = apan_bg.x + apan_bg.w - airgap + ScreenScaleMulti(corny),
                y = apan_bg.y - ScreenScaleMulti(4) - ScreenScaleMulti(ngap),
                text = tostring(data.clip),
                font = "ArcCW_26",
                col = col2,
                align = 1,
                shadow = true,
                alpha = alpha,
            }

            wammo.col = col2

            if data.clip == 0 then
                wammo.col = col3
            end

            if tostring(data.clip) == "-" then
                wammo.text = ""
            end
                MyDrawText(wammo)
                wammo.w, wammo.h = surface.GetTextSize(wammo.text)
            surface.SetFont("ArcCW_26")

            if data.plus and !self:HasBottomlessClip() then
                local wplus = {
                    x = wammo.x,
                    y = wammo.y,
                    text = "+" .. tostring(data.plus),
                    font = "ArcCW_16",
                    col = col2,
                    shadow = true,
                    alpha = alpha,
                }

                MyDrawText(wplus)
            end

            local wreserve = {
                x = wammo.x - wammo.w - ScreenScaleMulti(4),
                y = apan_bg.y + ScreenScaleMulti(10) - ScreenScaleMulti(ngap),
                text = tostring(data.ammo) .. " /",
                font = "ArcCW_12",
                col = col2,
                align = 1,
                yalign = 2,
                shadow = true,
                alpha = alpha,
            }

            if tonumber(data.ammo) and tonumber(data.clip) and tonumber(data.clip) >= self:GetCapacity() then
                wreserve.text = tostring(data.ammo) .. " |"
            end

            if self:GetPrimaryAmmoType() <= 0 then
                wreserve.text = "!"
            end

            if self.PrimaryBash then
                wreserve.text = ""
            end

            local drew = false
            local ungl = false
            if tostring(data.ammo) != "-" then
                drew = true
                MyDrawText(wreserve)
                surface.SetFont("ArcCW_12")
                wreserve.w, wreserve.h = surface.GetTextSize(wreserve.text)
            end

            if GetConVar("arccw_hud_3dfun_ammotype"):GetBool() and isstring(data.ammotype) then
                local wammotype = {
                    x = wammo.x - wammo.w - ScreenScaleMulti(3),
                    y = wammo.y + (wammo.h/2),
                    text = language.GetPhrase(data.ammotype .. "_ammo"),
                    font = "ArcCW_8",
                    col = col2,
                    align = 1,
                    yalign = 2,
                    shadow = true,
                    alpha = alpha,
                }

                if drew then
                    wammotype.x = wreserve.x - wreserve.w - ScreenScaleMulti(3)
                    wammotype.y = wreserve.y-- + (wreserve.h/2)
                end

                MyDrawText(wammotype)
            end

            --ubgl
            if self:GetBuff_Override("UBGL") then
                ungl = true
                local ugap = 22 * (1-vubgl)
    
                local wammo = {
                    x = apan_bg.x + apan_bg.w - airgap + ScreenScaleMulti(corny*-1),
                    y = apan_bg.y - ScreenScaleMulti(4) - ScreenScaleMulti(ugap),
                    text = tostring(data.clip2),
                    font = "ArcCW_26",
                    col = col2,
                    align = 1,
                    shadow = true,
                    alpha = alpha,
                }
    
                wammo.col = col2
    
                if data.clip2 == 0 then
                    wammo.col = col3
                end
    
                if tostring(data.clip2) != "-" then
                    MyDrawText(wammo)
                end
                surface.SetFont("ArcCW_26")
                wammo.w, wammo.h = surface.GetTextSize(wammo.text)
    
                if data.plus2 and !self:HasBottomlessClip() then
                    local wplus = {
                        x = wammo.x,
                        y = wammo.y,
                        text = "+" .. tostring(data.plus2),
                        font = "ArcCW_16",
                        col = col2,
                        shadow = true,
                        alpha = alpha,
                    }
    
                    MyDrawText(wplus)
                end
    
                local wreserve = {
                    x = wammo.x - wammo.w - ScreenScaleMulti(4),
                    y = apan_bg.y + ScreenScaleMulti(10) - ScreenScaleMulti(ugap),
                    text = tostring(data.ammo2) .. " /",
                    font = "ArcCW_12",
                    col = col2,
                    align = 1,
                    yalign = 2,
                    shadow = true,
                    alpha = alpha,
                }

                if tonumber(data.ammo2) and tonumber(data.clip2) and tonumber(data.clip2) >= self:GetBuff_Override("UBGL_Capacity") then
                    wreserve.text = tostring(data.ammo2) .. " |"
                end

                if self:GetSecondaryAmmoType() <= 0 then
                    wreserve.text = "!"
                end

                local drew = false
                if tostring(data.ammo2) != "-" then
                    drew = true
                    MyDrawText(wreserve)
                    surface.SetFont("ArcCW_12")
                    wreserve.w, wreserve.h = surface.GetTextSize(wreserve.text)
                end

                if GetConVar("arccw_hud_3dfun_ammotype"):GetBool() and isstring(data.ammotype) then
                    local wammotype = {
                        x = wammo.x - wammo.w - ScreenScaleMulti(3),
                        y = wammo.y + (wammo.h/2),
                        text = language.GetPhrase(data.ammotype2 .. "_ammo"),
                        font = "ArcCW_8",
                        col = col2,
                        align = 1,
                        yalign = 2,
                        shadow = true,
                        alpha = alpha,
                    }
    
                    if drew then
                        wammotype.x = wreserve.x - wreserve.w - ScreenScaleMulti(3)
                        wammotype.y = wreserve.y
                    end
    
                    MyDrawText(wammotype)
                end
            end

            local wmode = {
                x = apan_bg.x + apan_bg.w - airgap,
                y = apan_bg.y + ScreenScaleMulti(28),
                font = "ArcCW_12",
                text = data.mode,
                col = col2,
                align = 1,
                shadow = true,
                alpha = alpha,
            }
            if !fmbars then
                wmode.y = wmode.y - ScreenScaleMulti(6)
            end
            MyDrawText(wmode)

            -- overheat bar 3d
            if self:GetMalfunctionJam() then
                local col = Color(255, 0, 32)

                local wheat = { --cheeeeerios
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = wmode.y + ScreenScaleMulti(16) * ( !GetConVar("arccw_hud_3dfun"):GetBool() and -2.5 or 1 ),
                    font = "ArcCW_12",
                    text = translate("ui.jammed"),
                    col = col,
                    align = 1,
                    shadow = true,
                    alpha = alpha,
                }
                if fmbars then
                    wheat.y = wmode.y + ScreenScaleMulti(16) * ( !GetConVar("arccw_hud_3dfun"):GetBool() and -2.5 or 0.8 )
                end
                if ungl then
                    wheat.y = wheat.y - ScreenScaleMulti(24)
                end

                local wheat_shad = {
                    x = wheat.x,
                    y = wheat.y,
                    font = "ArcCW_12_Glow",
                    text = wheat.text,
                    col = col,
                    align = 1,
                    shadow = false,
                    alpha = alpha,
                }
                MyDrawText(wheat_shad)

                MyDrawText(wheat)
            elseif data.heat_enabled then
                local pers = math.Clamp(1 - (data.heat_level / data.heat_maxlevel), 0, 1)
                local pers2 = math.Clamp(data.heat_level / data.heat_maxlevel, 0, 1)
                local colheat1 = data.heat_locked and Color(255, 0, 0) or Color(255, 128 + 127 * pers, 128 + 127 * pers)
                local colheat2 = data.heat_locked and Color(255, 0, 0) or Color(255 * pers2, 0, 0)

                local wheat = {
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = wmode.y + ScreenScaleMulti(16) * ( !GetConVar("arccw_hud_3dfun"):GetBool() and -2.5 or 1 ),
                    font = "ArcCW_12",
                    text = data.heat_name .. " " .. tostring(math.floor(100 * data.heat_level / data.heat_maxlevel)) .. "%",
                    col = colheat1,
                    align = 1,
                    shadow = false,
                    alpha = alpha,
                }
                if fmbars then
                    wheat.y = wmode.y + ScreenScaleMulti(16) * ( !GetConVar("arccw_hud_3dfun"):GetBool() and -2.5 or 0.8 )
                end
                if ungl then
                    wheat.y = wheat.y - ScreenScaleMulti(24)
                end

                local wheat_shad = {
                    x = wheat.x,
                    y = wheat.y,
                    font = "ArcCW_12_Glow",
                    text = wheat.text,
                    col = colheat2,
                    align = 1,
                    shadow = false,
                    alpha = alpha * pers,
                }
                MyDrawText(wheat_shad)

                MyDrawText(wheat)
            end
            if self:CanBipod() or self:GetInBipod() then
                local size = ScreenScaleMulti(32)
                local awesomematerial = self:GetBuff_Override("Bipod_Icon", bipod_mat)
                local whatsthecolor =   self:GetInBipod() and     Color(255, 255, 255, alpha) or
                                        self:CanBipod() and   Color(255, 255, 255, alpha / 4) or Color(0, 0, 0, 0)
                local bar = {
                    w = size,
                    h = size,
                    x = (ScrW()/2) - (size/2),
                    y = ScrH() - CopeY() - ScreenScaleMulti(40),
                }
                surface.SetDrawColor( whatsthecolor )
                surface.SetMaterial( awesomematerial )
                surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )

                local txt = string.upper(ArcCW:GetBind("+use"))

                local bip = {
                    shadow = true,
                    x = bar.x + (bar.w/2),
                    y = bar.y - ScreenScaleMulti(12),
                    align = 2,
                    font = "ArcCW_12",
                    text = txt,
                    col = whatsthecolor,
                    alpha = alpha,
                }

                MyDrawText(bip)
            end

            if GetConVar("arccw_hud_togglestats") and GetConVar("arccw_hud_togglestats"):GetBool() then
            local items = {
            }
            --[[
            {
                Icon = "",
                Locked = false,
                Selected = 1,
                Toggles = {
                    [1] = "",
                    [2] = "",
                    [3] = "",
                }
            }
            ]]
            
            for k, v in pairs(self.Attachments) do
                local atttbl = v.Installed and ArcCW.AttachmentTable[v.Installed]
                if atttbl and atttbl.ToggleStats then-- and !v.ToggleLock then
                    --print(atttbl.PrintName)
                    local item = {
                        Icon = atttbl.Icon,
                        Locked = v.ToggleLock,
                        Selected = v.ToggleNum,
                        Toggles = {}
                    }
                    for i, h in ipairs(atttbl.ToggleStats) do
                        table.insert(item.Toggles, h.PrintName)
                        --print("\t" .. (v.ToggleNum == i and "> " or "") .. atttbl.ToggleStats[i].PrintName .. (v.ToggleNum == i and " <" or ""))
                    end
                    table.insert(items, item)
                end
            end

            for i=1, 0 do
                table.insert(items, {
                    Icon = Material("Test"),
                    Locked = false,
                    Selected = i,
                    Toggles = {
                        "Test",
                        "Test",
                        "Test",
                        "Test",
                        "Test",
                    }
                })
            end

            do
                local size = ScreenScaleMulti(28)
                local lock = ScreenScaleMulti(7)
                local shiit = 1.5
                local gaap = ScreenScaleMulti(7) -- 32 / 8
                if #items == 1 then
                    gaap = 0
                    shiit = 1
                end
                for index, item in ipairs(items) do
                    surface.SetMaterial(item.Icon or bird)
                    surface.SetDrawColor(color_white)

                    local px, py = (ScrW()/2) - ((size*shiit)*(index-(#items*0.5))) + gaap, (ScrH()-CopeY()-(size*1.25))
                    surface.DrawTexturedRect(px, py, size, size)

                    if item.Locked then
                        surface.SetMaterial(statlocked)
                        surface.DrawTexturedRect(px + (size/2) - (lock/2), py + size - (lock/2), lock, lock)
                    end

                    for tdex, tinfo in ipairs(item.Toggles) do
                        local infor = {
                            x = px + (size*0.5),
                            y = py - (#item.Toggles * ScreenScaleMulti(8)) + (tdex * ScreenScaleMulti(8)),
                            font = "ArcCW_8",
                            text = tinfo,
                            col = col2,
                            align = 2,
                            yalign = 1,
                            shadow = true,
                            alpha = alpha * (tdex == item.Selected and 1 or 0.25),
                        }
                        MyDrawText(infor)
                    end
                end
            end
            end

            if fmbars then
                local segcount = string.len( self:GetFiremodeBars() or "-----" )
                local bargap = ScreenScaleMulti(2)
                local bart = {
                    w = (ScreenScaleMulti(100) + ((segcount + 1) * bargap)) / segcount,
                    h = ScreenScaleMulti(8),
                    x = apan_bg.x + apan_bg.w,
                    y = apan_bg.y + apan_bg.h
                }

                bart.x = bart.x - ((bart.w / 2 + bargap) * segcount) - ScreenScaleMulti(4) - (bart.w / 4)
                bart.y = bart.y - ScreenScaleMulti(28)

                for i = 1, segcount do
                    local c = data.bars[i]

                    if c == "#" then continue end

                    if c != "!" and c != "-" then
                        surface.SetMaterial(bar_shou)
                    else
                        surface.SetMaterial(bar_shad)
                    end
                    surface.SetDrawColor(255, 255, 255, 255 / 5 * 3)
                    surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)

                    if c == "-" then
                        -- good ol filled
                        surface.SetMaterial(bar_fill)
                        surface.SetDrawColor(col2)
                        surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                    elseif c == "!" then
                        surface.SetMaterial(bar_fill)
                        surface.SetDrawColor(col3)
                        surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                        surface.SetMaterial(bar_outl)
                        surface.SetDrawColor(col2)
                        surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                    else
                        -- good ol outline
                        surface.SetMaterial(bar_outl)
                        surface.SetDrawColor(col2)
                        surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                    end

                    bart.x = bart.x + (bart.w / 2 + bargap)
                end
            end
        end
    elseif !GetConVar("arccw_override_hud_off"):GetBool() and GetConVar("arccw_hud_minimal"):GetBool() then
        if fmbars then
            local segcount = string.len( self:GetFiremodeBars() or "-----" )
            local bargap = ScreenScaleMulti(2)
            local bart = {
                w = (ScreenScaleMulti(256) - ((segcount + 1) * bargap)) / segcount,
                h = ScreenScaleMulti(8),
                x = ScrW() / 2,
                y = ScrH() - ScreenScaleMulti(24)
            }

            bart.x = bart.x - ((bart.w / 4) * segcount) - bart.w / 3.5 - bargap

            for i = 1, segcount do
                local c = data.bars[i]

                if c == "#" then continue end

                if c != "!" and c != "-" then
                    surface.SetMaterial(bar_shou)
                else
                    surface.SetMaterial(bar_shad)
                end
                surface.SetDrawColor(255, 255, 255, 255 / 5 * 3)
                surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)

                if c == "-" then
                    -- good ol filled
                    surface.SetMaterial(bar_fill)
                    surface.SetDrawColor(col2)
                    surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                elseif c == "!" then
                    surface.SetMaterial(bar_fill)
                    surface.SetDrawColor(col3)
                    surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                    surface.SetMaterial(bar_outl)
                    surface.SetDrawColor(col2)
                    surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                else
                    -- good ol outline
                    surface.SetMaterial(bar_outl)
                    surface.SetDrawColor(col2)
                    surface.DrawTexturedRect(bart.x, bart.y, bart.w, bart.h)
                end

                bart.x = bart.x + (bart.w / 2) + bargap
            end
        end
        local wmode = {
            x = ScrW() / 2,
            y = ScrH() - ScreenScaleMulti(34),
            font = "ArcCW_12",
            text = data.mode,
            col = col2,
            align = 2,
            shadow = true,
            alpha = alpha,
        }
        MyDrawText(wmode)

        if self:GetBuff_Override("UBGL") then
            local size = ScreenScaleMulti(32)
            local awesomematerial = self:GetBuff_Override("UBGL_Icon", ubgl_mat)
            local whatsthecolor = self:GetInUBGL() and  Color(255, 255, 255, 255) or
                                                    Color(255, 255, 255, 0)
            local bar2 = {
                w = size,
                h = size,
                x = ScrW() / 2 + ScreenScaleMulti(32),
                y = ScrH() - ScreenScaleMulti(52),
            }
            surface.SetDrawColor( whatsthecolor )
            surface.SetMaterial( awesomematerial )
            surface.DrawTexturedRect( bar2.x, bar2.y, bar2.w, bar2.h )
        end

        if self:CanBipod() or self:GetInBipod() then
            local size = ScreenScaleMulti(32)
            local awesomematerial = self:GetBuff_Override("Bipod_Icon", bipod_mat)
            local whatsthecolor =   self:GetInBipod() and   Color(255, 255, 255, 255) or
                                    self:CanBipod() and     Color(255, 255, 255, 127) or
                                                            Color(255, 255, 255, 0)
            local bar2 = {
                w = size,
                h = size,
                x = ScrW() / 2 - ScreenScaleMulti(64),
                y = ScrH() - ScreenScaleMulti(52),
            }
            surface.SetDrawColor( whatsthecolor )
            surface.SetMaterial( awesomematerial )
            surface.DrawTexturedRect( bar2.x, bar2.y, bar2.w, bar2.h )

            local txt = string.upper(ArcCW:GetBind("+use"))

            local bip = {
                shadow = true,
                x = ScrW() / 2 - ScreenScaleMulti(64),
                y = ScrH() - ScreenScaleMulti(52),
                font = "ArcCW_12",
                text = txt,
                col = whatsthecolor,
            }

            MyDrawText(bip)
        end

        if data.heat_enabled then
            surface.SetDrawColor(col2)
            local perc = data.heat_level / data.heat_maxlevel

            local bar = {
                x = 0,
                y = ScrH() - ScreenScaleMulti(22)
            }

            surface.DrawOutlinedRect(ScrW() / 2 - ScreenScaleMulti(62), bar.y + ScreenScaleMulti(4.5), ScreenScaleMulti(124), ScreenScaleMulti(3))
            surface.DrawRect(ScrW() / 2 - ScreenScaleMulti(62), bar.y + ScreenScaleMulti(4.5), ScreenScaleMulti(124) * perc, ScreenScaleMulti(3))

            surface.SetFont("ArcCW_8")
            local bip = {
                shadow = false,
                x = (ScrW() / 2) - (surface.GetTextSize(data.heat_name) / 2),
                y = bar.y + ScreenScaleMulti(8),
                font = "ArcCW_8",
                text = data.heat_name,
                col = col2,
            }

            MyDrawText(bip)
        end
    end

    -- health + armor

    if ArcCW:ShouldDrawHUDElement("CHudHealth") then

        local colhp = Color(255, 255, 255, 255)
        local gotarmor = false

        if LocalPlayer():Armor() > 0 then
            gotarmor = true
            local armor_s = ScreenScaleMulti(10)
            local war = {
                x = airgap + CopeX() + armor_s + ScreenScaleMulti(6),
                y = ScrH() - ScreenScaleMulti(16) - airgap - CopeY(),
                font = "ArcCW_16",
                text = tostring(math.Round(varmor)),
                col = Color(255, 255, 255, 255),
                shadow = true,
                alpha = alpha
            }

            local armor_x = war.x - armor_s - ScreenScaleMulti(4)
            local armor_y = war.y + ScreenScaleMulti(4)

            surface.SetMaterial(armor_shad)
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawTexturedRect(armor_x, armor_y, armor_s, armor_s)

            surface.SetMaterial(armor)
            surface.SetDrawColor(colhp)
            surface.DrawTexturedRect(armor_x, armor_y, armor_s, armor_s)

            MyDrawText(war)
        end

        local hpicon_s = ScreenScaleMulti(16)
        local hpicon_x = airgap + CopeX()

        if LocalPlayer():Health() <= 30 then
            colhp = col3
        end

        local whp = {
            x = airgap + hpicon_s + CopeX(),
            y = ScrH() - ScreenScaleMulti(26 + (gotarmor and 16 or 0)) - airgap - CopeY(),
            font = "ArcCW_26",
            text = tostring(math.Round(vhp)),
            col = colhp,
            shadow = true,
            alpha = alpha
        }

        local hpicon_y = whp.y + ScreenScaleMulti(8)

        MyDrawText(whp)

        surface.SetMaterial(hp_shad)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawTexturedRect(hpicon_x, hpicon_y, hpicon_s, hpicon_s)

        surface.SetMaterial(hp)
        surface.SetDrawColor(colhp)
        surface.DrawTexturedRect(hpicon_x, hpicon_y, hpicon_s, hpicon_s)

    end

    vhp = self:GetOwner():Health()
    varmor = self:GetOwner():Armor()

    local clipdiff = math.abs(vclip - self:Clip1())
    local reservediff = math.abs(vreserve - self:Ammo1())

    if clipdiff == 1 then
        vclip = self:Clip1()
    elseif self:Clip1() == ArcCW.BottomlessMagicNumber then
        clipdiff = 0
    end

    vclip = math.Approach(vclip, self:Clip1(), FrameTime() * 30 * clipdiff)
    vreserve = math.Approach(vreserve, self:Ammo1(), FrameTime() * 30 * reservediff)

    do
        local clipdiff = math.abs(vclip2 - self:Clip2())
        local reservediff = math.abs(vreserve2 - self:Ammo2())

        if clipdiff == 1 then
            vclip2 = self:Clip2()
        elseif self:Clip2() == ArcCW.BottomlessMagicNumber then
            clipdiff = 0
        end

        vclip2 = math.Approach(vclip2, self:Clip2(), FrameTime() * 30 * clipdiff)
        vreserve2 = math.Approach(vreserve2, self:Ammo2(), FrameTime() * 30 * reservediff)
    end

    vubgl = math.Approach(vubgl, (self:GetInUBGL() and 1 or 0), (FrameTime() / 0.3) )

    if lastwpn != self then
        vclip = self:Clip1()
        vreserve = self:Ammo1()
        vclip2 = self:Clip2()
        vreserve2 = self:Ammo2()
        vubgl = 0
        vhp = self:GetOwner():Health()
        varmor = self:GetOwner():Armor()
    end

    lastwpn = self
end

function SWEP:CustomAmmoDisplay()
    local data = self:GetHUDData()
    self.AmmoDisplay = self.AmmoDisplay or {}

    self.AmmoDisplay.Draw = true -- draw the display?

    if self.Primary.ClipSize > 0 and tonumber(data.clip) then
        local plus = tonumber(data.plus) or 0
        self.AmmoDisplay.PrimaryClip = tonumber(data.clip) + plus -- amount in clip
    end

    if self.Primary.ClipSize > 0 and tonumber(data.ammo) then
        self.AmmoDisplay.PrimaryAmmo = tonumber(data.ammo) -- amount in reserve
    end

    if true then
        local ubglammo = self:GetBuff_Override("UBGL_Ammo")
        if ubglammo then
            self.AmmoDisplay.SecondaryAmmo = self:Clip2() + self:GetOwner():GetAmmoCount(ubglammo) -- amount of secondary ammo
        end
    end

    return self.AmmoDisplay -- return the table
end