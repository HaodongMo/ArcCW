net.Receive("arccw_sp_anim", function(len, ply)
    local wep    = LocalPlayer():GetActiveWeapon()
    local key    = net.ReadString()
    local mul    = net.ReadFloat()
    local start  = net.ReadFloat()
    local time   = net.ReadBool()
    --local skip   = net.ReadBool() Unused
    local ignore = net.ReadBool()

    if !wep.ArcCW then return end

    wep:PlayAnimation(key, mul, false, start, time, false, ignore)
end)

net.Receive("arccw_sp_checkpoints", function(len, ply)
    local wep = LocalPlayer():GetActiveWeapon()

    if !wep.ArcCW then return end

    wep.CheckpointAnimation = nil
end)

net.Receive("arccw_sp_lhikanim", function(len, ply)
    local wep  = LocalPlayer():GetActiveWeapon()
    local key  = net.ReadString()
    local time = net.ReadFloat() or -1

    if !wep.ArcCW then return end

    wep:DoLHIKAnimation(key, time)
end)

net.Receive("arccw_sp_health", function(len, ply)
    local ent = net.ReadEntity()

    if !IsValid(ent) then return end

    ent:SetHealth(0)
    ent.ArcCWCLHealth = 0
end)

local clr_b = Color(160, 190, 255)
local clr_r = Color(255, 190, 190)

concommand.Add("arccw_listvmanims", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if !wep then return end

    local vm = LocalPlayer():GetViewModel()

    if !vm then return end

    local alist = vm:GetSequenceList()

    for i = 0, #alist do
        MsgC(clr_b, i, " --- ")
        MsgC(color_white, "\t", alist[i], "\n     [")
        MsgC(clr_r, "\t", vm:SequenceDuration(i), "\n")
    end
end)

concommand.Add("arccw_listvmbones", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if !wep then return end

    local vm = LocalPlayer():GetViewModel()

    if !vm then return end

    for i = 0, (vm:GetBoneCount() - 1) do
        print(i .. " - " .. vm:GetBoneName(i))
    end
end)

concommand.Add("arccw_listvmatts", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if !wep then return end

    local vm = LocalPlayer():GetViewModel()

    if !vm then return end

    local alist = vm:GetAttachments()

    for i = 1, #alist do
        MsgC(clr_b, i, " --- ")
        MsgC(color_white, "\tindex : ", alist[i].id, "\n     [")
        MsgC(clr_r, "\tname: ", alist[i].name, "\n")
    end
end)

concommand.Add("arccw_listvmbgs", function()
    local wep = LocalPlayer():GetActiveWeapon()

    if !wep then return end

    local vm = LocalPlayer():GetViewModel()

    if !vm then return end

    local alist = vm:GetBodyGroups()

    for i = 1, #alist do
        local alistsm = alist[i].submodels
        local active = vm:GetBodygroup(alist[i].id)
        MsgC(clr_b, alist[i].id, " --  ")
        MsgC(color_white, "\t", alist[i].name, "\n")
        if alistsm then
            for j = 0, #alistsm do
                MsgC(active == j and color_white or clr_b, "\t" .. j, " - ")
                MsgC(active == j and color_white or clr_r, alistsm[j], "\n")
            end
        end
    end
end)

local lastwpn = nil

hook.Add("Think", "ArcCW_FixDeploy", function()
    --if !game.SinglePlayer() then return end
    local wep = LocalPlayer():GetActiveWeapon()

    if wep.ArcCW and wep != lastwpn then wep:Deploy() end

    lastwpn = wep
end)