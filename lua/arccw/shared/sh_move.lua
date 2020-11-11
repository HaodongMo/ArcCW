
function ArcCW.Move(ply, mv, cmd)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local s = 1

    -- look, basically I made a bit of an oopsy and uh this is the best way to fix that
    s = s * math.Clamp(wpn:GetBuff("SpeedMult"), 0, 1)

    local basespd = (Vector(cmd:GetForwardMove(), cmd:GetUpMove(), cmd:GetSideMove())):Length()
    basespd = math.min(basespd, mv:GetMaxClientSpeed())

    if wpn:GetState() == ArcCW.STATE_SIGHTS or
        wpn:GetState() == ArcCW.STATE_CUSTOMIZE then
        basespd = math.min(basespd, ply:GetWalkSpeed())
        s = s * math.Clamp(wpn:GetBuff("SightedSpeedMult"), 0, 1)
    end

    if wpn:GetInBipod() then
        s = 0.0001
    end

    mv:SetMaxSpeed(basespd * s)
    mv:SetMaxClientSpeed(basespd * s)

end

hook.Add("SetupMove", "ArcCW_SetupMove", ArcCW.Move)

function ArcCW.CreateMove(cmd)
    local ply = LocalPlayer()
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    if wpn:GetInBipod() and wpn.BipodAngle then
        local bipang = wpn.BipodAngle
        local ang = cmd:GetViewAngles()

        local dy = math.AngleDifference(ang.y, bipang.y)
        local dp = math.AngleDifference(ang.p, bipang.p)

        local limy_p = 75
        local limy_n = -75
        local limp_p = 30
        local limp_n = -30

        if dy > limy_p then
            ang.y = bipang.y + limy_p
        elseif dy < limy_n then
            ang.y = bipang.y + limy_n
        end

        if dp > limp_p then
            ang.p = bipang.p + limp_p
        elseif dp < limp_n then
            ang.p = bipang.p + limp_n
        end

        cmd:SetViewAngles(ang)
    end
end

hook.Add("CreateMove", "ArcCW_CreateMove", ArcCW.CreateMove)