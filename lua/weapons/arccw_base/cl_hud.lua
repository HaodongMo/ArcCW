

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
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
        mode = self:GetFiremodeName()
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

    data = self:GetBuff_Hook("Hook_GetHUDData", data) or data

    return data
end

function SWEP:DrawHUD()

    -- info panel

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

    if self:CanBipod() or self:GetInBipod() then
        local txt = "[" .. string.upper(ArcCW:GetBind("+use")) .. "]"

        if self:InBipod() then
            txt = txt .. " Retract Bipod"
        else
            txt = txt .. " Deploy Bipod"
        end

        local bip = {
            shadow = true,
            x = ScrW() / 2,
            y = (ScrH() / 2) + ScreenScaleMulti(36),
            font = "ArcCW_12",
            text = txt,
            col = col2,
            align = 2
        }

        MyDrawText(bip)
    end

    if self:GetHeatLocked() then
        col2 = col3
    end

    local data = self:GetHUDData()

    if ArcCW:ShouldDrawHUDElement("CHudAmmo") then

        local curTime = CurTime()
        local mode = self:GetFiremodeName()

        local muzz = self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1

        local yuriewantsbabynapnaptimewaawaawaaa = GetConVar("arccw_hud_3dfun"):GetBool()

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

        if yuriewantsbabynapnaptimewaawaawaaa and muzz and angpos then

            local visible = (lastinfotime + 4 > curTime or lastinfotime - 0.5 > curTime)

            -- Detect changes to stuff drawn in HUD
            local curInfo = {ammo = data.ammo, clip = data.clip, plus = data.plus, firemode = data.mode, heat = self:GetHeat()}
            for i, v in pairs(curInfo) do
                if v != lastinfo[i] then
                    lastinfotime = visible and (curTime - 0.5) or curTime
                    lastinfo = curInfo
                    break
                end
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

                cam.Start3D()
                    local toscreen = angpos.Pos:ToScreen()
                cam.End3D()

                apan_bg.x = toscreen.x - apan_bg.w - ScreenScaleMulti(8)
                apan_bg.y = toscreen.y - apan_bg.h * 0.5

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

                if self:HeatEnabled() then
                    local wheat = {
                        x = apan_bg.x + apan_bg.w - airgap,
                        y = wmode.y + ScreenScaleMulti(14),
                        font = "ArcCW_12",
                        text = "HEAT " .. tostring(math.ceil(100 * self:GetHeat() / self:GetMaxHeat())) .. "%",
                        col = col2,
                        align = 1,
                        shadow = true,
                        alpha = alpha,
                    }
                    MyDrawText(wheat)
                end

            end
        else

            apan_bg.x = ScrW() - apan_bg.w - airgap - ScreenScaleMulti( GetConVar("arccw_hud_deadzone_x"):GetFloat() * 320 )
            apan_bg.y = ScrH() - apan_bg.h - airgap - ScreenScaleMulti( GetConVar("arccw_hud_deadzone_y"):GetFloat() * 240 )

            surface.SetDrawColor(col1)
            surface.DrawRect(apan_bg.x, apan_bg.y, apan_bg.w, apan_bg.h)

            local segcount = string.len( self:GetFiremodeBars() or "-----" )

            local bar = {
                w = (apan_bg.w - ((segcount + 1) * bargap)) / segcount,
                h = ScreenScaleMulti(3),
                x = apan_bg.x + bargap,
                y = apan_bg.y + ScreenScaleMulti(14)
            }

            for i = 1, segcount do
                local c = data.bars[i]

                surface.SetDrawColor(col2)

                if c == "-" then
                    surface.DrawRect(bar.x, bar.y, bar.w, bar.h)
                else
                    surface.DrawOutlinedRect(bar.x, bar.y, bar.w, bar.h)
                end

                bar.x = bar.x + bar.w + bargap
            end

            surface.SetFont("ArcCW_12")
            local wname = {
                x = apan_bg.x + ScreenScaleMulti(4),
                y = apan_bg.y,
                font = "ArcCW_12",
                text = self.PrintName,
                col = col2
            }

            MyDrawText(wname)

            surface.SetFont("ArcCW_12")
            local wmode = {
                x = apan_bg.x + apan_bg.w - ScreenScaleMulti(4) - surface.GetTextSize(mode),
                y = apan_bg.y,
                font = "ArcCW_12",
                text = data.mode,
                col = col2
            }

            MyDrawText(wmode)
			
			if self:GetBuff_Override("UBGL") then
				local size = ScreenScaleMulti(32)
				local awesomematerial = Material( "hud/ubgl.png", "smooth" )
				local whatsthecolor = self:GetInUBGL() and Color(255, 255, 255, 255) or Color(255, 255, 255, 0)
				local bar = {
					w = size,
					h = size,
					x = apan_bg.x - size - ScreenScaleMulti(8),
					y = apan_bg.y + apan_bg.h - size,
				}
				surface.SetDrawColor( whatsthecolor )
				surface.SetMaterial( awesomematerial )
				surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )
			end
			
			if self:GetBuff_Override("Bipod") or self.Bipod_Integral then
				local size = ScreenScaleMulti(32)
				local awesomematerial = Material( "hud/bipod.png", "smooth" )
				local whatsthecolor = self:GetInBipod() and Color(255, 255, 255, 255) or Color(255, 255, 255, 0)
				local bar = {
					w = size,
					h = size,
					x = apan_bg.x - size - ScreenScaleMulti(8),
					y = apan_bg.y,
				}
				surface.SetDrawColor( whatsthecolor )
				surface.SetMaterial( awesomematerial )
				surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )
			end

            surface.SetFont("ArcCW_26")
            local wammo = {
                x = apan_bg.x + airgap,
                y = bar.y + ScreenScaleMulti(4),
                text = tostring(data.clip),
                font = "ArcCW_26",
                col = col2
            }

            wammo.col = col2

            if data.clip == 0 then
                wammo.col = col3
            end

            MyDrawText(wammo)

            surface.SetFont("ArcCW_26")
            local wreserve = {
                x = apan_bg.x + ScreenScaleMulti(64) - airgap,
                y = bar.y + ScreenScaleMulti(4),
                text = "/ " .. tostring(data.ammo),
                font = "ArcCW_26",
                col = col2,
            }

            MyDrawText(wreserve)

            wammo.w = surface.GetTextSize(tostring(data.clip))

            surface.SetFont("ArcCW_16")
            if data.plus then
                local wplus = {
                    x = wammo.x + bargap + wammo.w,
                    y = wammo.y,
                    text = "+" .. tostring(data.plus),
                    font = "ArcCW_16",
                    col = col2
                }

                MyDrawText(wplus)
            end

            if self:HeatEnabled() then
                local heat_bg = {
                    x = apan_bg.x,
                    w = apan_bg.w,
                    h = ScreenScaleMulti(14)
                }

                heat_bg.y = apan_bg.y - heat_bg.h - ScreenScaleMulti(2)
                surface.SetDrawColor(col1)
                surface.DrawRect(heat_bg.x, heat_bg.y, heat_bg.w, heat_bg.h)

                local theat = {
                    x = heat_bg.x + ScreenScaleMulti(2),
                    y = heat_bg.y,
                    text = "HEAT [",
                    font = "ArcCW_12",
                    col = col2
                }

                MyDrawText(theat)

                local eheat = {
                    x = heat_bg.x + heat_bg.w - ScreenScaleMulti(4),
                    y = heat_bg.y,
                    text = "]",
                    font = "ArcCW_12",
                    col = col2
                }

                MyDrawText(eheat)

                local heat_bar = {
                    x = heat_bg.x + ScreenScaleMulti(33),
                    y = heat_bg.y + ScreenScaleMulti(4),
                    h = heat_bg.h - ScreenScaleMulti(8),
                    w = heat_bg.w - ScreenScaleMulti(38)
                }

                local perc = self:GetHeat() / self:GetMaxHeat()

                heat_bar.w = heat_bar.w * perc

                surface.SetDrawColor(col2)
                surface.DrawRect(heat_bar.x, heat_bar.y, heat_bar.w, heat_bar.h)
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
            x = airgap + ScreenScaleMulti( GetConVar("arccw_hud_deadzone_x"):GetFloat() * 320 ),
            y = ScrH() - ScreenScaleMulti(26) - ScreenScaleMulti(16) - airgap - ScreenScaleMulti( GetConVar("arccw_hud_deadzone_y"):GetFloat() * 240 ),
            font = "ArcCW_26",
            text = "HP: " .. tostring(math.Round(vhp)),
            col = colhp,
            shadow = true
        }

        MyDrawText(whp)

        if LocalPlayer():Armor() > 0 then
            local war = {
                x = airgap + ScreenScaleMulti( GetConVar("arccw_hud_deadzone_x"):GetFloat() * 320 ),
                y = ScrH() - ScreenScaleMulti(16) - airgap - ScreenScaleMulti( GetConVar("arccw_hud_deadzone_y"):GetFloat() * 240 ),
                font = "ArcCW_16",
                text = "ARMOR: " .. tostring(math.Round(varmor)),
                col = col2,
                shadow = true
            }

            MyDrawText(war)
        end

    end

    vhp = math.Approach(vhp, self:GetOwner():Health(), RealFrameTime() * 100)
    varmor = math.Approach(varmor, self:GetOwner():Armor(), RealFrameTime() * 100)

    local clipdiff = math.abs(vclip - self:Clip1())
    local reservediff = math.abs(vreserve - self:Ammo1())

    if clipdiff == 1 then
        vclip = self:Clip1()
    end

    vclip = math.Approach(vclip, self:Clip1(), RealFrameTime() * 30 * clipdiff)
    vreserve = math.Approach(vreserve, self:Ammo1(), RealFrameTime() * 30 * reservediff)

    if lastwpn != self then
        vclip = self:Clip1()
        vreserve = self:Ammo1()
        vhp = self:GetOwner():Health()
        varmor = self:GetOwner():Armor()
    end

    lastwpn = self
end