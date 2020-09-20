local tbl     = table
local tbl_add = tbl.Add
local tbl_ins = tbl.insert
local tostr   = tostring

-- ["buff"] = {"desc", string mode (mult, add, override), bool lowerbetter}

ArcCW.AutoStats = {
    -- Attachments
    ["MagExtender"]           = { "autostat.magextender", "override", false },
    ["MagReducer"]            = { "autostat.magreducer",  "override", true },
    ["Bipod"]                 = { "autostat.bipod",       "override", false },
    ["ScopeGlint"]            = { "autostat.glint",       "override", true },
    ["Silencer"]              = { "autostat.silencer",    "override", false },
    ["Override_NoRandSpread"] = { "autostat.norandspr",   "override", false },
    ["Override_CanFireUnderwater"] = { "autostat.underwater",   "override", false },
    -- Multipliers
    ["Mult_BipodRecoil"]      = { "autostat.bipodrecoil", "mult", true },
    ["Mult_BipodDispersion"]  = { "autostat.bipoddisp",   "mult", true },
    ["Mult_Damage"]           = { "autostat.damage",      "mult", false },
    ["Mult_DamageMin"]        = { "autostat.damagemin",   "mult", false },
    ["Mult_Range"]            = { "autostat.range",       "mult", false },
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
    ["Mult_ShootVol"]         = { "autostat.shootvol",    "mult", true },
    ["Mult_SpeedMult"]        = { "autostat.speedmult",   "mult", false },
    ["Mult_MoveSpeed"]        = { "autostat.speedmult",   "mult", false },
    ["Mult_SightedSpeedMult"] = { "autostat.sightspeed",  "mult", false },
    ["Mult_SightedMoveSpeed"] = { "autostat.sightspeed",  "mult", false },
    ["Mult_ReloadTime"]       = { "autostat.reloadtime",  "mult", true },
    ["Mult_DrawTime"]         = { "autostat.drawtime",    "mult", true },
    ["Mult_SightTime"]        = { "autostat.sighttime",   "mult", true },
    ["Mult_CycleTime"]        = { "autostat.cycletime",   "mult", true },
}

local function getsimpleamt(stat)
    if stat > 1 then
        return stat >= 2 and "++++ " or stat >= 1.5 and "+++ " or stat >= 1.25 and "++ " or "+ "
    elseif stat < 1 then
        return stat <= 0.75 and "---- " or stat <= 0.5 and "--- " or stat <= 0.25 and "-- " or "- "
    end
end

function ArcCW:GetProsCons(att)
    local pros = {}
    local cons = {}

    tbl_add(pros, att.Desc_Pros or {})
    tbl_add(cons, att.Desc_Cons or {})

    -- Localize pro and con text
    for i, v in pairs(pros) do pros[i] = ArcCW.TryTranslation(v) end
    for i, v in pairs(cons) do cons[i] = ArcCW.TryTranslation(v) end

    if not att.AutoStats then return pros, cons end

    local simple = GetConVar("arccw_attinv_simpleproscons"):GetBool()

    for i, stat in pairs(ArcCW.AutoStats) do
        if not att[i] then continue end

        local k, txt  = att[i], ""
        local str, st = ArcCW.GetTranslation(stat[1]) or stat[1], stat[3]

        local tcon, tpro = st and cons or pros, st and pros or cons

        if stat[2] == "mult" and k ~= 1 then
            local sign, percent = k > 1 and "+" or "-", k > 1 and (k - 1) or (1 - k)

            txt = simple and getsimpleamt(k) or sign .. tostr(percent * 100) .. "% "

            tbl_ins(k > 1 and tcon or tpro, txt .. str)
        elseif stat[2] == "add" and k ~= 0 then
            local sign, state = k > 0 and "+" or "-", k > 0 and k or -k

            txt = simple and "+ " or sign .. tostr(state) .. " "

            tbl_ins(k > 1 and tpro or tcon, txt .. str)
        elseif stat[2] == "override" and k == true then
            tbl_ins(st and cons or pros, 1, str)
        end
    end

    return pros, cons
end