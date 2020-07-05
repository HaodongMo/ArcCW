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

if CLIENT then
    net.Receive("arccw_togglecustomize", function()
        if !LocalPlayer():GetActiveWeapon() or !LocalPlayer():GetActiveWeapon().ArcCW then return end
        LocalPlayer():GetActiveWeapon():ToggleCustomizeHUD(net.ReadBool())
    end)
elseif SERVER then
    net.Receive("arccw_togglecustomize", function(len, ply)
        local wpn = ply:GetActiveWeapon()
        local onoff = net.ReadBool()

        if !wpn.ArcCW then return end

        wpn:ToggleCustomizeHUD(onoff)
    end)
end

hook.Add("EntityTakeDamage", "ArcCW_CloseOnHurt", function(ply, dmg)
    if ply:IsPlayer() and ply:GetActiveWeapon() and ply:GetActiveWeapon().ArcCW
            and tobool(ply:GetInfo("arccw_attinv_closeonhurt"))
            and ply:GetActiveWeapon():GetState() == ArcCW.STATE_CUSTOMIZE then
        net.Start("arccw_togglecustomize")
            net.WriteBool(false)
        net.Send(ply)
        ply:GetActiveWeapon():ToggleCustomizeHUD(false)
    end
end)