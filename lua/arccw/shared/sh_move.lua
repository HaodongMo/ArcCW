
function ArcCW.Move(ply, mv, cmd)
    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local s = 1

    local sm = math.Clamp(wpn.SpeedMult * wpn:GetBuff_Mult("Mult_SpeedMult") * wpn:GetBuff_Mult("Mult_MoveSpeed"), 0, 1)

    -- look, basically I made a bit of an oopsy and uh this is the best way to fix that
    s = s * sm

    local basespd = (Vector(cmd:GetForwardMove(), cmd:GetUpMove(), cmd:GetSideMove())):Length()
    basespd = math.min(basespd, mv:GetMaxClientSpeed())

    local shootmove = wpn:GetBuff("ShootSpeedMult")

    local delta = 0 -- how close should we be to the shoot speed mult
    local shottime = wpn:GetNextPrimaryFireSlowdown() - CurTime()

    if shottime > 0 then -- apply full shoot move speed
        delta = 1
    else -- apply partial shoot move speed
        local delay = wpn:GetFiringDelay()
        local aftershottime = shottime / delay
        delta = math.Clamp(aftershottime, 0, 1)
    end

    local blocksprint = false

    if wpn:GetState() == ArcCW.STATE_SIGHTS or
        wpn:GetState() == ArcCW.STATE_CUSTOMIZE then
        blocksprint = true
        s = s * math.Clamp(wpn:GetBuff("SightedSpeedMult") * wpn:GetBuff_Mult("Mult_SightedMoveSpeed"), 0, 1)
    elseif shottime > 0 then
        blocksprint = true

        if wpn:GetBuff("ShootWhileSprint") then
            blocksprint = false
        end
    end

    if blocksprint then
        basespd = math.min(basespd, ply:GetWalkSpeed())
    end

    if wpn:GetInBipod() then
        s = 0.0001
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

    if wpn:GetInBipod() then
        if !wpn.BipodAngle then
            wpn.BipodPos = wpn:GetOwner():EyePos()
            wpn.BipodAngle = wpn:GetOwner():EyeAngles()
        end

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

    local ang2 = cmd:GetViewAngles()

    -- ang2 = ang2 - (wpn.ViewPunchAngle * FrameTime() * 60)

    ang2 = ang2 - (Angle(wpn.RecoilAmount, wpn.RecoilAmountSide, 0) * FrameTime() * 30)

    cmd:SetViewAngles(ang2)
end

hook.Add("CreateMove", "ArcCW_CreateMove", ArcCW.CreateMove)

local function tgt_pos(ent, head)
    local mins, maxs = ent:WorldSpaceAABB()
    local pos = ent:WorldSpaceCenter()
    pos.z = pos.z + (maxs.z - mins.z) * 0.2 -- Aim at chest level
    if head and ent:GetAttachment(ent:LookupAttachment("eyes")) ~= nil then
        pos = ent:GetAttachment(ent:LookupAttachment("eyes")).Pos
    end
    return pos
end

function ArcCW.StartCommand(ply, ucmd)
    -- Sprint will not interrupt a runaway burst
    local wep = ply:GetActiveWeapon()
    if ply:Alive() and IsValid(wep) and wep.ArcCW and wep:GetBurstCount() > 0
            and ucmd:KeyDown(IN_SPEED) and wep:GetCurrentFiremode().RunawayBurst
            and !(wep:GetBuff_Override("Override_ShootWhileSprint") or wep.ShootWhileSprint) then
        ucmd:SetButtons(ucmd:GetButtons() - IN_SPEED)
    end

    -- Aim assist
    if CLIENT and IsValid(wep) and wep.ArcCW
            and (wep:GetBuff("AimAssist", true) or (GetConVar("arccw_aimassist"):GetBool() and ply:GetInfoNum("arccw_aimassist_cl", 0) == 1))  then
        local cone = wep:GetBuff("AimAssist", true) and wep:GetBuff("AimAssist_Cone") or GetConVar("arccw_aimassist_cone"):GetFloat()
        local dist = wep:GetBuff("AimAssist", true) and wep:GetBuff("AimAssist_Distance") or GetConVar("arccw_aimassist_distance"):GetFloat()
        local inte = wep:GetBuff("AimAssist", true) and wep:GetBuff("AimAssist_Intensity") or GetConVar("arccw_aimassist_intensity"):GetFloat()
        local head = wep:GetBuff("AimAssist", true) and wep:GetBuff("AimAssist_Head") or GetConVar("arccw_aimassist_head"):GetBool()

        -- Check if current target is beyond tracking cone
        local tgt = ply.ArcCW_AATarget
        if IsValid(tgt) and (tgt_pos(tgt, head) - ply:EyePos()):Cross(ply:EyeAngles():Forward()):Length() > cone * 2 then ply.ArcCW_AATarget = nil end -- lost track

        -- Try to seek target if not exists
        tgt = ply.ArcCW_AATarget
        if !IsValid(tgt) or (tgt.Health and tgt:Health() <= 0) or util.QuickTrace(ply:EyePos(), tgt_pos(tgt, head) - ply:EyePos(), ply).Entity ~= tgt then
            local min_diff
            ply.ArcCW_AATarget = nil
            for _, ent in pairs(ents.FindInCone(ply:EyePos(), ply:EyeAngles():Forward(), dist, math.cos(math.rad(cone)))) do
                if ent == ply or (!ent:IsNPC() and !ent:IsNextBot() and !ent:IsPlayer()) or ent:Health() <= 0
                        or (ent:IsPlayer() and ent:Team() ~= TEAM_UNASSIGNED and ent:Team() == ply:Team()) then continue end
                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = tgt_pos(ent, head),
                    mask = MASK_SHOT,
                    filter = ply
                })
                if tr.Entity ~= ent then continue end
                local diff = (tgt_pos(ent, head) - ply:EyePos()):Cross(ply:EyeAngles():Forward()):Length()
                if !ply.ArcCW_AATarget or diff < min_diff then
                    ply.ArcCW_AATarget = ent
                    min_diff = diff
                end
            end
        end

        -- Aim towards target
        tgt = ply.ArcCW_AATarget
        if wep:GetState() ~= ArcCW.STATE_CUSTOMIZE and wep:GetState() ~= ArcCW.STATE_SPRINT and IsValid(tgt) then
            local ang = ucmd:GetViewAngles()
            local pos = tgt_pos(tgt, head)
            local tgt_ang = (pos - ply:EyePos()):Angle()
            local ang_diff = (pos - ply:EyePos()):Cross(ply:EyeAngles():Forward()):Length()
            if ang_diff > 0.1 then
                ang = LerpAngle(math.Clamp(inte / ang_diff, 0, 1), ang, tgt_ang)
                ucmd:SetViewAngles(ang)
            end
        end
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