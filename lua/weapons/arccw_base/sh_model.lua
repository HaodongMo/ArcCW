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
            eles = e.VMElements
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

local function ScaleModel(model, vscale)
    if !model then return end
    local scale = Matrix()
    scale:Scale(vscale)
    model:EnableMatrix("RenderMultiply", scale)
end

function SWEP:SetupModel(wm)
    local elements = {}

    if !wm and !self:GetOwner():IsPlayer() then return end

    local og = weapons.Get(self:GetClass())

    self.PrintName = self.OldPrintName or og.PrintName
    local prefix, suffix = "", ""

    self:GetActiveElements(true)

    if !wm then
        local vm = self:GetOwner():GetViewModel()

        vm.RenderOverride = function(v)
            if !self or !self.ArcCW then v.RenderOverride = nil return end
            local wep = LocalPlayer():GetActiveWeapon()
            if wep and !wep.ArcCW then v.RenderOverride = nil return end
            self:RefreshBGs()

            for i, k in pairs(self:GetBuff_Override("Override_CaseBGs", self.CaseBGs) or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualClip() >= i then
                    vm:SetBodygroup(k.ind, k.bg)
                else
                    vm:SetBodygroup(k.ind, 0)
                end
            end

            for i, k in pairs(self:GetBuff_Override("Override_BulletBGs", self.BulletBGs) or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualBullets() >= i then
                    vm:SetBodygroup(k.ind, k.bg)
                else
                    vm:SetBodygroup(k.ind, 0)
                end
            end

            for i, k in pairs(self:GetBuff_Override("Override_StripperClipBGs", self.StripperClipBGs) or {}) do
                if !isnumber(i) then continue end
                local bone = vm:LookupBone(k)

                if !bone then continue end

                if self:GetVisualLoadAmount() >= i then
                    vm:SetBodygroup(k.ind, k.bg)
                else
                    vm:SetBodygroup(k.ind, 0)
                end
            end

            ArcCW.VM_OverDraw = true
            v:DrawModel()
            ArcCW.VM_OverDraw = false
        end
    end

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

    local vscale = Vector(1, 1, 1)

    -- if !wm and CLIENT then
    --     local sm = self.ViewModel

    --     local model = ClientsideModel(sm)

    --     if !model then return end
    --     if !IsValid(model) then return end

    --     model:SetNoDraw(ArcCW.NoDraw)
    --     model:DrawShadow(true)
    --     model:SetPredictable(false)
    --     model.Weapon = self
    --     model:SetSkin(self.DefaultVMSkin or 0)
    --     model:SetBodyGroups(self.DefaultVMBodygroups or "")
    --     model:SetupBones()
    --     local element = {}
    --     element.Model = model

    --     model:SetParent(self:GetOwner():GetViewModel())
    --     model:AddEffects(EF_BONEMERGE)
    --     element.BoneMerge = true
    --     element.IsBaseVM = true

    --     self.VMModel = model

    --     table.insert(elements, element)
    -- end

    if wm and CLIENT then
        local sm = self.WorldModel
        if self.MirrorVMWM then
            sm = self.MirrorWorldModel or self.ViewModel
        end
        local vs = (self.WorldModelOffset or {}).scale or 1
        vscale = Vector(vs, vs, vs)
        local model = ClientsideModel(sm)

        if !model then return end
        if !IsValid(model) then return end

        model:SetNoDraw(ArcCW.NoDraw)
        model:DrawShadow(true)
        model:SetPredictable(false)
        model.Weapon = self
        model:SetSkin(self.DefaultWMSkin or 0)
        model:SetBodyGroups(self.DefaultWMBodygroups or "")
        ScaleModel(model, vscale)
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

    for _, k in pairs(self:GetActiveElements()) do
        self:AddElement(k, wm)
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        local slots = atttbl.Slot

        if isstring(slots) then
            slots = {slots}
        end

        for _, ele in pairs(slots) do
            self:AddElement(ele, wm)
        end

        if atttbl.AddPrefix then
            -- self.PrintName = atttbl.AddPrefix .. self.PrintName
            prefix = atttbl.AddPrefix .. prefix
        end

        if atttbl.AddSuffix then
            -- self.PrintName = self.PrintName .. atttbl.AddSuffix
            suffix = suffix .. atttbl.AddSuffix
        end

        if CLIENT and !GetConVar("arccw_att_showothers"):GetBool() and LocalPlayer() != self:GetOwner() then
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
                repbone = ele.AttPosMods[i].bone
            end

            if wm then
                if ((ele.AttPosMods or {})[i] or {}).wang then
                    repang = ele.AttPosMods[i].wang
                end
            else
                if ((ele.AttPosMods or {})[i] or {}).vang then
                    repang = ele.AttPosMods[i].vang
                end
            end
        end

        local element = {}

        local scale

        if wm then
            scale = (k.WMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1)
        else
            scale = (k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1)
        end

        scale = scale * vscale

        model:SetNoDraw(ArcCW.NoDraw)
        model:DrawShadow(true)
        model:SetPredictable(false)
        model.Weapon = self
        model:SetSkin(self:GetBuff_Stat("ModelSkin", i) or 0)
        model:SetBodyGroups(self:GetBuff_Stat("ModelBodygroups", i) or "")
        model:SetupBones()
        ScaleModel(model, scale)
        element.Model = model
        element.DrawFunc = atttbl.DrawFunc
        element.WM = wm or false
        element.Bone = repbone or k.Bone
        element.NoDraw = atttbl.NoDraw or false
        element.BoneMerge = k.BoneMerge or false
        element.Bodygroups = self:GetBuff_Stat("ModelBodygroups", k)
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

            local charmscale = vscale

            if wm then
                if self.MirrorVMWM then
                    charmscale = charmscale * ((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                else
                    charmscale = charmscale * ((k.WMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
                end
            else
                charmscale = charmscale * ((k.VMScale or Vector(1, 1, 1)) * (atttbl.ModelScale or 1))
            end

            charmscale = charmscale * (atttbl.CharmScale or Vector(1, 1, 1))

            if IsValid(charmmodel) then
                charmmodel:SetNoDraw(ArcCW.NoDraw)
                charmmodel:DrawShadow(true)
                charmmodel:SetupBones()
                ScaleModel(charmmodel, charmscale)
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
            ScaleModel(charmmodel, scale)

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
            ScaleModel(hspmodel, scale)
            hspmodel.Weapon = self

            hspelement.Model = hspmodel

            hspelement.WM = wm or false
            hspelement.Bone = repbone or k.Bone
            hspelement.NoDraw = atttbl.NoDraw or false
            hspelement.BoneMerge = k.BoneMerge or false
            hspelement.Slot = i
            hspelement.WMBone = k.WMBone

            hspelement.ModelOffset = atttbl.HolosightModelOffset or atttbl.ModelOffset
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

    if !wm then
    --     self:CreateFlashlightsWM()
    -- else
        self:CreateFlashlightsVM()
    end

    end

    self.PrintName = prefix .. (self:GetBuff_Hook("Hook_NameChange", self.PrintName) or self.PrintName) .. suffix
    self.Trivia_Class = self:GetBuff_Hook("Hook_ClassChange", self.Trivia_Class) or self.Trivia_Class
    self.Trivia_Desc = self:GetBuff_Hook("Hook_DescChange", self.Trivia_Desc) or self.Trivia_Desc

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

function SWEP:DrawCustomModel(wm,origin,angle)
    if ArcCW.VM_OverDraw then return end
    local disttoeye = self:GetPos():DistToSqr(EyePos())
    local visibility = math.pow(GetConVar("arccw_visibility"):GetInt(), 2)
    local always = false
    if GetConVar("arccw_visibility"):GetInt() < 0 then
        always = true
    end
    local models = self.VM
    local vm

    if origin and !angle then
        angle = Angle()
    end
    local custompos = origin and angle
    if custompos then
        wm = true --VM drawing borked
    end

    -- self:KillModel(self.VM)
    -- self:KillModel(self.WM)
    -- self.VM = nil
    -- self.WM = nil

    local vscale = 1

    if wm then
        if !self.WM then
            self:SetupModel(wm)
        end

        models = self.WM

        vm = self:GetOwner()

        if self.MirrorVMWM or !IsValid(self:GetOwner()) then
            vm = self.WMModel or self
        end

        if self.WorldModelOffset then
            vscale = self.WorldModelOffset.scale or 1
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

        if k.IsBaseVM and !custompos then
            k.Model:SetParent(self:GetOwner():GetViewModel())
            vm = self
            selfmode = true
            basewm = true
        elseif k.IsBaseWM then
            if self:GetOwner():IsValid() and !custompos then
                local wmo = self.WorldModelOffset
                if !wmo then
                    wmo = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
                end
                k.Model:SetParent(self:GetOwner())
                vm = self:GetOwner()
                k.OffsetAng = wmo.ang
                k.OffsetPos = wmo.pos
            else
                k.Model:SetParent(self)
                vm = self
                selfmode = true
                basewm = true
                k.OffsetAng = Angle(0, 0, 0)
                k.OffsetPos = Vector(0, 0, 0)
            end
        elseif wm and self:ShouldCheapWorldModel() then
            continue
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

            if !boneindex then continue end

            bpos, bang = vm:GetBonePosition(boneindex)

            if bpos == vm:GetPos() then
                local bonemat = vm:GetBoneMatrix(boneindex)
                if bonemat then
                    bpos = bonemat:GetTranslation()
                    bang = bonemat:GetAngles()
                end
            end

            if custompos and (!self.MirrorVMWM or (self.MirrorVMWM and k.Model:GetModel() == self.ViewModel) ) then
                bpos = origin
                bang = angle
            end

            if k.Slot then

                local attslot = self.Attachments[k.Slot]

                local delta = attslot.SlidePos or 0.5

                local vmelemod = nil
                local wmelemod = nil
                local slidemod = nil

                for _, e in pairs(self:GetActiveElements(true)) do
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

                    -- Why the fuck is it called 'slide'. Call it fucking SlideAmount like it is
                    -- in the fucking attachment slot you fucking cockfuck shitdick
                    if ((ele.AttPosMods or {})[k.Slot] or {}).SlideAmount then
                        slidemod = ele.AttPosMods[k.Slot].SlideAmount
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

        if k.CharmParent and IsValid(k.CharmParent.Model) then
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
        elseif bang and bpos then

            local pos = offset or Vector(0, 0, 0)
            local ang = k.OffsetAng or Angle(0, 0, 0)

            pos = pos * vscale

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
        else
            continue
        end

        if !apos or !aang then return end

        k.Model:SetPos(apos)
        k.Model:SetAngles(aang)
        k.Model:SetRenderOrigin(apos)
        k.Model:SetRenderAngles(aang)

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

    if wm then
        self:DrawFlashlightsWM()
        -- self:KillFlashlightsVM()
    else
        self:DrawFlashlightsVM()
    end

    -- self:RefreshBGs()
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

    local seq = "idle"

    seq = self.AutosolveSourceSeq or seq

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