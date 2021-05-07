function SWEP:Deploy()
    if !IsValid(self:GetOwner()) or self:GetOwner():IsNPC() then
        return
    end

    self:InitTimers()

    self.FullyHolstered = false

    self:SetShouldHoldType()

    self:SetReloading(false)
    self:SetState(0)
    self:SetInUBGL(false)
    self:SetMagUpIn(0)

    self.LHIKAnimation = nil

    self:SetBurstCount(0)

    -- Remove me shall I interfere
    --[[if CLIENT then
        if ArcCW.LastWeapon != self then
            self:LoadPreset("autosave")
        end

        ArcCW.LastWeapon = self
    end]]

    -- Don't play anim if in vehicle. This can be caused by HL2 level changes

    if !self:GetOwner():InVehicle() then
        local prd = false

        local r_anim = self:SelectAnimation("ready")
        local d_anim = self:SelectAnimation("draw")

        if self.Animations[r_anim] and self.UnReady then
            self:PlayAnimation(r_anim, 1, true, 0, true)

            self:SetReloading(CurTime() + self:GetAnimKeyTime(r_anim))

            prd = self.Animations[r_anim].ProcDraw
        else
            self:PlayAnimation(d_anim, self:GetBuff_Mult("Mult_DrawTime"), true, 0, true)

            self:SetReloading(CurTime() + (self:GetAnimKeyTime(d_anim) * self:GetBuff_Mult("Mult_DrawTime")))

            prd = self.Animations[d_anim].ProcDraw
        end

        if prd then
            self:ProceduralDraw()
        end
    end

    if self.UnReady then
        if SERVER then
            self:InitialDefaultClip()
        end
        self.UnReady = false
    end

    if (self.AutoReload or self:GetBuff_Override("Override_AutoReload")) and (self:GetBuff_Override("Override_AutoReload") != false) then
        self:RestoreAmmo()
    else
        self:RestoreAmmo(0)
    end

    self.LHIKAnimation = nil

    timer.Simple(0, function()
        if IsValid(self) then self:SetupModel(false) end
    end)

    if SERVER then
        self:SetupShields()
        self:NetworkWeapon()
    end

    -- self:RefreshBGs()

    return true
end

function SWEP:ResetCheckpoints()
    self.CheckpointAnimation = nil

    if game.SinglePlayer() and SERVER then
        net.Start("arccw_sp_checkpoints")
        net.Broadcast()
    end
end

function SWEP:InitialDefaultClip()
    if !self.Primary.Ammo then return end
    if engine.ActiveGamemode() == "darkrp" then return end -- DarkRP is god's second biggest mistake after gmod

    if self:GetOwner() and self:GetOwner():IsPlayer() then
        if self.ForceDefaultAmmo then
            self:GetOwner():GiveAmmo(self.ForceDefaultAmmo, self.Primary.Ammo)
        elseif engine.ActiveGamemode() != "terrortown" then
            self:GetOwner():GiveAmmo(self:GetCapacity() * GetConVar("arccw_mult_defaultammo"):GetInt(), self.Primary.Ammo)
        end
    end
end

function SWEP:Initialize()
    if (!IsValid(self:GetOwner()) or self:GetOwner():IsNPC()) and self:IsValid() and self.NPC_Initialize and SERVER then
        self:NPC_Initialize()
    end

    if game.SinglePlayer() and self:GetOwner():IsValid() and SERVER then
        self:CallOnClient("Initialize")
    end

    if CLIENT then
        local class = self:GetClass()

        if self.KillIconAlias then
            killicon.AddAlias(class, self.KillIconAlias)
            class = self.KillIconAlias
        end

        local path = "arccw/weaponicons/" .. class
        local mat = Material(path)

        if !mat:IsError() then

            local tex = mat:GetTexture("$basetexture")
            if tex then
                local texpath = tex:GetName()
                killicon.Add(class, texpath, Color(255, 255, 255))
                self.WepSelectIcon = surface.GetTextureID(texpath)

                if self.ShootEntity then
                killicon.Add(self.ShootEntity, texpath, Color(255, 255, 255))
                end
            end
        end

        -- Check for incompatibile addons once 
        if LocalPlayer().ArcCW_IncompatibilityCheck != true then
            LocalPlayer().ArcCW_IncompatibilityCheck = true
            local incompatList = {}
            local addons = engine.GetAddons()
            for _, addon in pairs(addons) do
                if ArcCW.IncompatibleAddons[tostring(addon.wsid)] and addon.mounted then
                    incompatList[tostring(addon.wsid)] = addon
                end
            end
            local shouldDo = true
            -- If never show again is on, verify we have no new addons
            if file.Exists("arccw_incompatible.txt", "DATA") then
                shouldDo = false
                local oldTbl = util.JSONToTable(file.Read("arccw_incompatible.txt"))
                for id, addon in pairs(incompatList) do
                    if !oldTbl[id] then shouldDo = true break end
                end
                if shouldDo then file.Delete("arccw_incompatible.txt") end
            end
            if shouldDo and table.Count(incompatList) > 0 then
                ArcCW.MakeIncompatibleWindow(incompatList)
            end
        end
    end

    if GetConVar("arccw_equipmentsingleton"):GetBool() and self.Throwing then
        self.Singleton = true
        self.Primary.ClipSize = -1
        self.Primary.Ammo = ""
    end

    self:SetState(0)
    self:SetClip2(0)
    self:SetLastLoad(self:Clip1())

    self.Attachments["BaseClass"] = nil

    self:SetHoldType(self.HoldtypeActive)

    local og = weapons.Get(self:GetClass())

    self.RegularClipSize = og.Primary.ClipSize

    self.OldPrintName = self.PrintName

    self:InitTimers()

    if engine.ActiveGamemode() == "terrortown" then
        self:TTT_Init()
    end

    self:AdjustAtts()
end

SWEP.FullyHolstered = false
SWEP.HolsterSwitchTo = nil

function SWEP:Holster(wep)
    if self:GetOwner():IsNPC() then return end
    if wep == self then return end

    -- Props deploy to NULL
    if !IsValid(wep) then
        -- We need to go! Right! Now!
        local time = 0.25
        local anim = self:SelectAnimation("holster")
        if anim then
            self:PlayAnimation(anim, self:GetBuff_Mult("Mult_DrawTime"), true, nil, nil, nil, true)
            time = self:GetAnimKeyTime(anim) * self:GetBuff_Mult("Mult_DrawTime")
        else
            if CLIENT then
                self:ProceduralHolster()
            end
            time = time * self:GetBuff_Mult("Mult_DrawTime")
        end

        --self:SetReqEnd(true)
        self:KillTimers()

        self.FullyHolstered = true

        if CLIENT then
            self:KillFlashlights()
        end
        if SERVER then
            if self:GetBuff_Override("UBGL_UnloadOnDequip") then
                local clip = self:Clip2()

                local ammo = self:GetBuff_Override("UBGL_Ammo") or "smg1_grenade"

                if IsValid(self:GetOwner()) then
                    self:GetOwner():GiveAmmo(clip, ammo, true)
                end

                self:SetClip2(0)
            end

            self:KillShields()

            local vm = self:GetOwner():GetViewModel()

            if IsValid(vm) then
                for i = 0, vm:GetNumBodyGroups() do
                    vm:SetBodygroup(i, 0)
                end
                vm:SetSkin(0)
            end

            if self.Disposable and self:Clip1() == 0 and self:Ammo1() == 0 then
                self:GetOwner():StripWeapon(self:GetClass())
            end
        end

        return true
    end
    if self:GetBurstCount() > 0 and self:Clip1() > 0 then return false end
    if self.FullyHolstered then return true end

    local skip = GetConVar("arccw_holstering"):GetBool()

    if CLIENT and LocalPlayer() != self:GetOwner() then
        return
    end

    if game.SinglePlayer() and self:GetOwner():IsValid() and SERVER then
        self:CallOnClient("Holster")
    end

    if self:GetGrenadePrimed() then
        self:Throw()
    end

    self.Sighted = false
    self.Sprinted = false
    self:SetMagUpIn(0)

    if CLIENT and LocalPlayer() == self:GetOwner() then
        self:ToggleCustomizeHUD(false)
    end

    if !self.FullyHolstered then
        self.HolsterSwitchTo = wep
    end

    local time = 0.25
    if skip then
        local anim = self:SelectAnimation("holster")
        if anim then
            self:PlayAnimation(anim, self:GetBuff_Mult("Mult_DrawTime"), true, nil, nil, nil, true)
            time = self:GetAnimKeyTime(anim) * self:GetBuff_Mult("Mult_DrawTime")
        else
            if CLIENT then
                self:ProceduralHolster()
            end
            time = time * self:GetBuff_Mult("Mult_DrawTime")
        end
    end

    if !skip then time = 0 end

    if !self.FullyHolstered then

        self:SetReloading(CurTime() + time * 1.1)
        self:SetTimer(time, function()
            self:SetShotgunReloading(0)
            self:KillTimers()

            self.FullyHolstered = true

            self:Holster(self.HolsterSwitchTo)

            if CLIENT then
                if isstring(self.HolsterSwitchTo) then
                    self.HolsterSwitchTo = LocalPlayer():GetWeapon(self.HolsterSwitchTo)
                end
                if IsValid(self.HolsterSwitchTo) then
                    input.SelectWeapon(self.HolsterSwitchTo)
                end

                self:KillFlashlights()
            else
                if SERVER then
                    if self:GetBuff_Override("UBGL_UnloadOnDequip") then
                        local clip = self:Clip2()

                        local ammo = self:GetBuff_Override("UBGL_Ammo") or "smg1_grenade"

                        if IsValid(self:GetOwner()) then
                            self:GetOwner():GiveAmmo(clip, ammo, true)
                        end

                        self:SetClip2(0)
                    end

                    self:KillShields()

                    if IsValid(self:GetOwner()) and IsValid(self.HolsterSwitchTo) then
                        self:GetOwner():SelectWeapon(self.HolsterSwitchTo:GetClass())
                    end

                    local vm = self:GetOwner():GetViewModel()

                    if IsValid(vm) then
                        for i = 0, vm:GetNumBodyGroups() do
                            vm:SetBodygroup(i, 0)
                        end
                        vm:SetSkin(0)
                    end

                    if self.Disposable and self:Clip1() == 0 and self:Ammo1() == 0 then
                        self:GetOwner():StripWeapon(self:GetClass())
                    end
                end
            end
        end)
    end

    -- return true

    if !skip then return true end

    local vm = self:GetOwner():GetViewModel()

    vm:SetPlaybackRate(1)

    return self.FullyHolstered
end

function SWEP:ProceduralDraw()
    if game.SinglePlayer() and self:GetOwner():IsValid() then
        self:CallOnClient("ProceduralDraw")
    end

    self.InProcDraw = true
    self.ProcDrawTime = CurTime()
    self:SetTimer(0.25, function()
        self.InProcDraw = false
    end)
end

function SWEP:ProceduralHolster()
    self.InProcHolster = true
    self.ProcHolsterTime = CurTime()
    self:SetTimer(0.25 * self:GetBuff_Mult("Mult_HolsterTime"), function()
        self.InProcHolster = false
    end)
end

function SWEP:ProceduralBash()
    if game.SinglePlayer() and self:GetOwner():IsValid() then
        self:CallOnClient("ProceduralBash")
    end

    local mult = self:GetBuff_Mult("Mult_MeleeTime")
    local mt = self.MeleeTime * mult

    self.InProcBash = true
    self.ProcBashTime = CurTime()
    self:SetTimer(mt, function()
        self.InProcBash = false
    end)
end