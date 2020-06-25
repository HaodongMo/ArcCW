hook.Add("PopulateMenuBar", "ArcCW_NPCWeaponMenu", function ( menubar )
    local m = menubar:AddOrGetMenu("ArcCW Weapons")
    local weaponlist = weapons.GetList()

    m:AddCVar("None", "gmod_npcweapon", "none")
    m:AddSpacer()

    local cats = {}

    table.SortByMember( weaponlist, "PrintName", true )

    for i, k in pairs(weaponlist) do
        if weapons.IsBasedOn(k.ClassName, "arccw_base") and !k.PrimaryBash and k.Spawnable and !k.NotForNPCs then
            local cat = k.Category or "Other"
            if !cats[cat] then
                cats[cat] = m:AddSubMenu(cat)
            end

            cats[cat]:SetDeleteSelf(false)

            cats[cat]:AddCVar(k.PrintName, "gmod_npcweapon", k.ClassName)
        end
    end
end)

net.Receive("arccw_npcgiverequest", function(len, ply)
    local class = GetConVar("gmod_npcweapon"):GetString()

    net.Start("arccw_npcgivereturn")
    net.WriteString(class)
    net.SendToServer()
end)