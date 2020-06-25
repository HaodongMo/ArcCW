local glintmat = Material("effects/blueflare1")

hook.Add("PostDrawEffects", "ArcCW_ScopeGlint", function()
    local e = player.GetAll()

    cam.Start3D()

    for _, ply in pairs(e) do
        if !IsValid(ply) then continue end
        if !ply:ShouldDrawLocalPlayer() then continue end

        local wpn = ply:GetActiveWeapon()

        if !IsValid(wpn) then continue end

        if !wpn.ArcCW then continue end

        if !wpn:GetBuff_Override("ScopeGlint") then continue end

        local v1 = (ply:EyePos() - EyePos()):GetNormalized()
        local v2 = -ply:EyeAngles():Forward()

        local d = v1:Dot(v2)

        d = (d * d * 1.75) - 0.75

        if d < 0 then continue end

        local pos = ply:EyePos() + (ply:EyeAngles():Forward() * 16) + (ply:EyeAngles():Right() * 8)

        local _, scope_i = wpn:GetBuff_Override("ScopeGlint")

        if scope_i then
            local wme = (wpn.Attachments[scope_i].WElement or {}).Model

            if wme then
                local att = wme:LookupAttachment("holosight")

                if !att then
                    att = wme:LookupAttachment("scope")
                end

                if att then
                    pos = wme:GetAttachment(att).Pos
                end
            end
        end

        render.SetMaterial(glintmat)
        render.DrawSprite(pos, 64 * d, 64 * d, Color(255, 255, 255))
    end

    cam.End3D()
end)