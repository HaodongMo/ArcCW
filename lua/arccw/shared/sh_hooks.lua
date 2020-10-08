-- Future hooks go here, can't find a good place otherwise

hook.Add("InitPostEntity", "ArcCW_WeakenSounds", function()
    local v = GetConVar("arccw_weakensounds"):GetInt()
    if v != 0 then
        for i, wep in pairs(weapons.GetList()) do
            if !weapons.IsBasedOn(wep.ClassName, "arccw_base") or !wep.ShootVol then continue end
            wep.ShootVol = math.Clamp(wep.ShootVol - v, 60, 150)
        end
    end
end)