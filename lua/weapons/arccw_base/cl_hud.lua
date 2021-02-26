

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local function CopeX()
    return GetConVar("arccw_hud_deadzone_x"):GetFloat() * ScrW()/2
end

local function CopeY()
    return GetConVar("arccw_hud_deadzone_y"):GetFloat() * ScrH()/2
end

local function MyDrawText(tbl)
    local x = tbl.x
    local y = tbl.y
    surface.SetFont(tbl.font)

    if tbl.alpha then
        tbl.col.a = tbl.alpha
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

    surface.SetTextColor(tbl.col)
    surface.SetTextPos(x, y)
    surface.SetFont(tbl.font)
    surface.DrawText(tbl.text)
end

local vhp = 0
local varmor = 0
local vclip = 0
local vreserve = 0
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
        heat_enabled        = self:HeatEnabled(),
        heat_name           = "HEAT",
        heat_level          = self:GetHeat(),
        heat_maxlevel       = self:GetMaxHeat(),
        heat_locked         = self:GetHeatLocked(),
    }

    if data.clip > self:GetCapacity() then
        data.plus = data.clip - self:GetCapacity()
        data.clip = self:GetCapacity()
    end

    if self.PrimaryBash or self:Clip1() == -1 or self:GetCapacity() == 0 or self.Primary.ClipSize == -1 then
        data.clip = "-"
    end

    if self.PrimaryBash or self:HasInfiniteAmmo() then
        data.ammo = "-"
    end

    if self:HasBottomlessClip() then
        data.clip = data.ammo
        data.ammo = "-"
    end

    if self:GetInUBGL() then
        data.clip = self:Clip2()
        local ubglammo = self:GetBuff_Override("UBGL_Ammo")

        if ubglammo then
            data.ammo = tostring(self:GetOwner():GetAmmoCount(ubglammo))
        end

        data.plus = nil
    end

    local ubglammo = self:GetBuff_Override("UBGL_Ammo")
    if ubglammo and !self:GetInUBGL() then
        data.ubgl = self:Clip2() + self:GetOwner():GetAmmoCount(ubglammo)
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
local bird = Material("hud/really cool bird.png", "smooth")

function SWEP:DrawHUD()
    -- DEBUG PANEL
    if GetConVar("arccw_dev_debug"):GetBool() then
        local reloadtime = self:GetReloadTime()
        local s = ScreenScaleMulti(1)
        local thestate = self:GetState()
        local ecksy = s* 64

        if thestate == ArcCW.STATE_CUSTOMIZE then
            ecksy = s* 256
        end

        surface.SetFont("ArcCW_26")
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetDrawColor(0, 0, 0, 63)
        
        -- it's for contrast, i promise
        surface.SetMaterial(bird)
        surface.DrawTexturedRect(ecksy - s-400, s-320, s*512, s*512)

        surface.SetDrawColor(255, 255, 255, 255)
        if reloadtime then
            surface.SetTextPos(ecksy, 26 * s*1)
            surface.DrawText(reloadtime[1])

            surface.SetTextPos(ecksy, 26 * s*2)
            surface.DrawText(reloadtime[2])

            surface.SetTextPos(ecksy, 26 * s*3)
            if self:GetMagUpIn()-CurTime() > 0 then
                surface.SetTextColor(255, 127, 127, 255)
            end
            surface.DrawText( mr( math.max( self:GetMagUpIn() - CurTime(), 0 ), 2) )
        else
            surface.SetFont("ArcCW_20")
            surface.SetTextPos(ecksy, 26 * s*2)
            surface.DrawText("NO RELOAD ANIMATION")
            
            surface.SetFont("ArcCW_12")
            surface.SetTextPos(ecksy, 26 * s*2.66)
            surface.DrawText("not a mag fed one, at least...")
        end
        surface.SetFont("ArcCW_26")
        surface.SetTextColor(255, 255, 255, 255)

        if self:GetReloadingREAL()-CurTime() > 0 then
            surface.SetTextColor(255, 127, 127, 255)
        end
        surface.SetTextPos(ecksy, 26 * s*4)
        surface.DrawText( mr( math.max( self:GetReloadingREAL() - CurTime(), 0 ), 2 ) )
        surface.SetTextColor(255, 255, 255, 255)

        if self:GetWeaponOpDelay()-CurTime() > 0 then
            surface.SetTextColor(255, 127, 127, 255)
        end
        surface.SetTextPos(ecksy, 26 * s*5)
        surface.DrawText( mr( math.max( self:GetWeaponOpDelay() - CurTime(), 0 ), 2 ) )
        surface.SetTextColor(255, 255, 255, 255)

        if self:GetNextPrimaryFire() - CurTime() > 0 then
            surface.SetTextColor(255, 127, 127, 255)
        end
        surface.SetTextPos(ecksy, 26 * s*6)
        surface.DrawText( mr( math.max( self:GetNextPrimaryFire()*1000 - CurTime()*1000, 0 ), 0 ) .. "ms" )
        surface.SetTextColor(255, 255, 255, 255)

        local seq = self:GetSequenceInfo( self:GetOwner():GetViewModel():GetSequence() )
        local seq2 = self:GetOwner():GetViewModel():GetSequence()
        local seq3 = self:GetOwner():GetViewModel()
        surface.SetFont("ArcCW_20")
        surface.SetTextPos(ecksy, 26 * s*7)
        surface.DrawText( seq2 .. ", " .. seq.label )

        local proggers = 1 - ( self.LastAnimFinishTime - CurTime() ) / seq3:SequenceDuration()

        surface.SetTextPos(ecksy, 26 * s*8)
        surface.SetFont("ArcCW_12")
        surface.DrawText( mr( seq3:SequenceDuration()*proggers, 2 ) )

        surface.SetTextPos(ecksy + s*30, 26 * s*8)
        surface.DrawText( "-" )

        surface.SetTextPos(ecksy + s*48, 26 * s*8)
        surface.DrawText( mr( self:SequenceDuration( seq2 ), 2 ) )

        surface.SetTextPos(ecksy + s*132, 26 * s*7.6)
        surface.DrawText( mr(proggers*100) .. "%" )

        -- welcome to the bar
        surface.DrawOutlinedRect(ecksy, 26 * s*7.7, s*128, s*8, s)
        surface.DrawRect(ecksy, 26 * s*7.7+s*2, s*128*proggers, s*8-s*4, s)

        surface.SetFont("ArcCW_20")
        surface.SetTextPos(ecksy, 26 * s*8.5)
        surface.DrawText( t_states[thestate] )

        surface.SetTextPos(ecksy, 26 * s*9.25)
        surface.DrawText( mr(self:GetSightDelta()*100) .. "%" )
        
        surface.DrawOutlinedRect(ecksy, 26 * s*10, s*64, s*4, s/2)
        surface.DrawRect(ecksy, 26 * s*10+s*1, s*64*self:GetSightDelta(), s*4-s*2)

        -- Labels
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetFont("ArcCW_8")

        if reloadtime then
            surface.SetTextPos(ecksy, 26 * s*1)
            surface.DrawText("RELOAD")

            surface.SetTextPos(ecksy- s*36, s*26 * 1.33)
            surface.DrawText("FULL")

            surface.SetTextPos(ecksy- s*36, s*26 * 2.33)
            surface.DrawText("MAGIN")

            surface.SetTextPos(ecksy- s*36, s*26 * 3.33)
            surface.DrawText("MAG LOAD")
        end

        surface.SetTextPos(ecksy, 26 * s*4)
        surface.DrawText("RELOAD DELAY")

        surface.SetTextPos(ecksy, 26 * s*5)
        surface.DrawText("WEAPON OPERATION DELAY")

        surface.SetTextPos(ecksy, 26 * s*6)
        surface.DrawText("NEXT PRIMARY FIRE")

        surface.SetTextPos(ecksy, 26 * s*7)
        surface.DrawText("CURRENT ANIMATION")

        surface.SetTextPos(ecksy, 26 * s*8.5)
        surface.DrawText("WEAPON STATE")  
        
        surface.SetTextPos(ecksy, 26 * s*9.25)
        surface.DrawText("SIGHT DELTA")
    end

    if self:GetState() != ArcCW.STATE_CUSTOMIZE then
        self:GetBuff_Hook("Hook_DrawHUD")
    end

    local col1 = Color(0, 0, 0, 100)
    local col2 = Color(255, 255, 255, 255)
    local col3 = Color(255, 0, 0, 255)

    local airgap = ScreenScaleMulti(8)

    local apan_bg = {
        w = ScreenScaleMulti(128),
        h = ScreenScaleMulti(48),
    }

    local bargap = ScreenScaleMulti(2)
    local data = self:GetHUDData()

    if data.heat_locked then
        col2 = col3
    end

    local curTime = CurTime()
    local mode = self:GetFiremodeName()

    local muzz = self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1

    local yuriewantsbabynapnaptimewaawaawaaa = GetConVar("arccw_hud_3dfun"):GetBool()

    if ArcCW:ShouldDrawHUDElement("CHudAmmo") then

        --if yuriewantsbabynapnaptimewaawaawaaa and muzz and angpos then
        if true then

            local visible = (lastinfotime + 4 > curTime or lastinfotime - 0.5 > curTime)

            -- Detect changes to stuff drawn in HUD
            local curInfo = {
                ammo = data.ammo,
                clip = data.clip,
                plus = data.plus,
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
                curInfo.heat = nil
            end
            for i, v in pairs(curInfo) do
                if v != lastinfo[i] then
                    lastinfotime = visible and (curTime - 0.5) or curTime
                    lastinfo = curInfo
                    break
                end
            end
            local woobie = ScreenScaleMulti(24)
            local items = 0
            local gonnacry = 28
            local gonnapisspant = 0
            if !GetConVar("arccw_hud_3dfun"):GetBool() then
                woobie = ScreenScaleMulti(-24)
                gonnacry = -16
                gonnapisspant = 52
            end

            -- TODO: There's an issue where this won't ping the HUD when switching in from non-ArcCW weapons
            if LocalPlayer():KeyDown(IN_RELOAD) or lastwpn != self then lastinfotime = visible and (curTime - 0.5) or curTime end

            local alpha
            if lastinfotime + 3 < curTime then
                alpha = 255 - (curTime - lastinfotime - 3) * 255
            elseif lastinfotime + 0.5 > curTime then
                alpha = 255 - (lastinfotime + 0.5 - curTime) * 255
            else
                alpha = 255
            end

            if alpha > 0 then

                local EyeAng = EyeAngles()

                if GetConVar("arccw_hud_3dfun"):GetBool() then
                    local angpos
                    if self:GetOwner():ShouldDrawLocalPlayer() then
                        local bone = "ValveBiped.Bip01_R_Hand"
                        local ind = self:GetOwner():LookupBone(bone)

                        if ind and ind > -1 then
                            local p, a = self:GetOwner():GetBonePosition(ind)
                            angpos = {Ang = a, Pos = p}
                        end
                    else
                        local vm = self:GetOwner():GetViewModel()

                        if vm and vm:IsValid() then
                            angpos = vm:GetAttachment(muzz)
                        end
                    end

                    angpos.Pos = angpos.Pos - EyeAng:Up() * GetConVar("arccw_hud_3dfun_up"):GetFloat() - EyeAng:Right() * GetConVar("arccw_hud_3dfun_right"):GetFloat() - EyeAng:Forward() * GetConVar("arccw_hud_3dfun_forward"):GetFloat()
                    cam.Start3D()
                        local toscreen = angpos.Pos:ToScreen()
                    cam.End3D()

                    apan_bg.x = toscreen.x - apan_bg.w - ScreenScaleMulti(8)
                    apan_bg.y = toscreen.y - apan_bg.h * 0.5
                else
                    apan_bg.x = ScrW() - CopeX() - ScreenScaleMulti(128+8)
                    apan_bg.y = ScrH() - CopeY() - ScreenScaleMulti(48)
                end

                if GetConVar("arccw_hud_3dfun_ammotype"):GetBool() then
                    local wammotype = {
                        x = apan_bg.x + apan_bg.w - airgap,
                        y = apan_bg.y - ScreenScaleMulti(8),
                        text = language.GetPhrase(data.ammotype .. "_ammo"),
                        font = "ArcCW_8",
                        col = col2,
                        align = 1,
                        shadow = true,
                        alpha = alpha,
                    }
                    MyDrawText(wammotype)
                end

                local wammo = {
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = apan_bg.y,
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

                MyDrawText(wammo)
                wammo.w, wammo.h = surface.GetTextSize(wammo.text)

                if data.plus then
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
                    y = apan_bg.y + ScreenScaleMulti(26 - 12),
                    text = tostring(data.ammo) .. " /",
                    font = "ArcCW_12",
                    col = col2,
                    align = 1,
                    yalign = 2,
                    shadow = true,
                    alpha = alpha,
                }

                if self.PrimaryBash then
                    wreserve.text = ""
                end

                MyDrawText(wreserve)
                wreserve.w, wreserve.h = surface.GetTextSize(wreserve.text)
                
                --[[local wwpnname = {
                    x = ScrW()/2,
                    y = ScrH() - ScreenScaleMulti(8),
                    text = self:GetPrintName(),
                    font = "ArcCW_24",
                    col = col2,
                    align = 2,
                    yalign = 1,
                    shadow = true,
                    alpha = alpha,
                }
                MyDrawText(wwpnname)]]

                local wmode = {
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = wammo.y + wammo.h,
                    font = "ArcCW_12",
                    text = data.mode,
                    col = col2,
                    align = 1,
                    shadow = true,
                    alpha = alpha,
                }
                MyDrawText(wmode)

                -- overheat bar 3d

                if data.heat_enabled then
                    local wheat = {
                        x = apan_bg.x + apan_bg.w - airgap,
                        y = wmode.y + ScreenScaleMulti(14) * ( !GetConVar("arccw_hud_3dfun"):GetBool() and -2.5 or 1 ),
                        font = "ArcCW_12",
                        text = data.heat_name .. " " .. tostring(math.ceil(100 * data.heat_level / data.heat_maxlevel)) .. "%",
                        col = col2,
                        align = 1,
                        shadow = true,
                        alpha = alpha,
                    }
                    MyDrawText(wheat)
                end
                if self:GetInUBGL() then
                    local size = ScreenScaleMulti(32)
                    local awesomematerial = Material( "hud/ubgl.png", "smooth" )
                    local whatsthecolor = self:GetInUBGL() and  Color(255, 255, 255, alpha) or
                                                        Color(255, 255, 255, 0)
                    local bar = {
                        w = size,
                        h = size,
                        x = apan_bg.x + apan_bg.w - airgap + ScreenScaleMulti(0+gonnapisspant) - size + woobie*items,
                        y = wmode.y + ScreenScaleMulti(gonnacry),
                    }
                    surface.SetDrawColor( whatsthecolor )
                    surface.SetMaterial( awesomematerial )
                    surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )
                    items = items + 1
                end

                if self:CanBipod() or self:GetInBipod() then
                    local size = ScreenScaleMulti(32)
                    local awesomematerial = Material( "hud/bipod.png", "smooth" )
                    local whatsthecolor =   self:GetInBipod() and     Color(255, 255, 255, alpha) or
                                            self:CanBipod() and   Color(255, 255, 255, alpha / 4) or Color(0, 0, 0, 0)
                    local bar = {
                        w = size,
                        h = size,
                        x = apan_bg.x + apan_bg.w - airgap - ScreenScaleMulti(32+gonnapisspant) + woobie*items,
                        y = wmode.y + ScreenScaleMulti(gonnacry),
                    }
                    surface.SetDrawColor( whatsthecolor )
                    surface.SetMaterial( awesomematerial )
                    surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )

                    local txt = string.upper(ArcCW:GetBind("+use"))

                    local bip = {
                        shadow = true,
                        x = apan_bg.x + apan_bg.w - airgap - ScreenScaleMulti(32+gonnapisspant) + woobie*items,
                        y = wmode.y + ScreenScaleMulti(gonnacry),
                        font = "ArcCW_12",
                        text = txt,
                        col = whatsthecolor,
                        alpha = alpha,
                    }

                    MyDrawText(bip)
                    items = items + 1
                end
            end
    elseif GetConVar("arccw_hud_minimal"):GetBool() then
        if !GetConVar("cl_drawhud"):GetBool() then return false end

            local segcount = string.len( self:GetFiremodeBars() or "-----" )

            local bar = {
                w = (ScreenScaleMulti(128) - ((segcount + 1) * bargap)) / segcount,
                h = ScreenScaleMulti(3),
                x = (ScrW() / 2) - ScreenScaleMulti(62),
                y = ScrH() - ScreenScaleMulti(24)
            }

            for i = 1, segcount do
                local c = data.bars[i]

                if c == "-" then
                    surface.SetDrawColor(col2)
                    surface.DrawRect(bar.x, bar.y, bar.w, bar.h)
                elseif c == "#" then
                    --surface.SetDrawColor(col2)
                    --surface.DrawRect(bar.x, bar.y, bar.w, bar.h)
                elseif c == "!" then
                    surface.SetDrawColor(col3)
                    surface.DrawRect(bar.x, bar.y, bar.w, bar.h)
                    surface.SetDrawColor(col2)
                    surface.DrawOutlinedRect(bar.x, bar.y, bar.w, bar.h)
                else
                    surface.SetDrawColor(col2)
                    surface.DrawOutlinedRect(bar.x, bar.y, bar.w, bar.h)
                end

                bar.x = bar.x + bar.w + bargap
            end

            surface.SetFont("ArcCW_12")
            local wmode = {
                x = (ScrW() / 2) - (surface.GetTextSize(data.mode) / 2),
                y = bar.y - ScreenScaleMulti(16),
                font = "ArcCW_12",
                text = data.mode,
                col = col2
            }

            MyDrawText(wmode)

            if self:GetBuff_Override("UBGL") then
                local size = ScreenScaleMulti(32)
                local awesomematerial = Material( "hud/ubgl.png", "smooth" )
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
                local awesomematerial = Material( "hud/bipod.png", "smooth" )
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
    end

    -- health + armor

    if ArcCW:ShouldDrawHUDElement("CHudHealth") then

        local colhp = Color(255, 255, 255, 255)

        if LocalPlayer():Health() <= 30 then
            colhp = col3
        end

        local whp = {
            x = airgap + CopeX(),
            y = ScrH() - ScreenScaleMulti(26+16) - airgap - CopeY(),
            font = "ArcCW_26",
            text = "HP " .. tostring(math.Round(vhp)),
            col = colhp,
            shadow = true
        }

        MyDrawText(whp)

        if LocalPlayer():Armor() > 0 then
            local war = {
                x = airgap + CopeX(),
                y = ScrH() - ScreenScaleMulti(16) - airgap - CopeY(),
                font = "ArcCW_16",
                text = "AP " .. tostring(math.Round(varmor)),
                col = col2,
                shadow = true
            }

            MyDrawText(war)
        end

    end

    vhp = math.Approach(vhp, self:GetOwner():Health(), FrameTime() * 100)
    varmor = math.Approach(varmor, self:GetOwner():Armor(), FrameTime() * 100)

    local clipdiff = math.abs(vclip - self:Clip1())
    local reservediff = math.abs(vreserve - self:Ammo1())

    if clipdiff == 1 then
        vclip = self:Clip1()
    end

    vclip = math.Approach(vclip, self:Clip1(), FrameTime() * 30 * clipdiff)
    vreserve = math.Approach(vreserve, self:Ammo1(), FrameTime() * 30 * reservediff)

    if lastwpn != self then
        vclip = self:Clip1()
        vreserve = self:Ammo1()
        vhp = self:GetOwner():Health()
        varmor = self:GetOwner():Armor()
    end

    lastwpn = self
end

function SWEP:CustomAmmoDisplay()
    local data = self:GetHUDData()
    self.AmmoDisplay = self.AmmoDisplay or {}

    self.AmmoDisplay.Draw = true -- draw the display?

    if self.Primary.ClipSize > 0 then
        local plus = data.plus or 0
        self.AmmoDisplay.PrimaryClip = data.clip + plus -- amount in clip
        self.AmmoDisplay.PrimaryAmmo = tonumber(data.ammo) -- amount in reserve
    end
    if true then
        local ubglammo = self:GetBuff_Override("UBGL_Ammo")
        if !ubglammo then return end
        self.AmmoDisplay.SecondaryAmmo = self:Clip2() + self:GetOwner():GetAmmoCount(ubglammo) -- amount of secondary ammo
    end

    return self.AmmoDisplay -- return the table
end