if SERVER and game.SinglePlayer() then
    util.AddNetworkString("arccw_sp_reloadlangs")
end

ArcCW.LangTable = {}
-- Converts raw string to a lang phrase. not case sensitive.
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
    ["magazine"] = "attslot.magazine",
    ["slide"] = "attslot.slide",

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

-- Helper function for getting the overwrite or default language
function ArcCW.GetLanguage()
    local l = GetConVar("arccw_language") and string.lower(GetConVar("arccw_language"):GetString())
    if !l or l == "" then l = string.lower(GetConVar("gmod_language"):GetString()) end
    return l
end

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
    local lang = ArcCW.GetLanguage()
    if !lang or lang == "" or !ArcCW.LangTable[lang] or !ArcCW.LangTable[lang][phrase] then
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
    if !str then return nil end
    local phrase = ArcCW.GetPhraseFromString(str)
    if !phrase then return str end

    return ArcCW.GetTranslation(phrase, format) or str
end

-- Adds a translated string for a specific language's phrase. lang defaults to English.
function ArcCW.AddTranslation(phrase, str, lang)
    if phrase == nil or phrase == "" or str == nil or str == "" then return nil end
    lang = lang and string.lower(lang) or "en"
    ArcCW.LangTable[lang] = ArcCW.LangTable[lang] or {}
    ArcCW.LangTable[lang][string.lower(phrase)] = str
end

if CLIENT then
    function ArcCW.LoadClientLanguage(files)
        local lang = ArcCW.GetLanguage()
        files = files or file.Find("arccw/client/cl_languages/*", "LUA")

        -- First make sure there is actually a file in such language; otherwise default to english
        local has = false
        for _, v in pairs(files) do
            local exp = string.Explode("_", string.lower(string.Replace(v, ".lua", "")))
            if exp[#exp] == lang then has = true break end
        end
        if !has then lang = "en" end

        for _, v in pairs(files) do
            local exp = string.Explode("_", string.lower(string.Replace(v, ".lua", "")))
            if exp[#exp] ~= lang then continue end
            include("arccw/client/cl_languages/" .. v)
            for phrase, str in pairs(L) do
                language.Add(phrase, str)
            end

            print("Loaded ArcCW cl_language file " .. v .. " with " .. table.Count(L) .. " strings.")
            L = nil
        end
    end
elseif SERVER then
    for _, v in pairs(file.Find("arccw/client/cl_languages/*", "LUA")) do
        AddCSLuaFile("arccw/client/cl_languages/" .. v)
    end
end

function ArcCW.LoadLanguages()
    ArcCW.LangTable = {}
    for _, v in pairs(file.Find("arccw/shared/languages/*", "LUA")) do
        include("arccw/shared/languages/" .. v)
        AddCSLuaFile("arccw/shared/languages/" .. v)

        local exp = string.Explode("_", string.lower(string.Replace(v, ".lua", "")))
        local lang = exp[#exp]

        if !lang then
            print("Failed to load ArcCW language file " .. v .. ", did not get language name (naming convention incorrect?)")
            continue
        elseif !L then
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

        print("Loaded ArcCW language file " .. v .. " with " .. table.Count(L) .. " strings.")
        L = nil
    end

    if CLIENT then
        ArcCW.LoadClientLanguage()
    end

    hook.Run("ArcCW_LocalizationLoaded")
end
ArcCW.LoadLanguages()

concommand.Add("arccw_reloadlangs", function(ply)
    ArcCW.LoadLanguages()
    if SERVER and game.SinglePlayer() then
        net.Start("arccw_sp_reloadlangs")
        net.Broadcast()
    end
end, nil, "Reloads all language files.")

if game.SinglePlayer() then
    net.Receive("arccw_sp_reloadlangs", function()
        ArcCW.LoadLanguages()
    end)
end
