hook.Add("Initialize", "ArcCW_AddGrenadeAmmo", function()
    if GetConVar("arccw_equipmentammo"):GetBool() and !GetConVar("arccw_equipmentsingleton"):GetBool() then
        for i, k in pairs(weapons.GetList()) do
            local class = k.ClassName
            local wpntbl = weapons.Get(class)

            if wpntbl.Throwing and !wpntbl.Singleton then
                local ammoid = game.GetAmmoID(class)

                if ammoid == -1 then
                    -- if ammo type does not exist, build it
                    game.AddAmmoType({
                        name = class,
                    })
                    if CLIENT then
                        language.Add(class .. "_ammo", wpntbl.PrintName)
                    end
                end

                k.Primary.Ammo = class
            end
        end
    end
end)