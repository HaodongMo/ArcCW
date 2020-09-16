ArcCW.LangTable = {}
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

    ["shotgun"] = "class.shotgun",

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

    -- Attachment Slot
    ["optic"] = "attslot.optic",
    ["backup optic"] = "attslot.bkoptic",
    ["muzzle"] = "attslot.muzzle",
    ["barrel"] = "attslot.barrel",
    ["choke"] = "attslot.choke",
    ["underbarrel"] = "attslot.underbarrel",
    ["tactical"] = "attslot.tactical",
    ["grip"] = "attslot.grip",
    ["stock"] = "attslot.stock",
    ["fire group"] = "attslot.fcg",
    ["ammo type"] = "attslot.ammo",
    ["perk"] = "attslot.perk",
    ["charm"] = "attslot.charm",
    ["skin"] = "attslot.skin",

    ["iron sights"] = "attslot.optic.default",
    ["ironsights"] = "attslot.optic.default",
    ["standard barrel"] = "attslot.barrel.default",
    ["standard choke"] = "attslot.choke.default",
    ["standard muzzle"] = "attslot.muzzle.default",
    ["standard grip"] = "attslot.grip.default",
    ["standard stock"] = "attslot.stock.default",
    ["no stock"] = "attslot.stock.none",
    ["standard fcg"] = "attslot.fcg.default",
}

-- Adds a string to the StringToLang table.
function ArcCW.AddStringToLang(str, phrase)
    if phrase == nil or phrase == "" or str == nil or str == "" then return nil end
    ArcCW.StringToLang[string.lower(str)] = phrase
end

-- Retrieves a lang phrase from a string. If the string is a phrase itself, it will be returned.
function ArcCW.GetPhraseFromString(str)
    if str == nil or str == "" then return nil end
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
function ArcCW.GetTranslation(phrase, format)
    if phrase == nil or phrase == "" then return nil end
    local lang = string.lower(GetConVar("gmod_language"):GetString())
    if not lang or lang == "" or not ArcCW.LangTable[lang] or not ArcCW.LangTable[lang][phrase] then
        lang = "en"
    end
    if ArcCW.LangTable[lang][phrase] then
        local str = ArcCW.LangTable[lang][phrase]
        for i, v in pairs(format or {}) do
            -- print(i, v)
            str = string.Replace(str, "{" .. i .. "}", v)
        end
        return str
    end
    return nil
end

-- Attempts to translate a string (could be either a raw string or a phrase).
-- If fail, return the string itself.
function ArcCW.TryTranslation(str, format)
    if str == nil or str == "" then return nil end
    local phrase = ArcCW.GetPhraseFromString(str)
    if not phrase then return str end

    return ArcCW.GetTranslation(phrase, format) or str
end

-- Adds a translated string for a specific language's phrase. lang defaults to English.
function ArcCW.AddTranslation(phrase, str, lang)
    if phrase == nil or phrase == "" or str == nil or str == "" then return nil end
    lang = lang and string.lower(lang) or "en"
    ArcCW.LangTable[lang] = ArcCW.LangTable[lang] or {}
    ArcCW.LangTable[lang][string.lower(phrase)] = str
end

function ArcCW.LoadLanguages()
    for _, v in pairs(file.Find("arccw/shared/languages/*", "LUA")) do
        include("arccw/shared/languages/" .. v)
        AddCSLuaFile("arccw/shared/languages/" .. v)

        local exp = string.Explode("_", string.lower(string.Replace(v, ".lua", "")))
        local lang = exp[#exp]

        if not lang then
            print("Failed to load ArcCW language file " .. v .. ", did not get language name (naming convention incorrect?)")
            continue
        elseif not L then
            print("Failed to load ArcCW language file " .. v .. ", did not get language table")
            continue
        end

        for phrase, str in pairs(L) do
            ArcCW.AddTranslation(phrase, str, lang)
        end

        -- Load StringToLang stuff incase it is needed
        if STL then
            for str, phrase in pairs(STL) do
                ArcCW.AddStringToLang(str, phrase)
            end
        end

        --print("Loaded ArcCW language file " .. v .. " with " .. table.Count(L) .. " strings.")
        L = nil
    end

    hook.Run("ArcCW_LocalizationLoaded")
end
ArcCW.LoadLanguages()