ArcCW.ConVar_BuffMults = {
    ["Mult_Damage"] = "arccw_mult_damage",
    ["Mult_DamageMin"] = "arccw_mult_damage",
    ["Mult_DamageNPC"] = "arccw_mult_npcdamage",
    ["Mult_HipDispersion"] = "arccw_mult_hipfire",
    ["Mult_ReloadTime"] = "arccw_mult_reloadtime",
    ["Mult_SightTime"] = "arccw_mult_sighttime",
    ["Mult_Range"] = "arccw_mult_range",
    ["Mult_Recoil"] = "arccw_mult_recoil",
    ["Mult_MoveDispersion"] = "arccw_mult_movedisp",
    ["Mult_Penetration"] = "arccw_mult_penetration"
}

SWEP.TickCache_Overrides = {}
SWEP.TickCache_Adds = {}
SWEP.TickCache_Mults = {}
SWEP.TickCache_Hooks = {}

SWEP.TickCache_Tick_Overrides = {}
SWEP.TickCache_Tick_Adds = {}
SWEP.TickCache_Tick_Mults = {}

SWEP.AttCache_Hooks = {}

function SWEP:RecalcAllBuffs()
    self.TickCache_Overrides = {}
    self.TickCache_Adds = {}
    self.TickCache_Mults = {}
    self.TickCache_Hooks = {}

    self.TickCache_Tick_Overrides = {}
    self.TickCache_Tick_Adds = {}
    self.TickCache_Tick_Mults = {}

    self.AttCache_Hooks = {}
end

function SWEP:GetBuff_Hook(buff, data)
    -- call through hook function, args = data. return nil to do nothing. return false to prevent thing from happening.

    -- Fesiug, this will only work if you have just one hook.
    -- if self.TickCache_Hooks[buff] and self.TickCache_Tick_Hooks[buff] == CurTime() then
    --     hook.Call(buff, ArcCW, self, data)
    --     return data
    -- end

    if self.AttCache_Hooks[buff] then
        for i, k in pairs(self.AttCache_Hooks[buff]) do
            local ret = k(self, data)

            if ret == nil then continue end

            if ret == false then return end

            data = ret
        end

        hook.Call(buff, ArcCW, self, data)

        return data
    else
        self.AttCache_Hooks[buff] = {}
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if !atttbl then continue end

        if isfunction(atttbl[buff]) then
            local ret = atttbl[buff](self, data)

            table.insert(self.AttCache_Hooks[buff], atttbl[buff])

            if ret == nil then continue end

            if ret == false then return end

            data = ret
        end
    end

    local cfm = self:GetCurrentFiremode()

    if cfm and isfunction(cfm[buff]) then
        local ret = cfm[buff](self, data)

        table.insert(self.AttCache_Hooks[buff], cfm[buff])

        hasany = true

        if ret != nil then

            if ret == false then return end

            data = ret

        end
    end

    for i, e in pairs(self:GetActiveElements()) do
        local ele = self.AttachmentElements[e]

        if ele then
            if ele[buff] then
                local ret = ele[buff](self, data)

                table.insert(self.AttCache_Hooks[buff], ele[buff])

                hasany = true

                if ret != nil then

                    if ret == false then return end

                    data = ret
                end
            end
        end
    end

    if isfunction(self:GetTable()[buff]) then
        local ret = self:GetTable()[buff](self, data)

        table.insert(self.AttCache_Hooks[buff], self:GetTable()[buff])

        hasany = true

        if ret != nil then

            if ret == false then return end

            data = ret

        end
    end

    hook.Call(buff, ArcCW, self, data)

    return data
end

function SWEP:GetBuff_Override(buff)
    local level = 0
    local current = nil
    local winningslot = nil

    if self.TickCache_Overrides[buff] then
        current = self.TickCache_Overrides[buff][1]
        winningslot = self.TickCache_Overrides[buff][2]

        local data = {
            buff = buff,
            current = current,
            winningslot = winningslot
        }

        if !ArcCW.BuffStack then

            ArcCW.BuffStack = true

            local out = (self:GetBuff_Hook("O_Hook_" .. buff, data) or {})

            current = out.current or current
            winningslot = out.winningslot or winningslot

            ArcCW.BuffStack = false

        end

        return current, winningslot
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if !atttbl then continue end

        if atttbl[buff] != nil then
            if level == 0 or (atttbl[buff .. "_Priority"] and atttbl[buff .. "_Priority"] > level) then
                current = atttbl[buff]
                level = atttbl[buff .. "_Priority"] or 1
                winningslot = i
            end
        end
    end

    if !ArcCW.BuffStack then

        ArcCW.BuffStack = true

        local cfm = self:GetCurrentFiremode()

        if cfm and cfm[buff] != nil then
            if level == 0 or (cfm[buff .. "_Priority"] and cfm[buff .. "_Priority"] > level) then
                current = cfm[buff]
                level = cfm[buff .. "_Priority"] or 1
            end
        end

        ArcCW.BuffStack = false

    end

    if !ArcCW.BuffStack then

        ArcCW.BuffStack = true

        for i, e in pairs(self:GetActiveElements()) do
            local ele = self.AttachmentElements[e]

            if ele then
                if ele[buff] != nil then
                    if level == 0 or (ele[buff .. "_Priority"] and ele[buff .. "_Priority"] > level) then
                        current = ele[buff]
                        level = ele[buff .. "_Priority"] or 1
                        winningslot = i
                    end
                end
            end
        end

        ArcCW.BuffStack = false

    end

    if self:GetTable()[buff] != nil then
        if level == 0 or (self:GetTable()[buff .. "_Priority"] and self:GetTable()[buff .. "_Priority"] > level) then
            current = self:GetTable()[buff]
            level = self:GetTable()[buff .. "_Priority"] or 1
        end
    end

    self.TickCache_Overrides[buff] = {current, winningslot}

    local data = {
        buff = buff,
        current = current,
        winningslot = winningslot
    }

    if !ArcCW.BuffStack then

        ArcCW.BuffStack = true

        current = (self:GetBuff_Hook("O_Hook_" .. buff, data) or {}).current or current

        ArcCW.BuffStack = false

    end

    return current, winningslot
end

function SWEP:GetBuff_Mult(buff)
    local mult = 1

    if self.TickCache_Mults[buff] then
        mult = self.TickCache_Mults[buff]
        local data = {
            buff = buff,
            mult = mult
        }

        if !ArcCW.BuffStack then

            ArcCW.BuffStack = true

            mult = (self:GetBuff_Hook("M_Hook_" .. buff, data) or {}).mult or mult

            ArcCW.BuffStack = false

        end

        return mult
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl[buff] then
            mult = mult * atttbl[buff]
        end
    end

    local cfm = self:GetCurrentFiremode()

    if cfm and cfm[buff] then
        mult = mult * cfm[buff]
    end

    if self:GetTable()[buff] then
        mult = mult * self:GetTable()[buff]
    end

    if ArcCW.ConVar_BuffMults[buff] then
        mult = mult * GetConVar(ArcCW.ConVar_BuffMults[buff]):GetFloat()
    end

    for i, e in pairs(self:GetActiveElements()) do
        local ele = self.AttachmentElements[e]

        if ele then
            if ele[buff] then
                mult = mult * ele[buff]
            end
        end
    end

    self.TickCache_Mults[buff] = mult

    local data = {
        buff = buff,
        mult = mult
    }

    if !ArcCW.BuffStack then

        ArcCW.BuffStack = true

        mult = (self:GetBuff_Hook("M_Hook_" .. buff, data) or {}).mult or mult

        ArcCW.BuffStack = false

    end

    return mult
end

function SWEP:GetBuff_Add(buff)
    local add = 0

    if self.TickCache_Adds[buff] then
        add = self.TickCache_Adds[buff]

        if !ArcCW.BuffStack then

            ArcCW.BuffStack = true

            add = (self:GetBuff_Hook("A_Hook_" .. buff, data) or {}).add or add

            ArcCW.BuffStack = false

        end

        return add
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl[buff] then
            add = add + atttbl[buff]
        end
    end

    local cfm = self:GetCurrentFiremode()

    if cfm and cfm[buff] then
        add = add + cfm[buff]
    end

    for i, e in pairs(self:GetActiveElements()) do
        local ele = self.AttachmentElements[e]

        if ele then
            if ele[buff] then
                add = add + ele[buff]
            end
        end
    end

    self.TickCache_Adds[buff] = add

    local data = {
        buff = buff,
        add = add
    }

    if !ArcCW.BuffStack then

        ArcCW.BuffStack = true

        add = (self:GetBuff_Hook("A_Hook_" .. buff, data) or {}).add or add

        ArcCW.BuffStack = false

    end

    return add
end

SWEP.ActiveElementCache = nil

function SWEP:GetActiveElements(recache)
    if self.ActiveElementCache and !recache then return self.ActiveElementCache end
    if ArcCW.Overflow and self.ActiveElementCache then return self.ActiveElementCache end

    local eles = {}

    for _, i in pairs(self.Attachments) do
        if !i.Installed then continue end

        if i.InstalledEles then
            table.Add(eles, i.InstalledEles)
        end

        local atttbl = ArcCW.AttachmentTable[i.Installed]

        if atttbl.ActivateElements then
            table.Add(eles, atttbl.ActivateElements)
        end

        local slots = atttbl.Slot

        if isstring(slots) then
            slots = {slots}
        end

        table.Add(eles, slots or {})

        table.insert(eles, i.Installed)
    end

    table.Add(eles, self.DefaultElements)

    local mode = self:GetCurrentFiremode()
    table.Add(eles, (mode or {}).ActivateElements or {})

    local eles2 = {}

    ArcCW.Overflow = true

    for f, i in pairs(eles) do
        local e = self.AttachmentElements[i]

        if !e then continue end

        if !self:CheckFlags(e.ExcludeFlags, e.RequireFlags) then continue end

        local a = false
        local c = 0

        for g = f, table.Count(eles) do
            if eles[g] == i then c = c + 1 end

            if c > 1 then a = true break end
        end

        if a then continue end

        table.insert(eles2, i)
    end

    table.Add(eles2, self:GetWeaponFlags())

    ArcCW.Overflow = false

    self.ActiveElementCache = eles2

    return eles2
end

function SWEP:GetMuzzleDevice(wm)
    local model = self.WM
    local muzz = self.WMModel or self

    if !wm then
        model = self.VM
        muzz = self:GetOwner():GetViewModel()
    end

    if model then
        for _, ele in pairs(model) do
            if ele.IsMuzzleDevice then
                muzz = ele.Model or muzz
            end
        end
    end

    if self:GetNWBool("ubgl") then
        local _, slot = self:GetBuff_Override("UBGL")

        if wm then
            muzz = (self.Attachments[slot].WMuzzleDeviceElement or {}).Model or muzz
        else
            muzz = (self.Attachments[slot].VMuzzleDeviceElement or {}).Model or muzz
        end
    end

    return muzz
end

function SWEP:GetTracerOrigin()
    -- local wm = self:GetOwner():ShouldDrawLocalPlayer()
    -- local muzz = self:GetMuzzleDevice(wm)

    -- if muzz then
    --     local pos = muzz:GetAttachment(1).Pos

    --     return pos
    -- end
end

function SWEP:CheckFlags(reject, need)
    local flags
    if ArcCW.Overflow then
        flags = {}
    else
        flags = self:GetActiveElements()
    end

    reject = reject or {}
    need = need or {}

    for _, i in pairs(reject) do
        if table.HasValue(flags, i) then
            return false
        end
    end

    for _, i in pairs(need) do
        if !table.HasValue(flags, i) then
            return false
        end
    end

    return true
end

function SWEP:GetWeaponFlags()
    local flags = {}

    for _, i in pairs(self.Attachments) do
        if !i.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[i.Installed]

        if atttbl.GivesFlags then
            table.Add(flags, atttbl.GivesFlags)
        end

        if i.GivesFlags then
            table.Add(flags, i.GivesFlags)
        end

        table.Add(flags, i.Installed)
    end

    return flags
end

function SWEP:PlayerOwnsAtt(att)
    local qty = ArcCW:PlayerGetAtts(self:GetOwner(), att)

    return qty > 0
end

function SWEP:NetworkWeapon(sendto)
    net.Start("arccw_networkatts")
    net.WriteEntity(self) -- self entity

    net.WriteUInt(table.Count(self.Attachments), 8)

    for _, i in pairs(self.Attachments) do
        if !i.Installed then net.WriteUInt(0, ArcCW.GetBitNecessity()) continue end

        local atttbl = ArcCW.AttachmentTable[i.Installed]
        local id = atttbl.ID

        net.WriteUInt(id, ArcCW.GetBitNecessity())

        if i.SlideAmount then
            net.WriteFloat(i.SlidePos or 0.5)
        end

        -- if atttbl.ColorOptionsTable then
        --     net.WriteUInt(i.ColorOptionIndex or 1, 8) -- look if you want more than 256 fucking color options you're insane and stupid and just don't ok
        -- end
    end

    if sendto then
        net.Send(sendto)
    else
        net.Broadcast()
    end
end

function SWEP:SendDetail_ColorIndex(slot)
    net.Start("arccw_colorindex")
    net.WriteUInt(slot, 8)
    net.WriteUInt(self.Attachments[slot].ColorOptionIndex)
    net.SendToServer()
end

function SWEP:SendDetail_SlidePos(slot, hmm)
    if !self.Attachments then return end
    if !self.Attachments[slot].SlidePos then return end

    net.Start("arccw_slidepos")
    net.WriteUInt(slot, 8)
    net.WriteFloat(self.Attachments[slot].SlidePos or 0.5)
    net.SendToServer()
end

function SWEP:SendAllDetails()
    for i, k in pairs(self.Attachments) do
        self:SendDetail_SlidePos(i, true)
    end
end

function SWEP:CountAttachments()
    local total = 0

    for _, i in pairs(self.Attachments) do
        if i.Installed and !i.FreeSlot then
            total = total + 1
        end
    end

    return total
end

function SWEP:RefreshBGs()
    local vm

    local vmm = self:GetBuff_Override("Override_VMMaterial") or ""
    local wmm = self:GetBuff_Override("Override_WMMaterial") or ""

    local vmc = self:GetBuff_Override("Override_VMColor") or Color(255, 255, 255)
    local wmc = self:GetBuff_Override("Override_WMColor") or Color(255, 255, 255)

    local vms = self:GetBuff_Override("Override_VMSkin") or self.DefaultSkin
    local wms = self:GetBuff_Override("Override_WMSkin") or self.DefaultWMSkin

    local vmp = self.DefaultPoseParams
    local wmp = self.DefaultWMPoseParams

    if self.MirrorVMWM then
        wmm = vmm
        wmc = vmc
        wms = vms
        wmp = vmp
    end

    if self:GetOwner():IsPlayer() then
        vm = self:GetOwner():GetViewModel()
    end

    if vm and vm:IsValid() then
        vm:SetBodyGroups(self.DefaultBodygroups)
        vm:SetMaterial(vmm)
        vm:SetColor(vmc)
        vm:SetSkin(vms)

        vmp["BaseClass"] = nil

        for i, k in pairs(vmp) do
            vm:SetPoseParameter(i, k)
        end
    end

    self:SetMaterial(wmm)
    self:SetColor(wmc)
    self:SetSkin(wms)

    if self.WMModel and self.WMModel:IsValid() then
        if self.MirrorVMWM then
            self.WMModel:SetBodyGroups(self.DefaultBodygroups)
        else
            self.WMModel:SetBodyGroups(self.DefaultWMBodygroups)
        end
        self.WMModel:SetMaterial(wmm)
        self.WMModel:SetColor(wmc)
        self.WMModel:SetSkin(wms)

        wmp["BaseClass"] = nil

        for i, k in pairs(wmp) do
            self.WMModel:SetPoseParameter(i, k)
        end
    end

    local ae = self:GetActiveElements()

    for _, e in pairs(ae) do
        local ele = self.AttachmentElements[e]

        if !ele then continue end

        if ele.VMPoseParams and vm and IsValid(vm) then
            ele.VMPoseParams["BaseClass"] = nil
            for i, k in pairs(ele.VMPoseParams) do
                vm:SetPoseParameter(i, k)
            end
        end

        if self.WMModel and self.WMModel:IsValid() then
            if self.MirrorVMWM and ele.VMPoseParams then
                ele.VMPoseParams["BaseClass"] = nil
                for i, k in pairs(ele.VMPoseParams) do
                    self.WMModel:SetPoseParameter(i, k)
                end
            elseif ele.WMPoseParams then
                ele.WMPoseParams["BaseClass"] = nil
                for i, k in pairs(ele.WMPoseParams) do
                    self.WMModel:SetPoseParameter(i, k)
                end
            end
        end

        if ele.VMSkin and vm and IsValid(vm) then
            vm:SetSkin(ele.VMSkin)
        end

        if self.WMModel and self.WMModel:IsValid() then
            if self.MirrorVMWM and ele.VMSkin then
                self.WMModel:SetSkin(ele.VMSkin)
                self:SetSkin(ele.VMSkin)
            elseif ele.WMSkin then
                self.WMModel:SetSkin(ele.WMSkin)
                self:SetSkin(ele.WMSkin)
            end
        end

        if ele.VMColor and vm and IsValid(vm) then
            vm:SetColor(ele.VMColor)
        end

        if self.WMModel and self.WMModel:IsValid() then
            if self.MirrorVMWM and ele.VMSkin then
                self.WMModel:SetColor(ele.VMColor)
                self:SetColor(ele.VMColor)
            elseif ele.WMSkin then
                self.WMModel:SetColor(ele.WMColor)
                self:SetColor(ele.WMColor)
            end
        end

        if ele.VMMaterial and vm and IsValid(vm) then
            vm:SetMaterial(ele.VMMaterial)
        end

        if self.WMModel and self.WMModel:IsValid() then
            if self.MirrorVMWM and ele.VMMaterial then
                self.WMModel:SetMaterial(ele.VMMaterial)
                self:SetMaterial(ele.VMMaterial)
            elseif ele.WMMaterial then
                self.WMModel:SetMaterial(ele.WMMaterial)
                self:SetMaterial(ele.WMMaterial)
            end
        end

        if ele.VMBodygroups then
            for _, i in pairs(ele.VMBodygroups) do
                if !i.ind or !i.bg then continue end

                if vm and IsValid(vm) and vm:GetBodygroup(i.ind) != i.bg then
                    vm:SetBodygroup(i.ind, i.bg)
                end
            end

            if self.MirrorVMWM then
                for _, i in pairs(ele.VMBodygroups) do
                    if !i.ind or !i.bg then continue end

                    if self.WMModel and IsValid(self.WMModel) and self.WMModel:GetBodygroup(i.ind) != i.bg then
                        self.WMModel:SetBodygroup(i.ind, i.bg)
                    end

                    if self:GetBodygroup(i.ind) != i.bg then
                        self:SetBodygroup(i.ind, i.bg)
                    end
                end
            end
        end

        if ele.WMBodygroups and !self.MirrorVMWM then
            for _, i in pairs(ele.WMBodygroups) do
                if !i.ind or !i.bg then continue end

                if self.WMModel and IsValid(self.WMModel) and self.WMModel:GetBodygroup(i.ind) != i.bg then
                    self.WMModel:SetBodygroup(i.ind, i.bg)
                end

                if self:GetBodygroup(i.ind) != i.bg then
                    self:SetBodygroup(i.ind, i.bg)
                end
            end
        end

        if ele.VMBoneMods then
            for bone, i in pairs(ele.VMBoneMods) do
                local boneind = vm:LookupBone(bone)

                if !boneind then continue end

                vm:ManipulateBonePosition(boneind, i)
            end

            if self.MirrorVMWM then
                for bone, i in pairs(ele.VMBoneMods) do
                    if !(self.WMModel and self.WMModel:IsValid()) then break end
                    local boneind = self:LookupBone(bone)

                    if !boneind then continue end

                    self:ManipulateBonePosition(boneind, i)
                end
            end
        end

        if ele.WMBoneMods and !self.MirrorVMWM then
            for bone, i in pairs(ele.WMBoneMods) do
                if !(self.WMModel and self.WMModel:IsValid()) then break end
                local boneind = self:LookupBone(bone)

                if !boneind then continue end

                self:ManipulateBonePosition(boneind, i)
            end
        end



        if SERVER then
            self:SetupShields()
        end
    end

    if vm and vm:IsValid() then
        self:GetBuff_Hook("Hook_ModifyBodygroups", {vm = vm, eles = ae})
    end
    self:GetBuff_Hook("Hook_ModifyBodygroups", {vm = self.WMModel or self, eles = ae})
end

function SWEP:GetPickX()
    return GetConVar("arccw_atts_pickx"):GetInt()
end

function SWEP:Attach(slot, attname, silent)
    silent = silent or false
    local attslot = self.Attachments[slot]
    if !attslot then return end
    if attslot.Installed == attname then return end

    if !ArcCW:PlayerCanAttach(self:GetOwner(), self, attname, slot, false) then
        if CLIENT and !silent then
            surface.PlaySound("items/medshotno1.wav")
        end
        return
    end

    local pick = self:GetPickX()

    if pick > 0 then
        if self:CountAttachments() >= pick and !attslot.FreeSlot then
            if CLIENT and !silent then
                surface.PlaySound("items/medshotno1.wav")
            end
            return
        end
    end

    if !self:CheckFlags(attslot.ExcludeFlags, attslot.RequireFlags) then return end

    local atttbl = ArcCW.AttachmentTable[attname]

    if !atttbl then return end
    if !ArcCW:SlotAcceptsAtt(attslot.Slot, self, attname) then return end
    if !self:CheckFlags(atttbl.ExcludeFlags, atttbl.RequireFlags) then return end
    if !self:PlayerOwnsAtt(attname) then return end

    if attslot.SlideAmount then
        attslot.SlidePos = 0.5
    end

    if atttbl.MountPositionOverride then
        attslot.SlidePos = atttbl.MountPositionOverride
    end

    if atttbl.AdditionalSights then
        self.SightMagnifications = {}
    end

    if CLIENT then
        -- we are asking to attach something

        self:SendAllDetails()

        net.Start("arccw_asktoattach")
        net.WriteUInt(slot, 8)
        net.WriteUInt(atttbl.ID, 24)
        net.SendToServer()

        if !silent then
            surface.PlaySound(atttbl.AttachSound or "weapons/arccw/install.wav")
        end
    else
        self:DetachAllMergeSlots(slot)
    end

    attslot.Installed = attname

    if atttbl.Health then
        attslot.HP = self:GetAttachmentMaxHP(slot)
    end

    if atttbl.ColorOptionsTable then
        attslot.ColorOptionIndex = 1
    end

    ArcCW:PlayerTakeAtt(self:GetOwner(), attname)

    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes
    local fmi = self:GetNWInt("firemode", 1)

    if fmi > table.Count(fmt) then
        self:SetNWInt("firemode", 1)
    end

    --self.UnReady = false

    if SERVER then
        self:NetworkWeapon()
        self:SetupModel(false)
        self:SetupModel(true)
        ArcCW:PlayerSendAttInv(self:GetOwner())

        if engine.ActiveGamemode() == "terrortown" then
            self:TTT_PostAttachments()
        end
    else
        self:SetupActiveSights()

        self.LHIKAnimation = 0
        self.LHIKAnimationStart = 0
        self.LHIKAnimationTime = 0

        self.LHIKDelta = {}
        self.LHIKDeltaAng = {}

        self.ViewModel_Hit = Vector(0, 0, 0)

        if !silent then
            self:SavePreset("autosave")
        end
    end

    self:AdjustAtts()

    for s, i in pairs(self.Attachments) do
        if !self:CheckFlags(i.ExcludeFlags, i.RequireFlags) then
            self:Detach(s, true)
        end
    end

    self:RefreshBGs()
end

function SWEP:DetachAllMergeSlots(slot, silent)
    local slots = {slot}

    table.Add(slots, self.Attachments[slot].MergeSlots or {})

    for _, i in pairs(slots) do
        self:Detach(i, silent)
    end
end

function SWEP:Detach(slot, silent)
    if !slot then return end
    if !self.Attachments[slot] then return end

    if !self.Attachments[slot].Installed then return end

    if !ArcCW:PlayerCanAttach(self:GetOwner(), self, self.Attachments[slot].Installed, slot, true) then
        if CLIENT and !silent then
            surface.PlaySound("items/medshotno1.wav")
        end
        return
    end

    local previnstall = self.Attachments[slot].Installed

    local atttbl = ArcCW.AttachmentTable[previnstall]

    if atttbl.UBGL then
        local clip = self:Clip2()

        local ammo = atttbl.UBGL_Ammo or "smg1_grenade"

        if SERVER then
            self:GetOwner():GiveAmmo(clip, ammo, true)
        end

        self:SetClip2(0)

        self:DeselectUBGL()
    end

    self.Attachments[slot].Installed = nil

    if self:GetAttachmentHP(slot) >= self:GetAttachmentMaxHP(slot) then
        ArcCW:PlayerGiveAtt(self:GetOwner(), previnstall)
    end

    if CLIENT then
        self:SendAllDetails()

        -- we are asking to detach something
        net.Start("arccw_asktodetach")
        net.WriteUInt(slot, 8)
        net.SendToServer()

        if !silent then
            surface.PlaySound(atttbl.DetachSound or "weapons/arccw/uninstall.wav")
        end

        self:SetupActiveSights()

        self.LHIKAnimation = 0
        self.LHIKAnimationStart = 0
        self.LHIKAnimationTime = 0

        if !silent then
            self:SavePreset("autosave")
        end
    else
        self:NetworkWeapon()
        self:SetupModel(false)
        self:SetupModel(true)
        ArcCW:PlayerSendAttInv(self:GetOwner())

        if engine.ActiveGamemode() == "terrortown" then
            self:TTT_PostAttachments()
        end
    end

    self:RefreshBGs()

    self:AdjustAtts()
end

function SWEP:AdjustAtts()
    self:RecalcAllBuffs()

    if SERVER then
        local cs = self:GetCapacity() + self:GetChamberSize()

        if self:Clip1() > cs then
            local diff = self:Clip1() - cs
            self:SetClip1(cs)

            if self:GetOwner():IsValid() and !self:GetOwner():IsNPC() then
                self:GetOwner():GiveAmmo(diff, self.Primary.Ammo, true)
            end
        end
    else
        local se = self:GetBuff_Override("Override_ShootEntity")
        if se then
            local path = "arccw/weaponicons/" .. self:GetClass()
            local mat = Material(path)

            if !mat:IsError() then
                local tex = mat:GetTexture("$basetexture")
                local texpath = tex:GetName()

                killicon.Add(se, texpath, Color(255, 255, 255))
            end
        end
    end

    if self:GetBuff_Override("UBGL_Capacity") then
        self.Secondary.ClipSize = self:GetBuff_Override("UBGL_Capacity")
        if GetConVar("arccw_atts_ubglautoload"):GetBool() then
            self:SetClip2(self:GetBuff_Override("UBGL_Capacity"))
        end
    else
        self.Secondary.ClipSize = -1
    end

    if self:GetBuff_Override("UBGL_Ammo") then
        self.Secondary.Ammo = self:GetBuff_Override("UBGL_Ammo")
    else
        self.Secondary.Ammo = "none"
    end

    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes

    fmt["BaseClass"] = nil

    local fmi = self:GetNWInt("firemode", 1)

    if !fmt[fmi] then fmi = 1 end

    self:SetNWInt("firemode", fmi)

    local wpn = weapons.Get(self:GetClass())

    local ammo = self:GetBuff_Override("Override_Ammo") or wpn.Primary.Ammo
    local oldammo = self.OldAmmo or self.Primary.Ammo

    if ammo != oldammo then
        self:Unload()
    end

    -- if CLIENT and self:GetOwner():GetViewModel() then
    --     self:PlayAnimation("idle")
    -- end

    self.Primary.Ammo = ammo

    self.OldAmmo = self.Primary.Ammo
end

function SWEP:GetAttachmentMaxHP(slot)
    if !self.Attachments[slot] then return 100 end
    if !self.Attachments[slot].Installed then return 100 end
    local maxhp = 100
    local atttbl = ArcCW.AttachmentTable[self.Attachments[slot].Installed]

    if atttbl.Health then
        maxhp = atttbl.Health
    end

    return maxhp
end

function SWEP:GetAttachmentHP(slot)
    if !self.Attachments[slot] then return 100 end
    if !self.Attachments[slot].Installed then return 100 end

    if self.Attachments[slot].HP then return self.Attachments[slot].HP end

    self.Attachments[slot].HP = self:GetAttachmentMaxHP(slot)

    return self.Attachments[slot].HP
end

function SWEP:ApplyAttachmentShootDamage()
    local any = false
    for j, i in pairs(self.Attachments) do
        if !i.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[i.Installed]

        if !atttbl.Health then continue end

        if atttbl.DamageOnShoot then
            self:DamageAttachment(j, atttbl.DamageOnShoot)
            any = true
        end
    end

    if any then
        self:SendAttHP()
    end
end

function SWEP:DamageAttachment(slot, dmg)
    if !self.Attachments[slot] then return end
    if !self.Attachments[slot].Installed then return end

    self.Attachments[slot].HP = self:GetAttachmentHP(slot) - dmg

    if self:GetAttachmentHP(slot) <= 0 then
        local atttbl = ArcCW.AttachmentTable[self.Attachments[slot].Installed]

        if atttbl.Hook_AttDestroyed then
            atttbl.Hook_AttDestroyed(self, {slot = slot, dmg = dmg})
        end

        self:Detach(slot, true)
    end
end

function SWEP:SendAttHP()
    net.Start("arccw_sendatthp")
    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.Health then
            net.WriteBool(true)
            net.WriteUInt(i, 8)
            net.WriteFloat(self:GetAttachmentHP(i))
        end
    end
    net.WriteBool(false)
    net.Send(self:GetOwner())
end

function SWEP:ClearSubAttachments()
end

function SWEP:AssembleAttachments()
end