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

    if engine.ActiveGamemode() == "terrortown" and (ele ~= "CHudAmmo") then return false end

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

local font = ArcCW.GetTranslation("default_font") or "Bahnschrift"

local sizes_to_make = {
    6,
    8,
    12,
    16,
    20,
    24,
    26
}

local unscaled_sizes_to_make = {
    32,
    24
}

local function generatefonts()

    for _, i in pairs(sizes_to_make) do

        surface.CreateFont( "ArcCW_" .. tostring(i), {
            font = font,
            size = ScreenScale(i),
            weight = 0,
            antialias = true,
        } )

        surface.CreateFont( "ArcCW_" .. tostring(i) .. "_Glow", {
            font = font,
            size = ScreenScale(i),
            weight = 0,
            antialias = true,
            blursize = 8,
        } )

    end

    for _, i in pairs(unscaled_sizes_to_make) do

        surface.CreateFont( "ArcCW_" .. tostring(i) .. "_Unscaled", {
            font = font,
            size = i,
            weight = 0,
            antialias = true,
        } )

    end

end

generatefonts()

language.Add("SniperPenetratedRound_ammo", "Sniper Ammo")

local lastScrH = ScrH()
local lastScrW = ScrW()

hook.Add("HUDPaint", "ArcCW_FontRegen", function()
    if (lastScrH != ScrH()) or (lastScrW != ScrW()) then
        generatefonts()
    end

    lastScrH = ScrH()
    lastScrW = ScrW()
end)

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