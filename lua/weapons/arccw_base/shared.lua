AddCSLuaFile()

SWEP.Spawnable = false -- this obviously has to be set to true
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

--[[
SWEP.WorldModelOffset = {
	pos		=	Vector(0, 0, 0),
	ang		=	Angle(0, 0, 0),
	bone	=	"ValveBiped.Bip01_R_Hand",
}]]

SWEP.PresetBase = nil -- make this weapon share presets with this one.

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

SWEP.Damage = 26
SWEP.DamageMin = 10 -- damage done at maximum range
SWEP.Range = 200 -- in METRES
SWEP.Penetration = 4
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 400 -- projectile muzzle velocity
-- IN M/S
SWEP.PhysBulletMuzzleVelocity = nil -- override phys bullet muzzle velocity
SWEP.PhysBulletDrag = 1

SWEP.AlwaysPhysBullet = false
SWEP.NeverPhysBullet = false

SWEP.TracerNum = 1 -- tracer every X
SWEP.Tracer = nil -- override tracer effect
SWEP.TracerCol = Color(255, 255, 255)
SWEP.HullSize = 0 -- HullSize used by FireBullets

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 25 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 50
SWEP.ReducedClipSize = 10

SWEP.ShotgunReload = false -- reloads like shotgun instead of magazines
SWEP.HybridReload = false -- reload normally when empty, reload like shotgun when part full

SWEP.ManualAction = false -- pump/bolt action
SWEP.NoLastCycle = false -- do not cycle on last shot

SWEP.RevolverReload = false -- cases all eject on reload

SWEP.ReloadInSights = false
SWEP.LockSightsInReload = false

SWEP.CanFireUnderwater = false

SWEP.Disposable = false -- when all ammo is expended, the gun will remove itself when holstered

SWEP.AutoReload = false -- when weapon is drawn, the gun will reload itself.

SWEP.Recoil = 2
SWEP.RecoilSide = 1
SWEP.RecoilRise = 1
SWEP.MaxRecoilBlowback = -1
SWEP.VisualRecoilMult = 1.25
SWEP.RecoilPunch = 1.5

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
SWEP.RunawayBurst = false
SWEP.Firemodes = {
    -- {
    --     Mode = 1,
    --     CustomBars = "----_", -- custom bar setup
    --     PrintName = "PUMP",
    --     RunAwayBurst = false,
    --     PostBurstDelay = 0,
    --     ActivateElements = {}
    -- }
}

SWEP.ShotRecoilTable = nil -- {[1] = 0.25, [2] = 2} etc.

SWEP.NotForNPCS = false
SWEP.NPCWeaponType = nil -- string or table, the NPC weapons for this gun to replace
-- if nil, this will be based on holdtype
SWEP.NPCWeight = 100 -- relative likeliness for an NPC to have this weapon
SWEP.TTTWeaponType = nil -- string or table, like NPCWeaponType but specifically for TTT weapons (takes precdence over NPCWeaponType, uses NPCWeight)

SWEP.AccuracyMOA = 15 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 500 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 150 -- inaccuracy added by moving. Applies in sights as well! Walking speed is considered as "maximum".
SWEP.SightsDispersion = 0 -- dispersion that remains even in sights
SWEP.JumpDispersion = 300 -- dispersion penalty when in the air

-- Based off of CS+'s bipod
SWEP.Bipod_Integral = false -- Integral bipod (ie, weapon model has one)
SWEP.BipodDispersion = .1 -- Bipod dispersion for Integral bipods
SWEP.BipodRecoil = 0.25 -- Bipod recoil for Integral bipods

SWEP.ShootWhileSprint = false

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mpk1" -- the magazine pool this gun draws from

SWEP.ShootVol = 125 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound
SWEP.ShootPitchVariation = 0.05

SWEP.FirstShootSound = nil
SWEP.ShootSound = ""
SWEP.FirstShootSoundSilenced = nil
SWEP.ShootDrySound = nil -- Add an attachment hook for Hook_GetShootDrySound please!
SWEP.DistantShootSound = nil
SWEP.ShootSoundSilenced = "weapons/arccw/m4a1/m4a1-1.wav"
SWEP.FiremodeSound = "weapons/arccw/firemode.wav"
SWEP.MeleeSwingSound = "weapons/arccw/m249/m249_draw.wav"
SWEP.MeleeMissSound = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.MeleeHitSound = "weapons/arccw/knife/knife_hitwall1.wav"
SWEP.MeleeHitNPCSound = "physics/body/body_medium_break2.wav"
SWEP.EnterBipodSound = "weapons/arccw/m249/m249_coverdown.wav"
SWEP.ExitBipodSound = "weapons/arccw/m249/m249_coverup.wav"
SWEP.SelectUBGLSound =  "weapons/arccw/ubgl_select.wav"
SWEP.ExitUBGLSound = "weapons/arccw/ubgl_exit.wav"

SWEP.MuzzleEffect = "arccw_muzzleeffect"
SWEP.FastMuzzleEffect = nil
SWEP.GMMuzzleEffect = false -- Use Gmod muzzle effects rather than particle effects
SWEP.ImpactEffect = nil
SWEP.ImpactDecal = nil

SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellMaterial = nil
SWEP.ShellScale = 1
SWEP.ShellPhysScale = 1
SWEP.ShellPitch = 100
SWEP.ShellSounds = ArcCW.ShellSoundsTable
SWEP.ShellRotate = 0
SWEP.ShellTime = 1 -- add shell life time

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.9
SWEP.SightedSpeedMult = 0.75

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.CaseBones = {}

-- Unlike BulletBones, these bones are determined by the missing bullet amount when reloading
SWEP.StripperClipBones = {}

SWEP.KeepBaseIrons = false -- do not override iron sights when scope installed

SWEP.IronSightStruct = {
    Pos = Vector(-8.728, -13.702, 4.014),
    Ang = Angle(-1.397, -0.341, -2.602),
    Magnification = 1,
    BlackBox = false,
    ScopeTexture = nil,
    SwitchToSound = "", -- sound that plays when switching to this sight
    SwitchFromSound = "",
    ScrollFunc = ArcCW.SCROLL_NONE,
    CrosshairInSights = false,
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false
SWEP.SightTime = 0.33

SWEP.Jamming = false
SWEP.HeatCapacity = 200 -- rounds that can be fired non-stop before the gun jams, playing the "fix" animation
SWEP.HeatDissipation = 5 -- rounds' worth of heat lost per second

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "smg"
SWEP.HoldtypeCustomize = "slam"
SWEP.HoldtypeNPC = nil

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.GuaranteeLaser = false -- GUARANTEE that the laser position will be accurate, so don't bother with sighted correction

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

SWEP.CrouchPos = nil
SWEP.CrouchAng = nil

SWEP.HolsterPos = Vector(0.532, -6, 0)
SWEP.HolsterAng = Angle(-4.633, 36.881, 0)

SWEP.SprintPos = nil
SWEP.SprintAng = nil

SWEP.BarrelOffsetSighted = Vector(0, 0, 0)
SWEP.BarrelOffsetHip = Vector(3, 0, -3)

SWEP.CustomizePos = Vector(9.824, 0, -4.897)
SWEP.CustomizeAng = Angle(12.149, 30.547, 0)

SWEP.InBipodPos = Vector(-4, 2, -4)

SWEP.BobMult = 1

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
    --             slide = { -- only if base att has slideable
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
--     RequireFlags = {}, -- if the weapon does NOT have all these flags, hide this slot
--     GivesFlags = {} -- give these slots if something is installed here
-- }

-- ready: deploy first time
-- draw
-- holster
-- reload
-- fire
-- fire_empty
-- cycle (for bolt actions)
-- bash
-- fix
-- fix_empty
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
-- append _empty for empty variation
-- use SWEP.Hook_TranslateAnimation, same as in attachment, to do even more behaviours

SWEP.Animations = {
    -- ["idle"] = {
    --     Source = "idle",
    --     Time = 10
    -- },
    -- ["draw"] = {
    --     RestoreAmmo = 1, -- only used by shotgun empty insert reload
    --     Source = "deploy",
    --     RareSource = "", -- 1/RareSourceChance of playing this animation instead
    --     RareSourceChance = 100 -- Chance the rapper
    --     Time = 0.5,
    --     TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, -- third person animation to play when this animation is played
    --     TPAnimStartTime = 0, -- when to start it from
    --     Checkpoints = {}, -- time checkpoints. If weapon is unequipped, the animation will continue to play from these checkpoints when reequipped.
    --     ShellEjectAt = 0, -- animation includes a shell eject at these times
    --     LHIKIn = 0.25, -- left hand inverse kinematics. In/Out controls how long it takes to switch to regular animation.
    --     LHIKOut = 0.25, -- (not actually inverse kinematics)
    --     LHIK = true, -- basically disable foregrips on this anim
    --     SoundTable = {
    --         {
    --             s = "", -- sound; can be string or table
    --             p = 100, -- pitch
    --             v = 75, -- volume
    --             t = 1, -- time at which to play relative to Animations.Time
    --             c = CHAN_ITEM, -- channel to play the sound
    --
    --             -- Can also play an effect at the same time
    --             e = "", -- effect name
    --             att = nil, -- attachment, defaults to shell attachment
    --             mag = 100, -- magnitude
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
    -- }
}

-- don't change any of this stuff

SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.DrawCrosshair = true
SWEP.m_WeaponDeploySpeed = 8008135
        -- We don't do that here

SWEP.ArcCW = true
--SWEP.BurstCount = 0
        --Outdated, but if you could find a way to keep compatibility with older atts/weps :heart:
SWEP.AnimQueue = {}
SWEP.FiremodeIndex = 1
SWEP.UnReady = true

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
-- {number starttime, number intime, number outtime, number finishouttime}

end

if SERVER then

include("sv_npc.lua")
include("sv_shield.lua")

end

include("sh_model.lua")
include("sh_timers.lua")
include("sh_think.lua")
include("sh_deploy.lua")
include("sh_anim.lua")
include("sh_firing.lua")
include("sh_reload.lua")
include("sh_attach.lua")
include("sh_sights.lua")
include("sh_firemodes.lua")
include("sh_customize.lua")
include("sh_ubgl.lua")
include("sh_rocket.lua")
include("sh_heat.lua")
include("sh_bash.lua")
include("sh_bipod.lua")
include("sh_grenade.lua")
include("sh_ttt.lua")
include("sh_util.lua")
AddCSLuaFile("sh_model.lua")
AddCSLuaFile("sh_timers.lua")
AddCSLuaFile("sh_think.lua")
AddCSLuaFile("sh_deploy.lua")
AddCSLuaFile("sh_anim.lua")
AddCSLuaFile("sh_firing.lua")
AddCSLuaFile("sh_reload.lua")
AddCSLuaFile("sh_attach.lua")
AddCSLuaFile("sh_sights.lua")
AddCSLuaFile("sh_firemodes.lua")
AddCSLuaFile("sh_customize.lua")
AddCSLuaFile("sh_ubgl.lua")
AddCSLuaFile("sh_rocket.lua")
AddCSLuaFile("sh_heat.lua")
AddCSLuaFile("sh_bash.lua")
AddCSLuaFile("sh_bipod.lua")
AddCSLuaFile("sh_grenade.lua")
AddCSLuaFile("sh_ttt.lua")
AddCSLuaFile("sh_util.lua")

AddCSLuaFile("cl_viewmodel.lua")
AddCSLuaFile("cl_scope.lua")
AddCSLuaFile("cl_crosshair.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_holosight.lua")
AddCSLuaFile("cl_lhik.lua")
AddCSLuaFile("cl_laser.lua")
AddCSLuaFile("cl_blur.lua")
AddCSLuaFile("cl_presets.lua")

if CLIENT then
    include("cl_viewmodel.lua")
    include("cl_scope.lua")
    include("cl_crosshair.lua")
    include("cl_hud.lua")
    include("cl_holosight.lua")
    include("cl_lhik.lua")
    include("cl_laser.lua")
    include("cl_blur.lua")
    include("cl_presets.lua")
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "NWState")

    
    self:NetworkVar("Float", 0, "NextArcCWPrimaryFire")
    self:NetworkVar("Int", 1, "BurstCount")
    --self:NetworkVar("Int", 0, "NWState")


end

function SWEP:SetState(v)
    self:SetNWState(v)

    if CLIENT then
        self.State = v
    end
end

function SWEP:GetState(v)
    if CLIENT and self.State then return self.State end

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
    if GetConVar("arccw_override_nearwall"):GetBool() then
        local offset = self.BarrelOffsetHip

        if vrmod and vrmod.IsPlayerInVR(self:GetOwner()) then
            return 0 -- Never block barrel in VR
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

        local tr = util.TraceLine({
            start = src,
            endpos = src + (dir:Forward() * (self.BarrelLength + self:GetBuff_Add("Add_BarrelLength"))),
            filter = {self:GetOwner()},
            mask = mask
        })

        if tr.Hit then
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

function SWEP:GetNextPrimaryFire()
    return self:GetNextArcCWPrimaryFire()
end

function SWEP:SetNextPrimaryFire(value)
    self:SetNextArcCWPrimaryFire(value)
    return 
end