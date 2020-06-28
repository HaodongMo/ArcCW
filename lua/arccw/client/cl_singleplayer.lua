net.Receive("arccw_sp_anim", function(len, ply)
    local key = net.ReadString()
    local mult = net.ReadFloat()
    local sf = net.ReadFloat()
    local tt = net.ReadBool()
    local skip = net.ReadBool()
    local ignore = net.ReadBool()

    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn.ArcCW then return end

    wpn:PlayAnimation(key, mult, false, sf, tt, skip, ignore)
end)

net.Receive("arccw_sp_lhikanim", function(len, ply)
    local key = net.ReadString()
    local time = net.ReadFloat()

    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn.ArcCW then return end

    wpn:DoLHIKAnimation(key, time)
end)

net.Receive("arccw_sp_health", function(len, ply)
    local ent = net.ReadEntity()

    if !IsValid(ent) then return end

    ent:SetHealth(0)
    ent.ArcCWCLHealth = 0
end)

concommand.Add("arccw_listvmanims", function()
    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn then return end

    local vm = LocalPlayer():GetViewModel()

    if !vm then return end

    PrintTable(vm:GetSequenceList())
end)

net.Receive("arccw_sp_loadautosave", function(len, ply)
    local wpn = LocalPlayer():GetActiveWeapon()

    if !wpn then return end
    if !IsValid(wpn) then return end
    if !wpn.ArcCW then return end

    wpn:LoadPreset()
end)

local lastwpn = nil

hook.Add("Think", "ArcCW_FixDeploy", function()

    local wpn = LocalPlayer():GetActiveWeapon()

    if wpn.ArcCW and wpn != lastwpn then
        wpn:Deploy()
    end

    lastwpn = wpn
end)