-- atts are comma separated
-- optic_mrs,,,perk_quickdraw,ammo_match

function SWEP:GetPresetBase()
    return self.PresetBase or self:GetClass()
end

function SWEP:GetPresets()
    local path = ArcCW.PresetPath .. self:GetPresetBase() .. "/*.txt"

    local files = file.Find(path, "DATA")

    return files
end

function SWEP:LoadPreset(filename)
    filename = filename or "autosave"
    if !GetConVar("arccw_autosave"):GetBool() then
        if filename == "autosave" then return end
    end

    if filename != "autosave" then
        surface.PlaySound("weapons/arccw/install.wav")
    end

    filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. filename .. ".txt"

    if !file.Exists(filename, "DATA") then return end

    local f = file.Open(filename, "r", "DATA")

    if !f then return end

    local ver = 1

    for i = 1, table.Count(self.Attachments) do
        local att = f:ReadLine()

        if !att then continue end

        att = string.Trim(att, "\n")

        if att == "v2" then ver = 2 continue end

        if !att then continue end

        if !self.Attachments[i] then continue end

        -- last 5 chars = slide pos
        -- next last 5 chars = magnification

        if att == self.Attachments[i].Installed then continue end

        self:Detach(i, true)

        if !ArcCW.AttachmentTable[att] then continue end

        self:Attach(i, att, true)
    end

    f:Close()

    self:SavePreset()
end

function SWEP:SavePreset(filename)
    filename = filename or "autosave"

    local str = ""
    for i, k in pairs(self.Attachments) do
        if k.Installed then
            str = str .. k.Installed .. "\n"
        else
            str = str .. "\n"
        end
    end

    filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. filename .. ".txt"

    file.CreateDir(ArcCW.PresetPath .. self:GetPresetBase())
    file.Write(filename, str)
end

function SWEP:CreatePresetSave()
    if !IsValid(ArcCW.InvHUD) then return end
    local bg = vgui.Create("DFrame", ArcCW.InvHUD)
    bg:SetPos(0, 0)
    bg:SetSize(ScrW(), ScrH())
    bg:SetText("")
    bg:SetTitle("")
    bg:SetDraggable(false)
    bg:ShowCloseButton(false)
    bg.Paint = function(span)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
    bg:MakePopup()

    local text = vgui.Create("DTextEntry", bg)
    text:SetSize(ScreenScale(256), ScreenScale(26))
    text:Center()
    text:RequestFocus()
    text:SetFont("ArcCW_24")
    text:SetText("")

    local accept = vgui.Create("DButton", bg)
    accept:SetSize((ScreenScale(256) - ScreenScale(2)) / 2, ScreenScale(14))
    accept:SetText("")
    accept:SetPos((ScrW() - ScreenScale(256)) / 2, ((ScrH() - ScreenScale(14)) / 2) + ScreenScale(26) + ScreenScale(2))

    accept.OnMousePressed = function(spaa, kc)
        local txt = text:GetText()
        txt = string.sub(txt, 0, 36)
        self:SavePreset(txt)
        bg:Close()
        bg:Remove()
    end

    accept.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = "Save"

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScale(2), ScreenScale(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local cancel = vgui.Create("DButton", bg)
    cancel:SetSize((ScreenScale(256) - ScreenScale(2)) / 2, ScreenScale(14))
    cancel:SetText("")
    cancel:SetPos(((ScrW() - ScreenScale(256)) / 2) + ScreenScale(128 + 1), ((ScrH() - ScreenScale(14)) / 2) + ScreenScale(26) + ScreenScale(2))

    cancel.OnMousePressed = function(spaa, kc)
        bg:Close()
        bg:Remove()
    end

    cancel.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = "Cancel"

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScale(2), ScreenScale(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end
end

function SWEP:CreatePresetMenu()
    if !IsValid(ArcCW.InvHUD) then return end

    if !IsValid(ArcCW.InvHUD) then return end
    local bg = vgui.Create("DFrame", ArcCW.InvHUD)
    bg:SetPos(0, 0)
    bg:SetSize(ScrW(), ScrH())
    bg:SetText("")
    bg:SetTitle("")
    bg:SetDraggable(false)
    bg:ShowCloseButton(false)
    bg.Paint = function(span)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    local cancel = vgui.Create("DButton", bg)
    cancel:SetSize(ScreenScale(128), ScreenScale(14))
    cancel:SetText("")
    cancel:SetPos((ScrW() - ScreenScale(128)) / 2, ScrH() - ScreenScale(32))

    cancel.OnMousePressed = function(spaa, kc)
        bg:Close()
        bg:Remove()
    end

    cancel.Paint = function(spaa, w, h)
        if !self:IsValid() then return end
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 100)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = "Cancel"

        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScale(2), ScreenScale(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local presetsmenu = vgui.Create("DScrollPanel", bg)
    presetsmenu:SetText("")
    presetsmenu:SetSize(ScreenScale(256), ScrH() - ScreenScale(64))
    presetsmenu:SetPos((ScrW() - ScreenScale(256)) / 2, ScreenScale(8))
    presetsmenu.Paint = function(span, w, h)
    end

    local sbar = presetsmenu:GetVBar()
    sbar.Paint = function() end

    sbar.btnUp.Paint = function(span, w, h)
    end

    sbar.btnDown.Paint = function(span, w, h)
    end

    sbar.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local c = 0

    for i, k in pairs(self:GetPresets()) do
        if k == "autosave.txt" then continue end
        local preset = vgui.Create("DButton", presetsmenu)
        preset:SetSize(ScreenScale(254), ScreenScale(14))
        preset:SetText("")
        preset:Dock(TOP)
        preset:DockMargin( 0, 0, 0, ScreenScale(2) )

        preset.PresetName = string.sub(k, 1, -5)

        preset.OnMousePressed = function(spaa, kc)
            self:LoadPreset(spaa.PresetName)
            bg:Close()
            bg:Remove()
        end

        preset.Paint = function(spaa, w, h)
            if !self:IsValid() then return end
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 100)

            if spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScale(2), ScreenScale(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(string.upper(spaa.PresetName))
        end

        local close = vgui.Create("DButton", preset)
        close:SetSize(ScreenScale(16), ScreenScale(16))
        close:SetText("")
        close:Dock(RIGHT)

        close.OnMousePressed = function(spaa, kc)
            local filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. k
            file.Delete(filename)
            preset:Remove()
        end

        close.Paint = function(spaa, w, h)
            if !self:IsValid() or preset:IsHovered() then return end
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 100)

            if spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            local w_x, h_x = surface.GetTextSize("×")
            surface.SetTextColor(Bfg_col)
            surface.SetTextPos((ScreenScale(16) - w_x) / 2, (ScreenScale(16) - h_x) / 2)
            surface.SetFont("ArcCW_12")
            surface.DrawText("×")
        end
        c = c + 1
    end

    if c == 0 then
        local label = vgui.Create("DLabel", presetsmenu)
        label:SetSize(ScreenScale(254), ScreenScale(14))
        label:SetText("")
        label:Dock(TOP)
        label:DockMargin( 0, 0, 0, ScreenScale(2) )

        label.Paint = function(spaa, w, h)
            local Bfg_col = Color(255, 255, 255, 255)

            local txt = "No presets found! Go make some!"

            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScale(2), ScreenScale(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)
        end
    end
end

function SWEP:ClosePresetMenu()
end