ArcCW.KEY_FIREMODE = "+zoom"
ArcCW.KEY_FIREMODE_ALT = "arccw_firemode"
ArcCW.KEY_ZOOMIN = "invnext"
ArcCW.KEY_ZOOMIN_ALT = "arccw_zoom_in"
ArcCW.KEY_ZOOMOUT = "invprev"
ArcCW.KEY_ZOOMOUT_ALT = "arccw_zoom_out"
ArcCW.KEY_TOGGLEINV = "+menu_context"
ArcCW.KEY_TOGGLEINV_ALT = "arccw_toggle_inv"
ArcCW.KEY_SWITCHSCOPE = "+use"
ArcCW.KEY_SWITCHSCOPE_ALT = "arccw_switch_scope"
ArcCW.KEY_TOGGLEUBGL = "arccw_toggle_ubgl"

local lastpressZ = 0
local lastpressE = 0

function ArcCW:GetBind(bind)
    local e = input.LookupBinding(bind)
    if e == "no value" then return bind .. " unbound" end
    return e
end

ArcCW.BindToEffect = {
    [ArcCW.KEY_FIREMODE] = "firemode",
    [ArcCW.KEY_ZOOMIN] = "zoomin",
    [ArcCW.KEY_ZOOMOUT] = "zoomout",
    [ArcCW.KEY_TOGGLEINV] = "inv",
    [ArcCW.KEY_SWITCHSCOPE] = "switchscope_dtap",
}

ArcCW.BindToEffect_Unique = {
    [ArcCW.KEY_TOGGLEUBGL] = "ubgl",
    [ArcCW.KEY_SWITCHSCOPE_ALT] = "switchscope",
    [ArcCW.KEY_FIREMODE_ALT] = "firemode",
    [ArcCW.KEY_ZOOMIN_ALT] = "zoomin",
    [ArcCW.KEY_ZOOMOUT_ALT] = "zoomout",
    [ArcCW.KEY_TOGGLEINV_ALT] = "inv"
}

local function ArcCW_TranslateBindToEffect(bind)
    if GetConVar("arccw_altbindsonly"):GetBool() then
        return ArcCW.BindToEffect_Unique[bind] or bind
    else
        return ArcCW.BindToEffect[bind] or ArcCW.BindToEffect_Unique[bind] or bind
    end
end

local function ArcCW_PlayerBindPress(ply, bind, pressed)
    if !pressed then return end
    if !ply:IsValid() then return end

    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local block = false

    bind = ArcCW_TranslateBindToEffect(bind)

    if bind == "firemode" and !GetConVar("arccw_altfcgkey"):GetBool() then
        if wpn:GetBuff_Override("UBGL") and !GetConVar("arccw_altubglkey"):GetBool() then
            if lastpressZ >= CurTime() - 0.25 then
                if wpn:GetNWBool("ubgl") then
                    net.Start("arccw_ubgl")
                    net.WriteBool(false)
                    net.SendToServer()

                    wpn:DeselectUBGL()
                else
                    net.Start("arccw_ubgl")
                    net.WriteBool(true)
                    net.SendToServer()

                    wpn:SelectUBGL()
                end
                lastpressZ = 0

                timer.Remove("ArcCW_doubletapZ")
            else
                lastpressZ = CurTime()
                timer.Create("ArcCW_doubletapZ", 0.25, 1, function()
                    if !IsValid(ply) then return end
                    if !IsValid(wpn) then return end
                    if ply:GetActiveWeapon() != wpn then return end
                    if wpn:GetNWBool("ubgl") then return end

                    net.Start("arccw_firemode")
                    net.SendToServer()

                    wpn:ChangeFiremode()
                end)
            end
        else
            net.Start("arccw_firemode")
            net.SendToServer()

            wpn:ChangeFiremode()
        end

        block = true
    elseif bind == "inv" then
        local p = wpn:GetState() != ArcCW.STATE_CUSTOMIZE
        wpn:ToggleCustomizeHUD(p)

        net.Start("arccw_togglecustomize")
        net.WriteBool(p)
        net.SendToServer()

        block = true
    elseif bind == "ubgl" then
        if wpn:GetNWBool("ubgl") then
            net.Start("arccw_ubgl")
            net.WriteBool(false)
            net.SendToServer()

            wpn:DeselectUBGL()
        else
            net.Start("arccw_ubgl")
            net.WriteBool(true)
            net.SendToServer()

            wpn:SelectUBGL()
        end
    end

    if wpn:GetState() == ArcCW.STATE_SIGHTS then
        if bind == "zoomin" then
            wpn:Scroll(1)
            block = true
        elseif bind == "zoomout" then
            wpn:Scroll(-1)
            block = true
        elseif bind == "switchscope_dtap" then
            if lastpressE >= CurTime() - 0.25 then
                wpn:SwitchActiveSights()
                lastpressE = 0
            else
                lastpressE = CurTime()
            end
        elseif bind == "switchscope" then
            wpn:SwitchActiveSights()
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