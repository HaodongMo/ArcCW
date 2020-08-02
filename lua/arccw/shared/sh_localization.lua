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
            print(i, v)
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

ArcCW.LangTable = {
    ["en"] = {
        -- You can translate the trivia of any arbitrary weapon or attachment by adding the phrase ["desc.class_name"]
        -- Similarly, you can translate attachment and weapon names with ["name.class_name"]
        -- When translating weapon names, append .true for truename, like ["name.arccw_p228.true"]
        -- Example: {["desc.fcg_auto"] = "blah blah blah automatic firemode", ["name.fcg_auto"] = "Auto But Cooler"}

        -- Not a translate string, but in case a language needs its own font
        ["default_font"] = "Bahnschrift",

        -- Attachment Slots
        ["attslot.optic"] = "Optic",
        ["attslot.bkoptic"] = "Backup Optic",
        ["attslot.muzzle"] = "Muzzle",
        ["attslot.barrel"] = "Barrel",
        ["attslot.choke"] = "Choke",
        ["attslot.underbarrel"] = "Underbarrel",
        ["attslot.tactical"] = "Tactical",
        ["attslot.grip"] = "Grip",
        ["attslot.stock"] = "Stock",
        ["attslot.fcg"] = "Fire Group",
        ["attslot.ammo"] = "Ammo Type",
        ["attslot.perk"] = "Perk",
        ["attslot.charm"] = "Charm",
        ["attslot.skin"] = "Skin",
        ["attslot.noatt"] = "No Attachment",
        ["attslot.optic.default"] = "Iron Sights",
        ["attslot.muzzle.default"] = "Standard Muzzle",
        ["attslot.barrel.default"] = "Standard Barrel",
        ["attslot.choke.default"] = "Standard Choke",
        ["attslot.grip.default"] = "Standard Grip",
        ["attslot.stock.default"] = "Standard Stock",
        ["attslot.stock.none"] = "No Stock",
        ["attslot.fcg.default"] = "Standard FCG",

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
        ["class.shotgun"] = "Shotgun",
        ["class.assaultcarbine"] = "Assault Carbine",
        ["class.carbine"] = "Carbine",
        ["class.assaultrifle"] = "Assault Rifle",
        ["class.rifle"] = "Rifle",
        ["class.battlerifle"] = "Battle Rifle",
        ["class.dmr"] = "DMR",
        ["class.sniperrifle"] = "Sniper Rifle",
        ["class.antimaterielrifle"] = "Antimateriel Rifle",
        ["class.rocketlauncher"] = "Rocket Launcher",
        ["class.grenade"] = "Hand Grenade",
        ["class.melee"] = "Melee Weapon",

        -- UI
        ["ui.savepreset"] = "Save Preset",
        ["ui.loadpreset"] = "Load Preset",
        ["ui.stats"] = "Stats",
        ["ui.trivia"] = "Trivia",
        ["ui.tttequip"] = "TTT Equipment",
        ["ui.tttchat"] = "TTT Quickchat",
        ["ui.position"] = "POSITION",
        ["ui.positives"] = "POSITIVES:",
        ["ui.negatives"] = "NEGATIVES:",
        ["ui.information"] = "INFORMATION:",

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

        -- Autostats
        ["autostat.bipodrecoil"] = "Recoil in bipod",
        ["autostat.bipoddisp"] = "Dispersion in bipod",
        ["autostat.damage"] = "Close range damage",
        ["autostat.damagemin"] = "Long range damage",
        ["autostat.range"] = "Range",
        ["autostat.penetration"] = "Penetration",
        ["autostat.muzzlevel"] = "Muzzle velocity",
        ["autostat.meleetime"] = "Melee attack time",
        ["autostat.meleedamage"] = "Melee damage",
        ["autostat.meleerange"] = "Melee range",
        ["autostat.recoil"] = "Recoil",
        ["autostat.recoilside"] = "Horizontal recoil",
        ["autostat.firerate"] = "Fire rate",
        ["autostat.precision"] = "Imprecision",
        ["autostat.hipdisp"] = "Hip fire spread",
        ["autostat.sightdisp"] = "Sighted spread",
        ["autostat.movedisp"] = "Moving accuracy",
        ["autostat.shootvol"] = "Weapon volume",
        ["autostat.speedmult"] = "Movement speed",
        ["autostat.sightspeed"] = "Sighted strafe speed",
        ["autostat.reloadtime"] = "Reload time",
        ["autostat.drawtime"] = "Draw time",
        ["autostat.sighttime"] = "Sight time",
        ["autostat.cycletime"] = "Cycle time",
        ["autostat.magextender"] = "Extended magazine size",
        ["autostat.magreducer"] = "Reduced magazine size",
        ["autostat.bipod"] = "Can use Bipod",
        ["autostat.holosight"] = "Precision sight picture",
        ["autostat.zoom"] = "Increased zoom",
        ["autostat.glint"] = "Visible scope glint",
        ["autostat.thermal"] = "Thermal vision",
        ["autostat.silencer"] = "Suppresses firing sound",

        -- TTT
        ["ttt.roundinfo"] = "ArcCW Configuration",
        ["ttt.roundinfo.replace"] = "Auto-replace TTT weapons",
        ["ttt.roundinfo.cmode"] = "Customize Mode:",
        ["ttt.roundinfo.cmode0"] = "No Restrictions",
        ["ttt.roundinfo.cmode1"] = "Restricted",
        ["ttt.roundinfo.cmode2"] = "Pre-game only",
        ["ttt.roundinfo.cmode3"] = "T/D only",

        ["ttt.roundinfo.attmode"] = "Attachment Mode:",
        ["ttt.roundinfo.free"] = "Free",
        ["ttt.roundinfo.locking"] = "Locking",
        ["ttt.roundinfo.inv"] = "Inventory",
        ["ttt.roundinfo.persist"] = "Persistent",
        ["ttt.roundinfo.drop"] = "Drop on death",
        ["ttt.roundinfo.inv"] = "Inventory",
        ["ttt.roundinfo.pickx"] = "Pick",

        ["ttt.roundinfo.bmode"] = "Attachment Info on Body:",
        ["ttt.roundinfo.bmode0"] = "Unavailable",
        ["ttt.roundinfo.bmode1"] = "Detectives Only",
        ["ttt.roundinfo.bmode2"] = "Available",

        ["ttt.roundinfo.amode"] = "Ammo Explosion:",
        ["ttt.roundinfo.amode-1"] = "Disabled",
        ["ttt.roundinfo.amode0"] = "Simple",
        ["ttt.roundinfo.amode1"] = "Frag",
        ["ttt.roundinfo.amode2"] = "Full",
        ["ttt.roundinfo.achain"] = "Chain explosions",

        ["ttt.bodyatt.found"] = "You think the murder weapon",
        ["ttt.bodyatt.founddet"] = "With your detective skills, you deduce the murder weapon",
        ["ttt.bodyatt.att1"] = " had {att} installed.",
        ["ttt.bodyatt.att2"] = " had {att1} and {att2} installed.",
        ["ttt.bodyatt.att3"] = " had these attachments: ",

        ["ttt.attachments"] = " Attachment(s): ", -- Used in TTT2 TargetID
        ["ttt.ammo"] = "Ammo: ", -- Used in TTT2 TargetID
    },
}

hook.Run("ArcCW_LocalizationLoaded")