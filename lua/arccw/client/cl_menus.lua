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
    t - textbox                       text string
    o - combo box                     text var choices (key - cvar, value - text)
    d - binder                        text var
    (you can add custom types in ArcCW.GeneratePanelElements's AddControl table)

    Generate elements via ArcCW.GeneratePanelElements:
    panel, panel table with data

    Add menu generation to ArcCW.ClientMenus:
    name = data:
    text - header text
    func - generator function
]]

local BulletPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "b", text = "#arccw.cvar.bullet_enable", var = "arccw_bullet_enable", sv = true },
    { type = "b", text = "#arccw.cvar.enable_penetration", var = "arccw_enable_penetration", sv = true },
    { type = "b", text = "#arccw.cvar.enable_ricochet", var = "arccw_enable_ricochet", sv = true },
    { type = "f", text = "#arccw.cvar.bullet_velocity", var = "arccw_bullet_velocity", min = 0, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_gravity", var = "arccw_bullet_gravity", min = 0, max = 1200, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_drag", var = "arccw_bullet_drag", min = 0, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_lifetime", var = "arccw_bullet_lifetime", min = 1, max = 20, sv = true},
}

local ClientPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.automaticreload", var = "arccw_automaticreload" },
    { type = "c", text = "#arccw.cvar.automaticreload.desc" },
    { type = "f", text = "#arccw.cvar.adjustsensthreshold", var = "arccw_adjustsensthreshold", min = 0, max = 50, sv = true },
    { type = "c", text = "#arccw.cvar.adjustsensthreshold.desc" },
    { type = "b", text = "#arccw.cvar.toggleads", var = "arccw_toggleads" },
    { type = "b", text = "#arccw.cvar.autosave", var = "arccw_autosave" },
    { type = "c", text = "#arccw.cvar.autosave.desc" },
    { type = "b", text = "#arccw.cvar.embracetradition", var = "arccw_hud_embracetradition" },
    { type = "c", text = "#arccw.cvar.embracetradition.desc" },
    { type = "b", text = "#arccw.cvar.glare", var = "arccw_glare" },
    { type = "c", text = "#arccw.cvar.glare.desc" },
    { type = "b", text = "#arccw.cvar.shake", var = "arccw_shake" },
    { type = "c", text = "#arccw.cvar.shake_info" },
    { type = "b", text = "#arccw.cvar.aimassist", var = "arccw_aimassist_cl" },
    { type = "c", text = "#arccw.cvar.aimassist_cl.desc" },
    { type = "b", text = "#arccw.cvar.2d3d", var = "arccw_2d3d" },
    { type = "c", text = "#arccw.cvar.2d3d_info" },
    { type = "t", text = "#arccw.cvar.language", var = "arccw_language"  },
    { type = "c", text = "#arccw.cvar.language_info" },
}

local PerformancePanel = {
    --{ type = "h", text = "#arccw.clientcfg" },
    { type = "h", text = "#arccw.performance" },
    { type = "b", text = "#arccw.cvar.cheapscopes", var = "arccw_cheapscopes" },
    { type = "c", text = "#arccw.cvar.cheapscopes.desc" },
    -- { type = "b", text = "#arccw.cvar.flatscopes", var = "arccw_flatscopes" },
    -- { type = "c", text = "#arccw.cvar.flatscopes.desc" },
    { type = "b", text = "#arccw.cvar.muzzleeffects", var = "arccw_muzzleeffects" },
    { type = "b", text = "#arccw.cvar.fastmuzzles", var = "arccw_fastmuzzles" },
    { type = "b", text = "#arccw.cvar.shelleffects", var = "arccw_shelleffects" },
    { type = "b", text = "#arccw.cvar.att_showothers", var = "arccw_att_showothers" },
    { type = "i", text = "#arccw.cvar.visibility", var = "arccw_visibility", min = -1, max = 32000},
    { type = "c", text = "#arccw.cvar.visibility.desc" },
    { type = "b", text = "#arccw.cvar.blur", var = "arccw_blur" },
    { type = "b", text = "#arccw.cvar.blur_toytown", var = "arccw_blur_toytown" },
    { type = "b", text = "#arccw.cvar.bullet_imaginary", var = "arccw_bullet_imaginary" },
    { type = "c", text = "#arccw.cvar.bullet_imaginary.desc" },
    { type = "f", text = "#arccw.cvar.shelltime", var = "arccw_shelltime", min = 0, max = 180 },
}

local ViewmodelPanel = {
    { type = "b", text = "#arccw.cvar.vm_coolsway", var = "arccw_vm_coolsway" },
    { type = "b", text = "#arccw.cvar.vm_coolview", var = "arccw_vm_coolview" },
    { type = "f", text = "#arccw.cvar.vm_sway_sprint", var = "arccw_vm_sway_sprint", min = 0, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_bob_sprint", var = "arccw_vm_bob_sprint", min = 0, max = 5 },
    { type = "h", text = "" },
    { type = "c", text = "#arccw.cvar.vm_offsetwarn" },
    { type = "f", text = "#arccw.cvar.vm_fov", var = "arccw_vm_fov", min = -15, max = 15 },
    { type = "f", text = "#arccw.cvar.vm_right", var = "arccw_vm_right", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_forward", var = "arccw_vm_forward", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_up", var = "arccw_vm_up", min = -5, max = 5 },
    { type = "c", text = "" },
    { type = "c", text = "#arccw.cvar.vm_swaywarn" },
    { type = "f", text = "#arccw.cvar.vm_look_xmult", var = "arccw_vm_look_xmult", min = -10, max = 10 },
    { type = "f", text = "#arccw.cvar.vm_look_ymult", var = "arccw_vm_look_ymult", min = -10, max = 10 },
    { type = "f", text = "#arccw.cvar.vm_sway_xmult", var = "arccw_vm_sway_xmult", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_sway_ymult", var = "arccw_vm_sway_ymult", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_sway_zmult", var = "arccw_vm_sway_zmult", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_sway_speedmult", var = "arccw_vm_sway_speedmult", min = 0, max = 2 },
    { type = "f", text = "#arccw.cvar.vm_sway_rotatemult", var = "arccw_vm_sway_rotatemult", min = -3, max = 3 },
    { type = "h", text = "" },
    { type = "c", text = "#arccw.cvar.vm_viewwarn" },
    { type = "f", text = "#arccw.cvar.vm_coolviewmult", var = "arccw_vm_coolview_mult", min = -5, max = 5 },
}

local HudPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.hud_showhealth", var = "arccw_hud_showhealth" },
    { type = "c", text = "#arccw.cvar.hud_showhealth.desc" },
    { type = "b", text = "#arccw.cvar.hud_showammo", var = "arccw_hud_showammo" },
    { type = "c", text = "#arccw.cvar.hud_showammo.desc" },
    { type = "b", text = "#arccw.cvar.hud_minimal", var = "arccw_hud_minimal" },
    { type = "c", text = "#arccw.cvar.hud_minimal.desc" },
    { type = "b", text = "#arccw.cvar.hud_forceshow", var = "arccw_hud_forceshow" },
    { type = "c", text = "#arccw.cvar.hud_forceshow.desc" },
    { type = "b", text = "#arccw.cvar.attinv_closeonhurt", var = "arccw_attinv_closeonhurt" },
    { type = "f", text = "#arccw.cvar.hudpos_deadzone_x", var = "arccw_hud_deadzone_x", min = 0, max = 0.5 },
    { type = "f", text = "#arccw.cvar.hudpos_deadzone_y", var = "arccw_hud_deadzone_y", min = 0, max = 0.5 },
    { type = "c", text = "#arccw.cvar.hudpos_deadzone.desc" },
    { type = "f", text = "#arccw.cvar.hudpos_size", var = "arccw_hud_size", min = 0.67, max = 1.5 },
    { type = "c", text = "#arccw.cvar.hudpos_size.desc" },
    { type = "t", text = "#arccw.cvar.font", var = "arccw_font"  },
    { type = "c", text = "#arccw.cvar.font_info" },

    { type = "b", text = "#arccw.cvar.attinv_sound", var = "arccw_cust_sounds" },
    { type = "c", text = "#arccw.cvar.attinv_sound.desc" },
    { type = "b", text = "#arccw.cvar.attinv_hideunowned", var = "arccw_attinv_hideunowned" },
    { type = "b", text = "#arccw.cvar.attinv_darkunowned", var = "arccw_attinv_darkunowned" },
    { type = "b", text = "#arccw.cvar.attinv_onlyinspect", var = "arccw_attinv_onlyinspect" },
    { type = "b", text = "#arccw.cvar.attinv_simpleproscons", var = "arccw_attinv_simpleproscons" },
    
    { type = "h", text = "#arccw.3d2d" },
    { type = "b", text = "#arccw.cvar.hud_3dfun", var = "arccw_hud_3dfun" },
    { type = "c", text = "#arccw.cvar.hud_3dfun.desc" },
    { type = "i", text = "#arccw.cvar.hud_3dfun_decay", var = "arccw_hud_3dfun_decaytime", min = 0, max = 5 },
    { type = "c", text = "#arccw.cvar.hud_3dfun_decay.desc" },
    { type = "b", text = "#arccw.cvar.hud_3dfun_lite", var = "arccw_hud_3dfun_lite" },
    { type = "c", text = "#arccw.cvar.hud_3dfun_lite.desc" },
    { type = "b", text = "#arccw.cvar.hud_3dfun_ammotype", var = "arccw_hud_3dfun_ammotype" },
    { type = "c", text = "#arccw.cvar.hud_3dfun_ammotype.desc" },

    { type = "f", text = "#arccw.cvar.hud_3dfun_right", var = "arccw_hud_3dfun_right", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.hud_3dfun_up", var = "arccw_hud_3dfun_up", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.hud_3dfun_forward", var = "arccw_hud_3dfun_forward", min = -5, max = 5 },
}

local CrosshairPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.crosshair", var = "arccw_crosshair" },
    { type = "f", text = "#arccw.cvar.crosshair_length", var = "arccw_crosshair_length", min = 0, max = 10 },
    { type = "f", text = "#arccw.cvar.crosshair_thickness", var = "arccw_crosshair_thickness", min = 0, max = 2 },
    { type = "f", text = "#arccw.cvar.crosshair_gap", var = "arccw_crosshair_gap", min = 0, max = 2 },
    { type = "b", text = "#arccw.cvar.crosshair_dot", var = "arccw_crosshair_dot" },
    { type = "b", text = "#arccw.cvar.crosshair_shotgun", var = "arccw_crosshair_shotgun" },
    { type = "b", text = "#arccw.cvar.crosshair_equip", var = "arccw_crosshair_equip" },
    { type = "b", text = "#arccw.cvar.crosshair_static", var = "arccw_crosshair_static" },
    { type = "b", text = "#arccw.cvar.crosshair_clump", var = "arccw_crosshair_clump" },
    { type = "b", text = "#arccw.cvar.crosshair_clump_outline", var = "arccw_crosshair_clump_outline" },
    { type = "b", text = "#arccw.cvar.crosshair_clump_always", var = "arccw_crosshair_clump_always" },
    { type = "b", text = "#arccw.cvar.crosshair_aa", var = "arccw_crosshair_aa" },
    { type = "m", text = "#arccw.cvar.crosshair_clr", r = "arccw_crosshair_clr_r", g = "arccw_crosshair_clr_g", b = "arccw_crosshair_clr_b", a = "arccw_crosshair_clr_a" },
    { type = "f", text = "#arccw.cvar.crosshair_outline", var = "arccw_crosshair_outline", min = 0, max = 4 },
    { type = "m", text = "#arccw.cvar.crosshair_outline_clr", r = "arccw_crosshair_outline_r", g = "arccw_crosshair_outline_g", b = "arccw_crosshair_outline_b", a = "arccw_crosshair_outline_a" },
    { type = "m", text = "#arccw.cvar.scope_clr", r = "arccw_scope_r", g = "arccw_scope_g", b = "arccw_scope_b" },
}

local BindsPanel = {
    { type = "h", text = "#arccw.bindhelp" },
    { type = "b", text = "#arccw.cvar.altfcgkey", var = "arccw_altfcgkey" },
    { type = "b", text = "#arccw.cvar.altubglkey", var = "arccw_altubglkey" },
    { type = "b", text = "#arccw.cvar.altsafety", var = "arccw_altsafety" },
    { type = "b", text = "#arccw.cvar.altbindsonly", var = "arccw_altbindsonly" },
    { type = "c", text = "#arccw.cvar.altbindsonly.desc" },
    { type = "d", text = "#arccw.bind.firemode", var = "arccw_firemode" },
    { type = "d", text = "#arccw.bind.zoom_in", var = "arccw_zoom_in" },
    { type = "d", text = "#arccw.bind.zoom_out", var = "arccw_zoom_out" },
    { type = "d", text = "#arccw.bind.toggle_inv", var = "arccw_toggle_inv" },
    { type = "d", text = "#arccw.bind.switch_scope", var = "arccw_switch_scope" },
    { type = "d", text = "#arccw.bind.toggle_ubgl", var = "arccw_toggle_ubgl" },
    { type = "d", text = "#arccw.bind.melee", var = "arccw_melee" },
}


local ServerPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "o", text = "#arccw.cvar.enable_customization", var = "arccw_enable_customization", sv = true,
            choices = {[-1] = "#arccw.cvar.enable_customization.-1", [0] = "#arccw.cvar.enable_customization.0", [1] = "#arccw.cvar.enable_customization.1"}},
    { type = "c", text = "#arccw.cvar.enable_customization.desc" },
    { type = "b", text = "#arccw.cvar.truenames", var = "arccw_truenames", sv = true },
    { type = "b", text = "#arccw.cvar.equipmentammo", var = "arccw_equipmentammo", sv = true },
    { type = "c", text = "#arccw.cvar.equipmentammo.desc" },
    { type = "b", text = "#arccw.cvar.equipmentsingleton", var = "arccw_equipmentsingleton", sv = true },
    { type = "c", text = "#arccw.cvar.equipmentsingleton.desc" },
    { type = "i", text = "#arccw.cvar.equipmenttime", var = "arccw_equipmenttime", min = 15, max = 3600, sv = true },
    { type = "b", text = "#arccw.cvar.throwinertia", var = "arccw_throwinertia", sv = true },
    { type = "b", text = "#arccw.cvar.limityear_enable", var = "arccw_limityear_enable", sv = true },
    { type = "i", text = "#arccw.cvar.limityear", var = "arccw_limityear", min = 1800, max = 2100, sv = true },
    { type = "c", text = "#arccw.cvar.limityear.desc"},
    { type = "b", text = "#arccw.cvar.desync", var = "arccw_desync", sv = true },
    { type = "c", text = "#arccw.cvar.desync.desc" },
    { type = "b", text = "#arccw.cvar.override_crosshair_off", var = "arccw_override_crosshair_off", sv = true },
    { type = "b", text = "#arccw.cvar.override_barrellength", var = "arccw_override_nearwall", sv = true },
    { type = "b", text = "#arccw.cvar.doorbust", var = "arccw_doorbust", sv = true },
    { type = "f", text = "#arccw.cvar.weakensounds", var = "arccw_weakensounds", min = -20, max = 30, sv = true},
    { type = "c", text = "#arccw.cvar.weakensounds.desc" },
    { type = "b", text = "#arccw.cvar.aimassist", var = "arccw_aimassist", sv = true },
    { type = "c", text = "#arccw.cvar.aimassist.desc" },
    { type = "b", text = "#arccw.cvar.aimassist_head", var = "arccw_aimassist_head", sv = true },
    { type = "f", text = "#arccw.cvar.aimassist_cone", var = "arccw_aimassist_cone", min = 0, max = 360, sv = true},
    { type = "f", text = "#arccw.cvar.aimassist_distance", var = "arccw_aimassist_distance", min = 128, max = 4096, sv = true},
    { type = "f", text = "#arccw.cvar.aimassist_intensity", var = "arccw_aimassist_intensity", min = 0, max = 10, sv = true},
}

local AmmoPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "o", text = "#arccw.cvar.ammo_detonationmode", var = "arccw_ammo_detonationmode", sv = true,
            choices = {[-1] = "#arccw.cvar.ammo_detonationmode.-1", [0] = "#arccw.cvar.ammo_detonationmode.0", [1] = "#arccw.cvar.ammo_detonationmode.1", [2] = "#arccw.cvar.ammo_detonationmode.2"}},
    { type = "b", text = "#arccw.cvar.ammo_autopickup", var = "arccw_ammo_autopickup", sv = true },
    { type = "b", text = "#arccw.cvar.ammo_largetrigger", var = "arccw_ammo_largetrigger", sv = true },
    { type = "f", text = "#arccw.cvar.ammo_rareskin", var = "arccw_ammo_rareskin", min = 0, max = 1, sv = true },
    { type = "b", text = "#arccw.cvar.ammo_chaindet", var = "arccw_ammo_chaindet", sv = true },
    { type = "b", text = "#arccw.cvar.ammo_replace", var = "arccw_ammo_replace", sv = true },
    { type = "f", text = "#arccw.cvar.mult_ammohealth", var = "arccw_mult_ammohealth", min = -1, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.mult_ammoamount", var = "arccw_mult_ammoamount", min = 0.1, max = 10, sv = true },
}

local AttsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "h", text = "#arccw.attdesc1" },
    { type = "h", text = "#arccw.attdesc2" },
    { type = "b", text = "#arccw.cvar.attinv_free", var = "arccw_attinv_free", sv = true },
    { type = "b", text = "#arccw.cvar.attinv_lockmode", var = "arccw_attinv_lockmode", sv = true },
    { type = "o", text = "#arccw.cvar.attinv_loseondie", var = "arccw_attinv_loseondie", sv = true,
            choices = {[0] = "#arccw.combobox.disabled", [1] = "#arccw.cvar.attinv_loseondie.1", [2] = "#arccw.cvar.attinv_loseondie.2"}},
    { type = "i", text = "#arccw.cvar.atts_pickx", var = "arccw_atts_pickx", min = 0, max = 10, sv = true },
    { type = "c", text = "#arccw.cvar.atts_pickx.desc", sv = true },
    { type = "b", text = "#arccw.cvar.enable_dropping", var = "arccw_enable_dropping", sv = true },
    { type = "b", text = "#arccw.cvar.atts_spawnrand", var = "arccw_atts_spawnrand", sv = true },
    { type = "b", text = "#arccw.cvar.atts_ubglautoload", var = "arccw_atts_ubglautoload", sv = true },
    { type = "p", text = "#arccw.blacklist", func = function() RunConsoleCommand("arccw_blacklist") end },
}

local DevPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "h", text = "#arccw.dev_info1" },
    { type = "h", text = "#arccw.dev_info2" },
    { type = "b", text = "#arccw.cvar.dev_reloadonadmincleanup", var = "arccw_reloadatts_mapcleanup", sv = true },
    { type = "c", text = "#arccw.cvar.dev_reloadonadmincleanup.desc" },
    { type = "b", text = "#arccw.cvar.dev_registerentities", var = "arccw_reloadatts_registerentities", sv = true },
    { type = "c", text = "#arccw.cvar.dev_registerentities.desc" },
    { type = "b", text = "#arccw.cvar.dev_showignored", var = "arccw_reloadatts_showignored", sv = true },
    { type = "c", text = "#arccw.cvar.dev_showignored.desc" },
    { type = "b", text = "#arccw.cvar.dev_debug", var = "arccw_dev_debug", sv = true },
    { type = "c", text = "#arccw.cvar.dev_debug.desc" },
    { type = "p", text = "#arccw.cvar.dev_reloadatts", func = function() RunConsoleCommand("arccw_reloadatts") end },
    { type = "h", text = "#arccw.cvar.dev_reloadatts.desc" },
    { type = "p", text = "#arccw.cvar.dev_reloadlangs", func = function() RunConsoleCommand("arccw_reloadlangs") end },
    { type = "h", text = "#arccw.cvar.dev_reloadlangs.desc" },
    { type = "p", text = "#arccw.cvar.dev_spawnmenureload", func = function() RunConsoleCommand("spawnmenu_reload") end },
    { type = "h", text = "#arccw.cvar.dev_spawnmenureload.desc" },
}

local MultsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "f", text = "#arccw.cvar.mult_damage",          var = "arccw_mult_damage", min = 0, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.mult_npcdamage",       var = "arccw_mult_npcdamage", min = 0, max = 5, sv = true },
    { type = "f", text = "#arccw.cvar.mult_range",           var = "arccw_mult_range", min = 0.1, max = 5, sv = true },
    { type = "f", text = "#arccw.cvar.mult_recoil",          var = "arccw_mult_recoil", min = 0, max = 5, sv = true },
    { type = "f", text = "#arccw.cvar.mult_penetration",     var = "arccw_mult_penetration", min = 0, max = 5, sv = true },
    { type = "f", text = "#arccw.cvar.mult_hipfire",         var = "arccw_mult_hipfire", min = 0, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.mult_accuracy",        var = "arccw_mult_accuracy", min = 0, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.mult_movedisp",        var = "arccw_mult_movedisp", min = 0, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.mult_reloadtime",      var = "arccw_mult_reloadtime", min = 0.2, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.mult_sighttime",       var = "arccw_mult_sighttime", min = 0.25, max = 3, sv = true },
    { type = "i", text = "#arccw.cvar.mult_defaultammo",     var = "arccw_mult_defaultammo", min = 0, max = 10, sv = true }, -- Fix default clip first
    { type = "f", text = "#arccw.cvar.mult_attchance",       var = "arccw_mult_attchance", min = 0, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.mult_heat",            var = "arccw_mult_heat", min = 0, max = 3, sv = true },
    { type = "f", text = "#arccw.cvar.mult_crouchdisp",      var = "arccw_mult_crouchdisp", min = 0, max = 1, sv = true },
    { type = "f", text = "#arccw.cvar.mult_crouchrecoil",    var = "arccw_mult_crouchrecoil", min = 0, max = 1, sv = true },
    { type = "b", text = "#arccw.cvar.mult_startunloaded",   var = "arccw_mult_startunloaded", sv = true },
    { type = "b", text = "#arccw.cvar.mult_shootwhilesprinting",   var = "arccw_mult_shootwhilesprinting", sv = true },
}

local MultPresets = {
    ["#preset.default"] = {
        arccw_mult_damage                   = "1",
        arccw_mult_npcdamage                = "1",
        arccw_mult_range                    = "1",
        arccw_mult_recoil                   = "1",
        arccw_mult_penetration              = "1",
        arccw_mult_hipfire                  = "1",
        arccw_mult_movedisp                 = "1",
        arccw_mult_reloadtime               = "1",
        arccw_mult_sighttime                = "1",
        arccw_mult_defaultclip              = "1",
        arccw_mult_attchance                = "1",
        arccw_mult_heat                     = "1",
    }
}

local NPCsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "b", text = "Replace NPC Weapons", var = "arccw_npc_replace", sv = true },
    { type = "b", text = "NPC Attachments", var = "arccw_npc_atts", sv = true },
}

local function networktheconvar(convar, value, p)
    if !LocalPlayer():IsAdmin() then return end
    if (p.TickCreated or 0) == UnPredictedCurTime() then return end
    if value == true or value == false then
        value = value and 1 or 0
    end
    if IsColor(value) then
        value = tostring(value.r) .. " " .. tostring(value.g) .. " " .. tostring(value.b) .. " " .. tostring(value.a)
    end

    local command = convar .. " " .. tostring(value)

    local timername = "change" .. convar

    if timer.Exists(timername) then
        timer.Remove(timername)
    end

    timer.Create(timername, 0.25, 1, function()
        net.Start("arccw_sendconvar")
        net.WriteString(command)
        net.SendToServer()
    end)
end

function ArcCW.GeneratePanelElements(panel, table)
    local AddControl = {
        ["h"] = function(p, d) return p:Help(d.text) end,
        ["c"] = function(p, d) return p:ControlHelp(d.text) end,
        ["b"] = function(p, d) return p:CheckBox(d.text, d.var) end,
        ["i"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 0) end,
        ["f"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 2) end,
        ["m"] = function(p, d) --return p:AddControl("color", { Label = d.text, Red = d.r, Green = d.g, Blue = d.b, Alpha = d.a })
            local ctrl = vgui.Create("DColorMixer", p)
            ctrl:SetLabel( d.text ) ctrl:SetConVarR( d.r ) ctrl:SetConVarG( d.g ) ctrl:SetConVarB( d.b ) ctrl:SetConVarA( d.a )
            p:AddItem( ctrl ) return ctrl
        end,
        ["p"] = function(p, d) local b = p:Button(d.text) b.DoClick = d.func return b end,
        ["t"] = function(p, d) return p:TextEntry(d.text, d.var) end,
        ["o"] = function(p, d) local cb = p:ComboBox(d.text, d.var) for k, v in pairs(d.choices) do cb:AddChoice(v, k) end return cb end,
        ["d"] = function(p, d)
                local s = vgui.Create("DSizeToContents", p) s:SetSizeX(false) s:Dock(TOP) s:InvalidateLayout()
                local l = vgui.Create("DLabel", s) l:SetText(d.text) l:SetTextColor(Color(0, 0, 0)) l:Dock(TOP) l:SetContentAlignment(5)
                local bd = vgui.Create("DBinder", s)
                if input.LookupBinding(d.var) then bd:SetValue(input.GetKeyCode(input.LookupBinding(d.var))) end
                bd.OnChange = function(b, k)
                    if k and input.GetKeyName(k) then
                        local str = input.LookupKeyBinding(k)
                        if str then
                            str = string.Replace(str, d.var .. "; ", "")
                            str = string.Replace(str, d.var, "")
                            chat.AddText(Color(255, 255, 255), language.GetPhrase("arccw.bind.msg"), Color(255, 128, 0), "bind " .. input.GetKeyName(k) .. " \"" .. str .. "; " .. d.var .. "\"")
                        else
                            chat.AddText(Color(255, 255, 255), language.GetPhrase("arccw.bind.msg"), Color(255, 128, 0), "bind " .. input.GetKeyName(k) .. " " .. d.var .. "")
                        end
                    end
                end
                bd:Dock(TOP) p:AddItem(s) return s end
    }

    local concommands = {
        ["b"] = true,
        ["i"] = true,
        ["f"] = true,
        ["m"] = true,
        ["t"] = true,
    }

    for _, data in SortedPairs(table) do
        local p = AddControl[data.type](panel, data)

        if concommands[data.type] and data.sv then
            p.TickCreated = UnPredictedCurTime()
            if data.type == "b" then
                p.OnChange = function(self, bval)
                    networktheconvar(data.var, bval, self)
                end
            elseif data.type == "i" or data.type == "f" or data.type == "m" or data.type == "t" then
                p.OnValueChanged = function(self, bval)
                    networktheconvar(data.var, bval, self)
                end
            end
        end
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

local ViewmodelPresets = {
    ["#preset.default"] = {
        arccw_vm_coolsway             = "1",
        arccw_vm_coolview             = "1",
        arccw_vm_sway_sprint          = "3",
        arccw_vm_bob_sprint           = "3",
        arccw_vm_right                = "0",
        arccw_vm_forward              = "0",
        arccw_vm_up                   = "0",
        arccw_vm_look_xmult            = "1",
        arccw_vm_look_ymult            = "1",
        arccw_vm_sway_xmult            = "1",
        arccw_vm_sway_ymult            = "1",
        arccw_vm_sway_zmult            = "1",
        arccw_vm_sway_speedmult        = "1",
        arccw_vm_sway_rotatemult       = "1",
        arccw_vm_coolview_mult        = "1",
    }
}

function ArcCW_Options_Bullet(panel)
    ArcCW.GeneratePanelElements(panel, BulletPanel)
end

function ArcCW_Options_Client(panel)
    ArcCW.GeneratePanelElements(panel, ClientPanel)
end

function ArcCW_Options_Perf(panel)
    ArcCW.GeneratePanelElements(panel, PerformancePanel)
end

function ArcCW_Options_Viewmodel(panel, no_preset)
    if !no_preset then
        panel:AddControl("ComboBox", {
            MenuButton = "1",
            Label      = "#Presets",
            Folder     = "arccw_vm",
            CVars      = { "" },
            Options    = ViewmodelPresets
        })
    end

    ArcCW.GeneratePanelElements(panel, ViewmodelPanel)
end

function ArcCW_Options_HUD(panel)
    ArcCW.GeneratePanelElements(panel, HudPanel)
end

function ArcCW_Options_Dev(panel)
    ArcCW.GeneratePanelElements(panel, DevPanel)
end

function ArcCW_Options_Crosshair(panel, no_preset)
    if !no_preset then
        panel:AddControl("ComboBox", {
            MenuButton = "1",
            Label      = "#Presets",
            Folder     = "arccw_crosshair",
            CVars      = { "" },
            Options    = CrosshairPresets
        })
    end
    ArcCW.GeneratePanelElements(panel, CrosshairPanel)
end

function ArcCW_Options_Server(panel)
    ArcCW.GeneratePanelElements(panel, ServerPanel)
end

function ArcCW_Options_Ammo(panel)
    ArcCW.GeneratePanelElements(panel, AmmoPanel)
end

function ArcCW_Options_Mults(panel, no_preset)
    if !no_preset then
        panel:AddControl("ComboBox", {
            MenuButton = "1",
            Label      = "#Presets",
            Folder     = "arccw_mults",
            CVars      = { "" },
            Options    = MultPresets
        })
    end
    ArcCW.GeneratePanelElements(panel, MultsPanel)
end

function ArcCW_Options_Atts(panel)
    ArcCW.GeneratePanelElements(panel, AttsPanel)
end

function ArcCW_Options_NPC(panel)
    ArcCW.GeneratePanelElements(panel, NPCsPanel)
end

function ArcCW_Options_Binds(panel)
    ArcCW.GeneratePanelElements(panel, BindsPanel)
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
    ["ArcCW_Options_Dev"]       = { text = "#arccw.menus.dev",   func = ArcCW_Options_Dev },
    ["ArcCW_Options_NPC"]       = { text = "#arccw.menus.npcs",   func = ArcCW_Options_NPC },
    ["ArcCW_Options_Binds"]    = { text = "#arccw.menus.binds", func = ArcCW_Options_Binds },
}

hook.Add("PopulateToolMenu", "ArcCW_Options", function()
    for menu, data in pairs(ArcCW.ClientMenus) do
        spawnmenu.AddToolMenuOption("Options", "ArcCW", menu, data.text, "", "", data.func)
    end
end)