CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 0
CLGAMEMODESUBMENU.title = "ArcCW"

local TTTPanel = {
    { type = "h", text = "#arccw.ttt_serverhelp" },
    { type = "b", text = "#arccw.cvar.ttt_replace", var = "arccw_ttt_replace", sv = true },
    { type = "b", text = "#arccw.cvar.ammo_replace", var = "arccw_ttt_ammo", sv = true },
    { type = "b", text = "#arccw.cvar.ttt_atts", var = "arccw_ttt_atts", sv = true },
    { type = "o", text = "#arccw.cvar.ttt_customizemode", var = "arccw_ttt_customizemode", sv = true,
            choices = {[0] = "#arccw.cvar.ttt_customizemode.0", [1] = "#arccw.cvar.ttt_customizemode.1", [2] = "#arccw.cvar.ttt_customizemode.2", [3] = "#arccw.cvar.ttt_customizemode.3"}},
    { type = "o", text = "#arccw.cvar.ttt_bodyattinfo", var = "arccw_ttt_bodyattinfo", sv = true,
            choices = {[0] = "#arccw.combobox.disabled", [1] = "#arccw.cvar.ttt_bodyattinfo.1", [2] = "#arccw.cvar.ttt_bodyattinfo.2"}},
    { type = "c", text = "#arccw.cvar.ttt_bodyattinfo.help"},
}

local serverpanels = {
    "ArcCW_Options_Server",
    "ArcCW_Options_Atts",
    "ArcCW_Options_Ammo",
    "ArcCW_Options_Mults",
    "ArcCW_Options_Bullet",
}

function CLGAMEMODESUBMENU:Populate(parent)
    ArcCW.TTT2_PopulateSettings(parent, "arccw.menus.ttt_server", TTTPanel)
    for _, pnlname in pairs(serverpanels) do
        local pnl = ArcCW.ClientMenus[pnlname]
        ArcCW.TTT2_PopulateSettings(parent, pnl.text, pnl.tbl)
    end
end