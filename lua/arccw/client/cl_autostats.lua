-- ["buff"] = {"desc", bool ismult, bool lowerbetter}
ArcCW.AutoStats = {
    ["Mult_BipodRecoil"] = {"autostat.bipodrecoil", true, true},
    ["Mult_BipodDispersion"] = {"autostat.bipoddisp", true, true},
    ["Mult_Damage"] = {"autostat.damage", true, false},
    ["Mult_DamageMin"] = {"autostat.damagemin", true, false},
    ["Mult_Range"] = {"autostat.range", true, false},
    ["Mult_Penetration"] = {"autostat.penetration", true, false},
    ["Mult_MuzzleVelocity"] = {"autostat.muzzlevel", true, false},
    ["Mult_MeleeTime"] = {"autostat.meleedamage", true, true},
    ["Mult_MeleeDamage"] = {"autostat.meleedamage", true, false},
    ["Add_MeleeRange"] = {"autostat.meleerange", false, false},
    ["Mult_Recoil"] = {"autostat.recoil", true, true},
    ["Mult_RecoilSide"] = {"autostat.recoilside", true, true},
    ["Mult_RPM"] = {"autostat.firerate", true, false},
    ["Mult_AccuracyMOA"] = {"autostat.precision", true, true},
    ["Mult_HipDispersion"] = {"autostat.hipdisp", true, true},
    ["Mult_SightsDispersion"] = {"autostat.sightdisp", true, true},
    ["Mult_MoveDispersion"] = {"autostat.movedisp", true, true},
    ["Mult_ShootVol"] = {"autostat.shootvol", true, true},
    ["Mult_SpeedMult"] = {"autostat.speedmult", true, false},
    ["Mult_MoveSpeed"] = {"autostat.speedmult", true, false},
    ["Mult_SightedSpeedMult"] = {"autostat.sightspeed", true, false},
    ["Mult_SightedMoveSpeed"] = {"autostat.sightspeed", true, false},
    ["Mult_ReloadTime"] = {"autostat.reloadtime", true, true},
    ["Mult_DrawTime"] = {"autostat.drawtime", true, true},
    ["Mult_SightTime"] = {"autostat.sighttime", true, true},
    ["Mult_CycleTime"] = {"autostat.cycletime", true, true},
}

local function getsimpleamt(stat)
    if stat > 1 then
        if stat >= 2 then
            return "++++ "
        elseif stat >= 1.5 then
            return "+++ "
        elseif stat >= 1.25 then
            return "++ "
        else
            return "+ "
        end
    elseif stat < 1 then
        if stat <= 0.25 then
            return "---- "
        elseif stat <= 0.5 then
            return "--- "
        elseif stat <= 0.25 then
            return "-- "
        else
            return "- "
        end
    end
end

function ArcCW:GetProsCons(att)
    local pros = {}
    local cons = {}

    table.Add(pros, att.Desc_Pros or {})
    table.Add(cons, att.Desc_Cons or {})

    -- Localize pro and con text
    for i, v in pairs(pros) do pros[i] = ArcCW.TryTranslation(v) end
    for i, v in pairs(cons) do cons[i] = ArcCW.TryTranslation(v) end

    if !att.AutoStats then
        return pros, cons
    end

    local simple = GetConVar("arccw_attinv_simpleproscons"):GetBool()

    for i, k in pairs(att) do
        if ArcCW.AutoStats[i] then
            local stat = ArcCW.AutoStats[i]
            local txt = ""

            local str = ArcCW.GetTranslation(stat[1]) or stat[1]

            if stat[2] then
                -- mult
                if k > 1 then
                    if simple then
                        txt = getsimpleamt(k) .. str
                    else
                        txt = "+" .. tostring((k - 1) * 100) .. "% " .. str
                    end
                    if stat[3] then
                        table.insert(cons, txt)
                    else
                        table.insert(pros, txt)
                    end
                elseif k < 1 then
                    if simple then
                        txt = getsimpleamt(k) .. str
                    else
                        txt = "-" .. tostring((1 - k) * 100) .. "% " .. str
                    end
                    if stat[3] then
                        table.insert(pros, txt)
                    else
                        table.insert(cons, txt)
                    end
                end
            else
                -- add
                if k > 0 then
                    if simple then
                        txt = "+ " .. str
                    else
                        txt = "+" .. tostring(k) .. " " .. str
                    end
                    if stat[3] then
                        table.insert(cons, txt)
                    else
                        table.insert(pros, txt)
                    end
                elseif k < 0 then
                    if simple then
                        txt = "+ " .. str
                    else
                        txt = "-" .. tostring(-k) .. " " .. str
                    end
                    if stat[3] then
                        table.insert(pros, txt)
                    else
                        table.insert(cons, txt)
                    end
                end
            end
        end
    end

    return pros, cons
end