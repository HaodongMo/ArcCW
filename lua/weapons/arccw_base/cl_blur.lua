local dofmat = Material("pp/dof")

function SWEP:BlurWeapon()
    if !GetConVar("arccw_blur"):GetBool() then return end

    local delta = self:GetSightDelta()

    if delta >= 1 then return end

    local vm = self:GetOwner():GetViewModel()

    render.UpdateScreenEffectTexture()
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_REPLACE)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)

    render.SetBlend(1)

        render.SetStencilReferenceValue(55)

        ArcCW.Overdraw = true
        vm:DrawModel()

        ArcCW.Overdraw = false

    render.SetBlend(0)

    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilCompareFunction(STENCIL_EQUAL)

    -- render.SetColorMaterial()

    dofmat:SetFloat("bluramount", 0.1 * (1 - delta))

    render.SetMaterial(dofmat)
    render.DrawScreenQuad()

    render.SetStencilEnable( false )
end

function SWEP:BlurNotWeapon()
    if !GetConVar("arccw_blur"):GetBool() then return end

    render.UpdateRefractTexture()
    DrawToyTown( 3, ScrH() )
end

function SWEP:DoToyTown()
    if !GetConVar("arccw_blur_toytown"):GetBool() then return end
    render.UpdateRefractTexture()
    DrawToyTown( 3, ScrH() * 0.5 * (1 - self:GetSightDelta()) )
end