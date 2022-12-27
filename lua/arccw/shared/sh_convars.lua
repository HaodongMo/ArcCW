CreateConVar("arccw_enable_penetration", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 1)
CreateConVar("arccw_enable_ricochet", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 1)
CreateConVar("arccw_enable_customization", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", -1, 1)
CreateConVar("arccw_enable_dropping", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 1)
CreateConVar("arccw_enable_sway", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 1)

CreateConVar("arccw_bodydamagemult_cancel", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 1)

CreateConVar("arccw_attinv_lockmode", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Once owned, players can use attachments as much as they like.")
CreateConVar("arccw_attinv_free", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "All attachments can always be used.")
CreateConVar("arccw_attinv_loseondie", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "All attachments reset on death. If set to 2, drops all attachments in a box.", 0, 2)

CreateConVar("arccw_atts_spawnrand", 0, FCVAR_ARCHIVE, "Randomly give attachments to player spawned SWEPs.", 0, 1)
CreateConVar("arccw_atts_ubglautoload", 0, FCVAR_ARCHIVE, "Automatically load underbarrel weapons when attached.", 0, 1)
CreateConVar("arccw_atts_pickx", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit weapons to this many maximum attachments. 0 = disable system.", 0)

CreateConVar("arccw_npc_replace", 0, FCVAR_ARCHIVE, "Replace NPC weapons with ArcCW weapons.")
CreateConVar("arccw_npc_atts", 1, FCVAR_ARCHIVE, "Randomly give NPC weapons attachments.")

CreateConVar("arccw_truenames", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use true names instead of fake names, where applicable. Requires restart.")

CreateConVar("arccw_equipmentammo", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Generate unique ammo types for throwables.", 0, 1) -- Automatically assign unique ammo types to each throwable weapon. Prone to running into the ammo type limit.
CreateConVar("arccw_equipmentsingleton", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Make grenades and equipment not use ammo, and remove themselves on use.", 0, 1)
CreateConVar("arccw_equipmenttime", 180, FCVAR_ARCHIVE, "How long equipment such as Claymores will remain on the map before self-destructing.")

CreateConVar("arccw_mult_damage", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for damage done by all weapons.")
CreateConVar("arccw_mult_npcdamage", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for damage done by weapons used by NPCs.")
CreateConVar("arccw_mult_hipfire", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for hip fire spread.")
CreateConVar("arccw_mult_reloadtime", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how long weapons take to reload.", 0.01)
CreateConVar("arccw_mult_sighttime", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how long weapons take to enter sights.", 0.1)
CreateConVar("arccw_mult_rpm", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how fast weapons fire. May be disastrous on performance.", 0.01)
CreateConVar("arccw_mult_range", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for range of all weapons.")
CreateConVar("arccw_mult_recoil", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for recoil of all weapons.")
CreateConVar("arccw_mult_accuracy", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for mechanical inprecision of weapons.")
CreateConVar("arccw_mult_movedisp", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for moving inaccuracy of weapons.")
CreateConVar("arccw_mult_penetration", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how far weapons should penetrate.")
CreateConVar("arccw_mult_startunloaded", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "All weapons spawn unloaded.")
CreateConVar("arccw_mult_shootwhilesprinting", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Allow any weapon to shoot while sprinting.")
CreateConVar("arccw_mult_defaultammo", 3, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for default ammo supply.")
CreateConVar("arccw_mult_attchance", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for random attachment chance on NPCs and in TTT.")
CreateConVar("arccw_mult_heat", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much heat increases per shot on certain weapons.", 0)
CreateConVar("arccw_mult_sway", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much sway exists when in sights.", 0)
CreateConVar("arccw_mult_malfunction", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how often malfunctions occur.", 0)
CreateConVar("arccw_mult_meleedamage", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for melee damage.", 0)
CreateConVar("arccw_mult_meleetime", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for melee speed.", 0)

CreateConVar("arccw_add_sway", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Add this much sway to all weapons.", 0)

CreateConVar("arccw_mult_bottomlessclip", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable bottomless clip.", 0, 1)
CreateConVar("arccw_mult_infiniteammo", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable infinite reserve ammo.", 0, 1)

CreateConVar("arccw_mult_crouchdisp", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for hip dispersion while crouching.", 0)
CreateConVar("arccw_mult_crouchrecoil", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for recoil while crouching.", 0)

CreateConVar("arccw_mult_movespeed", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much weapons should affect your regular movespeed.", 0)
CreateConVar("arccw_mult_movespeedads", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much weapons should affect your movespeed while aiming down sights.", 0)
CreateConVar("arccw_mult_movespeedfire", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much weapons should affect your movespeed while firing them.", 0)

CreateConVar("arccw_override_crosshair_off", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Set to true to force everyone's crosshairs off.", 0, 1)
CreateConVar("arccw_override_hud_off", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Set to true to force everyone's HUDs off.", 0, 1)
CreateConVar("arccw_override_nearwall", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Disable weapon length and near-walling.", 0, 1)
CreateConVar("arccw_override_lunge_off", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Disable melee lunging.", 0, 1)


CreateConVar("arccw_ammo_detonationmode", 2, FCVAR_REPLICATED, "The type of ammo detonation to use. -1 = don't explode, 0 = simple explosion, 1 = fragmentation, 2 = full", -1, 2)
CreateConVar("arccw_ammo_autopickup", 1, FCVAR_REPLICATED, "Whether to pick up ammo when walking over in addition to pressing Use.", 0, 1)
CreateConVar("arccw_ammo_largetrigger", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to use larger trigger boxes for ammo, similar to HL2. Only useful when autopickup is true.", 0, 1)
CreateConVar("arccw_ammo_rareskin", 0.08, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Chance for a rare skin to appear. Only specific models have these.", 0, 1)
CreateConVar("arccw_ammo_chaindet", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to allow ammoboxes to detonate each other. If disabled, they will still be destroyed but !explode.", 0, 1)
CreateConVar("arccw_ammo_replace", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "If enabled, all vanilla ammo entities will be forcefully replaced with ArcCW equivalents.", 0, 1)

CreateConVar("arccw_mult_ammohealth", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much health ammo boxes have. Set to -1 for indestructible boxes.", -1)
CreateConVar("arccw_mult_ammoamount", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much ammo are in ammo boxes.", 0)

CreateConVar("arccw_limityear_enable", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit the maximum year for weapons.")
CreateConVar("arccw_limityear", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit the maximum year for weapons.")

CreateConVar("arccw_doorbust", 0, FCVAR_ARCHIVE, "Whether to allow door busting. 1 - break down, 2 - open only", 0, 2)
CreateConVar("arccw_doorbust_threshold", 80, FCVAR_ARCHIVE, "The amount of damage needed to bust a normal sized door.")
CreateConVar("arccw_doorbust_time", 180, FCVAR_ARCHIVE, "The amount of time to keep the door busted by.", 1)

CreateConVar("arccw_driveby", 0, FCVAR_ARCHIVE, "Enable special checks that allow you to fire out of vehicles (assuming some vehicle weaponizer addon exists).", 0, 1)

CreateConVar("arccw_clicktocycle", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to make it so left clicking after shooting cycles instead of on mouse release.")
CreateConVar("arccw_throwinertia", 1, FCVAR_ARCHIVE, "Set to make throwable equipment inherit the player's velocity.", 0, 1)

CreateConVar("arccw_bullet_enable", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use physical bullets with drop and travel time.")
CreateConVar("arccw_bullet_velocity", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("arccw_bullet_drag", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("arccw_bullet_lifetime", 10, FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar("arccw_bullet_gravity", 600, FCVAR_ARCHIVE + FCVAR_REPLICATED)

CreateConVar("arccw_weakensounds", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Reduce all weapons' firing volume by this much decibels, making it easier to hide shooting sounds. Clamped to 60-150dB.")

CreateConVar("arccw_desync", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Turning this on prevents cheaters from predicting the bullet direction/spread, making the nospread cheat useless.")

CreateConVar("arccw_aimassist", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable A I M B O T", 0, 1)
CreateConVar("arccw_aimassist_head", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "My advice for you: aim for the head!", 0, 1)
CreateConVar("arccw_aimassist_cone", 5, FCVAR_ARCHIVE + FCVAR_REPLICATED, "The angle of the cone within which targets can be seeked.", 1, 360)
CreateConVar("arccw_aimassist_distance", 1024, FCVAR_ARCHIVE + FCVAR_REPLICATED, "The distance within which aim assist will trigger.", 128)
CreateConVar("arccw_aimassist_intensity", 0.5, FCVAR_ARCHIVE + FCVAR_REPLICATED, "How strong the assist is.", 0, 10)

CreateConVar("arccw_malfunction", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 2)

CreateConVar("arccw_attinv_giveonspawn", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Give this many random attachments to players on spawn.", 0)

CreateConVar("arccw_reloadincust", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Allow players to reload when customizing.", 0, 1)
CreateConVar("arccw_freeaim", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "", 0, 2)

-- developer stuff
CreateConVar("arccw_reloadatts_mapcleanup", 0, 0, "Whether to reload ArcCW attachments on admin clean up.")
CreateConVar("arccw_reloadatts_registerentities", 1, 0, "Register attachment entities. This may increase time to reload attachments.")
CreateConVar("arccw_reloadatts_showignored", 0, 0, "Whether to include attachments set to Ignore.")
CreateConVar("arccw_dev_debug", 0, 0, "Developer debug HUD showing cool time shit.", 0, 1)
CreateConVar("arccw_dev_shootinfo", 0, 0, "Show debug overlay firing information. Only works when developer is set to 1.", 0, 3)
CreateConVar("arccw_dev_alwaysready", 0, 0, "Always draw using the ready animation.", 0, 1)
--CreateConVar("arccw_dev_cust2beta", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use the new beta customize hud.", 0, 1)