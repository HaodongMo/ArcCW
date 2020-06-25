ArcCW.TTTAmmo_To_Ent = {
    ["pistol"] = "item_ammo_pistol_ttt",
    ["smg1"] = "item_ammo_smg1_ttt",
    ["AlyxGun"] = "item_ammo_revolver_ttt",
    ["357"] = "item_ammo_357_ttt",
    ["buckshot"] = "item_box_buckshot_ttt"
}
ArcCW.Ammo_To_TTTAmmo = {
    ["357"] = "AlyxGun",
    ["SniperPenetratedAmmo"] = "357",
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
CreateConVar("arccw_ttt_atts", 1, FCVAR_ARCHIVE, "Automatically set up ArcCW weapons with an attachment loadout.", 0, 1)
CreateConVar("arccw_ttt_nocustomize", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Disable all customization features on ArcCW weapons.", 0, 1)

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
    for i, wep in pairs(weapons.GetList()) do
        if !weapons.IsBasedOn(wep.ClassName, "arccw_base") then continue end

        if ArcCW.Ammo_To_TTTAmmo[wep.Primary.Ammo] then
            wep.Primary.Ammo = ArcCW.Ammo_To_TTTAmmo[wep.Primary.Ammo]
        end

        wep.AmmoEnt = ArcCW.TTTAmmo_To_Ent[wep.Primary.Ammo] or ""
    end
end)