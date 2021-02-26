ArcCW.IncompatibleAddons = {
    -- ["2137567877"] = "Causes viewmodel flickering with LHIK attachments",
    ["847269692"] = "Causes viewmodel flickering, may crash when customization menu opens",
    ["1875551051"] = "Breaks LHIK attachments. VManip has similar features and doesn't conflict.",
    ["306149085"] = "Makes the customize menu mouse unable to appear.",
    ["541434990"] = "Neurotec is ancient, half the base is missing, and it flat-out doesn't work. Causes all sorts of problems. For the love of god, let go.", -- Neurotec
    --["1100368137"] = "May cause Lua errors. Use the wOS version instead.", -- Prone Mod
    ["476997621"] = "Causes issues with arms.",
    -- ["1308077613"] = "Will make near-walling look exaggerated; known to conflict with cBobbing.", -- View model bump, should be fixed
    -- ["1429489453"] = "Causes issues with arms." -- bio annihilation extended sninctbur
    ["1588705429"] = "Causes damage calculation to not work properly.", -- Realistic Bullet Overhaul
}

local t = ArcCW.GetTranslation

local function ScreenScaleMulti(input)
    return ScreenScale(input) * GetConVar("arccw_hud_size"):GetFloat()
end

function ArcCW.MakeIncompatibleWindow(tbl)
    local startTime = CurTime()

    local window = vgui.Create( "DFrame" )
    window:SetSize( ScrW() * 0.6, ScrH() * 0.6)
    window:Center()
    window:SetTitle("")
    window:SetDraggable(false)
    window:SetVisible(true)
    window:ShowCloseButton(false)
    window:MakePopup()
    window.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, w, h)
    end

    local title = vgui.Create("DLabel", window)
    title:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(26))
    title:Dock(TOP)
    title:SetFont("ArcCW_24")
    title:SetText(t("incompatible.title"))
    title:DockMargin(ScreenScaleMulti(16), 0, ScreenScaleMulti(16), ScreenScaleMulti(8))

    local desc = vgui.Create("DLabel", window)
    desc:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(12))
    desc:Dock(TOP)
    desc:DockMargin(ScreenScaleMulti(4), 0, ScreenScaleMulti(4), 0)
    desc:SetFont("ArcCW_12")
    desc:SetText(t("incompatible.line1"))
    desc:SetContentAlignment(5)

    local desc2 = vgui.Create("DLabel", window)
    desc2:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(12))
    desc2:Dock(TOP)
    desc2:DockMargin(ScreenScaleMulti(4), 0, ScreenScaleMulti(4), ScreenScaleMulti(4))
    desc2:SetFont("ArcCW_12")
    desc2:SetText(t("incompatible.line2"))
    desc2:SetContentAlignment(5)

    local neverAgain = vgui.Create("DButton", window)
    neverAgain:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(20))
    neverAgain:SetText("")
    neverAgain:Dock(BOTTOM)
    neverAgain:DockMargin(ScreenScaleMulti(48), ScreenScaleMulti(2), ScreenScaleMulti(48), ScreenScaleMulti(2))
    neverAgain.OnMousePressed = function(spaa, kc)
        if CurTime() > startTime + 10 then
            local simpleTbl = {}
            for _, v in pairs(tbl) do simpleTbl[tostring(v.wsid)] = true end
            file.Write("arccw_incompatible.txt", util.TableToJSON(simpleTbl))
            window:Close()
            window:Remove()
            chat.AddText(Color(255,0,0),t("incompatible.never.confirm"))
        end
    end
    neverAgain.Paint = function(spaa, w, h)
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 200)

        if CurTime() > startTime + 10 and spaa:IsHovered() then
            Bbg_col = Color(255, 100, 100, 100)
            Bfg_col = Color(255, 255, 255, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = (CurTime() > startTime + 10) and (spaa:IsHovered() and t("incompatible.never.hover") or t("incompatible.never")) or t("incompatible.wait", {time = math.ceil(startTime + 10 - CurTime())})
        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScaleMulti(8), ScreenScaleMulti(2))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    local addonList = vgui.Create("DScrollPanel", window)
    addonList:SetText("")
    addonList:Dock(FILL)
    addonList.Paint = function(span, w, h) end
    local sbar = addonList:GetVBar()
    sbar.Paint = function() end
    sbar.btnUp.Paint = function(span, w, h) end
    sbar.btnDown.Paint = function(span, w, h) end
    sbar.btnGrip.Paint = function(span, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(0, 0, w, h)
    end


    local accept = vgui.Create("DButton", window)
    accept:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(20))
    accept:SetText("")
    accept:Dock(BOTTOM)
    accept:DockMargin(ScreenScaleMulti(48), ScreenScaleMulti(2), ScreenScaleMulti(48), ScreenScaleMulti(2))
    accept.OnMousePressed = function(spaa, kc)
        if CurTime() > startTime + 5 then
            window:Close()
            window:Remove()
        end
    end
    accept.Paint = function(spaa, w, h)
        local Bfg_col = Color(255, 255, 255, 255)
        local Bbg_col = Color(0, 0, 0, 200)

        if CurTime() > startTime + 5 and spaa:IsHovered() then
            Bbg_col = Color(255, 255, 255, 100)
            Bfg_col = Color(0, 0, 0, 255)
        end

        surface.SetDrawColor(Bbg_col)
        surface.DrawRect(0, 0, w, h)

        local txt = t("incompatible.confirm") .. ((CurTime() > startTime + 5) and "" or (" - " .. t("incompatible.wait", {time = math.ceil(startTime + 5 - CurTime())})))
        surface.SetTextColor(Bfg_col)
        surface.SetTextPos(ScreenScaleMulti(8), ScreenScaleMulti(2))
        surface.SetFont("ArcCW_12")
        surface.DrawText(txt)
    end

    for _, addon in pairs(tbl) do
        local addonBtn = vgui.Create("DButton", window)
        addonBtn:SetSize(ScreenScaleMulti(256), ScreenScaleMulti(28))
        addonBtn:Dock(TOP)
        addonBtn:DockMargin(ScreenScaleMulti(36), ScreenScaleMulti(2), ScreenScaleMulti(36), ScreenScaleMulti(2))
        addonBtn:SetFont("ArcCW_12")
        addonBtn:SetText("")
        addonBtn:SetContentAlignment(5)
        addonBtn.Paint = function(spaa, w, h)
            local Bfg_col = Color(255, 255, 255, 255)
            local Bbg_col = Color(0, 0, 0, 200)

            if spaa:IsHovered() then
                Bbg_col = Color(255, 255, 255, 100)
                Bfg_col = Color(0, 0, 0, 255)
            end

            surface.SetDrawColor(Bbg_col)
            surface.DrawRect(0, 0, w, h)

            local txt = addon.title
            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScaleMulti(18), ScreenScaleMulti(2))
            surface.SetFont("ArcCW_12")
            surface.DrawText(txt)

            local txt2 = ArcCW.IncompatibleAddons[tostring(addon.wsid)]
            surface.SetTextColor(Bfg_col)
            surface.SetTextPos(ScreenScaleMulti(18), ScreenScaleMulti(16))
            surface.SetFont("ArcCW_8")
            surface.DrawText(txt2)
        end
        addonBtn.OnMousePressed = function(spaa, kc)
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. tostring(addon.wsid))
        end
    end
end

hook.Add("InitPostEntity", "ArcCW_CheckContent", function()
    for _, k in pairs(weapons.GetList()) do
        if weapons.IsBasedOn(k.ClassName, "arccw_base") and k.ClassName != "arccw_base" then
            return
        end
    end
    chat.AddText(Color(255,255,255), "You have installed ArcCW Base but have no content packs installed. Perhaps you want to install the CS+ pack?")
    chat.AddText(Color(255,255,255), "https://steamcommunity.com/sharedfiles/filedetails/?id=2131058270")
end)