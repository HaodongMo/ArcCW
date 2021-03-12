

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
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
local defaultatticon = Material("hud/atts/default.png", "mips")
local blockedatticon = Material("hud/atts/blocked.png", "mips")

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

    scrw, scrh = scrw - scrwmult, scrh - scrhmult

    local bar1_w = scrw / 4
    local bar2_w = scrw / 5
    local bar3_w = scrw / 2.5
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
    closebutton:SetPos(scrw - bigbuttonheight - airgap_x, airgap_y)
    closebutton:SetSize(bigbuttonheight, bigbuttonheight)
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

    -- add attachments

    local function FormAttachments()
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
                surface.DrawTexturedRect(w - icon_h - (ss * 2), 0, icon_h, icon_h)

                surface.SetTextColor(col2)
                surface.SetFont("ArcCW_10")
                surface.SetTextPos(ss * 6, ss * 4)
                surface.DrawText(slot.PrintName)

                surface.SetFont("ArcCW_14")
                surface.SetTextPos(ss * 6, ss * 14)
                DrawTextRot(self2, txt, 0, 0, ss * 6, ss * 14, w)
            end
        end
    end

    FormAttachments()

end