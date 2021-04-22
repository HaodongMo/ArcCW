SWEP.Flashlights = {} -- tracks projectedlights
-- {{att = int, light = ProjectedTexture}}
SWEP.CheapFlashlights = {} -- tracks cheap flashlight models + lights
-- {{att = int, dlight = DynamicLight, vlight = ClientsideModel}}

function SWEP:GetHasFlashlights()
    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        if self:GetBuff_Stat("Flashlight", i) != nil then return true end
    end

    return false
end

function SWEP:CreateFlashlightsVM()
    self:KillFlashlights()
    self.Flashlights = {}

    local total_lights = 0

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        if self:GetBuff_Stat("Flashlight", i) then
            local newlight = {
                att = i,
                light = ProjectedTexture(),
                bone = self:GetBuff_Stat("FlashlightBone", i) or "laser",
                col = self:GetBuff_Stat("FlashlightColor", i) or Color(255, 255, 255),
                br = self:GetBuff_Stat("FlashlightBrightness", i) or 2
            }
            total_lights = total_lights + 1

            local l = newlight.light
            if !IsValid(l) then continue end

            table.insert(self.Flashlights, newlight)

            l:SetFOV(self:GetBuff_Stat("FlashlightFOV", i) or 50)

            if self:GetBuff_Stat("FlashlightHFOV", i) then
                l:SetHorizontalFOV(self:GetBuff_Stat("FlashlightHFOV", i))
            end

            if self:GetBuff_Stat("FlashlightVFOV", i) then
                l:SetVerticalFOV(self:GetBuff_Stat("FlashlightVFOV", i))
            end

            l:SetFarZ(self:GetBuff_Stat("FlashlightFarZ", i) or 512)
            l:SetNearZ(self:GetBuff_Stat("FlashlightNearZ", i) or 4)

            local atten = self:GetBuff_Stat("FlashlightAttenuationType", i) or ArcCW.FLASH_ATT_LINEAR

            l:SetLinearAttenuation(0)
            l:SetConstantAttenuation(0)
            l:SetQuadraticAttenuation(0)

                if atten == ArcCW.FLASH_ATT_CONSTANT then
                    l:SetConstantAttenuation(100)
                elseif atten == ArcCW.FLASH_ATT_QUADRATIC then
                    l:SetQuadraticAttenuation(100)
                else
                    l:SetLinearAttenuation(100)
                end

            l:SetColor(self:GetBuff_Stat("FlashlightColor", i) or Color(255, 255, 255))
            l:SetTexture(self:GetBuff_Stat("FlashlightTexture", i))
            l:SetBrightness(self:GetBuff_Stat("FlashlightBrightness", i))
            l:SetEnableShadows(true)
            l:Update()

            local g_light = {
                Weapon = self,
                ProjectedTexture = l
            }

            table.insert(ArcCW.FlashlightPile, g_light)
        end
    end

    if total_lights > 2 then -- you are a madman
        for i, k in pairs(self.Flashlights) do
            if k.light:IsValid() then k.light:SetEnableShadows(false) end
        end
    end
end

-- for world model flashlights we will use a cheap solution similar to what HL2 uses
-- throw up a volumetric light model
-- function SWEP:CreateFlashlightsWM()
--     self:KillFlashlights()
--     self.CheapFlashlights = {}
--     for i, k in pairs(self.Attachments) do
--         if !k.Installed then continue end
--         local atttbl = ArcCW.AttachmentTable[k.Installed]

--         if atttbl.Flashlight then
--             local newlight = {
--                 att = i,
--                 vlight = ClientsideModel(ArcCW.VolumetricLightModel),
--                 scale_x = 1,
--                 scale_y = 1,
--                 maxz = atttbl.FlashlightFarZ or 512,
--                 bone = atttbl.FlashlightBone or "laser",
--                 col = Color(255, 255, 255)
--             }

--             local vl = newlight.vlight

--             if !IsValid(vl) then continue end

--             table.insert(self.CheapFlashlights, newlight)

--             local xfov = atttbl.FlashlightHFOV or atttbl.FlashlightFOV or 50
--             local yfov = atttbl.FlashlightVFOV or atttbl.FlashlightFOV or 50

--             local target_x = 128 * (xfov / 90)
--             local target_y = 128 * (yfov / 90)

--             local scale_x = target_x / ArcCW.VolumetricLightX
--             local scale_y = target_y / ArcCW.VolumetricLightY

--             newlight.scale_x = scale_x
--             newlight.scale_y = scale_y

--             vl:SetNoDraw(ArcCW.NoDraw)
--             vl:DrawShadow(false)
--             local col = atttbl.FlashlightColor or Color(255, 255, 255)
--             col = Color(255, 0, 0)
--             newlight.col = col
--             -- vl:SetColor(col)

--             local g_light = {
--                 Model = vl,
--                 Weapon = self
--             }

--             table.insert(ArcCW.CSModelPile, g_light)
--         end
--     end
-- end

function SWEP:KillFlashlights()
    self:KillFlashlightsVM()
    -- self:KillFlashlightsWM()
end

function SWEP:KillFlashlightsVM()
    if !self.Flashlights then return end

    for i, k in pairs(self.Flashlights) do
        if k.light and k.light:IsValid() then
            k.light:Remove()
        end
    end

    self.Flashlights = nil
end

function SWEP:KillFlashlightsWM()
    -- if !self.CheapFlashlights then return end

    -- for i, k in pairs(self.CheapFlashlights) do
    --     if k.vlight and k.vlight:IsValid() then
    --         k.vlight:Remove()
    --     end
    -- end

    -- self.CheapFlashlights = nil
end

-- given fov and distance solve apparent size
local function solvetriangle(angle, dist)
    local a = angle / 2
    local b = dist
    return b * math.tan(a) * 2
end

local flashlight_mat = Material("models/effects/vol_light002")
-- local flashlight_mat = Material("effects/blueblacklargebeam")

function SWEP:DrawFlashlightsWM()
    -- if !self.CheapFlashlights then
    --     self:CreateFlashlightsWM()
    -- end

    local owner = self:GetOwner()

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if !self:GetBuff_Stat("Flashlight", i) then continue end

        local maxz = atttbl.FlashlightFarZ or 512
        local bone = atttbl.FlashlightBone or "laser"
        local col = atttbl.FlashlightColor or Color(255, 255, 255)

        local model = k.WElement.Model

        local pos, ang, dir

        if !model then
            pos = self:GetOwner():EyePos()
            ang = self:GetOwner():EyeAngles()
            dir = ang:Forward()
        else
            local att = model:LookupAttachment(bone or "laser")

            att = att == 0 and model:LookupAttachment("muzzle") or att

            if att == 0 then
                pos = model:GetPos()
                ang = owner:EyeAngles()
                dir = ang:Forward()
                dir_2 = ang:Up()
            else
                local attdata  = model:GetAttachment(att)
                pos, ang = attdata.Pos, attdata.Ang
                dir = -ang:Right()
                dir_2 = ang:Up()
            end
        end

        local maxs = Vector(2, 2, 2)
        local mins = -maxs

        -- scale volumetric light
        local tr = util.TraceHull({
            start = pos,
            endpos = pos + (dir * maxz),
            mask = MASK_OPAQUE,
            mins = mins,
            maxs = maxs
        })

        local z = (tr.HitPos - tr.StartPos):Length()
        -- local s_z = z / ArcCW.VolumetricLightZ

        local xfov = atttbl.FlashlightHFOV or atttbl.FlashlightFOV or 50
        local yfov = atttbl.FlashlightVFOV or atttbl.FlashlightFOV or 50

        -- local target_x = 128 * (xfov / 90)
        -- local target_y = 128 * (yfov / 90)

        local target_x = solvetriangle(xfov, z)
        local target_y = target_x

        if xfov != yfov then
            target_y = solvetriangle(yfov, z)
        end

        local vs = EyeAngles():Up()

        local c1 = pos + vs
        local c4 = pos - vs
        local c2 = tr.HitPos + (vs * target_y * 0.75)
        local c3 = tr.HitPos - (vs * target_y * 0.75)

        render.SetMaterial(flashlight_mat)
        render.DrawQuad(c1,c2,c3,c4, col)

        -- local scale = Matrix()
        -- scale:Scale(Vector(s_x, s_y, s_z))

        -- k.vlight:SetPos(pos)
        -- k.vlight:SetAngles(ang + Angle(0, 0, 90))
        -- k.vlight:EnableMatrix("RenderMultiply", scale)
        -- k.vlight:SetColor(Color(255, 0, 0, 255))
        -- k.vlight:SetRenderMode(RENDERMODE_NORMAL)
        -- k.vlight:SetKeyValue("RenderFX", kRenderFxNone)
        -- k.vlight:DrawModel()
        -- place dynamic light to make some light appear

        local dl = DynamicLight(self:EntIndex())

        local delta = (z / maxz)
        delta = math.Clamp(delta, 0, 1)

        if dl then
            dl.pos = tr.HitPos
            dl.r = col.r
            dl.g = col.g
            dl.b = col.b
            dl.brightness = Lerp(delta, atttbl.FlashlightBrightness or 2, 0)
            -- print(z / maxz)
            dl.Decay = 1000 / 1
            dl.dietime = CurTime() + 0.1
            dl.size = xfov * 5
        end
    end
end

function SWEP:DrawFlashlightsVM()
    if !self.Flashlights then
        self:CreateFlashlightsVM()
    end

    for i, k in pairs(self.Flashlights) do
        local model = (self.Attachments[k.att].VElement or {}).Model

        local pos, ang

        if !model then
            pos = self:GetOwner():EyePos()
            ang = self:GetOwner():EyeAngles()
        else
            local att = model:LookupAttachment(k.bone or "laser")

            att = att == 0 and model:LookupAttachment("muzzle") or att

            if att == 0 then
                pos = model:GetPos()
                ang = owner:EyeAngles()
            else
                local attdata  = model:GetAttachment(att)
                pos, ang = attdata.Pos, attdata.Ang
            end
        end

        local tr = util.TraceLine({
            start = self:GetOwner():EyePos(),
            endpos = self:GetOwner():EyePos() - ang:Right() * 128,
            mask = MASK_OPAQUE,
            filter = LocalPlayer(),
        })
        if tr.Fraction < 1 then -- We need to push the flashlight back
            local tr2 = util.TraceLine({
                start = self:GetOwner():EyePos(),
                endpos = self:GetOwner():EyePos() + ang:Right() * 128,
                mask = MASK_OPAQUE,
                filter = LocalPlayer(),
            })
            -- push it as back as the area behind us allows
            pos = pos + ang:Right() * 128 * math.min(1 - tr.Fraction, tr2.Fraction)
        end

        ang:RotateAroundAxis(ang:Up(), 90)

        k.light:SetPos(pos)
        k.light:SetAngles(ang)
        k.light:Update()

        -- local col = k.col

        -- local dl = DynamicLight(self:EntIndex())

        -- if dl then
        --     dl.pos = pos
        --     dl.r = col.r
        --     dl.g = col.g
        --     dl.b = col.b
        --     dl.brightness = k.br or 2
        --     -- print(z / maxz)
        --     dl.Decay = 1000 / 0.1
        --     dl.dietime = CurTime() + 0.1
        --     dl.size = (k.br or 2) * 64
        -- end
    end
end