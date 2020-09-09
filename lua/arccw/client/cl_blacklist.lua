local srf      = surface
local ScrScale = ScreenScale

local blacklistWindow = nil
local blacklistTbl    = {}
local filter          = ""
local onlyblacklisted = false

local color_arccwbred = Color(150, 50, 50, 255)
local color_arccwlred = Color(125, 25, 25, 150)
local color_arccwdred = Color(75, 0, 0, 150)
local color_arccwdtbl = Color(0, 0, 0, 200)

local Scr256, Scr48, Scr36, Scr20    = ScrScale(256), ScrScale(48), ScrScale(36), ScrScale(20)
local Scr16, Scr12, Scr4, Scr2, Scr1 =  ScrScale(16), ScrScale(12), ScrScale(4), ScrScale(2), ScrScale(1)

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
    attBtn:SetSize(Scr256, Scr16)
    attBtn:Dock(TOP)
    attBtn:DockMargin(Scr36, Scr1, Scr36, Scr1)
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
            srf.DrawTexturedRect(Scr2, 0, h, h)
        end

        local txt = attTbl.PrintName
        srf.SetTextColor(Bfg_col)
        srf.SetTextPos(Scr20, Scr2)
        srf.SetFont("ArcCW_12")
        srf.DrawText(txt)

        local listed   = (blacklistTbl[attName] and not attTbl.Blacklisted)
        local unlisted = (attTbl.Blacklisted and not blacklistTbl[attName])
        local saved = (listed or unlisted) and " [not saved]" or ""
        srf.SetTextColor(Bfg_col)
        srf.SetTextPos(spaa:GetWide() - Scr36, Scr4)
        srf.SetFont("ArcCW_8")
        srf.DrawText(saved)
    end

    attBtn.OnMousePressed = function(spaa, kc)
        blacklistTbl[attName] = not blacklistTbl[attName] and not attTbl.Blacklisted or not blacklistTbl[attName]
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
    title:SetSize(Scr256, ScrScale(26))
    title:Dock(TOP)
    title:SetFont("ArcCW_24")
    title:SetText("ArcCW Blacklist")
    title:DockMargin(Scr16, 0, Scr16, ScrScale(8))

    local desc = vgui.Create("DLabel", blacklistWindow)
    desc:SetSize(Scr256, Scr12)
    desc:Dock(TOP)
    desc:DockMargin(Scr4, 0, Scr4, Scr4)
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
    FilterPanel:DockMargin(Scr16, Scr2, Scr16, Scr2)
    FilterPanel:SetSize(Scr256, Scr12)
    FilterPanel:SetPaintBackground(false)

    local FilterLabel = vgui.Create("DLabel", FilterPanel)
    FilterLabel:Dock(LEFT)
    FilterLabel:SetWidth(Scr36)
    FilterLabel:DockMargin(Scr2, Scr2, Scr2, Scr2)
    FilterLabel:SetFont("ArcCW_12")
    FilterLabel:SetText("FILTER")

    local FilterButton = vgui.Create("DButton", FilterPanel)
    FilterButton:SetFont("ArcCW_8")
    FilterButton:SetText("")
    FilterButton:SetSize(Scr48, Scr12)
    FilterButton:Dock(RIGHT)
    FilterButton:DockMargin(Scr1, 0, 0, 0)
    FilterButton:SetContentAlignment(5)

    FilterButton.OnMousePressed = function(spaa, kc)
        onlyblacklisted = not onlyblacklisted

        attList:GenerateButtonsToList()
    end

    FilterButton.Paint = function(spaa, w, h)
        local hovered = spaa:IsHovered()

        local Bfg_col = hovered and color_black or color_white
        local Bbg_col = hovered and color_white or color_arccwdtbl

        srf.SetDrawColor(Bbg_col)
        srf.DrawRect(0, 0, w, h)

        spaa:SetTextColor(Bfg_col)
        spaa:SetText(onlyblacklisted and "ALL" or "BLACKLISTED")
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
    accept:SetSize(Scr256, Scr20)
    accept:SetText("")
    accept:Dock(BOTTOM)
    accept:DockMargin(Scr48, Scr2, Scr48, Scr2)
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
        srf.SetTextPos(Scr4, Scr4)
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

            if onlyblacklisted and not (attTbl.Blacklisted or blacklistTbl[attName]) then continue end

            if filter ~= "" and not string.find((attTbl.PrintName):lower(), filter) then continue end

            --if attTbl.Slot == "charm" then continue end why the fuck would you do this

            CreateAttButton(self, attName, attTbl)
        end
    end

    attList:GenerateButtonsToList()
end

concommand.Add("arccw_blacklist", function()
    if LocalPlayer():IsAdmin() then ArcCW.MakeBlacklistWindow() end
end)