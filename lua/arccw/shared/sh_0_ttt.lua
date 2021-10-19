ArcCW.TTTAmmoToEntity = {
    ["pistol"] = "item_ammo_pistol_ttt",
    ["smg1"] = "item_ammo_smg1_ttt",
    ["AlyxGun"] = "item_ammo_revolver_ttt",
    ["357"] = "item_ammo_357_ttt",
    ["buckshot"] = "item_box_buckshot_ttt"
}
ArcCW.AmmoToTTT = {
    ["357"] = "AlyxGun",
    ["SniperPenetratedRound"] = "357",
    ["ar2"] = "smg1",
}
ArcCW.TTTAmmo_To_ClipMax = {
    ["357"] = 20,
    ["smg1"] = 60,
    ["pistol"] = 60,
    ["alyxgun"] = 36,
    ["buckshot"] = 24
}
-- translate TTT weapons to HL2 weapons, in order to recognize NPC weapon replacements.
ArcCW.TTTReplaceTable = {
    ["weapon_ttt_glock"] = "weapon_pistol",
    ["weapon_zm_mac10"] = "weapon_ar2",
    ["weapon_ttt_m16"] = "weapon_smg1",
    ["weapon_zm_pistol"] = "weapon_pistol",
    ["weapon_zm_revolver"] = "weapon_357",
    ["weapon_zm_rifle"] = "weapon_crossbow",
    ["weapon_zm_shotgun"] = "weapon_shotgun",
    ["weapon_zm_sledge"] = "weapon_ar2",
    ["weapon_ttt_smokegrenade"] = "weapon_grenade",
    ["weapon_ttt_confgrenade"] = "weapon_grenade",
    ["weapon_tttbasegrenade"] = "weapon_grenade",
    ["weapon_zm_molotov"] = "weapon_grenade",
}

if engine.ActiveGamemode() != "terrortown" then return end

CreateConVar("arccw_ttt_replace", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use custom code to forcefully replace TTT weapons with ArcCW ones.", 0, 1)
CreateConVar("arccw_ttt_ammo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Replace TTT ammo with ArcCW ones, takes precedence over the default convar.", 0, 1)
CreateConVar("arccw_ttt_atts", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Automatically set up ArcCW weapons with an attachment loadout.", 0, 1)
CreateConVar("arccw_ttt_customizemode", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "If set to 1, disallow customization on ArcCW weapons. If set to 2, players can customize during setup and postgame. If set to 3, only T and Ds can customize.", 0, 3)
CreateConVar("arccw_ttt_bodyattinfo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether a corpse contains info on the attachments of the murder weapon. 1 means detective only and 2 means everyone.", 0, 2)

hook.Add("InitPostEntity", "ArcCW_TTT", function()
    for i, wep in pairs(weapons.GetList()) do
        local weap = weapons.Get(wep.ClassName)
        if weap then
            if !weap.ArcCW then
                --print(weap.ClassName)
                --print("\t- No ArcCW")
                continue
            end
            if weap.ArcCW and !weap.Spawnable then
                --[[]
                if weap.AutoSpawnable then
                    --print(weap.ClassName)
                    --print("\t- Not spawnable but AutoSpawnable so alright")
                end
                ]]
                --print(weap.ClassName)
                --print("\t- Not spawnable, ignored")
                continue
            end
            --print(wep.ClassName)
            --print("\t- Accepted")
        end

        if ArcCW.AmmoToTTT[wep.Primary.Ammo] then
            wep.Primary.Ammo = ArcCW.AmmoToTTT[wep.Primary.Ammo]
        end

        wep.AmmoEnt = ArcCW.TTTAmmoToEntity[wep.Primary.Ammo] or ""
        -- You can tell how desperate I am in blocking the base from spawning
        wep.AutoSpawnable = (wep.AutoSpawnable == nil and true) or wep.AutoSpawnable
        wep.AllowDrop = wep.AllowDrop or true

        -- We have to do this here because TTT2 does a check for .Kind in WeaponEquip,
        -- earlier than Initialize() which assigns .Kind
        if !wep.Kind and !wep.CanBuy then
            if wep.Throwing then
                wep.Slot = 3
                wep.Kind = WEAPON_NADE
            elseif wep.Slot == 0 then
                -- melee weapons
                wep.Slot = 6
                wep.Kind = WEAPON_MELEE or WEAPON_EQUIP1
            elseif wep.Slot == 1 then
                -- sidearms
                wep.Kind = WEAPON_PISTOL
            else
                -- other weapons are considered primary
                wep.Slot = 2
                wep.Kind = WEAPON_HEAVY
            end
        end

        local class = wep.ClassName
        local path = "arccw/weaponicons/" .. class
        local path2 = "arccw/ttticons/" .. class .. ".png"
        local path3 = "vgui/ttt/" .. class
        local path4 = "entities/" .. class .. ".png"

        if !Material(path2):IsError() then
            -- TTT icon (png)
            wep.Icon = path2
        elseif !Material(path3):IsError() then
            -- TTT icon (vtf)
            wep.Icon = path3
        elseif !Material(path4):IsError() then
            -- Entity spawn icon
            wep.Icon = path4
        elseif !Material(path):IsError() then
            -- Kill icon
            wep.Icon = path
        else
            -- fallback: display _something_
            wep.Icon = "arccw/hud/arccw_bird.png"
        end

    end

    --[[]
    local pistol_ammo = (scripted_ents.GetStored("arccw_ammo_pistol") or {}).t
    if pistol_ammo then
        pistol_ammo.AmmoCount = 30
    end
    ]]

    -- Language string(s)
    if CLIENT then
        LANG.AddToLanguage("en", "search_dmg_buckshot", "This person was blasted to pieces by buckshot.")
        LANG.AddToLanguage("en", "search_dmg_nervegas", "Their face looks pale. It must have been some sort of nerve gas.")
        LANG.AddToLanguage("en", "ammo_smg1_grenade", "Rifle Grenades")
    end
end)

hook.Add("DoPlayerDeath", "ArcCW_DetectiveSeeAtts", function(ply, attacker, dmginfo)
    local wep = util.WeaponFromDamage(dmginfo)
    timer.Simple(0, function()
        if GetConVar("arccw_ttt_bodyattinfo"):GetInt() > 0 and ply.server_ragdoll and IsValid(wep) and wep:IsWeapon() and wep.ArcCW and wep.Attachments then
            net.Start("arccw_ttt_bodyattinfo")
                net.WriteEntity(ply.server_ragdoll)
                net.WriteUInt(table.Count(wep.Attachments), 8)
                for i, info in pairs(wep.Attachments) do
                    if info.Installed then
                        net.WriteUInt(ArcCW.AttachmentTable[info.Installed].ID, ArcCW.GetBitNecessity())
                    else
                        net.WriteUInt(0, ArcCW.GetBitNecessity())
                    end
                end
            net.Broadcast()
        end
    end)
end)

hook.Add("ArcCW_OnAttLoad", "ArcCW_TTT", function(att)
    if att.Override_Ammo and ArcCW.AmmoToTTT[att.Override_Ammo] then
        att.Override_Ammo = ArcCW.AmmoToTTT[att.Override_Ammo]
    end
end)