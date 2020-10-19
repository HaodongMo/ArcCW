local enabled = GetConVar("arccw_enable_sway")
local mult = GetConVar("arccw_mult_sway")

function ArcCW.Sway(cmd)

    local ply = LocalPlayer()
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local ang = cmd:GetViewAngles()

    if (wpn.Sighted or wpn:GetState() == ArcCW.STATE_SIGHTS) and !wpn.NoSway and enabled:GetBool() then
        local sway = mult:GetFloat() * ((wpn.Sway or 0) + wpn:GetBuff_Add("Add_Sway"))
        if sway > 0 then
            ang.p = ang.p - math.sin(CurTime() * 1.25) * 0.004 * sway
            cmd:SetViewAngles(ang)
        end
    end
end

hook.Add("CreateMove", "ArcCW_Sway", ArcCW.Sway)