hook.Add( "PopulateToolMenu", "ArcCW_Options", function()
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_HUD", "HUD", "", "", ArcCW_Options_HUD)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Client", "Client", "", "", ArcCW_Options_Client)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Server", "Server", "", "", ArcCW_Options_Server)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Mults", "Multipliers", "", "", ArcCW_Options_Mults)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_NPC", "NPCs", "", "", ArcCW_Options_NPC)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Atts", "Attachments", "", "", ArcCW_Options_Atts)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Ammo", "Ammo", "", "", ArcCW_Options_Ammo)
    spawnmenu.AddToolMenuOption( "Options", "ArcCW", "ArcCW_Options_Crosshair", "Crosshair", "", "", ArcCW_Options_Crosshair)
end )

function ArcCW_Options_Ammo( CPanel )
    CPanel:AddControl("Header", {Description = "These options require admin privileges to change."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "-1 = don't explode, 0 = simple explosion, 1 = fragmentation, 2 = full"})
    CPanel:AddControl("Slider", {Label = "Ammo Detonation Mode", Command = "arccw_ammo_detonationmode", Min = -1, Max = 2, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "Auto Pickup", Command = "arccw_ammo_autopickup" })
    CPanel:AddControl("Checkbox", {Label = "Large Pickup Trigger", Command = "arccw_ammo_largetrigger" })
    CPanel:AddControl("Slider", {Label = "Rare Skin Chance", Command = "arccw_ammo_rareskin", Min = 0, Max = 1, Type = "float" })
    CPanel:AddControl("Checkbox", {Label = "Chain Detonation", Command = "arccw_ammo_chaindet" })
    CPanel:AddControl("Slider", {Label = "Ammo Health (-1 for indestructible)", Command = "arccw_mult_ammohealth", Min = -1, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Ammo Amount", Command = "arccw_mult_ammoamount", Min = 0.1, Max = 10, Type = "float" })
end

function ArcCW_Options_HUD( CPanel )
    CPanel:AddControl("Header", {Description = "All options in this menu can be customized by players, and do not need admin privileges."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "3D Alt HUD", Command = "arccw_hud_3dfun" })
    CPanel:AddControl("Checkbox", {Label = "Show Health", Command = "arccw_hud_showhealth" })
    CPanel:AddControl("Checkbox", {Label = "Show Ammo", Command = "arccw_hud_showammo" })
    CPanel:AddControl("Checkbox", {Label = "Hide Unowned Attachments", Command = "arccw_attinv_hideunowned" })
    CPanel:AddControl("Checkbox", {Label = "Grey Out Unowned Attachments", Command = "arccw_attinv_darkunowned" })
    CPanel:AddControl("Checkbox", {Label = "Hide Customization UI", Command = "arccw_attinv_onlyinspect" })
    CPanel:AddControl("Checkbox", {Label = "Simple Pros And Cons", Command = "arccw_attinv_simpleproscons" })
    CPanel:AddControl("Checkbox", {Label = "Close menu on damage taken", Command = "arccw_attinv_closeonhurt" })
end

function ArcCW_Options_Client( CPanel )
    CPanel:AddControl("Header", {Description = "All options in this menu can be customized by players, and do not need admin privileges."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Toggle Aim", Command = "arccw_toggleads" })
    CPanel:AddControl("Checkbox", {Label = "E+RMB To Toggle UBGL", Command = "arccw_altubglkey" })
    CPanel:AddControl("Checkbox", {Label = "Weapon Autosave", Command = "arccw_autosave" })
    CPanel:AddControl("Header", {Description = "Attempt to re-equip the last equipped set of attachments."})
    CPanel:AddControl("Checkbox", {Label = "Cheap Scopes", Command = "arccw_cheapscopes" })
    CPanel:AddControl("Header", {Description = "A cheaper PIP scope implementation that is very low quality but saves a significant amount of performance. Can be a little glitchy."})
    CPanel:AddControl("Checkbox", {Label = "Scope Glare", Command = "arccw_glare" })
    CPanel:AddControl("Header", {Description = "Glare visible on your scope lens when aiming."})
    CPanel:AddControl("Checkbox", {Label = "Customization Blur", Command = "arccw_blur" })
    CPanel:AddControl("Checkbox", {Label = "Screen Shake", Command = "arccw_shake" })
    CPanel:AddControl("Checkbox", {Label = "Floating Help Text", Command = "arccw_2d3d" })
    CPanel:AddControl("Checkbox", {Label = "Muzzle Effects (Others Only)", Command = "arccw_muzzleeffects" })
    CPanel:AddControl("Checkbox", {Label = "Case Effects (Others Only)", Command = "arccw_shelleffects" })
    CPanel:AddControl("Checkbox", {Label = "Show World Attachments (Others Only)", Command = "arccw_att_showothers" })
    CPanel:AddControl("Slider", {Label = "Viewmodel Right", Command = "arccw_vm_right", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Viewmodel Forward", Command = "arccw_vm_forward", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Viewmodel Up", Command = "arccw_vm_up", Min = -5, Max = 5, Type = "float" })
    CPanel:AddControl("Header", {Description = "  Warning! Viewmodel offset settings may cause clipping or other undesired effects!"})
end

function ArcCW_Options_Crosshair( CPanel )
    CPanel:AddControl("Header", {Description = "All options in this menu can be customized by players, and do not need admin privileges."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Show Crosshair", Command = "arccw_crosshair" })
    CPanel:AddControl("Slider", {Label = "Crosshair Length", Command = "arccw_crosshair_length", Min = 0, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Crosshair Thickness", Command = "arccw_crosshair_thickness", Min = 0, Max = 4, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Crosshair Gap Scale", Command = "arccw_crosshair_gap", Min = 0, Max = 2, Type = "float" })
    CPanel:AddControl("Checkbox", {Label = "Show Center Dot", Command = "arccw_crosshair_dot" })
    CPanel:AddControl("Checkbox", {Label = "Use Shotgun Prongs", Command = "arccw_crosshair_shotgun" })
    CPanel:AddControl("Checkbox", {Label = "Show Equipment Prongs", Command = "arccw_crosshair_equip" })
    CPanel:AddControl("color", {Label = "Crosshair Color",
        Red = "arccw_crosshair_clr_r",
        Green = "arccw_crosshair_clr_g",
        Blue = "arccw_crosshair_clr_b",
        Alpha = "arccw_crosshair_clr_a"
    })

    CPanel:AddControl("Slider", {Label = "Outline Size", Command = "arccw_crosshair_outline", Min = 0, Max = 4, Type = "float" })
    CPanel:AddControl("color", {Label = "Outline Color",
        Red = "arccw_crosshair_outline_r",
        Green = "arccw_crosshair_outline_g",
        Blue = "arccw_crosshair_outline_b",
        Alpha = "arccw_crosshair_outline_a"
    })

    CPanel:AddControl("color", {Label = "Sight Color",
        Red = "arccw_scope_r",
        Green = "arccw_scope_g",
        Blue = "arccw_scope_b",
    })
end

function ArcCW_Options_Mults( CPanel )
    CPanel:AddControl("Header", {Description = "These options require admin privileges to change."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Slider", {Label = "Damage", Command = "arccw_mult_damage", Min = 0, Max = 20, Type = "float" })
    CPanel:AddControl("Slider", {Label = "NPC Damage", Command = "arccw_mult_npcdamage", Min = 0, Max = 20, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Range", Command = "arccw_mult_range", Min = 0.01, Max = 20, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Recoil", Command = "arccw_mult_recoil", Min = 0, Max = 100, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Penetration", Command = "arccw_mult_penetration", Min = 0, Max = 25, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Hip Dispersion", Command = "arccw_mult_hipfire", Min = 0, Max = 100, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Move Dispersion", Command = "arccw_mult_movedisp", Min = 0, Max = 100, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Reload Time", Command = "arccw_mult_reloadtime", Min = 0.01, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "ADS Time", Command = "arccw_mult_sighttime", Min = 0.1, Max = 10, Type = "float" })
    CPanel:AddControl("Slider", {Label = "Default Clip", Command = "arccw_mult_defaultclip", Min = -1, Max = 10})
    CPanel:AddControl("Slider", {Label = "Random Att. Chance", Command = "arccw_mult_attchance", Min = 0, Max = 10, Type = "float"})
end

function ArcCW_Options_NPC( CPanel )
    CPanel:AddControl("Header", {Description = "These options require admin privileges to change."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Replace NPC Weapons", Command = "arccw_npc_replace" })
    CPanel:AddControl("Checkbox", {Label = "NPC Attachments", Command = "arccw_npc_atts" })
end

function ArcCW_Options_Atts( CPanel )
    CPanel:AddControl("Header", {Description = "These options require admin privileges to change."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "ArcCW supports attachment inventory style behaviour (Like ACT3) as well as attachment locking style behaviour (Like CW2.0) as well as giving everyone all attachments for free (Like TFA Base)."})
    CPanel:AddControl("Header", {Description = "Leave all options off for ACT3 style attachment inventory behaviour."})
    CPanel:AddControl("Checkbox", {Label = "Free Attachments", Command = "arccw_attinv_free" })
    CPanel:AddControl("Checkbox", {Label = "Attachment Locking", Command = "arccw_attinv_lockmode" })
    CPanel:AddControl("Header", {Description = "Lose Attachments Mode: 0 = Disable; 1 = Removed on death, 2 = Drop Attachment Box on death"})
    CPanel:AddControl("Slider", {Label = "Lose Attachments Mode", Command = "arccw_attinv_loseondie", Min = 0, Max = 2, Type = "int" })
    CPanel:AddControl("Header", {Description = "Pick X behaviour allows you to set a limit on attachments that can be placed on any weapon. 0 = unlimited."})
    CPanel:AddControl("Slider", {Label = "Pick X", Command = "arccw_atts_pickx", Min = 0, Max = 15, Type = "int" })
    CPanel:AddControl("Checkbox", {Label = "Attachment Dropping", Command = "arccw_enable_dropping" })
    CPanel:AddControl("Checkbox", {Label = "Random Attachments on Spawn", Command = "arccw_atts_spawnrand" })
end

function ArcCW_Options_Server( CPanel )
    CPanel:AddControl("Header", {Description = "These options require admin privileges to change."})
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Enable Penetration", Command = "arccw_enable_penetration" })
    CPanel:AddControl("Checkbox", {Label = "Enable Customization", Command = "arccw_enable_customization" })
    CPanel:AddControl("Checkbox", {Label = "True Names (Requires Restart)", Command = "arccw_truenames" })
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Header", {Description = "There is a limit of 127 ammo types, and enabling this option can cause problems related to this. Requires restart."})
    CPanel:AddControl("Checkbox", {Label = "Equipment Unique Ammo Types", Command = "arccw_equipmentammo" })
    CPanel:AddControl("Header", {Description = "Singletons can be used once and then remove themselves from your inventory. Requires restart."})
    CPanel:AddControl("Checkbox", {Label = "Grenade/Equipment Singleton", Command = "arccw_equipmentsingleton" })
    CPanel:AddControl("Slider", {Label = "Equipment Self-Destruct Time", Command = "arccw_equipmenttime", Min = 15, Max = 3600, Type = "int" })
    CPanel:AddControl("Header", {Description = ""})
    CPanel:AddControl("Checkbox", {Label = "Enable Year Limit", Command = "arccw_limityear_enable" })
    CPanel:AddControl("Slider", {Label = "Year Limit", Command = "arccw_limityear", Min = 1800, Max = 2100, Type = "int" })
end