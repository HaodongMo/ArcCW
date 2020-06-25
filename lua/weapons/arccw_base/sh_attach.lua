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

function SWEP:GetBuff_Hook(buff, data)
    -- call through hook function, args = data. return nil to do nothing. return false to prevent thing from happening.

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end

        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if !atttbl then continue end

        if isfunction(atttbl[buff]) then
            local ret = atttbl[buff](self, data)

            if ret == nil then continue end

            if ret == false then return end

            data = ret
        end
    end

    local cfm = self:GetCurrentFiremode()

    if cfm and isfunction(cfm[buff]) then
        local ret = cfm[buff](self, data)

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

                if ret != nil then

                    if ret == false then return end

                    data = ret
                end
            end
        end
    end

    if isfunction(self:GetTable()[buff]) then
        local ret = self:GetTable()[buff](self, data)

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

    if self:GetTable()[buff] != nil then
        if level == 0 or (self:GetTable()[buff .. "_Priority"] and self:GetTable()[buff .. "_Priority"] > level) then
            current = self:GetTable()[buff]
            level = self:GetTable()[buff .. "_Priority"] or 1
        end
    end

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

    ArcCW.Overflow = false

    self.ActiveElementCache = eles2

    return eles2
end

function SWEP:GetMuzzleDevice(wm)
    local model = self.WM
    local muzz = self

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

function SWEP:CheckFlags(reject, need)
    local flags = self:GetWeaponFlags()

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

function SWEP:SendDetail_SlidePos(slot)
    if !self.Attachments then return end
    if !self.Attachments[slot].SlidePos then return end

    net.Start("arccw_slidepos")
    net.WriteUInt(slot, 8)
    net.WriteFloat(self.Attachments[slot].SlidePos or 0.5)
    net.SendToServer()
end

function SWEP:SendAllDetails()
    for i, k in pairs(self.Attachments) do
        self:SendDetail_SlidePos(i)
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

    if self:GetOwner():IsPlayer() then
        vm = self:GetOwner():GetViewModel()
    end

    if vm and vm:IsValid() then
        vm:SetBodyGroups(self.DefaultBodygroups)
        vm:SetMaterial(vmm)
        vm:SetColor(vmc)
        vm:SetSkin(vms)
    end

    self:SetMaterial(wmm)
    self:SetColor(wmc)
    self:SetSkin(wms)

    if self.WMModel and self.WMModel:IsValid() then
        self.WMModel:SetMaterial(wmm)
        self.WMModel:SetColor(wmc)
        self.WMModel:SetSkin(wms)
    end

    for _, e in pairs(self:GetActiveElements()) do
    local ele = self.AttachmentElements[e]

    if !ele then continue end

    if ele.VMSkin and vm and IsValid(vm) then
        vm:SetSkin(ele.VMSkin)
    end

    if self.WMModel and self.WMModel:IsValid() and ele.WMSkin then
        self.WMModel:SetSkin(ele.WMSkin)
        self:SetSkin(ele.WMSkin)
    end

    if ele.VMColor and vm and IsValid(vm) then
        vm:SetColor(ele.VMColor)
    end

    if self.WMModel and self.WMModel:IsValid() and ele.WMColor then
        self.WMModel:SetColor(ele.WMColor)
        self:SetColor(ele.WMColor)
    end

    if ele.VMMaterial and vm and IsValid(vm) then
        vm:SetMaterial(ele.VMMaterial)
    end

    if self.WMModel and self.WMModel:IsValid() and ele.WMMaterial then
        self.WMModel:SetMaterial(ele.WMMaterial)
        self:SetMaterial(ele.WMMaterial)
    end

    if ele.VMBodygroups then
        for _, i in pairs(ele.VMBodygroups) do
            if !i.ind or !i.bg then continue end

            if vm and IsValid(vm) and vm:GetBodygroup(i.ind) != i.bg then
                vm:SetBodygroup(i.ind, i.bg)
            end
        end
    end

    if ele.WMBodygroups then
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
    end

    if ele.WMBoneMods then
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
end

function SWEP:Attach(slot, attname, silent)
    silent = silent or false
    local attslot = self.Attachments[slot]
    if !attslot then return end
    if attslot.Installed == attname then return end

    if !ArcCW.EnableCustomization or !GetConVar("arccw_enable_customization"):GetBool() then
        if CLIENT and !silent then
            surface.PlaySound("items/medshotno1.wav")
        end
        return
    end

    local pick = GetConVar("arccw_atts_pickx"):GetInt()

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
            surface.PlaySound("weapons/arccw/install.wav")
        end
    else
        self:DetachAllMergeSlots(slot)
    end

    attslot.Installed = attname

    if atttbl.Breakable then
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

    self.UnReady = false

    if SERVER then
        self:NetworkWeapon()
        self:SetupModel(false)
        self:SetupModel(true)
        ArcCW:PlayerSendAttInv(self:GetOwner())
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

    if !ArcCW.EnableCustomization or !GetConVar("arccw_enable_customization"):GetBool() then
        if CLIENT then
            surface.PlaySound("items/medshotno1.wav")
        end
        return
    end

    if !self.Attachments[slot].Installed then return end

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
            surface.PlaySound("weapons/arccw/uninstall.wav")
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
    end

    self:RefreshBGs()

    self:AdjustAtts()
end

function SWEP:AdjustAtts()
    if SERVER then
        local cs = self:GetBuff_Override("Override_ChamberSize") or self.ChamberSize

        if self:Clip1() > self:GetCapacity() + cs then
            local diff = self:Clip1() - (self:GetCapacity() + cs)
            self:GetOwner():GiveAmmo(diff, self.Primary.Ammo, true)
            self:SetClip1(self:GetCapacity() + cs)
        end
    end

    if self:GetBuff_Override("UBGL_Capacity") then
        self.Secondary.ClipSize = self:GetBuff_Override("UBGL_Capacity")
    else
        self.Secondary.ClipSize = -1
    end

    if self:GetBuff_Override("UBGL_Ammo") then
        self.Secondary.Ammo = self:GetBuff_Override("UBGL_Ammo")
    else
        self.Secondary.Ammo = "none"
    end
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

function SWEP:DamageAttachment(slot, dmg)
    if !self.Attachments[slot] then return end
    if !self.Attachments[slot].Installed then return end

    self.Attachments[slot].HP = self:GetAttachmentHP(slot) - dmg

    if self:GetAttachmentHP(slot) <= 0 then
        self:Detach(slot, true)
    end
end