-- Converts raw string to a lang phrase. Not case sensitive.
ArcCW.StringToLang = {
    -- Class
    ["pistol"] = "class.pistol",
    ["revolver"] = "class.revolver",
    ["machine pistol"] = "class.machinepistol",

    ["submachine gun"] = "class.smg", -- Preferred
    ["sub-machine gun"] = "class.smg",
    ["smg"] = "class.smg",

    ["personal defense weapon"] = "class.pdw", -- Preferred
    ["pdw"] = "class.pdw",

    ["assault carbine"] = "class.assaultcarbine",
    ["carbine"] = "class.carbine",
    ["assault rifle"] = "class.assaultrifle",
    ["rifle"] = "class.rifle",

    ["battle rifle"] = "class.battlerifle",
    ["designated marksman rifle"] = "class.dmr",
    ["dmr"] = "class.dmr", -- Preferred
    ["sniper rifle"] = "class.sniperrifle", -- Preferred
    ["sniper"] = "class.sniperrifle",

    ["antimateriel rifle"] = "class.antimaterielrifle", -- Preferred
    ["antimaterial rifle"] = "class.antimaterielrifle",
    ["anti-material rifle"] = "class.antimaterielrifle",
    ["rocket launcher"] = "class.rocketlauncher",

    ["hand grenade"] = "class.grenade", -- Preferred
    ["grenade"] = "class.grenade",
    ["melee weapon"] = "class.melee", -- Preferred
    ["melee"] = "class.melee",
}

-- Adds a string to the StringToLang table.
function ArcCW.AddStringToLang(str, phrase)
    ArcCW.StringToLang[string.lower(str)] = phrase
end

-- Retrieves a lang phrase from a string. If the string is a phrase itself, it will be returned.
function ArcCW.GetPhraseFromString(str)
    if ArcCW.StringToLang[string.lower(str)] then
        return ArcCW.StringToLang[string.lower(str)]
    end
    if ArcCW.LangTable["en"][string.lower(str)] then
        return string.lower(str)
    end
    return nil
end

-- Gets a translated string from a phrase. Will attempt to fallback to English.
-- Returns nil if no such phrase exists.
function ArcCW.GetTranslation(phrase, lang)
    if not lang then
        lang = string.lower(GetConVar("gmod_language"):GetString())
    end
    if not lang or lang == "" or not ArcCW.LangTable[lang] then
        lang = "en"
    end
    if ArcCW.LangTable[lang][phrase] then
        return ArcCW.LangTable[lang][phrase], lang
    else
        return nil
    end
end

-- Attempts to translate a string (could be either a raw string or a phrase).
-- If fail, return the string itself.
function ArcCW.TryTranslation(str, lang)
    local phrase = ArcCW.GetPhraseFromString(str)
    if not phrase then return str end

    return ArcCW.GetTranslationFromPhrase(phrase, lang) or str
end

-- Adds a translated string for a specific language's phrase. lang defaults to English.
function ArcCW.AddTranslation(phrase, str, lang)
    lang = lang and string.lower(lang) or "en"
    ArcCW.LangTable[lang][string.lower(phrase)] = str
end

ArcCW.LangTable = {
    ["en"] = {
        -- Trivia
        ["trivia.class"] = "Class",
        ["trivia.year"] = "Year",
        ["trivia.mechanism"] = "Mechanism",
        ["trivia.calibre"] = "Calibre",
        ["trivia.ammo"] = "Ammo Type",
        ["trivia.country"] = "Country",
        ["trivia.manufacturer"] = "Manufacturer",
        ["trivia.clipsize"] = "Magazine Capacity",
        ["trivia.precision"] = "Precision",
        ["trivia.noise"] = "Noise",
        ["trivia.recoil"] = "Effective Recoil Momentum",
        ["trivia.penetration"] = "Penetration",
        ["trivia.firerate"] = "Fire Rate",
        ["trivia.fusetime"] = "Fuse Time",

        -- Class
        ["class.pistol"] = "Pistol",
        ["class.revolver"] = "Revolver",
        ["class.machinepistol"] = "Machine Pistol",
        ["class.smg"] = "Submachine Gun",
        ["class.pdw"] = "Personal Defense Weapon",
        ["class.assaultcarbine"] = "Assault Carbine",
        ["class.carbine"] = "Carbine",
        ["class.assaultrifle"] = "Assault Rifle",
        ["class.rifle"] = "Rifle",
        ["class.battlerifle"] = "Battle Rifle",
        ["class.dmr"] = "DMR",
        ["class.sniperrifle"] = "Sniper Rifle",
        ["class.antimaterielrifle"] = "Antimateriel rifle",
        ["class.rocketlauncher"] = "Rocket Launcher",
        ["class.grenade"] = "Hand Grenade",
        ["class.melee"] = "Melee Weapon",

        -- Stats
        ["stat.stat"] = "Stat", -- Used on first line of stat page
        ["stat.original"] = "Original",
        ["stat.current"] = "Current",
        ["stat.damage"] = "Close Range Damage",
        ["stat.damage.tooltip"] = "How much damage this weapon does at point blank.",
        ["stat.damagemin"] = "Long Range Damage",
        ["stat.damagemin.tooltip"] = "How much damage this weapon does beyond its range.",
        ["stat.range"] = "Range",
        ["stat.range.tooltip"] = "The distance between which close range damage turns to long range damage, in meters.",
        ["stat.firerate"] = "Fire Rate",
        ["stat.firerate.tooltip"] = "The rate at which this weapon cycles at, in rounds per minute.",
        ["stat.firerate.manual"] = "MANUAL", -- Shown instead of RPM when it is a manual weapon
        ["stat.capacity"] = "Capacity",
        ["stat.capacity.tooltip"] = "How many rounds this weapon can hold.",
        ["stat.precision"] = "Precision",
        ["stat.precision.tooltip"] = "How precise the weapon is when still and aimed, in minutes of arc.",
        ["stat.hipdisp"] = "Hip Dispersion",
        ["stat.hipdisp.tooltip"] = "How much imprecision is added when the weapon is hipfired.",
        ["stat.movedisp"] = "Moving Accuracy",
        ["stat.movedisp.tooltip"] = "How much imprecision is added when the weapon is used while moving.",
        ["stat.recoil"] = "Recoil",
        ["stat.recoil.tooltip"] = "The amount of kick produced each shot.",
        ["stat.recoilside"] = "Side Recoil",
        ["stat.recoilside.tooltip"] = "The amount of horizontal kick produced each shot.",
        ["stat.sighttime"] = "Sight Time",
        ["stat.sighttime.tooltip"] = "How long does it take to transition from or to sprinting and sights with this weapon.",
        ["stat.speedmult"] = "Move Speed",
        ["stat.speedmult.tooltip"] = "The speed at which you move with the gun, in percentage of original speed.",
        ["stat.sightspeed"] = "Sighted Strafe Speed",
        ["stat.sightspeed.tooltip"] = "The additional slowdown applied when you are moving with sights down.",
        ["stat.meleedamage"] = "Bash Damage",
        ["stat.meleedamage.tooltip"] = "How much damage the melee bash causes.",
        ["stat.meleetime"] = "Bash Time",
        ["stat.meleetime.tooltip"] = "The time it takes to do a melee bash.",
        ["stat.shootvol"] = "Firing Volume",
        ["stat.shootvol.tooltip"] = "How loud the weapon is, in decibels. Louder weapons can be heard from further away.",
        ["stat.barrellen"] = "Barrel Length",
        ["stat.barrellen.tooltip"] = "The length of the barrel, in Hammer Units. Long barrels will be blocked by walls more easily.",
        ["stat.pen"] = "Penetration",
        ["stat.pen.tooltip"] = "How much material this weapon can penetrate.",
    }
}