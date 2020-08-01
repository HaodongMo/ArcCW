att.PrintName = ""
att.Icon = nil
att.Description = ""
att.Desc_Pros = {}
att.Desc_Cons = {}
att.Slot = ""
att.TargetSpecificWeapon = "" -- ALWAYS make this attachment available on a specific weapon
att.TargetSpecificSlot = 0 -- on this specific slot

att.SortOrder = 0

att.Spawnable = false -- generate entity
att.AdminOnly = false -- see above
att.Ignore = true
att.InvAtt = nil -- use this other attachment in inventory
att.Free = false -- attachment is always available, and does not need to be picked up or unlocked
att.Hidden = false

att.AddPrefix = ""
att.AddSuffix = ""

att.GivesFlags = {}
att.RequireFlags = {}
att.ExcludeFlags = {}

att.Model = ""
att.HideModel = false
att.ModelBodygroups = ""
att.ModelSkin = 0
att.ModelScale = 1
att.ModelOffset = Vector(0, 0, 0)
att.ModelIsShield = false
att.DrawFunc = function(self, element, wm) end

att.Charm = false
att.CharmBone = "Charm"
att.CharmModel = ""
att.CharmOffset = Vector(0, 0, 0)
att.CharmScale = Vector(1, 1, 1)
att.CharmSkin = 0
att.CharmBodygroups = ""

att.Breakable = false
att.Health = 0 -- for shields
att.ShieldCorrectAng = Angle(0, 0, 0)
att.ShieldCorrectPos = Vector(0, 0, 0)

-- amount of damage done to this attachment
-- attachments which are even a bit damaged are not returned
att.DamageOnShoot = 0
att.DamageOnReload = 0
att.DamagePerSecond = 0

-- {slot = int, oldhp = float, dmg = float}
att.Hook_AttTakeDamage = function(wep, data) end

-- {slot = int, dmg = float}
att.Hook_AttDestroyed = function(wep, data) end

att.VMColor = Color(255, 255, 255)
att.WMColor = Color(255, 255, 255)
att.VMMaterial = ""
att.WMMaterial = ""

att.DroppedModel = nil
att.LHIKHide = false -- use this to just hide the left hand
att.LHIK = false -- use this model for left hand IK
att.LHIK_Animation = false

att.ActivateElements = {}

att.MountPositionOverride = nil -- set between 0 to 1 to always mount in a certain position

att.AdditionalSights = {
    {
        Pos = Vector(0, 0, 0), -- relative to where att.Model is placed
        Ang = Angle(0, 0, 0),
        ScrollFunc = ArcCW.SCROLL_ZOOM,
        ZoomLevels = 6,
        ZoomSound = "weapons/arccw/fiveseven/fiveseven_slideback.wav",
        NVScope = nil, -- enables night vision effects for scope
        NVScopeColor = Color(0, 255, 100),
        NVFullColor = false, -- night vision scope is true full color
        Thermal = true,
        ThermalScopeColor = Color(255, 255, 255),
        ThermalHighlightColor = Color(255, 255, 255),
        ThermalScopeSimple = false,
        ThermalNoCC = false,
        ThermalBHOT = false, -- invert bright/dark
        IgnoreExtra = false -- ignore gun-determined extra sight distance
    }
}

att.UBGL = false -- is underbarrel grenade launcher

att.UBGL_Automatic = false
att.UBGL_ClipSize = 1
att.UBGL_Ammo = "smg1_grenade"
att.UBGL_RPM = 300

-- wep: weapon
-- ubgl: UBGL attachment slot.
att.UBGL_Fire = function(wep, ubgl) end
att.UBGL_Reload = function(wep, ubgl) end

att.Silencer = false

att.Bipod = false
att.Mult_BipodRecoil = 0.25
att.Mult_BipodDispersion = 0.1

att.MagExtender = false
att.MagReducer = false
att.OverrideClipSize = nil
att.Add_ClipSize = 0

att.Laser = false
att.LaserStrength = 1
att.LaserBone = "laser"

att.Holosight = false
att.HolosightReticle = nil
att.HolosightFlare = nil
att.HolosightSize = nil
att.HolosightBone = "holosight"
att.HolosightPiece = nil -- the lens of the holo sight, if applicable
att.HolosightMagnification = 1 -- magnify the lens by this much
att.HolosightBlackbox = false
att.HolosightNoHSP = false -- for this holosight ignore HSP
att.HolosightConstDist = nil -- constant holosight distance, mainly for scopes with range finder

att.Colorable = false -- automatically use the player's color option
att.HolosightColor = Color(255, 255, 255)

att.Override_Firemodes = {}

-- all hooks will work when applied to the SWEP table as well
-- e.g. SWEP.Hook_FireBullets

-- use A_Hook_[Add_Whatever] to hook into additive hooks.
-- {buff = string buff, add = num add}
-- return table

-- use O_Hook_[Override_Whatever] to hook into override hooks.
-- {buff = string buff, current = any override, winningslot = int slot}

-- use M_Hook_[Mult_Whatever] to hook into multiply hooks.
-- {buff = string buff, mult = num mult}

-- all hooks, mults, and adds will work on fire modes

-- allows you to return a shotgun spread offset
-- {n = int number, ang = angle offset}
att.Hook_ShotgunSpreadOffset = function(wep, data) end

-- done before playing an effect
-- return false to prevent playing
-- fx: {fx = EffectData()}
att.Hook_PreDoEffects = function(wep, fx) end

-- return true = compatible
-- return false = incompatible
-- data = {slot = string or table, att = string}
att.Hook_Compatible = function(wep, data) end

-- hook that lets you change the values of the bullet before it's fired.
att.Hook_FireBullets = function(wep, bullettable) end

-- called after all other primary attack functions. Do stuff here.
att.Hook_PostFireBullets = function(wep) end

-- return true to prevent fire
att.Hook_ShouldNotFire = function(wep) end

-- return anything to select this reload animation. Bear in mind that not all guns have the same animations, so check first.
att.Hook_SelectReloadAnimation = function(wep, curanim) end

-- return anything to multiply reload time by that much
att.Hook_MultReload = function(wep, mult) end

-- data has entries:
-- number count, how much ammo to add with this insert
-- string anim, which animation to play
-- bool empty, whether we are reloading from empty
att.Hook_SelectInsertAnimation = function(wep, data) end

-- return to override fire animation
att.Hook_SelectFireAnimation = function(wep, curanim) end

-- return string to change played anim
-- string anim, animation we are attempting to play
-- return false to block animation
-- return nil to do nothing
att.Hook_TranslateAnimation = function(wep, anim) end

-- directly changes source sequence to play
-- seq and return can either be string or table
att.Hook_TranslateSequence = function(wep, seq) end

att.Hook_LHIK_TranslateAnimation = function(wep, anim) end

-- att.Hook_TranslateAnimation = function(wep, anim)
--     if anim == "reload" then
--         return "reload_soh"
--     elseif anim == "reload_empty" then
--         return "reload_empty_soh"
--     end
-- end

-- anim is string
att.Hook_SelectBashAnim = function(wep, anim) end

att.Hook_PreBash = function(wep) end

-- data = {tr = tr, dmg = dmg}
att.Hook_PostBash = function(wep, data) end

-- data has entries:
-- number range, the distance the bullet had to travel
-- number damage, the calculated damage the bullet will do
-- number penleft, the amount of penetration the bullet still possesses
-- enum dmgtype, the DMG_ enum of the damagetype
-- table tr, the trace result
-- entity att, the attacker (?)
-- DamageInfo dmg, the damage info

-- changes to dmg may be overwritten later, so set damage and dmgtype instead
att.Hook_BulletHit = function(wep, data) end

att.Hook_PreReload = function(wep) end

att.Hook_PostReload = function(wep) end

att.Hook_GetVisualBullets = function(wep) end

att.Hook_GetVisualClip = function(wep) end

-- return to set mag capacity
att.Hook_GetCapacity = function(wep, cap) end

-- return false to suppress shoot sound
-- string sound = default sound
att.Hook_GetShootSound = function(wep, sound) end
att.Hook_GetDistantShootSound = function(wep, sound) end

-- allows you to modify the weapon's rate of fire
att.Hook_ModifyRPM = function(wep, delay) end

-- return a table containing Recoil, RecoilSide, VisualRecoilMult to multiply them
att.Hook_ModifyRecoil = function(wep) end

-- run in Think()
att.Hook_Think = function(wep) end

-- thinking hook for att
att.DrawFunc = function(wep, element, wm) end

att.Mult_Damage = 1
att.Mult_DamageMin = 1
att.Mult_DamageNPC = 1 -- damage WHEN USED BY NPCS not when used against them
att.Mult_Range = 1
att.Mult_Penetration = 1
att.Override_DamageType = nil
att.Override_ShootEntity = nil
att.Mult_MuzzleVelocity = 1

att.Override_ShotgunSpreadPattern = {}
att.Override_ShotgunSpreadPatternOverrun = {}

att.Mult_MeleeTime = 1
att.Mult_MeleeDamage = 1
att.Add_MeleeRange = 0
att.Mult_MeleeAttackTime = 1

att.Override_Tracer = nil -- tracer effect name
att.Override_TracerNum = nil
-- att.Override_TracerCol = nil
-- att.Mult_TracerWidth = 1

att.Override_CanBash = nil

att.Override_ShotgunReload = nil
att.Override_HybridReload = nil

att.Override_AutoReload = nil

att.Override_ManualAction = nil

att.Override_CanFireUnderwater = nil

att.Override_ChamberSize = nil
att.Add_ChamberSize = nil

att.Mult_Recoil = 1
att.Mult_RecoilSide = 1
att.Mult_VisualRecoilMult = 1

att.Override_ShootWhileSprint = nil

att.Mult_RPM = 1

att.Override_Num = nil

att.Mult_AccuracyMOA = 1
att.Mult_HipDispersion = 1
att.Mult_SightsDispersion = 1

att.Mult_ShootVol = 1
att.Mult_ShootPitch = 1

att.Override_MuzzleEffect = nil

att.Override_ShellMaterial = nil

att.Override_MuzzleEffectAttachment = nil
att.Override_CaseEffectAttachment = nil

att.Mult_SpeedMult = 1
att.Mult_SightedSpeedMult = 1

att.Override_HoldtypeHolstered = nil
att.Override_HoldtypeActive = nil
att.Override_HoldtypeSights = nil

att.Override_AnimShoot = nil

att.Override_HolsterPos = nil
att.Override_HolsterAng = nil

att.Add_BarrelLength = 0

att.Override_BarrelOffsetSighted = nil
att.Override_BarrelOffsetHip = nil

att.Mult_ReloadTime = 1
att.Mult_DrawTime = 1
att.Mult_SightTime = 1
att.Mult_CycleTime = 1