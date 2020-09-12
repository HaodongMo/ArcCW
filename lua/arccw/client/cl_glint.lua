local rnd        = render
local r_lightcol = rnd.GetLightColor

local glintmat = Material("effects/blueflare1")

local players
local playerssaver = {}

hook.Add("PostDrawEffects", "ArcCW_ScopeGlint", function()
    if playerssaver ~= players then -- less calls on GetAll
        players      = player.GetAll()
        playerssaver = players
    end

    cam.Start3D()
        for _, ply in pairs(players) do
            if not IsValid(ply) then continue end

            if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then continue end

            local wep = ply:GetActiveWeapon()

            if not (IsValid(wep) and wep.ArcCW) then continue end

            if not wep:GetBuff_Override("ScopeGlint") then continue end

            if wep:GetState() ~= ArcCW.STATE_SIGHTS then continue end

            local vec = (ply:EyePos() - EyePos()):GetNormalized()
            local dot = vec:Dot(-ply:EyeAngles():Forward())

            dot = (dot * dot * 1.75) - 0.75
            dot = dot * (0.5 + (1 - wep:GetSightDelta()) * 0.5)

            if dot < 0 then continue end

            local pos = ply:EyePos() + (ply:EyeAngles():Forward() * 16) + (ply:EyeAngles():Right() * 8)

            local _, scope_i = wep:GetBuff_Override("ScopeGlint")

            if scope_i then
                local world = (wep.Attachments[scope_i].WElement or {}).Model

                if world and IsValid(world) then
                    local att = world:LookupAttachment("holosight") or world:LookupAttachment("scope")

                    if att then pos = world:GetAttachment(att).Pos end
                end
            end

            local lcolpos = r_lightcol(pos):Length()
            local lcoleye = r_lightcol(EyePos()):Length()

            local mag       = wep:GetBuff_Mult("Mult_GlintMagnitude") or 1
            local intensity = math.min(0.2 + (lcolpos + lcoleye) / 2 * 1, 1) * mag
            local col       = 255 * intensity

            rnd.SetMaterial(glintmat)
            rnd.DrawSprite(pos, 96 * dot, 96 * dot, Color(col, col, col))
        end
    cam.End3D()
end)