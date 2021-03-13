

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local function LerpColor(d, col1, col2)
    local r = Lerp(d, col1.r, col2.r)
    local g = Lerp(d, col1.g, col2.g)
    local b = Lerp(d, col1.b, col2.b)
    local a = Lerp(d, col1.a, col2.a)
    return Color(r, g, b, a)
end

local function DrawTextRot(span, txt, x, y, tx, ty, maxw, only)
    local tw, th = surface.GetTextSize(txt)

    if tw > maxw then
        local realx, realy = span:LocalToScreen(x, y)
        render.SetScissorRect(realx, realy, realx + maxw, realy + (th * 2), true)

        if !only then
            span.TextRot = span.TextRot or 0
            span.StartTextRot = span.StartTextRot or CurTime()
            span.TextRotState = span.TextRotState or 0 -- 0: start, 1: moving, 2: end
            if span.TextRotState == 0 then
                span.TextRot = 0
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 1
                end
            elseif span.TextRotState == 1 then
                span.TextRot = span.TextRot + (FrameTime() * ScreenScaleMulti(16))
                if span.TextRot >= (tw - maxw) + ScreenScaleMulti(8) then
                    span.StartTextRot = CurTime()
                    span.TextRotState = 2
                end
            elseif span.TextRotState == 2 then
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 0
                    span.StartTextRot = CurTime()
                end
            end
        end
        surface.SetTextPos(tx - span.TextRot, ty)
        surface.DrawText(txt)
        render.SetScissorRect(0, 0, 0, 0, false)
    else
        surface.DrawText(txt)
    end
end

local translate = ArcCW.GetTranslation
local defaultatticon = Material("hud/atts/default.png", "mips smooth")
local blockedatticon = Material("hud/atts/blocked.png", "mips smooth")

-- 1: Customize
-- 2: Presets
SWEP.Inv_SelectedMenu = 1

-- Selected inventory slot
SWEP.Inv_SelectedSlot = 0

-- 1: Stats
-- 2: Trivia
SWEP.Inv_SelectedInfo = 1

function SWEP:CreateCustomize2HUD()
    local col_fg = Color(255, 255, 255, 255)
    local col_fg_tr = Color(255, 255, 255, 125)
    local col_shadow = Color(0, 0, 0, 255)
    local col_button = Color(0, 0, 0, 175)

    local scrw, scrh = ScrW(), ScrH()
    if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
        -- Other resolutions seem to cause stretching issues
        scrw = 1366
        scrh = 768
    end

    ArcCW.InvHUD = vgui.Create("DFrame")

    local scrwmult = GetConVar("arccw_hud_deadzone_x"):GetFloat() * scrw
    local scrhmult = GetConVar("arccw_hud_deadzone_y"):GetFloat() * scrh

    local ss = (math.max(scrw, scrh) / 800) * GetConVar("arccw_hud_size"):GetFloat()
    local rss = ScreenScale(1)

    scrw, scrh = scrw - scrwmult, scrh - scrhmult

    local bar1_w = scrw / 4
    local bar2_w = scrw / 5
    local bar3_w = scrw / 2
    local airgap_x = ss * 24
    local airgap_y = ss * 24
    local smallgap = ss * 4

    local top_zone = ss * 24
    local bottom_zone = ss * 64

    local cornerrad = ss * 4

    local bigbuttonheight = ss * 36
    local smallbuttonheight = ss * 24

    local function PaintScrollBar(panel, w, h)
        local s = ss * 2
        draw.RoundedBox(ss * 1, (w - s) / 2, 0, s, h, col_fg)
    end

    ArcCW.InvHUD:SetPos(0, 0)
    ArcCW.InvHUD:SetSize(scrw, scrh)
    ArcCW.InvHUD:Center()
    ArcCW.InvHUD:SetText("")
    ArcCW.InvHUD:SetTitle("")
    ArcCW.InvHUD:ShowCloseButton(false)
    ArcCW.InvHUD.Paint = function(span)
        if !IsValid(self) then
            gui.EnableScreenClicker(false)
            span:Remove()
        end

        if --[[self:GetState() != ArcCW.STATE_CUSTOMIZE or]] self:GetReloading() then
            span:Remove()
        end
    end
    ArcCW.InvHUD.ActiveWeapon = self
    ArcCW.InvHUD.OnRemove = function()
        local close = false
        if self:IsValid() and self:GetState() == ArcCW.STATE_CUSTOMIZE then
            close = true
        end

        if LocalPlayer():GetActiveWeapon() != ArcCW.InvHUD.ActiveWeapon then
            close = true
        end

        if close then
            net.Start("arccw_togglecustomize")
            net.WriteBool(false)
            net.SendToServer()

            if IsValid(self) and self.ToggleCustomizeHUD then
                self:ToggleCustomizeHUD(false)
            end
        end

        gui.EnableScreenClicker(false)
    end

    if GetConVar("arccw_attinv_onlyinspect"):GetBool() then
        return
    end

    local menu1_w = bar1_w - airgap_x
    local menu1_h = scrh - (2 * airgap_y) - bottom_zone - top_zone

    local closebutton = vgui.Create("DButton", ArcCW.InvHUD)
    closebutton:SetText("")
    closebutton:SetPos(scrw - smallbuttonheight - airgap_x, smallgap)
    closebutton:SetSize(smallbuttonheight, bigbuttonheight)
    closebutton.Paint = function(self2, w, h)
        local col = col_fg

        if self2:IsHovered() then
            col = col_shadow
        end

        surface.SetTextColor(col_shadow)
        surface.SetTextPos(ss * 1, 0)
        surface.SetFont("ArcCW_24_Glow")
        surface.DrawText("x")

        surface.SetTextColor(col)
        surface.SetTextPos(ss * 1, 0)
        surface.SetFont("ArcCW_24")
        surface.DrawText("x")
    end
    closebutton.DoClick = function(self2, clr, btn)
        self:CloseCustomizeHUD()
    end

    local hidebutton = vgui.Create("DButton", ArcCW.InvHUD)
    hidebutton:SetText("")
    hidebutton:SetPos(scrw - smallbuttonheight * 2 - airgap_x, smallgap)
    hidebutton:SetSize(smallbuttonheight, bigbuttonheight)
    hidebutton.Paint = function(self2, w, h)
        local col = col_fg

        if self2:IsHovered() then
            col = col_shadow
        end

        surface.SetTextColor(col_shadow)
        surface.SetTextPos(ss * 1, ss * -4)
        surface.SetFont("ArcCW_24_Glow")
        surface.DrawText("_")

        surface.SetTextColor(col)
        surface.SetTextPos(ss * 1, ss * -4)
        surface.SetFont("ArcCW_24")
        surface.DrawText("_")
    end
    hidebutton.DoClick = function(self2, clr, btn)
        self:CloseCustomizeHUD(true)
    end

    -- Menu for attachment slots/presets
    ArcCW.InvHUD_Menu1 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu1:SetPos(airgap_x, airgap_y + top_zone)
    ArcCW.InvHUD_Menu1:SetSize(menu1_w, menu1_h)

    local scroll_1 = ArcCW.InvHUD_Menu1:GetVBar()
    scroll_1.Paint = function() end

    scroll_1.btnUp.Paint = function(span, w, h)
    end
    scroll_1.btnDown.Paint = function(span, w, h)
    end
    scroll_1.btnGrip.Paint = PaintScrollBar

    local menu2_x, menu2_y = ArcCW.InvHUD_Menu1:GetPos()
    menu2_x = menu2_x + ArcCW.InvHUD_Menu1:GetWide()
    local menu2_w = bar2_w
    local menu2_h = menu1_h

    -- Menu for attachments
    ArcCW.InvHUD_Menu2 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu2:SetPos(menu2_x, menu2_y)
    ArcCW.InvHUD_Menu2:SetSize(menu2_w, menu2_h)

    -- ArcCW.InvHUD_Menu2.Paint = function(self2, w, h)
    --     draw.RoundedBox(2, 0, 0, w, h, col_fg)
    -- end

    local scroll_2 = ArcCW.InvHUD_Menu2:GetVBar()
    scroll_2.Paint = function() end

    scroll_2.btnUp.Paint = function(span, w, h)
    end
    scroll_2.btnDown.Paint = function(span, w, h)
    end
    scroll_2.btnGrip.Paint = PaintScrollBar

    function ArcCW.InvHUD_FormAttachmentSelect(slot)
    end

    -- add attachments

    function ArcCW.InvHUD_FormAttachments()
        ArcCW.InvHUD_Menu1:Clear()
        for i, slot in pairs(self.Attachments) do
            if !istable(slot) then continue end
            if !slot.PrintName then continue end
            if i == "BaseClass" then continue end
            if slot.Hidden or slot.Blacklisted then continue end
            if slot.Integral then continue end

            local button = vgui.Create("DButton", ArcCW.InvHUD_Menu1)
            button.attindex = i
            button:SetText("")
            button:SetSize(menu1_w, bigbuttonheight)
            button:DockMargin(0, smallgap, 0, 0)
            button:Dock(TOP)
            button.DoClick = function(self2, clr, btn)
                self.Inv_SelectedSlot = self2.attindex
            end
            button.Paint = function(self2, w, h)
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() or self.Inv_SelectedSlot == self2.attindex then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local att_icon = defaultatticon
                local txt = translate("attslot.noatt")
                local atttbl = ArcCW.AttachmentTable[slot.Installed or ""]

                if atttbl then
                    txt =  translate("name." .. slot.Installed) or atttbl.PrintName
                    att_icon = atttbl.Icon
                end

                surface.SetDrawColor(col2)
                local icon_h = h
                surface.SetMaterial(att_icon)
                surface.DrawTexturedRect(w - icon_h, 0, icon_h, icon_h)

                surface.SetTextColor(col2)
                surface.SetFont("ArcCW_10")
                surface.SetTextPos(ss * 6, ss * 4)
                surface.DrawText(slot.PrintName)

                surface.SetFont("ArcCW_14")
                surface.SetTextPos(ss * 6, ss * 14)
                DrawTextRot(self2, txt, 0, 0, ss * 6, ss * 14, w - icon_h - ss * 2)
            end
        end
    end

    ArcCW.InvHUD_FormAttachments()

    local menu3_h = scrh - airgap_y - bottom_zone
    local menu3_w = bar3_w

    -- weapon details
    ArcCW.InvHUD_Menu3 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu3:SetPos(scrw - menu3_w, airgap_y + smallgap)
    ArcCW.InvHUD_Menu3:SetSize(menu3_w, menu3_h)

    function ArcCW.InvHUD_FormWeaponName()
        local weapon_title = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        weapon_title:SetSize(menu3_w, rss * 32)
        weapon_title:SetPos(0, 0)
        weapon_title.Paint = function(self2, w, h)
            local name = translate("name." .. self:GetClass() .. (GetConVar("arccw_truenames"):GetBool() and ".true" or "")) or translate(self.PrintName) or self.PrintName

            surface.SetFont("ArcCW_32")
            local tw = surface.GetTextSize(name)

            surface.SetTextColor(col_shadow)
            surface.SetFont("ArcCW_32_Glow")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x)

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCW_32")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x, true)
        end

        local weapon_cat = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        weapon_cat:SetSize(menu3_w, rss * 16)
        weapon_cat:SetPos(0, rss * 32)
        weapon_cat.Paint = function(self2, w, h)
            local class = translate(self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class) or self.Trivia_Class
            local cal = translate(self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre) or self.Trivia_Calibre
            local name = class .. ", " .. cal

            surface.SetFont("ArcCW_16")
            local tw = surface.GetTextSize(name)

            surface.SetTextColor(col_shadow)
            surface.SetFont("ArcCW_16_Glow")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x)

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCW_16")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x, true)
        end
    end

    function ArcCW.InvHUD_FormWeaponStats()
        ArcCW.InvHUD_Menu3:Clear()
        ArcCW.InvHUD_FormWeaponName()

        local rangegraph = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        rangegraph:SetSize(ss * 200, ss * 110)
        rangegraph:SetPos(menu3_w - ss * 200 - airgap_x, rss * 48 + ss * 32)
        rangegraph.Paint = function(self2, w, h)
            local ovr = self:GetBuff_Override("Override_Num")
            local add = self:GetBuff_Add("Add_Num")

            local num = self.Num
            local nbr = (ovr or num) + add
            local mul = 1

            mul = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num != nbr) and (num / nbr)) or 1

            if !pellet then mul = mul * nbr end

            local dmgmax = self:GetBuff("Damage") * mul
            local dmgmin = self:GetBuff("DamageMin") * mul

            local mran = (self.RangeMin or 0) * self:GetBuff_Mult("Mult_RangeMin")
            local sran = self.Range * self:GetBuff_Mult("Mult_Range")

            local scale = math.ceil((math.max(dmgmax, dmgmin) + 10) / 25) * 25
            local hscale = math.ceil(math.max(mran, sran) / 100) * 100

            scale = math.max(scale, 100)
            hscale = math.max(hscale, 100)

            draw.RoundedBox(cornerrad, 0, 0, w, h, col_button)

            local thicc = math.ceil(ss * 1)

            // segment 1: minimum range
            local x_1 = 0
            local y_1 = h - (dmgmax / scale * h)
            y_1 = math.Clamp(y_1, ss * 16, h - (ss * 16))
            // segment 2: slope
            local x_2 = 0
            local y_2 = y_1
            if mran > 0 then
                x_2 = w * 1 / 3
            end
            // segment 3: maximum range
            local x_3 = w * 2 / 3
            local y_3 = h - (dmgmin / scale * h)
            y_3 = math.Clamp(y_3, ss * 16, h - (ss * 16))

            local x_4 = w
            local y_4 = y_3

            local col_vline = LerpColor(0.5, col_fg, Color(0, 0, 0, 0))

            surface.SetDrawColor(col_vline)

            // line for min range
            if dmgmax != dmgmin and mran > 0 then
                surface.DrawLine(x_2, 0, x_2, h)
            end

            // line for max range
            if dmgmax != dmgmin then
                surface.DrawLine(x_3, 0, x_3, h)
            end

            // damage number text

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCW_8")

            local function RangeText(range)
                local metres = tostring(math.Round(range)) .. "m"
                local hu = tostring(math.Round(range / ArcCW.HUToM)) .. "HU"

                return metres, hu
            end

            local m_1, hu_1 = RangeText(0)

            surface.SetTextPos(ss * 2, h - rss * 16)
            surface.DrawText(m_1)
            surface.SetTextPos(ss * 2, h - rss * 10)
            surface.DrawText(hu_1)

            local drawndmg = false

            if dmgmax != dmgmin and mran > 0 then
                local dmg = tostring(math.Round(dmgmax))
                local tw = surface.GetTextSize(dmg)
                surface.SetTextPos(x_2 - (tw / 2), ss * 1)
                surface.DrawText(dmg)

                local m_2, hu_2 = RangeText(mran)

                surface.SetTextPos(x_2, h - rss * 16)
                surface.DrawText(m_2)
                surface.SetTextPos(x_2, h - rss * 10)
                surface.DrawText(hu_2)

                local dmgt = tostring("DMG")
                local twt = surface.GetTextSize(dmgt)
                surface.SetTextPos(x_2 - (twt / 2), ss * 8)
                surface.DrawText(dmgt)

                drawndmg = true
            end

            if dmgmax != dmgmin then
                local dmg = tostring(math.Round(dmgmin))
                local tw = surface.GetTextSize(dmg)
                surface.SetTextPos(x_3 - (tw / 2), ss * 1)
                surface.DrawText(dmg)

                local m_3, hu_3 = RangeText(sran)

                surface.SetTextPos(x_3, h - rss * 16)
                surface.DrawText(m_3)
                surface.SetTextPos(x_3, h - rss * 10)
                surface.DrawText(hu_3)

                local dmgt = tostring("DMG")
                local twt = surface.GetTextSize(dmgt)
                surface.SetTextPos(x_3 - (twt / 2), ss * 8)
                surface.DrawText(dmgt)
            end

            if !drawndmg then
                local dmg = tostring(math.Round(dmgmax))
                surface.SetTextPos(ss * 2, ss * 1)
                surface.DrawText(dmg)

                local dmgt = tostring("DMG")
                surface.SetTextPos(ss * 2, ss * 8)
                surface.DrawText(dmgt)
            end

            for i = 1, thicc do

                surface.SetDrawColor(col_fg)

                if mran > 0 then
                    // draw seg 1
                    surface.DrawLine(x_1, y_1 + i, x_2, y_2 + i)
                end
                // draw seg 2
                surface.DrawLine(x_2, y_2 + i, x_3, y_3 + i)
                // drag seg 3
                surface.DrawLine(x_3, y_3 + i, x_4, y_4 + i)
            end
        end
    end

    ArcCW.InvHUD_FormWeaponStats()

end