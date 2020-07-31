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
    ["sniper rifle"] = "class.sniperrifle",

    ["antimateriel rifle"] = "class.antimaterielrifle", -- Preferred
    ["antimaterial rifle"] = "class.antimaterielrifle",
    ["anti-material rifle"] = "class.antimaterielrifle",
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

-- Gets a translated string from a phrase. If none exist, returns nil.
function ArcCW.GetTranslationFromPhrase(phrase, lang)
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
function ArcCW.TryTranslate(str, lang)
    local phrase = ArcCW.GetPhraseFromString(str)
    if not phrase then return str end

    return ArcCW.GetTranslationFromPhrase(phrase, lang) or str
end

ArcCW.LangTable = {
    ["en"] = {
        ["trivia.class"] = "Class",
        ["trivia.year"] = "Year",
        ["trivia.mechanism"] = "Mechanism",
        ["trivia.calibre"] = "Calibre",
        ["trivia.ammo"] = "Ammo Type",
        ["trivia.country"] = "Country",
        ["trivia.manufacturer"] = "Manufacturer",
        ["trivia.clipsize"] = "Magazine Capacity",
        ["trivia.precision"] = "Precision"
    }
}