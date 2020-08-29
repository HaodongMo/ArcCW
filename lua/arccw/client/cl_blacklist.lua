local blacklistWindow = nil
local blacklistTbl = {}

function ArcCW.MakeBlacklistWindow()
    if blacklistWindow then blacklistWindow:Remove() end

    blacklistTbl = {}

    blacklistWindow = vgui.Create( "DFrame" )
    blacklistWindow:SetSize( ScrW() * 0.4, ScrH() * 0.75)
    blacklistWindow:Center()
    blacklistWindow:SetTitle("")
    blacklistWindow:SetDraggable(false)
    blacklistWindow:SetVisible(true)
    blacklistWindow:ShowCloseButton(true)
    blacklistWindow:MakePopup()
    blacklistWindow.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, w, h)
    end

    local title = vgui.Create("DLabel", blacklistWindow)
    title:SetSize(ScreenScale(256), ScreenScale(26))
    title:Dock(TOP)
    title:SetFont("ArcCW_24")
    title:SetText("ArcCW Blacklist")
    title:DockMargin(ScreenScale(16), 0, ScreenScale(16), ScreenScale(8))

    local desc = vgui.Create("DLabel", blacklistWindow)
    desc:SetSize(ScreenScale(256), ScreenScale(12))
    desc:Dock(TOP)
    desc:DockMargin(ScreenScale(4), 0, ScreenScale(4), ScreenScale(4))
    desc:SetFont("ArcCW_12")
    desc:SetText("Attachments checked here will stop showing up at all.")
    desc:SetContentAlignment(5)

    local attList = vgui.Create("DScrollPanel", blacklistWindow)
    attList:SetText("")
    attList:Dock(FILL)
    attList.Paint = function(span, w, h) end
    local sbar = attList:GetVBar()
    sbar.Paint = function() end
    sbar.btnUp.Paint = function(span, w, h) end
    sbar.btnDown.Paint = function(span, w, h) end
    sbar.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local accept = vgui.Create("DButton", blacklistWindow)
    accept:SetSize(ScreenScale(256), ScreenScale(20))
    accept:SetText("")
    accept:Dock(BOTTOM)
    accept:DockMargin(ScreenScale(48), ScreenScale(2), ScreenScale(48), ScreenScale(2))
    accept.OnMousePressed = function(spaa, kc)
        -- We send ID over instead of strings to save on network costs
        -- optimization_is_optimization.png

        local blacklistAmt = 0

        for attName, bStatus in pairs(blacklistTbl) do
            if bStatus then
                blacklistAmt = blacklistAmt + 1
            end
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
        blacklistWindow:Close()
        blacklistWindow:Remove()
    end
    accept.Paint = function(spaa, w, h)
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 200)

        if spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = "Save"
        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScale(8), ScreenScale(2))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    for attName, attTbl in SortedPairsByMemberValue(ArcCW.AttachmentTable, "PrintName") do

        --if attTbl.Slot == "charm" then continue end why the fuck would you do this

        -- We have to do this because we're no longer using deltas
        if attTbl.Blacklisted then blacklistTbl[attName] = true end

        local attBtn = vgui.Create("DButton", attList)
        attBtn:SetSize(ScreenScale(256), ScreenScale(16))
        attBtn:Dock(TOP)
        attBtn:DockMargin(ScreenScale(36), ScreenScale(1), ScreenScale(36), ScreenScale(1))
        attBtn:SetFont("ArcCW_8")
        attBtn:SetText("")
        attBtn:SetContentAlignment(5)
        attBtn.Paint = function(spaa, w, h)
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 200)

            local isBlacklisted = blacklistTbl[attName]
            if isBlacklisted == nil then isBlacklisted = attTbl.Blacklisted end

            if isBlacklisted and spaa:IsHovered() then
                Bbg_col = Color(125, 25, 25, 150)
                Bfg_col = Color(150, 50, 50, 255)
            elseif isBlacklisted then
                Bbg_col = Color(75, 0, 0, 150)
                Bfg_col = Color(150, 50, 50, 255)
            elseif spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            local img = attTbl.Icon
            if img then
                surface.SetDrawColor(Bfg_col)
                surface.SetMaterial(img)
                surface.DrawTexturedRect(ScreenScale(2), 0, h, h)
            end

            local txt = attTbl.PrintName
            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScale(20), 0)
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)
        end
        attBtn.OnMousePressed = function(spaa, kc)
            if blacklistTbl[attName] == nil then
                blacklistTbl[attName] = !attTbl.Blacklisted
            else
                blacklistTbl[attName] = !blacklistTbl[attName]
            end
        end
    end
end

concommand.Add("arccw_blacklist", function()
    if LocalPlayer():IsAdmin() then
        ArcCW.MakeBlacklistWindow()
    end
end)