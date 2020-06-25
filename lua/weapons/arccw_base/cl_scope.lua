function SWEP:AdjustMouseSensitivity()
    if self:GetState() != ArcCW.STATE_SIGHTS then return end

    local irons = self:GetActiveSights()

    return 1 / (irons.Magnification + (irons.ScopeMagnification or 0))
end

function SWEP:Scroll(var)
    local irons = self:GetActiveSights()

    if irons.ScrollFunc == ArcCW.SCROLL_ZOOM then
        if !irons.ScopeMagnificationMin then return end
        if !irons.ScopeMagnificationMax then return end

        local old = irons.ScopeMagnification

        local minus = var < 0

        var = math.abs(irons.ScopeMagnificationMax - irons.ScopeMagnificationMin)

        var = var / (irons.ZoomLevels or 5)

        if minus then
            var = var * -1
        end

        irons.ScopeMagnification = irons.ScopeMagnification - var

        irons.ScopeMagnification = math.Clamp(irons.ScopeMagnification, irons.ScopeMagnificationMin, irons.ScopeMagnificationMax)

        self.SightMagnifications[irons.Slot or 0] = irons.ScopeMagnification

        if old != irons.ScopeMagnification then
            self:EmitSound(irons.ZoomSound or "", 75, math.Rand(95, 105), 1, CHAN_ITEM)
        end

        -- if !irons.MinZoom then return end
        -- if !irons.MaxZoom then return end

        -- local old = irons.Magnification

        -- irons.Magnification = irons.Magnification - var

        -- irons.Magnification = math.Clamp(irons.Magnification, irons.MinZoom, irons.MaxZoom)

        -- if old != irons.Magnification then
        --     self:EmitSound(irons.ZoomSound or "", 75, 100, 1, CHAN_ITEM)
        -- end
    end

end

function SWEP:CalcView(ply, pos, ang, fov)
    if !GetConVar("arccw_shake"):GetBool() then return end

    return pos, ang + (AngleRand() * self.RecoilAmount * 0.008), fov
end

function SWEP:ShouldGlint()
    return self:GetBuff_Override("ScopeGlint") and self:GetNWBool("state") == ArcCW.STATE_SIGHTS
end

function SWEP:DoScopeGlint()
end