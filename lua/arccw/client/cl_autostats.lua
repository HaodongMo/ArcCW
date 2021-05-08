local tbl     = table
local tbl_add = tbl.Add
local tbl_ins = tbl.insert
local tostr   = tostring

-- ["buff"] = {"desc", string mode (mult, add, override, func), bool lowerbetter or function(val)}

ArcCW.AutoStats = {
    -- Attachments
    ["MagExtender"]           = { "autostat.magextender", "override", false },
    ["MagReducer"]            = { "autostat.magreducer",  "override", true },
    ["Bipod"]                 = { "autostat.bipod",       "override", false },
    ["ScopeGlint"]            = { "autostat.glint",       "override", true },
    ["Silencer"]              = { "autostat.silencer",    "override", false },
    ["Override_NoRandSpread"] = { "autostat.norandspr",   "override", false },
    ["Override_CanFireUnderwater"] = { "autostat.underwater",   "override", false },
    ["Override_ShootWhileSprint"] = { "autostat.sprintshoot",   "override", false },
    -- Multipliers
    ["Mult_BipodRecoil"]      = { "autostat.bipodrecoil", "mult", true },
    ["Mult_BipodDispersion"]  = { "autostat.bipoddisp",   "mult", true },
    ["Mult_Damage"]           = { "autostat.damage",      "mult", false },
    ["Mult_DamageMin"]        = { "autostat.damagemin",   "mult", false },
    ["Mult_Range"]            = { "autostat.range",       "mult", false },
    ["Mult_RangeMin"]         = { "autostat.rangemin",    "mult", false },
    ["Mult_Penetration"]      = { "autostat.penetration", "mult", false },
    ["Mult_MuzzleVelocity"]   = { "autostat.muzzlevel",   "mult", false },
    ["Mult_MeleeTime"]        = { "autostat.meleetime",   "mult", true },
    ["Mult_MeleeDamage"]      = { "autostat.meleedamage", "mult", false },
    ["Add_MeleeRange"]        = { "autostat.meleerange",  false,  false },
    ["Mult_Recoil"]           = { "autostat.recoil",      "mult", true },
    ["Mult_RecoilSide"]       = { "autostat.recoilside",  "mult", true },
    ["Mult_RPM"]              = { "autostat.firerate",    "mult", false },
    ["Mult_AccuracyMOA"]      = { "autostat.precision",   "mult", true },
    ["Mult_HipDispersion"]    = { "autostat.hipdisp",     "mult", true },
    ["Mult_SightsDispersion"] = { "autostat.sightdisp",   "mult", true },
    ["Mult_MoveDispersion"]   = { "autostat.movedisp",    "mult", true },
    ["Mult_JumpDispersion"]   = { "autostat.jumpdisp",    "mult", true },
    ["Mult_ShootVol"]         = { "autostat.shootvol",    "mult", true },
    ["Mult_SpeedMult"]        = { "autostat.speedmult",   "mult", false },
    ["Mult_MoveSpeed"]        = { "autostat.speedmult",   "mult", false },
    ["Mult_SightedSpeedMult"] = { "autostat.sightspeed",  "mult", false },
    ["Mult_SightedMoveSpeed"] = { "autostat.sightspeed",  "mult", false },
    ["Mult_ShootSpeedMult"]   = { "autostat.shootspeed",  "mult", false },
    ["Mult_ReloadTime"]       = { "autostat.reloadtime",  "mult", true },
    ["Add_BarrelLength"]      = { "autostat.barrellength","add",  false },
    ["Mult_DrawTime"]         = { "autostat.drawtime",    "mult", true },
    ["Mult_SightTime"]        = { "autostat.sighttime",   "mult", true },
    ["Mult_CycleTime"]        = { "autostat.cycletime",   "mult", true },
    ["Mult_Sway"]             = { "autostat.sway",        "mult",  true },
    ["Mult_HeatCapacity"]     = { "autostat.heatcap",     "mult", false },
    ["Mult_HeatDissipation"]  = { "autostat.heatdrain",   "mult", false },
    ["Mult_FixTime"]          = { "autostat.heatfix",     "mult", true },
    ["Mult_HeatDelayTime"]    = { "autostat.heatdelay",   "mult", true },

    ["Override_Ammo"] = {"autostat.ammotype", "func", function(val)
        return string.format(ArcCW.GetTranslation("autostat.ammotype"), string.lower(language.GetPhrase(val .. "_ammo"))), "infos"
    end},
}

local function getsimpleamt(stat)
    if stat > 1 then
        return stat >= 2 and "++++ " or stat >= 1.5 and "+++ " or stat >= 1.25 and "++ " or "+ "
    elseif stat < 1 then
        return stat <= 0.75 and "---- " or stat <= 0.5 and "--- " or stat <= 0.25 and "-- " or "- "
    end
end

local function stattext(i, k, dmgboth)
    if !ArcCW.AutoStats[i] then return end
    if i == "Mult_DamageMin" and dmgboth then return end

    local stat = ArcCW.AutoStats[i]
    local simple = GetConVar("arccw_attinv_simpleproscons"):GetBool()

    local txt = ""
    local str, st = ArcCW.GetTranslation(stat[1]) or stat[1], stat[3]

    if i == "Mult_Damage" and dmgboth then
        str = ArcCW.GetTranslation("autostat.damageboth") or stat[1]
    end

    local tcon, tpro = st and "cons" or "pros", st and "pros" or "cons"

    if stat[2] == "mult" and k != 1 then
        local sign, percent = k > 1 and "+" or "-", k > 1 and (k - 1) or (1 - k)
        txt = simple and getsimpleamt(k) or sign .. tostr(math.Round(percent * 100, 2)) .. "% "
        return txt .. str, k > 1 and tcon or tpro
    elseif stat[2] == "add" and k != 0 then
        local sign, state = k > 0 and "+" or "-", k > 0 and k or -k
        txt = simple and "+ " or sign .. tostr(state) .. " "
        return txt .. str, k > 1 and tpro or tcon
    elseif stat[2] == "override" and k == true then
        return st and cons or pros, str
    elseif stat[2] == "func" then
        local a, b = stat[3](k)
        if a and b then return a, b end
    end
end

function ArcCW:GetProsCons(att, toggle)
    local pros = {}
    local cons = {}
    local infos = {}

    tbl_add(pros, att.Desc_Pros or {})
    tbl_add(cons, att.Desc_Cons or {})
    tbl_add(infos, att.Desc_Neutrals or {})

    -- Localize pro and con text
    for i, v in pairs(pros) do pros[i] = ArcCW.TryTranslation(v) end
    for i, v in pairs(cons) do cons[i] = ArcCW.TryTranslation(v) end
    for i, v in pairs(infos) do infos[i] = ArcCW.TryTranslation(v) end

    if !att.AutoStats then return pros, cons, infos end

    -- Process togglable stats
    if att.ToggleStats then
        local toggletbl = att.ToggleStats[toggle or 1]
        if toggletbl and !toggletbl.NoAutoStats then

            local dmgboth = toggletbl.Mult_DamageMin and toggletbl.Mult_Damage and toggletbl.Mult_DamageMin == toggletbl.Mult_Damage
            for i, k in pairs(toggletbl) do
                local txt, typ = stattext(i, k, dmgboth)
                if !txt then continue end

                local stat = ArcCW.AutoStats[i]
                local prefix = (stat[2] == "override" and k == true) and "" or ("[" .. (toggletbl.AutoStatName or toggletbl.PrintName or i) .. "] ")

                if typ == "pros" then
                    tbl_ins(pros, prefix .. txt)
                elseif typ == "cons" then
                    tbl_ins(cons, prefix .. txt)
                elseif typ == "infos" then
                    tbl_ins(infos, prefix .. txt)
                end

                --[[]
                if !ArcCW.AutoStats[i] then continue end
                if i == "Mult_DamageMin" and dmgboth then continue end
                local stat = ArcCW.AutoStats[i]

                local prefix = "[" .. (toggletbl.AutoStatName or toggletbl.PrintName or i) .. "] "
                local txt = ""
                local str, st = ArcCW.GetTranslation(stat[1]) or stat[1], stat[3]

                if i == "Mult_Damage" and dmgboth then
                    str = ArcCW.GetTranslation("autostat.damageboth") or stat[1]
                end

                local tcon, tpro = st and cons or pros, st and pros or cons

                if stat[2] == "mult" and k != 1 then
                    local sign, percent = k > 1 and "+" or "-", k > 1 and (k - 1) or (1 - k)

                    txt = simple and getsimpleamt(k) or sign .. tostr(math.Round(percent * 100, 2)) .. "% "

                    tbl_ins(k > 1 and tcon or tpro, prefix .. txt .. str)
                elseif stat[2] == "add" and k != 0 then
                    local sign, state = k > 0 and "+" or "-", k > 0 and k or -k

                    txt = simple and "+ " or sign .. tostr(state) .. " "

                    tbl_ins(k > 1 and tpro or tcon, prefix .. txt .. str)
                elseif stat[2] == "override" and k == true then
                    tbl_ins(st and cons or pros, 1, prefix .. str)
                end
                ]]
            end
        end
    end

    local dmgboth = att.Mult_DamageMin and att.Mult_Damage and att.Mult_DamageMin == att.Mult_Damage

    for i, stat in pairs(ArcCW.AutoStats) do
        if !att[i] then continue end

        local txt, typ = stattext(i, att[i], dmgboth)
        if !txt then continue end

        if typ == "pros" then
            tbl_ins(pros, txt)
        elseif typ == "cons" then
            tbl_ins(cons, txt)
        elseif typ == "infos" then
            tbl_ins(infos, txt)
        end

        --[[]
        if i == "Mult_DamageMin" and dmgboth then continue end

        local k, txt  = att[i], ""
        local str, st = ArcCW.GetTranslation(stat[1]) or stat[1], stat[3]

        if i == "Mult_Damage" and dmgboth then
            str = ArcCW.GetTranslation("autostat.damageboth") or stat[1]
        end

        local tcon, tpro = st and cons or pros, st and pros or cons

        if stat[2] == "mult" and k != 1 then
            local sign, percent = k > 1 and "+" or "-", k > 1 and (k - 1) or (1 - k)

            txt = simple and getsimpleamt(k) or sign .. tostr(math.Round(percent * 100, 2)) .. "% "

            tbl_ins(k > 1 and tcon or tpro, txt .. str)
        elseif stat[2] == "add" and k != 0 then
            local sign, state = k > 0 and "+" or "-", k > 0 and k or -k

            txt = simple and "+ " or sign .. tostr(state) .. " "

            tbl_ins(k > 1 and tpro or tcon, txt .. str)
        elseif stat[2] == "override" and k == true then
            tbl_ins(st and cons or pros, 1, str)
        end
        ]]
    end

    return pros, cons, infos
end