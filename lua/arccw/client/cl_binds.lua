ArcCW.KEY_FIREMODE        = "+zoom"
ArcCW.KEY_FIREMODE_ALT    = "arccw_firemode"
ArcCW.KEY_ZOOMIN          = "invnext"
ArcCW.KEY_ZOOMIN_ALT      = "arccw_zoom_in"
ArcCW.KEY_ZOOMOUT         = "invprev"
ArcCW.KEY_ZOOMOUT_ALT     = "arccw_zoom_out"
ArcCW.KEY_TOGGLEINV       = "+menu_context"
ArcCW.KEY_TOGGLEINV_ALT   = "arccw_toggle_inv"
ArcCW.KEY_SWITCHSCOPE     = "+use"
ArcCW.KEY_SWITCHSCOPE_ALT = "arccw_switch_scope"
ArcCW.KEY_TOGGLEUBGL      = "arccw_toggle_ubgl"
ArcCW.KEY_TOGGLEATT       = "arccw_toggle_att"
ArcCW.KEY_MELEE           = "arccw_melee"

ArcCW.BindToEffect = {
    [ArcCW.KEY_FIREMODE]    = "firemode",
    [ArcCW.KEY_ZOOMIN]      = "zoomin",
    [ArcCW.KEY_ZOOMOUT]     = "zoomout",
    [ArcCW.KEY_TOGGLEINV]   = "inv",
    [ArcCW.KEY_SWITCHSCOPE] = "switchscope_dtap",
}

ArcCW.BindToEffect_Unique = {
    [ArcCW.KEY_TOGGLEUBGL]      = "ubgl",
    [ArcCW.KEY_SWITCHSCOPE_ALT] = "switchscope",
    [ArcCW.KEY_FIREMODE_ALT]    = "firemode",
    [ArcCW.KEY_ZOOMIN_ALT]      = "zoomin",
    [ArcCW.KEY_ZOOMOUT_ALT]     = "zoomout",
    [ArcCW.KEY_TOGGLEINV_ALT]   = "inv",
    [ArcCW.KEY_TOGGLEATT]       = "toggleatt",
    [ArcCW.KEY_MELEE]           = "melee",
}

local lastpressZ = 0
local lastpressE = 0

function ArcCW:GetBind(bind)
    local button = input.LookupBinding(bind)

    return button == "no value" and bind .. " unbound" or button
end

local function ArcCW_TranslateBindToEffect(bind)
    local alt = GetConVar("arccw_altbindsonly"):GetBool()
    if alt then
        return ArcCW.BindToEffect_Unique[bind], true
    else
        return ArcCW.BindToEffect_Unique[bind] or ArcCW.BindToEffect[bind] or bind, ArcCW.BindToEffect_Unique[bind] != nil
    end
end

local function SendNet(string, bool)
    net.Start(string)
    if bool != nil then net.WriteBool(bool) end
    net.SendToServer()
end

local function DoUbgl(wep)
    if wep:GetInUBGL() then
        SendNet("arccw_ubgl", false)

        wep:DeselectUBGL()
    else
        SendNet("arccw_ubgl", true)

        wep:SelectUBGL()
    end
end

local debounce = 0
local function ToggleAtts(wep)
    if debounce > CurTime() then return end -- ugly hack for double trigger
    debounce = CurTime() + 0.1
    local sounds = {}
    for k, v in pairs(wep.Attachments) do
        local atttbl = v.Installed and ArcCW.AttachmentTable[v.Installed]
        if atttbl and atttbl.ToggleStats and not v.ToggleLock then
            if atttbl.ToggleSound then sounds[atttbl.ToggleSound] = true
            else sounds["weapons/arccw/firemode.wav"] = true end
            wep:ToggleSlot(k, nil, true)
        end
    end
    for snd, _ in pairs(sounds) do
        surface.PlaySound(snd)
    end
end

local function ArcCW_PlayerBindPress(ply, bind, pressed)
    if !(ply:IsValid() and pressed) then return end

    local wep = ply:GetActiveWeapon()

    if !wep.ArcCW then return end

    local block = false

    local alt
    bind, alt = ArcCW_TranslateBindToEffect(bind)

    if bind == "firemode" and (alt or !GetConVar("arccw_altfcgkey"):GetBool()) and !ply:KeyDown(IN_USE) then
        if wep:GetBuff_Override("UBGL") and !alt and !GetConVar("arccw_altubglkey"):GetBool() then
            if lastpressZ >= CurTime() - 0.25 then
                DoUbgl(wep)

                lastpressZ = 0

                timer.Remove("ArcCW_doubletapZ")
            else
                lastpressZ = CurTime()

                timer.Create("ArcCW_doubletapZ", 0.25, 1, function()
                    if !(IsValid(ply) and IsValid(wep)) then return end

                    if ply:GetActiveWeapon() != wep then return end

                    if wep:GetInUBGL() then return end

                    SendNet("arccw_firemode")

                    wep:ChangeFiremode()
                end)
            end
        else
            SendNet("arccw_firemode")

            wep:ChangeFiremode()
        end

        block = true
    elseif bind == "inv" and !ply:KeyDown(IN_USE) and GetConVar("arccw_enable_customization"):GetInt() > -1 then

        local state = wep:GetState() != ArcCW.STATE_CUSTOMIZE

        SendNet("arccw_togglecustomize", state)

        wep:ToggleCustomizeHUD(state)

        block = true
    elseif bind == "ubgl" then
        DoUbgl(wep)
    elseif bind == "toggleatt" then
        ToggleAtts(wep)
    end

    if wep:GetState() == ArcCW.STATE_SIGHTS then
        if bind == "zoomin" then
            wep:Scroll(1)
            block = true
        elseif bind == "zoomout" then
            wep:Scroll(-1)
            block = true
        elseif bind == "switchscope_dtap" then
            if lastpressE >= CurTime() - 0.25 then
                wep:SwitchActiveSights()
                lastpressE = 0
            else
                lastpressE = CurTime()
            end
        elseif bind == "switchscope" then
            wep:SwitchActiveSights()
            block = true
        end
    end

    if bind == "melee" and wep:GetState() != ArcCW.STATE_SIGHTS then
        wep:Bash()
    end

    if block then return true end
end

hook.Add("PlayerBindPress", "ArcCW_PlayerBindPress", ArcCW_PlayerBindPress)

-- Actually register the damned things so they can be bound
for k, v in pairs(ArcCW.BindToEffect_Unique) do
    concommand.Add(k, function(ply) ArcCW_PlayerBindPress(ply, k, true) end, nil, v, 0)
end

-- ArcCW.CaptureKeys = {
--     KEY_G
-- }
-- ArcCW.LastInputs = {}
-- ArcCW.Inputs = {}

-- local function ArcCW_CustomInputs()
--     local inputs = {}

--     for _, i in pairs(ArcCW.CaptureKeys) do
--         -- local conv = GetConVar(i)

--         -- if !conv then continue end
--         -- if !IsValid(conv) then continue end

--         local kc = i

--         inputs[kc] = input.IsKeyDown(kc)
--     end

--     ArcCW.LastInputs = ArcCW.Inputs
--     ArcCW.Inputs = inputs

--     if ArcCW:KeyPressed(KEY_G) then
--         ArcCW:QuickNade("frag")
--     end
-- end

-- hook.Add("Think", "ArcCW_CustomInputs", ArcCW_CustomInputs)

-- function ArcCW:KeyPressed(key)
--     if !ArcCW.LastInputs[key] and ArcCW.Inputs[key] then
--         return true
--     end

--     return false
-- end