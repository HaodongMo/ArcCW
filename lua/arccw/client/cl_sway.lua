local enabled = GetConVar("arccw_enable_sway")
local mult = GetConVar("arccw_mult_sway")

ArcCW.SwayDir = 0

function ArcCW.Sway(cmd)

    local ply = LocalPlayer()
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local ang = cmd:GetViewAngles()

    if wpn:GetState() == ArcCW.STATE_SIGHTS and !wpn.NoSway and enabled:GetBool() then
        local sway = mult:GetFloat() * wpn:GetBuff("Sway")
        --sway = sway * math.Clamp(1 / (wpn:GetActiveSights().ScopeMagnification or 1), 0.1, 1)
        if wpn:InBipod() then
            sway = sway * (wpn.BipodDispersion * wpn:GetBuff_Mult("Mult_BipodDispersion"))
        end
        if sway > 0.05 then
            ang.p = math.Clamp(ang.p + math.sin(CurTime() * 1.25) * FrameTime() * sway, -89, 89)

            ArcCW.SwayDir = ArcCW.SwayDir + math.Rand(-360, 360) * FrameTime() / math.min(sway, 1)

            ang.p = ang.p + math.sin(ArcCW.SwayDir) * FrameTime() * sway
            ang.y = ang.y + math.cos(ArcCW.SwayDir) * FrameTime() * sway

            -- ang.p = ang.p + math.Rand(-1, 1) * FrameTime() * sway
            -- ang.y = ang.y + math.Rand(-1, 1) * FrameTime() * sway

            cmd:SetViewAngles(ang)
        end
    end
end

hook.Add("CreateMove", "ArcCW_Sway", ArcCW.Sway)