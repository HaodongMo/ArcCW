ArcCW.TTTAmmo_To_Ent = {
    ["pistol"] = "item_ammo_pistol_ttt",
    ["smg1"] = "item_ammo_smg1_ttt",
    ["AlyxGun"] = "item_ammo_revolver_ttt",
    ["357"] = "item_ammo_357_ttt",
    ["buckshot"] = "item_box_buckshot_ttt"
}
ArcCW.Ammo_To_TTTAmmo = {
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

ArcCW.TTTAmmoEnt_To_ArcCW = {
    ["item_ammo_pistol_ttt"] = "arccw_ammo_pistol",
    ["item_ammo_smg1_ttt"] = "arccw_ammo_smg1",
    ["item_ammo_revolver_ttt"] = "arccw_ammo_357",
    ["item_ammo_357_ttt"] = "arccw_ammo_sniper",
    ["item_box_buckshot_ttt"] = "arccw_ammo_buckshot"
}

-- translate TTT weapons to HL2 weapons, in order to recognize NPC weapon replacements.
ArcCW.TTTReplaceTable = {
    ["weapon_ttt_glock"] = "weapon_pistol",
    ["weapon_zm_mac10"] = "weapon_smg1",
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

CreateConVar("arccw_ttt_replace", 1, FCVAR_ARCHIVE, "Use custom code to forcefully replace TTT weapons with ArcCW ones.", 0, 1)
CreateConVar("arccw_ttt_replaceammo", 1, FCVAR_ARCHIVE, "Forcefully replace TTT ammo boxes with ArcCW ones.", 0, 1)
CreateConVar("arccw_ttt_atts", 1, FCVAR_ARCHIVE, "Automatically set up ArcCW weapons with an attachment loadout.", 0, 1)
CreateConVar("arccw_ttt_nocustomize", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Disable all customization features on ArcCW weapons.", 0, 1)
CreateConVar("arccw_ttt_bodyattinfo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether a corpse contains info on the attachments of the murder weapon. 1 means detective only and 2 means everyone.", 0, 2)


function ArcCW:TTT_GetRandomWeapon(class)
    if class and ArcCW.TTTReplaceTable[class] then
        class = ArcCW.TTTReplaceTable[class]
    else
        return
    end

    if SERVER then
        return ArcCW:GetRandomWeapon(class, true)
    else
        return class
    end
end

hook.Add("InitPostEntity", "ArcCW_TTT", function()

    if weapons.GetStored("arccw_base") then
        -- Blocks TTT from autospawning the base, which it likes to do
        weapons.GetStored("arccw_base").AutoSpawnable = false
    end

    for i, wep in pairs(weapons.GetList()) do
        if !weapons.IsBasedOn(wep.ClassName, "arccw_base") then continue end

        if ArcCW.Ammo_To_TTTAmmo[wep.Primary.Ammo] then
            wep.Primary.Ammo = ArcCW.Ammo_To_TTTAmmo[wep.Primary.Ammo]
        end

        wep.AmmoEnt = ArcCW.TTTAmmo_To_Ent[wep.Primary.Ammo] or ""

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
                wep.Kind = WEAPON_EQUIP1
            elseif wep.Slot == 1 then
                -- sidearms
                wep.Kind = WEAPON_PISTOL
            elseif wep.Slot == 2 or wep.Slot == 3 then
                -- primaries
                wep.Kind = WEAPON_HEAVY
            else
                -- weird slots, let's assume they're a main weapon
                wep.Slot = 2
                wep.Kind = WEAPON_HEAVY
            end
        end
    end

    -- Language string(s)
    LANG.AddToLanguage("English", "search_dmg_buckshot", "This person was blasted to pieces by buckshot.")
end)

hook.Add("DoPlayerDeath", "ArcCW_DetectiveSeeAtts", function(ply, attacker, dmginfo)
    local wep = util.WeaponFromDamage(dmginfo)
    timer.Simple(0, function()
        if GetConVar("arccw_ttt_bodyattinfo"):GetInt() > 0 and ply.server_ragdoll and IsValid(wep) and wep:IsWeapon() and wep.ArcCW then
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

if SERVER then
    hook.Add( "OnEntityCreated", "ArcCW_TTTAmmoReplacement", function(ent)
        if GetConVar("arccw_ttt_replaceammo"):GetBool() and ArcCW.TTTAmmoEnt_To_ArcCW[ent:GetClass()] then
            timer.Simple(0, function()
                if !IsValid(ent) then return end
                local ammoent = ents.Create(ArcCW.TTTAmmoEnt_To_ArcCW[ent:GetClass()])
                ammoent:SetPos(ent:GetPos())
                ammoent:SetAngles(ent:GetAngles())
                ammoent:Spawn()
                SafeRemoveEntityDelayed(ent, 0) -- remove next tick
            end)
        end
    end)
end
if CLIENT then

    net.Receive("arccw_ttt_bodyattinfo", function()
        local rag = net.ReadEntity()
        rag.ArcCW_AttInfo = {}
        local atts = net.ReadUInt(8)
        for i = 1, atts do
            local id = net.ReadUInt(ArcCW.GetBitNecessity())
            if id != 0 then
                rag.ArcCW_AttInfo[i] = ArcCW.AttachmentIDTable[id]
            end
        end
    end)

    hook.Add("TTTBodySearchPopulate", "ArcCW_PopulateHUD", function(processed, raw)

        -- Attachment Info
        local mode = GetConVar("arccw_ttt_bodyattinfo"):GetInt()
        if Entity(raw.eidx).ArcCW_AttInfo and (mode == 2 or (mode == 1 and raw.detective_search)) then
            local finalTbl = {
                img	= "arccw/ttticons/arccw_dropattinfo.png",
                p = 10.5, -- Right after the murder weapon
                text = (mode == 1 and "With your detective skills, you" or "You") .. " deduce the murder weapon had these attachments: "
            }
            local comma = false
            for i, v in pairs(Entity(raw.eidx).ArcCW_AttInfo) do
                if v and ArcCW.AttachmentTable[v] then
                    finalTbl.text = finalTbl.text .. (comma and ", " or "") .. ArcCW.AttachmentTable[v].PrintName
                    comma = true
                end
            end
            finalTbl.text = finalTbl.text .. "."
            processed.arccw_atts = finalTbl
        end

        -- Buckshot kill info
        if bit.band(raw.dmg, DMG_BUCKSHOT) == DMG_BUCKSHOT then
            processed.dmg.text = LANG.GetTranslation("search_dmg_buckshot")
            processed.dmg.img = "arccw/ttticons/kill_buckshot.png"
        end
    end)

end