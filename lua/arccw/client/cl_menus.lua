hook.Add( "PopulateToolMenu", "ArcCW_Options", function()
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_HUD", "#arccw.menus.hud", "", "", ArcCW_Options_HUD)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Client", "#arccw.menus.client", "", "", ArcCW_Options_Client)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Server", "#arccw.menus.server", "", "", ArcCW_Options_Server)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Mults", "#arccw.menus.mults", "", "", ArcCW_Options_Mults)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_NPC", "#arccw.menus.npcs", "", "", ArcCW_Options_NPC)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Atts", "#arccw.menus.atts", "", "", ArcCW_Options_Atts)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Ammo", "#arccw.menus.ammo", "", "", ArcCW_Options_Ammo)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Crosshair", "#arccw.menus.xhair", "", "", ArcCW_Options_Crosshair)
end )

function ArcCW_Options_Ammo( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.adminonly"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "#arccw.cvar.ammo_detonationmode.desc"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.ammo_detonationmode", Command = "arccw_ammo_detonationmode", Min = -1, Max = 2, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.ammo_autopickup", Command = "arccw_ammo_autopickup" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.ammo_largetrigger", Command = "arccw_ammo_largetrigger" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.ammo_rareskin", Command = "arccw_ammo_rareskin", Min = 0, Max = 1, Type = "float" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.ammo_chaindet", Command = "arccw_ammo_chaindet" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.mult_ammohealth", Command = "arccw_mult_ammohealth", Min = -1, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.mult_ammoamount", Command = "arccw_mult_ammoamount", Min = 0.1, Max = 10, Type = "float" })
end

function ArcCW_Options_HUD( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.clientcfg"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.hud_showhealth", Command = "arccw_hud_showhealth" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.hud_showammo", Command = "arccw_hud_showammo" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.hud_3dfun", Command = "arccw_hud_3dfun" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.hud_forceshow", Command = "arccw_hud_forceshow" })

    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_hideunowned", Command = "arccw_attinv_hideunowned" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_darkunowned", Command = "arccw_attinv_darkunowned" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_onlyinspect", Command = "arccw_attinv_onlyinspect" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_simpleproscons", Command = "arccw_attinv_simpleproscons" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_closeonhurt", Command = "arccw_attinv_closeonhurt" })
end

function ArcCW_Options_Client( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.clientcfg"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.toggleads", Command = "arccw_toggleads" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.altfcgkey", Command = "arccw_altfcgkey" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.altubglkey", Command = "arccw_altubglkey" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.altsafety", Command = "arccw_altsafety" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.autosave", Command = "arccw_autosave" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.autosave.desc"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.cheapscopes", Command = "arccw_cheapscopes" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.cheapscopes.desc"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.glare", Command = "arccw_glare" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.glare.desc"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.blur", Command = "arccw_blur" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.blur_toytown", Command = "arccw_blur_toytown" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.shake", Command = "arccw_shake" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.2d3d", Command = "arccw_2d3d" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.muzzleeffects", Command = "arccw_muzzleeffects" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.shelleffects", Command = "arccw_shelleffects" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.att_showothers", Command = "arccw_att_showothers" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.shelltime", Command = "arccw_shelltime", Min = 0, Max = 180, Type = "float" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.vm_coolsway", Command = "arccw_vm_coolsway" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.vm_coolview", Command = "arccw_vm_coolview" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_right", Command = "arccw_vm_right", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_forward", Command = "arccw_vm_forward", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_up", Command = "arccw_vm_up", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.vm_offsetwarn"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_sway_sprint", Command = "arccw_vm_sway_sprint", Min = 0, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_bob_sprint", Command = "arccw_vm_bob_sprint", Min = 0, Max = 5, Type = "float" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.vm_swaywarn"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_lookymult", Command = "arccw_vm_lookymult", Min = -10, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_lookxmult", Command = "arccw_vm_lookxmult", Min = -10, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_swayxmult", Command = "arccw_vm_swayxmult", Min = -1, Max = 1, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_swayymult", Command = "arccw_vm_swayymult", Min = -2, Max = 2, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_swayzmult", Command = "arccw_vm_swayzmult", Min = -2, Max = 2, Type = "float" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.vm_viewwarn"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.vm_coolviewmult", Command = "arccw_vm_coolview_mult", Min = -10, Max = 10, Type = "float" })
end

local crosshair_cvars = {
    "arccw_crosshair_length", "arccw_crosshair_thickness", "arccw_crosshair_gap",
    "arccw_crosshair_dot", "arccw_crosshair_shotgun", "arccw_crosshair_equip", "arccw_crosshair_static",
    "arccw_crosshair_clump", "arccw_crosshair_clump_outline", "arccw_crosshair_clump_always",
    "arccw_crosshair_clr_r", "arccw_crosshair_clr_g", "arccw_crosshair_clr_b", "arccw_crosshair_clr_a",
    "arccw_crosshair_outline", "arccw_crosshair_outline_r", "arccw_crosshair_outline_g", "arccw_crosshair_outline_b", "arccw_crosshair_outline_a",
    "arccw_scope_r", "arccw_scope_g", "arccw_scope_b"}
local crosshair_presets = {
    ["#preset.default"] = {
        ["arccw_crosshair_length"] = "4",
        ["arccw_crosshair_thickness"] = "1",
        ["arccw_crosshair_gap"] = "1",
        ["arccw_crosshair_dot"] = "1",
        ["arccw_crosshair_shotgun"] = "1",
        ["arccw_crosshair_equip"] = "1",
        ["arccw_crosshair_static"] = "0",
        ["arccw_crosshair_clump"] = "0",
        ["arccw_crosshair_clump_outline"] = "0",
        ["arccw_crosshair_clump_always"] = "0",
        ["arccw_crosshair_clr_r"] = "255",
        ["arccw_crosshair_clr_g"] = "255",
        ["arccw_crosshair_clr_b"] = "255",
        ["arccw_crosshair_clr_a"] = "255",
        ["arccw_crosshair_outline"] = "2",
        ["arccw_crosshair_outline_r"] = "0",
        ["arccw_crosshair_outline_g"] = "0",
        ["arccw_crosshair_outline_b"] = "0",
        ["arccw_crosshair_outline_a"] = "255",
        ["arccw_scope_r"] = "255",
        ["arccw_scope_g"] = "0",
        ["arccw_scope_b"] = "0",
    },
    ["#arccw.crosshair.tfa"] = {
        ["arccw_crosshair_length"] = "8",
        ["arccw_crosshair_thickness"] = "0.4",
        ["arccw_crosshair_gap"] = "1",
        ["arccw_crosshair_dot"] = "0",
        ["arccw_crosshair_shotgun"] = "0",
        ["arccw_crosshair_equip"] = "0",
        ["arccw_crosshair_static"] = "0",
        ["arccw_crosshair_clump"] = "0",
        ["arccw_crosshair_clump_outline"] = "0",
        ["arccw_crosshair_clump_always"] = "0",
        ["arccw_crosshair_clr_r"] = "255",
        ["arccw_crosshair_clr_g"] = "255",
        ["arccw_crosshair_clr_b"] = "255",
        ["arccw_crosshair_clr_a"] = "255",
        ["arccw_crosshair_outline"] = "2",
        ["arccw_crosshair_outline_r"] = "0",
        ["arccw_crosshair_outline_g"] = "0",
        ["arccw_crosshair_outline_b"] = "0",
        ["arccw_crosshair_outline_a"] = "255",
        ["arccw_scope_r"] = "255",
        ["arccw_scope_g"] = "0",
        ["arccw_scope_b"] = "0",
    },
    ["#arccw.crosshair.cw2"] = {
        ["arccw_crosshair_length"] = "3.5",
        ["arccw_crosshair_thickness"] = "0.4",
        ["arccw_crosshair_gap"] = "1",
        ["arccw_crosshair_dot"] = "0",
        ["arccw_crosshair_shotgun"] = "0",
        ["arccw_crosshair_equip"] = "0",
        ["arccw_crosshair_static"] = "0",
        ["arccw_crosshair_clump"] = "1",
        ["arccw_crosshair_clump_outline"] = "1",
        ["arccw_crosshair_clump_always"] = "0",
        ["arccw_crosshair_clr_r"] = "255",
        ["arccw_crosshair_clr_g"] = "255",
        ["arccw_crosshair_clr_b"] = "255",
        ["arccw_crosshair_clr_a"] = "200",
        ["arccw_crosshair_outline"] = "2",
        ["arccw_crosshair_outline_r"] = "0",
        ["arccw_crosshair_outline_g"] = "0",
        ["arccw_crosshair_outline_b"] = "0",
        ["arccw_crosshair_outline_a"] = "200",
        ["arccw_scope_r"] = "255",
        ["arccw_scope_g"] = "0",
        ["arccw_scope_b"] = "0",
    },
    ["#arccw.crosshair.cs"] = {
        ["arccw_crosshair_length"] = "3",
        ["arccw_crosshair_thickness"] = "0.4",
        ["arccw_crosshair_gap"] = "0.4",
        ["arccw_crosshair_dot"] = "0",
        ["arccw_crosshair_shotgun"] = "0",
        ["arccw_crosshair_equip"] = "0",
        ["arccw_crosshair_static"] = "1",
        ["arccw_crosshair_clump"] = "0",
        ["arccw_crosshair_clump_outline"] = "0",
        ["arccw_crosshair_clump_always"] = "0",
        ["arccw_crosshair_clr_r"] = "0",
        ["arccw_crosshair_clr_g"] = "255",
        ["arccw_crosshair_clr_b"] = "0",
        ["arccw_crosshair_clr_a"] = "255",
        ["arccw_crosshair_outline"] = "0",
        ["arccw_crosshair_outline_r"] = "0",
        ["arccw_crosshair_outline_g"] = "0",
        ["arccw_crosshair_outline_b"] = "0",
        ["arccw_crosshair_outline_a"] = "0",
        ["arccw_scope_r"] = "255",
        ["arccw_scope_g"] = "0",
        ["arccw_scope_b"] = "0",
    },
    ["#arccw.crosshair.light"] = {
        ["arccw_crosshair_length"] = "4",
        ["arccw_crosshair_thickness"] = "0.8",
        ["arccw_crosshair_gap"] = "1",
        ["arccw_crosshair_dot"] = "0",
        ["arccw_crosshair_shotgun"] = "1",
        ["arccw_crosshair_equip"] = "1",
        ["arccw_crosshair_static"] = "0",
        ["arccw_crosshair_clump"] = "1",
        ["arccw_crosshair_clump_outline"] = "1",
        ["arccw_crosshair_clump_always"] = "0",
        ["arccw_crosshair_clr_r"] = "255",
        ["arccw_crosshair_clr_g"] = "255",
        ["arccw_crosshair_clr_b"] = "255",
        ["arccw_crosshair_clr_a"] = "200",
        ["arccw_crosshair_outline"] = "2",
        ["arccw_crosshair_outline_r"] = "0",
        ["arccw_crosshair_outline_g"] = "0",
        ["arccw_crosshair_outline_b"] = "0",
        ["arccw_crosshair_outline_a"] = "200",
        ["arccw_scope_r"] = "255",
        ["arccw_scope_g"] = "0",
        ["arccw_scope_b"] = "0",
    },
}
function ArcCW_Options_Crosshair( CPanel )
    CPanel:AddControl("combobox", {menubutton = 1, folder = "arccw_crosshair", options = crosshair_presets, cvars = crosshair_cvars})
    CPanel:AddControl("Header", {Description = "#arccw.clientcfg"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair", Command = "arccw_crosshair" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.crosshair_length", Command = "arccw_crosshair_length", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.crosshair_thickness", Command = "arccw_crosshair_thickness", Min = 0, Max = 4, Type = "float" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.crosshair_gap", Command = "arccw_crosshair_gap", Min = 0, Max = 2, Type = "float" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_dot", Command = "arccw_crosshair_dot" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_shotgun", Command = "arccw_crosshair_shotgun" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_equip", Command = "arccw_crosshair_equip" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_static", Command = "arccw_crosshair_static" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_clump", Command = "arccw_crosshair_clump" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_clump_outline", Command = "arccw_crosshair_clump_outline" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.crosshair_clump_always", Command = "arccw_crosshair_clump_always" })
    CPanel:AddControl("color", {Label = "#arccw.cvar.crosshair_clr",
        Red = "arccw_crosshair_clr_r",
        Green = "arccw_crosshair_clr_g",
        Blue = "arccw_crosshair_clr_b",
        Alpha = "arccw_crosshair_clr_a"
    })

    CPanel:AddControl("Slider", {Label = "#arccw.cvar.crosshair_outline", Command = "arccw_crosshair_outline", Min = 0, Max = 4, Type = "float" })
    CPanel:AddControl("color", {Label = "#arccw.cvar.crosshair_outline_clr",
        Red = "arccw_crosshair_outline_r",
        Green = "arccw_crosshair_outline_g",
        Blue = "arccw_crosshair_outline_b",
        Alpha = "arccw_crosshair_outline_a"
    })

    CPanel:AddControl("color", {Label = "#arccw.cvar.scope_clr",
        Red = "arccw_scope_r",
        Green = "arccw_scope_g",
        Blue = "arccw_scope_b",
    })
end

function ArcCW_Options_Mults( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.adminonly"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Slider", {Label = "Damage", Command = "arccw_mult_damage", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "NPC Damage", Command = "arccw_mult_npcdamage", Min = 0, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Range", Command = "arccw_mult_range", Min = 0.01, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Recoil", Command = "arccw_mult_recoil", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Penetration", Command = "arccw_mult_penetration", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Hip Dispersion", Command = "arccw_mult_hipfire", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Move Dispersion", Command = "arccw_mult_movedisp", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Reload Time", Command = "arccw_mult_reloadtime", Min = 0.01, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "ADS Time", Command = "arccw_mult_sighttime", Min = 0.1, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Default Clip", Command = "arccw_mult_defaultclip", Min = -1, Max = 10})
    CPanel:AddControl("Slider", {Label = "Random Att. Chance", Command = "arccw_mult_attchance", Min = 0, Max = 10, Type = "float"})
end

function ArcCW_Options_NPC( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.adminonly"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Replace NPC Weapons", Command = "arccw_npc_replace" })
    CPanel:AddControl("Checkbox", {Label = "NPC Attachments", Command = "arccw_npc_atts" })
end

function ArcCW_Options_Atts( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.adminonly"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "#arccw.attdesc1"})
    CPanel:AddControl("Header", {Description = "#arccw.attdesc2"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_free", Command = "arccw_attinv_free" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.attinv_lockmode", Command = "arccw_attinv_lockmode" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.attinv_loseondie.desc"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.attinv_loseondie", Command = "arccw_attinv_loseondie", Min = 0, Max = 2, Type = "int" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.atts_pickx.desc"})
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.atts_pickx", Command = "arccw_atts_pickx", Min = 0, Max = 10, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.enable_dropping", Command = "arccw_enable_dropping" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.atts_spawnrand", Command = "arccw_atts_spawnrand" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.atts_ubglautoload", Command = "arccw_atts_ubglautoload" })
    CPanel:AddControl("Button", {Label = "#arccw.blacklist", Command = "arccw_blacklist"})
end

function ArcCW_Options_Server( CPanel )
    CPanel:AddControl("Header", {Description = "#arccw.adminonly"})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.enable_penetration", Command = "arccw_enable_penetration" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.enable_customization", Command = "arccw_enable_customization" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.truenames", Command = "arccw_truenames" })
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "#arccw.cvar.equipmentammo.desc"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.equipmentammo", Command = "arccw_equipmentammo" })
    CPanel:AddControl("Header", {Description = "#arccw.cvar.equipmentsingleton.desc"})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.equipmentsingleton", Command = "arccw_equipmentsingleton" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.equipmenttime", Command = "arccw_equipmenttime", Min = 15, Max = 3600, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.throwinertia", Command = "arccw_throwinertia" })
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.limityear_enable", Command = "arccw_limityear_enable" })
    CPanel:AddControl("Slider", {Label = "#arccw.cvar.limityear", Command = "arccw_limityear", Min = 1800, Max = 2100, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.override_crosshair_off", Command = "arccw_override_crosshair_off" })
    CPanel:AddControl("Checkbox", {Label = "#arccw.cvar.override_deploychambered", Command = "arccw_override_deploychambered" })
end

language.Add("arccw.crosshair.tfa", "TFA")
language.Add("arccw.crosshair.cw2", "CW 2.0")
language.Add("arccw.crosshair.cs", "Counter-Strike")
language.Add("arccw.crosshair.light", "Lightweight")
