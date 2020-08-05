if engine.ActiveGamemode() != "terrortown" then return end

CreateClientConVar("arccw_ttt_inforoundstart", "1", true, false, "Whether to show ArcCW config every round.")
CreateClientConVar("arccw_ttt_rolecrosshair", "1", true, false, "Whether to color your crosshair according to your role.")

ArcCW.TTT_AttInfo = ArcCW.TTT_AttInfo or {}

net.Receive("arccw_ttt_bodyattinfo", function()
    local rag = net.ReadEntity()
    rag = rag:EntIndex()
    ArcCW.TTT_AttInfo[rag] = {}
    local atts = net.ReadUInt(8)
    for i = 1, atts do
        local id = net.ReadUInt(ArcCW.GetBitNecessity())
        if id != 0 then
            --ArcCW.TTT_AttInfo[rag][i] = ArcCW.AttachmentIDTable[id]
            table.insert(ArcCW.TTT_AttInfo[rag], ArcCW.AttachmentIDTable[id])
        end
    end
end)

hook.Add("TTTBodySearchPopulate", "ArcCW_PopulateHUD", function(processed, raw)

    -- Attachment Info
    local mode = GetConVar("arccw_ttt_bodyattinfo"):GetInt()
    local attTbl = ArcCW.TTT_AttInfo[raw.eidx]
    if attTbl and table.Count(attTbl) > 0 and (mode == 2 or (mode == 1 and raw.detective_search)) then
        local finalTbl = {
            img	= "arccw/ttticons/arccw_dropattinfo.png",
            p = 10.5, -- Right after the murder weapon
            text = ArcCW.GetTranslation(mode == 1 and "ttt.bodyatt.founddet" or "ttt.bodyatt.found")
        }
        local count = table.Count(attTbl)
        if count == 1 then
            if not ArcCW.AttachmentTable[attTbl[1]] then return end
            local printName = ArcCW.GetTranslation("name." .. attTbl[1]) or ArcCW.AttachmentTable[attTbl[1]].PrintName
            finalTbl.text = finalTbl.text .. ArcCW.GetTranslation("ttt.bodyatt.att1", {att = printName})
        elseif count == 2 then
            if not ArcCW.AttachmentTable[attTbl[1]] or not ArcCW.AttachmentTable[attTbl[2]] then return end
            local printName1 = ArcCW.GetTranslation("name." .. attTbl[1]) or ArcCW.AttachmentTable[attTbl[1]].PrintName
            local printName2 = ArcCW.GetTranslation("name." .. attTbl[2]) or ArcCW.AttachmentTable[attTbl[2]].PrintName
            finalTbl.text = finalTbl.text .. ArcCW.GetTranslation("ttt.bodyatt.att2", {att1 = printName1, att2 = printName2})
        else
            finalTbl.text = finalTbl.text .. ArcCW.GetTranslation("ttt.bodyatt.att3")
            local comma = false
            for i, v in pairs(attTbl) do
                if v and ArcCW.AttachmentTable[v] then
                    local printName = ArcCW.GetTranslation("name." .. v) or ArcCW.AttachmentTable[v].PrintName
                    finalTbl.text = finalTbl.text .. (comma and ", " or "") .. printName
                    comma = true
                end
            end
            finalTbl.text = finalTbl.text .. "."
        end
        processed.arccw_atts = finalTbl
    end

    -- kill info
    if bit.band(raw.dmg, DMG_BUCKSHOT) == DMG_BUCKSHOT then
        processed.dmg.text = LANG.GetTranslation("search_dmg_buckshot")
        processed.dmg.img = "arccw/ttticons/kill_buckshot.png"
    elseif bit.band(raw.dmg, DMG_NERVEGAS) == DMG_NERVEGAS then
        processed.dmg.text = LANG.GetTranslation("search_dmg_nervegas")
        processed.dmg.img = "arccw/ttticons/kill_nervegas.png"
    end
end)

local function AddLine(parent, str)
    local pw, ph = parent:GetSize()
    local label = vgui.Create("DLabel", parent)
    label:SetSize(pw, ScreenScale(8))
    label:Dock(TOP)
    label:DockMargin(ScreenScale(4), ScreenScale(1), ScreenScale(4), ScreenScale(1))
    label:SetFont("ArcCW_8")
    label:SetTextColor(Color(255,255,255,255))
    label:SetText(str)
    return label
end

local infoBox = nil
local function CreateInfoBox(t)
    if infoBox then
        infoBox:Remove()
        timer.Remove("ArcCW_TTT_InfoBox")
    end

    local totalw, totalh = ScrW() * 0.25, ScrH() * 0.2
    infoBox = vgui.Create("DPanel")
    infoBox:SetSize(totalw, totalh)
    infoBox:SetPos(ScreenScale(2), ScrH() * 0.5)
    infoBox.Paint = function(span, w, h)
        surface.SetDrawColor(Color(0, 0, 0, 150))
        surface.DrawRect(0, 0, w, h)
    end

    local label = vgui.Create("DLabel", infoBox)
    label:SetSize(totalw, ScreenScale(12))
    label:Dock(TOP)
    label:DockMargin(ScreenScale(4), ScreenScale(2), ScreenScale(4), ScreenScale(2))
    label:SetTextColor(Color(255,255,255,255))
    label:SetFont("ArcCW_12")
    label:SetText(ArcCW.GetTranslation("ttt.roundinfo"))

    if GetConVar("arccw_ttt_replace"):GetBool() then
        AddLine(infoBox, ArcCW.GetTranslation("ttt.roundinfo.replace"))
    end

    local cmode_str = "ttt.roundinfo.cmode" .. GetConVar("arccw_ttt_customizemode"):GetInt()
    AddLine(infoBox, ArcCW.GetTranslation("ttt.roundinfo.cmode") .. " " .. ArcCW.GetTranslation(cmode_str))

    local att_str = ""
    local att_cvar = GetConVar("arccw_attinv_free"):GetBool()
    local att_cvar2 = GetConVar("arccw_attinv_lockmode"):GetBool()
    local att_cvar3 = GetConVar("arccw_attinv_loseondie"):GetBool()
    if att_cvar then
        att_str = "ttt.roundinfo.free"
    elseif att_cvar2 then
        att_str = "ttt.roundinfo.locking"
    else
        att_str = "ttt.roundinfo.inv"
    end
    att_str = ArcCW.GetTranslation(att_str)
    if att_cvar3 == 0 then
        att_str = att_str .. ", " .. ArcCW.GetTranslation("ttt.roundinfo.persist")
    elseif not att_cvar and not att_cvar2 and att_cvar3 == 2 then
        att_str = att_str .. ", " .. ArcCW.GetTranslation("ttt.roundinfo.drop")
    end
    if GetConVar("arccw_atts_pickx"):GetInt() > 0 then
        att_str = att_str .. ", " .. ArcCW.GetTranslation("ttt.roundinfo.pickx") .. " " .. GetConVar("arccw_atts_pickx"):GetInt()
    end
    AddLine(infoBox, ArcCW.GetTranslation("ttt.roundinfo.attmode") .. " " .. att_str)

    local binfo_cvar = GetConVar("arccw_ttt_bodyattinfo"):GetInt()
    AddLine(infoBox, ArcCW.GetTranslation("ttt.roundinfo.bmode") .. " " .. ArcCW.GetTranslation("ttt.roundinfo.bmode" .. binfo_cvar))

    if GetConVar("arccw_ttt_replaceammo"):GetBool() and GetConVar("arccw_mult_ammohealth"):GetFloat() > 0 then
        local ainfo_cvar = GetConVar("arccw_ammo_detonationmode"):GetInt()
        local ainfo_str = ArcCW.GetTranslation("ttt.roundinfo.amode" .. ainfo_cvar)
        if GetConVar("arccw_ammo_chaindet"):GetBool() then
            ainfo_str = ainfo_str .. ", " .. ArcCW.GetTranslation("ttt.roundinfo.achain")
        end
        AddLine(infoBox, ArcCW.GetTranslation("ttt.roundinfo.amode") .. " " .. ainfo_str)
    end


    timer.Create("ArcCW_TTT_InfoBox", t, 1, function()
        if infoBox then infoBox:Remove() end
    end)
end
concommand.Add("arccw_ttt_info", function()
    CreateInfoBox(20)
end, nil, "Shows a panel detailing current ArcCW settings.")

local turnoff = true
hook.Add("TTTPrepareRound", "ArcCW_TTT_Info", function()
    if GetConVar("arccw_ttt_inforoundstart"):GetBool() then
        CreateInfoBox(15)
        if turnoff then
            turnoff = false
            chat.AddText(Color(255,255,255), "To turn off ArcCW config info, type 'arccw_ttt_inforoundstart 0' in console.")
        end
    end
    ArcCW.TTT_AttInfo = {}
end)

hook.Add("TTTSettingsTabs", "ArcCW_TTT", function(dtabs)

    local padding = dtabs:GetPadding() * 2

    local panellist = vgui.Create("DPanelList", dtabs)
    panellist:StretchToParent(0,0,padding,0)
    panellist:EnableVerticalScrollbar(true)
    panellist:SetPadding(10)
    panellist:SetSpacing(10)

    local dgui = vgui.Create("DForm", panellist)
    dgui:SetName("#arccw.menus.client")
    dgui:Help("#arccw.clientcfg")
    dgui:Help("")
    dgui:CheckBox("#arccw.cvar.ttt_inforoundstart", "arccw_ttt_inforoundstart")
    dgui:CheckBox("#arccw.cvar.crosshair", "arccw_crosshair")
    dgui:CheckBox("#arccw.cvar.ttt_rolecrosshair", "arccw_ttt_rolecrosshair")
    dgui:CheckBox("#arccw.cvar.blur", "arccw_blur")
    dgui:CheckBox("#arccw.cvar.hud_3dfun", "arccw_hud_3dfun")
    dgui:CheckBox("#arccw.cvar.hud_forceshow", "arccw_hud_forceshow")
    dgui:CheckBox("#arccw.cvar.hud_showammo", "arccw_hud_showammo")
    dgui:CheckBox("#arccw.cvar.2d3d", "arccw_2d3d")
    dgui:CheckBox("#arccw.cvar.cheapscopes", "arccw_cheapscopes")
    dgui:CheckBox("#arccw.cvar.toggleads", "arccw_toggleads")
    dgui:CheckBox("#arccw.cvar.altubglkey", "arccw_altubglkey")
    dgui:CheckBox("#arccw.cvar.altfcgkey", "arccw_altfcgkey")
    panellist:AddItem(dgui)

    if not game.IsDedicated() and LocalPlayer():IsSuperAdmin() then
        local dgui2 = vgui.Create("DForm", panellist)
        dgui2:SetName("#arccw.menus.server")
        dgui2:Help("#arccw.adminonly")
        dgui2:Help("")
        dgui2:CheckBox("#arccw.cvar.ttt_replace", "arccw_ttt_replace")
        dgui2:CheckBox("#arccw.cvar.ttt_replaceammo", "arccw_ttt_replaceammo")
        dgui2:CheckBox("#arccw.cvar.ttt_atts", "arccw_ttt_atts")
        dgui2:NumSlider("#arccw.cvar.ttt_customizemode", "arccw_ttt_customizemode", 0, 3, 0)
        dgui2:Help("#arccw.cvar.ttt_customizemode.desc")

        local cb = dgui2:CheckBox("#arccw.cvar.enable_customization", "arccw_enable_customization")
        cb:SetTooltip("arccw.cvar.enable_customization.help")

        cb = dgui2:CheckBox("#arccw.cvar.ttt_weakensounds", "arccw_ttt_weakensounds")
        cb:SetTooltip("#arccw.cvar.ttt_weakensounds.help")

        cb = dgui2:CheckBox("#arccw.cvar.attinv_free", "arccw_attinv_free")
        cb:SetTooltip("#arccw.cvar.attinv_free.help")
        cb = dgui2:CheckBox("#arccw.cvar.attinv_lockmode", "arccw_attinv_lockmode")
        cb:SetTooltip("#arccw.cvar.attinv_lockmode.help")

        local ns = dgui2:NumSlider("#arccw.cvar.ttt_bodyattinfo", "arccw_ttt_bodyattinfo", 0, 2, 0)
        ns:SetTooltip("#arccw.cvar.ttt_bodyattinfo.help")
        dgui2:Help("#arccw.cvar.ttt_bodyattinfo.desc")

        ns = dgui2:NumSlider("#arccw.cvar.attinv_loseondie", "arccw_attinv_loseondie", 0, 2, 0)
        ns:SetTooltip("#arccw.cvar.attinv_loseondie.help")
        dgui2:Help("#arccw.cvar.attinv_loseondie.desc")

        ns = dgui2:NumSlider("#arccw.cvar.atts_pickx", "arccw_atts_pickx", 0, 15, 0)
        ns:SetTooltip("#arccw.cvar.atts_pickx.desc")

        ns = dgui2:NumSlider("#arccw.cvar.ammo_detonationmode", "arccw_ammo_detonationmode", -1, 2, 0)
        ns:SetTooltip("#arccw.cvar.ammo_detonationmode.help")
        dgui2:Help("#arccw.cvar.ammo_detonationmode.desc")
        dgui2:CheckBox("#arccw.cvar.ammo_chaindet", "arccw_ammo_chaindet")

        dgui2:CheckBox("#arccw.cvar.override_crosshair_off", "arccw_override_crosshair_off")
        dgui2:CheckBox("#arccw.cvar.truenames", "arccw_truenames")

        ns = dgui2:NumSlider("#arccw.cvar.equipmenttime", "arccw_equipmenttime", 60, 600, 0)
        ns:SetTooltip("#arccw.cvar.equipmenttime.help")

        panellist:AddItem(dgui2)
    end

    dtabs:AddSheet("ArcCW", panellist, "icon16/gun.png", false, false, "ArcCW Settings")
end)

hook.Add("TTTRenderEntityInfo", "ArcCW_TTT2_Weapons", function(tData)
    local client = LocalPlayer()
    local ent = tData:GetEntity()

    if not IsValid(client) or not client:IsTerror() or not client:Alive()
    or not IsValid(ent) or tData:GetEntityDistance() > 100 or not ent:IsWeapon()
    or not ent.ArcCW or ent.Throwable then
        return
    end

    if tData:GetAmountDescriptionLines() > 0 then
        tData:AddDescriptionLine()
    end

    local pickx = GetConVar("arccw_atts_pickx"):GetInt()

    if ent.Attachments and ent:CountAttachments() > 0 then
        tData:AddDescriptionLine(tostring(ent:CountAttachments()) .. (pickx > 0 and ("/" .. pickx) or "") .. ArcCW.GetTranslation("ttt.attachments"), nil)
        for i, v in pairs(ent.Attachments) do
            local attName = v.Installed
            if not attName and not v.MergeSlots then
                continue
            elseif v.MergeSlots and not attName then
                for _, s in pairs(v.MergeSlots) do
                    if ent.Attachments[s] and ent.Attachments[s].Installed then
                        attName = ent.Attachments[s].Installed
                        break
                    end
                end
                if not attName then continue end
            end
            local attTbl = ArcCW.AttachmentTable[attName]
            if attTbl and v.PrintName and attTbl.PrintName then
                local printName = ArcCW.GetTranslation("name." .. attName) or attTbl.PrintName
                tData:AddDescriptionLine(ArcCW.TryTranslation(v.PrintName) .. ": " .. printName, nil, {attTbl.Icon})
            end
        end
    end
end)

hook.Add("TTTRenderEntityInfo", "ArcCW_TTT2_Ammo", function(tData)
    local client = LocalPlayer()
    local ent = tData:GetEntity()

    if not IsValid(client) or not client:IsTerror() or not client:Alive()
    or not IsValid(ent) or tData:GetEntityDistance() > 100 or not scripted_ents.IsBasedOn(ent:GetClass(), "arccw_ammo") then
        return
    end

    -- enable targetID rendering
    tData:EnableText()
    tData:EnableOutline()
    tData:SetOutlineColor(client:GetRoleColor())

    tData:SetTitle(ent.PrintName)
    tData:SetSubtitle(ArcCW.GetTranslation("ttt.ammo") .. ent:GetNWInt("truecount", ent.AmmoCount))
end)