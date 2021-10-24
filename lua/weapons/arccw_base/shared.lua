AddCSLuaFile()

-- For those who may find it useful...
-- use WEAPONENTITY:SetNWBool("ArcCW_DisableAutosave", true) to tell the client to not load their autosaves.

SWEP.Spawnable = false -- this obviously has to be set to true
SWEP.AutoSpawnable = nil -- TTT weapon autospawn. ArcCW weapons automatically spawn in TTT as long as SWEP.Spawnable is set to true
SWEP.Category = "ArcCW - Firearms" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "ArcCW Base"
SWEP.Trivia_Class = nil -- "Submachine Gun"
SWEP.Trivia_Desc = nil -- "Ubiquitous 9mm SMG. Created as a response to the need for a faster-firing and more reliable submachine gun than existing options at the time."
SWEP.Trivia_Manufacturer = nil -- "Auschen Waffenfabrik"
SWEP.Trivia_Calibre = nil -- "9x21mm Jager"
SWEP.Trivia_Mechanism = nil -- "Roller-Delayed Blowback"
SWEP.Trivia_Country = nil -- "Austria"
SWEP.Trivia_Year = nil -- 1968

SWEP.UseHands = true

SWEP.ViewModel = "" -- I mean, you probably have to edit these too
SWEP.WorldModel = ""

SWEP.MirrorVMWM = nil -- Copy the viewmodel, along with all its attachments, to the worldmodel. Super convenient!
SWEP.MirrorWorldModel = nil -- Use this to set the mirrored viewmodel to a different model, without any floating speedloaders or cartridges you may have. Needs MirrorVMWM

--[[SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}]]

SWEP.PresetBase = nil -- make this weapon share saves with this one.

SWEP.KillIconAlias = nil -- set to other weapon class to share select and kill icons

SWEP.DefaultBodygroups = "00000000"
SWEP.DefaultWMBodygroups = "00000000"
SWEP.DefaultSkin = 0
SWEP.DefaultWMSkin = 0

SWEP.WorldModelOffset = nil
-- {
--     pos = Vector(0, 0, 0),
--     ang = Angle(0, 0, 0)
-- }

SWEP.NoHideLeftHandInCustomization = false

SWEP.Damage = 26
SWEP.DamageMin = 10 -- damage done at maximum range
SWEP.DamageRand = 0 -- damage will vary randomly each shot by this fraction
SWEP.RangeMin = 0 -- how far bullets will retain their maximum damage for
SWEP.Range = 200 -- in METRES
SWEP.Penetration = 4
SWEP.DamageType = DMG_BULLET
SWEP.DamageTypeHandled = false -- set to true to have the base not do anything with damage types
-- this includes: igniting if type has DMG_BURN; adding DMG_AIRBOAT when hitting helicopter; adding DMG_BULLET to DMG_BUCKSHOT

SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 400 -- projectile muzzle velocity in m/s
SWEP.PhysBulletMuzzleVelocity = nil -- override phys bullet muzzle velocity
SWEP.PhysBulletDrag = 1
SWEP.PhysBulletGravity = 1
SWEP.PhysBulletDontInheritPlayerVelocity = true

SWEP.BodyDamageMults = nil
-- if a limb is not set the damage multiplier will default to 1
-- that means gmod's stupid default limb mults will **NOT** apply
-- {
--     [HITGROUP_HEAD] = 1.25,
--     [HITGROUP_CHEST] = 1,
--     [HITGROUP_LEFTARM] = 0.9,
--     [HITGROUP_RIGHTARM] = 0.9,
-- }

SWEP.AlwaysPhysBullet = false
SWEP.NeverPhysBullet = false
SWEP.PhysTracerProfile = 0 -- color for phys tracer.
-- there are 8 options:
-- 0 = normal
-- 1 = red
-- 2 = green
-- 3 = blue
-- 4 = yellow
-- 5 = violet
-- 6 = cyan
-- 7 = black/invisible

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerFinalMag = 0 -- the last X bullets in a magazine are all tracers
SWEP.Tracer = "arccw_tracer" -- override tracer (hitscan) effect
SWEP.TracerCol = Color(255, 255, 255)
SWEP.HullSize = 0 -- HullSize used by FireBullets

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 25 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 50
SWEP.ReducedClipSize = 10

-- But if you insist...
SWEP.ForceDefaultClip = nil
SWEP.ForceDefaultAmmo = nil

-- The amount of rounds to load in the chamber when the gun is non-empty or empty
-- Defaults to ChamberSize and 0. Don't change unless you have a good reason
SWEP.ChamberLoadNonEmpty = nil
SWEP.ChamberLoadEmpty = nil

SWEP.AmmoPerShot = 1
SWEP.InfiniteAmmo = false -- weapon can reload for free
SWEP.BottomlessClip = false -- weapon never has to reload

SWEP.DoNotEquipmentAmmo = false -- do not automatically give this weapon unique ammo when arccw_equipmentammo is used

SWEP.ShotgunReload = false -- reloads like shotgun instead of magazines
SWEP.HybridReload = false -- reload normally when empty, reload like shotgun when part full

SWEP.ManualAction = false -- pump/bolt action
SWEP.NoLastCycle = false -- do not cycle on last shot

SWEP.RevolverReload = false -- cases all eject on reload

SWEP.ReloadInSights = false
SWEP.ReloadInSights_CloseIn = 0.25
SWEP.ReloadInSights_FOVMult = 0.875
SWEP.LockSightsInReload = false

SWEP.CanFireUnderwater = false

SWEP.Disposable = false -- when all ammo is expended, the gun will remove itself when holstered

SWEP.AutoReload = false -- when weapon is drawn, the gun will reload itself.

SWEP.IsShotgun = false -- weapon receives shotgun ammo types

SWEP.TriggerDelay = false -- Set to true to play the "trigger" animation before firing. Delay time is dependent on animation time.

SWEP.Recoil = 2
SWEP.RecoilSide = 1
SWEP.RecoilRise = 1
SWEP.MaxRecoilBlowback = -1
SWEP.VisualRecoilMult = 1.25
SWEP.RecoilPunch = 1.5
SWEP.RecoilPunchBackMax = 1
SWEP.RecoilPunchBackMaxSights = nil -- may clip with scopes
SWEP.RecoilVMShake = 1 -- random viewmodel offset when shooty

SWEP.Sway = 0

SWEP.ShotgunSpreadDispersion = false -- dispersion will cause pattern to increase instead of shifting
SWEP.ShotgunSpreadPattern = nil
SWEP.ShotgunSpreadPatternOverrun = nil
-- {Angle(1, 1, 0), Angle(1, 0, 0) ..}
-- list of how far each pellet should veer
-- if only one pellet then it'll use the first index
-- if two then the first two
-- in case of overrun pellets will start looping, preferably with the second one, so use that for the loopables
-- precision will still be applied

SWEP.RecoilDirection = Angle(1, 0, 0)
SWEP.RecoilDirectionSide = Angle(0, 1, 0)

SWEP.Delay = 60 / 750 -- 60 / RPM.
SWEP.Num = 1 -- number of shots per trigger pull.
SWEP.Firemode = 1 -- 0: safe, 1: semi, 2: auto, negative: burst
SWEP.Firemodes = {
    -- {
    --     Mode = 1,
    --     CustomBars = "---_#!",
--[[ 
                Custom bar setup
        Colored variants        Classic
        'a' Filled              '-' Filled
        'b' Outline             '_' Outline
        'd' CLR w Outline       '!' Red w Outline        
                    '#' Empty
]]
    --     PrintName = "PUMP",
    --     RunAwayBurst = false,
    --     AutoBurst = false, -- hold fire to continue firing bursts
    --     PostBurstDelay = 0,
    --     ActivateElements = {}
    -- }
}

SWEP.ShotRecoilTable = nil -- {[1] = 0.25, [2] = 2} etc.

SWEP.NotForNPCS = false
SWEP.NPCWeaponType = nil -- string or table, the NPC weapons for this gun to replace
-- if nil, this will be based on holdtype
SWEP.NPCWeight = 100 -- relative likeliness for an NPC to have this weapon
SWEP.TTTWeaponType = nil -- string or table, like NPCWeaponType but specifically for TTT weapons (takes precdence over NPCWeaponType)
SWEP.TTTWeight = 100 -- like NPCWeight but for TTT gamemode

SWEP.AccuracyMOA = 15 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 500 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 150 -- inaccuracy added by moving. Applies in sights as well! Walking speed is considered as "maximum".
SWEP.SightsDispersion = 0 -- dispersion that remains even in sights
SWEP.JumpDispersion = 300 -- dispersion penalty when in the air

SWEP.Bipod_Integral = false -- Integral bipod (ie, weapon model has one)
SWEP.BipodDispersion = 1 -- Bipod dispersion for Integral bipods
SWEP.BipodRecoil = 1 -- Bipod recoil for Integral bipods

SWEP.ShootWhileSprint = false

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mpk1" -- the magazine pool this gun draws from

SWEP.ShootVol = 125 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound
SWEP.ShootPitchVariation = 0.05

SWEP.FirstShootSound = nil
SWEP.ShootSound = ""
SWEP.ShootSoundLooping = nil
SWEP.FirstShootSoundSilenced = nil
SWEP.ShootDrySound = nil -- Add an attachment hook for Hook_GetShootDrySound please!
SWEP.DistantShootSound = nil
SWEP.ShootSoundSilenced = "weapons/arccw/m4a1/m4a1-1.wav"
SWEP.ShootSoundSilencedLooping = nil
SWEP.FiremodeSound = "weapons/arccw/firemode.wav"
SWEP.MeleeSwingSound = "weapons/arccw/melee_lift.wav"
SWEP.MeleeMissSound = "weapons/arccw/melee_miss.wav"
SWEP.MeleeHitSound = "weapons/arccw/melee_hitworld.wav"
SWEP.MeleeHitNPCSound = "weapons/arccw/melee_hitbody.wav"
SWEP.EnterBipodSound = "weapons/arccw/bipod_down.wav"
SWEP.ExitBipodSound = "weapons/arccw/bipod_up.wav"
SWEP.SelectUBGLSound =  "weapons/arccw/ubgl_select.wav"
SWEP.ExitUBGLSound = "weapons/arccw/ubgl_exit.wav"

SWEP.NoFlash = nil -- disable light flash
SWEP.MuzzleEffect = nil
SWEP.FastMuzzleEffect = nil
SWEP.GMMuzzleEffect = false -- Use Gmod muzzle effects rather than particle effects
SWEP.ImpactEffect = nil
SWEP.ImpactDecal = nil

SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellMaterial = nil
SWEP.ShellEffect = nil
SWEP.ShellEjectPosCorrection = nil
SWEP.ShellScale = 1
SWEP.ShellPhysScale = 1
SWEP.ShellPitch = 100
SWEP.ShellSounds = "autocheck"--ArcCW.ShellSoundsTable
SWEP.ShellRotate = 0
SWEP.ShellTime = 0.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on
SWEP.ProceduralViewBobAttachment = nil -- attachment on which coolview is affected by, default is muzzleeffect
SWEP.CamAttachment = nil -- if set, this attachment will control camera movement
SWEP.MuzzleFlashColor = Color(244, 209, 66)

SWEP.SpeedMult = 0.9
SWEP.SightedSpeedMult = 0.75
SWEP.ShootSpeedMult = 1

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}
SWEP.CaseBones = {}
-- Unlike BulletBones, these bones are determined by the missing bullet amount when reloading
SWEP.StripperClipBones = {}

-- the same as the bone versions but works via bodygroups.
-- bodygroups work the same as in attachmentelements.
-- [0] = {ind = 0, bg = 1}
SWEP.BulletBGs = {}
SWEP.CaseBGs = {}
SWEP.StripperClipBGs = {}

SWEP.KeepBaseIrons = false -- do not override iron sights when scope installed
SWEP.BaseIronsFirst = false -- If a sight keeps base irons, irons comes first

SWEP.IronSightStruct = {
    Pos = Vector(-8.728, -13.702, 4.014),
    Ang = Angle(-1.397, -0.341, -2.602),
    Midpoint = { -- Where the gun should be at the middle of it's irons
        Pos = Vector(0, 15, -4),
        Ang = Angle(0, 0, -45),
    },
    Magnification = 1,
    BlackBox = false,
    ScopeTexture = nil,
    SwitchToSound = "", -- sound that plays when switching to this sight
    SwitchFromSound = "",
    ScrollFunc = ArcCW.SCROLL_NONE,
    CrosshairInSights = false,
}

-- add lasers to your weapon without attachments
SWEP.Lasers = nil
-- {
--     {
--         LaserStrength = 1,
--         LaserBone = "laser",
--         Color = Color(255, 0, 0)
--     }
-- }

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false
SWEP.SightTime = 0.33
SWEP.SprintTime = 0

-- If Jamming is enabled, a heat meter will gradually build up until it reaches HeatCapacity.
-- Once that happens, the gun will overheat, playing an animation. If HeatLockout is true, it cannot be fired until heat is 0 again.
SWEP.Jamming = false
SWEP.HeatCapacity = 200 -- rounds that can be fired non-stop before the gun jams, playing the "fix" animation
SWEP.HeatDissipation = 2 -- rounds' worth of heat lost per second
SWEP.HeatLockout = false -- overheating means you cannot fire until heat has been fully depleted
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = false -- when the "fix" animation is played, all heat is restored.
SWEP.HeatOverflow = nil -- if true, heat is allowed to exceed capacity (this only applies when the default overheat handling is overridden)

-- If Malfunction is enabled, the gun has a random chance to be jammed
-- after the gun is jammed, it won't fire unless reload is pressed, which plays the "unjam" animation
-- if no "unjam", "fix", or "cycle" animations exist, the weapon will reload instead
SWEP.Malfunction = false
SWEP.MalfunctionJam = true -- After a malfunction happens, the gun will dryfire until reload is pressed. If unset, instead plays animation right after.
SWEP.MalfunctionTakeRound = true -- When malfunctioning, a bullet is consumed.
SWEP.MalfunctionWait = 0.5 -- The amount of time to wait before playing malfunction animation (or can reload)
SWEP.MalfunctionMean = nil -- The mean number of shots between malfunctions, will be autocalculated if nil
SWEP.MalfunctionVariance = 0.25 -- The fraction of mean for variance. e.g. 0.2 means 20% variance
SWEP.MalfunctionSound = "weapons/arccw/malfunction.wav"

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "smg"
SWEP.HoldtypeCustomize = "slam"
SWEP.HoldtypeNPC = nil

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.GuaranteeLaser = false -- GUARANTEE that the laser position will be accurate, so don't bother with sighted correction

SWEP.ShieldProps = nil
-- {
--     {
--         Model = "",
--         Pos = Vector(0, 0, 0),
--         Ang = Angle(0, 0, 0),
--         Bone = "", -- leave blank for valvebiped right hand
--         Resistance = 5, -- one unit of this object counts for how much penetration amount
--     }
-- }

SWEP.CanBash = true
SWEP.PrimaryBash = false -- primary attack triggers melee attack

SWEP.MeleeDamage = 25
SWEP.MeleeRange = 16
SWEP.MeleeDamageType = DMG_CLUB
SWEP.MeleeTime = 0.5
SWEP.MeleeGesture = nil
SWEP.MeleeAttackTime = 0.2

SWEP.Melee2 = false
SWEP.Melee2Damage = 25
SWEP.Melee2Range = 16
SWEP.Melee2Time = 0.5
SWEP.Melee2Gesture = nil
SWEP.Melee2AttackTime = 0.2

SWEP.BashPreparePos = Vector(2.187, -4.117, -7.14)
SWEP.BashPrepareAng = Angle(32.182, -3.652, -19.039)

SWEP.BashPos = Vector(8.876, 0, 0)
SWEP.BashAng = Angle(-16.524, 70, -11.046)

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.ReloadPos = nil
SWEP.ReloadAng = nil

SWEP.CrouchPos = nil
SWEP.CrouchAng = nil

SWEP.HolsterPos = Vector(0.532, -6, 0)
SWEP.HolsterAng = Angle(-4.633, 36.881, 0)

-- When using custom sprint animations, set this to the same as ActivePos and ActiveAng
SWEP.SprintPos = nil
SWEP.SprintAng = nil

SWEP.BarrelOffsetSighted = Vector(0, 0, 0)
SWEP.BarrelOffsetCrouch = nil
SWEP.BarrelOffsetHip = Vector(3, 0, -3)

SWEP.CustomizePos = Vector(9.824, 0, -4.897)
SWEP.CustomizeAng = Angle(12.149, 30.547, 0)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 1, 1)

SWEP.BarrelLength = 24

SWEP.SightPlusOffset = nil

SWEP.DefaultPoseParams = {} -- {["pose"] = 0.5}
SWEP.DefaultWMPoseParams = {}

SWEP.DefaultElements = {} -- {"ele1", "ele2"}

SWEP.AttachmentElements = {
    -- ["name"] = {
    --     RequireFlags = {}, -- same as attachments
    --     ExcludeFlags = {},
    --     NamePriority = 0, -- higher = more likely to be chosen
    --     NameChange = "",
    --     TrueNameChange = "",
    --     AddPrefix = "",
    --     AddSuffix = "",
    --     VMPoseParams = {}, -- {["pose"] = 0.5}
    --     VMColor = Color(),
    --     VMMaterial = "",
    --     VMBodygroups = {{ind = 1, bg = 1}},
    --     VMElements = {
    --         {
    --             Model = "",
    --             Bone = "",
    --             Offset = {
    --                 pos = Vector(),
    --                 ang = Angle(),
    --             },
    --             ModelSkin = 0,
    --             ModelBodygroups = "",
    --             Scale = Vector(1, 1, 1),
    --             IsMuzzleDevice = false -- this element is a muzzle device, and the muzzle flash should come from here.
    --         }
    --     },
    --     VMOverride = "", -- change the view model to something else. Please make sure it's compatible with the last one.
    --     VMBoneMods = {
    --         ["bone"] = Vector(0, 0, 0)
    --     },
    --     WMPoseParams = {}, -- {["pose"] = 0.5}
    --     WMColor = Color(),
    --     WMMaterial = "",
    --     WMBodygroups = {},
    --     WMElements = {
    --         {
    --             Model = "",
    --             Offset = {
    --                 pos = Vector(),
    --                 ang = Angle(),
    --             },
    --             IsMuzzleDevice = false -- this element is a muzzle device, and the muzzle flash should come from here.
    --         }
    --     },
    --     WMOverride = "", -- change the world model to something else. Please make sure it's compatible with the last one.
    --     WMBoneMods = {
    --         ["bone"] = Vector(0, 0, 0)
    --     },
    --     AttPosMods = {
    --         [1] = {
    --             bone = "", -- optional
    --             vpos = Vector(0, 0, 0),
    --             vang = Angle(0, 0, 0),
    --             wpos = Vector(0, 0, 0),
    --             wang = Angle(0, 0, 0),
    --             SlideAmount = { -- only if base att has slideable
    --                 vmin = Vector(0, 0, 0),
    --                 vmax = Vector(0, 0, 0),
    --                 wmin = Vector(0, 0, 0),
    --                 wmax = Vector(0, 0, 0)
    --             }
    --         }
    --     }
    -- }
}

SWEP.RejectAttachments = {
    -- ["optic_docter"] = true -- stop this attachment from being usable on this gun
}

SWEP.AttachmentOverrides = {
    -- ["optic_docter"] = {} -- allows you to overwrite atttbl values
}

SWEP.TTT_DoNotAttachOnBuy = false -- don't give all attachments when bought

SWEP.Attachments = {}
-- [1] = {
--     PrintName = "Optic", -- print name
--     DefaultAttName = "Iron Sights", -- used to display the "no attachment" text
--     DefaultAttIcon = Material(),
--     Slot = "pic_sight", -- what kind of attachments can fit here
--     MergeSlots = {}, -- these other slots will be merged into this one.
--     Bone = "sight", -- relevant bone any attachments will be mostly referring to
--     WMBone = "ValveBiped.Bip01_L_Hand", -- set it to change parent bone of attachment WM
--     KeepBaseIrons = false,
--     ExtraSightDist = 0,
--     Offset = {
--         vpos = Vector(0, 0, 0), -- offset that the attachment will be relative to the bone
--         vang = Angle(0, 0, 0),
--         wpos = Vector(0, 0, 0), -- same, for the worldmodels
--         wang = Angle(0, 0, 0)
--     },
--     RejectAttachments = {}, -- specific blacklist of attachments this slot cannot accept. Needs to be like {"optic_mrs" = true}
--     VMScale = Vector(1, 1, 1),
--     WMScale = Vector(1, 1, 1),
--     SlideAmount = { -- how far this attachment can slide in both directions.
--         -- overrides Offset.
--         vmin = Vector(0, 0, 0),
--         vmax = Vector(0, 0, 0),
--         wmin = Vector(0, 0, 0),
--         wmax = Vector(0, 0, 0),
--     },
--     CorrectiveAng = Vector(1, 1, 1), -- okay, I know I said sights were pain-free.
--     CorrectivePos = Vector(0, 0, 0), -- that won't always be the case. Use these to fix it. Issues mainly crop up in case of sights parented to bones that are not a root bone.
--     InstalledEles = {"toprail"}, -- activate these AttachmentElements if something is installed
--     DefaultEles = {""} -- activeate these AttachmentElements *unless* something is installed
--     Hidden = false, -- attachment cannot be seen in customize menu
--     Integral = false, -- attachment is assumed never to change
--     RandomChance = 1, -- multiplies chance this slot will get a random attachment
--     DoNotRandomize = false,
--     NoWM = false, -- do not make this show up on worldmodel
--     NoVM = false, -- what do *you* think this one does?
--     FreeSlot = false, -- slot does not count towards attachment capacity
--     -- ABOUT THE FLAG SYSTEM:
--     -- Attachments and slots can give flags
--     -- All attachments automatically give themselves as a flag, e.g. "optic_mrs"
--     -- If requirements are not satisfied, the slot or attachment will not be attachable
--     ExcludeFlags = {}, -- if the weapon has this flag, hide this slot
--     RequireFlags = {}, -- if the weapon does not have all these flags, hide this slot
--     GivesFlags = {} -- give these slots if something is installed here
--     HideIfBlocked = false, -- If flag requirements are not met, do not show the attachment at all
-- }

-- ready: deploy first time
-- draw
-- holster
-- reload
-- fire
-- cycle (for bolt/pump actions)
-- bash
-- fix
-- enter_bipod
-- exit_bipod
-- enter_sight
-- exit_sight
-- a_to_b: switch from firemode a to firemode b. e.g.: 1_to_2
-- idle
-- idle_sights
-- idle_sprint
-- idle_bipod
-- enter_inspect
-- idle_inspect
-- exit_inspect
-- enter_ubgl
-- exit_ubgl
-- idle_ubgl

-- you can append suffixes for different states
-- append list:

-- _iron, _sights, or _sight     for sighted variation
-- _sprint                       for sprinting variation
-- _bipod                        for bipod variation
-- _empty                        for empty variation
-- _jammed                       for jammed variation

-- this does not apply to reload animations.

-- !! they MUST be in the order of this list.
-- example: fire_iron_bipod_empty

-- use SWEP/wep.Hook_TranslateAnimation, same as in attachment, to do even more behaviours
-- use SWEP/wep.Hook_SelectReloadAnimation to change the reload animation
-- use SWEP/wep.Hook_SelectInsertAnimation to change the shotgun reload insert animation
-- use SWEP/wep.Hook_SelectFireAnimation to change the fire animation
-- use SWEP/wep.Hook_SelectCycleAnimation to change the cycle/pump animation
-- use SWEP/wep.Hook_SelectBashAnimation to change the bash animation

-- which sequence to derive the sight autosolver from.
SWEP.AutosolveSourceSeq = "idle"

-- Disclaimer: LHIK is *actually* a type of forward kinematics.
-- If you prefer, LHIK can stand for "Left Hand Individual Kinematics" or some shit

SWEP.Animations = {
    -- ["idle"] = {
    --     Source = "idle",
    --     Time = 10
    -- },
    -- ["draw"] = {
    --     RestoreAmmo = 1, -- only used by shotgun empty insert reload
    --     Source = "deploy",
    --     RareSource = "", -- 1/RareSourceChance of playing this animation instead
    --     RareSourceChance = 100, -- Chance the rapper
    --     Time = 0.5, -- Overwrites the duration of the animation (changes speed). Don't set to use sequence length
    --     Mult = 1, -- Multiplies the rate of animation.
    --     TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, -- third person animation to play when this animation is played
    --     TPAnimStartTime = 0, -- when to start it from
    --     Checkpoints = {}, -- time checkpoints. If weapon is unequipped, the animation will continue to play from these checkpoints when reequipped.
    --     ShellEjectAt = 0, -- animation includes a shell eject at these times
    --     LHIKIn = 0.25, -- In/Out controls how long it takes to switch to regular animation.
    --     LHIKOut = 0.25, -- (not actually inverse kinematics)
    --     LHIKEaseIn = 0.1, -- how long LHIK eases in.
    --     LHIKEaseOut = 0.1, -- if no value is specified then ease = lhikin
    --     LHIKTimeline = { -- allows arbitrary LHIK values to be interpolated between
    --         {
    --             t = 0.1,
    --             lhik = 0,
    --         },
    --         {
    --             t = 0.25,
    --             lhik = 1
    --         }
    --     },
    --     LHIK = true, -- basically disable foregrips on this anim
    --     SoundTable = {
    --         {
    --             s = "", -- sound; can be string or table
    --             p = 100, -- pitch
    --             v = 75, -- volume
    --             t = 1, -- time at which to play relative to Animations.Time
    --             c = CHAN_ITEM, -- channel to play the sound

    --             -- Can also play an effect at the same time
    --             e = "", -- effect name
    --             att = nil, -- attachment, defaults to shell attachment
    --             mag = 100, -- magnitude
    --             -- also capable of modifying bodygroups
    --             ind = 0,
    --             bg = 0,
    --             -- and poseparams
    --             pp = "pose",
    --             ppv = 0.25,
    --         }
    --     },
    --     ViewPunchTable = {
    --         {
    --             p = Vector(0, 0, 0),
    --             t = 1
    --         }
    --     },
    --     ProcDraw = false, -- for draw/deploy animations, always procedurally draw in addition to playing animation
    --     ProcHolster = false, -- procedural holster weapon, THEN play animation
    --     LastClip1OutTime = 0, -- when should the belt visually replenish on a belt fed
    --     MinProgress = 0, -- how much time in seconds must pass before the animation can be cancelled
    --     ForceEmpty = false, -- Used by empty shotgun reloads that load rounds to force consider the weapon to still be empty.
    -- }
}

-- don't change any of this stuff

SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = -1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DrawCrosshair = true
SWEP.m_WeaponDeploySpeed = 80.08135 -- 8008135 boobies is funny but it'll bitch in console :(
        -- We don't do that here

SWEP.ArcCW = true
SWEP.BurstCount = 0
SWEP.AnimQueue = {}
SWEP.FiremodeIndex = 1
SWEP.UnReady = true
SWEP.EventTable = {
    [1] = {} -- for every overlapping one, a new one is made -- checked to be removed afterwards, except 1
}

SWEP.ProneMod_DisableTransitions = true

SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false

if CLIENT or game.SinglePlayer() then

SWEP.RecoilAmount = 0
SWEP.RecoilAmountSide = 0
SWEP.RecoilPunchBack = 0
SWEP.RecoilPunchUp = 0
SWEP.RecoilPunchSide = 0
SWEP.HammerDown = false

SWEP.LHIKTimeline = nil
SWEP.LHIKStartTime = 0
-- {number starttime, number intime, number outtime, number finishouttime}
end

SWEP.Bodygroups = {} -- [0] = 1, [1] = 0...
-- SWEP.RegularClipSize = 0

local searchdir = "weapons/arccw_base"

local function autoinclude(dir)
    local files, dirs = file.Find(searchdir .. "/*.lua", "LUA")

    for _, filename in pairs(files) do
        if filename == "shared.lua" then continue end
        local luatype = string.sub(filename, 1, 2)

        if luatype == "sv" then
            if SERVER then
                include(dir .. "/" .. filename)
            end
        elseif luatype == "cl" then
            AddCSLuaFile(dir .. "/" .. filename)
            if CLIENT then
                include(dir .. "/" .. filename)
            end
        else
            AddCSLuaFile(dir .. "/" .. filename)
            include(dir .. "/" .. filename)
        end
    end

    for _, path in pairs(dirs) do
        autoinclude(dir .. "/" .. path)
    end
end

autoinclude(searchdir)

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "NWState")
    self:NetworkVar("Int", 1, "FireMode")
    self:NetworkVar("Int", 2, "BurstCountUM")
    self:NetworkVar("Int", 3, "LastLoad")
    self:NetworkVar("Int", 4, "NthReload")
    self:NetworkVar("Int", 5, "NthShot")

    -- 2 = insert
    -- 3 = cancelling
    -- 4 = insert empty
    -- 5 = cancelling empty
    self:NetworkVar("Int", 6, "ShotgunReloading")
    self:NetworkVar("Int", 7, "MagUpCount")

    self:NetworkVar("Bool", 0, "HeatLocked")
    self:NetworkVar("Bool", 1, "NeedCycle")
    self:NetworkVar("Bool", 2, "InBipod")
    self:NetworkVar("Bool", 3, "InUBGL")
    self:NetworkVar("Bool", 4, "InCustomize")
    self:NetworkVar("Bool", 5, "GrenadePrimed")
    self:NetworkVar("Bool", 6, "MalfunctionJam")

    self:NetworkVar("Float", 0, "Heat")
    self:NetworkVar("Float", 1, "WeaponOpDelay")
    self:NetworkVar("Float", 2, "ReloadingREAL")
    self:NetworkVar("Float", 3, "MagUpIn")
    self:NetworkVar("Float", 4, "NextPrimaryFireSlowdown")
    self:NetworkVar("Float", 5, "NextIdle")
    self:NetworkVar("Float", 6, "Holster_Time")
    self:NetworkVar("Float", 7, "SightDelta")
    self:NetworkVar("Float", 8, "SprintDelta")

    self:NetworkVar("Vector", 0, "BipodPos")

    self:NetworkVar("Angle", 0, "BipodAngle")

    self:NetworkVar("Entity", 0, "Holster_Entity")
end

function SWEP:OnRestore()
    self:SetNthReload(0)
    self:SetNthShot(0)
    self:SetBurstCountUM(0)
    self:SetReloadingREAL(0)
    self:SetWeaponOpDelay(0)
    self:SetMagUpIn(0)

    self:KillTimers()
    self:Initialize()

    self.UnReady = false
end


function SWEP:SetReloading( v )
    if isbool(v) then
        if v then
            self:SetReloadingREAL(math.huge)
        else
            self:SetReloadingREAL(-math.huge)
        end
    elseif isnumber(v) and v > self:GetReloadingREAL() then
        self:SetReloadingREAL( v )
    end
end

function SWEP:GetReloading()
    local decide

    if self:GetReloadingREAL() > CurTime() then
        decide = true
    else
        decide = false
    end

    self:GetBuff_Hook("Hook_GetReloading", decide)

    return decide
end

function SWEP:SetBurstCount(b)
    self:SetBurstCountUM(b)
end

function SWEP:GetBurstCount()
    return self:GetBuff_Hook("Hook_GetBurstCount", self:GetBurstCountUM()) or self:GetBurstCountUM() or 0
end

function SWEP:SetState(v)
    self:SetNWState(v)
    if !game.SinglePlayer() and CLIENT then self.State = v end
end

function SWEP:GetState(v)
    if !game.SinglePlayer() and CLIENT and self.State then return self.State end
    return self:GetNWState(v)
end

function SWEP:IsProne()
    if PRONE_INPRONE then
        return self:GetOwner().IsProne and self:GetOwner():IsProne()
    else
        return false
    end
end

function SWEP:BarrelHitWall()
    if self.BarrelLength > 0 and GetConVar("arccw_override_nearwall"):GetBool() then
        local offset = self.BarrelOffsetHip

        if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
            return 0 -- Never block barrel in VR
        end

        if self:GetOwner():IsPlayer() and self:GetOwner():InVehicle() then
            return 0
        end

        if self:GetState() == ArcCW.STATE_SIGHTS then
            offset = self.BarrelOffsetSighted
        end

        local dir = self:GetOwner():EyeAngles()
        local src = self:GetOwner():EyePos()

        src = src + dir:Right() * offset[1]
        src = src + dir:Forward() * offset[2]
        src = src + dir:Up() * offset[3]

        local mask = MASK_SOLID

        local filter = {self:GetOwner()}

        table.Add(filter, self.Shields)

        local tr = util.TraceLine({
            start = src,
            endpos = src + (dir:Forward() * (self.BarrelLength + self:GetBuff_Add("Add_BarrelLength"))),
            filter = filter,
            mask = mask
        })

        if tr.Hit and !tr.Entity.ArcCWProjectile then
            local l = (tr.HitPos - src):Length()
            l = l
            return 1 - math.Clamp(l / (self.BarrelLength + self:GetBuff_Add("Add_BarrelLength")), 0, 1)
        else
            return 0
        end
    else
        return 0
    end
end