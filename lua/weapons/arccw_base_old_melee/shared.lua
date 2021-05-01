SWEP.Base = "arccw_base"

SWEP.Primary.Ammo = "" -- Prevent base "pistol" ammo type from showing up on the HUD of melee weapons

SWEP.MeleeDamage = 25
SWEP.MeleeDamageBackstab = nil -- If not exists, use multiplier on standard damage
SWEP.MeleeRange = 16
SWEP.MeleeDamageType = DMG_CLUB
SWEP.MeleeTime = 0.5
SWEP.MeleeGesture = nil
SWEP.MeleeAttackTime = 0.2

SWEP.Melee2 = false
SWEP.Melee2Damage = 25
SWEP.Melee2DamageBackstab = nil -- If not exists, use multiplier on standard damage
SWEP.Melee2Range = 16
SWEP.Melee2Time = 0.5
SWEP.Melee2Gesture = nil
SWEP.Melee2AttackTime = 0.2

SWEP.Backstab = false
SWEP.BackstabMultiplier = 2

SWEP.NotForNPCs = true

SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "MELEE"
    },
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "melee"

SWEP.Primary.ClipSize = -1

SWEP.Animations = {
    -- ["draw"] = {
    --     Source = "draw",
    --     Time = 0.5,
    -- },
    -- ["ready"] = {
    --     Source = "draw",
    --     Time = 0.5,
    -- },
    -- ["bash"] = {
    --     Source = {"stab", "midslash1", "midslash2", "stab_miss"},
    --     Time = 0.5,
    -- },
    -- ["bash_backstab"] = {
    --     Source = {"stab_backstab"},
    --     Time = 0.5,
    -- },
}

SWEP.IronSightStruct = false

SWEP.BashPreparePos = Vector(0, 0, 0)
SWEP.BashPrepareAng = Angle(0, 0, 0)

SWEP.BashPos = Vector(0, 0, 0)
SWEP.BashAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(0, -1, 0)
SWEP.HolsterAng = Angle(-10, 0, 0)

SWEP.ShootWhileSprint = true

SWEP.SpeedMult = 1

SWEP.Secondary.Automatic = true

