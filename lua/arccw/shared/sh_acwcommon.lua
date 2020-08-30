ArcCW.EnableCustomization = true
ArcCW.PresetPath          = "arccw_presets/"

ArcCW.NoDraw = true

ArcCW.HUToM    = 0.0254 -- 1 / 12 * 0.3048
ArcCW.MOAToAcc = 0.00092592592 -- 10 / 180 / 60

ArcCW.STATE_IDLE      = 0
ArcCW.STATE_SIGHTS    = 1
ArcCW.STATE_SPRINT    = 2
ArcCW.STATE_DISABLE   = 3
ArcCW.STATE_CUSTOMIZE = 4
ArcCW.STATE_BIPOD     = 5

ArcCW.SCROLL_NONE = 0
ArcCW.SCROLL_ZOOM = 1

ArcCW.ShellSoundsTable = {
    "player/pl_shell1.wav",
    "player/pl_shell2.wav",
    "player/pl_shell3.wav"
}

ArcCW.ShotgunShellSoundsTable = {
    "weapons/fx/tink/shotgun_shell1.wav",
    "weapons/fx/tink/shotgun_shell2.wav",
    "weapons/fx/tink/shotgun_shell3.wav"
}

ArcCW.ReloadTimeTable = {
    [ACT_HL2MP_GESTURE_RELOAD_AR2]      = 2,
    [ACT_HL2MP_GESTURE_RELOAD_SMG1]     = 2,
    [ACT_HL2MP_GESTURE_RELOAD_PISTOL]   = 1.5,
    [ACT_HL2MP_GESTURE_RELOAD_REVOLVER] = 2.5,
    [ACT_HL2MP_GESTURE_RELOAD_SHOTGUN]  = 2.5,
    [ACT_HL2MP_GESTURE_RELOAD_DUEL]     = 3.25,
}

ArcCW.ReplaceWeapons = {
    ["weapon_pistol"]    = true,
    ["weapon_smg1"]      = true,
    ["weapon_ar2"]       = true,
    ["weapon_shotgun"]   = true,
    ["weapon_357"]       = true,
    ["weapon_alyxgun"]   = true,
    ["weapon_crossbow"]  = true,
    ["weapon_rpg"]       = true,
    ["weapon_annabelle"] = true,
}

ArcCW.PenTable = {
   [MAT_ANTLION]     = 1,
   [MAT_BLOODYFLESH] = 1,
   [MAT_CONCRETE]    = 0.75,
   [MAT_DIRT]        = 0.5,
   [MAT_EGGSHELL]    = 1,
   [MAT_FLESH]       = 0.25,
   [MAT_GRATE]       = 1,
   [MAT_ALIENFLESH]  = 0.25,
   [MAT_CLIP]        = 1000,
   [MAT_SNOW]        = 0.25,
   [MAT_PLASTIC]     = 0.5,
   [MAT_METAL]       = 2,
   [MAT_SAND]        = 0.25,
   [MAT_FOLIAGE]     = 0.5,
   [MAT_COMPUTER]    = 0.25,
   [MAT_SLOSH]       = 1,
   [MAT_TILE]        = 0.5,
   [MAT_GRASS]       = 0.5,
   [MAT_VENT]        = 0.75,
   [MAT_WOOD]        = 0.5,
   [MAT_DEFAULT]     = 0.75,
   [MAT_GLASS]       = 0.1,
   [MAT_WARPSHIELD]  = 1
}

ArcCW.Colors = {
    POS     = Color(25, 225, 25),
    MINIPOS = Color(75, 225, 75),
    NEU     = Color(225, 225, 225),
    MININEG = Color(225, 75, 75),
    NEG     = Color(225, 25, 25),
    COSM    = Color(100, 100, 225)
}

ArcCW.LHIKBones = {
    "ValveBiped.Bip01_L_UpperArm",
    "ValveBiped.Bip01_L_Forearm",
    "ValveBiped.Bip01_L_Wrist",
    "ValveBiped.Bip01_L_Ulna",
    "ValveBiped.Bip01_L_Hand",
    "ValveBiped.Bip01_L_Finger4",
    "ValveBiped.Bip01_L_Finger41",
    "ValveBiped.Bip01_L_Finger42",
    "ValveBiped.Bip01_L_Finger3",
    "ValveBiped.Bip01_L_Finger31",
    "ValveBiped.Bip01_L_Finger32",
    "ValveBiped.Bip01_L_Finger2",
    "ValveBiped.Bip01_L_Finger21",
    "ValveBiped.Bip01_L_Finger22",
    "ValveBiped.Bip01_L_Finger1",
    "ValveBiped.Bip01_L_Finger11",
    "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger0",
    "ValveBiped.Bip01_L_Finger01",
    "ValveBiped.Bip01_L_Finger02",
    "ValveBiped.Bip01_L_Wrist",
    "ValveBiped.Bip01_L_Ulna"
}