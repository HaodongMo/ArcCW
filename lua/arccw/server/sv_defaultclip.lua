hook.Add("OnEntityCreated", "ArcCW_DefaultClip", function(ent)
    if not ent.ArcCW then return end
    if ent.Primary.DefaultClip <= 0 then return end

    if ent.ForceDefaultClip then
        ent.Primary.DefaultClip = ent.ForceDefaultClip
    elseif GetConVar("arccw_mult_defaultclip"):GetInt() < 0 then
        ent.Primary.DefaultClip = ent.Primary.ClipSize * 3
        if ent.Primary.ClipSize >= 100 then
            ent.Primary.DefaultClip = ent.Primary.ClipSize * 2
        end
    else
        ent.Primary.DefaultClip = ent.Primary.ClipSize * GetConVar("arccw_mult_defaultclip"):GetInt()
    end
end)

hook.Add("PlayerCanPickupWeapon", "ArcCW_EquipmentSingleton", function(ply, wep)
    if wep.ArcCW and wep.Throwing and wep.Singleton and ply:HasWeapon(wep:GetClass()) then return false end
end)