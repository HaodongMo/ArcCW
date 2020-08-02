-- ["buff"] = {"desc", string mode (mult, add, override), bool lowerbetter}
ArcCW.AutoStats = {
    ["MagExtender"] = {"autostat.magextender", "override", false},
    ["MagReducer"] = {"autostat.magreducer", "override", true},
    ["Bipod"] = {"autostat.bipod", "override", false},
    ["ScopeGlint"] = {"autostat.glint", "override", true},
    ["Silencer"] = {"autostat.silencer", "override", false},

    ["Mult_BipodRecoil"] = {"autostat.bipodrecoil", "mult", true},
    ["Mult_BipodDispersion"] = {"autostat.bipoddisp", "mult", true},
    ["Mult_Damage"] = {"autostat.damage", "mult", false},
    ["Mult_DamageMin"] = {"autostat.damagemin", "mult", false},
    ["Mult_Range"] = {"autostat.range", "mult", false},
    ["Mult_Penetration"] = {"autostat.penetration", "mult", false},
    ["Mult_MuzzleVelocity"] = {"autostat.muzzlevel", "mult", false},
    ["Mult_MeleeTime"] = {"autostat.meleetime", "mult", true},
    ["Mult_MeleeDamage"] = {"autostat.meleedamage", "mult", false},
    ["Add_MeleeRange"] = {"autostat.meleerange", false, false},
    ["Mult_Recoil"] = {"autostat.recoil", "mult", true},
    ["Mult_RecoilSide"] = {"autostat.recoilside", "mult", true},
    ["Mult_RPM"] = {"autostat.firerate", "mult", false},
    ["Mult_AccuracyMOA"] = {"autostat.precision", "mult", true},
    ["Mult_HipDispersion"] = {"autostat.hipdisp", "mult", true},
    ["Mult_SightsDispersion"] = {"autostat.sightdisp", "mult", true},
    ["Mult_MoveDispersion"] = {"autostat.movedisp", "mult", true},
    ["Mult_ShootVol"] = {"autostat.shootvol", "mult", true},
    ["Mult_SpeedMult"] = {"autostat.speedmult", "mult", false},
    ["Mult_MoveSpeed"] = {"autostat.speedmult", "mult", false},
    ["Mult_SightedSpeedMult"] = {"autostat.sightspeed", "mult", false},
    ["Mult_SightedMoveSpeed"] = {"autostat.sightspeed", "mult", false},
    ["Mult_ReloadTime"] = {"autostat.reloadtime", "mult", true},
    ["Mult_DrawTime"] = {"autostat.drawtime", "mult", true},
    ["Mult_SightTime"] = {"autostat.sighttime", "mult", true},
    ["Mult_CycleTime"] = {"autostat.cycletime", "mult", true},
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

    --for i, k in pairs(att) do
    for i, stat in pairs(ArcCW.AutoStats) do
        if att[i] ~= nil then
            local k = att[i]
            local txt = ""

            local str = ArcCW.GetTranslation(stat[1]) or stat[1]

            if stat[2] == "mult" then
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
            elseif stat[2] == "add" then
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
            elseif stat[2] == "override" and k == true then
                if stat[3] then
                    table.insert(cons, 1, str)
                else
                    table.insert(pros, 1, str)
                end
            end
        end
    end

    return pros, cons
end