function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local wpn = data:GetEntity()

    if !IsValid(wpn) then return end

    local muzzle = wpn.MuzzleEffect
    local overridemuzzle = wpn:GetBuff_Override("Override_MuzzleEffect")

    local gmmuzzle = wpn:GetBuff_Override("Override_GMMuzzleEffect") or wpn.GMMuzzleEffect

    muzzle = overridemuzzle or muzzle

    if wpn.GetInUBGL and wpn:GetInUBGL() then
        muzzle = wpn:GetBuff_Override("UBGL_MuzzleEffect") or muzzle
    end

    if GetConVar("arccw_fastmuzzles"):GetBool() then
        muzzle = wpn.FastMuzzleEffect or "CS_MuzzleFlash"

        gmmuzzle = true

        if overridemuzzle then
            muzzle = nil
        end

        muzzle = wpn:GetBuff_Override("Override_FastMuzzleEffect") or muzzle
    end

    local att = data:GetAttachment() or 1

    local wm = false
	
	local Owner = wpn:GetOwner()
    if (LocalPlayer():ShouldDrawLocalPlayer() or Owner != LocalPlayer()) and !wpn.AlwaysWM then
        wm = true
        att = 1
    end

    if Owner != LocalPlayer() and !GetConVar("arccw_muzzleeffects"):GetBool() then
        return
    end

    local mdl = wpn:GetMuzzleDevice(wm)
    local parent = mdl

    if !wm then
        parent = LocalPlayer():GetViewModel()
    end

    if !IsValid(mdl) then return end

    pos = (mdl:GetAttachment(att) or {}).Pos
    ang = (mdl:GetAttachment(att) or {}).Ang

    if gmmuzzle then
        if muzzle then
            if !pos then return end

            local fx = EffectData()

            fx:SetOrigin(pos)
            fx:SetEntity(parent)
            fx:SetAttachment(att)
            fx:SetNormal((ang or Angle(0, 0, 0)):Forward())
            fx:SetStart(pos)
            fx:SetScale(1)

            util.Effect(muzzle, fx)
        end
    else
        if muzzle then
            ParticleEffectAttach(muzzle, PATTACH_POINT_FOLLOW, mdl, att)
        end
    end

    if !pos then return end

    if !GetConVar("arccw_fastmuzzles"):GetBool() and !wpn.NoFlash
            and !wpn:GetBuff_Override("Silencer")
            and !wpn:GetBuff_Override("FlashHider") then
        local light = DynamicLight(self:EntIndex())
        local clr = wpn:GetBuff_Override("Override_MuzzleFlashColor", wpn.MuzzleFlashColor) or Color(244, 209, 66)
        if (light) then
            light.Pos = pos
            light.r = clr.r
            light.g = clr.g
            light.b = clr.b
            light.Brightness = 2
            light.Decay = 2500
            light.Size = Owner == LocalPlayer() and 256 or 128
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