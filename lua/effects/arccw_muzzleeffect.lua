function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local wpn = data:GetEntity()

    if !IsValid(wpn) then return end

    local muzzle = wpn.MuzzleEffect
    local overridemuzzle = wpn:GetBuff_Override("Override_MuzzleEffect")

    muzzle = overridemuzzle or muzzle

    if wpn:GetNWBool("ubgl", false) then
        muzzle = wpn:GetBuff_Override("UBGL_MuzzleEffect") or muzzle
    end

    if GetConVar("arccw_fastmuzzles"):GetBool() then
        muzzle = wpn.FastMuzzleEffect or "MuzzleEffect"

        if overridemuzzle then
            muzzle = nil
        end

        muzzle = wpn:GetBuff_Override("Override_FastMuzzleEffect") or muzzle
    end

    local att = data:GetAttachment() or 1

    local wm = false

    if (LocalPlayer():ShouldDrawLocalPlayer() or wpn.Owner != LocalPlayer()) and !wpn.AlwaysWM then
        wm = true
        att = 1
    end

    if wpn.Owner != LocalPlayer() then
        if !GetConVar("arccw_muzzleeffects"):GetBool() then return end
    end

    local mdl = wpn:GetMuzzleDevice(wm)

    if !IsValid(mdl) then return end

    print(muzzle)

    if muzzle then
        ParticleEffectAttach(muzzle, PATTACH_POINT_FOLLOW, mdl, att)
    end

    pos = (mdl:GetAttachment(att) or {}).Pos

    if !pos then return end

    if !wpn:GetBuff_Override("Silencer") and !wpn:GetBuff_Override("FlashHider") then
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