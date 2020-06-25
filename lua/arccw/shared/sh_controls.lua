net.Receive("arccw_firemode", function(len, ply)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    wpn:ChangeFiremode()
end)

net.Receive("arccw_ubgl", function(len, ply)
    local on = net.ReadBool()
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    if on then
        wpn:SelectUBGL()
    else
        wpn:DeselectUBGL()
    end
end)

net.Receive("arccw_togglecustomize", function(len, ply)
    local wpn = ply:GetActiveWeapon()
    local onoff = net.ReadBool()

    if !wpn.ArcCW then return end

    wpn:ToggleCustomizeHUD(onoff)
end)