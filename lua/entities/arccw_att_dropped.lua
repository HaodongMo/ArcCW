AddCSLuaFile()

ENT.Base = "arccw_att_base"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Category			= "ArcCW - Attachments"
ENT.PrintName = "Attachment Box"
ENT.Spawnable = false

ENT.Model = "models/Items/BoxMRounds.mdl"

function ENT:Draw()
    self:DrawModel()

    if !GetConVar("arccw_2d3d"):GetBool() then return end

    if (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 then -- 512^2
        local ang = LocalPlayer():EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 180)
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)

        cam.Start3D2D(self:WorldSpaceCenter() + Vector(0, 0, 16), ang, 0.1)
            surface.SetFont("ArcCW_32_Unscaled")

            local w = surface.GetTextSize(self.PrintName)
            surface.SetTextPos(-w / 2, 0)
            surface.SetTextColor(255, 255, 255, 255)
            surface.DrawText(self:GetNWString("boxname", nil) or self.PrintName)

            local count = #self.GiveAttachments
            local w2 = surface.GetTextSize(count)
            surface.SetTextPos(-w2 / 2, 0)
            surface.SetTextColor(255, 255, 255, 255)
            surface.DrawText(count .. " Attachment" .. (count ~= 1 and "s" or ""))
        cam.End3D2D()
    end
end