CreateConVar("arccw_enable_penetration", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "")
CreateConVar("arccw_enable_customization", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "")
CreateConVar("arccw_enable_dropping", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "")

CreateConVar("arccw_attinv_lockmode", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Once owned, players can use attachments as much as they like.")
CreateConVar("arccw_attinv_free", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "All attachments can always be used.")
CreateConVar("arccw_attinv_loseondie", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "All attachments reset on death. If set to 2, drops all attachments in a box.", 0, 2)

CreateConVar("arccw_atts_spawnrand", 0, FCVAR_ARCHIVE, "Randomly give attachments to player spawned SWEPs.", 0, 1)
CreateConVar("arccw_atts_ubglautoload", 0, FCVAR_ARCHIVE, "Automatically load underbarrel weapons when attached.", 0, 1)
CreateConVar("arccw_atts_pickx", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit weapons to this many maximum attachments. 0 = disable system.", 0)

CreateConVar("arccw_npc_replace", 0, FCVAR_ARCHIVE, "Replace NPC weapons with ArcCW weapons.")
CreateConVar("arccw_npc_atts", 1, FCVAR_ARCHIVE, "Randomly give NPC weapons attachments.")

CreateConVar("arccw_truenames", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Use true names instead of fake names, where applicable. Requires restart.")

CreateConVar("arccw_equipmentammo", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Automatically assign unique ammo types to each throwable weapon. Prone to running into the ammo type limit.", 0, 1)
CreateConVar("arccw_equipmentsingleton", 0, FCVAR_ARCHIVE, "Make grenades and equipment not use ammo, and remove themselves on use.", 0, 1)
CreateConVar("arccw_equipmenttime", 180, FCVAR_ARCHIVE, "How long equipment such as Claymores will remain on the map before self-destructing.")

CreateConVar("arccw_mult_damage", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for damage done by all ArcCW weapons.")
CreateConVar("arccw_mult_npcdamage", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for damage done by all ArcCW weapons used by NPCs.")
CreateConVar("arccw_mult_hipfire", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for hip fire spread for ArcCW.")
CreateConVar("arccw_mult_reloadtime", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how long ArcCW weapons take to reload.", 0.01)
CreateConVar("arccw_mult_sighttime", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how long ArcCW weapons take to enter sights.", 0.1)
CreateConVar("arccw_mult_range", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for range of all ArcCW weapons.")
CreateConVar("arccw_mult_recoil", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for recoil of all ArcCW weapons.")
CreateConVar("arccw_mult_movedisp", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for moving inaccuracy of ArcCW weapons.")
CreateConVar("arccw_mult_penetration", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for ArcCW penetration amount.")
CreateConVar("arccw_mult_defaultclip", -1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for default clip size. Set to -1 for default.")
CreateConVar("arccw_mult_attchance", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for random attachment chance on NPCs and in TTT.")

CreateConVar("arccw_reloadonrefresh", 1, FCVAR_ARCHIVE, "Whether to reload ArcCW attachments on admin clean up.")

CreateConVar("arccw_override_crosshair_off", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Set to true to force everyone's crosshairs off.", 0, 1)
CreateConVar("arccw_override_deploychambered", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Draw the weapon with a round in chamber.", 0, 1)

CreateConVar("arccw_ammo_detonationmode", 2, FCVAR_ARCHIVE + FCVAR_REPLICATED, "The type of ammo detonation to use. -1 = don't explode, 0 = simple explosion, 1 = fragmentation, 2 = full", -1, 2)
CreateConVar("arccw_ammo_autopickup", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to pick up ammo when walking over in addition to pressing Use.", 0, 1)
CreateConVar("arccw_ammo_largetrigger", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to use larger trigger boxes for ammo, similar to HL2. Only useful when autopickup is true.", 0, 1)
CreateConVar("arccw_ammo_rareskin", 0.08, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Chance for a rare skin to appear. Only specific models have these.", 0, 1)
CreateConVar("arccw_ammo_chaindet", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to allow ammoboxes to detonate each other. If disabled, they will still be destroyed but not explode.", 0, 1)

CreateConVar("arccw_mult_ammohealth", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much health ammo boxes have. Set to -1 for indestructible boxes.", -1)
CreateConVar("arccw_mult_ammoamount", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Multiplier for how much ammo are in ammo boxes.", 0)

CreateConVar("arccw_limityear_enable", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit the maximum year for weapons.")
CreateConVar("arccw_limityear", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Limit the maximum year for weapons.")

CreateConVar("arccw_doorbust", 1, FCVAR_ARCHIVE, "Whether to allow door busting. 1 - break down, 2 - open only", 0, 2)
CreateConVar("arccw_doorbust_threshold", 80, FCVAR_ARCHIVE, "The amount of damage needed to bust a normal sized door.")
CreateConVar("arccw_doorbust_time", 180, FCVAR_ARCHIVE, "The amount of time to keep the door busted by.", 1)

CreateConVar("arccw_holstering", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Take time to holster your weapon.")
CreateConVar("arccw_clicktocycle", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Whether to make it so left clicking after shooting cycles instead of on mouse release.")
CreateConVar("arccw_throwinertia", 1, FCVAR_ARCHIVE, "Set to make throwable equipment inherit the player's velocity.", 0, 1)
