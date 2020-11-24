

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local function CopeX()
    return ScreenScaleMulti( GetConVar("arccw_hud_deadzone_x"):GetFloat() * 320 )
end

local function CopeY()
    return ScreenScaleMulti( GetConVar("arccw_hud_deadzone_y"):GetFloat() * 240 )
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

    --[[if self:CanBipod() or self:GetInBipod() then
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
    end]]

    local data = self:GetHUDData()

    if data.heat_locked then
        col2 = col3
    end

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
            local curInfo = {
				ammo = data.ammo,
				clip = data.clip,
				plus = data.plus,
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
				angpos.Pos = angpos.Pos - EyeAng:Up() * 5 - EyeAng:Right() * 4

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

                if data.heat_enabled then
                    local wheat = {
                        x = apan_bg.x + apan_bg.w - airgap,
                        y = wmode.y + ScreenScaleMulti(14),
                        font = "ArcCW_12",
                        text = data.heat_name .. " " .. tostring(math.ceil(100 * data.heat_level / data.heat_maxlevel)) .. "%",
                        col = col2,
                        align = 1,
                        shadow = true,
                        alpha = alpha,
                    }
                    MyDrawText(wheat)
                end
                if self:GetBuff_Override("UBGL") then
                    local size = ScreenScaleMulti(32)
                    local awesomematerial = Material( "hud/ubgl.png", "smooth" )
                    local whatsthecolor = self:GetInUBGL() and  Color(255, 255, 255, alpha) or
                                                        Color(255, 255, 255, 0)
                    local bar = {
                        w = size,
                        h = size,
                        x = apan_bg.x + apan_bg.w - airgap - size,
                        y = wmode.y + ScreenScaleMulti(14),
                    }
                    surface.SetDrawColor( whatsthecolor )
                    surface.SetMaterial( awesomematerial )
                    surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )
                end
                
                if self:CanBipod() or self:GetInBipod() then
                    local size = ScreenScaleMulti(32)
                    local awesomematerial = Material( "hud/bipod.png", "smooth" )
                    local whatsthecolor =   self:GetInBipod() and     Color(255, 255, 255, alpha) or
                                            self:CanBipod() and   Color(255, 255, 255, alpha/2) or
                                                                    Color(255, 255, 255, 0)
                    local bar = {
                        w = size,
                        h = size,
                        x = apan_bg.x + apan_bg.w - airgap - ScreenScaleMulti(32) - (self:GetInUBGL() and ScreenScaleMulti(32) or 0),
                        y = wmode.y + ScreenScaleMulti(14),
                    }
                    surface.SetDrawColor( whatsthecolor )
                    surface.SetMaterial( awesomematerial )
                    surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )

                    local txt = string.upper(ArcCW:GetBind("+use"))

                    local bip = {
                        shadow = true,
                        x = apan_bg.x + apan_bg.w - airgap - ScreenScaleMulti(32) - (self:GetInUBGL() and ScreenScaleMulti(32) or 0),
                        y = wmode.y + ScreenScaleMulti(14),
                        font = "ArcCW_12",
                        text = txt,
                        col = whatsthecolor,
                        alpha = alpha,
                    }

                    MyDrawText(bip)
                end
            end
        else

            apan_bg.x = ScrW() - apan_bg.w - airgap - CopeX()
            apan_bg.y = ScrH() - apan_bg.h - airgap - CopeY()

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
				local whatsthecolor = self:GetInUBGL() and  Color(255, 255, 255, 255) or
                                                       Color(255, 255, 255, 0)
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
			
			if self:CanBipod() or self:GetInBipod() then
				local size = ScreenScaleMulti(32)
				local awesomematerial = Material( "hud/bipod.png", "smooth" )
				local whatsthecolor =   self:GetInBipod() and   Color(255, 255, 255, 255) or
                                        self:CanBipod() and     Color(255, 255, 255, 127) or
                                                                Color(255, 255, 255, 0)
				local bar = {
					w = size,
					h = size,
					x = apan_bg.x - size - ScreenScaleMulti(8) - (self:GetInUBGL() and ScreenScaleMulti(32) or 0),
					y = apan_bg.y + apan_bg.h - size,
				}
				surface.SetDrawColor( whatsthecolor )
				surface.SetMaterial( awesomematerial )
				surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )

                local txt = string.upper(ArcCW:GetBind("+use"))

                local bip = {
                    shadow = true,
                    x = apan_bg.x - size - ScreenScaleMulti(8) - (self:GetInUBGL() and ScreenScaleMulti(32) or 0),
                    y = apan_bg.y + apan_bg.h - size,
                    font = "ArcCW_12",
                    text = txt,
                    col = whatsthecolor,
                }

                MyDrawText(bip)
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

            if data.heat_enabled then
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
                    text = data.heat_name .. " [",
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

                local perc = data.heat_level / data.heat_maxlevel

                heat_bar.w = heat_bar.w * perc

                surface.SetDrawColor(col2)
                surface.DrawRect(heat_bar.x, heat_bar.y, heat_bar.w, heat_bar.h)
            end

        end

    elseif GetConVar("arccw_hud_minimal"):GetBool() then

            local segcount = string.len( self:GetFiremodeBars() or "-----" )

            local bar = {
                w = (ScreenScaleMulti(128) - ((segcount + 1) * bargap)) / segcount,
                h = ScreenScaleMulti(3),
                x = (ScrW()/2) - ScreenScaleMulti(62),
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
                x = (ScrW()/2) - (surface.GetTextSize(data.mode)/2),
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
				local bar = {
					w = size,
					h = size,
					x = ScrW()/2 + ScreenScaleMulti(32),
					y = ScrH() - ScreenScaleMulti(52),
				}
				surface.SetDrawColor( whatsthecolor )
				surface.SetMaterial( awesomematerial )
				surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )
			end
			
			if self:CanBipod() or self:GetInBipod() then
				local size = ScreenScaleMulti(32)
				local awesomematerial = Material( "hud/bipod.png", "smooth" )
				local whatsthecolor =   self:GetInBipod() and   Color(255, 255, 255, 255) or
                                        self:CanBipod() and     Color(255, 255, 255, 127) or
                                                                Color(255, 255, 255, 0)
				local bar = {
					w = size,
					h = size,
					x = ScrW()/2 - ScreenScaleMulti(64),
					y = ScrH() - ScreenScaleMulti(52),
				}
				surface.SetDrawColor( whatsthecolor )
				surface.SetMaterial( awesomematerial )
				surface.DrawTexturedRect( bar.x, bar.y, bar.w, bar.h )

                local txt = string.upper(ArcCW:GetBind("+use"))

                local bip = {
                    shadow = true,
					x = ScrW()/2 - ScreenScaleMulti(64),
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

                surface.DrawOutlinedRect(ScrW()/2 - ScreenScaleMulti(62), bar.y + ScreenScaleMulti(4.5), ScreenScaleMulti(124), ScreenScaleMulti(3))
                surface.DrawRect(ScrW()/2 - ScreenScaleMulti(62), bar.y + ScreenScaleMulti(4.5), ScreenScaleMulti(124) * perc, ScreenScaleMulti(3))

                surface.SetFont("ArcCW_8")
                local bip = {
                    shadow = false,
					x = (ScrW()/2) - (surface.GetTextSize(data.heat_name)/2),
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

        if LocalPlayer():Health() <= 30 then
            colhp = col3
        end

        local whp = {
            x = airgap + CopeX(),
            y = ScrH() - ScreenScaleMulti(26) - ScreenScaleMulti(16) - airgap - CopeY(),
            font = "ArcCW_26",
            text = "HP: " .. tostring(math.Round(vhp)),
            col = colhp,
            shadow = true
        }

        MyDrawText(whp)

        if LocalPlayer():Armor() > 0 then
            local war = {
                x = airgap + CopeX(),
                y = ScrH() - ScreenScaleMulti(16) - airgap - CopeY(),
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

function SWEP:CustomAmmoDisplay()
    local data = self:GetHUDData()
	self.AmmoDisplay = self.AmmoDisplay or {} 
 
	self.AmmoDisplay.Draw = true -- draw the display?
 
	if self.Primary.ClipSize > 0 or self:GetInUBGL() then
		self.AmmoDisplay.PrimaryClip = data.clip -- amount in clip
		self.AmmoDisplay.PrimaryAmmo = tonumber(data.ammo) -- amount in reserve
	end
	--[[if self.Secondary.ClipSize > 0 then
		self.AmmoDisplay.SecondaryAmmo = self:Clip2() + self:Ammo2() -- amount of secondary ammo
	end]]
 
	return self.AmmoDisplay -- return the table
end