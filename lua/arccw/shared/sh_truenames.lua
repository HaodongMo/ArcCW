hook.Add("CreateTeams", "ArcCW_TrueNames", function()
    if !GetConVar("arccw_truenames"):GetBool() then return end

    for _, i in pairs(weapons.GetList()) do
        local wpn = weapons.GetStored(i.ClassName)

        if wpn.TrueName then
            wpn.PrintName = wpn.TrueName
        end
    end
end)