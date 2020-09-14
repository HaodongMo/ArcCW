language.Add("arccw.crosshair.tfa",   "TFA")
language.Add("arccw.crosshair.cw2",   "CW 2.0")
language.Add("arccw.crosshair.cs",    "Counter-Strike")
language.Add("arccw.crosshair.light", "Lightweight")

local ClientPanel = {
    [0.1] = { type = "h", text = "#arccw.clientcfg" },
    [0.2] = { type = "b", text = "#arccw.cvar.toggleads", var = "arccw_toggleads" },
    [0.3] = { type = "b", text = "#arccw.cvar.altfcgkey", var = "arccw_altfcgkey" },
    [0.4] = { type = "b", text = "#arccw.cvar.altubglkey", var = "arccw_altubglkey" },
    [0.5] = { type = "b", text = "#arccw.cvar.altlaserkey", var = "arccw_altlaserkey" },
    [0.6] = { type = "b", text = "#arccw.cvar.altsafety", var = "arccw_altsafety" },
    [0.7] = { type = "b", text = "#arccw.cvar.autosave", var = "arccw_autosave" },
    [0.8] = { type = "c", text = "#arccw.cvar.autosave.desc" },
    [0.9] = { type = "b", text = "#arccw.cvar.embracetradition", var = "arccw_hud_embracetradition" },
    [1.0] = { type = "c", text = "#arccw.cvar.embracetradition.desc" },
    [1.3] = { type = "b", text = "#arccw.cvar.glare", var = "arccw_glare" },
    [1.4] = { type = "c", text = "#arccw.cvar.glare.desc" },
    [1.7] = { type = "b", text = "#arccw.cvar.shake", var = "arccw_shake" },
    [1.75] = { type = "c", text = "#arccw.cvar.shake_info" },
    [1.8] = { type = "b", text = "#arccw.cvar.2d3d", var = "arccw_2d3d" },
    [1.85] = { type = "c", text = "#arccw.cvar.2d3d_info" },

    
    [2.9] = { type = "h", text = "" },
    [3] = { type = "h", text = "#arccw.performance" },
    [3.1] = { type = "b", text = "#arccw.cvar.cheapscopes", var = "arccw_cheapscopes" },
    [3.2] = { type = "c", text = "#arccw.cvar.cheapscopes.desc" },
    [3.3] = { type = "b", text = "#arccw.cvar.muzzleeffects", var = "arccw_muzzleeffects" },
    [3.4] = { type = "b", text = "#arccw.cvar.shelleffects", var = "arccw_shelleffects" },
    [3.5] = { type = "b", text = "#arccw.cvar.att_showothers", var = "arccw_att_showothers" },
    [3.51] = { type = "b", text = "#arccw.cvar.blur", var = "arccw_blur" },
    [3.52] = { type = "b", text = "#arccw.cvar.blur_toytown", var = "arccw_blur_toytown" },
    [3.6] = { type = "f", text = "#arccw.cvar.shelltime", var = "arccw_shelltime", min = 0, max = 180 },
}

local Viewmodel = {
    [2.3] = { type = "b", text = "#arccw.cvar.vm_coolsway", var = "arccw_vm_coolsway" },
    [2.4] = { type = "b", text = "#arccw.cvar.vm_coolview", var = "arccw_vm_coolview" },
    [2.5] = { type = "f", text = "#arccw.cvar.vm_right", var = "arccw_vm_right", min = -5, max = 5 },
    [2.6] = { type = "f", text = "#arccw.cvar.vm_forward", var = "arccw_vm_forward", min = -5, max = 5 },
    [2.7] = { type = "f", text = "#arccw.cvar.vm_up", var = "arccw_vm_up", min = -5, max = 5 },
    [2.8] = { type = "c", text = "#arccw.cvar.vm_offsetwarn" },
    [2.9] = { type = "f", text = "#arccw.cvar.vm_sway_sprint", var = "arccw_vm_sway_sprint", min = 0, max = 5 },
    [3.0] = { type = "f", text = "#arccw.cvar.vm_bob_sprint", var = "arccw_vm_bob_sprint", min = 0, max = 5 },
    [3.1-.01] = { type = "h", text = "" },
    [3.1] = { type = "h", text = "#arccw.cvar.vm_swaywarn" },
    [3.2] = { type = "f", text = "#arccw.cvar.vm_lookxmult", var = "arccw_vm_lookxmult", min = -10, max = 10 },
    [3.3] = { type = "f", text = "#arccw.cvar.vm_lookymult", var = "arccw_vm_lookymult", min = -10, max = 10 },
    [3.31] = { type = "f", text = "#arccw.cvar.vm_accelmult", var = "arccw_vm_accelmult", min = 1/3, max = 3 },
    [3.4] = { type = "f", text = "#arccw.cvar.vm_swayxmult", var = "arccw_vm_swayxmult", min = -1, max = 1 },
    [3.5] = { type = "f", text = "#arccw.cvar.vm_swayymult", var = "arccw_vm_swayymult", min = -2, max = 2 },
    [3.6] = { type = "f", text = "#arccw.cvar.vm_swayzmult", var = "arccw_vm_swayzmult", min = -2, max = 2 },
    [3.7-.01] = { type = "h", text = "" },
    [3.7] = { type = "h", text = "#arccw.cvar.vm_viewwarn" },
    [3.8] = { type = "f", text = "#arccw.cvar.vm_coolviewmult", var = "arccw_vm_coolview_mult", min = -10, max = 10 },
}

local HudPanel = {
    [0.1] = { type = "h", text = "#arccw.clientcfg" },
    [0.2] = { type = "b", text = "#arccw.cvar.hud_showhealth", var = "arccw_hud_showhealth" },
    [0.3] = { type = "b", text = "#arccw.cvar.hud_showammo", var = "arccw_hud_showammo" },
    [0.4] = { type = "b", text = "#arccw.cvar.hud_3dfun", var = "arccw_hud_3dfun" },
    [0.5] = { type = "b", text = "#arccw.cvar.hud_forceshow", var = "arccw_hud_forceshow" },
    [0.6] = { type = "b", text = "#arccw.cvar.attinv_hideunowned", var = "arccw_attinv_hideunowned" },
    [0.7] = { type = "b", text = "#arccw.cvar.attinv_darkunowned", var = "arccw_attinv_darkunowned" },
    [0.8] = { type = "b", text = "#arccw.cvar.attinv_onlyinspect", var = "arccw_attinv_onlyinspect" },
    [0.9] = { type = "b", text = "#arccw.cvar.attinv_simpleproscons", var = "arccw_attinv_simpleproscons" },
    [1.0] = { type = "b", text = "#arccw.cvar.attinv_closeonhurt", var = "arccw_attinv_closeonhurt" },
    [1.1] = { type = "f", text = "#arccw.cvar.hudpos_deadzone_x", var = "arccw_hud_deadzone_x", min = 0, max = 1 },
    [1.2] = { type = "f", text = "#arccw.cvar.hudpos_deadzone_y", var = "arccw_hud_deadzone_y", min = 0, max = 1 },
}

local CrosshairPanel = {
    [0.1] = { type = "h", text = "#arccw.clientcfg" },
    [0.2] = { type = "b", text = "#arccw.cvar.crosshair", var = "arccw_crosshair" },
    [0.3] = { type = "f", text = "#arccw.cvar.crosshair_length", var = "arccw_crosshair_length", min = 0, max = 10 },
    [0.4] = { type = "f", text = "#arccw.cvar.crosshair_thickness", var = "arccw_crosshair_thickness", min = 0, max = 2 },
    [0.5] = { type = "f", text = "#arccw.cvar.crosshair_gap", var = "arccw_crosshair_gap", min = 0, max = 2 },
    [0.6] = { type = "b", text = "#arccw.cvar.crosshair_dot", var = "arccw_crosshair_dot" },
    [0.7] = { type = "b", text = "#arccw.cvar.crosshair_shotgun", var = "arccw_crosshair_shotgun" },
    [0.8] = { type = "b", text = "#arccw.cvar.crosshair_equip", var = "arccw_crosshair_equip" },
    [0.9] = { type = "b", text = "#arccw.cvar.crosshair_static", var = "arccw_crosshair_static" },
    [1.0] = { type = "b", text = "#arccw.cvar.crosshair_clump", var = "arccw_crosshair_clump" },
    [1.1] = { type = "b", text = "#arccw.cvar.crosshair_clump_outline", var = "arccw_crosshair_clump_outline" },
    [1.2] = { type = "b", text = "#arccw.cvar.crosshair_clump_always", var = "arccw_crosshair_clump_always" },
    [1.3] = { type = "m", text = "#arccw.cvar.crosshair_clr", r = "arccw_crosshair_clr_r", g = "arccw_crosshair_clr_g", b = "arccw_crosshair_clr_b", a = "arccw_crosshair_clr_a" },
    [1.4] = { type = "f", text = "#arccw.cvar.crosshair_outline", var = "arccw_crosshair_outline", min = 0, max = 4 },
    [1.5] = { type = "m", text = "#arccw.cvar.crosshair_outline_clr", r = "arccw_crosshair_outline_r", g = "arccw_crosshair_outline_g", b = "arccw_crosshair_outline_b", a = "arccw_crosshair_outline_a" },
    [1.6] = { type = "m", text = "#arccw.cvar.scope_clr", r = "arccw_scope_r", g = "arccw_scope_g", b = "arccw_scope_b" },
}

local ServerPanel = {
    [0.1] = { type = "h", text = "#arccw.adminonly" },
    [0.2] = { type = "b", text = "#arccw.cvar.enable_penetration", var = "arccw_enable_penetration" },
    [0.3] = { type = "b", text = "#arccw.cvar.enable_customization", var = "arccw_enable_customization" },
    [0.4] = { type = "b", text = "#arccw.cvar.truenames", var = "arccw_truenames" },
    [0.5] = { type = "b", text = "#arccw.cvar.equipmentammo", var = "arccw_equipmentammo" },
    [0.6] = { type = "c", text = "#arccw.cvar.equipmentammo.desc" },
    [0.7] = { type = "b", text = "#arccw.cvar.equipmentsingleton", var = "arccw_equipmentsingleton" },
    [0.8] = { type = "c", text = "#arccw.cvar.equipmentsingleton.desc" },
    [0.9] = { type = "i", text = "#arccw.cvar.equipmenttime", var = "arccw_equipmenttime", min = 15, max = 3600 },
    [1.0] = { type = "b", text = "#arccw.cvar.throwinertia", var = "arccw_throwinertia" },
    [1.1] = { type = "b", text = "#arccw.cvar.limityear_enable", var = "arccw_limityear_enable" },
    [1.2] = { type = "i", text = "#arccw.cvar.limityear", var = "arccw_limityear", min = 1800, max = 2100 },
    [1.3] = { type = "b", text = "#arccw.cvar.override_crosshair_off", var = "arccw_override_crosshair_off" },
    [1.4] = { type = "b", text = "#arccw.cvar.override_deploychambered", var = "arccw_override_deploychambered" },
    [1.5] = { type = "b", text = "#arccw.cvar.override_barrellength", var = "arccw_override_nearwall" },
}

local AmmoPanel = {
    [0.1] = { type = "h", text = "#arccw.adminonly" },
    [0.3] = { type = "h", text = "#arccw.cvar.ammo_detonationmode.desc" },
    [0.4] = { type = "i", text = "#arccw.cvar.ammo_detonationmode", var = "arccw_ammo_detonationmode", min = -1, max = 2 },
    [0.5] = { type = "b", text = "#arccw.cvar.ammo_autopickup", var = "arccw_ammo_autopickup" },
    [0.6] = { type = "b", text = "#arccw.cvar.ammo_largetrigger", var = "arccw_ammo_largetrigger" },
    [0.7] = { type = "f", text = "#arccw.cvar.ammo_rareskin", var = "arccw_ammo_rareskin", min = 0, max = 1 },
    [0.8] = { type = "b", text = "#arccw.cvar.ammo_chaindet", var = "arccw_ammo_chaindet" },
    [0.9] = { type = "f", text = "#arccw.cvar.mult_ammohealth", var = "arccw_mult_ammohealth", min = -1, max = 10 },
    [1.0] = { type = "f", text = "#arccw.cvar.mult_ammoamount", var = "arccw_mult_ammoamount", min = 0.1, max = 10 },
}

local AttsPanel = {
    [0.1] = { type = "h", text = "#arccw.adminonly" },
    [0.2] = { type = "h", text = "#arccw.attdesc1" },
    [0.3] = { type = "h", text = "#arccw.attdesc2" },
    [0.4] = { type = "b", text = "#arccw.cvar.attinv_free", var = "arccw_attinv_free" },
    [0.5] = { type = "b", text = "#arccw.cvar.attinv_lockmode", var = "arccw_attinv_lockmode" },
    [0.6] = { type = "c", text = "#arccw.cvar.attinv_loseondie.desc" },
    [0.7] = { type = "i", text = "#arccw.cvar.attinv_loseondie", var = "arccw_attinv_loseondie", min = 0, max = 2 },
    [0.8] = { type = "c", text = "#arccw.cvar.atts_pickx.desc" },
    [0.9] = { type = "i", text = "#arccw.cvar.atts_pickx", var = "arccw_atts_pickx", min = 0, max = 10 },
    [1.0] = { type = "b", text = "#arccw.cvar.enable_dropping", var = "arccw_enable_dropping" },
    [1.1] = { type = "b", text = "#arccw.cvar.atts_spawnrand", var = "arccw_atts_spawnrand" },
    [1.2] = { type = "b", text = "#arccw.cvar.atts_ubglautoload", var = "arccw_atts_ubglautoload" },
    [1.2] = { type = "p", text = "#arccw.blacklist", func = function() RunConsoleCommand("arccw_blacklist") end },
}

local MultsPanel = {
    [0.1] = { type = "h", text = "#arccw.adminonly" },
    [0.2] = { type = "f", text = "Damage", var = "arccw_mult_damage", min = 0, max = 10 },
    [0.3] = { type = "f", text = "NPC Damage", var = "arccw_mult_npcdamage", min = 0, max = 5 },
    [0.4] = { type = "f", text = "Range", var = "arccw_mult_range", min = 0.01, max = 10 },
    [0.5] = { type = "f", text = "Recoil", var = "arccw_mult_recoil", min = 0, max = 10 },
    [0.6] = { type = "f", text = "Penetration", var = "arccw_mult_penetration", min = 0, max = 10 },
    [0.7] = { type = "f", text = "Hip Dispersion", var = "arccw_mult_hipfire", min = 0, max = 10 },
    [0.8] = { type = "f", text = "Move Dispersion", var = "arccw_mult_movedisp", min = 0, max = 10 },
    [0.9] = { type = "f", text = "Reload Time", var = "arccw_mult_reloadtime", min = 0.01, max = 5 },
    [1.0] = { type = "f", text = "ADS Time", var = "arccw_mult_sighttime", min = 0.1, max = 5 },
    [1.1] = { type = "f", text = "Default Clip", var = "arccw_mult_defaultclip", min = -1, max = 10 },
    [1.2] = { type = "f", text = "Random Att. Chance", var = "arccw_mult_attchance", min = 0, max = 10 },
}

local NPCsPanel = {
    [0.1] = { type = "h", text = "#arccw.adminonly" },
    [0.2] = { type = "b", text = "Replace NPC Weapons", var = "arccw_npc_replace" },
    [0.3] = { type = "b", text = "NPC Attachments", var = "arccw_npc_atts" },
}

function ArcCW.GeneratePanelElements(panel, table)
    local AddControl = {
        ["h"] = function(p, d) return p:Help(d.text) end,
        ["c"] = function(p, d) return p:ControlHelp(d.text) end,
        ["b"] = function(p, d) return p:CheckBox(d.text, d.var) end,
        ["i"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 0) end,
        ["f"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 2) end,
        ["m"] = function(p, d) return p:AddControl("color", { Label = d.text, Red = d.r, Green = d.g, Blue = d.b, Alpha = d.a }) end,
        ["p"] = function(p, d) local b = p:Button(d.text) b.DoClick = d.func return b end,
    }

    for _, data in SortedPairs(table) do
        AddControl[data.type](panel, data)
    end
end

local CrosshairPresets = {
    ["#preset.default"] = {
        arccw_crosshair_length        = "4",
        arccw_crosshair_thickness     = "1",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "1",
        arccw_crosshair_shotgun       = "1",
        arccw_crosshair_equip         = "1",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "255",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.tfa"] = {
        arccw_crosshair_length        = "8",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "255",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.cw2"] = {
        arccw_crosshair_length        = "3.5",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "1",
        arccw_crosshair_clump_outline = "1",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "200",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "200",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.cs"] = {
        arccw_crosshair_length        = "3",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "0.4",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "1",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "0",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "0",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "0",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "0",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.light"] = {
        arccw_crosshair_length        = "4",
        arccw_crosshair_thickness     = "0.8",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "1",
        arccw_crosshair_equip         = "1",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "1",
        arccw_crosshair_clump_outline = "1",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "200",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "200",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
}

function ArcCW_Options_Client(panel)
    ArcCW.GeneratePanelElements(panel, ClientPanel)
end

function ArcCW_Options_Viewmodel(panel)
    ArcCW.GeneratePanelElements(panel, Viewmodel)
end

function ArcCW_Options_HUD(panel)
    ArcCW.GeneratePanelElements(panel, HudPanel)
end

function ArcCW_Options_Crosshair(panel)
    panel:AddControl("ComboBox", {
        MenuButton = "1",
        Label      = "#Presets",
        Folder     = "arccw_crosshair",
        CVars      = { "" },
        Options    = CrosshairPresets
    })

    ArcCW.GeneratePanelElements(panel, CrosshairPanel)
end

function ArcCW_Options_Server(panel)
    ArcCW.GeneratePanelElements(panel, ServerPanel)
end

function ArcCW_Options_Ammo(panel)
    ArcCW.GeneratePanelElements(panel, AmmoPanel)
end

function ArcCW_Options_Mults(panel)
    ArcCW.GeneratePanelElements(panel, MultsPanel)
end

function ArcCW_Options_Atts(panel)
    ArcCW.GeneratePanelElements(panel, AttsPanel)
end

function ArcCW_Options_NPC(panel)
    ArcCW.GeneratePanelElements(panel, NPCsPanel)
end

ArcCW.ClientMenus = {
    ["ArcCW_Options_Client"]    = { name = "#arccw.menus.client", func = ArcCW_Options_Client },
    ["ArcCW_Options_Viewmodel"]    = { name = "#arccw.menus.viewmodel", func = ArcCW_Options_Viewmodel },
    ["ArcCW_Options_HUD"]       = { name = "#arccw.menus.hud",    func = ArcCW_Options_HUD },
    ["ArcCW_Options_Crosshair"] = { name = "#arccw.menus.xhair",  func = ArcCW_Options_Crosshair },
    ["ArcCW_Options_Server"]    = { name = "#arccw.menus.server", func = ArcCW_Options_Server },
    ["ArcCW_Options_Ammo"]      = { name = "#arccw.menus.ammo",   func = ArcCW_Options_Ammo },
    ["ArcCW_Options_Atts"]      = { name = "#arccw.menus.atts",   func = ArcCW_Options_Atts },
    ["ArcCW_Options_Mults"]     = { name = "#arccw.menus.mults",  func = ArcCW_Options_Mults },
    ["ArcCW_Options_NPC"]       = { name = "#arccw.menus.npcs",   func = ArcCW_Options_NPC },
}

hook.Add("PopulateToolMenu", "ArcCW_Options", function()
    for menu, data in pairs(ArcCW.ClientMenus) do
        spawnmenu.AddToolMenuOption("Options", "ArcCW", menu, data.name, "", "", data.func)
    end
end)