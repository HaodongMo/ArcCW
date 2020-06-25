function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local wpn = data:GetEntity()

    if !IsValid(wpn) then return end

    local muzzle = wpn:GetBuff_Override("Override_MuzzleEffect") or wpn.MuzzleEffect

    if wpn:GetNWBool("ubgl", false) then
        muzzle = wpn:GetBuff_Override("UBGL_MuzzleEffect") or muzzle
    end

    local att = data:GetAttachment() or 1

    if !muzzle then return end

    local wm = false

    if (LocalPlayer():ShouldDrawLocalPlayer() or wpn.Owner != LocalPlayer()) and !wpn.AlwaysWM then
        wm = true
        att = 1
    end

    if wpn.Owner != LocalPlayer() then
        if !GetConVar("arccw_muzzleeffects"):GetBool() then return end
    end

    local mdl = wpn:GetMuzzleDevice(wm)

    ParticleEffectAttach(muzzle, PATTACH_POINT_FOLLOW, mdl, att)

    pos = (mdl:GetAttachment(att) or {}).Pos

    if !pos then return end

    if !wpn:GetBuff_Override("Silencer") then
        local light = DynamicLight(self:EntIndex())
        if (light) then
            light.Pos = pos
            light.r = 244
            light.g = 209
            light.b = 66
            light.Brightness = 2
            light.Decay = 2500
            light.Size = 256
            light.DieTime = CurTime() + 0.1
        end
    end
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
    return false
end