L = {}
STL = {}

-- not a translate string, but in case a language needs its own font
L["default_font"] = "Bahnschrift"

-- Attachment Slots
L["attslot.optic"] = "Optic"
L["attslot.bkoptic"] = "Backup Optic"
L["attslot.muzzle"] = "Muzzle"
L["attslot.barrel"] = "Barrel"
L["attslot.choke"] = "Choke"
L["attslot.underbarrel"] = "Underbarrel"
L["attslot.tactical"] = "Tactical"
L["attslot.grip"] = "Grip"
L["attslot.stock"] = "Stock"
L["attslot.fcg"] = "Fire Group"
L["attslot.ammo"] = "Ammo Type"
L["attslot.perk"] = "Perk"
L["attslot.charm"] = "Charm"
L["attslot.skin"] = "Skin"
L["attslot.noatt"] = "No Attachment"
L["attslot.optic.default"] = "Iron Sights"
L["attslot.muzzle.default"] = "Standard Muzzle"
L["attslot.barrel.default"] = "Standard Barrel"
L["attslot.choke.default"] = "Standard Choke"
L["attslot.grip.default"] = "Standard Grip"
L["attslot.stock.default"] = "Standard Stock"
L["attslot.stock.none"] = "No Stock"
L["attslot.fcg.default"] = "Standard FCG"

-- Trivia
L["trivia.class"] = "Class"
L["trivia.year"] = "Year"
L["trivia.mechanism"] = "Mechanism"
L["trivia.calibre"] = "Calibre"
L["trivia.ammo"] = "Ammo Type"
L["trivia.country"] = "Country"
L["trivia.manufacturer"] = "Manufacturer"
L["trivia.clipsize"] = "Magazine Capacity"
L["trivia.precision"] = "Precision"
L["trivia.noise"] = "Noise"
L["trivia.recoil"] = "Vertical Recoil"
L["trivia.penetration"] = "Penetration"
L["trivia.firerate"] = "Fire Rate"
L["trivia.firerate_burst"] = "Burst Fire Rate"
L["trivia.fusetime"] = "Fuse Time"

-- Class
L["class.pistol"] = "Pistol"
L["class.revolver"] = "Revolver"
L["class.machinepistol"] = "Machine Pistol"
L["class.smg"] = "Submachine Gun"
L["class.pdw"] = "Personal Defense Weapon"
L["class.shotgun"] = "Shotgun"
L["class.assaultcarbine"] = "Assault Carbine"
L["class.carbine"] = "Carbine"
L["class.assaultrifle"] = "Assault Rifle"
L["class.rifle"] = "Rifle"
L["class.battlerifle"] = "Battle Rifle"
L["class.dmr"] = "DMR"
L["class.sniperrifle"] = "Sniper Rifle"
L["class.antimaterielrifle"] = "Antimateriel Rifle"
L["class.rocketlauncher"] = "Rocket Launcher"
L["class.grenade"] = "Hand Grenade"
L["class.melee"] = "Melee Weapon"

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
L["fcg.safe"] = "Safety"
L["fcg.semi"] = "Semi-auto"
L["fcg.auto"] = "Automatic"
L["fcg.burst"] = "%d-round burst"
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

--2021-05-27
L["ui.pickx"] = "Attachments: %d/%d"
L["ui.ballistics"] = "Ballistics"

L["ammo.pistol"] = "Pistol Ammo"
L["ammo.357"] = "Magnum Ammo"
L["ammo.smg1"] = "Carbine Ammo"
L["ammo.ar2"] = "Rifle Ammo"
L["ammo.buckshot"] = "Shotgun Ammo"
L["ammo.sniperpenetratedround"] = "Sniper Ammo"
L["ammo.smg1_grenade"] = "Rifle Grenades"

--2021-05-31
L["ui.nodata"] = "No Data"
L["ui.createpreset"] = "Create"
L["ui.deletepreset"] = "Delete"

--2021-06-09 nice
L["autostat.clipsize"] = "%d-round magazine capacity"

--2021-06-30
L["autostat.bipod2"] = "Allows bipod (-%d%% Dispersion, -%d%% Recoil)"
L["autostat.nobipod"] = "Disables bipod"

--2021-07-01
L["fcg.safe2"] = "Lowered"
L["fcg.dact"] = "Double-action"
L["fcg.sact"] = "Single-action"
L["fcg.bolt"] = "Bolt-action"
L["fcg.pump"] = "Pump-action"
L["fcg.lever"] = "Lever-action"
L["fcg.manual"] = "Manual-action"
L["fcg.break"] = "Break-action"
L["fcg.sngl"] = "Single"
L["fcg.both"] = "Both"

--2021-08-11
L["autostat.clipsize.mod"] = "Magazine capacity" -- used for Add_ClipSize and Mult_ClipSize

--2021-08-22
L["trivia.recoilscore"] = "Recoil Score (Lower is better)"
L["fcg.safe.abbrev"] = "SAFE"
L["fcg.semi.abbrev"] = "SEMI"
L["fcg.auto.abbrev"] = "AUTO"
L["fcg.burst.abbrev"] = "%d-BST"
L["fcg.ubgl.abbrev"] = "UBGL"
L["fcg.safe2.abbrev"] = "LOW"
L["fcg.dact.abbrev"] = "DACT"
L["fcg.sact.abbrev"] = "SACT"
L["fcg.bolt.abbrev"] = "BOLT"
L["fcg.pump.abbrev"] = "PUMP"
L["fcg.lever.abbrev"] = "LEVER"
L["fcg.manual.abbrev"] = "MANUAL"
L["fcg.break.abbrev"] = "BREAK"
L["fcg.sngl.abbrev"] = "SNGL"
L["fcg.both.abbrev"] = "BOTH"

-- 2021-10-10
STL["lowered"] = "fcg.safe2"
STL["double-action"] = "fcg.dact"
STL["single-action"] = "fcg.sact"
STL["bolt-action"] = "fcg.bolt"
STL["pump-action"] = "fcg.pump"
STL["lever-action"] = "fcg.lever"
STL["manual-action"] = "fcg.manual"
STL["break-action"] = "fcg.break"
--STL["single"] = "fcg.sngl"
--STL["both"] = "fcg.both"

--[[]
You can translate the trivia of any arbitrary weapon or attachment by adding the phrase ["desc.class_name"]
Similarly, you can translate attachment and weapon names with ["name.class_name"]
When translating weapon names, append .true for truename, like ["name.arccw_p228.true"]
Example:
 L["desc.fcg_auto"] = "blah blah blah automatic firemode"
 L["name.fcg_auto"] = "Auto But Cooler"
You can also translate custom firemodes with "fcg.FIREMODE_NAME"
]]