local tbl     = table
local tbl_add = tbl.Add
local tbl_ins = tbl.insert
local tostr   = tostring
local translate = ArcCW.GetTranslation

-- ["buff"] = {"desc", string mode (mult, add, override, func), bool lowerbetter or function(val), number priority, bool flipsigns }

ArcCW.AutoStats = {
    -- Attachments
    ["MagExtender"]           = { "autostat.magextender", "override", false,       pr = 317 },
    ["MagReducer"]            = { "autostat.magreducer",  "override", true,        pr = 316 },
    ["Bipod"]                 = { "autostat.bipod",       false, false,            pr = 313 },
    ["ScopeGlint"]            = { "autostat.glint",       "override", true,        pr = 255 },
    ["Silencer"]              = { "autostat.silencer",    "override", false,       pr = 254 },
    ["Override_NoRandSpread"] = { "autostat.norandspr",   "override", false,       pr = 253 },
    ["Override_CanFireUnderwater"] = { "autostat.underwater",   "override", false, pr = 252 },
    ["Override_ShootWhileSprint"] = { "autostat.sprintshoot",   "override", false, pr = 251 },
    -- Multipliers
    ["Mult_BipodRecoil"]      = { "autostat.bipodrecoil", false, true,             pr = 312 },
    ["Mult_BipodDispersion"]  = { "autostat.bipoddisp",   false, true,             pr = 311 },
    ["Mult_Damage"]           = { "autostat.damage",      "mult", false,           pr = 215 },
    ["Mult_DamageMin"]        = { "autostat.damagemin",   "mult", false,           pr = 214 },
    ["Mult_Range"]            = { "autostat.range",       "mult", false,           pr = 185 },
    ["Mult_RangeMin"]         = { "autostat.rangemin",    "mult", false,           pr = 184 },
    ["Mult_Penetration"]      = { "autostat.penetration", "mult", false,           pr = 213 },
    ["Mult_MuzzleVelocity"]   = { "autostat.muzzlevel",   "mult", false,           pr = 212 },
    ["Mult_PhysBulletMuzzleVelocity"] = { "autostat.muzzlevel",   "mult", false,   pr = 211 },
    ["Mult_MeleeTime"]        = { "autostat.meleetime",   "mult", true,            pr = 145 },
    ["Mult_MeleeDamage"]      = { "autostat.meleedamage", "mult", false,           pr = 144 },
    ["Add_MeleeRange"]        = { "autostat.meleerange",  false,  false,           pr = 143 },
    ["Mult_Recoil"]           = { "autostat.recoil",      "mult", true,            pr = 195 },
    ["Mult_RecoilSide"]       = { "autostat.recoilside",  "mult", true,            pr = 194 },
    ["Mult_RPM"]              = { "autostat.firerate",    "mult", false,           pr = 216 },
    ["Mult_AccuracyMOA"]      = { "autostat.precision",   "mult", true,            pr = 186 },
    ["Mult_HipDispersion"]    = { "autostat.hipdisp",     "mult", true,            pr = 155 },
    ["Mult_SightsDispersion"] = { "autostat.sightdisp",   "mult", true,            pr = 154 },
    ["Mult_MoveDispersion"]   = { "autostat.movedisp",    "mult", true,            pr = 153 },
    ["Mult_JumpDispersion"]   = { "autostat.jumpdisp",    "mult", true,            pr = 152 },
    ["Mult_ShootVol"]         = { "autostat.shootvol",    "mult", true,            pr = 115 },
    ["Mult_SpeedMult"]        = { "autostat.speedmult",   "mult", false,           pr = 114 },
    ["Mult_MoveSpeed"]        = { "autostat.speedmult",   "mult", false,           pr = 105 },
    ["Mult_SightedSpeedMult"] = { "autostat.sightspeed",  "mult", false,           pr = 104 },
    ["Mult_SightedMoveSpeed"] = { "autostat.sightspeed",  "mult", false,           pr = 103 },
    ["Mult_ShootSpeedMult"]   = { "autostat.shootspeed",  "mult", false,           pr = 102 },
    ["Mult_ReloadTime"]       = { "autostat.reloadtime",  "mult", true,            pr = 125 },
    ["Add_BarrelLength"]      = { "autostat.barrellength","add",  true,            pr = 915 },
    ["Mult_DrawTime"]         = { "autostat.drawtime",    "mult", true,            pr = 14 },
    ["Mult_SightTime"]        = { "autostat.sighttime",   "mult", true,            pr = 335, flipsigns = true },
    ["Mult_CycleTime"]        = { "autostat.cycletime",   "mult", true,            pr = 334 },
    ["Mult_Sway"]             = { "autostat.sway",        "mult",  true,           pr = 353 },
    ["Mult_HeatCapacity"]     = { "autostat.heatcap",     "mult", false,           pr = 10 },
    ["Mult_HeatDissipation"]  = { "autostat.heatdrain",   "mult", false,           pr = 9 },
    ["Mult_FixTime"]          = { "autostat.heatfix",     "mult", true,            pr = 8 },
    ["Mult_HeatDelayTime"]    = { "autostat.heatdelay",   "mult", true,            pr = 7 },
    ["Mult_MalfunctionMean"]  = { "autostat.malfunctionmean", "mult", false,       pr = 6 },
    ["Add_ClipSize"]          = { "autostat.clipsize.mod",    "add", false,         pr = 315 },
    ["Mult_ClipSize"]         = { "autostat.clipsize.mod",    "mult", false,        pr = 314 },

    ["Override_Ammo"] = {"autostat.ammotype", "func", function(wep, val, att)
        -- have to use the weapons table here because Primary.Ammo *is* modified when attachments are used
        if !IsValid(wep) or !weapons.Get(wep:GetClass()) or weapons.Get(wep:GetClass()).Primary.Ammo == val then return end
        return string.format(translate("autostat.ammotype"), string.lower(ArcCW.TranslateAmmo(val))), "infos"
    end, pr = 316},
    ["Override_ClipSize"] = {"autostat.clipsize", "func", function(wep, val, att)
        if !IsValid(wep) then return end
        local ogclip = wep:GetBuff_Override("BaseClipSize") or (wep.RegularClipSize or (wep.Primary and wep.Primary.ClipSize) or 0)
        if ogclip < val then
            return string.format(translate("autostat.clipsize"), val), "pros"
        else
            return string.format(translate("autostat.clipsize"), val), "cons"
        end
    end, pr = 317},
    ["Bipod"] = {"autostat.bipod2", "func", function(wep, val, att)
        if val then
            local recoil = 100 - math.Round((att.Mult_BipodRecoil or (IsValid(wep) and wep.BipodRecoil) or 1) * 100)
            local disp = 100 - math.Round((att.Mult_BipodDispersion or (IsValid(wep) and wep.BipodDispersion) or 1) * 100)
            return string.format(translate("autostat.bipod2"), disp, recoil), "pros"
        else
            return translate("autostat.nobipod"), "cons"
        end
    end, pr = 314},
    ["UBGL"] = { "autostat.ubgl",  "override", false,        pr = 950 },
    ["UBGL_Ammo"] = {"autostat.ammotypeubgl", "func", function(wep, val, att)
        -- have to use the weapons table here because Primary.Ammo *is* modified when attachments are used
        if !IsValid(wep) then return end
        return string.format(translate("autostat.ammotypeubgl"), string.lower(ArcCW.TranslateAmmo(val))), "infos"
    end, pr = 949},
}

local function getsimpleamt(stat)
    if stat > 1 then
        return stat >= 2 and "++++ " or stat >= 1.5 and "+++ " or stat >= 1.25 and "++ " or "+ "
    elseif stat < 1 then
        return stat <= 0.75 and "---- " or stat <= 0.5 and "--- " or stat <= 0.25 and "-- " or "- "
    end
end

local function stattext(wep, att, i, k, dmgboth, flipsigns)
    if !ArcCW.AutoStats[i] then return end
    if i == "Mult_DamageMin" and dmgboth then return end

    local stat = ArcCW.AutoStats[i]
    local simple = GetConVar("arccw_attinv_simpleproscons"):GetBool()

    local txt = ""
    local str, eval = ArcCW.GetTranslation(stat[1]) or stat[1], stat[3]

    if i == "Mult_Damage" and dmgboth then
        str = ArcCW.GetTranslation("autostat.damageboth") or stat[1]
    end

    local tcon, tpro = eval and "cons" or "pros", eval and "pros" or "cons"

    if stat[3] == "infos" then
        tcon = "infos"
    end

    if stat[2] == "mult" and k != 1 then
        local sign, percent = k > 1 and (flipsigns and "-" or "+") or (flipsigns and "+" or "-"), k > 1 and (k - 1) or (1 - k)
        txt = simple and getsimpleamt(k) or sign .. tostr(math.Round(percent * 100, 2)) .. "% "
        return txt .. str, k > 1 and tcon or tpro
    elseif stat[2] == "add" and k != 0 then
        local sign, state = k > 0 and (flipsigns and "-" or "+") or (flipsigns and "+" or "-"), k > 0 and k or -k
        txt = simple and "+ " or sign .. tostr(state) .. " "
        return txt .. str, k > 0 and tcon or tpro
    elseif stat[2] == "override" and k == true then
        return str, tcon
    elseif stat[2] == "func" then
        local a, b = stat[3](wep, k, att)
        if a and b then return a, b end
    end
end

function ArcCW:GetProsCons(wep, att, toggle)
    local pros = {}
    local cons = {}
    local infos = {}

    tbl_add(pros, att.Desc_Pros or {})
    tbl_add(cons, att.Desc_Cons or {})
    tbl_add(infos, att.Desc_Neutrals or {})

    local override = hook.Run("ArcCW_PreAutoStats", wep, att, pros, cons, infos, toggle)
    if override then return pros, cons, infos end

    -- Localize attachment-specific text
    local hasmaginfo = false
    for i, v in pairs(pros) do
        if v == "pro.magcap" then hasmaginfo = true end
        pros[i] = ArcCW.TryTranslation(v)
    end
    for i, v in pairs(cons) do
        if v == "con.magcap" then hasmaginfo = true end
        cons[i] = ArcCW.TryTranslation(v)
    end
    for i, v in pairs(infos) do infos[i] = ArcCW.TryTranslation(v) end

    if !att.AutoStats then return pros, cons, infos end

    -- Process togglable stats
    if att.ToggleStats then
        --local toggletbl = att.ToggleStats[toggle or 1]
        for ti, toggletbl in pairs(att.ToggleStats) do
            -- show the first stat block (unless NoAutoStats), and all blocks with AutoStats
            if toggletbl.AutoStats or (ti == (toggle or 1) and !toggletbl.NoAutoStats) then
                local dmgboth = toggletbl.Mult_DamageMin and toggletbl.Mult_Damage and toggletbl.Mult_DamageMin == toggletbl.Mult_Damage
                for i, stat in SortedPairsByMemberValue(ArcCW.AutoStats, "pr", true) do
                    if !toggletbl[i] or toggletbl[i .. "_SkipAS"] then continue end
                    local val = toggletbl[i]
                    --[[]
                    -- makes the stat show as a sum and not an additional modifier
                    -- feels more confusing though
                    if att[i] then
                        if stat[2] == "add" then
                            val = val + att[i]
                        elseif stat[2] == "mult" then
                            val = val * att[i]
                        end
                    end
                    ]]

                    local txt, typ = stattext(wep, toggletbl, i, val, dmgboth, ArcCW.AutoStats[i].flipsigns )
                    if !txt then continue end

                    local prefix = (stat[2] == "override" and k == true) and "" or ("[" .. (toggletbl.AutoStatName or toggletbl.PrintName or ti) .. "] ")

                    if typ == "pros" then
                        tbl_ins(pros, prefix .. txt)
                    elseif typ == "cons" then
                        tbl_ins(cons, prefix .. txt)
                    elseif typ == "infos" then
                        tbl_ins(infos, prefix .. txt)
                    end
                end
            end
        end
    end

    local dmgboth = att.Mult_DamageMin and att.Mult_Damage and att.Mult_DamageMin == att.Mult_Damage

    for i, stat in SortedPairsByMemberValue(ArcCW.AutoStats, "pr", true) do
        if !att[i] or att[i .. "_SkipAS"] then continue end

        -- Legacy support: If "Increased/Decreased magazine capacity" line exists, don't do our autostats version
        if hasmaginfo and i == "Override_ClipSize" then continue end

        if i == "UBGL" then 
			tbl_ins(infos, translate("autostat.ubgl2"))
		end

        local txt, typ = stattext(wep, att, i, att[i], dmgboth, ArcCW.AutoStats[i].flipsigns )
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

    hook.Run("ArcCW_PostAutoStats", wep, att, pros, cons, infos, toggle)

    return pros, cons, infos
end