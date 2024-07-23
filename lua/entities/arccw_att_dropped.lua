AddCSLuaFile()

ENT.Base = "arccw_att_base"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Category = "ArcCW - Attachments"
ENT.PrintName = "Attachment Box"
ENT.Spawnable = false

ENT.Model = "models/Items/BoxMRounds.mdl"

function ENT:Draw()
    self:DrawModel()

    local cvar2d3d = ArcCW.ConVars["2d3d"]:GetInt()
    if cvar2d3d == 0 or (cvar2d3d == 1 and LocalPlayer():GetEyeTrace().Entity != self) then return end

    if (EyePos() - self:WorldSpaceCenter()):LengthSqr() <= 262144 then -- 512^2
        local ang = LocalPlayer():EyeAngles()
        local name = self:GetNWString("boxname", nil) or self.PrintName

        ang:RotateAroundAxis(ang:Forward(), 180)
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)

        cam.Start3D2D(self:WorldSpaceCenter() + Vector(0, 0, 14), ang, 0.1)
            surface.SetFont("ArcCW_32_Unscaled")
            local w = surface.GetTextSize(name)

            surface.SetTextPos(-w / 2 + 2, 2)
            surface.SetTextColor(0, 0, 0, 150)
            surface.DrawText(name)

            surface.SetTextPos(-w / 2, 0)
            surface.SetTextColor(255, 255, 255, 255)
            surface.DrawText(name)

            local count = self:GetNWInt("boxcount", 0)
            local str = count .. " Attachment" .. (count != 1 and "s" or "")
            local w2 = surface.GetTextSize(str)

            surface.SetTextPos(-w2 / 2 + 2, 26)
            surface.SetTextColor(0, 0, 0, 150)
            surface.DrawText(str)
            surface.SetTextPos(-w2 / 2, 24)
            surface.SetTextColor(255, 255, 255, 255)
            surface.DrawText(str)
        cam.End3D2D()
    end
end