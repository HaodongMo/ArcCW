function ArcCW.DoorBust(ent, vel)
    local cvar = GetConVar("arccw_doorbust"):GetInt()
    local t = GetConVar("arccw_doorbust_time"):GetFloat()
    if cvar == 0 or ent.ArcCW_DoorBusted then return end
    ent.ArcCW_DoorBusted = true

    local oldSpeed = ent:GetInternalVariable("m_flSpeed")
    ent:Fire("SetSpeed", tostring(oldSpeed * 5), 0)
    ent:Fire("Open", "", 0)
    ent:Fire("SetSpeed", oldSpeed, 0.3)

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
        timer.Create("ArcCW_DoorBust_" .. prop:EntIndex(), 2, 1, function()
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
                ent.ArcCW_DoorBusted = false
            end
        end)
    else
        timer.Create("ArcCW_DoorBust_" .. ent:EntIndex(), 0.5, 1, function()
            if IsValid(ent) then
                ent.ArcCW_DoorBusted = false
            end
        end)
    end
end

function ArcCW.TryBustDoor(ent, dmginfo)
    if GetConVar("arccw_doorbust"):GetInt() == 0 or not IsValid(ent) or not string.find(ent:GetClass(), "door") then return end
    local wep = IsValid(dmginfo:GetAttacker()) and ((dmginfo:GetInflictor():IsWeapon() and dmginfo:GetInflictor()) or dmginfo:GetAttacker():GetActiveWeapon())
    if not wep or not wep:IsWeapon() or not wep.ArcCW or not dmginfo:IsDamageType(DMG_BUCKSHOT) then return end
    if ent:GetNoDraw() or ent.ArcCW_NoBust or ent.ArcCW_DoorBusted then return end

    -- Magic number: 119.506 is the size of door01_left
    -- The bigger the door is, the harder it is to bust
    local threshold = GetConVar("arccw_doorbust_threshold"):GetInt() * math.pow((ent:OBBMaxs() - ent:OBBMins()):Length() / 119.506, 2)

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

hook.Add("PlayerUse", "ArcCW_DoorBust", function(ply, ent)
    if ent.ArcCW_DoorBusted then return false end
end)

-- This hook is not called on brush doors. Let's call this, uhh, intended behavior.
-- hook.Add("EntityTakeDamage", "ArcCW_DoorBust", ArcCW.TryBustDoor)