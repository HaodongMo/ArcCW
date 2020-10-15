--[[
    Panel table doc:
    id (any number) = data:
    type
    type args

    types:
    h - header                        text
    c - control help                  text
    b - checkbox                      text var
    i - integer slider                text var min max
    f - float slider (2 nums after .) text var min max
    m - color mixer                   text r g b a 
    p - press or button               text func
    t - textbox                       text string
    (you can add custom types in ArcCW.GeneratePanelElements's AddControl table)

    Generate elements via ArcCW.GeneratePanelElements:
    panel, panel table with data

    Add menu generation to ArcCW.ClientMenus:
    name = data:
    text - header text
    func - generator function
]]

local BulletPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "b", text = "#arccw.cvar.bullet_enable", var = "arccw_bullet_enable", sv = true },
    { type = "f", text = "#arccw.cvar.bullet_velocity", var = "arccw_bullet_velocity", min = 0, max = 100, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_gravity", var = "arccw_bullet_gravity", min = 0, max = 32000, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_drag", var = "arccw_bullet_drag", min = 0, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.bullet_lifetime", var = "arccw_bullet_lifetime", min = 1, max = 60, sv = true},
}

local ClientPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.automaticreload", var = "arccw_automaticreload" },
    { type = "c", text = "#arccw.cvar.automaticreload.desc" },
    { type = "b", text = "#arccw.cvar.toggleads", var = "arccw_toggleads" },
    { type = "b", text = "#arccw.cvar.altfcgkey", var = "arccw_altfcgkey" },
    { type = "b", text = "#arccw.cvar.altubglkey", var = "arccw_altubglkey" },
    { type = "b", text = "#arccw.cvar.altsafety", var = "arccw_altsafety" },
    { type = "b", text = "#arccw.cvar.autosave", var = "arccw_autosave" },
    { type = "c", text = "#arccw.cvar.autosave.desc" },
    { type = "b", text = "#arccw.cvar.embracetradition", var = "arccw_hud_embracetradition" },
    { type = "c", text = "#arccw.cvar.embracetradition.desc" },
    { type = "b", text = "#arccw.cvar.glare", var = "arccw_glare" },
    { type = "c", text = "#arccw.cvar.glare.desc" },
    { type = "b", text = "#arccw.cvar.shake", var = "arccw_shake" },
    { type = "c", text = "#arccw.cvar.shake_info" },
    { type = "b", text = "#arccw.cvar.2d3d", var = "arccw_2d3d" },
    { type = "c", text = "#arccw.cvar.2d3d_info" },
    { type = "t", text = "#arccw.cvar.language", var = "arccw_language"  },
    { type = "c", text = "#arccw.cvar.language_info" },
}

local PerformancePanel = {
    --{ type = "h", text = "#arccw.clientcfg" },
    { type = "h", text = "#arccw.performance" },
    { type = "b", text = "#arccw.cvar.cheapscopes", var = "arccw_cheapscopes" },
    { type = "c", text = "#arccw.cvar.cheapscopes.desc" },
    { type = "b", text = "#arccw.cvar.flatscopes", var = "arccw_flatscopes" },
    { type = "c", text = "#arccw.cvar.flatscopes.desc" },
    { type = "b", text = "#arccw.cvar.muzzleeffects", var = "arccw_muzzleeffects" },
    { type = "b", text = "#arccw.cvar.fastmuzzles", var = "arccw_fastmuzzles" },
    { type = "b", text = "#arccw.cvar.shelleffects", var = "arccw_shelleffects" },
    { type = "b", text = "#arccw.cvar.att_showothers", var = "arccw_att_showothers" },
    { type = "i", text = "#arccw.cvar.visibility", var = "arccw_visibility", min = -1, max = 32000},
    { type = "c", text = "#arccw.cvar.visibility.desc" },
    { type = "b", text = "#arccw.cvar.blur", var = "arccw_blur" },
    { type = "b", text = "#arccw.cvar.blur_toytown", var = "arccw_blur_toytown" },
    { type = "b", text = "#arccw.cvar.bullet_imaginary", var = "arccw_bullet_imaginary" },
    { type = "c", text = "#arccw.cvar.bullet_imaginary.desc" },
    { type = "f", text = "#arccw.cvar.shelltime", var = "arccw_shelltime", min = 0, max = 180 },
}

local ViewmodelPanel = {
    { type = "b", text = "#arccw.cvar.vm_coolsway", var = "arccw_vm_coolsway" },
    { type = "b", text = "#arccw.cvar.vm_coolview", var = "arccw_vm_coolview" },
    { type = "f", text = "#arccw.cvar.vm_sway_sprint", var = "arccw_vm_sway_sprint", min = 0, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_bob_sprint", var = "arccw_vm_bob_sprint", min = 0, max = 5 },
    { type = "h", text = "" },
    { type = "c", text = "#arccw.cvar.vm_offsetwarn" },
    { type = "f", text = "#arccw.cvar.vm_right", var = "arccw_vm_right", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_forward", var = "arccw_vm_forward", min = -5, max = 5 },
    { type = "f", text = "#arccw.cvar.vm_up", var = "arccw_vm_up", min = -5, max = 5 },
    { type = "c", text = "" },
    { type = "c", text = "#arccw.cvar.vm_swaywarn" },
    { type = "f", text = "#arccw.cvar.vm_lookxmult", var = "arccw_vm_lookxmult", min = -10, max = 10 },
    { type = "f", text = "#arccw.cvar.vm_lookymult", var = "arccw_vm_lookymult", min = -10, max = 10 },
    { type = "f", text = "#arccw.cvar.vm_accelmult", var = "arccw_vm_accelmult", min = 0.3, max = 3 },
    { type = "f", text = "#arccw.cvar.vm_swayxmult", var = "arccw_vm_swayxmult", min = -1, max = 1 },
    { type = "f", text = "#arccw.cvar.vm_swayymult", var = "arccw_vm_swayymult", min = -2, max = 2 },
    { type = "f", text = "#arccw.cvar.vm_swayzmult", var = "arccw_vm_swayzmult", min = -2, max = 2 },
    { type = "f", text = "#arccw.cvar.vm_swaywigglemult", var = "arccw_vm_swaywigglemult", min = -3, max = 3 },
    { type = "f", text = "#arccw.cvar.vm_swayspeedmult", var = "arccw_vm_swayspeedmult", min = 0, max = 3 },
    { type = "f", text = "#arccw.cvar.vm_swayrotatemult", var = "arccw_vm_swayrotatemult", min = -3, max = 3 },
    { type = "h", text = "" },
    { type = "c", text = "#arccw.cvar.vm_viewwarn" },
    { type = "f", text = "#arccw.cvar.vm_coolviewmult", var = "arccw_vm_coolview_mult", min = -10, max = 10 },
}

local HudPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.hud_showhealth", var = "arccw_hud_showhealth" },
    { type = "b", text = "#arccw.cvar.hud_showammo", var = "arccw_hud_showammo" },
    { type = "b", text = "#arccw.cvar.hud_3dfun", var = "arccw_hud_3dfun" },
    { type = "b", text = "#arccw.cvar.hud_forceshow", var = "arccw_hud_forceshow" },
    { type = "b", text = "#arccw.cvar.attinv_closeonhurt", var = "arccw_attinv_closeonhurt" },
    { type = "f", text = "#arccw.cvar.hudpos_deadzone_x", var = "arccw_hud_deadzone_x", min = 0, max = 1 },
    { type = "f", text = "#arccw.cvar.hudpos_deadzone_y", var = "arccw_hud_deadzone_y", min = 0, max = 1 },
    { type = "f", text = "#arccw.cvar.hudpos_size", var = "arccw_hud_size", min = 0, max = 1.5 },
    
    { type = "b", text = "#arccw.cvar.attinv_hideunowned", var = "arccw_attinv_hideunowned" },
    { type = "b", text = "#arccw.cvar.attinv_darkunowned", var = "arccw_attinv_darkunowned" },
    { type = "b", text = "#arccw.cvar.attinv_onlyinspect", var = "arccw_attinv_onlyinspect" },
    { type = "b", text = "#arccw.cvar.attinv_simpleproscons", var = "arccw_attinv_simpleproscons" },
}

local CrosshairPanel = {
    { type = "h", text = "#arccw.clientcfg" },
    { type = "b", text = "#arccw.cvar.crosshair", var = "arccw_crosshair" },
    { type = "f", text = "#arccw.cvar.crosshair_length", var = "arccw_crosshair_length", min = 0, max = 10 },
    { type = "f", text = "#arccw.cvar.crosshair_thickness", var = "arccw_crosshair_thickness", min = 0, max = 2 },
    { type = "f", text = "#arccw.cvar.crosshair_gap", var = "arccw_crosshair_gap", min = 0, max = 2 },
    { type = "b", text = "#arccw.cvar.crosshair_dot", var = "arccw_crosshair_dot" },
    { type = "b", text = "#arccw.cvar.crosshair_shotgun", var = "arccw_crosshair_shotgun" },
    { type = "b", text = "#arccw.cvar.crosshair_equip", var = "arccw_crosshair_equip" },
    { type = "b", text = "#arccw.cvar.crosshair_static", var = "arccw_crosshair_static" },
    { type = "b", text = "#arccw.cvar.crosshair_clump", var = "arccw_crosshair_clump" },
    { type = "b", text = "#arccw.cvar.crosshair_clump_outline", var = "arccw_crosshair_clump_outline" },
    { type = "b", text = "#arccw.cvar.crosshair_clump_always", var = "arccw_crosshair_clump_always" },
    { type = "m", text = "#arccw.cvar.crosshair_clr", r = "arccw_crosshair_clr_r", g = "arccw_crosshair_clr_g", b = "arccw_crosshair_clr_b", a = "arccw_crosshair_clr_a" },
    { type = "f", text = "#arccw.cvar.crosshair_outline", var = "arccw_crosshair_outline", min = 0, max = 4 },
    { type = "m", text = "#arccw.cvar.crosshair_outline_clr", r = "arccw_crosshair_outline_r", g = "arccw_crosshair_outline_g", b = "arccw_crosshair_outline_b", a = "arccw_crosshair_outline_a" },
    { type = "m", text = "#arccw.cvar.scope_clr", r = "arccw_scope_r", g = "arccw_scope_g", b = "arccw_scope_b" },
}

local ServerPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "b", text = "#arccw.cvar.enable_penetration", var = "arccw_enable_penetration", sv = true },
    { type = "b", text = "#arccw.cvar.enable_customization", var = "arccw_enable_customization", sv = true },
    { type = "b", text = "#arccw.cvar.truenames", var = "arccw_truenames", sv = true },
    { type = "b", text = "#arccw.cvar.equipmentammo", var = "arccw_equipmentammo", sv = true },
    { type = "c", text = "#arccw.cvar.equipmentammo.desc" },
    { type = "b", text = "#arccw.cvar.equipmentsingleton", var = "arccw_equipmentsingleton", sv = true },
    { type = "c", text = "#arccw.cvar.equipmentsingleton.desc" },
    { type = "i", text = "#arccw.cvar.equipmenttime", var = "arccw_equipmenttime", min = 15, max = 3600, sv = true },
    { type = "b", text = "#arccw.cvar.throwinertia", var = "arccw_throwinertia", sv = true },
    { type = "b", text = "#arccw.cvar.limityear_enable", var = "arccw_limityear_enable", sv = true },
    { type = "i", text = "#arccw.cvar.limityear", var = "arccw_limityear", min = 1800, max = 2100, sv = true },
    { type = "b", text = "#arccw.cvar.desync", var = "arccw_desync", sv = true },
    { type = "c", text = "#arccw.cvar.desync.desc" },
    { type = "b", text = "#arccw.cvar.override_crosshair_off", var = "arccw_override_crosshair_off", sv = true },
    { type = "b", text = "#arccw.cvar.override_deploychambered", var = "arccw_override_deploychambered", sv = true },
    { type = "b", text = "#arccw.cvar.override_barrellength", var = "arccw_override_nearwall", sv = true },
    { type = "b", text = "#arccw.cvar.doorbust", var = "arccw_doorbust", sv = true },
    { type = "f", text = "#arccw.cvar.weakensounds", var = "arccw_weakensounds", min = -20, max = 30, sv = true},
    { type = "c", text = "#arccw.cvar.weakensounds.desc" },
}

local AmmoPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "i", text = "#arccw.cvar.ammo_detonationmode", var = "arccw_ammo_detonationmode", min = -1, max = 2, sv = true },
    { type = "c", text = "#arccw.cvar.ammo_detonationmode.desc", sv = true },
    { type = "b", text = "#arccw.cvar.ammo_autopickup", var = "arccw_ammo_autopickup", sv = true },
    { type = "b", text = "#arccw.cvar.ammo_largetrigger", var = "arccw_ammo_largetrigger", sv = true },
    { type = "f", text = "#arccw.cvar.ammo_rareskin", var = "arccw_ammo_rareskin", min = 0, max = 1, sv = true },
    { type = "b", text = "#arccw.cvar.ammo_chaindet", var = "arccw_ammo_chaindet", sv = true },
    { type = "f", text = "#arccw.cvar.mult_ammohealth", var = "arccw_mult_ammohealth", min = -1, max = 10, sv = true },
    { type = "f", text = "#arccw.cvar.mult_ammoamount", var = "arccw_mult_ammoamount", min = 0.1, max = 10, sv = true },
}

local AttsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "h", text = "#arccw.attdesc1" },
    { type = "h", text = "#arccw.attdesc2" },
    { type = "b", text = "#arccw.cvar.attinv_free", var = "arccw_attinv_free", sv = true },
    { type = "b", text = "#arccw.cvar.attinv_lockmode", var = "arccw_attinv_lockmode", sv = true },
    { type = "i", text = "#arccw.cvar.attinv_loseondie", var = "arccw_attinv_loseondie", min = 0, max = 2, sv = true },
    { type = "c", text = "#arccw.cvar.attinv_loseondie.desc" },
    { type = "i", text = "#arccw.cvar.atts_pickx", var = "arccw_atts_pickx", min = 0, max = 10, sv = true },
    { type = "c", text = "#arccw.cvar.atts_pickx.desc", sv = true },
    { type = "b", text = "#arccw.cvar.enable_dropping", var = "arccw_enable_dropping", sv = true },
    { type = "b", text = "#arccw.cvar.atts_spawnrand", var = "arccw_atts_spawnrand", sv = true },
    { type = "b", text = "#arccw.cvar.atts_ubglautoload", var = "arccw_atts_ubglautoload", sv = true },
    { type = "p", text = "#arccw.blacklist", func = function() RunConsoleCommand("arccw_blacklist") end },
}

local MultsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "f", text = "Damage", var = "arccw_mult_damage", min = 0, max = 10, sv = true },
    { type = "f", text = "NPC Damage", var = "arccw_mult_npcdamage", min = 0, max = 5, sv = true },
    { type = "f", text = "Range", var = "arccw_mult_range", min = 0.01, max = 10, sv = true },
    { type = "f", text = "Recoil", var = "arccw_mult_recoil", min = 0, max = 10, sv = true },
    { type = "f", text = "Penetration", var = "arccw_mult_penetration", min = 0, max = 10, sv = true },
    { type = "f", text = "Hip Dispersion", var = "arccw_mult_hipfire", min = 0, max = 10, sv = true },
    { type = "f", text = "Move Dispersion", var = "arccw_mult_movedisp", min = 0, max = 10, sv = true },
    { type = "f", text = "Reload Time", var = "arccw_mult_reloadtime", min = 0.01, max = 5, sv = true },
    { type = "f", text = "ADS Time", var = "arccw_mult_sighttime", min = 0.1, max = 5, sv = true },
    { type = "i", text = "Default Clip", var = "arccw_mult_defaultclip", min = -1, max = 10, sv = true },
    { type = "f", text = "Random Att. Chance", var = "arccw_mult_attchance", min = 0, max = 10, sv = true },
}

local NPCsPanel = {
    { type = "h", text = "#arccw.adminonly" },
    { type = "b", text = "Replace NPC Weapons", var = "arccw_npc_replace", sv = true },
    { type = "b", text = "NPC Attachments", var = "arccw_npc_atts", sv = true },
}

local function networktheconvar(convar, value, p)
    if !LocalPlayer():IsAdmin() then return end
    if (p.TickCreated or 0) == UnPredictedCurTime() then return end
    if value == true or value == false then
        value = value and 1 or 0
    end
    if IsColor(value) then
        value = tostring(value.r) .. " " .. tostring(value.g) .. " " .. tostring(value.b) .. " " .. tostring(value.a)
    end

    local command = convar .. " " .. tostring(value)

    local timername = "change" .. convar

    if timer.Exists(timername) then
        timer.Remove(timername)
    end

    timer.Create(timername, 0.25, 1, function()
        net.Start("arccw_sendconvar")
        net.WriteString(command)
        net.SendToServer()
    end)
end

function ArcCW.GeneratePanelElements(panel, table)
    local AddControl = {
        ["h"] = function(p, d) return p:Help(d.text) end,
        ["c"] = function(p, d) return p:ControlHelp(d.text) end,
        ["b"] = function(p, d) return p:CheckBox(d.text, d.var) end,
        ["i"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 0) end,
        ["f"] = function(p, d) return p:NumSlider(d.text, d.var, d.min, d.max, 2) end,
        ["m"] = function(p, d) return p:AddControl("color", { Label = d.text, Red = d.r, Green = d.g, Blue = d.b, Alpha = d.a }) end, -- change this someday
        ["p"] = function(p, d) local b = p:Button(d.text) b.DoClick = d.func return b end,
        ["t"] = function(p, d) return p:TextEntry(d.text, d.var) end
    }

    local concommands = {
        ["b"] = true,
        ["i"] = true,
        ["f"] = true,
        ["m"] = true,
        ["t"] = true,
    }

    for _, data in SortedPairs(table) do
        local p = AddControl[data.type](panel, data)

        if concommands[data.type] then
            if data.sv then
                p.TickCreated = UnPredictedCurTime()
                if data.type == "b" then
                    p.OnChange = function(self, bval)
                        networktheconvar(data.var, bval, self)
                    end
                elseif data.type == "i" or data.type == "f" or data.type == "m" or data.type == "t" then
                    p.OnValueChanged = function(self, bval)
                        networktheconvar(data.var, bval, self)
                    end
                end
            end
        end
    end
end

local CrosshairPresets = {
    ["#preset.default"] = {
        arccw_crosshair_length        = "4",
        arccw_crosshair_thickness     = "1",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "1",
        arccw_crosshair_shotgun       = "1",
        arccw_crosshair_equip         = "1",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "255",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.tfa"] = {
        arccw_crosshair_length        = "8",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "255",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.cw2"] = {
        arccw_crosshair_length        = "3.5",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "1",
        arccw_crosshair_clump_outline = "1",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "200",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "200",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.cs"] = {
        arccw_crosshair_length        = "3",
        arccw_crosshair_thickness     = "0.4",
        arccw_crosshair_gap           = "0.4",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "0",
        arccw_crosshair_equip         = "0",
        arccw_crosshair_static        = "1",
        arccw_crosshair_clump         = "0",
        arccw_crosshair_clump_outline = "0",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "0",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "0",
        arccw_crosshair_clr_a         = "255",
        arccw_crosshair_outline       = "0",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "0",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
    ["#arccw.crosshair.light"] = {
        arccw_crosshair_length        = "4",
        arccw_crosshair_thickness     = "0.8",
        arccw_crosshair_gap           = "1",
        arccw_crosshair_dot           = "0",
        arccw_crosshair_shotgun       = "1",
        arccw_crosshair_equip         = "1",
        arccw_crosshair_static        = "0",
        arccw_crosshair_clump         = "1",
        arccw_crosshair_clump_outline = "1",
        arccw_crosshair_clump_always  = "0",
        arccw_crosshair_clr_r         = "255",
        arccw_crosshair_clr_g         = "255",
        arccw_crosshair_clr_b         = "255",
        arccw_crosshair_clr_a         = "200",
        arccw_crosshair_outline       = "2",
        arccw_crosshair_outline_r     = "0",
        arccw_crosshair_outline_g     = "0",
        arccw_crosshair_outline_b     = "0",
        arccw_crosshair_outline_a     = "200",
        arccw_scope_r                 = "255",
        arccw_scope_g                 = "0",
        arccw_scope_b                 = "0",
    },
}

local ViewmodelPresets = {
    ["#preset.default"] = {
        arccw_vm_coolsway				= "1",
        arccw_vm_coolview				= "1",
        arccw_vm_sway_sprint			= "3",
        arccw_vm_bob_sprint				= "3",
        arccw_vm_right					= "0",
        arccw_vm_forward				= "0",
        arccw_vm_up						= "0",
        arccw_vm_lookxmult				= "1",
        arccw_vm_lookymult				= "2",
        arccw_vm_accelmult				= "1",
        arccw_vm_swayxmult				= "-0.1",
        arccw_vm_swayymult				= "0.1",
        arccw_vm_swayzmult				= "-0.3",
        arccw_vm_swaywigglemult			= "1",
        arccw_vm_swayspeedmult			= "1",
        arccw_vm_swayrotatemult			= "1",
        arccw_vm_coolview_mult			= "1",
    }
}

function ArcCW_Options_Bullet(panel)
    ArcCW.GeneratePanelElements(panel, BulletPanel)
end

function ArcCW_Options_Client(panel)
    ArcCW.GeneratePanelElements(panel, ClientPanel)
end

function ArcCW_Options_Perf(panel)
    ArcCW.GeneratePanelElements(panel, PerformancePanel)
end

function ArcCW_Options_Viewmodel(panel)
    panel:AddControl("ComboBox", {
        MenuButton = "1",
        Label      = "#Presets",
        Folder     = "arccw_vm",
        CVars      = { "" },
        Options    = ViewmodelPresets
    })

    ArcCW.GeneratePanelElements(panel, ViewmodelPanel)
end

function ArcCW_Options_HUD(panel)
    ArcCW.GeneratePanelElements(panel, HudPanel)
end

function ArcCW_Options_Crosshair(panel)
    panel:AddControl("ComboBox", {
        MenuButton = "1",
        Label      = "#Presets",
        Folder     = "arccw_crosshair",
        CVars      = { "" },
        Options    = CrosshairPresets
    })

    ArcCW.GeneratePanelElements(panel, CrosshairPanel)
end

function ArcCW_Options_Server(panel)
    ArcCW.GeneratePanelElements(panel, ServerPanel)
end

function ArcCW_Options_Ammo(panel)
    ArcCW.GeneratePanelElements(panel, AmmoPanel)
end

function ArcCW_Options_Mults(panel)
    ArcCW.GeneratePanelElements(panel, MultsPanel)
end

function ArcCW_Options_Atts(panel)
    ArcCW.GeneratePanelElements(panel, AttsPanel)
end

function ArcCW_Options_NPC(panel)
    ArcCW.GeneratePanelElements(panel, NPCsPanel)
end

ArcCW.ClientMenus = {
    ["ArcCW_Options_Client"]    = { text = "#arccw.menus.client", func = ArcCW_Options_Client },
    ["ArcCW_Options_Bullet"]    = { text = "#arccw.menus.bullet", func = ArcCW_Options_Bullet },
    ["ArcCW_Options_Perf"]      = { text = "#arccw.menus.perf", func = ArcCW_Options_Perf },
    ["ArcCW_Options_Viewmodel"] = { text = "#arccw.menus.vmodel", func = ArcCW_Options_Viewmodel },
    ["ArcCW_Options_HUD"]       = { text = "#arccw.menus.hud",    func = ArcCW_Options_HUD },
    ["ArcCW_Options_Crosshair"] = { text = "#arccw.menus.xhair",  func = ArcCW_Options_Crosshair },
    ["ArcCW_Options_Server"]    = { text = "#arccw.menus.server", func = ArcCW_Options_Server },
    ["ArcCW_Options_Ammo"]      = { text = "#arccw.menus.ammo",   func = ArcCW_Options_Ammo },
    ["ArcCW_Options_Atts"]      = { text = "#arccw.menus.atts",   func = ArcCW_Options_Atts },
    ["ArcCW_Options_Mults"]     = { text = "#arccw.menus.mults",  func = ArcCW_Options_Mults },
    ["ArcCW_Options_NPC"]       = { text = "#arccw.menus.npcs",   func = ArcCW_Options_NPC },
}

hook.Add("PopulateToolMenu", "ArcCW_Options", function()
    for menu, data in pairs(ArcCW.ClientMenus) do
        spawnmenu.AddToolMenuOption("Options", "ArcCW", menu, data.text, "", "", data.func)
    end
end)