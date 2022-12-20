local ang0 = Angle(0, 0, 0)
local dev_alwaysready = GetConVar("arccw_dev_alwaysready")

function SWEP:Deploy()
    if !IsValid(self:GetOwner()) or self:GetOwner():IsNPC() then
        return
    end

    if self.UnReady then
        local sp = game.SinglePlayer()

        if sp then
            if SERVER then
                self:CallOnClient("LoadPreset", "autosave")
            else
                self:LoadPreset("autosave")
            end
        else
            if SERVER then
                -- the server... can't get the client's attachments in time.
                -- can make it so client has to do a thing and tell the server it's ready,
                -- and that's probably what i'll do later.
            else
                self:LoadPreset("autosave")
            end
        end
    end

    self:InitTimers()

    self:SetShouldHoldType()

    self:SetReloading(false)
    self:SetPriorityAnim(false)
    self:SetInUBGL(false)
    self:SetMagUpCount(0)
    self:SetMagUpIn(0)
    self:SetShotgunReloading(0)
    self:SetHolster_Time(0)
    self:SetHolster_Entity(NULL)

    self:SetFreeAimAngle(ang0)
    self:SetLastAimAngle(ang0)

    self.LHIKAnimation = nil
    self.CrosshairDelta = 0

    self:SetBurstCount(0)

    self:WepSwitchCleanup()
    if game.SinglePlayer() then self:CallOnClient("WepSwitchCleanup") end

    if !self:GetOwner():InVehicle() then -- Don't play anim if in vehicle. This can be caused by HL2 level changes
        local prd = false

        local r_anim = self:SelectAnimation("ready")
        local d_anim = self:SelectAnimation("draw")

        if self.Animations[r_anim] and ( dev_alwaysready:GetBool() or self.UnReady ) then
            self:PlayAnimation(r_anim, 1, true, 0, false)
            prd = self.Animations[r_anim].ProcDraw

            self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime(r_anim, true) )
        elseif self.Animations[d_anim] then
            self:PlayAnimation(d_anim, self:GetBuff_Mult("Mult_DrawTime"), true, 0, false)
            prd = self.Animations[d_anim].ProcDraw

            self:SetPriorityAnim(CurTime() + self:GetAnimKeyTime(d_anim, true) * self:GetBuff_Mult("Mult_DrawTime"))
        end

        if prd or (!self.Animations[r_anim] and !self.Animations[d_anim]) then
            self:ProceduralDraw()
        end
    end

    self:SetState(ArcCW.STATE_DISABLE)

    if self.UnReady then
        if SERVER then
            self:InitialDefaultClip()
        end
        self.UnReady = false
    end

    if self:GetBuff_Override("Override_AutoReload", self.AutoReload) then
        self:RestoreAmmo()
    end

    timer.Simple(0, function()
        if IsValid(self) then self:SetupModel(false) end
    end)

    if SERVER then
        self:SetupShields()
        -- Networking the weapon at this time is too early - entity is not yet valid on client
        -- Instead, make client send a request when it is valid there
        --self:NetworkWeapon()
    elseif CLIENT and !self.CertainAboutAtts then
        net.Start("arccw_rqwpnnet")
            net.WriteEntity(self)
        net.SendToServer()
    end

    -- self:RefreshBGs()

    self:GetBuff_Hook("Hook_OnDeploy")

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
        if self:HasBottomlessClip() then
            self:SetClip1(0)
        end
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
        if LocalPlayer().ArcCW_IncompatibilityCheck != true and game.SinglePlayer() then
            LocalPlayer().ArcCW_IncompatibilityCheck = true

            local incompatList = {}
            local addons = engine.GetAddons()
            for _, addon in pairs(addons) do
                if ArcCW.IncompatibleAddons[tostring(addon.wsid)] and addon.mounted then
                    incompatList[tostring(addon.wsid)] = addon
                end
            end

            local predrawvmhooks = hook.GetTable().PreDrawViewModel
            if predrawvmhooks and (predrawvmhooks.DisplayDistancePlaneLS or predrawvmhooks.DisplayDistancePlane) then -- vtools lua breaks arccw with stupid return in vm hook, ya dont need it if you going to play with guns
                hook.Remove("PreDrawViewModel", "DisplayDistancePlane")
                hook.Remove("PreDrawViewModel", "DisplayDistancePlaneLS")
                incompatList["DisplayDistancePlane"] = {
                    title = "Light Sprayer / Scenic Dispenser tool",
                    wsid = "DisplayDistancePlane",
                    nourl = true,
                }
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
            if shouldDo and !table.IsEmpty(incompatList) then
                ArcCW.MakeIncompatibleWindow(incompatList)
            elseif !table.IsEmpty(incompatList) then
                print("ArcCW ignored " .. table.Count(incompatList) .. " incompatible addons. If things break, it's your fault.")
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

    if !self:GetOwner():IsNPC() then
        self:SetHoldType(self.HoldtypeActive)
    end

    local og = weapons.Get(self:GetClass())

    self.RegularClipSize = og.Primary.ClipSize

    self.OldPrintName = self.PrintName

    self:InitTimers()

    if engine.ActiveGamemode() == "terrortown" then
        self:TTT_Init()
    end

    hook.Run("ArcCW_WeaponInit", self)

    self:AdjustAtts()
end

function SWEP:Holster(wep)
    if !IsFirstTimePredicted() then return end
    if self:GetOwner():IsNPC() then return end

    if CLIENT and self:GetOwner() == LocalPlayer() and ArcCW.InvHUD then ArcCW.InvHUD:Remove() end

    if self:GetBurstCount() > 0 and self:Clip1() > self:GetBuff("AmmoPerShot") then return false end

    if CLIENT and LocalPlayer() != self:GetOwner() then
        return
    end

    if self:GetGrenadePrimed() then
        self:GrenadeDrop(true)
    end

    self:WepSwitchCleanup()
    if game.SinglePlayer() then self:CallOnClient("WepSwitchCleanup") end

    if wep == self then self:Deploy() return false end
    if self:GetHolster_Time() > CurTime() then return false end

    -- Props deploy to NULL, finish holster on NULL too
    if (self:GetHolster_Time() != 0 and self:GetHolster_Time() <= CurTime()) or !IsValid(wep) then
        self:SetHolster_Time(0)
        self:SetHolster_Entity(NULL)
        self:FinishHolster()
        self:GetBuff_Hook("Hook_OnHolsterEnd")
        return true
    else
        self:SetHolster_Entity(wep)

        if self:GetGrenadePrimed() then
            self:Throw()
        end

        self.Sighted = false
        self.Sprinted = false
        self:SetShotgunReloading(0)
        self:SetMagUpCount(0)
        self:SetMagUpIn(0)

        local time = 0.25
        local anim = self:SelectAnimation("holster")
        if anim then
            local prd = self.Animations[anim].ProcHolster
            time = self:GetAnimKeyTime(anim)
            if prd then
                self:ProceduralHolster()
                time = 0.25
            end
            self:PlayAnimation(anim, self:GetBuff_Mult("Mult_DrawTime"), true, nil, nil, nil, true)
            self:SetHolster_Time(CurTime() + time * self:GetBuff_Mult("Mult_DrawTime"))
        else
            self:ProceduralHolster()
            self:SetHolster_Time(CurTime() + time * self:GetBuff_Mult("Mult_DrawTime"))
        end
        self:SetPriorityAnim(CurTime() + time * self:GetBuff_Mult("Mult_DrawTime"))
        self:SetWeaponOpDelay(CurTime() + time * self:GetBuff_Mult("Mult_DrawTime"))

        self:GetBuff_Hook("Hook_OnHolster")
    end
end

function SWEP:FinishHolster()
    self:KillTimers()

    if CLIENT then
        self:KillFlashlights()
    else
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
            vm:SetPlaybackRate(1)
        end

        if self.Disposable and self:Clip1() == 0 and self:Ammo1() == 0 then
            self:GetOwner():StripWeapon(self:GetClass())
        end
    end
end

-- doesn't work if they dont call in prediction blah blah

function SWEP:ProceduralDraw()
    if SERVER and self:GetOwner():IsValid() then
        self:CallOnClient("ProceduralDraw")
    end

    self.InProcDraw = true
    self.ProcDrawTime = CurTime()
end

function SWEP:ProceduralHolster()
    if SERVER and self:GetOwner():IsValid() then
        self:CallOnClient("ProceduralHolster")
    end

    self.InProcHolster = true
    self.ProcHolsterTime = CurTime()
end

function SWEP:WepSwitchCleanup()
    table.Empty(self.EventTable)
    self.InProcDraw = false
    self.InProcHolster = false
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