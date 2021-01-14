
function ArcCW.Move(ply, mv, cmd)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local s = 1

    -- look, basically I made a bit of an oopsy and uh this is the best way to fix that
    s = s * math.Clamp(wpn.SpeedMult * wpn:GetBuff_Mult("Mult_SpeedMult") * wpn:GetBuff_Mult("Mult_MoveSpeed"), 0, 1)

    local basespd = (Vector(cmd:GetForwardMove(), cmd:GetUpMove(), cmd:GetSideMove())):Length()
    basespd = math.min(basespd, mv:GetMaxClientSpeed())

    if wpn:GetState() == ArcCW.STATE_SIGHTS or
        wpn:GetState() == ArcCW.STATE_CUSTOMIZE then
        basespd = math.min(basespd, ply:GetWalkSpeed())
        s = s * math.Clamp(wpn:GetBuff("SightedSpeedMult") * wpn:GetBuff_Mult("Mult_SightedMoveSpeed"), 0, 1)
    end

    if wpn:GetInBipod() then
        s = 0.0001
    end

    local shootmove = wpn:GetBuff("ShootSpeedMult")

    local delta = 0 -- how close should we be to the shoot speed mult
    local shottime = wpn:GetNextSecondaryFire() - CurTime()

    if shottime > 0 then -- apply full shoot move speed
        delta = 1
    else -- apply partial shoot move speed
        local delay = wpn:GetFiringDelay()
        local aftershottime = shottime / delay
        delta = math.Clamp(aftershottime, 0, 1)
    end

    s = s * Lerp(delta, 1, shootmove)

    mv:SetMaxSpeed(basespd * s)
    mv:SetMaxClientSpeed(basespd * s)

    wpn.StrafeSpeed = math.Clamp(mv:GetSideSpeed(), -1, 1)

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

function ArcCW.StartCommand(ply, ucmd)
    -- Sprint will not interrupt a runaway burst
    local wep = ply:GetActiveWeapon()
    if ply:Alive() and IsValid(wep) and wep.ArcCW and wep:GetBurstCount() > 0
            and ucmd:KeyDown(IN_SPEED) and wep:GetCurrentFiremode().RunawayBurst
            and !(wep:GetBuff_Override("Override_ShootWhileSprint") or wep.ShootWhileSprint) then
        ucmd:SetButtons(ucmd:GetButtons() - IN_SPEED)
    end
end

hook.Add("StartCommand", "ArcCW_StartCommand", ArcCW.StartCommand)

function ArcCW.StrafeTilt(wep)
    if GetConVar("arccw_strafetilt"):GetBool() then
        local tilt = wep.StrafeSpeed or 0
        if wep:GetState() == ArcCW.STATE_SIGHTS and wep:GetActiveSights().Holosight then
            tilt = tilt * (wep:GetBuff("MoveDispersion") / 360 / 60) * 2
        end
        return tilt
    end
    return 0
end