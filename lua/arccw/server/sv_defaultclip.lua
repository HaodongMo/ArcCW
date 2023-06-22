if CLIENT then return end

hook.Add("OnEntityCreated", "ArcCW_DefaultClip", function(ent)
    if !ent.ArcCW then return end

    if GetConVar("arccw_mult_startunloaded"):GetBool() then
        ent.Primary.DefaultClip = 0
    elseif ent.ForceDefaultClip then
        ent.Primary.DefaultClip = ent.ForceDefaultClip
    elseif ent.Primary.DefaultClip <= 0 then
        ent.Primary.DefaultClip = ent.Primary.ClipSize
    end
end)

hook.Add("PlayerCanPickupWeapon", "ArcCW_EquipmentSingleton", function(ply, wep)
    if wep.ArcCW and wep.Throwing and wep.Singleton and ply:HasWeapon(wep:GetClass()) then return false end
end)