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
function ArcCW.GetTranslation(phrase, lang)
    if phrase == nil or phrase == "" then return nil end
    if not lang then
        lang = string.lower(GetConVar("gmod_language"):GetString())
    end
    if not lang or lang == "" or not ArcCW.LangTable[lang] or not ArcCW.LangTable[lang][phrase] then
        lang = "en"
    end
    if ArcCW.LangTable[lang][phrase] then
        return ArcCW.LangTable[lang][phrase], lang
    end
    return nil
end

-- Attempts to translate a string (could be either a raw string or a phrase).
-- If fail, return the string itself.
function ArcCW.TryTranslation(str, lang)
    if str == nil or str == "" then return nil end
    local phrase = ArcCW.GetPhraseFromString(str)
    if not phrase then return str end

    return ArcCW.GetTranslation(phrase, lang) or str
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
        -- Similarly, you can translate attachment and weapoon names with ["name.class_name"]
        -- Example: {["desc.fcg_auto"] = "blah blah blah automatic firemode", ["name.arccw_p228"] = "P228 But Cooler"}

        -- Not a translate string, but in case a language needs its own font
        ["default_font"] = "Bahnschrift",

        -- Attachment Slots
        ["attslot.optic"] = "Optic",
        ["attslot.bkoptic"] = "Backup Optic",
        ["attslot.muzzle"] = "Muzzle",
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
    },
    ["zh-cn"] = {
        ["attslot.optic"] = "准镜",
        ["attslot.bkoptic"] = "备用准镜",
        ["attslot.muzzle"] = "枪口",
        ["attslot.underbarrel"] = "下挂",
        ["attslot.tactical"] = "侧挂",
        ["attslot.grip"] = "握把",
        ["attslot.stock"] = "枪托",
        ["attslot.fcg"] = "火控",
        ["attslot.ammo"] = "弹药",
        ["attslot.perk"] = "能力",
        ["attslot.charm"] = "挂件",
        ["attslot.skin"] = "皮肤",
        ["attslot.noatt"] = "无",
        ["attslot.optic.default"] = "机械瞄具",
        ["attslot.muzzle.default"] = "标准枪管",
        ["attslot.grip.default"] = "标准握把",
        ["attslot.stock.default"] = "标准枪托",
        ["attslot.stock.none"] = "无枪托",
        ["attslot.fcg.default"] = "标准火控",

        ["trivia.class"] = "枪种",
        ["trivia.year"] = "生产年份",
        ["trivia.mechanism"] = "内部机制",
        ["trivia.calibre"] = "口径",
        ["trivia.ammo"] = "弹药类型",
        ["trivia.country"] = "生产国家",
        ["trivia.manufacturer"] = "生产商",
        ["trivia.clipsize"] = "弹夹容量",
        ["trivia.precision"] = "准度",
        ["trivia.noise"] = "噪音",
        ["trivia.recoil"] = "有效后坐力",
        ["trivia.penetration"] = "穿透力",
        ["trivia.firerate"] = "射速",
        ["trivia.fusetime"] = "引线",

        ["class.pistol"] = "手枪",
        ["class.revolver"] = "左轮",
        ["class.machinepistol"] = "微型冲锋枪",
        ["class.smg"] = "冲锋枪",
        ["class.pdw"] = "个人防卫武器",
        ["class.shotgun"] = "霰弹枪",
        ["class.assaultcarbine"] = "突击卡宾枪",
        ["class.carbine"] = "卡宾枪",
        ["class.assaultrifle"] = "突击步枪",
        ["class.rifle"] = "步枪",
        ["class.battlerifle"] = "战斗步枪",
        ["class.dmr"] = "精准射手步枪",
        ["class.sniperrifle"] = "狙击步枪",
        ["class.antimaterielrifle"] = "反器材步枪",
        ["class.rocketlauncher"] = "火箭发射器",
        ["class.grenade"] = "手榴弹",
        ["class.melee"] = "近战武器",

        ["ui.savepreset"] = "保存预设",
        ["ui.loadpreset"] = "读取预设",
        ["ui.stats"] = "属性",
        ["ui.trivia"] = "简介",
        ["ui.tttequip"] = "TTT 商店",
        ["ui.tttchat"] = "TTT 消息",
        ["ui.positives"] = "优点:",
        ["ui.negatives"] = "缺点:",
        ["ui.information"] = "细节:",

        ["stat.stat"] = "属性",
        ["stat.original"] = "原始",
        ["stat.current"] = "当前",
        ["stat.damage"] = "近距离伤害",
        ["stat.damage.tooltip"] = "How much damage this weapon does at point blank.",
        ["stat.damagemin"] = "远距离伤害",
        ["stat.damagemin.tooltip"] = "How much damage this weapon does beyond its range.",
        ["stat.range"] = "射程",
        ["stat.range.tooltip"] = "The distance between which close range damage turns to long range damage, in meters.",
        ["stat.firerate"] = "射速",
        ["stat.firerate.tooltip"] = "The rate at which this weapon cycles at, in rounds per minute.",
        ["stat.firerate.manual"] = "手动",
        ["stat.capacity"] = "装填量",
        ["stat.capacity.tooltip"] = "How many rounds this weapon can hold.",
        ["stat.precision"] = "精准度",
        ["stat.precision.tooltip"] = "How precise the weapon is when still and aimed, in minutes of arc.",
        ["stat.hipdisp"] = "扫射扩散",
        ["stat.hipdisp.tooltip"] = "How much imprecision is added when the weapon is hipfired.",
        ["stat.movedisp"] = "移动扩散",
        ["stat.movedisp.tooltip"] = "How much imprecision is added when the weapon is used while moving.",
        ["stat.recoil"] = "后坐力",
        ["stat.recoil.tooltip"] = "The amount of kick produced each shot.",
        ["stat.recoilside"] = "水平后坐力",
        ["stat.recoilside.tooltip"] = "The amount of horizontal kick produced each shot.",
        ["stat.sighttime"] = "瞄准耗时",
        ["stat.sighttime.tooltip"] = "How long does it take to transition from or to sprinting and sights with this weapon.",
        ["stat.speedmult"] = "移动速度",
        ["stat.speedmult.tooltip"] = "The speed at which you move with the gun, in percentage of original speed.",
        ["stat.sightspeed"] = "瞄准移动速度",
        ["stat.sightspeed.tooltip"] = "The additional slowdown applied when you are moving with sights down.",
        ["stat.meleedamage"] = "近战伤害",
        ["stat.meleedamage.tooltip"] = "How much damage the melee bash causes.",
        ["stat.meleetime"] = "近战耗时",
        ["stat.meleetime.tooltip"] = "The time it takes to do a melee bash.",
        ["stat.shootvol"] = "开火音量",
        ["stat.shootvol.tooltip"] = "How loud the weapon is, in decibels. Louder weapons can be heard from further away.",
        ["stat.barrellen"] = "枪管长度",
        ["stat.barrellen.tooltip"] = "The length of the barrel, in Hammer Units. Long barrels will be blocked by walls more easily.",
        ["stat.pen"] = "穿透力",
        ["stat.pen.tooltip"] = "How much material this weapon can penetrate.",

        ["autostat.bipodrecoil"] = "两脚架后座力",
        ["autostat.bipoddisp"] = "两脚架扩散",
        ["autostat.damage"] = "近距离伤害",
        ["autostat.damagemin"] = "远距离伤害",
        ["autostat.range"] = "射程",
        ["autostat.penetration"] = "穿透力",
        ["autostat.muzzlevel"] = "出膛速度",
        ["autostat.meleetime"] = "近战耗时",
        ["autostat.meleedamage"] = "近战伤害",
        ["autostat.meleerange"] = "近战距离",
        ["autostat.recoil"] = "后坐力",
        ["autostat.recoilside"] = "水平后坐力",
        ["autostat.firerate"] = "射速",
        ["autostat.precision"] = "不准度",
        ["autostat.hipdisp"] = "扫射扩散",
        ["autostat.sightdisp"] = "瞄准扩散",
        ["autostat.movedisp"] = "移动扩散",
        ["autostat.shootvol"] = "开火音量",
        ["autostat.speedmult"] = "移动速度",
        ["autostat.sightspeed"] = "瞄准移动速度",
        ["autostat.reloadtime"] = "装填耗时",
        ["autostat.drawtime"] = "准备耗时",
        ["autostat.sighttime"] = "瞄准耗时",
        ["autostat.cycletime"] = "上膛耗时",
    }
}