-- atts are comma separated
-- optic_mrs,,,perk_quickdraw,ammo_match



local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

function SWEP:GetPresetBase()
    return self.PresetBase or self:GetClass()
end

function SWEP:GetPresets()
    local path = ArcCW.PresetPath .. self:GetPresetBase() .. "/*.txt"

    local files = file.Find(path, "DATA")

    files = table.Add(files, file.Find(ArcCW.PresetPath .. self:GetPresetBase() .. "/*.json", "DATA"))

    return files
end

function SWEP:LoadPreset(presetname)
    presetname = presetname or "autosave"
    if presetname == "autosave" then
        if self:GetNWBool("ArcCW_DisableAutosave", false) then return end
        if !GetConVar("arccw_autosave"):GetBool() then return end
    end

    if presetname != "autosave" then
        surface.PlaySound("weapons/arccw/install.wav")
    end

    -- ???
    self.Attachments.BaseClass = nil

    local presetTbl


    -- New behavior
    local filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. presetname .. ".json"
    if file.Exists(filename, "DATA") then
        presetTbl = util.JSONToTable(file.Read(filename))
        if presetTbl and presetTbl != {} then
            for i = 1, table.Count(self.Attachments) do
                local ok = true

                if !presetTbl[i] or !ArcCW.AttachmentTable[presetTbl[i].Installed or ""] then
                    ok = false
                end

                if !ok then
                    presetTbl[i] = nil
                end
            end
        end
    end

    -- Legacy behavior
    filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. presetname .. ".txt"
    if presetTbl == nil and file.Exists(filename, "DATA") then
        local f = file.Open(filename, "r", "DATA")
        if !f then return end

        presetTbl = {}

        for i = 1, table.Count(self.Attachments) do
            local line = f:ReadLine()
            if !line then continue end
            local split = string.Split(string.Trim(line, "\n"), ",")
            if !ArcCW.AttachmentTable[split[1]] then continue end
            presetTbl[i] = {
                Installed = split[1],
                SlidePos = split[2] and tonumber(split[2]),
                SightMagnifications = split[3] and tonumber(split[3]),
                ToggleNum = nil, -- not implemented in legacy preset
            }
        end
        f:Close()
    end

    if !presetTbl then return end

    net.Start("arccw_applypreset")
    net.WriteEntity(self)
    for k, v in pairs(self.Attachments) do
        local att = (presetTbl[k] or {}).Installed

        if !att or !ArcCW.AttachmentTable[att] then
            net.WriteUInt(0, ArcCW.GetBitNecessity())
            continue
        end

        net.WriteUInt(ArcCW.AttachmentTable[att].ID, ArcCW.GetBitNecessity())

        net.WriteBool(presetTbl[k].SlidePos)
        if presetTbl[k].SlidePos then
            net.WriteFloat(presetTbl[k].SlidePos)
        end

        if ArcCW.AttachmentTable[att].ToggleStats != nil then
            net.WriteUInt(presetTbl[k].ToggleNum or 1, 8)
        end
        v.ToggleNum = presetTbl[k].ToggleNum or 1

        -- not networked
        self.SightMagnifications[k] = presetTbl[k].SightMagnifications
    end
    net.SendToServer()

    --[[]
    for i = 1, table.Count(self.Attachments) do
        local att = presetTbl[i]
        if !att then continue end

        if ArcCW:PlayerGetAtts(self:GetOwner(), att) == 0 then continue end
        if !self.Attachments[i] then continue end

        -- detect commas
        -- no commas = do nothing
        -- commas: If exactly two commas are detected
        -- try to parse them as slidepos, magnification

        local split = string.Split(att, ",")
        local sc = table.Count(split)

        local slidepos = 0.5
        local mag = -1

        if sc == 3 then
            att = split[1]
            slidepos = tonumber(split[2])
            mag = tonumber(split[3])
        end

        if att == self.Attachments[i].Installed then continue end

        self:Detach(i, true, true)

        if !ArcCW.AttachmentTable[att] then continue end

        self:Attach(i, att, true, true)

        if slidepos != 0.5 then
            self.Attachments[i].SlidePos = slidepos
        end

        if mag != -1 then
            self.SightMagnifications[i] = mag
        end
    end

    self:SendAllDetails()

    self:SavePreset()
    ]]
end

function SWEP:SavePreset(presetname)
    presetname = presetname or "autosave"
    if presetname == "autosave" and !GetConVar("arccw_attinv_free"):GetBool() then return end

    local presetTbl = {}
    for i, k in pairs(self.Attachments) do
        if k.Installed then
            presetTbl[i] = {
                Installed = k.Installed,
                SlidePos = k.SlidePos,
                SightMagnifications = self.SightMagnifications[i],
                ToggleNum = k.ToggleNum
            }
        end
    end

    filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. presetname .. ".json"
    file.CreateDir(ArcCW.PresetPath .. self:GetPresetBase())
    file.Write(filename, util.TableToJSON(presetTbl))

    local legacy_filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. presetname .. ".txt"
    if file.Exists(legacy_filename, "DATA") then
        file.Delete(legacy_filename)
    end

    -- Legacy presets
    --[[]
    local str = ""
    for i, k in pairs(self.Attachments) do
        if k.Installed then
            str = str .. k.Installed
            if k.SlidePos or self.SightMagnifications[i] then
                str = str .. "," .. tostring(k.SlidePos or 0.5) .. "," .. tostring(self.SightMagnifications[i] or -1)
            end
        end

        str = str .. "\n"
    end

    filename = ArcCW.PresetPath .. self:GetPresetBase() .. "/" .. filename .. ".txt"

    file.CreateDir(ArcCW.PresetPath .. self:GetPresetBase())
    file.Write(filename, str)
    ]]
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
    text:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(26))
    text:Center()
    text:RequestFocus()
    text:SetFont("ArcCW_24")
    text:SetText(self.LastPresetName or "")

    local accept = vgui.Create("DButton", bg)
    accept:SetSize((ScreenScaleMulti(256) - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
    accept:SetText("")
    accept:SetPos((ScrW() - ScreenScaleMulti(256)) / 2, ((ScrH() - ScreenScaleMulti(14)) / 2) + ScreenScaleMulti(26) + ScreenScaleMulti(2))

    accept.OnMousePressed = function(spaa, kc)
        local txt = text:GetText()
        txt = string.sub(txt, 0, 36)
        self.LastPresetName = txt
        self:SavePreset(txt)
        bg:Close()
        bg:Remove()

        ArcCW.InvHUD_FormPresets()
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
        surface.SetTextPos(ScreenScaleMulti(2), ScreenScaleMulti(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local cancel = vgui.Create("DButton", bg)
    cancel:SetSize((ScreenScaleMulti(256) - ScreenScaleMulti(2)) / 2, ScreenScaleMulti(14))
    cancel:SetText("")
    cancel:SetPos(((ScrW() - ScreenScaleMulti(256)) / 2) + ScreenScaleMulti(128 + 1), ((ScrH() - ScreenScaleMulti(14)) / 2) + ScreenScaleMulti(26) + ScreenScaleMulti(2))

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
        surface.SetTextPos(ScreenScaleMulti(2), ScreenScaleMulti(1))
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
    cancel:SetSize(ScreenScaleMulti(128), ScreenScaleMulti(14))
    cancel:SetText("")
    cancel:SetPos((ScrW() - ScreenScaleMulti(128)) / 2, ScrH() - ScreenScaleMulti(32))

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
        surface.SetTextPos(ScreenScaleMulti(2), ScreenScaleMulti(1))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local presetsmenu = vgui.Create("DScrollPanel", bg)
    presetsmenu:SetText("")
    presetsmenu:SetSize(ScreenScaleMulti(256), ScrH() - ScreenScaleMulti(64))
    presetsmenu:SetPos((ScrW() - ScreenScaleMulti(256)) / 2, ScreenScaleMulti(8))
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
        if string.StripExtension(k) == "autosave" then continue end
        local preset = vgui.Create("DButton", presetsmenu)
        preset:SetSize(ScreenScaleMulti(254), ScreenScaleMulti(14))
        preset:SetText("")
        preset:Dock(TOP)
        preset:DockMargin( 0, 0, 0, ScreenScaleMulti(2) )

        preset.PresetName = string.StripExtension(k) --string.sub(k, 1, -5)
        preset.PresetFile = k

        preset.OnMousePressed = function(spaa, kc)
            self.LastPresetName = spaa.PresetName
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
            surface.SetTextPos(ScreenScaleMulti(2), ScreenScaleMulti(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(string.upper(spaa.PresetName))
        end

        local close = vgui.Create("DButton", preset)
        close:SetSize(ScreenScaleMulti(16), ScreenScaleMulti(16))
        close:SetText("")
        close:Dock(RIGHT)

        close.OnMousePressed = function(spaa, kc)
            local filename = spaa.PresetFile
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
            surface.SetTextPos((ScreenScaleMulti(16) - w_x) / 2, (ScreenScaleMulti(16) - h_x) / 2)
            surface.SetFont("ArcCW_12")
            surface.DrawText("×")
        end
        c = c + 1
    end

    if c == 0 then
        local label = vgui.Create("DLabel", presetsmenu)
        label:SetSize(ScreenScaleMulti(254), ScreenScaleMulti(14))
        label:SetText("")
        label:Dock(TOP)
        label:DockMargin( 0, 0, 0, ScreenScaleMulti(2) )

        label.Paint = function(spaa, w, h)
            local Bfg_col = Color(255, 255, 255, 255)

            local txt = "No presets found! Go make some!"

            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScaleMulti(2), ScreenScaleMulti(1))
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)
        end
    end
end

function SWEP:ClosePresetMenu()
end