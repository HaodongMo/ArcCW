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
    [ArcCW.KEY_TOGGLEINV_ALT]   = "inv"
}

local lastpressZ = 0
local lastpressE = 0

function ArcCW:GetBind(bind)
    local button = input.LookupBinding(bind)

    return button == "no value" and bind .. " unbound" or button
end

local function ArcCW_TranslateBindToEffect(bind)
    local alt = GetConVar("arccw_altbindsonly"):GetBool()

    return alt and ArcCW.BindToEffect_Unique[bind] or ArcCW.BindToEffect[bind] or bind
end

local function SendNet(string, bool)
    net.Start(string)
    if bool then net.WriteBool(bool) end
    net.SendToServer()
end

local function DoUbgl(wep)
    if wep:GetNWBool("ubgl") then
        SendNet("arccw_ubgl", false)

        wep:DeselectUBGL()
    else
        SendNet("arccw_ubgl", true)

        wep:SelectUBGL()
    end
end

local function ArcCW_PlayerBindPress(ply, bind, pressed)
    if not (ply:IsValid() and pressed) then return end

    local wep = ply:GetActiveWeapon()

    if not wep.ArcCW then return end

    local block = false

    bind = ArcCW_TranslateBindToEffect(bind)

    if bind == "firemode" and not GetConVar("arccw_altfcgkey"):GetBool() then
        if wep:GetBuff_Override("UBGL") and not GetConVar("arccw_altubglkey"):GetBool() then
            if lastpressZ >= CurTime() - 0.25 then
                DoUbgl(wep)

                lastpressZ = 0

                timer.Remove("ArcCW_doubletapZ")
            else
                lastpressZ = CurTime()

                timer.Create("ArcCW_doubletapZ", 0.25, 1, function()
                    if not (IsValid(ply) and IsValid(wep)) then return end

                    if ply:GetActiveWeapon() ~= wep then return end

                    if wep:GetNWBool("ubgl") then return end

                    SendNet("arccw_firemode")

                    wep:ChangeFiremode()
                end)
            end
        else
            SendNet("arccw_firemode")

            wep:ChangeFiremode()
        end

        block = true
    elseif bind == "inv" then
        local state = wep:GetState() ~= ArcCW.STATE_CUSTOMIZE

        SendNet("arccw_togglecustomize", state)

        wep:ToggleCustomizeHUD(state)

        block = true
    elseif bind == "ubgl" then
        DoUbgl(wep)
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
        end
    end

    if block then return true end
end

hook.Add("PlayerBindPress", "ArcCW_PlayerBindPress", ArcCW_PlayerBindPress)

-- ArcCW.CaptureKeys = {
--     KEY_G
-- }
-- ArcCW.LastInputs = {}
-- ArcCW.Inputs = {}

-- local function ArcCW_CustomInputs()
--     local inputs = {}

--     for _, i in pairs(ArcCW.CaptureKeys) do
--         -- local conv = GetConVar(i)

--         -- if not conv then continue end
--         -- if not IsValid(conv) then continue end

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
--     if not ArcCW.LastInputs[key] and ArcCW.Inputs[key] then
--         return true
--     end

--     return false
-- end