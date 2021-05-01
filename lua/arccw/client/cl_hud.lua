local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
}

ArcCW.HUDElementConVars = {
    ["CHudHealth"] = CreateClientConVar("arccw_hud_showhealth", "1"),
    ["CHudBattery"] = GetConVar("arccw_hud_showhealth"),
    ["CHudAmmo"] = CreateClientConVar("arccw_hud_showammo", "1"),
    ["CHudSecondaryAmmo"] = GetConVar("arccw_hud_showammo"),
}

hook.Add("HUDShouldDraw", "ArcCW_HideHUD", function(name)
    if !hide[name] then return end
    if !LocalPlayer():IsValid() then return end
    if !LocalPlayer():GetActiveWeapon().ArcCW then return end
    if ArcCW.PollingDefaultHUDElements then return end
    if ArcCW.HUDElementConVars[name] and ArcCW.HUDElementConVars[name]:GetBool() == false then return end
    if engine.ActiveGamemode() == "terrortown" then return end

    return false
end)

hook.Add("RenderScreenspaceEffects", "ArcCW_ToyTown", function()
    if !LocalPlayer():IsValid() then return end
    local wpn = LocalPlayer():GetActiveWeapon()
    if !IsValid(wpn) then return end

    if !wpn.ArcCW then return end

    local delta = wpn:GetSightDelta()

    if delta < 1 then
        wpn:DoToyTown()
    end
end)

ArcCW.PollingDefaultHUDElements = false

function ArcCW:ShouldDrawHUDElement(ele)
    if !GetConVar("cl_drawhud"):GetBool() then return false end

    if engine.ActiveGamemode() == "terrortown" and (ele != "CHudAmmo") then return false end

    if ArcCW.HUDElementConVars[ele] and !ArcCW.HUDElementConVars[ele]:GetBool() then
        return false
    end

    ArcCW.PollingDefaultHUDElements = true

    if !GetConVar("arccw_hud_forceshow"):GetBool() and hook.Call("HUDShouldDraw", nil, ele) == false then
        ArcCW.PollingDefaultHUDElements = false
        return false
    end

    ArcCW.PollingDefaultHUDElements = false

    return true
end

local function GetFont()
    local font = "Bahnschrift"

    if ArcCW.GetTranslation("default_font") then
        font = ArcCW.GetTranslation("default_font")
    end

    if GetConVar("arccw_font"):GetString() != "" then
        font = GetConVar("arccw_font"):GetString()
    end

    return font
end

-- Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. Yes. 
-- What is the size of your ass. What is it. Tell me.
local ScreenScale_CacheC2 = {}
ArcCW.AugmentedScreenScale = function(size)
    if ScreenScale_CacheC2[size] then return ScreenScale_CacheC2[size] end

    local scrw, scrh = ScrW(), ScrH()
    if vrmod and vrmod.IsPlayerInVR(LocalPlayer()) then
        -- Other resolutions seem to cause stretching issues
        scrw = 1366
        scrh = 768
    end

    local scrwmult = GetConVar("arccw_hud_deadzone_x"):GetFloat() * scrw
    local scrhmult = GetConVar("arccw_hud_deadzone_y"):GetFloat() * scrh

    scrw, scrh = scrw - scrwmult, scrh - scrhmult

    local r = size
    r = r * (math.max(scrw, scrh) / 800)
    r = r * GetConVar("arccw_hud_size"):GetFloat()
    ScreenScale_CacheC2[size] = r
    return r
end

local sizes_to_make = {
    6,
    8,
    10,
    12,
    14,
    16,
    20,
    24,
    26,
    32
}

local sizes_to_make_cust2 = {
    8,
    10,
    12,
    14,
    16,
    24,
    32
}

local unscaled_sizes_to_make = {
    32,
    24
}

local function generatefonts()

    for _, i in pairs(sizes_to_make) do

        surface.CreateFont( "ArcCW_" .. tostring(i), {
            font = GetFont(),
            size = ScreenScale(i) * GetConVar("arccw_hud_size"):GetFloat(),
            weight = 0,
            antialias = true,
            extended = true, -- Required for non-latin fonts
        } )

        surface.CreateFont( "ArcCW_" .. tostring(i) .. "_Glow", {
            font = GetFont(),
            size = ScreenScale(i) * GetConVar("arccw_hud_size"):GetFloat(),
            weight = 0,
            antialias = true,
            blursize = 6,
            extended = true,
        } )

    end

    for _, i in pairs(sizes_to_make_cust2) do

        surface.CreateFont( "ArcCWC2_" .. tostring(i), {
            font = GetFont(),
            size = ArcCW.AugmentedScreenScale(i) * GetConVar("arccw_hud_size"):GetFloat(),
            weight = 0,
            antialias = true,
            extended = true, -- Required for non-latin fonts
        } )

        surface.CreateFont( "ArcCWC2_" .. tostring(i) .. "_Glow", {
            font = GetFont(),
            size = ArcCW.AugmentedScreenScale(i) * GetConVar("arccw_hud_size"):GetFloat(),
            weight = 0,
            antialias = true,
            blursize = 6,
            extended = true,
        } )

    end

    for _, i in pairs(unscaled_sizes_to_make) do

        surface.CreateFont( "ArcCW_" .. tostring(i) .. "_Unscaled", {
            font = GetFont(),
            size = i,
            weight = 0,
            antialias = true,
            extended = true,
        } )

    end

end

local og_ScreenScale = ScreenScale

local ScreenScale_Cache = {}

function ScreenScale(a)
    if ScreenScale_Cache[a] then return ScreenScale_Cache[a] end

    ScreenScale_Cache[a] = og_ScreenScale(a)
    return ScreenScale_Cache[a]
end

language.Add("SniperPenetratedRound_ammo", "Sniper Ammo")

generatefonts()
function ArcCW_Regen(full)
    if full then
        generatefonts()
        ScreenScale_Cache = {}
        ScreenScale_CacheC2 = {}
    end
    if IsValid(ArcCW.InvHUD) then
        ArcCW.InvHUD:Clear()
        ArcCW.InvHUD:Remove()
    end
end

cvars.AddChangeCallback("arccw_dev_cust2beta",  function() ArcCW_Regen(true) end)
cvars.AddChangeCallback("arccw_hud_deadzone_x", function() ArcCW_Regen(true) end)
cvars.AddChangeCallback("arccw_hud_deadzone_y", function() ArcCW_Regen(true) end)
cvars.AddChangeCallback("arccw_hud_size",       function() ArcCW_Regen(true) end)
cvars.AddChangeCallback("arccw_font",           function() ArcCW_Regen(true) end)
hook.Add( "OnScreenSizeChanged", "ArcCW_Regen", function() ArcCW_Regen(true) end)

-- surface.CreateFont( "ArcCW_12", {
--     font = font,
--     size = ScreenScale(12),
--     weight = 0,
--     antialias = true,
-- } )

-- surface.CreateFont( "ArcCW_12_Glow", {
--     font = font,
--     size = ScreenScale(12),
--     weight = 0,
--     antialias = true,
--     blursize = 8,
-- } )

-- surface.CreateFont( "ArcCW_16", {
--     font = font,
--     size = ScreenScale(16),
--     weight = 0,
--     antialias = true,
-- } )

-- surface.CreateFont( "ArcCW_16_Glow", {
--     font = font,
--     size = ScreenScale(16),
--     weight = 0,
--     antialias = true,
--     blursize = 8,
-- } )

-- surface.CreateFont( "ArcCW_26", {
--     font = font,
--     size = ScreenScale(26),
--     weight = 0,
--     antialias = true,
-- } )

-- surface.CreateFont( "ArcCW_26_Glow", {
--     font = font,
--     size = ScreenScale(26),
--     weight = 0,
--     antialias = true,
--     blursize = 8,
-- } )