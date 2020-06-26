hook.Add( "PlayerGiveSWEP", "ArcCW_YearLimiter", function( ply, class, swep )
    local wep = weapons.Get(class)
    if !wep then return end
    if !wep.ArcCW then return end

    if !GetConVar("arccw_limityear_enable"):GetBool() then return end

    local year = GetConVar("arccw_limityear"):GetInt()

    if !wep.Trivia_Year then return end
    if !isnumber(wep.Trivia_Year) then return end

    if wep.Trivia_Year > year then
        ply:ChatPrint( wep.PrintName .. " is outside the year limit! (" .. wep.Trivia_Year .. " > " .. year .. ")")
        return false
    end
end )