function ArcCW.DoorBust(ent, vel)
    local cvar = GetConVar("arccw_doorbust"):GetInt()
    local t = GetConVar("arccw_doorbust_time"):GetFloat()
    if cvar == 0 then return end

    local oldSpeed = ent:GetInternalVariable("m_flSpeed")
    ent:Fire("SetSpeed", "1000", 0)
    ent:Fire("Open", "", 0)
    ent:Fire("SetSpeed", oldSpeed, 0.5)

    if string.find(ent:GetClass(), "prop_door*") and ent:GetPhysicsObject():IsValid() and cvar == 1 then

        -- Don't remove the door, that's a silly thing to do
        ent:SetNoDraw(true)
        ent:SetNotSolid(true)

        -- Make a busted door prop and fling it
        local prop = ents.Create("prop_physics")
        prop:SetModel(ent:GetModel())
        prop:SetPos(ent:GetPos())
        prop:SetAngles(ent:GetAngles())
        prop:SetSkin(ent:GetSkin())
        prop:Spawn()
        prop:GetPhysicsObject():SetVelocity(vel)

        -- Make it not collide with players after a bit cause that's annoying
        timer.Create("ArcCW_DoorBust_" .. prop:EntIndex(), 3, 1, function()
            if IsValid(prop) then
                prop:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            end
        end)

        -- Reset it after a while
        SafeRemoveEntityDelayed(prop, t)
        timer.Create("ArcCW_DoorBust_" .. ent:EntIndex(), t, 1, function()
            if IsValid(ent) then
                ent:SetNoDraw(false)
                ent:SetNotSolid(false)
            end
        end)
    end
end

-- This function is not called on brush doors. Let's call this, uhh, intended behavior.
local function DoorBustCheck(ent, dmginfo)
    if GetConVar("arccw_doorbust"):GetInt() == 0 or not string.find(ent:GetClass(), "door") then return end
    local wep = IsValid(dmginfo:GetAttacker()) and ((dmginfo:GetInflictor():IsWeapon() and dmginfo:GetInflictor()) or dmginfo:GetAttacker():GetActiveWeapon())
    if not wep or not wep:IsWeapon() or not wep.ArcCW or not dmginfo:IsDamageType(DMG_BUCKSHOT) then return end
    if ent:GetNoDraw() then return end

    -- Magic number: 119.506 is the size of door01_left
    local threshold = GetConVar("arccw_doorbust_threshold"):GetInt() * (ent:OBBMaxs() - ent:OBBMins()):Length() / 119.506

    -- Because shotgun damage is done per pellet, we must count them together
    if ent.ArcCW_BustCurTime and (ent.ArcCW_BustCurTime + 0.1 < CurTime()) then
        ent.ArcCW_BustCurTime = nil
        ent.ArcCW_BustDamage = 0
    end
    if dmginfo:GetDamage() < (threshold - (ent.ArcCW_BustDamage or 0)) then
        ent.ArcCW_BustCurTime = ent.ArcCW_BustCurTime or CurTime()
        ent.ArcCW_BustDamage = (ent.ArcCW_BustDamage or 0) + dmginfo:GetDamage()
        return
    else
        ent.ArcCW_BustCurTime = nil
        ent.ArcCW_BustDamage = nil
    end
    ArcCW.DoorBust(ent, dmginfo:GetDamageForce() * 0.5)
    -- Double doors are usually linked to the same areaportal. We must destroy the second half of the double door no matter what
    for _, otherDoor in pairs(ents.FindInSphere(ent:GetPos(), 64)) do
        if ent ~= otherDoor and otherDoor:GetClass() == ent:GetClass() and not otherDoor:GetNoDraw() then
                ArcCW.DoorBust(otherDoor, dmginfo:GetDamageForce() * 0.5)
                break
        end
    end
end
hook.Add("EntityTakeDamage", "ArcCW_DoorBust", DoorBustCheck)