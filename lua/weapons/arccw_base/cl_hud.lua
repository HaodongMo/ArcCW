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

function SWEP:DrawHUD()
    -- info panel

    local col1 = Color(0, 0, 0, 100)
    local col2 = Color(255, 255, 255, 255)
    local col3 = Color(255, 0, 0, 255)

    local airgap = ScreenScale(8)

    local apan_bg = {
        w = ScreenScale(128),
        h = ScreenScale(48),
    }

    local bargap = ScreenScale(2)

    if self:CanBipod() then
        local txt = "[" .. string.upper(ArcCW:GetBind("+use")) .. "]"

        if self:InBipod() then
            txt = txt .. " Retract Bipod"
        else
            txt = txt .. " Deploy Bipod"
        end

        local bip = {
            shadow = true,
            x = ScrW() / 2,
            y = (ScrH() / 2) + ScreenScale(36),
            font = "ArcCW_12",
            text = txt,
            col = col2,
            align = 2
        }

        MyDrawText(bip)
    end

    if ArcCW:ShouldDrawHUDElement("CHudAmmo") then

        local curTime = CurTime()
        local ammo = math.Round(vreserve)
        local clip = math.Round(vclip)
        local plus = 0
        local mode = self:GetFiremodeName()

        if clip > self:GetCapacity() then
            plus = clip - self:GetCapacity()
            clip = clip - plus
        end

        local muzz = self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1

        local yuriewantsbabynapnaptimewaawaawaaa = GetConVar("arccw_hud_3dfun"):GetBool()

        local vm = self.Owner:GetViewModel()

        local angpos

        if vm and vm:IsValid() then
            angpos = vm:GetAttachment(muzz)
        end

        if yuriewantsbabynapnaptimewaawaawaaa and muzz and angpos then

            local visible = (lastinfotime + 4 > curTime or lastinfotime - 0.5 > curTime)

            -- Detect changes to stuff drawn in HUD
            local curInfo = {ammo = ammo, clip = clip, plus = plus, firemode = mode}
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

                apan_bg.x = toscreen.x - apan_bg.w - ScreenScale(8)
                apan_bg.y = toscreen.y - apan_bg.h * 0.5

                if self.PrimaryBash or self:Clip1() == -1 or self:GetCapacity() == 0 or self.Primary.ClipSize == -1 then
                    clip = "-"
                end

                local wammo = {
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = apan_bg.y,
                    text = tostring(clip),
                    font = "ArcCW_26",
                    col = col2,
                    align = 1,
                    shadow = true,
                    alpha = alpha,
                }

                wammo.col = col2

                if self:Clip1() == 0 then
                    wammo.col = col3
                end

                if self:GetNWBool("ubgl") then
                    wammo.col = col2
                    wammo.text = self:Clip2()
                end

                MyDrawText(wammo)
                wammo.w, wammo.h = surface.GetTextSize(wammo.text)

                if plus > 0 and !self:GetNWBool("ubgl") then
                    local wplus = {
                        x = wammo.x,
                        y = wammo.y,
                        text = "+" .. tostring(plus),
                        font = "ArcCW_16",
                        col = col2,
                        shadow = true,
                        alpha = alpha,
                    }

                    MyDrawText(wplus)
                end


                local wreserve = {
                    x = wammo.x - wammo.w - ScreenScale(4),
                    y = apan_bg.y + ScreenScale(26 - 12),
                    text = tostring(ammo) .. " /",
                    font = "ArcCW_12",
                    col = col2,
                    align = 1,
                    yalign = 2,
                    shadow = true,
                    alpha = alpha,
                }

                if self:GetNWBool("ubgl") then
                    local ubglammo = self:GetBuff_Override("UBGL_Ammo")

                    if ubglammo then
                        wreserve.text = tostring(self:GetOwner():GetAmmoCount(ubglammo)) .. " /"
                    end
                end

                if self.PrimaryBash then
                    wreserve.text = ""
                end

                MyDrawText(wreserve)
                wreserve.w, wreserve.h = surface.GetTextSize(wreserve.text)

                local wmode = {
                    x = apan_bg.x + apan_bg.w - airgap,
                    y = wammo.y + wammo.h,
                    font = "ArcCW_12",
                    text = mode,
                    col = col2,
                    align = 1,
                    shadow = true,
                    alpha = alpha,
                }
                MyDrawText(wmode)

            end
        else

            apan_bg.x = ScrW() - apan_bg.w - airgap
            apan_bg.y = ScrH() - apan_bg.h - airgap

            surface.SetDrawColor(col1)
            surface.DrawRect(apan_bg.x, apan_bg.y, apan_bg.w, apan_bg.h)

            local bar = {
                w = (apan_bg.w - (6 * bargap)) / 5,
                h = ScreenScale(3),
                x = apan_bg.x + bargap,
                y = apan_bg.y + ScreenScale(14)
            }

            local bars = self:GetFiremodeBars()

            for i = 1, 5 do
                local c = bars[i]

                surface.SetDrawColor(col2)

                if c == "-" then
                    surface.DrawRect(bar.x, bar.y, bar.w, bar.h)
                else
                    surface.DrawOutlinedRect(bar.x, bar.y, bar.w, bar.h)
                end

                bar.x = bar.x + bar.w + bargap
            end

            local wname = {
                x = apan_bg.x + ScreenScale(4),
                y = apan_bg.y,
                font = "ArcCW_12",
                text = self.PrintName,
                col = col2
            }

            MyDrawText(wname)

            local wmode = {
                x = apan_bg.x + apan_bg.w - ScreenScale(4) - surface.GetTextSize(mode),
                y = apan_bg.y,
                font = "ArcCW_12",
                text = mode,
                col = col2
            }

            MyDrawText(wmode)

            if self.PrimaryBash or self:Clip1() == -1 or self:GetCapacity() == 0 or self.Primary.ClipSize == -1 then
                clip = "-"
            end

            local wammo = {
                x = apan_bg.x + airgap,
                y = bar.y + ScreenScale(4),
                text = tostring(clip),
                font = "ArcCW_26",
                col = col2
            }

            wammo.col = col2

            if self:Clip1() == 0 then
                wammo.col = col3
            end

            if self:GetNWBool("ubgl") then
                wammo.col = col2
                wammo.text = self:Clip2()
            end

            MyDrawText(wammo)

            local wreserve = {
                x = apan_bg.x + ScreenScale(64) - airgap,
                y = bar.y + ScreenScale(4),
                text = "/ " .. tostring(ammo),
                font = "ArcCW_26",
                col = col2,
            }

            if self:GetNWBool("ubgl") then
                local ubglammo = self:GetBuff_Override("UBGL_Ammo")

                if ubglammo then
                    wreserve.text = "/ " .. tostring(self:GetOwner():GetAmmoCount(ubglammo))
                end
            end

            if self.PrimaryBash then
                wreserve.text = "/ -"
            end

            MyDrawText(wreserve)

            wammo.w = surface.GetTextSize(tostring(clip))

            if plus > 0 and !self:GetNWBool("ubgl") then
                local wplus = {
                    x = wammo.x + bargap + wammo.w,
                    y = wammo.y,
                    text = "+" .. tostring(plus),
                    font = "ArcCW_16",
                    col = col2
                }

                MyDrawText(wplus)
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
            x = airgap,
            y = ScrH() - ScreenScale(26) - ScreenScale(16) - airgap,
            font = "ArcCW_26",
            text = "HP: " .. tostring(math.Round(vhp)),
            col = colhp,
            shadow = true
        }

        MyDrawText(whp)

        if LocalPlayer():Armor() > 0 then
            local war = {
                x = airgap,
                y = ScrH() - ScreenScale(16) - airgap,
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