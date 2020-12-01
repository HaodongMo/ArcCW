local srf      = surface



local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

local blacklistWindow = nil
local blacklistTbl    = {}
local filter          = ""
local onlyblacklisted = false
local internalName    = false
local dragMode = nil

local color_arccwbred = Color(150, 50, 50, 255)
local color_arccwlred = Color(125, 25, 25, 150)
local color_arccwdred = Color(75, 0, 0, 150)
local color_arccwdtbl = Color(0, 0, 0, 200)

local function SaveBlacklist()
    -- We send ID over instead of strings to save on network costs
    -- optimization_is_optimization.png

    local blacklistAmt = 0

    for attName, bStatus in pairs(blacklistTbl) do
        if bStatus then blacklistAmt = blacklistAmt + 1 end
    end

    net.Start("arccw_blacklist")
        net.WriteBool(false)
        net.WriteUInt(blacklistAmt, ArcCW.GetBitNecessity())
        for attName, bStatus in pairs(blacklistTbl) do
            if bStatus then
                net.WriteUInt(ArcCW.AttachmentTable[attName].ID, ArcCW.GetBitNecessity())
            end
        end
    net.SendToServer()

    blacklistTbl = {}
end

local function CreateAttButton(parent, attName, attTbl)
    local attBtn = vgui.Create("DButton", parent)
    attBtn:SetFont("ArcCW_8")
    attBtn:SetText("")
    attBtn:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(16))
    attBtn:Dock(TOP)
    attBtn:DockMargin(ScreenScaleMulti(36), ScreenScaleMulti(1), ScreenScaleMulti(36), ScreenScaleMulti(1))
    attBtn:SetContentAlignment(5)

    attBtn.Paint = function(spaa, w, h)
        local blisted = blacklistTbl[attName]
        if blisted == nil then blisted = attTbl.Blacklisted end

        local hovered = spaa:IsHovered()
        local blackhov = blisted and hovered

        local Bfg_col = blackhov and color_arccwbred or blisted and color_arccwbred or hovered and color_black or color_white
        local Bbg_col = blackhov and color_arccwlred or blisted and color_arccwdred or hovered and color_white or color_arccwdtbl

        srf.SetDrawColor(Bbg_col)
        srf.DrawRect(0, 0, w, h)

        local img = attTbl.Icon
        if img then
            srf.SetDrawColor(Bfg_col)
            srf.SetMaterial(img)
            srf.DrawTexturedRect(ScreenScaleMulti(2), 0, h, h)
        end

        local txt = attTbl.PrintName
        if internalName then txt = attName end
        srf.SetTextColor(Bfg_col)
        srf.SetTextPos(ScreenScaleMulti(20), ScreenScaleMulti(2))
        srf.SetFont("ArcCW_12")
        srf.DrawText(txt)

        local listed   = (blacklistTbl[attName] and !attTbl.Blacklisted)
        local unlisted = (attTbl.Blacklisted and !blacklistTbl[attName])
        local saved = (listed or unlisted) and " [not saved]" or ""
        srf.SetTextColor(Bfg_col)
        srf.SetTextPos(spaa:GetWide() - ScreenScaleMulti(36), ScreenScaleMulti(4))
        srf.SetFont("ArcCW_8")
        srf.DrawText(saved)
    end

    -- In addition to clicking on a button, you can drag over all of them!
    attBtn.OnMousePressed = function(spaa, kc)
        blacklistTbl[attName] = !blacklistTbl[attName] and !attTbl.Blacklisted or !blacklistTbl[attName]
        dragMode = blacklistTbl[attName]
        hook.Add("Think", "ArcCW_Blacklist", function()
            if !input.IsMouseDown(MOUSE_LEFT) then
                dragMode = nil
                hook.Remove("Think", "ArcCW_Blacklist")
            end
        end)
    end
    attBtn.OnCursorEntered = function(spaa, kc)
        if dragMode != nil and input.IsMouseDown(MOUSE_LEFT) then
            blacklistTbl[attName] = dragMode
        end
    end

    return attBtn
end

function ArcCW.MakeBlacklistWindow()
    if blacklistWindow then blacklistWindow:Remove() end

    blacklistTbl = {}

    blacklistWindow = vgui.Create("DFrame")
    blacklistWindow:SetSize(ScrW() * 0.5, ScrH() * 0.75)
    blacklistWindow:Center()
    blacklistWindow:SetTitle("")
    blacklistWindow:SetDraggable(false)
    blacklistWindow:SetVisible(true)
    blacklistWindow:ShowCloseButton(true)
    blacklistWindow:MakePopup()
    blacklistWindow.Paint = function(self, w, h)
        srf.SetDrawColor(color_arccwdtbl)
        srf.DrawRect(0, 0, w, h)
    end

    local title = vgui.Create("DLabel", blacklistWindow)
    title:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(26))
    title:Dock(TOP)
    title:SetFont("ArcCW_24")
    title:SetText("ArcCW Blacklist")
    title:DockMargin(ScreenScaleMulti(16), 0, ScreenScaleMulti(16), ScreenScaleMulti(8))

    local desc = vgui.Create("DLabel", blacklistWindow)
    desc:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(12))
    desc:Dock(TOP)
    desc:DockMargin(ScreenScaleMulti(4), 0, ScreenScaleMulti(4), ScreenScaleMulti(4))
    desc:SetFont("ArcCW_12")
    desc:SetText("Attachments checked here will stop showing up at all.")
    desc:SetContentAlignment(5)

    local attList = vgui.Create("DScrollPanel", blacklistWindow)
    attList:SetText("")
    attList:Dock(FILL)
    attList:SetContentAlignment(5)
    attList.Paint = function(span, w, h) end

    local sbar = attList:GetVBar()
    sbar.Paint = function() end
    sbar.btnUp.Paint = function(span, w, h) end
    sbar.btnDown.Paint = function(span, w, h) end
    sbar.btnGrip.Paint = function(span, w, h)
        srf.SetDrawColor(color_white)
        srf.DrawRect(0, 0, w, h)
    end

    local FilterPanel = vgui.Create("DPanel", blacklistWindow)
    FilterPanel:Dock(TOP)
    FilterPanel:DockMargin(ScreenScaleMulti(16), ScreenScaleMulti(2), ScreenScaleMulti(16), ScreenScaleMulti(2))
    FilterPanel:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(12))
    FilterPanel:SetPaintBackground(false)

    local FilterLabel = vgui.Create("DLabel", FilterPanel)
    FilterLabel:Dock(LEFT)
    FilterLabel:SetWidth(ScreenScaleMulti(36))
    FilterLabel:DockMargin(ScreenScaleMulti(2), ScreenScaleMulti(2), ScreenScaleMulti(2), ScreenScaleMulti(2))
    FilterLabel:SetFont("ArcCW_12")
    FilterLabel:SetText("FILTER")

    local FilterButton = vgui.Create("DButton", FilterPanel)
    FilterButton:SetFont("ArcCW_8")
    FilterButton:SetText("")
    FilterButton:SetSize(ScreenScaleMulti(48), ScreenScaleMulti(12))
    FilterButton:Dock(RIGHT)
    FilterButton:DockMargin(ScreenScaleMulti(1), 0, 0, 0)
    FilterButton:SetContentAlignment(5)

    FilterButton.OnMousePressed = function(spaa, kc)
        onlyblacklisted = !onlyblacklisted

        attList:GenerateButtonsToList()
    end

    FilterButton.Paint = function(spaa, w, h)
        local hovered = spaa:IsHovered()

        local Bfg_col = hovered and color_black or color_white
        local Bbg_col = hovered and color_white or color_arccwdtbl

        srf.SetDrawColor(Bbg_col)
        srf.DrawRect(0, 0, w, h)

        spaa:SetTextColor(Bfg_col)
        spaa:SetText(onlyblacklisted and "BLACKLISTED" or "ALL")
    end

    local NameButton = vgui.Create("DButton", FilterPanel)
    NameButton:SetFont("ArcCW_8")
    NameButton:SetText("")
    NameButton:SetSize(ScreenScaleMulti(24), ScreenScaleMulti(12))
    NameButton:Dock(RIGHT)
    NameButton:DockMargin(ScreenScaleMulti(1), 0, 0, 0)
    NameButton:SetContentAlignment(5)

    NameButton.OnMousePressed = function(spaa, kc)
        internalName = !internalName
        attList:GenerateButtonsToList()
    end

    NameButton.Paint = function(spaa, w, h)
        local hovered = spaa:IsHovered()

        local Bfg_col = hovered and color_black or color_white
        local Bbg_col = hovered and color_white or color_arccwdtbl

        srf.SetDrawColor(Bbg_col)
        srf.DrawRect(0, 0, w, h)

        spaa:SetTextColor(Bfg_col)
        spaa:SetText(internalName and "ID" or "NAME")
    end

    local FilterEntry = vgui.Create("DTextEntry", FilterPanel)
    FilterEntry:Dock(FILL)
    FilterEntry:SetValue(filter)
    FilterEntry:SetFont("ArcCW_12")
    FilterEntry.OnChange = function( self )
        filter = self:GetValue():lower()

        attList:GenerateButtonsToList()
    end

    local accept = vgui.Create("DButton", blacklistWindow)
    accept:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(20))
    accept:SetText("")
    accept:Dock(BOTTOM)
    accept:DockMargin(ScreenScaleMulti(48), ScreenScaleMulti(2), ScreenScaleMulti(48), ScreenScaleMulti(2))
    accept:SetContentAlignment(5)

    accept.OnMousePressed = function(spaa, kc)
        SaveBlacklist()

        blacklistWindow:Close()
        blacklistWindow:Remove()
    end

    accept.Paint = function(spaa, w, h)
        local hovered = spaa:IsHovered()

        local Bfg_col = hovered and color_black or color_white
        local Bbg_col = hovered and color_white or color_arccwdtbl

        srf.SetDrawColor(Bbg_col)
        srf.DrawRect(0, 0, w, h)

        srf.SetTextColor(Bfg_col)
        srf.SetTextPos(ScreenScaleMulti(4), ScreenScaleMulti(4))
        srf.SetFont("ArcCW_12")
        srf.DrawText("Save")
    end

    -- Perhaps unoptimized, but it's client
    -- client_side_calculations_is_not_expensive.png
    function attList:GenerateButtonsToList()
        self:GetCanvas():Clear()

        for attName, attTbl in SortedPairsByMemberValue(ArcCW.AttachmentTable, "PrintName") do
            if attTbl.Hidden then continue end

            if attTbl.Blacklisted then blacklistTbl[attName] = true end

            if onlyblacklisted and !(attTbl.Blacklisted or blacklistTbl[attName]) then continue end

            if filter != "" and !(string.find((attTbl.PrintName):lower(), filter) or string.find((attName):lower(), filter)) then continue end

            --if attTbl.Slot == "charm" then continue end why the fuck would you do this

            CreateAttButton(self, attName, attTbl)
        end
    end

    attList:GenerateButtonsToList()
end

concommand.Add("arccw_blacklist", function()
    if LocalPlayer():IsAdmin() then ArcCW.MakeBlacklistWindow() end
end)