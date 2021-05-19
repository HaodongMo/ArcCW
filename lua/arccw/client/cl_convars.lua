local NewConv = CreateClientConVar

--[[
    ClientConVars table doc:
    name = data:
    def  - default value
    desc - description of var
    min  - minimum value
    max  - maximum value
    usri - userinfo
]]

ArcCW.ClientConVars = {
    ["arccw_bullet_imaginary"]        = { def = 1 },

    ["arccw_crosshair"]               = { def = 1 },
    ["arccw_crosshair_clr_r"]         = { def = 255 },
    ["arccw_crosshair_clr_g"]         = { def = 255 },
    ["arccw_crosshair_clr_b"]         = { def = 255 },
    ["arccw_crosshair_clr_a"]         = { def = 255 },
    ["arccw_crosshair_length"]        = { def = 4 },
    ["arccw_crosshair_thickness"]     = { def = 1 },
    ["arccw_crosshair_gap"]           = { def = 1 },
    ["arccw_crosshair_static"]        = { def = 0 },
    ["arccw_crosshair_clump"]         = { def = 0 },
    ["arccw_crosshair_clump_outline"] = { def = 0 },
    ["arccw_crosshair_clump_always"]  = { def = 0 },
    ["arccw_crosshair_outline"]       = { def = 2 },
    ["arccw_crosshair_outline_r"]     = { def = 0 },
    ["arccw_crosshair_outline_g"]     = { def = 0 },
    ["arccw_crosshair_outline_b"]     = { def = 0 },
    ["arccw_crosshair_outline_a"]     = { def = 255 },
    ["arccw_crosshair_dot"]           = { def =  1 },
    ["arccw_crosshair_shotgun"]       = { def =  1 },
    ["arccw_crosshair_equip"]         = { def =  1 },
    ["arccw_crosshair_aa"]            = { def =  1 },
    ["arccw_crosshair_trueaim"]            = { def =  0 },

    ["arccw_attinv_simpleproscons"]   = { def =  0 },
    ["arccw_attinv_onlyinspect"]      = { def =  0 },
    ["arccw_attinv_hideunowned"]      = { def =  0 },
    ["arccw_attinv_darkunowned"]      = { def =  0 },
    ["arccw_attinv_closeonhurt"]      = { def =  0, usri = true },
    ["arccw_attinv_gamemodebuttons"]  = { def =  1 },

    ["arccw_language"]                = { def =  "", usri = true },
    ["arccw_font"]                    = { def =  "", usri = true },

    ["arccw_cheapscopes"]             = { def =  1 },
    ["arccw_cheapscopesautoconfig"]   = { def =  0 },

    --["arccw_flatscopes"]              = { def = 0 },

    ["arccw_shake"]                   = { def =  1 },
    ["arccw_muzzleeffects"]           = { def =  1 },
    ["arccw_shelleffects"]            = { def =  1 },
    ["arccw_shelltime"]               = { def =  0 },
    ["arccw_att_showothers"]          = { def =  1 },
    ["arccw_visibility"]              = { def =  8000 },
    ["arccw_fastmuzzles"]             = { def =  0 },
    ["arccw_fasttracers"]             = { def =  0 },

    ["arccw_2d3d"]                    = { def =  1 },

    ["arccw_hud_3dfun"]               = { def =  0, usri = true },
    ["arccw_hud_3dfun_lite"]          = { def =  0 },
    ["arccw_hud_3dfun_ammotype"]      = { def =  0 },
    ["arccw_hud_forceshow"]           = { def =  0 },
    ["arccw_hud_fcgbars"]             = { def =  1, desc = "Draw firemode bars on ammo HUD." },
    ["arccw_hud_minimal"]             = { def =  1, desc = "Backup HUD if we cannot draw the ammo HUD." },
    ["arccw_hud_embracetradition"]    = { def =  0, desc = "Use the classic customization HUD." },
    ["arccw_hud_deadzone_x"]          = { def =  0 },
    ["arccw_hud_deadzone_y"]          = { def =  0 },
    ["arccw_hud_3dfun_decaytime"]     = { def =  3 },
    ["arccw_hud_3dfun_right"]         = { def =  2 },
    ["arccw_hud_3dfun_up"]            = { def =  1 },
    ["arccw_hud_3dfun_forward"]       = { def =  0 },
    ["arccw_hud_size"]                = { def =  1 },

    ["arccw_cust_sounds"]             = { def =  1, desc = "Play sounds when opening and closing the customization menu." },

    ["arccw_scope_r"]                 = { def =  255 },
    ["arccw_scope_g"]                 = { def =  0 },
    ["arccw_scope_b"]                 = { def =  0 },

    ["arccw_blur"]                    = { def =  0 },
    ["arccw_blur_toytown"]            = { def =  1 },

    ["arccw_adjustsensthreshold"]     = { def =  0 },

    ["arccw_glare"]                   = { def =  1 },
    ["arccw_autosave"]                = { def =  1 },

    ["arccw_vm_right"]                = { def =  0 },
    ["arccw_vm_up"]                   = { def =  0 },
    ["arccw_vm_forward"]              = { def =  0 },
    ["arccw_vm_fov"]                  = { def =  0, usri = true },
    ["arccw_vm_sway_sprint"]          = { def =  3 },
    ["arccw_vm_bob_sprint"]           = { def =  3 },
    ["arccw_vm_coolsway"]             = { def =  1 },
    ["arccw_vm_coolview"]             = { def =  1 },
    ["arccw_vm_coolview_mult"]        = { def =  1 },
    ["arccw_vm_look_xmult"]           = { def =  1 },
    ["arccw_vm_look_ymult"]           = { def =  1 },
    ["arccw_vm_sway_xmult"]           = { def =  1 },
    ["arccw_vm_sway_ymult"]           = { def =  1 },
    ["arccw_vm_sway_zmult"]           = { def =  1 },

    ["arccw_vm_sway_speedmult"]       = { def =  1 },
    ["arccw_vm_sway_rotatemult"]      = { def =  1 },

    ["arccw_toggleads"]               = { def = 0, usri = true },
    ["arccw_altubglkey"]              = { def = 0, usri = true },
    ["arccw_altfcgkey"]               = { def = 0, usri = true },
    ["arccw_altlaserkey"]             = { def = 0, usri = true },
    ["arccw_altbindsonly"]            = { def = 0, usri = true },
    ["arccw_altsafety"]               = { def = 0, usri = true },
    ["arccw_automaticreload"]         = { def = 0, usri = true },

    ["arccw_aimassist_cl"]            = { def = 0, usri = true },

    ["arccw_dev_removeonclose"]       = { def = 0, desc = "Remove the hud when closing instead of fading out, allowing easy reloading of the hud." },
}

for name, data in pairs(ArcCW.ClientConVars) do
    NewConv(name, data.def, true, data.usri or false, data.desc, data.min, data.max)
end

-- CreateClientConVar("arccw_quicknade", KEY_G)