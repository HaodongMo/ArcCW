net.Receive("arccw_sp_anim", function(len, ply)
    local wep    = LocalPlayer():GetActiveWeapon()
    local key    = net.ReadString()
    local mul    = net.ReadFloat()
    local start  = net.ReadFloat()
    local time   = net.ReadBool()
    local skip   = net.ReadBool()
    local ignore = net.ReadBool()

    if not wep.ArcCW then return end

    wep:PlayAnimation(key, mul, false, start, time, skip, ignore)
end)

net.Receive("arccw_sp_checkpoints", function(len, ply)
    local wep = LocalPlayer():GetActiveWeapon()

    if not wep.ArcCW then return end

    wep.CheckpointAnimation = nil
end)

net.Receive("arccw_sp_lhikanim", function(len, ply)
    local wep  = LocalPlayer():GetActiveWeapon()
    local key  = net.ReadString()
    local time = net.ReadFloat()

    if not wep.ArcCW then return end

    wep:DoLHIKAnimation(key, time)
end)

net.Receive("arccw_sp_health", function(len, ply)
    local ent = net.ReadEntity()

    if not IsValid(ent) then return end

    ent:SetHealth(0)
    ent.ArcCWCLHealth = 0
end)

concommand.Add("arccw_listvmanims", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if not wep then return end

    local vm = LocalPlayer():GetViewModel()

    if not vm then return end

    PrintTable(vm:GetSequenceList())
end)

net.Receive("arccw_sp_loadautosave", function(len, ply)
    local wep = LocalPlayer():GetActiveWeapon()

    if not (wep and IsValid(wep)) then return end

    if not wep.ArcCW then return end

    wpn:LoadPreset()
end)

local lastwpn = nil

hook.Add("Think", "ArcCW_FixDeploy", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if wep.ArcCW and wep ~= lastwpn then wep:Deploy() end

    lastwpn = wep
end)