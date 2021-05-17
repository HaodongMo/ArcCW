L = {}

-- not a translate string, but in case a language needs its own font
L["default_font"] = "Bahnschrift"

-- Attachment Slots
L["attslot.optic"] = "Ótico"
L["attslot.bkoptic"] = "Ótico de Reserva"
L["attslot.muzzle"] = "Boca do Cano"
L["attslot.barrel"] = "Cano"
L["attslot.choke"] = "Afogador"
L["attslot.underbarrel"] = "Baixo-do-Cano"
L["attslot.tactical"] = "Tático"
L["attslot.grip"] = "Cabo"
L["attslot.stock"] = "Coronha"
L["attslot.fcg"] = "Fogo Seletivo"
L["attslot.ammo"] = "Tipo de Munição"
L["attslot.perk"] = "Vantagem"
L["attslot.charm"] = "Penduricalho"
L["attslot.skin"] = "Camada Externa"
L["attslot.noatt"] = "Sem Acessório"
L["attslot.optic.default"] = "Mira de Ferro"
L["attslot.muzzle.default"] = "Boca do Cano Padrão"
L["attslot.barrel.default"] = "Cano Padrão"
L["attslot.choke.default"] = "Afogador Padrão"
L["attslot.grip.default"] = "Cabo Padrão"
L["attslot.stock.default"] = "Coronha Padrão"
L["attslot.stock.none"] = "Sem Coronha"
L["attslot.fcg.default"] = "Fogo Seletivo Padrão"

-- Trivia
L["trivia.class"] = "Classe"
L["trivia.year"] = "Ano"
L["trivia.mechanism"] = "Mecanismo"
L["trivia.calibre"] = "Calibre"
L["trivia.ammo"] = "Tipo de Munição"
L["trivia.country"] = "País"
L["trivia.manufacturer"] = "Fabricante"
L["trivia.clipsize"] = "Capacidade do Carregador"
L["trivia.precision"] = "Precisão"
L["trivia.noise"] = "Barulho"
L["trivia.recoil"] = "Coice Vertical"
L["trivia.penetration"] = "Penetração"
L["trivia.firerate"] = "Taxa de Fogo"
L["trivia.fusetime"] = "Tempo do Pavil"

-- Class
L["class.pistol"] = "Pistola"
L["class.revolver"] = "Revolver"
L["class.machinepistol"] = "Pistola Automática"
L["class.smg"] = "Sub-Metralhadora"
L["class.pdw"] = "Arma de Defesa Pessoal"
L["class.shotgun"] = "Espingarda"
L["class.assaultcarbine"] = "Carabina de Assalto"
L["class.carbine"] = "Carabina"
L["class.assaultrifle"] = "Fuzil de Assalto"
L["class.rifle"] = "Fuzil"
L["class.battlerifle"] = "Fuzil de Batalha"
L["class.dmr"] = "F.A.D"
L["class.sniperrifle"] = "Fuzil de Precisão"
L["class.antimaterielrifle"] = "Fuzil Anti-Equipamento"
L["class.rocketlauncher"] = "Lança Foguetes"
L["class.grenade"] = "Granada de Mão"
L["class.melee"] = "Arma Corpo-a-Corpo"

-- UI
L["ui.savepreset"] = "Save Preset"
L["ui.loadpreset"] = "Load Preset"
L["ui.stats"] = "Stats"
L["ui.trivia"] = "Trivia"
L["ui.tttequip"] = "Equipment"
L["ui.tttchat"] = "Quickchat"
L["ui.position"] = "POSITION"
L["ui.positives"] = "POSITIVES:"
L["ui.negatives"] = "NEGATIVES:"
L["ui.information"] = "INFORMATION:"

-- Stats
L["stat.stat"] = "Stat" -- Used on first line of stat page
L["stat.original"] = "Original"
L["stat.current"] = "Current"
L["stat.damage"] = "Close Range Damage"
L["stat.damage.tooltip"] = "How much damage this weapon does at point blank."
L["stat.damagemin"] = "Long Range Damage"
L["stat.damagemin.tooltip"] = "How much damage this weapon does beyond its range."
L["stat.range"] = "Range"
L["stat.range.tooltip"] = "The distance between which close range damage turns to long range damage, in meters."
L["stat.firerate"] = "Fire Rate"
L["stat.firerate.tooltip"] = "The rate at which this weapon cycles at, in rounds per minute."
L["stat.firerate.manual"] = "MANUAL" -- Shown instead of RPM when it is a manual weapon
L["stat.capacity"] = "Capacity"
L["stat.capacity.tooltip"] = "How many rounds this weapon can hold."
L["stat.precision"] = "Precision"
L["stat.precision.tooltip"] = "How precise the weapon is when still and aimed, in minutes of arc."
L["stat.hipdisp"] = "Hip Dispersion"
L["stat.hipdisp.tooltip"] = "How much imprecision is added when the weapon is hipfired."
L["stat.movedisp"] = "Moving Accuracy"
L["stat.movedisp.tooltip"] = "How much imprecision is added when the weapon is used while moving."
L["stat.recoil"] = "Recoil"
L["stat.recoil.tooltip"] = "The amount of kick produced each shot."
L["stat.recoilside"] = "Side Recoil"
L["stat.recoilside.tooltip"] = "The amount of horizontal kick produced each shot."
L["stat.sighttime"] = "Handling Time"
L["stat.sighttime.tooltip"] = "How long does it take to transition from or to sprinting and sights with this weapon."
L["stat.speedmult"] = "Move Speed"
L["stat.speedmult.tooltip"] = "The speed at which you move with the gun, in percentage of original speed."
L["stat.sightspeed"] = "Sighted Strafe Speed"
L["stat.sightspeed.tooltip"] = "The additional slowdown applied when you are moving with sights down."
L["stat.meleedamage"] = "Bash Damage"
L["stat.meleedamage.tooltip"] = "How much damage the melee bash causes."
L["stat.meleetime"] = "Bash Time"
L["stat.meleetime.tooltip"] = "The time it takes to do a melee bash."
L["stat.shootvol"] = "Firing Volume"
L["stat.shootvol.tooltip"] = "How loud the weapon is, in decibels. Louder weapons can be heard from further away."
L["stat.barrellen"] = "Barrel Length"
L["stat.barrellen.tooltip"] = "The length of the barrel, in Hammer Units. Long barrels will be blocked by walls more easily."
L["stat.pen"] = "Penetration"
L["stat.pen.tooltip"] = "How much material this weapon can penetrate."

-- Autostats
L["autostat.bipodrecoil"] = "Recoil in bipod"
L["autostat.bipoddisp"] = "Dispersion in bipod"
L["autostat.damage"] = "Close range damage"
L["autostat.damagemin"] = "Long range damage"
L["autostat.damageboth"] = "Damage" -- When damage and damagemin are the same value
L["autostat.range"] = "Range"
L["autostat.penetration"] = "Penetration"
L["autostat.muzzlevel"] = "Muzzle velocity"
L["autostat.meleetime"] = "Melee attack time"
L["autostat.meleedamage"] = "Melee damage"
L["autostat.meleerange"] = "Melee range"
L["autostat.recoil"] = "Recoil"
L["autostat.recoilside"] = "Horizontal recoil"
L["autostat.firerate"] = "Fire rate"
L["autostat.precision"] = "Imprecision"
L["autostat.hipdisp"] = "Hip fire spread"
L["autostat.sightdisp"] = "Sighted spread"
L["autostat.movedisp"] = "Moving spread"
L["autostat.jumpdisp"] = "Jumping spread"
L["autostat.barrellength"] = "Barrel length"
L["autostat.shootvol"] = "Weapon volume"
L["autostat.speedmult"] = "Movement speed"
L["autostat.sightspeed"] = "Sighted strafe speed"
L["autostat.shootspeed"] = "Shooting movement speed"
L["autostat.reloadtime"] = "Reload time"
L["autostat.drawtime"] = "Draw time"
L["autostat.sighttime"] = "Handling"
L["autostat.cycletime"] = "Cycle time"
L["autostat.magextender"] = "Extended magazine size"
L["autostat.magreducer"] = "Reduced magazine size"
L["autostat.bipod"] = "Can use Bipod"
L["autostat.holosight"] = "Precision sight picture"
L["autostat.zoom"] = "Increased zoom"
L["autostat.glint"] = "Visible scope glint"
L["autostat.thermal"] = "Thermal vision"
L["autostat.silencer"] = "Suppresses firing sound"
L["autostat.norandspr"] = "No random spread"
L["autostat.sway"] = "Aim sway"
L["autostat.heatcap"] = "Heat capacity"
L["autostat.heatfix"] = "Overheat fix time"
L["autostat.heatdelay"] = "Heat recovery delay"
L["autostat.heatdrain"] = "Heat recovery rate"

-- TTT
L["ttt.roundinfo"] = "ArcCW Configuration"
L["ttt.roundinfo.replace"] = "Auto-replace TTT weapons"
L["ttt.roundinfo.cmode"] = "Customize Mode:"
L["ttt.roundinfo.cmode0"] = "No Restrictions"
L["ttt.roundinfo.cmode1"] = "Restricted"
L["ttt.roundinfo.cmode2"] = "Pre-game only"
L["ttt.roundinfo.cmode3"] = "T/D only"

L["ttt.roundinfo.attmode"] = "Attachment Mode:"
L["ttt.roundinfo.free"] = "Free"
L["ttt.roundinfo.locking"] = "Locking"
L["ttt.roundinfo.inv"] = "Inventory"
L["ttt.roundinfo.persist"] = "Persistent"
L["ttt.roundinfo.drop"] = "Drop on death"
L["ttt.roundinfo.inv"] = "Inventory"
L["ttt.roundinfo.pickx"] = "Pick"

L["ttt.roundinfo.bmode"] = "Attachment Info on Body:"
L["ttt.roundinfo.bmode0"] = "Unavailable"
L["ttt.roundinfo.bmode1"] = "Detectives Only"
L["ttt.roundinfo.bmode2"] = "Available"

L["ttt.roundinfo.amode"] = "Ammo Explosion:"
L["ttt.roundinfo.amode-1"] = "Disabled"
L["ttt.roundinfo.amode0"] = "Simple"
L["ttt.roundinfo.amode1"] = "Frag"
L["ttt.roundinfo.amode2"] = "Full"
L["ttt.roundinfo.achain"] = "Chain explosions"

L["ttt.bodyatt.found"] = "You think the murder weapon"
L["ttt.bodyatt.founddet"] = "With your detective skills, you deduce the murder weapon"
L["ttt.bodyatt.att1"] = " had {att} installed."
L["ttt.bodyatt.att2"] = " had {att1} and {att2} installed."
L["ttt.bodyatt.att3"] = " had these attachments: "

L["ttt.attachments"] = " Attachment(s): " -- Used in TTT2 TargetID
L["ttt.ammo"] = "Ammo: " -- Used in TTT2 TargetID

-- Shit that used to be in CS+ why
L["info.togglesight"] = "Double press +USE to toggle sights"
L["info.toggleubgl"] = "Double press +ZOOM to toggle underbarrel"
L["pro.ubgl"] = "Selectable underbarrel launcher"
L["pro.ubsg"] = "Selectable underbarrel shotgun"
L["con.obstruction"] = "May obstruct sights"
L["autostat.underwater"] = "Shoot underwater"
L["autostat.sprintshoot"] = "Shoot while sprinting"

-- Incompatibility Menu
L["incompatible.title"] = "ArcCW: INCOMPATIBLE ADDONS"
L["incompatible.line1"] = "You have some addons that are known to not work with ArcCW."
L["incompatible.line2"] = "Disable them or expect broken behavior!"
L["incompatible.confirm"] = "Acknowledge"
L["incompatible.wait"] = "Wait {time}s"
L["incompatible.never"] = "Never warn me again"
L["incompatible.never.hover"] = "Are you absolutely sure you understand the consequences?"
L["incompatible.never.confirm"] = "You have chosen to never show incompatiblity warnings again. If you encounter errors or broken behaviour, it is your own responsibility."

-- 2020-12-11
L["hud.hp"] = "HP: " -- Used in default HUD
L["fcg.safe"] = "SAFE"
L["fcg.semi"] = "SEMI"
L["fcg.auto"] = "AUTO"
L["fcg.burst"] = "%dBST"
L["fcg.ubgl"] = "UBGL"

-- 2021-01-14
L["ui.toggle"] = "TOGGLE"
L["ui.whenmode"] = "When %s"
L["ui.modex"] = "Mode %s"

-- 2021-01-25
L["attslot.magazine"] = "Magazine"

-- 2021-03-13
L["trivia.damage"] = "Damage"
L["trivia.range"] = "Range"
L["trivia.attackspersecond"] = "Attacks Per Second"
L["trivia.description"] = "Description"
L["trivia.meleedamagetype"] = "Damage Type"

-- Units
L["unit.rpm"] = "RPM"
L["unit.moa"] = "MOA"
L["unit.mm"] = "mm"
L["unit.db"] = "dB"
L["unit.bce"] = "BC"
L["unit.aps"] = "APS"

-- melee damage types
L["dmg.generic"] = "Unarmed"
L["dmg.bullet"] = "Piercing"
L["dmg.slash"] = "Slashing"
L["dmg.club"] = "Blunt"
L["dmg.shock"] = "Shock"

L["ui.presets"] = "Presets"
L["ui.customize"] = "Customize"
L["ui.inventory"] = "Inventory"

-- 2021-05-05
L["ui.gamemode_buttons"] = "Gamemode-specific commands"
L["ui.gamemode_usehint"] = "You can hold USE to access original keybinds."
L["ui.darkrpdrop"] = "Drop Weapon"
L["ui.noatts"] = "You have no attachments"
L["ui.noatts_slot"] = "You have no attachments for this slot"
L["ui.lockinv"] = "These attachments are unlocked for all weapons."
L["autostat.ammotype"] = "Converts weapon ammo type to %s"

-- 2021-05-08
L["autostat.rangemin"] = "Minimum range"

-- 2021-05-13
L["autostat.malfunctionmean"] = "Reliability"
L["ui.heat"] = "HEAT"
L["ui.jammed"] = "JAMMED"

-- 2021-05-15

L["trivia.muzzlevel"] = "Muzzle Velocity"
L["unit.mps"] = "m/s"
L["unit.lbfps"] = "lb-fps"
L["trivia.recoilside"] = "Horizontal Recoil"

-- You can translate the trivia of any arbitrary weapon or attachment by adding the phrase ["desc.class_name"]
-- Similarly, you can translate attachment and weapon names with ["name.class_name"]
-- When translating weapon names, append .true for truename, like ["name.arccw_p228.true"]
-- Example: {L["desc.fcg_auto"] = "blah blah blah automatic firemode" ["name.fcg_auto"] = "Auto But Cooler"}
