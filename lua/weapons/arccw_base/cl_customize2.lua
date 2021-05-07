

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local function multlinetext(text, maxw, font)
    local content = {}
    local tline = ""
    local x = 0
    surface.SetFont(font)

    local newlined = string.Split(text, "\n")

    for _, line in pairs(newlined) do
        local words = string.Split(line, " ")

        for _, word in pairs(words) do
            local tx = surface.GetTextSize(word)

            if x + tx >= maxw then
                table.insert(content, tline)
                tline = ""
                x = surface.GetTextSize(word)
            end

            tline = tline .. word .. " "

            x = x + surface.GetTextSize(word .. " ")
        end

        table.insert(content, tline)
        tline = ""
        x = 0
    end

    return content
end

function SWEP:ShowInventoryButton()
    if GetConVar("arccw_attinv_free"):GetBool() then return false end
    --if GetConVar("arccw_attinv_lockmode"):GetBool() then return false end
    if !GetConVar("arccw_enable_dropping"):GetBool() then return false end

    return true
end

function SWEP:GetSlotInstalled(i)
    local slot = self.Attachments[i]
    local installed = slot.Installed

    if !installed then
        for _, slot2 in pairs(slot.MergeSlots or {}) do
            if !isnumber(slot2) then continue end
            if self.Attachments[slot2] and self.Attachments[slot2].Installed then
                installed = self.Attachments[slot2].Installed
                break
            elseif !self.Attachments[slot2] then
                print("ERROR! No attachment " .. tostring(slot2))
            end
        end
    end

    return installed
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

    span.TextRot = span.TextRot or {}

    if tw > maxw then
        local realx, realy = span:LocalToScreen(x, y)
        render.SetScissorRect(realx, realy, realx + maxw, realy + (th * 2), true)

        span.TextRot[txt] = span.TextRot[txt] or 0

        if !only then
            span.StartTextRot = span.StartTextRot or CurTime()
            span.TextRotState = span.TextRotState or 0 -- 0: start, 1: moving, 2: end
            if span.TextRotState == 0 then
                span.TextRot[txt] = 0
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 1
                end
            elseif span.TextRotState == 1 then
                span.TextRot[txt] = span.TextRot[txt] + (FrameTime() * ScreenScaleMulti(16))
                if span.TextRot[txt] >= (tw - maxw) + ScreenScaleMulti(8) then
                    span.StartTextRot = CurTime()
                    span.TextRotState = 2
                end
            elseif span.TextRotState == 2 then
                if span.StartTextRot < CurTime() - 2 then
                    span.TextRotState = 3
                    span.StartTextRot = CurTime()
                end
            elseif span.TextRotState == 3 then
                span.TextRot[txt] = span.TextRot[txt] - (FrameTime() * ScreenScaleMulti(16))
                if span.TextRot[txt] <= 0 then
                    span.StartTextRot = CurTime()
                    span.TextRotState = 0
                end
            end
        end
        surface.SetTextPos(tx - span.TextRot[txt], ty)
        surface.DrawText(txt)
        render.SetScissorRect(0, 0, 0, 0, false)
    else
        surface.DrawText(txt)
    end
end

local translate = ArcCW.GetTranslation
local defaultatticon = Material("hud/atts/default.png", "mips smooth")
local blockedatticon = Material("hud/atts/blocked.png", "mips smooth")

local pickx_empty = Material("hud/pickx_empty.png", "mips smooth")
local pickx_full = Material("hud/pickx_filled.png", "mips smooth")

local grad = Material("hud/grad.png", "mips smooth")

local bird = Material("hud/arccw_bird.png", "mips smooth")

-- 1: Customize
-- 2: Presets
-- 3: Inventory
ArcCW.Inv_SelectedMenu = 1

-- Selected inventory slot
SWEP.Inv_SelectedSlot = 0

SWEP.Inv_Scroll = {}

-- 1: Stats
-- 2: Trivia
ArcCW.Inv_SelectedInfo = 1

ArcCW.Inv_Fade = 0

ArcCW.Inv_ShownAtt = nil
ArcCW.Inv_Hidden = false

function SWEP:CreateCustomize2HUD()
    local col_fg = Color(255, 255, 255, 255)
    local col_fg_tr = Color(255, 255, 255, 125)
    local col_shadow = Color(0, 0, 0, 255)
    local col_button = Color(0, 0, 0, 175)

    local col_block = Color(50, 0, 0, 175)
    local col_block_txt = Color(175, 10, 10, 255)

    if GetConVar("arccw_attinv_darkunowned"):GetBool() then
        col_block = Color(0, 0, 0, 100)
        col_block_txt = Color(10, 10, 10, 255)
    end

    local col_bad = Color(255, 50, 50, 255)
    local col_good = Color(100, 255, 100, 255)
    local col_info = Color(150, 150, 255, 255)

    ArcCW.Inv_ShownAtt = nil

    local scrw, scrh = ScrW(), ScrH()
    if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
        -- Other resolutions seem to cause stretching issues
        scrw = 1366
        scrh = 768
    end

    ArcCW.InvHUD = vgui.Create("DFrame")

    local scrwmult = GetConVar("arccw_hud_deadzone_x"):GetFloat() * scrw
    local scrhmult = GetConVar("arccw_hud_deadzone_y"):GetFloat() * scrh

    local ss = ArcCW.AugmentedScreenScale(1)
    local rss = ss -- REAL SCREEN SCALE

    scrw, scrh = scrw - scrwmult, scrh - scrhmult

    local bar1_w = scrw / 4
    local bar2_w = scrw / 5
    local bar3_w = scrw / 2
    local airgap_x = ss * 24
    local airgap_y = ss * 24
    local smallgap = ss * 4

    local top_zone = ss * 24
    local bottom_zone = ss * 68

    local cornerrad = ss * 4

    local bigbuttonheight = ss * 36
    local smallbuttonheight = rss * 16

    local function PaintScrollBar(panel, w, h)
        local s = ss * 2
        draw.RoundedBox(ss * 1, (w - s) / 2, 0, s, h, col_fg)
    end

    local function clearrightpanel()
        if ArcCW.Inv_SelectedInfo == 1 then
            ArcCW.InvHUD_FormWeaponStats()
        elseif ArcCW.Inv_SelectedInfo == 2  then
            ArcCW.InvHUD_FormWeaponTrivia()
        end
    end

    ArcCW.Inv_Fade = 0

    ArcCW.InvHUD:SetPos(0, 0)
    ArcCW.InvHUD:SetSize(ScrW(), ScrH())
    ArcCW.InvHUD:Center()
    ArcCW.InvHUD:SetDraggable(false)
    ArcCW.InvHUD:SetText("")
    ArcCW.InvHUD:SetTitle("")
    ArcCW.InvHUD:ShowCloseButton(false)
    ArcCW.InvHUD.Paint = function(self2)
        if !IsValid(self) then
            gui.EnableScreenClicker(false)
            ArcCW.InvHUD:Remove()
            return
        end

        surface.SetDrawColor(Color(0, 0, 0, Lerp(ArcCW.Inv_Fade, 0, 255)))
        surface.SetMaterial(grad)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

        if self:GetReloading() then
            ArcCW.InvHUD:Remove()
            return
        end

        local st = 1 / 5
        if self:GetState() == ArcCW.STATE_CUSTOMIZE and !ArcCW.Inv_Hidden then
            ArcCW.Inv_Fade = math.Approach(ArcCW.Inv_Fade, 1, FrameTime() * 1 / st)
        else
            ArcCW.Inv_Fade = math.Approach(ArcCW.Inv_Fade, 0, FrameTime() * 1 / st)
            -- if (self:GetState() != ArcCW.STATE_CUSTOMIZE or !ArcCW.Inv_Hidden) and ArcCW.Inv_Fade == 0 then ArcCW.InvHUD:Remove() end
                -- This'll completely screw up on multiplayer games and sometimes even singleplayer
        end
        col_fg = Color(255, 255, 255, Lerp(ArcCW.Inv_Fade, 0, 255))
        col_fg_tr = Color(255, 255, 255, Lerp(ArcCW.Inv_Fade, 0, 125))
        col_shadow = Color(0, 0, 0, Lerp(ArcCW.Inv_Fade, 0, 255))
        col_button = Color(0, 0, 0, Lerp(ArcCW.Inv_Fade, 0, 175))

        if GetConVar("arccw_attinv_darkunowned"):GetBool() then
            col_block = Color(0, 0, 0, Lerp(ArcCW.Inv_Fade, 0, 100))
            col_block_txt = Color(10, 10, 10, Lerp(ArcCW.Inv_Fade, 0, 255))
        else
            col_block = Color(50, 0, 0, 175 * ArcCW.Inv_Fade)
            col_block_txt = Color(175, 10, 10, Lerp(ArcCW.Inv_Fade, 0, 255))
        end

        --col_bad = Color(255, 50, 50, 255 * ArcCW.Inv_Fade)
        --col_good = Color(100, 255, 100, 255 * ArcCW.Inv_Fade)
        --col_info = Color(75, 75, 255, 255 * ArcCW.Inv_Fade)
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
    local menu1_h = scrh - (2 * airgap_y) - bottom_zone - top_zone + smallgap

    local closebutton = vgui.Create("DButton", ArcCW.InvHUD)
    closebutton:SetText("")
    closebutton:SetPos(scrw - smallbuttonheight - airgap_x, smallgap)
    closebutton:SetSize(rss * 24, bigbuttonheight)
    closebutton.Paint = function(self2, w, h)
        local col = col_fg

        if self2:IsHovered() then
            col = col_shadow
        end
        --draw.RoundedBox(ss * 1, 0, 0, w, h, Color(127, 127, 127, 127))
            -- Comment me! But it'll show when the HUD is alive.

        surface.SetTextColor(col_shadow)
        surface.SetTextPos(ss * 8, 0)
        surface.SetFont("ArcCWC2_24_Glow")
        surface.DrawText("x")

        surface.SetTextColor(col)
        surface.SetTextPos(ss * 8, 0)
        surface.SetFont("ArcCWC2_24")
        surface.DrawText("x")
    end
    closebutton.DoClick = function(self2, clr, btn)
        net.Start("arccw_togglecustomize")
        net.WriteBool(false)
        net.SendToServer()

        if IsValid(self) and self.ToggleCustomizeHUD then
            self:ToggleCustomizeHUD(false)
        end
    end

    local hidebutton = vgui.Create("DButton", ArcCW.InvHUD)
    hidebutton:SetText("")
    hidebutton:SetPos(scrw - smallbuttonheight * 2 - airgap_x, smallgap)
    hidebutton:SetSize(smallbuttonheight, bigbuttonheight)
    hidebutton.Paint = function(self2, w, h)
        local col = col_fg

        if self2:IsHovered() then
            col = Color(col_shadow.r, col_shadow.g, col_shadow.b, col_shadow.a * ArcCW.Inv_Fade)
        end
        --draw.RoundedBox(ss * 1, 0, 0, w, h, Color(127, 127, 127, 127))
            -- Comment me! But it'll show when the HUD is alive.

        surface.SetTextColor(col_shadow)
        surface.SetTextPos(ss * 8, ss * -4)
        surface.SetFont("ArcCWC2_24_Glow")
        surface.DrawText("_")

        surface.SetTextColor(col)
        surface.SetTextPos(ss * 8, ss * -4)
        surface.SetFont("ArcCWC2_24")
        surface.DrawText("_")
    end
    hidebutton.DoClick = function(self2, clr, btn)
        if IsValid(self) and self.ToggleCustomizeHUD then
            ArcCW.Inv_Hidden = !ArcCW.Inv_Hidden
            gui.EnableScreenClicker(false)
        end
    end

    -- Menu for attachment slots/presets
    ArcCW.InvHUD_Menu1 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu1:SetPos(airgap_x, airgap_y + top_zone + smallgap)
    ArcCW.InvHUD_Menu1:SetSize(menu1_w, menu1_h)

    local scroll_1 = ArcCW.InvHUD_Menu1:GetVBar()
    scroll_1.Paint = function() end

    scroll_1.btnUp.Paint = function(span, w, h)
    end
    scroll_1.btnDown.Paint = function(span, w, h)
    end
    scroll_1.btnGrip.Paint = PaintScrollBar

    local customizebutton = vgui.Create("DButton", ArcCW.InvHUD)
    customizebutton:SetSize(ss * 90, ss * 16)
    customizebutton:SetPos(airgap_x, airgap_y + ss * 8)
    customizebutton:SetText("")
    customizebutton.Text = translate("ui.customize")
    customizebutton.Val = 1
    customizebutton.DoClick = function(self2, clr, btn)
        ArcCW.Inv_SelectedMenu = 1
        ArcCW.InvHUD_FormAttachments()

        surface.PlaySound("weapons/arccw/hover.wav")
    end
    customizebutton.Paint = function(self2, w, h)
        local col = col_button
        local col2 = col_fg

        if self2:IsHovered() or (ArcCW.Inv_SelectedMenu == self2.Val) then
            col = col_fg_tr
            col2 = col_shadow
        end

        draw.RoundedBox(cornerrad, 0, 0, w, h, col)

        surface.SetFont("ArcCWC2_8")
        local tw, th = surface.GetTextSize(self2.Text)

        surface.SetFont("ArcCWC2_8_Glow")
        surface.SetTextColor(col_shadow)
        surface.SetTextPos((w - tw) / 2, (h - th) / 2)
        surface.DrawText(self2.Text)

        surface.SetFont("ArcCWC2_8")
        surface.SetTextColor(col2)
        surface.SetTextPos((w - tw) / 2, (h - th) / 2)
        surface.DrawText(self2.Text)
    end

    local presetsbutton = vgui.Create("DButton", ArcCW.InvHUD)
    presetsbutton:SetSize(ss * 72, ss * 16)
    presetsbutton:SetPos(airgap_x + customizebutton:GetWide() + (ss * 8), airgap_y + ss * 8)
    presetsbutton:SetText("")
    presetsbutton.Text = translate("ui.presets")
    presetsbutton.Val = 2
    presetsbutton.DoClick = function(self2, clr, btn)
        ArcCW.Inv_SelectedMenu = 2
        ArcCW.InvHUD_FormPresets()

        surface.PlaySound("weapons/arccw/hover.wav")
    end
    presetsbutton.Paint = customizebutton.Paint

    if self:ShowInventoryButton() then
        local inventorybutton = vgui.Create("DButton", ArcCW.InvHUD)
        inventorybutton:SetSize(ss * 72, ss * 16)
        inventorybutton:SetPos(airgap_x + customizebutton:GetWide() + (ss * 8 * 2) + presetsbutton:GetWide(), airgap_y + ss * 8)
        inventorybutton:SetText("")
        inventorybutton.Text = translate("ui.inventory")
        inventorybutton.Val = 3
        inventorybutton.DoClick = function(self2, clr, btn)
            ArcCW.Inv_SelectedMenu = 3
            ArcCW.InvHUD_FormInventory()

            surface.PlaySound("weapons/arccw/hover.wav")
        end
        inventorybutton.Paint = customizebutton.Paint
    end

    local menu2_x, menu2_y = ArcCW.InvHUD_Menu1:GetPos()
    menu2_x = menu2_x + ArcCW.InvHUD_Menu1:GetWide() + smallgap
    local menu2_w = bar2_w
    local menu2_h = scrh - top_zone - airgap_y - airgap_y - (ss * 16)

    -- Menu for attachments
    ArcCW.InvHUD_Menu2 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu2:SetPos(menu2_x, menu2_y)
    ArcCW.InvHUD_Menu2:SetSize(menu2_w, menu2_h)

    -- ArcCW.InvHUD_Menu2.Paint = function(self2, w, h)
    --     draw.RoundedBox(2, 0, 0, w, h, col_fg)
    -- end

    local scroll_2 = ArcCW.InvHUD_Menu2:GetVBar()
    scroll_2.AlreadySet = false
    scroll_2.Paint = function(self2, w, h)
        if !self2.AlreadySet then
            self2:SetScroll(self.Inv_Scroll[self.Inv_SelectedSlot or 0] or 0)
            self2.AlreadySet = true
        end

        local scroll = self2:GetScroll()

        self.Inv_Scroll[self.Inv_SelectedSlot or 0] = scroll
    end

    scroll_2.btnUp.Paint = function(span, w, h)
    end
    scroll_2.btnDown.Paint = function(span, w, h)
    end
    scroll_2.btnGrip.Paint = PaintScrollBar

    function ArcCW.InvHUD_FormInventory()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_Menu1:Clear()
        ArcCW.InvHUD_Menu2:Clear()
        self.Inv_SelectedSlot = nil
        clearrightpanel()

        local attinv = LocalPlayer().ArcCW_AttInv or {}

        local atts = table.GetKeys(attinv)

        table.sort(atts)

        local str = ""
        if #atts == 0 then
            str = translate("ui.noatts")
        elseif GetConVar("arccw_attinv_lockmode"):GetBool() then
            str = translate("ui.lockinv")
        end

        if str then
            local msg = vgui.Create("DPanel", ArcCW.InvHUD_Menu1)
            msg:SetText("")
            msg:SetSize(menu2_w - (2 * ss), rss * 12)
            msg:Dock(TOP)
            msg.Paint = function(self2, w, h)
                local old = DisableClipping(true)
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_12_Glow")
                surface.DrawText(str)
                --DrawTextRot(self2, str, ss * 4, 0, ss * 4, ss * 2, w - (ss * 4))

                surface.SetTextColor(col_fg)
                surface.SetTextPos(ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_12")
                surface.DrawText(str)
                --DrawTextRot(self2, str, ss * 4, 0, ss * 4, ss * 2, w - (ss * 4))
                DisableClipping(old)
            end
        end

        for i, k in ipairs(atts) do
            if (ArcCW:PlayerGetAtts(self:GetOwner(), k) or 0) <= 0 then continue end
            local atttbl = ArcCW.AttachmentTable[k or ""]

            if atttbl.Free then continue end

            local button = vgui.Create("DButton", ArcCW.InvHUD_Menu1)
            button.att = k
            button:SetText("")
            button:SetSize(menu2_w - (2 * ss), smallbuttonheight)
            button:DockMargin(0, smallgap, 0, 0)
            button:Dock(TOP)
            button.DoClick = function(self2, clr, btn)
                if GetConVar("arccw_attinv_lockmode"):GetBool() then return end

                surface.PlaySound("weapons/arccw/uninstall.wav")

                net.Start("arccw_asktodrop")
                    net.WriteUInt(ArcCW.AttachmentTable[self2.att].ID, 24)
                net.SendToServer()

                ArcCW:PlayerTakeAtt(self:GetOwner(), self2.att)
                if (self:GetOwner().ArcCW_AttInv[self2.att] or 0) == 0 then
                    self2:Remove()
                end
            end
            button.Paint = function(self2, w, h)
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                -- if self2:IsHovered() then
                --     ArcCW.InvHUD_FormAttachmentStats(self2.att, self2.attslot)
                -- end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local icon_h = h
                local buffer = 0

                if !GetConVar("arccw_attinv_lockmode"):GetBool() then
                    local amt = ArcCW:PlayerGetAtts(self:GetOwner(), self2.att) or 0
                    amt = math.min(amt, 99)
                    local amttxt = tostring(amt)
                    surface.SetFont("ArcCWC2_8")
                    local amt_w = surface.GetTextSize(amttxt)

                    -- surface.SetTextColor(col_shadow)
                    -- surface.SetFont("ArcCWC2_8_Glow")
                    -- surface.SetTextPos(w - amt_w - (ss * 1), h - (rss * 8) - (ss * 1))
                    -- surface.DrawText(amttxt)

                    surface.SetTextColor(col2)
                    surface.SetFont("ArcCWC2_8")
                    surface.SetTextPos(w - amt_w - (ss * 4), h - (rss * 8) - (ss * 1))
                    surface.DrawText(amttxt)

                    buffer = amt_w + (ss * 6)
                end

                local txt = atttbl.PrintName or ""
                txt = translate("name." .. self2.att) or translate(txt) or txt

                surface.SetTextColor(col2)
                surface.SetTextPos(icon_h + ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_12")

                DrawTextRot(self2, txt, icon_h + (ss * 4), 0, icon_h + ss * 4, ss * 2, w - icon_h - (ss * 4) - buffer)

                local icon = atttbl.Icon
                if !icon or icon:IsError() then icon = bird end

                surface.SetDrawColor(col2)
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(ss * 2, 0, icon_h, icon_h)
            end
        end
    end

    function ArcCW.InvHUD_FormPresets()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_Menu1:Clear()
        ArcCW.InvHUD_Menu2:Clear()
        self.Inv_SelectedSlot = nil
        clearrightpanel()

        local button = vgui.Create("DButton", ArcCW.InvHUD_Menu1)
        button:SetText("")
        button:SetSize(menu1_w, smallbuttonheight)
        button:DockMargin(0, smallgap, 0, 0)
        button:Dock(TOP)
        button.DoClick = function(self2, clr, btn)
            self:CreatePresetSave()
        end
        button.Paint = function(self2, w, h)
            local col = col_button
            local col2 = col_fg

            if self2:IsHovered() then
                col = col_fg_tr
                col2 = col_shadow
            end

            draw.RoundedBox(cornerrad, 0, 0, w, h, col)

            local preset_txt = "Create New Preset"

            surface.SetFont("ArcCWC2_14")
            surface.SetTextPos(ss * 4, ss * 0)
            surface.SetTextColor(col2)
            DrawTextRot(self2, preset_txt, 0, 0, ss * 4, ss * 0, w - ss * 4)
        end

        local preset = {}

        preset = self:GetPresets()

        for i, k in pairs(preset) do
            if k == "autosave.txt" then continue end
            local load_btn = vgui.Create("DButton", ArcCW.InvHUD_Menu1)
            load_btn:SetText("")
            load_btn.PresetName = string.sub(k, 1, -5)
            load_btn:SetSize(menu1_w, smallbuttonheight)
            load_btn:DockMargin(0, smallgap, 0, 0)
            load_btn:Dock(TOP)
            load_btn.DoClick = function(self2, clr, btn)
                self.LastPresetName = self2.PresetName
                self:LoadPreset(self2.PresetName)
            end
            load_btn.DoRightClick = function(self2)
                local filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. self2.PresetName .. ".txt"
                file.Delete(filename)
                self2:Remove()
            end
            load_btn.Paint = function(self2, w, h)
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local preset_txt = self2.PresetName

                surface.SetFont("ArcCWC2_14")
                surface.SetTextPos(ss * 4, ss * 0)
                surface.SetTextColor(col2)
                DrawTextRot(self2, preset_txt, 0, 0, ss * 4, ss * 0, w - ss * 4)
            end
        end
    end

    function ArcCW.InvHUD_FormAttachmentSelect()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_Menu2:Clear()

        local slot = self.Attachments[self.Inv_SelectedSlot or 0]

        if !slot then return end

        local atts = {}
        local slots = {self.Inv_SelectedSlot}
        local attCheck = {}

        table.Add(slots, slot.MergeSlots or {})

        for _, y in pairs(slots) do
            for _, bruh in pairs(ArcCW:GetAttsForSlot((self.Attachments[y] or {}).Slot, self)) do
                if attCheck[bruh] then continue end
                table.insert(atts, {
                    att = bruh,
                    slot = y
                })
                attCheck[bruh] = true
            end
        end

        atts[0] = {
            att = "",
            slot = self.Inv_SelectedSlot
        }

        table.sort(atts, function(a, b)
            a = a.att or ""
            b = b.att or ""
            local atttbl_a = ArcCW.AttachmentTable[a]
            local atttbl_b = ArcCW.AttachmentTable[b]

            local order_a = 0
            local order_b = 0

            order_a = atttbl_a.SortOrder or order_a
            order_b = atttbl_b.SortOrder or order_b

            if order_a == order_b then
                return (translate("name." .. a) or atttbl_a.PrintName or "") > (translate("name." .. b) or atttbl_b.PrintName or "")
            end

            return order_a > order_b
        end)

        local has = false
        for _, att in pairs(atts) do
            if !att then continue end
            if !istable(att) then continue end

            local show, _, _ = self:ValidateAttachment(att.att, nil, att.slot)
            -- if !ArcCW.AttachmentTable[att] then continue end

            if !show then continue end
            has = (att.att != "")

            local button = vgui.Create("DButton", ArcCW.InvHUD_Menu2)
            button.att = att.att
            button.attslot = att.slot
            button:SetText("")
            button:SetSize(menu2_w - (2 * ss), smallbuttonheight)
            button:DockMargin(0, smallgap, 0, 0)
            button:Dock(TOP)
            button.DoClick = function(self2, clr, btn)
                -- self.Inv_SelectedSlot = self2.attindex
                -- ArcCW.InvHUD_FormAttachmentSelect()
                -- self:DetachAllMergeSlots(self2.attslot, true)
                if self2.att == "" then
                    self2:DoRightClick()
                else
                    self:Attach(self2.attslot, self2.att)
                    ArcCW.Inv_ShownAtt = nil -- Force a regen on the panel so we can see toggle/slider options
                    ArcCW.InvHUD_FormAttachmentStats(self2.att, self2.attslot, true)
                end
            end
            button.DoRightClick = function(self2)
                self:DetachAllMergeSlots(self2.attslot)
                ArcCW.InvHUD_FormAttachmentSelect()
            end
            button.Paint = function(self2, w, h)
                if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
                local col = col_button
                local col2 = col_fg

                local _, _, blocked, showqty = self:ValidateAttachment(att.att, nil, att.slot)

                local installed = self:GetSlotInstalled(self2.attslot)

                if self2:IsHovered() or self2.att == installed or (self2.att == "" and !installed) then
                    col = col_fg_tr
                    col2 = col_shadow

                --     self2:SetSize(menu2_w - (2 * ss), smallbuttonheight * 2)
                -- else
                --     self2:SetSize(menu2_w - (2 * ss), smallbuttonheight)
                end

                if self2:IsHovered() then
                    ArcCW.InvHUD_FormAttachmentStats(self2.att, self2.attslot, installed == self2.att)
                end

                local owned = ArcCW:PlayerGetAtts(self:GetOwner(), att.att) > 0

                if blocked or (!owned and installed != self2.att) then
                    col = col_block
                    col2 = col_block_txt
                end

                if !owned and installed != self2.att then
                    showqty = false
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local icon_h = h

                local atttbl = ArcCW.AttachmentTable[self2.att or ""]

                if !self2.att or self2.att == "" then
                    local attslot = self.Attachments[self2.attslot]
                    atttbl = {
                        PrintName = translate(attslot.DefaultAttName) or attslot.DefaultAttName or translate("attslot.noatt"),
                        Icon = attslot.DefaultAttIcon or defaultatticon
                    }
                end

                local buffer = 0

                if showqty then
                    local amt = ArcCW:PlayerGetAtts(self:GetOwner(), self2.att) or 0

                    amt = math.min(amt, 99)

                    local amttxt = tostring(amt)

                    surface.SetFont("ArcCWC2_8")
                    local amt_w = surface.GetTextSize(amttxt)

                    -- surface.SetTextColor(col_shadow)
                    -- surface.SetFont("ArcCWC2_8_Glow")
                    -- surface.SetTextPos(w - amt_w - (ss * 1), h - (rss * 8) - (ss * 1))
                    -- surface.DrawText(amttxt)

                    surface.SetTextColor(col2)
                    surface.SetFont("ArcCWC2_8")
                    surface.SetTextPos(w - amt_w - (ss * 4), h - (rss * 8) - (ss * 1))
                    surface.DrawText(amttxt)

                    buffer = amt_w + (ss * 6)
                end

                local txt = atttbl.PrintName or ""
                txt = translate("name." .. self2.att) or translate(txt) or txt

                surface.SetTextColor(col2)
                surface.SetTextPos(icon_h + ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_12")

                DrawTextRot(self2, txt, icon_h + (ss * 4), 0, icon_h + ss * 4, ss * 2, w - icon_h - (ss * 4) - buffer)

                local icon = atttbl.Icon
                if !icon or icon:IsError() then icon = bird end

                surface.SetDrawColor(col2)
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(ss * 2, 0, icon_h, icon_h)
            end
        end

        if table.Count(atts) > 1 and !has then
            local msg = vgui.Create("DPanel", ArcCW.InvHUD_Menu2)
            msg:SetText("")
            msg:SetSize(menu2_w - (2 * ss), smallbuttonheight)
            msg:Dock(TOP)
            msg.Paint = function(self2, w, h)
                local txt = translate("ui.noatts_slot")

                surface.SetTextColor(col_shadow)
                surface.SetTextPos(ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_10_Glow")
                DrawTextRot(self2, txt, ss * 4, 0, ss * 4, ss * 2, w - (ss * 4))

                surface.SetTextColor(col_fg)
                surface.SetTextPos(ss * 4, ss * 2)
                surface.SetFont("ArcCWC2_10")
                DrawTextRot(self2, txt, ss * 4, 0, ss * 4, ss * 2, w - (ss * 4))
            end
        end
    end

    -- add attachments

    function ArcCW.InvHUD_FormAttachments()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
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
            button:DockMargin(0, 0, 0, smallgap)
            button:Dock(TOP)
            button.DoClick = function(self2, clr, btn)
                if self.Inv_SelectedSlot == self2.attindex then
                    self.Inv_SelectedSlot = nil
                    ArcCW.InvHUD_Menu2:Clear()
                    clearrightpanel()
                    if GetConVar("arccw_cust_sounds"):GetBool() then surface.PlaySound("weapons/arccw/close.wav") end
                else
                    local aslot = self.Attachments[i]

                    if self:CheckFlags(aslot.ExcludeFlags, aslot.RequireFlags) then
                        self.Inv_SelectedSlot = self2.attindex
                        ArcCW.InvHUD_FormAttachmentSelect()
                        ArcCW.InvHUD_FormAttachmentStats(self2.attindex, self2.attindex, true)
                        if GetConVar("arccw_cust_sounds"):GetBool() then surface.PlaySound("weapons/arccw/open.wav") end
                    end
                end
            end
            button.DoRightClick = function(self2)
                self:DetachAllMergeSlots(self2.attindex)
                ArcCW.InvHUD_FormAttachmentSelect()
            end
            button.Paint = function(self2, w, h)
                if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() or self.Inv_SelectedSlot == self2.attindex then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                local aslot = self.Attachments[i]

                if !self:CheckFlags(aslot.ExcludeFlags, aslot.RequireFlags) then
                    col = col_block
                    col2 = col_block_txt
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local installed = self:GetSlotInstalled(i)

                local att_icon = slot.DefaultAttIcon or defaultatticon
                local att_txt = translate(slot.DefaultAttName) or slot.DefaultAttName or translate("attslot.noatt")
                local atttbl = ArcCW.AttachmentTable[installed or ""]

                if atttbl then
                    att_txt = translate("name." .. installed) or atttbl.PrintName
                    att_icon = atttbl and atttbl.Icon
                    if !att_icon or att_icon:IsError() then att_icon = bird end
                end

                local slot_txt = translate(slot.PrintName) or slot.PrintName

                surface.SetDrawColor(col2)
                local icon_h = h
                surface.SetMaterial(att_icon)
                surface.DrawTexturedRect(w - icon_h - ss * 2, 0, icon_h, icon_h)

                surface.SetTextColor(col2)
                surface.SetFont("ArcCWC2_10")
                surface.SetTextPos(ss * 6, ss * 4)
                DrawTextRot(self2, slot_txt, 0, 0, ss * 6, ss * 4, w - icon_h - ss * 4)
                -- surface.DrawText(slot.PrintName)

                surface.SetFont("ArcCWC2_14")
                surface.SetTextPos(ss * 6, ss * 14)
                DrawTextRot(self2, att_txt, 0, 0, ss * 6, ss * 14, w - icon_h - ss * 4)
            end
        end

        local pickxpanel = vgui.Create("DPanel", ArcCW.InvHUD)
        pickxpanel:SetSize(menu1_w, bottom_zone - airgap_y)
        pickxpanel:SetPos(airgap_x, scrh - bottom_zone - airgap_y)
        pickxpanel.Paint = function(self2, w, h)
            if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
            local pickx_amount = self:GetPickX()
            local pickedatts = self:CountAttachments()

            if pickx_amount == 0 then return end
            if pickx_amount > 8 then
                surface.SetTextColor(col_fg)
                surface.SetTextPos(0, ss * 4)
                surface.SetFont("ArcCWC2_16")
                surface.DrawText("Attachments: " .. tostring(pickedatts) .. "/" .. tostring(pickx_amount))
                return
            end

            local x = 0
            local y = ss * 4

            local s = ss * 20

            x = (w - (s * pickx_amount)) / 2

            for i = 1, pickx_amount do
                surface.SetDrawColor(col_fg)
                if i > pickedatts then
                    surface.SetMaterial(pickx_empty)
                else
                    surface.SetMaterial(pickx_full)
                end
                surface.DrawTexturedRect(x, y, s, s)

                x = x + s
            end
        end
    end

    local menu3_h = scrh - airgap_y - bottom_zone
    local menu3_w = bar3_w

    -- weapon details
    ArcCW.InvHUD_Menu3 = vgui.Create("DScrollPanel", ArcCW.InvHUD)
    ArcCW.InvHUD_Menu3:SetPos(scrw - menu3_w, airgap_y + smallgap)
    ArcCW.InvHUD_Menu3:SetSize(menu3_w, menu3_h)

    function ArcCW.InvHUD_FormAttachmentStats(att, slot, equipped)
        if ArcCW.Inv_ShownAtt == att then
            return
        end
        if isnumber(att) then
            local installed = self:GetSlotInstalled(att)

            att = installed
        end
        if !att then
            clearrightpanel()
            return
        end
        local atttbl = ArcCW.AttachmentTable[att]

        if !atttbl then return end

        ArcCW.InvHUD_Menu3:Clear()

        ArcCW.Inv_ShownAtt = att

        local s = ss * 250

        local bgim = vgui.Create("DLabel", ArcCW.InvHUD_Menu3)
        bgim:SetText("")
        bgim:SetPos(menu3_w - s - (ss * 25), 0)
        bgim:SetSize(s, s)
        bgim.Paint = function(self2, w, h)
            local icon = atttbl.Icon
            if !icon or icon:IsError() then icon = bird end

            surface.SetDrawColor(255, 255, 255, 25 * ArcCW.Inv_Fade)
            surface.SetMaterial(icon)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local attname_panel = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        attname_panel:SetSize(menu3_w, rss * 24)
        attname_panel:SetPos(0, rss * 16)
        attname_panel.Paint = function(self2, w, h)
            local name = atttbl.PrintName

            surface.SetFont("ArcCWC2_24")
            local tw = surface.GetTextSize(name)

            surface.SetTextColor(col_shadow)
            surface.SetFont("ArcCWC2_24_Glow")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x)

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCWC2_24")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x, true)
        end

        local scroll = vgui.Create("DScrollPanel", ArcCW.InvHUD_Menu3)
        scroll:SetSize(menu3_w - airgap_x, ss * 128)
        scroll:SetPos(0, rss * 32 + ss * 16)

        local scroll_bar = scroll:GetVBar()
        scroll_bar.Paint = function() end

        scroll_bar.btnUp.Paint = function(span, w, h)
        end
        scroll_bar.btnDown.Paint = function(span, w, h)
        end
        scroll_bar.btnGrip.Paint = PaintScrollBar

        local bottombuffer = 0

        local m_w = menu3_w * 0.75
        local leftbuffer = 0

        if equipped and self.Attachments[slot].SlideAmount then
            local slider = vgui.Create("DButton", ArcCW.InvHUD_Menu3)

            slider:SetSize(m_w * 2 / 3, rss * 10)
            slider:SetPos(0, rss * 16 + rss * 24 + ss * 128 - (rss * 10))
            slider:SetText("")
            slider.Dragging = false
            slider.NextDrag = 0
            slider.OnRemove = function(self2)
                self:SendDetail_SlidePos(slot)
                self:SavePreset("autosave")
            end
            slider.Paint = function(self2, w, h)
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() or self2.Dragging then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local linebuffer = ss * 8
                local line_w = w - (linebuffer * 2)

                if self2.Dragging or (self2:IsHovered() and input.IsMouseDown(MOUSE_LEFT)) then
                    local x, _ = self2:LocalCursorPos()

                    local mouse_line_x = x - linebuffer

                    local delta = mouse_line_x / line_w

                    delta = math.Clamp(delta, 0, 1)

                    if self.Attachments[slot].SlidePos != delta and self2.NextDrag <= CurTime() then
                        -- local amt = math.abs(self.Attachments[slot].SlidePos - delta)
                        EmitSound("weapons/arccw/dragatt.wav", EyePos(), -2, CHAN_ITEM, 1,75, 0, math.Clamp(delta * 200, 90, 110))
                        self2.NextDrag = CurTime() + 0.05
                    end

                    self.Attachments[slot].SlidePos = delta

                    self2.Dragging = true

                    if !input.IsMouseDown(MOUSE_LEFT) then
                        self2.Dragging = false

                        self:SendDetail_SlidePos(slot)
                        self:SavePreset("autosave")
                    end
                end

                local slide = (self.Attachments[slot] or {}).SlidePos or 0.5

                surface.SetDrawColor(col2)
                surface.DrawLine(linebuffer, h / 2, w - linebuffer, h / 2)

                local rect_x = slide * line_w + linebuffer
                local rect_w = ss * 6
                surface.DrawRect(rect_x - (rect_w / 2), (h - rect_w) / 2, rect_w, rect_w)
            end

            leftbuffer = m_w * 2 / 3
            bottombuffer = rss * 10
        end

        if equipped and atttbl.ToggleStats then
            local toggle = vgui.Create("DButton", ArcCW.InvHUD_Menu3)

            toggle:SetSize(m_w * 1 / 3, rss * 10)
            toggle:SetPos(leftbuffer + (ss * 4), rss * 16 + rss * 24 + ss * 128 - (rss * 10))
            toggle:SetText("")
            toggle.OnMousePressed = function(self2, kc)
                if kc == MOUSE_LEFT then
                    self:ToggleSlot(slot)
                elseif kc == MOUSE_RIGHT then
                    self:ToggleSlot(slot, nil, nil, true)
                end
            end
            toggle.Paint = function(self2, w, h)
                local col = col_button
                local col2 = col_fg

                if self2:IsHovered() or ArcCW.Inv_SelectedInfo == self2.Val then
                    col = col_fg_tr
                    col2 = col_shadow
                end

                draw.RoundedBox(cornerrad, 0, 0, w, h, col)

                local txt = (translate("ui.toggle"))
                local catttbl = ArcCW.AttachmentTable[att]
                if catttbl and catttbl.ToggleStats[self.Attachments[slot].ToggleNum]
                        and catttbl.ToggleStats[self.Attachments[slot].ToggleNum].PrintName then
                    txt = ArcCW.TryTranslation(catttbl.ToggleStats[self.Attachments[slot].ToggleNum].PrintName)
                end

                surface.SetFont("ArcCWC2_8")
                local tw, th = surface.GetTextSize(txt)

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(txt)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col2)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(txt)
            end

            bottombuffer = rss * 10
        end

        scroll:SetSize(menu3_w - airgap_x, ss * 128 - bottombuffer)

        local multiline = {}
        local desc = atttbl.Description

        multiline = multlinetext(desc, scroll:GetWide() - (ss * 2), "ArcCW_10")

        local desc_title = vgui.Create("DPanel", scroll)
        desc_title:SetSize(scroll:GetWide(), rss * 8)
        desc_title:SetPos(0, 0)
        desc_title.Paint = function(self2, w, h)
            surface.SetFont("ArcCWC2_8")
            local txt = translate("trivia.description")
            local tw_1 = surface.GetTextSize(txt)

            surface.SetFont("ArcCWC2_8_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos(w - tw_1, 0)
            surface.DrawText(txt)

            surface.SetFont("ArcCWC2_8")
            surface.SetTextColor(col_fg)
            surface.SetTextPos(w - tw_1, 0)
            surface.DrawText(txt)
        end

        for i, text in pairs(multiline) do
            local desc_line = vgui.Create("DPanel", scroll)
            desc_line:SetSize(scroll:GetWide(), rss * 10)
            desc_line:SetPos(0, (rss * 10 * i) - (rss * 2))
            desc_line.Paint = function(self2, w, h)
                surface.SetFont("ArcCWC2_10")
                local tw = surface.GetTextSize(text)

                surface.SetFont("ArcCWC2_10_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw, 0)
                surface.DrawText(text)

                surface.SetFont("ArcCWC2_10")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw, 0)
                surface.DrawText(text)
            end
        end

        local scroll_pros = vgui.Create("DScrollPanel", ArcCW.InvHUD_Menu3)
        scroll_pros:SetSize(menu3_w, ss * 172)
        scroll_pros:SetPos(0, menu3_h - (ss * 172))
        scroll_pros.Paint = function() end

        local scroll_bar_pros = scroll_pros:GetVBar()
        scroll_bar_pros.Paint = function() end

        scroll_bar_pros.btnUp.Paint = function(span, w, h)
        end
        scroll_bar_pros.btnDown.Paint = function(span, w, h)
        end
        scroll_bar_pros.btnGrip.Paint = PaintScrollBar

        -- It's kind of weird to have some stats disappear depending on state
        local pros, cons, infos = ArcCW:GetProsCons(atttbl) -- self.Attachments[slot].ToggleNum

        pros = pros or {}
        cons = cons or {}
        infos = infos or {}

        local p_w = menu3_w / 2

        local pan_pros = vgui.Create("DPanel", scroll_pros)
        pan_pros:SetPos(0, 0)
        pan_pros.Paint = function() end

        local pan_cons = vgui.Create("DPanel", scroll_pros)
        pan_cons:SetPos(#pros > 0 and (menu3_w * 1 / 2) or 0, 0)
        pan_cons.Paint = function() end

        local pan_infos

        if #infos > 0 then
            pan_infos = vgui.Create("DPanel", scroll_pros)
            pan_infos:SetWide(menu3_w)
            pan_infos.Paint = function() end
        end
        p_w = (pan_pros and pan_cons) and (menu3_w / 2) or p_w

        local function linepaintfunc(self2, w, h)
            surface.SetDrawColor(Color(self2.Color.r, self2.Color.g, self2.Color.b, self2.Color.a * ArcCW.Inv_Fade))
            surface.SetMaterial(pickx_full)

            local imsize = h * 0.45

            surface.DrawTexturedRect((h - imsize) / 2, ((h - imsize) / 2) + (ss * 2), imsize, imsize)

            local tp = h + (ss * 2)

            surface.SetFont("ArcCWC2_10_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos(tp, 0)
            DrawTextRot(self2, self2.Text, tp, 0, tp, 0, self2:GetWide() - tp)

            surface.SetFont("ArcCWC2_10")
            surface.SetTextColor(Color(self2.Color.r, self2.Color.g, self2.Color.b, self2.Color.a * ArcCW.Inv_Fade))
            surface.SetTextPos(tp, 0)
            DrawTextRot(self2, self2.Text, tp, 0, tp, 0, self2:GetWide() - tp, true)
        end

        local function headpaintfunc(self2, w, h)
            local tp = 0

            surface.SetFont("ArcCWC2_8_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos(tp, 0)
            DrawTextRot(self2, self2.Text, tp, 0, tp, 0, self2:GetWide() - tp)

            surface.SetFont("ArcCWC2_8")
            surface.SetTextColor(Color(self2.Color.r, self2.Color.g, self2.Color.b, self2.Color.a * ArcCW.Inv_Fade))
            surface.SetTextPos(tp, 0)
            DrawTextRot(self2, self2.Text, tp, 0, tp, 0, self2:GetWide() - tp, true)
        end

        if #pros > 0 then
            local pan_head = vgui.Create("DPanel", pan_pros)
            pan_head:SetTall(rss * 8)
            pan_head:Dock(TOP)
            pan_head.Paint = headpaintfunc
            pan_head.Text = translate("ui.positives")
            pan_head.Color = col_good
        end

        if #cons > 0 then
            local pan_head = vgui.Create("DPanel", pan_cons)
            pan_head:SetTall(rss * 8)
            pan_head:Dock(TOP)
            pan_head.Paint = headpaintfunc
            pan_head.Text = translate("ui.negatives")
            pan_head.Color = col_bad
        end

        for i, line in pairs(pros) do
            if !line or line == "" then continue end
            local pan_line = vgui.Create("DPanel", pan_pros)
            pan_line:SetSize(p_w, rss * 10)
            pan_line:SetPos(0, rss * 10 * i)
            pan_line.Paint = linepaintfunc
            pan_line.Text = line
            pan_line.Color = col_good
        end

        pan_pros:SizeToChildren(true, true)

        for i, line in pairs(cons) do
            if !line or line == "" then continue end
            local pan_line = vgui.Create("DPanel", pan_cons)
            pan_line:SetSize(p_w, rss * 10)
            pan_line:SetPos(0, rss * 10 * i)
            pan_line.Paint = linepaintfunc
            pan_line.Text = line
            pan_line.Color = col_bad
        end

        pan_cons:SizeToChildren(true, true)

        if #infos > 0 then
            local pan_head = vgui.Create("DPanel", pan_infos)
            pan_head:SetTall(rss * 8)
            pan_head:Dock(TOP)
            pan_head.Paint = headpaintfunc
            pan_head.Text = translate("ui.information")
            pan_head.Color = col_info

            for i, line in pairs(infos) do
                if !line or line == "" then continue end
                local pan_line = vgui.Create("DPanel", pan_infos)
                pan_line:SetSize(menu3_w, rss * 10)
                pan_line:SetPos(0, rss * 10 * i)
                pan_line.Paint = linepaintfunc
                pan_line.Text = line
                pan_line.Color = col_info
            end

            -- We can't do this on initialize because SizeToChildren isn't called yet
            local h = math.max(pan_pros and pan_pros:GetTall() or 0, pan_cons and pan_cons:GetTall() or 0)
            h = (h > 0) and (h + rss * 10) or 0 -- if only info, don't add padding
            pan_infos:SetPos(0, h)
            pan_infos:SizeToChildren(true, true)
        end
    end

    function ArcCW.InvHUD_FormStatsTriviaBar()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        local statsbutton = vgui.Create("DButton", ArcCW.InvHUD_Menu3)
        statsbutton:SetSize(ss * 48, ss * 16)
        statsbutton:SetPos(menu3_w - (ss * 48 * 2) - airgap_x - (ss * 4), rss * 48 + ss * 12)
        statsbutton:SetText("")
        statsbutton.Text = "Stats"
        statsbutton.Val = 1
        statsbutton.DoClick = function(self2, clr, btn)
            ArcCW.InvHUD_FormWeaponStats()
            ArcCW.Inv_SelectedInfo = 1
        end
        statsbutton.Paint = function(self2, w, h)
            local col = col_button
            local col2 = col_fg

            if self2:IsHovered() or ArcCW.Inv_SelectedInfo == self2.Val then
                col = col_fg_tr
                col2 = col_shadow
            end

            draw.RoundedBox(cornerrad, 0, 0, w, h, col)

            surface.SetFont("ArcCWC2_8")
            local tw, th = surface.GetTextSize(self2.Text)

            surface.SetFont("ArcCWC2_8_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos((w - tw) / 2, (h - th) / 2)
            surface.DrawText(self2.Text)

            surface.SetFont("ArcCWC2_8")
            surface.SetTextColor(col2)
            surface.SetTextPos((w - tw) / 2, (h - th) / 2)
            surface.DrawText(self2.Text)
        end

        local triviabutton = vgui.Create("DButton", ArcCW.InvHUD_Menu3)
        triviabutton:SetSize(ss * 48, ss * 16)
        triviabutton:SetPos(menu3_w - ss * 48 - airgap_x, rss * 48 + ss * 12)
        triviabutton:SetText("")
        triviabutton.Text = "Trivia"
        triviabutton.Val = 2
        triviabutton.DoClick = function(self2, clr, btn)
            ArcCW.InvHUD_FormWeaponTrivia()
            ArcCW.Inv_SelectedInfo = 2
        end
        triviabutton.Paint = statsbutton.Paint
    end

    function ArcCW.InvHUD_FormWeaponName()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_FormStatsTriviaBar()
        local weapon_title = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        weapon_title:SetSize(menu3_w, rss * 32)
        weapon_title:SetPos(0, 0)
        weapon_title.Paint = function(self2, w, h)
            if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
            local name = translate("name." .. self:GetClass() .. (GetConVar("arccw_truenames"):GetBool() and ".true" or "")) or translate(self.PrintName) or self.PrintName

            surface.SetFont("ArcCWC2_32")
            local tw = surface.GetTextSize(name)

            surface.SetTextColor(col_shadow)
            surface.SetFont("ArcCWC2_32_Glow")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x)

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCWC2_32")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x, true)
        end

        local weapon_cat = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        weapon_cat:SetSize(menu3_w, rss * 16)
        weapon_cat:SetPos(0, rss * 32)
        weapon_cat.Paint = function(self2, w, h)
            if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
            local class = translate(self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class) or self:GetBuff_Override("Override_Trivia_Class") or self.Trivia_Class
            local cal = translate(self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre) or self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre
            local name = class

            if !self.PrimaryMelee and !self.Throwing and cal then
                name = name .. ", " .. cal
            end

            surface.SetFont("ArcCWC2_16")
            local tw = surface.GetTextSize(name)

            surface.SetTextColor(col_shadow)
            surface.SetFont("ArcCWC2_16_Glow")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x)

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCWC2_16")
            surface.SetTextPos(w - tw - airgap_x, 0)
            DrawTextRot(self2, name, 0, 0, 0, 0, w - airgap_x, true)
        end
    end

    function ArcCW.InvHUD_FormWeaponTrivia()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_Menu3:Clear()
        ArcCW.InvHUD_FormWeaponName()

        local scroll = vgui.Create("DScrollPanel", ArcCW.InvHUD_Menu3)
        scroll:SetSize(menu3_w - airgap_x, ss * 110)
        scroll:SetPos(0, rss * 48 + ss * 32)

        local scroll_bar = scroll:GetVBar()
        scroll_bar.Paint = function() end

        scroll_bar.btnUp.Paint = function(span, w, h)
        end
        scroll_bar.btnDown.Paint = function(span, w, h)
        end
        scroll_bar.btnGrip.Paint = PaintScrollBar

        local multiline = {}
        local desc = translate(self:GetBuff_Override("Override_Trivia_Desc")) or translate("desc." .. self:GetClass()) or self.Trivia_Desc

        multiline = multlinetext(desc, scroll:GetWide() - (ss * 2), "ArcCW_10")

        local desc_title = vgui.Create("DPanel", scroll)
        desc_title:SetSize(scroll:GetWide(), rss * 8)
        desc_title:Dock(TOP)
        desc_title.Paint = function(self2, w, h)
            surface.SetFont("ArcCWC2_8")
            local txt = translate("trivia.description")
            local tw_1 = surface.GetTextSize(txt)

            surface.SetFont("ArcCWC2_8_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos(w - tw_1, 0)
            surface.DrawText(txt)

            surface.SetFont("ArcCWC2_8")
            surface.SetTextColor(col_fg)
            surface.SetTextPos(w - tw_1, 0)
            surface.DrawText(txt)
        end

        for i, text in pairs(multiline) do
            local desc_line = vgui.Create("DPanel", scroll)
            desc_line:SetSize(scroll:GetWide(), rss * 10)
            desc_line:Dock(TOP)
            desc_line.Paint = function(self2, w, h)
                surface.SetFont("ArcCWC2_10")
                local tw = surface.GetTextSize(text)

                surface.SetFont("ArcCWC2_10_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw, 0)
                surface.DrawText(text)

                surface.SetFont("ArcCWC2_10")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw, 0)
                surface.DrawText(text)
            end
        end

        local info = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        info:SetSize(menu3_w - airgap_x, menu3_h - ss * 110 - rss * 48 - ss * 32)
        info:SetPos(0, rss * 48 + ss * 32 + ss * 110)
        info.Paint = function(self2, w, h)
            local infos = self.Infos_Trivia or {}

            local year = self:GetBuff_Override("Override_Trivia_Year") or self.Trivia_Year

            if year then
                if isnumber(year) and year < 0 then
                    table.insert(infos, {
                        title = translate("trivia.year"),
                        value = tostring(-year),
                        unit = translate("unit.bce"),
                    })
                else
                    table.insert(infos, {
                        title = translate("trivia.year"),
                        value = tostring(year),
                    })
                end
            end

            local mech = self:GetBuff_Override("Override_Trivia_Mechanism") or self.Trivia_Mechanism

            if mech then
                table.insert(infos, {
                    title = translate("trivia.mechanism"),
                    value = translate(mech) or mech,
                })
            end

            local country = self:GetBuff_Override("Override_Trivia_Country") or self.Trivia_Country

            if country then
                table.insert(infos, {
                    title = translate("trivia.country"),
                    value = translate(country) or country,
                })
            end

            local manufacturer = self:GetBuff_Override("Override_Trivia_Manufacturer") or self.Trivia_Manufacturer

            if manufacturer then
                table.insert(infos, {
                    title = translate("trivia.manufacturer"),
                    value = translate(manufacturer) or manufacturer,
                })
            end

            local calibre = self:GetBuff_Override("Override_Trivia_Calibre") or self.Trivia_Calibre

            if calibre then
                table.insert(infos, {
                    title = translate("trivia.calibre"),
                    value = translate(calibre) or calibre,
                })
            end

            for i, triv in pairs(infos) do
                triv.unit = triv.unit or ""
                local i_2 = i - 1
                surface.SetFont("ArcCWC2_8")
                local tw_1 = surface.GetTextSize(triv.title)

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw_1, i_2 * (rss * 24))
                surface.DrawText(triv.title)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw_1, i_2 * (rss * 24))
                surface.DrawText(triv.title)

                surface.SetFont("ArcCWC2_8")
                local tw_2 = surface.GetTextSize(triv.unit)

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw_2, (i_2 * (rss * 24)) + (rss * 12))
                surface.DrawText(triv.unit)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw_2, (i_2 * (rss * 24)) + (rss * 12))
                surface.DrawText(triv.unit)

                surface.SetFont("ArcCWC2_16")
                local tw_3 = surface.GetTextSize(tostring(triv.value))

                surface.SetFont("ArcCWC2_16_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw_2 - tw_3, (i_2 * (rss * 24)) + (rss * 6))
                -- surface.DrawText(triv.value)
                DrawTextRot(self2, triv.value, 0, i_2 * (rss * 24), math.max(w - tw_2 - tw_3, 0), (i_2 * (rss * 24)) + (rss * 6), w)

                -- (span, txt, x, y, tx, ty, maxw, only)

                surface.SetFont("ArcCWC2_16")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw_2 - tw_3, (i_2 * (rss * 24)) + (rss * 6))
                -- surface.DrawText(triv.value)
                DrawTextRot(self2, triv.value, 0, i_2 * (rss * 24), math.max(w - tw_2 - tw_3, 0), (i_2 * (rss * 24)) + (rss * 6), w, true)
            end
        end
    end

    function ArcCW.InvHUD_FormWeaponStats()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        ArcCW.InvHUD_Menu3:Clear()
        ArcCW.InvHUD_FormWeaponName()

        local info = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        info:SetSize(menu3_w - airgap_x, menu3_h - ss * 110 - rss * 48 - ss * 32)
        info:SetPos(0, rss * 48 + ss * 32 + ss * 110)
        info.Paint = function(self2, w, h)
            if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
            local infos = self.Infos_Stats or {}

            -- rpm
            local rpm = math.Round(60 / self:GetFiringDelay())

            if self:GetIsManualAction() then
                local fireanim = self:GetBuff_Hook("Hook_SelectFireAnimation") or self:SelectAnimation("fire")
                local firedelay = self.Animations[fireanim].MinProgress or 0
                rpm = math.Round(60 / ((firedelay + self:GetAnimKeyTime("cycle", true)) * self:GetBuff_Mult("Mult_CycleTime")))
            end

            if self:GetIsManualAction() then
                table.insert(infos, {
                    title = translate("trivia.firerate"),
                    value = "~" .. tostring(rpm),
                    unit = translate("unit.rpm"),
                })
            elseif !self.PrimaryBash and !self.Throwing then
                table.insert(infos, {
                    title = translate("trivia.firerate"),
                    value = rpm,
                    unit = translate("unit.rpm"),
                })
            end

            -- precision
            local precision = math.Round(self:GetBuff("AccuracyMOA"), 1)

            if !self.PrimaryBash and !self.Throwing then
                table.insert(infos, {
                    title = translate("trivia.precision"),
                    value = precision,
                    unit = translate("unit.moa"),
                })
            end

            -- ammo type
            if self.Primary.Ammo and self.Primary.Ammo != "" and self.Primary.Ammo != "none" then
                local ammotype = language.GetPhrase(self.Primary.Ammo .. "_ammo")
                if ammotype then
                    table.insert(infos, {
                        title = translate("trivia.ammo"),
                        value = ammotype,
                    })
                end
            end

            -- penetration
            local shootent = self:GetBuff("ShootEntity", true)

            if !self.PrimaryBash and !shootent then
                local pen  = self:GetBuff("Penetration")
                table.insert(infos, {
                    title = translate("trivia.penetration"),
                    value = pen,
                    unit = translate("unit.mm"),
                })
            end

            -- noise
            local noise = self:GetBuff("ShootVol")

            if !self.PrimaryBash then
                table.insert(infos, {
                    title = translate("trivia.noise"),
                    value = noise,
                    unit = translate("unit.db"),
                })
            end

            if self.PrimaryBash then
                local meleedelay = self.MeleeTime * self:GetBuff_Mult("Mult_MeleeTime")
                table.insert(infos, {
                    title = translate("trivia.attackspersecond"),
                    value = tostring(math.Round(1 / meleedelay, 1)),
                    unit = translate("unit.aps")
                })

                local meleerange = self:GetBuff("MeleeRange")
                table.insert(infos, {
                    title = translate("trivia.range"),
                    value = tostring(math.Round(meleerange * ArcCW.HUToM)),
                    unit = "m"
                })

                local dmg = self.MeleeDamage * self:GetBuff_Mult("Mult_MeleeDamage")
                table.insert(infos, {
                    title = translate("trivia.damage"),
                    value = dmg,
                })

                local dmgtype = self:GetBuff_Override("Override_MeleeDamageType") or self.MeleeDamageType

                if ArcCW.MeleeDamageTypes[dmgtype or ""] then
                    table.insert(infos, {
                        title = translate("trivia.meleedamagetype"),
                        value = translate(ArcCW.MeleeDamageTypes[dmgtype]),
                    })
                end
            end

            if self.Throwing then
                local ft = self:GetBuff_Override("Override_FuseTime") or self.FuseTime

                table.insert(infos, {
                    title = translate("trivia.fusetime"),
                    value = tostring(math.Round(ft, 1)),
                    unit = "s"
                })
            end

            for i, triv in pairs(infos) do
                triv.unit = triv.unit or ""
                local i_2 = i - 1
                surface.SetFont("ArcCWC2_8")
                local tw_1 = surface.GetTextSize(triv.title)

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw_1, i_2 * (rss * 24))
                surface.DrawText(triv.title)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw_1, i_2 * (rss * 24))
                surface.DrawText(triv.title)


                surface.SetFont("ArcCWC2_16")
                local tw_3a = select(2, surface.GetTextSize(tostring(triv.value)))

                surface.SetFont("ArcCWC2_8")
                local tw_2 = surface.GetTextSize(triv.unit)
                local tw_2a = select(2, surface.GetTextSize(triv.unit))

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(w - tw_2, (i_2 * (rss * 24)) + (rss * 4.4) + tw_2a)
                surface.DrawText(triv.unit)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(w - tw_2, (i_2 * (rss * 24)) + (rss * 4.4) + tw_2a)
                surface.DrawText(triv.unit)

                surface.SetFont("ArcCWC2_16")
                local tw_3 = surface.GetTextSize(tostring(triv.value))

                surface.SetFont("ArcCWC2_16_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos(math.max(w - tw_2 - tw_3, 0), (i_2 * (rss * 24)) + (rss * 6))
                surface.DrawText(triv.value)

                surface.SetFont("ArcCWC2_16")
                surface.SetTextColor(col_fg)
                surface.SetTextPos(math.max(w - tw_2 - tw_3, 0), (i_2 * (rss * 24)) + (rss * 6))
                surface.DrawText(triv.value)
            end
        end

        local rangegraph = vgui.Create("DPanel", ArcCW.InvHUD_Menu3)
        rangegraph:SetSize(ss * 200, ss * 110)
        rangegraph:SetPos(menu3_w - ss * 200 - airgap_x, rss * 48 + ss * 32)
        rangegraph.Paint = function(self2, w, h)
            if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
            if self.PrimaryBash or
                self.ShootEntity or
                self:GetBuff_Override("Override_ShootEntity") or
                self.NoRangeGraph
            then
                draw.RoundedBox(cornerrad, 0, 0, w, h, col_button)

                local txt = "No Data"

                surface.SetTextColor(col_fg)
                surface.SetFont("ArcCWC2_24")
                local tw, th = surface.GetTextSize(txt)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(txt)

                return
            end

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

            scale = math.max(scale, 75)
            hscale = math.max(hscale, 100)

            draw.RoundedBox(cornerrad, 0, 0, w, h, col_button)

            local thicc = math.ceil(ss * 2)

            -- segment 1: minimum range
            local x_1 = 0
            local y_1 = h - (dmgmax / scale * h)
            y_1 = math.Clamp(y_1, ss * 16, h - (ss * 16))
            -- segment 2: slope
            local x_2 = 0
            local y_2 = y_1
            if mran > 0 then
                x_2 = w * 1 / 3
            end
            -- segment 3: maximum range
            local x_3 = w * 2 / 3
            local y_3 = h - (dmgmin / scale * h)
            y_3 = math.Clamp(y_3, ss * 16, h - (ss * 16))

            local x_4 = w
            local y_4 = y_3

            if sran == mran then
                x_2 = w / 2
                x_3 = w / 2
            end

            local col_vline = LerpColor(0.5, col_fg, Color(0, 0, 0, 0))

            surface.SetDrawColor(col_vline)

            -- line for min range
            if dmgmax != dmgmin and mran > 0 then
                surface.DrawLine(x_2, 0, x_2, h)
            end

            -- line for max range
            if dmgmax != dmgmin then
                surface.DrawLine(x_3, 0, x_3, h)
            end

            -- damage number text
            for i = 1, thicc do
                local meth = ((thicc - i) / thicc)
                surface.SetDrawColor(255, 255, 255, Lerp(ArcCW.Inv_Fade, 0, 127 * meth))

                local of
                if i == 1 then
                    surface.SetDrawColor(col_fg)
                    of = 0
                elseif (i % 2 == 0) then
                    -- even
                    of = -1 * i / 2
                else
                    -- odd
                    of = 1 * i / 2
                end

                if mran > 0 then
                    -- draw seg 1
                    surface.DrawLine(x_1, y_1 + of, x_2, y_2 + of)
                end
                -- draw seg 2
                surface.DrawLine(x_2, y_2 + of, x_3, y_3 + of)
                -- drag seg 3
                surface.DrawLine(x_3, y_3 + of, x_4, y_4 + of)
            end

            surface.SetTextColor(col_fg)
            surface.SetFont("ArcCWC2_8")

            local function RangeText(range)
                local metres = tostring(math.Round(range)) .. "m"
                local hu = tostring(math.Round(range / ArcCW.HUToM)) .. "HU"

                return metres, hu
            end

            if dmgmax != dmgmin then
                local m_1, hu_1 = RangeText(0)

                surface.SetTextPos(ss * 2, h - rss * 16)
                surface.DrawText(m_1)
                surface.SetTextPos(ss * 2, h - rss * 10)
                surface.DrawText(hu_1)
            end

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

            if dmgmax != dmgmin and sran != mran then
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
        end
    end

    function ArcCW.InvHUD_FormGamemodeFunctions()
        if !IsValid(ArcCW.InvHUD) or !IsValid(self) then return end
        if !GetConVar("arccw_attinv_gamemodebuttons"):GetBool() then return end

        local shoulddrawtitle = false
        local function paint_gmbutton(self2, w, h)
            local col = col_button
            local col2 = col_fg

            if self2:IsHovered() then
                col = col_fg_tr
                col2 = col_shadow
            end

            draw.RoundedBox(cornerrad, 0, 0, w, h, col)

            surface.SetFont("ArcCWC2_14")
            local tw, th = surface.GetTextSize(self2.Text)

            surface.SetFont("ArcCWC2_14_Glow")
            surface.SetTextColor(col_shadow)
            surface.SetTextPos((w - tw) / 2, (h - th) / 2)
            surface.DrawText(self2.Text)

            surface.SetFont("ArcCWC2_14")
            surface.SetTextColor(col2)
            surface.SetTextPos((w - tw) / 2, (h - th) / 2)
            surface.DrawText(self2.Text)
        end

        if engine.ActiveGamemode() == "terrortown" then
            shoulddrawtitle = true
            local shop = vgui.Create("DButton", ArcCW.InvHUD)
            shop:SetSize(ss * 64, ss * 24)
            shop:SetPos(ScrW() * 0.5 - ss * (64 + 4), ScrH() - ss * (24 + 10))
            shop:SetText("")
            shop.Text = translate("ui.tttequip")
            shop.DoClick = function(self2, clr, btn)
                RunConsoleCommand("ttt_cl_traitorpopup")
            end
            shop.Paint = paint_gmbutton

            local quickchat = vgui.Create("DButton", ArcCW.InvHUD)
            quickchat:SetSize(ss * 64, ss * 24)
            quickchat:SetPos(ScrW() * 0.5 + ss * 4, ScrH() - ss * (24 + 10))
            quickchat:SetText("")
            quickchat.Text = translate("ui.tttchat")
            quickchat.DoClick = function(self2, clr, btn)
                if RADIO then RADIO:ShowRadioCommands(!RADIO.Show) end
            end
            quickchat.Paint = paint_gmbutton
        elseif engine.ActiveGamemode() == "darkrp" or DarkRP then
            -- Check for the global table, as DarkRP has many derivatives
            shoulddrawtitle = true
            local drop = vgui.Create("DButton", ArcCW.InvHUD)
            drop:SetSize(ss * 96, ss * 24)
            drop:SetPos(ScrW() * 0.5 - ss * 48, ScrH() - ss * (24 + 10))
            drop:SetText("")
            drop.Text = translate("ui.darkrpdrop")
            drop.DoClick = function(self2, clr, btn)
                LocalPlayer():ConCommand("say /drop")
            end
            drop.Paint = paint_gmbutton
        end

        if shoulddrawtitle then
            local text = vgui.Create("DPanel", ArcCW.InvHUD)
            text:SetSize(ss * 256, ss * 12)
            text:SetPos(ScrW() * 0.5 - ss * 128, ScrH() - ss * (24 + 12 + 12))
            text.Paint = function(self2, w, h)
                local col2 = col_fg
                local str = translate("ui.gamemode_buttons")
                surface.SetFont("ArcCWC2_12")
                local tw, th = surface.GetTextSize(str)

                surface.SetFont("ArcCWC2_12_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(str)

                surface.SetFont("ArcCWC2_12")
                surface.SetTextColor(col2)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(str)
            end

            local text2 = vgui.Create("DPanel", ArcCW.InvHUD)
            text2:SetSize(ss * 256, ss * 8)
            text2:SetPos(ScrW() * 0.5 - ss * 128, ScrH() - ss * 9)
            text2.Paint = function(self2, w, h)
                local col2 = col_fg
                local str = translate("ui.gamemode_usehint")
                surface.SetFont("ArcCWC2_8")
                local tw, th = surface.GetTextSize(str)

                surface.SetFont("ArcCWC2_8_Glow")
                surface.SetTextColor(col_shadow)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(str)

                surface.SetFont("ArcCWC2_8")
                surface.SetTextColor(col2)
                surface.SetTextPos((w - tw) / 2, (h - th) / 2)
                surface.DrawText(str)
            end
        end
    end

    clearrightpanel()

    ArcCW.Inv_SelectedMenu = ArcCW.Inv_SelectedMenu or 1

    if ArcCW.Inv_SelectedMenu == 1 then
        ArcCW.InvHUD_FormAttachments()
        if self.Inv_SelectedSlot then
            ArcCW.InvHUD_FormAttachmentSelect()
        end
    elseif ArcCW.Inv_SelectedMenu == 2 then
        ArcCW.InvHUD_FormPresets()
    elseif ArcCW.Inv_SelectedMenu == 3 then
        ArcCW.InvHUD_FormInventory()
    end

    ArcCW.InvHUD_FormGamemodeFunctions()

end