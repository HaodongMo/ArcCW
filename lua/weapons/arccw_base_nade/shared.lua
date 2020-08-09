SWEP.Base = "arccw_base"

SWEP.Throwing = true
SWEP.Singleton = false -- for grenades, means that weapons ARE ammo; hold one, use one.

SWEP.NotForNPCs = true

SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "NADE"
    },
}

SWEP.PullPinTime = 0.25
SWEP.FuseTime = 3.5

SWEP.ChamberSize = 0

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "grenade"

SWEP.Primary.ClipSize = 1
SWEP.Primary.Ammo = "grenade"

SWEP.Animations = {
    -- ["draw"] = {
    --     Source = "draw",
    --     Time = 0.5,
    -- },
    -- ["ready"] = {
    --     Source = "draw",
    --     Time = 0.5,
    -- },
    -- ["pre_throw"] = {
    --     Source = "pullpin",
    --     Time = 0.5,
    -- },
    -- ["throw"] = {
    --     Source = "throw",
    --     Time = 0.5
    -- }
}

SWEP.BashPreparePos = Vector(2.187, -7.117, -1)
SWEP.BashPrepareAng = Angle(5, -3.652, -19.039)

SWEP.BashPos = Vector(8.876, 0, 0)
SWEP.BashAng = Angle(-16.524, 70, -11.046)

SWEP.HolsterPos = Vector(0.532, -1, 0)
SWEP.HolsterAng = Angle(-10, 0, 0)

SWEP.IronSightStruct = false

SWEP.MeleeSwingSound = "weapons/arccw/m249/m249_draw.wav"
SWEP.MeleeHitSound = "weapons/arccw/knife/knife_hitwall1.wav"
SWEP.MeleeHitNPCSound = "physics/body/body_medium_break2.wav"

SWEP.ShootWhileSprint = true

SWEP.SpeedMult = 1

SWEP.Secondary.Automatic = true

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
end

function SWEP:OnRemove()
    if engine.ActiveGamemode() != "terrortown" then return end
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("use", "weapon_ttt_unarmed")
    end
end