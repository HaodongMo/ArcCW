hook.Add("PopulateMenuBar", "ArcCW_NPCWeaponMenu", function (menubar)
    local menu = menubar:AddOrGetMenu("ArcCW Weapons")

    menu:AddCVar("None", "gmod_npcweapon", "none")
    menu:AddSpacer()

    local weaponlist = weapons.GetList()

    table.SortByMember(weaponlist, "PrintName", true)

    local cats = {}

    for _, k in pairs(weaponlist) do
        if weapons.IsBasedOn(k.ClassName, "arccw_base") and not k.NotForNPCs and not k.PrimaryBash and k.Spawnable then
            local cat = k.Category or "Other"

            if not cats[cat] then cats[cat] = menu:AddSubMenu(cat) end

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