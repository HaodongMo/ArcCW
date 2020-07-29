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
            text = (mode == 1 and "With your detective skills, you deduce" or "You think") .. " the murder weapon "
        }
        local count = table.Count(attTbl)
        if count == 1 then
            if not ArcCW.AttachmentTable[attTbl[1]] then return end
            finalTbl.text = finalTbl.text .. "had " .. ArcCW.AttachmentTable[attTbl[1]].PrintName .. " installed."
        elseif count == 2 then
            if not ArcCW.AttachmentTable[attTbl[1]] or not ArcCW.AttachmentTable[attTbl[2]] then return end
            finalTbl.text = finalTbl.text .. "had " .. ArcCW.AttachmentTable[attTbl[1]].PrintName .. " and " .. ArcCW.AttachmentTable[attTbl[2]].PrintName .. " installed."
        else
            finalTbl.text = finalTbl.text .. "had these attachments: "
            local comma = false
            for i, v in pairs(attTbl) do
                if v and ArcCW.AttachmentTable[v] then
                    finalTbl.text = finalTbl.text .. (comma and ", " or "") .. ArcCW.AttachmentTable[v].PrintName
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
    label:SetText("ArcCW Configuration")

    if GetConVar("arccw_ttt_replace"):GetBool() then
        AddLine(infoBox, "Auto-replace TTT weapons")
    end

    local cmode_str = "No Restrictions"
    local cmode_cvar = GetConVar("arccw_ttt_customizemode"):GetInt()
    if cmode_cvar == 1 then
        cmode_str = "Restricted"
    elseif cmode_cvar == 2 then
        cmode_str = "Availble during setup"
    elseif cmode_cvar == 3 then
        cmode_str = "Traitor/Detective only"
    end
    AddLine(infoBox, "Customize Mode: " .. cmode_str)

    local att_str = ""
    local att_cvar = GetConVar("arccw_attinv_free"):GetBool()
    local att_cvar2 = GetConVar("arccw_attinv_lockmode"):GetBool()
    local att_cvar3 = GetConVar("arccw_attinv_loseondie"):GetBool()
    if att_cvar then
        att_str = "Free"
    elseif att_cvar2 then
        att_str = "Locking"
    else
        att_str = "Inventory"
    end
    if att_cvar3 == 0 then
        att_str = att_str .. ", Persistent"
    elseif not att_cvar and not att_cvar2 and att_cvar3 == 2 then
        att_str = att_str .. ", Dropped"
    end
    if GetConVar("arccw_atts_pickx"):GetInt() > 0 then
        att_str = att_str .. ", Pick " .. GetConVar("arccw_atts_pickx"):GetInt()
    end
    AddLine(infoBox, "Attachment Mode: " .. att_str)

    local binfo_str = "Unavailable"
    local binfo_cvar = GetConVar("arccw_ttt_bodyattinfo"):GetInt()
    if binfo_cvar == 1 then
        binfo_str = "Detectives Only"
    elseif binfo_cvar == 2 then
        binfo_str = "Available"
    end
    AddLine(infoBox, "Attachment Info on Body: " .. binfo_str)

    if GetConVar("arccw_ttt_replaceammo"):GetBool() then
        local ainfo_str = "None"
        local ainfo_cvar = GetConVar("arccw_ammo_detonationmode"):GetInt()

        if GetConVar("arccw_mult_ammohealth"):GetFloat() <= 0 then
            ainfo_str = "Indestructible"
        elseif ainfo_cvar == 0 then
            ainfo_str = "Simple"
        elseif ainfo_cvar == 1 then
            ainfo_str = "Frag"
        elseif ainfo_cvar == 2 then
            ainfo_str = "Full"
        end
        if GetConVar("arccw_mult_ammohealth"):GetFloat() > 0 and GetConVar("arccw_ammo_chaindet"):GetBool() then
            ainfo_str = ainfo_str .. ", Chain reaction"
        end
        AddLine(infoBox, "Ammo explosion: " .. ainfo_str)
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
    dgui:SetName("Client Settings")
    dgui:CheckBox("Enable round startup info", "arccw_ttt_inforoundstart")
    dgui:CheckBox("Enable Crosshair", "arccw_crosshair")
    dgui:CheckBox("Enable role-based crosshair color", "arccw_ttt_rolecrosshair")
    dgui:CheckBox("Enable Customization Blur", "arccw_blur")
    dgui:CheckBox("Use Alternative 2D3D HUD", "arccw_hud_3dfun")
    dgui:CheckBox("Force enable custom HUD", "arccw_hud_forceshow")
    dgui:CheckBox("Show Health HUD", "arccw_hud_showhealth")
    dgui:CheckBox("Show Ammo HUD", "arccw_hud_showammo")
    dgui:CheckBox("Enable 2D3D on ammo and weapons", "arccw_2d3d")
    dgui:CheckBox("Enable Cheap Scopes (saves perf.)", "arccw_cheapscopes")
    dgui:CheckBox("Toggle ADS", "arccw_toggleads")
    dgui:CheckBox("E+RMB for UBGL", "arccw_altubglkey")
    dgui:CheckBox("E+R for Firemodes", "arccw_altfcgkey")
    panellist:AddItem(dgui)

    if not game.IsDedicated() and LocalPlayer():IsSuperAdmin() then
        local dgui2 = vgui.Create("DForm", panellist)
        dgui2:SetName("Server Settings")
        dgui2:CheckBox("Auto-replace Weapons", "arccw_ttt_replace")
        dgui2:CheckBox("Auto-replace Ammo", "arccw_ttt_replaceammo")
        dgui2:CheckBox("Random Attachments", "arccw_ttt_atts")
        dgui2:NumSlider("Customization Mode", "arccw_ttt_customizemode", 0, 3, 0)
        dgui2:Help("0 - No restrictions; 1 - Restricted; 2 - Pregame only; 3 - Traitor/Detective only")

        local cb = dgui2:CheckBox("Enable Customization", "arccw_enable_customization")
        cb:SetTooltip("If disabled, nobody can customize. This overwrites Customization Mode.")

        cb = dgui2:CheckBox("Weaken Sounds", "arccw_ttt_weakensounds")
        cb:SetTooltip("Reduces all firearm volume by 20dB, making shots easier to hide.")

        cb = dgui2:CheckBox("Free Attachments", "arccw_attinv_free")
        cb:SetTooltip("If enabled, players have access to all attachments.\nCustomization mode may still restrict them from using them.")
        cb = dgui2:CheckBox("Attachment Locking", "arccw_attinv_lockmode")
        cb:SetTooltip("If enabled, picking up one attachment unlocks it for every weapon, a-la CW2.")


        local ns = dgui2:NumSlider("Body Attachment Info", "arccw_ttt_bodyattinfo", 0, 2, 0)
        ns:SetTooltip("If enabled, searching a body will reveal the attachments on the weapon used to kill someone.")
        dgui2:Help("0 - Off; 1 - Detectives can see; 2 - Everyone can see")

        ns = dgui2:NumSlider("Lose Attachments", "arccw_attinv_loseondie", 0, 2, 0)
        ns:SetTooltip("If enabled, players lose attachment on death and round end.")
        dgui2:Help("0 - Persistent; 1 - Remove on death; 2 - Drop box on death")

        ns = dgui2:NumSlider("Pick X", "arccw_atts_pickx", 0, 15, 0)
        ns:SetTooltip("Enable to have a limit on how many attachment a gun can have. 0 disables.")

        ns = dgui2:NumSlider("Ammo Detonation Mode", "arccw_ammo_detonationmode", -1, 2, 0)
        ns:SetTooltip("Determines what happens if ammo boxes are destroyed.")
        dgui2:Help("-1 - No explosion; 0 - Simple; 1 - Fragmentation; 2 - Full (chance to burn up)")
        dgui2:CheckBox("Ammo Chain Detonation", "arccw_ammo_chaindet")

        dgui2:CheckBox("Force crosshair off for everyone", "arccw_override_crosshair_off")
        dgui2:CheckBox("True Names (requires restart)", "arccw_truenames")

        ns = dgui2:NumSlider("Equipment Lifetime", "arccw_equipmenttime", 60, 600, 0)
        ns:SetTooltip("Applies to deployable equipment like Claymores, in seconds.")

        panellist:AddItem(dgui2)
    end

    dtabs:AddSheet("ArcCW", panellist, "icon16/gun.png", false, false, "ArcCW Settings")
end)