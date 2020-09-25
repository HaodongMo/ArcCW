function SWEP:KillModels()
    self:KillModel(self.WM)
    self.WM = nil
    self:KillModel(self.VM)
    self.VM = nil
end

function SWEP:AddElement(elementname, wm)
    local e = self.AttachmentElements[elementname]

    if !e then return end
    if !wm and self:GetOwner():IsNPC() then return end

    if !self:CheckFlags(e.ExcludeFlags, e.RequireFlags) then return end

    if GetConVar("arccw_truenames"):GetBool() and e.TrueNameChange then
        self.PrintName = e.TrueNameChange
    elseif GetConVar("arccw_truenames"):GetBool() and e.NameChange then
        self.PrintName = e.NameChange
    end

    if !GetConVar("arccw_truenames"):GetBool() and e.NameChange then
        self.PrintName = e.NameChange
    elseif !GetConVar("arccw_truenames"):GetBool() and e.TrueNameChange then
        self.PrintName = e.TrueNameChange
    end

    if e.AddPrefix then
        self.PrintName = e.AddPrefix .. self.PrintName
    end

    if e.AddSuffix then
        self.PrintName = self.PrintName .. e.AddSuffix
    end

    local og_weapon = weapons.GetStored(self:GetClass())

    local og_vm = og_weapon.ViewModel
    local og_wm = og_weapon.WorldModel

    self.ViewModel = og_vm
    self.WorldModel = og_wm

    local parent = self
    local elements = self.WM

    if !wm then
        parent = self:GetOwner():GetViewModel()
        elements = self.VM
    end

    local eles = e.VMElements

    if wm then
        eles = e.WMElements

        if self.MirrorVMWM then
            self.WorldModel = e.VMOverride or self.WorldModel
            self:SetSkin(e.VMSkin or self.DefaultSkin)
        else
            self.WorldModel = e.WMOverride or self.WorldModel
            self:SetSkin(e.WMSkin or self.DefaultWMSkin)
        end
    else
        self.ViewModel = e.VMOverride or self.ViewModel
        self:GetOwner():GetViewModel():SetSkin(e.VMSkin or self.DefaultSkin)
    end

    if SERVER then return end

    for _, i in pairs(eles or {}) do
        local model = ClientsideModel(i.Model)

        if !model or !IsValid(model) or !IsValid(self) then continue end

        if i.BoneMerge then
            model:SetParent(parent)
            model:AddEffects(EF_BONEMERGE)
        else
            model:SetParent(self)
        end

        local element = {}

        local scale = Matrix()
        scale:Scale(i.Scale or Vector(1, 1, 1))

        model:SetNoDraw(ArcCW.NoDraw)
        model:DrawShadow(true)
        model:SetPredictable(false)
        model.Weapon = self
        model:SetSkin(i.ModelSkin or 0)
        model:SetBodyGroups(i.ModelBodygroups or "")
        model:EnableMatrix("RenderMultiply", scale)
        model:SetupBones()
        element.Model = model
        element.DrawFunc = i.DrawFunc
        element.WM = wm or false
        element.Bone = i.Bone
        element.NoDraw = i.NoDraw or false
        element.BoneMerge = i.BoneMerge or false
        element.Bodygroups = i.ModelBodygroups
        element.DrawFunc = i.DrawFunc
        element.OffsetAng = Angle()
        element.OffsetAng:Set(i.Offset.ang or Angle(0, 0, 0))
        element.OffsetPos = Vector()
        element.OffsetPos:Set(i.Offset.pos or Vector(), 0, 0)
        element.IsMuzzleDevice = i.IsMuzzleDevice

        if self.MirrorVMWM then
            element.WMBone = i.Bone
        else
            element.WMBone = i.WMBone
        end

        table.insert(elements, element)
    end

end

function SWEP:SetupModel(wm)
    local elements = {}

    if !wm and !self:GetOwner():IsPlayer() then return end

    local og = weapons.Get(self:GetClass())

    self.PrintName = self.OldPrintName or og.PrintName

    self:GetActiveElements(true)

    if CLIENT then

    if wm then
        self:KillModel(self.WM)
        self.WM = elements
    else
        self:KillModel(self.VM)
        self.VM = elements

        if !IsValid(self:GetOwner()) or self:GetOwner():IsNPC() then
            return
        end

        if !IsValid(self:GetOwner():GetViewModel()) then
            self:SetTimer(0.5, function()
                self:SetupModel(wm)
            end)
            return
        end

        self:GetOwner():GetViewModel():SetupBones()
    end

    render.OverrideDepthEnable( true, true )

    end

    if wm and CLIENT then
        local sm = self.WorldModel
        if self.MirrorVMWM then
            sm = self.ViewModel
        end
        local model = ClientsideModel(sm)

        if !model then return end
        if !IsValid(model) then return end

        model:SetNoDraw(ArcCW.NoDraw)
        model:DrawShadow(true)
        model:SetPredictable(false)
        model.Weapon = self
        model:SetSkin(self.DefaultWMSkin or 0)
        model:SetBodyGroups(self.DefaultWMBodygroups or "")
        model:SetupBones()
        local element = {}
        element.Model = model
        element.WM = true
        element.IsBaseWM = true
        element.WMBone = "ValveBiped.Bip01_R_Hand"

        if self.WorldModelOffset then
            if !self:GetOwner():IsValid() then
                element.OffsetAng = Angle(0, 0, 0)
                element.OffsetPos = Vector(0, 0, 0)
            else
                element.OffsetAng = self.WorldModelOffset.ang or Angle(0, 0, 0)
                element.OffsetPos = self.WorldModelOffset.pos or Vector(0, 0, 0)
                element.WMBone = self.WorldModelOffset.bone or element.WMBone
            end
            element.BoneMerge = false
        else
            model:SetParent(self:GetOwner() or self)
            model:AddEffects(EF_BONEMERGE)
            element.BoneMerge = true
            element.OffsetAng = Angle(0, 0, 0)
        end

        self.WMModel = model

        table.insert(elements, element)
    end

    for _, k in pairs(self.DefaultElements) do
        self:AddElement(k, wm)
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        if self.AttachmentElements[k.Installed] then
            self:AddElement(k.Installed, wm)
        end

        if k.InstalledEles then
            for _, ele in pairs(k.InstalledEles or {}) do
                self:AddElement(ele, wm)
            end
        end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        for _, ele in pairs(atttbl.ActivateElements or {}) do
            self:AddElement(ele, wm)
        end

        local slots = atttbl.Slot

        if isstring(slots) then
            slots = {slots}
        end

        for _, ele in pairs(slots) do
            self:AddElement(ele, wm)
        end

        if atttbl.AddPrefix then
            self.PrintName = atttbl.AddPrefix .. self.PrintName
        end

        if atttbl.AddSuffix then
            self.PrintName = self.PrintName .. atttbl.AddSuffix
        end

        if !GetConVar("arccw_att_showothers"):GetBool() and CLIENT and LocalPlayer() != self:GetOwner() then
            continue
        end

        if SERVER then continue end

        if wm and k.NoWM then continue end
        if !wm and k.NoVM then continue end

        if !atttbl.Model then continue end
        if atttbl.HideModel then continue end

        if !k.Offset and !atttbl.BoneMerge then continue end

        local model = ClientsideModel(atttbl.Model)

        if !model or !IsValid(model) then continue end

        if atttbl.BoneMerge then
            local parent = self:GetOwner():GetViewModel()

            if wm then
                parent = self:GetOwner()
            end

            model:SetParent(parent)
            model:AddEffects(EF_BONEMERGE)
        else
            model:SetParent(self)
        end

        local repbone = nil
        local repang = nil

        for _, e in pairs(self:GetActiveElements()) do
            local ele = self.AttachmentElements[e]

            if !ele then continue end

            if ((ele.AttPosMods or {})[i] or {}).bone then
                repbone = ele.AttPosMods.bone
            end

            if wm then
                if ((ele.AttPosMods or {})[i] or {}).wmang then
                    repang = ele.AttPosMods.wmang
                end
            else
                if ((ele.AttPosMods or {})[i] or {}).vmang then
                    repang = ele.AttPosMods.vmang
                end
            end
        end

        local element = {}

        local scale = Matrix()

        if wm then
            scale:Scale((k.WMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
        else
            scale:Scale((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
        end

        model:SetNoDraw(ArcCW.NoDraw)
        model:DrawShadow(true)
        model:SetPredictable(false)
        model.Weapon = self
        model:SetSkin(atttbl.ModelSkin or 0)
        model:SetBodyGroups(atttbl.ModelBodygroups or "")
        model:SetupBones()
        model:EnableMatrix("RenderMultiply", scale)
        element.Model = model
        element.DrawFunc = atttbl.DrawFunc
        element.WM = wm or false
        element.Bone = repbone or k.Bone
        element.NoDraw = atttbl.NoDraw or false
        element.BoneMerge = k.BoneMerge or false
        element.Bodygroups = atttbl.ModelBodygroups
        element.DrawFunc = atttbl.DrawFunc
        element.Slot = i
        element.ModelOffset = atttbl.ModelOffset or Vector(0, 0, 0)

        if wm then
            element.OffsetAng = Angle()
            element.OffsetAng:Set(repang or k.Offset.wang or Angle(0, 0, 0))
            element.OffsetAng = element.OffsetAng + (atttbl.OffsetAng or Angle(0, 0, 0))
            k.WElement = element

            if self.MirrorVMWM then
                element.WMBone = repbone or k.Bone
                element.OffsetAng = Angle()
                element.OffsetAng:Set(repang or k.Offset.vang or Angle(0, 0, 0))
                element.OffsetAng = element.OffsetAng + (atttbl.OffsetAng or Angle(0, 0, 0))
            else
                element.WMBone = k.WMBone or "ValveBiped.Bip01_R_Hand"
            end
        else
            element.OffsetAng = Angle()
            element.OffsetAng:Set(repang or k.Offset.vang or Angle(0, 0, 0))
            element.OffsetAng = element.OffsetAng + (atttbl.OffsetAng or Angle(0, 0, 0))
            k.VMOffsetAng = element.OffsetAng
            k.VElement = element
        end

        table.insert(elements, element)

        if atttbl.Charm and atttbl.CharmModel then
            local charmmodel = ClientsideModel(atttbl.CharmModel)

            local charmscale = Matrix()

            if wm then
                if self.MirrorVMWM then
                    charmscale:Scale((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                else
                    charmscale:Scale((k.WMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                end
            else
                charmscale:Scale((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
            end

            charmscale:Scale(atttbl.CharmScale or Vector(1, 1, 1))

            if IsValid(charmmodel) then
                charmmodel:SetNoDraw(ArcCW.NoDraw)
                charmmodel:DrawShadow(true)
                charmmodel:SetupBones()
                charmmodel:EnableMatrix("RenderMultiply", charmscale)
                charmmodel:SetSkin(atttbl.CharmSkin or 0)
                charmmodel:SetBodyGroups(atttbl.CharmBodygroups or "")

                local charmelement = {}
                charmelement.Model = charmmodel
                charmelement.CharmOffset = atttbl.CharmOffset or Vector(0, 0, 0)
                charmelement.CharmAngle = atttbl.CharmAngle or Angle(0, 0, 0)
                charmelement.CharmAtt = atttbl.CharmAtt or "charm"
                charmelement.CharmParent = element
                charmelement.SubModel = true

                if wm then
                    if self.MirrorVMWM then
                        charmelement.CharmScale = ((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                    else
                        charmelement.CharmScale = ((k.WMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                    end
                else
                    charmelement.CharmScale = ((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                end

                table.insert(elements, charmelement)
            end
        end

        if atttbl.IsMuzzleDevice or atttbl.UBGL then
            local hspmodel = ClientsideModel(atttbl.Model)

            if k.BoneMerge then
                local parent = self:GetOwner():GetViewModel()

                if wm then
                    parent = self:GetOwner()
                end

                hspmodel:SetParent(parent)
                hspmodel:AddEffects(EF_BONEMERGE)
            else
                hspmodel:SetParent(self)
            end

            local hspelement = {}
            hspmodel:SetNoDraw(true)
            hspmodel:DrawShadow(true)
            hspmodel:SetPredictable(false)
            hspmodel.Weapon = self

            hspelement.Model = hspmodel
            hspmodel:EnableMatrix("RenderMultiply", scale)

            hspelement.WM = wm or false
            hspelement.Bone = repbone or k.Bone
            hspelement.NoDraw = true
            hspelement.BoneMerge = k.BoneMerge or false
            hspelement.Slot = i
            hspelement.WMBone = k.WMBone

            hspelement.OffsetAng = element.OffsetAng

            if atttbl.IsMuzzleDevice then
                hspelement.IsMuzzleDevice = true
            end

            if wm then
                k.WMuzzleDeviceElement = hspelement

                if self.MirrorVMWM then
                    hspelement.WMBone = k.Bone
                end
            else
                k.VMuzzleDeviceElement = hspelement
            end

            table.insert(elements, hspelement)
        else
            k.VMuzzleDeviceElement = nil
            k.WMuzzleDeviceElement = nil
        end

        if atttbl.HolosightPiece then
            local hspmodel = ClientsideModel(atttbl.HolosightPiece)

            if k.BoneMerge then
                local parent = self:GetOwner():GetViewModel()

                if wm then
                    parent = self:GetOwner()
                end

                hspmodel:SetParent(parent)
                hspmodel:AddEffects(EF_BONEMERGE)
            else
                hspmodel:SetParent(self)
            end

            local hspelement = {}
            hspmodel:SetNoDraw(true)
            hspmodel:DrawShadow(true)
            hspmodel:SetPredictable(false)
            hspmodel:EnableMatrix("RenderMultiply", scale)
            hspmodel.Weapon = self

            hspelement.Model = hspmodel

            hspelement.WM = wm or false
            hspelement.Bone = repbone or k.Bone
            hspelement.NoDraw = atttbl.NoDraw or false
            hspelement.BoneMerge = k.BoneMerge or false
            hspelement.Slot = i
            hspelement.WMBone = k.WMBone

            hspelement.ModelOffset = atttbl.ModelOffset
            hspelement.OffsetAng = element.OffsetAng

            if !wm then
                k.HSPElement = hspelement
            else
                if self.MirrorVMWM then
                    hspelement.WMBone = k.Bone
                end
            end

            table.insert(elements, hspelement)
        else
            k.HSPElement = nil
        end
    end

    if CLIENT then

    if !wm and self.HolosightPiece then
        local hspmodel = ClientsideModel(self.HolosightPiece)

        hspmodel:SetParent(parent)
        hspmodel:AddEffects(EF_BONEMERGE)

        local hspelement = {}
        hspmodel:SetNoDraw(true)
        hspmodel:DrawShadow(true)
        hspmodel:SetPredictable(false)
        hspmodel.Weapon = self

        hspelement.Model = hspmodel

        hspelement.WM = wm or false
        hspelement.BoneMerge = true
        hspelement.NoDraw = false

        if !wm then
            self.HSPElement = hspelement
        end

        table.insert(elements, hspelement)
    end

    local eid = self:EntIndex()

    for i, k in pairs(elements) do
        local piletab = {
            Model = k.Model,
            Weapon = self
        }

        table.insert(ArcCW.CSModelPile, piletab)
    end

    if !ArcCW.CSModels[eid] then
        ArcCW.CSModels[eid] = {
            Weapon = self
        }
    end

    if wm then
        self.WM = elements
        self:KillModel(ArcCW.CSModels[eid].WModels)
        ArcCW.CSModels[eid].WModels = elements
    else
        self.VM = elements
        self:KillModel(ArcCW.CSModels[eid].VModels)
        ArcCW.CSModels[eid].VModels = elements
    end

    render.OverrideDepthEnable( false, true )

    end

    self.PrintName = self:GetBuff_Hook("Hook_NameChange", self.PrintName) or self.PrintName

    self:SetupActiveSights()

    self:RefreshBGs()
end

function SWEP:KillModel(models)
    if !models then return end
    if table.Count(models) == 0 then return end

    for _, i in pairs(models) do
        if !isentity(i.Model) then continue end
        SafeRemoveEntity(i.Model)
    end
end

function SWEP:DrawCustomModel(wm)
    local disttoeye = self:GetPos():DistToSqr(EyePos())
    local visibility = math.pow(GetConVar("arccw_visibility"):GetInt(), 2)
    local always = false
    if GetConVar("arccw_visibility"):GetInt() < 0 then
        always = true
    end
    local models = self.VM
    local vm
    local selfmode = false

    -- self:KillModel(self.VM)
    -- self:KillModel(self.WM)
    -- self.VM = nil
    -- self.WM = nil

    if wm then
        if !self.WM then
            self:SetupModel(wm)
        end

        models = self.WM

        vm = self:GetOwner()

        if self.MirrorVMWM or !IsValid(self:GetOwner()) then
            vm = self.WMModel or self
        end

        if !vm or !IsValid(vm) then return end
    else
        if !self.VM then
            self:SetupModel(wm)
        end

        vm = self:GetOwner():GetViewModel()

        if !vm or !IsValid(vm) then return end

        models = self.VM

        -- if self.HSPElement then
        --     self.HSPElement.Model:DrawModel()
        -- end
    end

    for i, k in pairs(models) do
        if !IsValid(k.Model) then
            self:SetupModel(wm)
            return
        end

        -- local asight = self:GetActiveSights()

        -- if asight then
        --     local activeslot = asight.Slot
        --     if k.Slot == activeslot and ArcCW.Overdraw then
        --         continue
        --     end
        -- end

        if k.IsBaseWM then
            if self:GetOwner():IsValid() then
                k.Model:SetParent(self:GetOwner())
                vm = self:GetOwner()
            else
                k.Model:SetParent(self)
                vm = self
                selfmode = true
            end
        else
            if wm and self.MirrorVMWM then
                vm = self.WMModel or self
                -- vm = self
            end

            if wm then
                if !always and disttoeye >= visibility then continue end
            end
        end

        if k.BoneMerge and !k.NoDraw then
            k.Model:DrawModel()
            continue
        end

        local bonename = k.Bone

        if wm then
            bonename = k.WMBone or "ValveBiped.Bip01_R_Hand"
        end

        local bpos, bang
        local offset = k.OffsetPos

        if bonename then
            local boneindex = vm:LookupBone(bonename)

            if selfmode then
                boneindex = 0
            end

            if !boneindex then continue end

            bpos, bang = vm:GetBonePosition(boneindex)

            if bpos == vm:GetPos() then
                local bonemat = vm:GetBoneMatrix(boneindex)
                if bonemat then
                    bpos = bonemat:GetTranslation()
                    bang = bonemat:GetAngles()
                end
            end

            if k.Slot then

                local attslot = self.Attachments[k.Slot]

                local delta = attslot.SlidePos or 0.5

                local vmelemod = nil
                local wmelemod = nil
                local slidemod = nil

                for _, e in pairs(self:GetActiveElements()) do
                    local ele = self.AttachmentElements[e]

                    if !ele then continue end

                    if ((ele.AttPosMods or {})[k.Slot] or {}).vpos then
                        vmelemod = ele.AttPosMods[k.Slot].vpos
                        if self.MirrorVMWM then
                            wmelemod = ele.AttPosMods[k.Slot].vpos
                        end
                    end

                    if !self.MirrorVMWM then
                        if ((ele.AttPosMods or {})[k.Slot] or {}).wpos then
                            wmelemod = ele.AttPosMods[k.Slot].wpos
                        end
                    end

                    if ((ele.AttPosMods or {})[k.Slot] or {}).slide then
                        slidemod = ele.AttPosMods[k.Slot].slide
                    end
                end

                if wm and !self.MirrorVMWM then
                    offset = wmelemod or (attslot.Offset or {}).wpos or Vector(0, 0, 0)

                    if attslot.SlideAmount then
                        offset = LerpVector(delta, (slidemod or attslot.SlideAmount).wmin or Vector(0, 0, 0), (slidemod or attslot.SlideAmount).wmax or Vector(0, 0, 0))
                    end
                else
                    offset = vmelemod or (attslot.Offset or {}).vpos or Vector(0, 0, 0)

                    if attslot.SlideAmount then
                        offset = LerpVector(delta, (slidemod or attslot.SlideAmount).vmin or Vector(0, 0, 0), (slidemod or attslot.SlideAmount).vmax or Vector(0, 0, 0))
                    end

                    attslot.VMOffsetPos = offset
                end

            end

        end

        local apos, aang

        if bang and bpos then

            local pos = offset or Vector(0, 0, 0)
            local ang = k.OffsetAng or Angle(0, 0, 0)

            local moffset = (k.ModelOffset or Vector(0, 0, 0))

            apos = bpos + bang:Forward() * pos.x
            apos = apos + bang:Right() * pos.y
            apos = apos + bang:Up() * pos.z

            aang = Angle()
            aang:Set(bang)

            aang:RotateAroundAxis(aang:Right(), ang.p)
            aang:RotateAroundAxis(aang:Up(), ang.y)
            aang:RotateAroundAxis(aang:Forward(), ang.r)

            apos = apos + aang:Forward() * moffset.x
            apos = apos + aang:Right() * moffset.y
            apos = apos + aang:Up() * moffset.z

        elseif k.CharmParent and IsValid(k.CharmParent.Model) then
            local cm = k.CharmParent.Model
            local boneindex = cm:LookupAttachment(k.CharmAtt)
            local angpos = cm:GetAttachment(boneindex)
            if angpos then
                apos, aang = angpos.Pos, angpos.Ang

                local pos = k.CharmOffset
                local ang = k.CharmAngle
                local scale = k.CharmScale or Vector(1, 1, 1)

                apos = apos + aang:Forward() * pos.x * scale.x
                apos = apos + aang:Right() * pos.y * scale.y
                apos = apos + aang:Up() * pos.z * scale.z

                aang:RotateAroundAxis(aang:Right(), ang.p)
                aang:RotateAroundAxis(aang:Up(), ang.y)
                aang:RotateAroundAxis(aang:Forward(), ang.r)
            end
        else
            continue
        end

        if !apos or !aang then return end

        k.Model:SetPos(apos)
        k.Model:SetAngles(aang)
        k.Model:SetRenderOrigin(apos)
        k.Model:SetRenderAngles(apos)

        if k.Bodygroups then
            k.Model:SetBodyGroups(k.Bodygroups)
        end

        if k.DrawFunc then
            k.DrawFunc(self, k, wm)
        end

        if !k.NoDraw then
            k.Model:DrawModel()
        end

        if activeslot then
            if i != activeslot and ArcCW.Overdraw then
                k.Model:SetBodygroup(1, 0)
            end
        end
    end

    self:RefreshBGs()
end

SWEP.ReferencePosCache = {}

function SWEP:GetFromReference(boneid)
    if !boneid then boneid = 1 end
    if self.ReferencePosCache[boneid] then
        return self.ReferencePosCache[boneid].Pos, self.ReferencePosCache[boneid].Ang
    end

    SafeRemoveEntity(ArcCW.ReferenceModel)

    if !self.ViewModel then
        -- uh oh panic
        local og = weapons.Get(self:GetClass())
        self.ViewModel = og.ViewModel
    end

    ArcCW.ReferenceModel = ClientsideModel(self.ViewModel)

    local pos = self:GetOwner():EyePos()
    local ang = self:GetOwner():EyeAngles()

    ArcCW.ReferenceModel:SetPos(pos)
    ArcCW.ReferenceModel:SetAngles(ang)
    ArcCW.ReferenceModel:SetNoDraw(true)
    ArcCW.ReferenceModel:SetupBones()

    local id = ArcCW.ReferenceModel:LookupSequence("idle")

    ArcCW.ReferenceModel:SetSequence(id)
    ArcCW.ReferenceModel:SetCycle(0)

    -- local transform = ArcCW.ReferenceModel:GetBoneMatrix(boneid)

    -- local bpos, bang = transform:GetTranslation(), transform:GetAngles()

    local bpos, bang = ArcCW.ReferenceModel:GetBonePosition(boneid)
    if bpos == ArcCW.ReferenceModel:GetPos() then
        bpos = ArcCW.ReferenceModel:GetBoneMatrix(0):GetTranslation()
        bang = ArcCW.ReferenceModel:GetBoneMatrix(0):GetAngles()
    end

    -- SafeRemoveEntity(ArcCW.ReferenceModel)

    bpos, bang = WorldToLocal(pos, ang, bpos, bang)

    self.ReferencePosCache[boneid] = {Pos = bpos, Ang = bang}

    return bpos, bang
end