-- ["buff"] = {"desc", bool ismult, bool lowerbetter}
ArcCW.AutoStats = {
    ["Mult_BipodRecoil"] = {"Recoil in bipod", true, true},
    ["Mult_BipodDispersion"] = {"Dispersion in bipod", true, true},
    ["Mult_Damage"] = {"Close range damage", true, false},
    ["Mult_DamageMin"] = {"Long range damage", true, false},
    ["Mult_Range"] = {"Range", true, false},
    ["Mult_Penetration"] = {"Penetration", true, false},
    ["Mult_MuzzleVelocity"] = {"Muzzle velocity", true, false},
    ["Mult_MeleeTime"] = {"Melee attack time", true, true},
    ["Mult_MeleeDamage"] = {"Melee damage", true, false},
    ["Add_MeleeRange"] = {"Melee range", false, false},
    ["Mult_Recoil"] = {"Recoil", true, true},
    ["Mult_RecoilSide"] = {"Horizontal recoil", true, true},
    ["Mult_RPM"] = {"Fire rate", true, false},
    ["Mult_AccuracyMOA"] = {"Imprecision", true, true},
    ["Mult_HipDispersion"] = {"Hip fire spread", true, true},
    ["Mult_SightsDispersion"] = {"Sighted spread", true, true},
    ["Mult_MoveDispersion"] = {"Moving spread", true, true},
    ["Mult_ShootVol"] = {"Weapon volume", true, true},
    ["Mult_SpeedMult"] = {"Movement speed", true, false},
    ["Mult_MoveSpeed"] = {"Movement speed", true, false},
    ["Mult_SightedSpeedMult"] = {"Sighted strafe speed", true, false},
    ["Mult_SightedMoveSpeed"] = {"Sighted strafe speed", true, false},
    ["Mult_ReloadTime"] = {"Reload time", true, true},
    ["Mult_DrawTime"] = {"Draw time", true, true},
    ["Mult_SightTime"] = {"Sight time", true, true},
    ["Mult_CycleTime"] = {"Cycle time", true, true}
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

    if !att.AutoStats then
        return pros, cons
    end

    local simple = GetConVar("arccw_attinv_simpleproscons"):GetBool()

    for i, k in pairs(att) do
        if ArcCW.AutoStats[i] then
            local stat = ArcCW.AutoStats[i]
            local txt = ""

            if stat[2] then
                -- mult
                if k > 1 then
                    if simple then
                        txt = getsimpleamt(k) .. stat[1]
                    else
                        txt = "+" .. tostring((k - 1) * 100) .. "% " .. stat[1]
                    end
                    if stat[3] then
                        table.insert(cons, txt)
                    else
                        table.insert(pros, txt)
                    end
                elseif k < 1 then
                    if simple then
                        txt = getsimpleamt(k) .. stat[1]
                    else
                        txt = "-" .. tostring((1 - k) * 100) .. "% " .. stat[1]
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
                        txt = "+ " .. stat[1]
                    else
                        txt = "+" .. tostring(k) .. " " .. stat[1]
                    end
                    if stat[3] then
                        table.insert(cons, txt)
                    else
                        table.insert(pros, txt)
                    end
                elseif k < 0 then
                    if simple then
                        txt = "+ " .. stat[1]
                    else
                        txt = "-" .. tostring(-k) .. " " .. stat[1]
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