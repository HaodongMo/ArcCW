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
ArcCW.KEY_TOGGLEUBGL_ALT = "arccw_toggle_ubgl"

local lastpressZ = 0
local lastpressE = 0

function ArcCW:GetBind(bind)
    if ArcCW[bind] then return ArcCW[bind] end

    return input.LookupBinding(bind)
end

local function ArcCW_PlayerBindPress(ply, bind, pressed)
    if !pressed then return end
    if !ply:IsValid() then return end

    local wpn = ply:GetActiveWeapon()

    if !wpn.ArcCW then return end

    local block = false

    if bind == ArcCW.KEY_FIREMODE then
        if wpn:GetBuff_Override("UBGL") then
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
    elseif bind == ArcCW.KEY_TOGGLEINV then
        local p = wpn:GetState() != ArcCW.STATE_CUSTOMIZE
        wpn:ToggleCustomizeHUD(p)

        net.Start("arccw_togglecustomize")
        net.WriteBool(p)
        net.SendToServer()

        block = true
    end

    if wpn:GetState() == ArcCW.STATE_SIGHTS then
        if bind == ArcCW.KEY_ZOOMIN then
            wpn:Scroll(1)
            block = true
        elseif bind == ArcCW.KEY_ZOOMOUT then
            wpn:Scroll(-1)
            block = true
        elseif bind == ArcCW.KEY_SWITCHSCOPE then
            if lastpressE >= CurTime() - 0.25 then
                wpn:SwitchActiveSights()
                lastpressE = 0
            else
                lastpressE = CurTime()
            end
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