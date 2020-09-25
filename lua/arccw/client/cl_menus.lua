--[[
    Panel table doc:
    id (any number) = data:
    type
    type args

    types:
    h - header                        text
    c - control help                  text
    b - checkbox                      text var
    i - integer slider                text var min max
    f - float slider (2 nums after .) text var min max
    m - color mixer                   text r g b a 
    p - press or button               text func
    (you can add custom types in ArcCW.GeneratePanelElements's AddControl table)

    Generate elements via ArcCW.GeneratePanelElements:
    panel, panel table with data

    Add menu generation to ArcCW.ClientMenus:
    name = data:
    text - header text
    func - generator function
]]

local BulletPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "b", text = "#arccw.cvar.bullet_enable", var = "arccw_bullet_enable" },
    [0.30] = { type = "f", text = "#arccw.cvar.bullet_velocity", var = "arccw_bullet_velocity", min = 0, max = 100 },
    [0.40] = { type = "f", text = "#arccw.cvar.bullet_gravity", var = "arccw_bullet_gravity", min = 0, max = 32000 },
    [0.50] = { type = "f", text = "#arccw.cvar.bullet_drag", var = "arccw_bullet_drag", min = 0, max = 10 },
    [0.60] = { type = "f", text = "#arccw.cvar.bullet_lifetime", var = "arccw_bullet_lifetime", min = 1, max = 60},
}

local ClientPanel = {
    [0.10] = { type = "h", text = "#arccw.clientcfg" },
    [0.20] = { type = "b", text = "#arccw.cvar.toggleads", var = "arccw_toggleads" },
    [0.30] = { type = "b", text = "#arccw.cvar.altfcgkey", var = "arccw_altfcgkey" },
    [0.40] = { type = "b", text = "#arccw.cvar.altubglkey", var = "arccw_altubglkey" },
    [0.50] = { type = "b", text = "#arccw.cvar.altlaserkey", var = "arccw_altlaserkey" },
    [0.60] = { type = "b", text = "#arccw.cvar.altsafety", var = "arccw_altsafety" },
    [0.70] = { type = "b", text = "#arccw.cvar.autosave", var = "arccw_autosave" },
    [0.80] = { type = "c", text = "#arccw.cvar.autosave.desc" },
    [0.90] = { type = "b", text = "#arccw.cvar.embracetradition", var = "arccw_hud_embracetradition" },
    [1.00] = { type = "c", text = "#arccw.cvar.embracetradition.desc" },
    [1.10] = { type = "b", text = "#arccw.cvar.glare", var = "arccw_glare" },
    [1.20] = { type = "c", text = "#arccw.cvar.glare.desc" },
    [1.30] = { type = "b", text = "#arccw.cvar.shake", var = "arccw_shake" },
    [1.40] = { type = "c", text = "#arccw.cvar.shake_info" },
    [1.50] = { type = "b", text = "#arccw.cvar.2d3d", var = "arccw_2d3d" },
    [1.60] = { type = "c", text = "#arccw.cvar.2d3d_info" },
    [1.70] = { type = "b", text = "#arccw.cvar.attinv_hideunowned", var = "arccw_attinv_hideunowned" },
    [1.80] = { type = "b", text = "#arccw.cvar.attinv_darkunowned", var = "arccw_attinv_darkunowned" },
    [1.90] = { type = "b", text = "#arccw.cvar.attinv_onlyinspect", var = "arccw_attinv_onlyinspect" },
    [2.00] = { type = "b", text = "#arccw.cvar.attinv_simpleproscons", var = "arccw_attinv_simpleproscons" },
}

local PerfomancePanel = {
    --[0.10] = { type = "h", text = "#arccw.clientcfg" },
    [0.20] = { type = "h", text = "#arccw.performance" },
    [0.30] = { type = "b", text = "#arccw.cvar.cheapscopes", var = "arccw_cheapscopes" },
    [0.40] = { type = "c", text = "#arccw.cvar.cheapscopes.desc" },
    [0.50] = { type = "b", text = "#arccw.cvar.flatscopes", var = "arccw_flatscopes" },
    [0.60] = { type = "c", text = "#arccw.cvar.flatscopes.desc" },
    [0.70] = { type = "b", text = "#arccw.cvar.muzzleeffects", var = "arccw_muzzleeffects" },
    [0.80] = { type = "b", text = "#arccw.cvar.fastmuzzles", var = "arccw_fastmuzzles" },
    [0.90] = { type = "b", text = "#arccw.cvar.shelleffects", var = "arccw_shelleffects" },
    [1.00] = { type = "b", text = "#arccw.cvar.att_showothers", var = "arccw_att_showothers" },
    [1.10] = { type = "i", text = "#arccw.cvar.visibility", var = "arccw_visiblity", min = -1, max = 32000},
    [1.20] = { type = "c", text = "#arccw.cvar.visibility.desc" },
    [1.30] = { type = "b", text = "#arccw.cvar.blur", var = "arccw_blur" },
    [1.40] = { type = "b", text = "#arccw.cvar.blur_toytown", var = "arccw_blur_toytown" },
    [1.50] = { type = "b", text = "#arccw.cvar.bullet_imaginary", var = "arccw_bullet_imaginary" },
    [1.70] = { type = "c", text = "#arccw.cvar.bullet_imaginary.desc" },
    [1.80] = { type = "f", text = "#arccw.cvar.shelltime", var = "arccw_shelltime", min = 0, max = 180 },
}

local ViewmodelPanel = {
    [0.10] = { type = "b", text = "#arccw.cvar.vm_coolsway", var = "arccw_vm_coolsway" },
    [0.20] = { type = "b", text = "#arccw.cvar.vm_coolview", var = "arccw_vm_coolview" },
    [0.30] = { type = "f", text = "#arccw.cvar.vm_sway_sprint", var = "arccw_vm_sway_sprint", min = 0, max = 5 },
    [0.40] = { type = "f", text = "#arccw.cvar.vm_bob_sprint", var = "arccw_vm_bob_sprint", min = 0, max = 5 },
    [0.50] = { type = "h", text = "" },
    [0.60] = { type = "c", text = "#arccw.cvar.vm_offsetwarn" },
    [0.70] = { type = "f", text = "#arccw.cvar.vm_right", var = "arccw_vm_right", min = -5, max = 5 },
    [0.80] = { type = "f", text = "#arccw.cvar.vm_forward", var = "arccw_vm_forward", min = -5, max = 5 },
    [0.90] = { type = "f", text = "#arccw.cvar.vm_up", var = "arccw_vm_up", min = -5, max = 5 },
    [1.00] = { type = "h", text = "" },
    [1.10] = { type = "c", text = "#arccw.cvar.vm_swaywarn" },
    [1.20] = { type = "f", text = "#arccw.cvar.vm_lookxmult", var = "arccw_vm_lookxmult", min = -10, max = 10 },
    [1.30] = { type = "f", text = "#arccw.cvar.vm_lookymult", var = "arccw_vm_lookymult", min = -10, max = 10 },
    [1.40] = { type = "f", text = "#arccw.cvar.vm_accelmult", var = "arccw_vm_accelmult", min = 0.3, max = 3 },
    [1.50] = { type = "f", text = "#arccw.cvar.vm_swayxmult", var = "arccw_vm_swayxmult", min = -1, max = 1 },
    [1.60] = { type = "f", text = "#arccw.cvar.vm_swayymult", var = "arccw_vm_swayymult", min = -2, max = 2 },
    [1.70] = { type = "f", text = "#arccw.cvar.vm_swayzmult", var = "arccw_vm_swayzmult", min = -2, max = 2 },
    [1.80] = { type = "h", text = "" },
    [1.90] = { type = "c", text = "#arccw.cvar.vm_viewwarn" },
    [2.00] = { type = "f", text = "#arccw.cvar.vm_coolviewmult", var = "arccw_vm_coolview_mult", min = -10, max = 10 },
}

local HudPanel = {
    [0.10] = { type = "h", text = "#arccw.clientcfg" },
    [0.20] = { type = "b", text = "#arccw.cvar.hud_showhealth", var = "arccw_hud_showhealth" },
    [0.30] = { type = "b", text = "#arccw.cvar.hud_showammo", var = "arccw_hud_showammo" },
    [0.40] = { type = "b", text = "#arccw.cvar.hud_3dfun", var = "arccw_hud_3dfun" },
    [0.50] = { type = "b", text = "#arccw.cvar.hud_forceshow", var = "arccw_hud_forceshow" },
    [1.00] = { type = "b", text = "#arccw.cvar.attinv_closeonhurt", var = "arccw_attinv_closeonhurt" },
    [1.10] = { type = "f", text = "#arccw.cvar.hudpos_deadzone_x", var = "arccw_hud_deadzone_x", min = 0, max = 1 },
    [1.20] = { type = "f", text = "#arccw.cvar.hudpos_deadzone_y", var = "arccw_hud_deadzone_y", min = 0, max = 1 },
}

local CrosshairPanel = {
    [0.10] = { type = "h", text = "#arccw.clientcfg" },
    [0.20] = { type = "b", text = "#arccw.cvar.crosshair", var = "arccw_crosshair" },
    [0.30] = { type = "f", text = "#arccw.cvar.crosshair_length", var = "arccw_crosshair_length", min = 0, max = 10 },
    [0.40] = { type = "f", text = "#arccw.cvar.crosshair_thickness", var = "arccw_crosshair_thickness", min = 0, max = 2 },
    [0.50] = { type = "f", text = "#arccw.cvar.crosshair_gap", var = "arccw_crosshair_gap", min = 0, max = 2 },
    [0.60] = { type = "b", text = "#arccw.cvar.crosshair_dot", var = "arccw_crosshair_dot" },
    [0.70] = { type = "b", text = "#arccw.cvar.crosshair_shotgun", var = "arccw_crosshair_shotgun" },
    [0.80] = { type = "b", text = "#arccw.cvar.crosshair_equip", var = "arccw_crosshair_equip" },
    [0.90] = { type = "b", text = "#arccw.cvar.crosshair_static", var = "arccw_crosshair_static" },
    [1.00] = { type = "b", text = "#arccw.cvar.crosshair_clump", var = "arccw_crosshair_clump" },
    [1.10] = { type = "b", text = "#arccw.cvar.crosshair_clump_outline", var = "arccw_crosshair_clump_outline" },
    [1.20] = { type = "b", text = "#arccw.cvar.crosshair_clump_always", var = "arccw_crosshair_clump_always" },
    [1.30] = { type = "m", text = "#arccw.cvar.crosshair_clr", r = "arccw_crosshair_clr_r", g = "arccw_crosshair_clr_g", b = "arccw_crosshair_clr_b", a = "arccw_crosshair_clr_a" },
    [1.40] = { type = "f", text = "#arccw.cvar.crosshair_outline", var = "arccw_crosshair_outline", min = 0, max = 4 },
    [1.50] = { type = "m", text = "#arccw.cvar.crosshair_outline_clr", r = "arccw_crosshair_outline_r", g = "arccw_crosshair_outline_g", b = "arccw_crosshair_outline_b", a = "arccw_crosshair_outline_a" },
    [1.60] = { type = "m", text = "#arccw.cvar.scope_clr", r = "arccw_scope_r", g = "arccw_scope_g", b = "arccw_scope_b" },
}

local ServerPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "b", text = "#arccw.cvar.enable_penetration", var = "arccw_enable_penetration" },
    [0.30] = { type = "b", text = "#arccw.cvar.enable_customization", var = "arccw_enable_customization" },
    [0.40] = { type = "b", text = "#arccw.cvar.truenames", var = "arccw_truenames" },
    [0.50] = { type = "b", text = "#arccw.cvar.equipmentammo", var = "arccw_equipmentammo" },
    [0.60] = { type = "c", text = "#arccw.cvar.equipmentammo.desc" },
    [0.70] = { type = "b", text = "#arccw.cvar.equipmentsingleton", var = "arccw_equipmentsingleton" },
    [0.80] = { type = "c", text = "#arccw.cvar.equipmentsingleton.desc" },
    [0.90] = { type = "i", text = "#arccw.cvar.equipmenttime", var = "arccw_equipmenttime", min = 15, max = 3600 },
    [1.00] = { type = "b", text = "#arccw.cvar.throwinertia", var = "arccw_throwinertia" },
    [1.10] = { type = "b", text = "#arccw.cvar.limityear_enable", var = "arccw_limityear_enable" },
    [1.20] = { type = "i", text = "#arccw.cvar.limityear", var = "arccw_limityear", min = 1800, max = 2100 },
    [1.30] = { type = "b", text = "#arccw.cvar.override_crosshair_off", var = "arccw_override_crosshair_off" },
    [1.40] = { type = "b", text = "#arccw.cvar.override_deploychambered", var = "arccw_override_deploychambered" },
    [1.50] = { type = "b", text = "#arccw.cvar.override_barrellength", var = "arccw_override_nearwall" },
    [1.60] = { type = "b", text = "#arccw.cvar.doorbust", var = "arccw_doorbust" },
}

local AmmoPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "i", text = "#arccw.cvar.ammo_detonationmode", var = "arccw_ammo_detonationmode", min = -1, max = 2 },
    [0.30] = { type = "c", text = "#arccw.cvar.ammo_detonationmode.desc" },
    [0.40] = { type = "b", text = "#arccw.cvar.ammo_autopickup", var = "arccw_ammo_autopickup" },
    [0.50] = { type = "b", text = "#arccw.cvar.ammo_largetrigger", var = "arccw_ammo_largetrigger" },
    [0.60] = { type = "f", text = "#arccw.cvar.ammo_rareskin", var = "arccw_ammo_rareskin", min = 0, max = 1 },
    [0.70] = { type = "b", text = "#arccw.cvar.ammo_chaindet", var = "arccw_ammo_chaindet" },
    [0.80] = { type = "f", text = "#arccw.cvar.mult_ammohealth", var = "arccw_mult_ammohealth", min = -1, max = 10 },
    [0.90] = { type = "f", text = "#arccw.cvar.mult_ammoamount", var = "arccw_mult_ammoamount", min = 0.1, max = 10 },
}

local AttsPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "h", text = "#arccw.attdesc1" },
    [0.30] = { type = "h", text = "#arccw.attdesc2" },
    [0.40] = { type = "b", text = "#arccw.cvar.attinv_free", var = "arccw_attinv_free" },
    [0.50] = { type = "b", text = "#arccw.cvar.attinv_lockmode", var = "arccw_attinv_lockmode" },
    [0.60] = { type = "i", text = "#arccw.cvar.attinv_loseondie", var = "arccw_attinv_loseondie", min = 0, max = 2 },
    [0.70] = { type = "c", text = "#arccw.cvar.attinv_loseondie.desc" },
    [0.80] = { type = "i", text = "#arccw.cvar.atts_pickx", var = "arccw_atts_pickx", min = 0, max = 10 },
    [0.90] = { type = "c", text = "#arccw.cvar.atts_pickx.desc" },
    [1.00] = { type = "b", text = "#arccw.cvar.enable_dropping", var = "arccw_enable_dropping" },
    [1.10] = { type = "b", text = "#arccw.cvar.atts_spawnrand", var = "arccw_atts_spawnrand" },
    [1.20] = { type = "b", text = "#arccw.cvar.atts_ubglautoload", var = "arccw_atts_ubglautoload" },
    [1.30] = { type = "p", text = "#arccw.blacklist", func = function() RunConsoleCommand("arccw_blacklist") end },
}

local MultsPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "f", text = "Damage", var = "arccw_mult_damage", min = 0, max = 10 },
    [0.30] = { type = "f", text = "NPC Damage", var = "arccw_mult_npcdamage", min = 0, max = 5 },
    [0.40] = { type = "f", text = "Range", var = "arccw_mult_range", min = 0.01, max = 10 },
    [0.50] = { type = "f", text = "Recoil", var = "arccw_mult_recoil", min = 0, max = 10 },
    [0.60] = { type = "f", text = "Penetration", var = "arccw_mult_penetration", min = 0, max = 10 },
    [0.70] = { type = "f", text = "Hip Dispersion", var = "arccw_mult_hipfire", min = 0, max = 10 },
    [0.80] = { type = "f", text = "Move Dispersion", var = "arccw_mult_movedisp", min = 0, max = 10 },
    [0.90] = { type = "f", text = "Reload Time", var = "arccw_mult_reloadtime", min = 0.01, max = 5 },
    [1.00] = { type = "f", text = "ADS Time", var = "arccw_mult_sighttime", min = 0.1, max = 5 },
    [1.10] = { type = "i", text = "Default Clip", var = "arccw_mult_defaultclip", min = -1, max = 10 },
    [1.20] = { type = "f", text = "Random Att. Chance", var = "arccw_mult_attchance", min = 0, max = 10 },
}

local NPCsPanel = {
    [0.10] = { type = "h", text = "#arccw.adminonly" },
    [0.20] = { type = "b", text = "Replace NPC Weapons", var = "arccw_npc_replace" },
    [0.30] = { type = "b", text = "NPC Attachments", var = "arccw_npc_atts" },
}

function ArcCW.GeneratePanelElements(panel, table)
    local AddControl = {
        ["h"] = function(p, d) return p:Help(d.text) end,
        ["c"] = function(p, d) return p:ControlHelp(d.text) end,
        ["b"] = function(p, d) return p:CheckBox(d.text, d.var) end,
        ["i"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 0) end,
        ["f"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 2) end,
        ["m"] = function(p, d) return p:AddControl("color", { Label = d.text, Red = d.r, Green = d.g, Blue = d.b, Alpha = d.a }) end, -- change this someday
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

function ArcCW_Options_Bullet(panel)
    ArcCW.GeneratePanelElements(panel, BulletPanel)
end

function ArcCW_Options_Client(panel)
    ArcCW.GeneratePanelElements(panel, ClientPanel)
end

function ArcCW_Options_Perf(panel)
    ArcCW.GeneratePanelElements(panel, PerfomancePanel)
end

function ArcCW_Options_Viewmodel(panel)
    ArcCW.GeneratePanelElements(panel, ViewmodelPanel)
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
    ["ArcCW_Options_Client"]    = { text = "#arccw.menus.client", func = ArcCW_Options_Client },
    ["ArcCW_Options_Bullet"]    = { text = "#arccw.menus.bullet", func = ArcCW_Options_Bullet },
    ["ArcCW_Options_Perf"]      = { text = "#arccw.menus.perf", func = ArcCW_Options_Perf },
    ["ArcCW_Options_Viewmodel"] = { text = "#arccw.menus.vmodel", func = ArcCW_Options_Viewmodel },
    ["ArcCW_Options_HUD"]       = { text = "#arccw.menus.hud",    func = ArcCW_Options_HUD },
    ["ArcCW_Options_Crosshair"] = { text = "#arccw.menus.xhair",  func = ArcCW_Options_Crosshair },
    ["ArcCW_Options_Server"]    = { text = "#arccw.menus.server", func = ArcCW_Options_Server },
    ["ArcCW_Options_Ammo"]      = { text = "#arccw.menus.ammo",   func = ArcCW_Options_Ammo },
    ["ArcCW_Options_Atts"]      = { text = "#arccw.menus.atts",   func = ArcCW_Options_Atts },
    ["ArcCW_Options_Mults"]     = { text = "#arccw.menus.mults",  func = ArcCW_Options_Mults },
    ["ArcCW_Options_NPC"]       = { text = "#arccw.menus.npcs",   func = ArcCW_Options_NPC },
}

hook.Add("PopulateToolMenu", "ArcCW_Options", function()
    for menu, data in pairs(ArcCW.ClientMenus) do
        spawnmenu.AddToolMenuOption("Options", "ArcCW", menu, data.text, "", "", data.func)
    end
end)