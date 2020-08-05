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

CreateConVar("arccw_ttt_replace", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use custom code to forcefully replace TTT weapons with ArcCW ones.", 0, 1)
CreateConVar("arccw_ttt_replaceammo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Forcefully replace TTT ammo boxes with ArcCW ones.", 0, 1)
CreateConVar("arccw_ttt_atts", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Automatically set up ArcCW weapons with an attachment loadout.", 0, 1)
CreateConVar("arccw_ttt_customizemode", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "If set to 1, disallow customization on ArcCW weapons. If set to 2, players can customize during setup and postgame. If set to 3, only T and Ds can customize.", 0, 3)
CreateConVar("arccw_ttt_bodyattinfo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether a corpse contains info on the attachments of the murder weapon. 1 means detective only and 2 means everyone.", 0, 2)
CreateConVar("arccw_ttt_weakensounds", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Reduce all weapons' sound volume, making it easier to hide shooting sounds.", 0, 1)


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
                wep.Kind = WEAPON_EQUIP1
            elseif wep.Slot == 1 then
                -- sidearms
                wep.Kind = WEAPON_PISTOL
            elseif wep.Slot == 2 or wep.Slot == 3 then
                -- primaries
                wep.Slot = 2
                wep.Kind = WEAPON_HEAVY
            else
                -- weird slots, let's assume they're a main weapon
                wep.Slot = 2
                wep.Kind = WEAPON_HEAVY
            end
        end

        local class = wep.ClassName
        local path = "arccw/weaponicons/" .. class
        local path2 = "arccw/ttticons/" .. class .. ".png"
        local path3 = "vgui/ttt/" .. class
        local mat2 = Material(path2)

        if !mat2:IsError() then
            wep.Icon = path2
        elseif !Material(path3):IsError() then
            wep.Icon = path3
        elseif !Material(path):IsError() then
            wep.Icon = path
        end

        if GetConVar("arccw_ttt_weakensounds"):GetBool() and wep.ShootVol then
            wep.ShootVol = math.Clamp(wep.ShootVol - 20, 70, 115)
        end

    end

    -- Language string(s)
    if CLIENT then
        LANG.AddToLanguage("English", "search_dmg_buckshot", "This person was blasted to pieces by buckshot.")
        LANG.AddToLanguage("English", "search_dmg_nervegas", "Their face looks pale. It must have been some sort of nerve gas.")
        LANG.AddToLanguage("English", "ammo_smg1_grenade", "Rifle Grenades")
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

if SERVER then
    hook.Add( "OnEntityCreated", "ArcCW_TTTAmmoReplacement", function(ent)
        if GetConVar("arccw_ttt_replaceammo"):GetBool() and ArcCW.TTTAmmoEnt_To_ArcCW[ent:GetClass()] then
            timer.Simple(0, function()
                if !IsValid(ent) then return end
                local ammoent = ents.Create(ArcCW.TTTAmmoEnt_To_ArcCW[ent:GetClass()])
                ammoent:SetPos(ent:GetPos())
                ammoent:SetAngles(ent:GetAngles())
                ammoent:Spawn()
                -- Setting owner prevents pickup
                if IsValid(ent:GetOwner()) then
                    ammoent:SetOwner(ent:GetOwner())
                    timer.Simple(2, function()
                        if IsValid(ammoent) then ammoent:SetOwner(nil) end
                    end)
                end
                -- Dropped ammo may have less rounds than usual
                ammoent.AmmoCount = ent.AmmoAmount or ammoent.AmmoCount
                if ent:GetClass() == "item_ammo_pistol_ttt" and ent.AmmoCount == 20 then
                    -- Extremely ugly hack: TTT pistol ammo only gives 20 rounds but we want it to be 30
                    -- Because most SMGs use pistol ammo (unlike vanilla TTT) and it runs out quickly
                    ammoent.AmmoCount = 30
                end
                ammoent:SetNWInt("truecount", ammoent.AmmoCount)
                SafeRemoveEntityDelayed(ent, 0) -- remove next tick
            end)
        end
    end)
end