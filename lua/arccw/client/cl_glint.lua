local glintmat = Material("effects/blueflare1")

hook.Add("PostDrawEffects", "ArcCW_ScopeGlint", function()
    local e = player.GetAll()

    cam.Start3D()

    for _, ply in pairs(e) do
        if !IsValid(ply) then continue end
        if ply == LocalPlayer() and !ply:ShouldDrawLocalPlayer() then continue end

        local wpn = ply:GetActiveWeapon()

        if !IsValid(wpn) then continue end

        if !wpn.ArcCW then continue end

        if !wpn:GetBuff_Override("ScopeGlint") then continue end

        local v1 = (ply:EyePos() - EyePos()):GetNormalized()
        local v2 = -ply:EyeAngles():Forward()

        local d = v1:Dot(v2)

        d = (d * d * 1.75) - 0.75

        -- Factor in sight size (-50% when not zoomed in at all)
        d = d * (0.5 + (1 - wpn:GetSightDelta()) * 0.5)

        if d < 0 then continue end

        local pos = ply:EyePos() + (ply:EyeAngles():Forward() * 16) + (ply:EyeAngles():Right() * 8)

        local _, scope_i = wpn:GetBuff_Override("ScopeGlint")

        if scope_i then
            local wme = (wpn.Attachments[scope_i].WElement or {}).Model

            if wme and IsValid(wme) then
                local att = wme:LookupAttachment("holosight")

                if !att then
                    att = wme:LookupAttachment("scope")
                end

                if att then
                    pos = wme:GetAttachment(att).Pos
                end
            end
        end

        -- Also check the player's view so snipers can't hide in a dark spot
        -- After all, glint is caused by reflection
        local lightcol = render.GetLightColor(pos):Length()
        local lightcol2 = render.GetLightColor(EyePos()):Length()

        -- There is some grace because natural light isn't always at max
        local intensity = math.min(0.2 + (lightcol + lightcol2) / 2 * 1, 1)

        render.SetMaterial(glintmat)
        render.DrawSprite(pos, 96 * d, 96 * d, Color(255 * intensity, 255 * intensity, 255 * intensity))
    end

    cam.End3D()
end)