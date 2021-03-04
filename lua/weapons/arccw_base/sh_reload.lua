

function SWEP:GetReloadTime()
    -- Only works with classic mag-fed weapons.
    local mult = self:GetBuff_Mult("Mult_ReloadTime")
    local anim = self:SelectReloadAnimation()

    if !self.Animations[anim] then return false end

    local full = self:GetAnimKeyTime(anim) * mult
    local magin = self:GetAnimKeyTime(anim, true) * mult

    return { full, magin }
end

function SWEP:SetClipInfo(load)
    load = self:GetBuff_Hook("Hook_SetClipInfo", load) or load
    self.LastLoadClip1 = load - self:Clip1()
    self.LastClip1 = load
end

function SWEP:Reload()
    if self:GetOwner():IsNPC() then
        return
    end

    if self:GetInUBGL() then
        if self:GetNextSecondaryFire() > CurTime() then return end
            self:ReloadUBGL()
        return
    end

    if self:GetNextPrimaryFire() >= CurTime() then return end
    --if self:GetNextSecondaryFire() > CurTime() then return end
        -- don't succumb to
                -- californication

    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    if self.Throwing then return end
    if self.PrimaryBash then return end

    if self:HasBottomlessClip() then return end

    -- with the lite 3D HUD, you may want to check your ammo without reloading
    local Lite3DHUD = self:GetOwner():GetInfo("arccw_hud_3dfun") == "1"
    if self:GetOwner():KeyDown(IN_WALK) and Lite3DHUD then
        return
    end

    -- Don't accidently reload when changing firemode
    if self:GetOwner():GetInfoNum("arccw_altfcgkey", 0) == 1 and self:GetOwner():KeyDown(IN_USE) then return end

    if self:Ammo1() <= 0 then return end

    self:GetBuff_Hook("Hook_PreReload")

    self.LastClip1 = self:Clip1()

    local reserve = self:Ammo1()

    reserve = reserve + self:Clip1()

    local clip = self:GetCapacity()

    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())

    local load = math.Clamp(clip + chamber, 0, reserve)

    if load <= self:Clip1() then return end

    self:SetReqEnd(false)
    self:SetBurstCount(0)

    local shouldshotgunreload = self:GetBuff_Override("Override_ShotgunReload")
    local shouldhybridreload = self:GetBuff_Override("Override_HybridReload")

    if shouldshotgunreload == nil then shouldshotgunreload = self.ShotgunReload end
    if shouldhybridreload == nil then shouldhybridreload = self.HybridReload end

    if shouldhybridreload then
        shouldshotgunreload = self:Clip1() != 0
    end

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    if shouldshotgunreload then
        local anim = "sgreload_start"
        local insertcount = 0

        local empty = (self:Clip1() == 0) or self:GetNeedCycle()

        if self.Animations.sgreload_start_empty and empty then
            anim = "sgreload_start_empty"
            empty = false

            insertcount = (self.Animations.sgreload_start_empty or {}).RestoreAmmo or 1
        else
            insertcount = (self.Animations.sgreload_start or {}).RestoreAmmo or 0
        end

        anim = self:GetBuff_Hook("Hook_SelectReloadAnimation", anim) or anim

        self:GetOwner():SetAmmo(self:Ammo1() - insertcount, self.Primary.Ammo)
        self:SetClip1(self:Clip1() + insertcount)

        self:PlayAnimation(anim, mult, true, 0, true, nil, true)
        self:SetReloading(CurTime() + (self:GetAnimKeyTime(anim) * mult))

        self:SetTimer(self:GetAnimKeyTime(anim) * mult,
        function()
            self:ReloadInsert(empty)
        end)
    else
        local anim = self:SelectReloadAnimation()

        -- Yes, this will cause an issue in mag-fed manual action weapons where
        -- despite an empty casing being in the chamber, you can load +1 and 
        -- cycle an empty shell afterwards.
        -- No, I am not in the correct mental state to fix this. - 8Z
        if self:Clip1() == 0 then
            self:SetNeedCycle(false)
        end

        if !self.Animations[anim] then print("Invalid animation \"" .. anim .. "\"") return end

        self:PlayAnimation(anim, mult, true, 0, false, nil, true)

        local reloadtime = self:GetAnimKeyTime(anim, true) * mult
        local reloadtime2 = self:GetAnimKeyTime(anim, false) * mult

        if !self.Animations[anim].MinProgress then
            -- needs to be here to fix empty idle related issues
            reloadtime = reloadtime * 0.9
        end

        self:SetNextPrimaryFire(CurTime() + reloadtime2)
        self:SetReloading(CurTime() + reloadtime2)

        self:SetMagUpIn(CurTime() + reloadtime)
    end

    self:SetClipInfo(load)
    if game.SinglePlayer() then
        self:CallOnClient("SetClipInfo", tostring(load))
    end

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.DamageOnReload then
            self:DamageAttachment(i, atttbl.DamageOnReload)
        end
    end

    if !self.ReloadInSights then
        self:ExitSights()
        self.Sighted = false
    end

    self:GetBuff_Hook("Hook_PostReload")
end

function SWEP:WhenTheMagUpIn()
    -- yeah my function names are COOL and QUIRKY and you can't say a DAMN thing about it.
    self:RestoreAmmo()
    self:SetLastLoad(self:Clip1())
    self:SetNthReload(self:GetNthReload() + 1)
end

function SWEP:Unload()
    if !self:GetOwner():IsPlayer() then return end
    if SERVER then
        self:GetOwner():GiveAmmo(self:Clip1(), self.Primary.Ammo or "", true)
    end
    self:SetClip1(0)
end

function SWEP:HasBottomlessClip()
    if self.BottomlessClip or self:GetBuff_Override("Override_BottomlessClip") then return true end
    return false
end

function SWEP:HasInfiniteAmmo()
    if self.InfiniteAmmo or self:GetBuff_Override("Override_InfiniteAmmo") then return true end
    return false
end

function SWEP:RestoreAmmo(count)
    if self:GetOwner():IsNPC() then return end
    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    local clip = self:GetCapacity()

    if self:HasInfiniteAmmo() then
        self:SetClip1(clip + chamber)
        return
    end

    count = count or (clip + chamber)

    local reserve = self:Ammo1()

    reserve = reserve + self:Clip1()

    local load = math.Clamp(self:Clip1() + count, 0, reserve)

    load = math.Clamp(load, 0, clip + chamber)

    reserve = reserve - load

    -- if load <= self:Clip1() then return end

    --if SERVER then
        self:GetOwner():SetAmmo(reserve, self.Primary.Ammo, true)
    --end
    self:SetClip1(load)
end

-- local lastframeclip1 = 0

SWEP.LastClipOutTime = 0

function SWEP:GetVisualBullets()
    local reserve = self:Ammo1()
    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    local abouttoload = math.Clamp(self:GetCapacity() + chamber, 0, reserve + self:Clip1())
    local h = self:GetBuff_Hook("Hook_GetVisualBullets")

    if h then return h end
    if self.LastClipOutTime > CurTime() then
        return self.LastClip1_B or self:Clip1()
    else
        self.LastClip1_B = self:Clip1()

        if self:GetReloading() and !(self.ShotgunReload or (self.HybridReload and self:Clip1() == 0)) then
            return abouttoload
        else
            return self:Clip1()
        end
    end
end

function SWEP:GetVisualClip()
    -- local reserve = self:Ammo1()
    -- local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    -- local abouttoload = math.Clamp(self:GetCapacity() + chamber, 0, reserve + self:Clip1())

    -- local h = self:GetBuff_Hook("Hook_GetVisualClip")

    -- if h then return h end
    -- if self.LastClipOutTime > CurTime() then
    --     return self.LastClip1 or self:Clip1()
    -- else
    --     if !self.RevolverReload then
    --         self.LastClip1 = self:Clip1()
    --     else
    --         if self:Clip1() > lastframeclip1 then
    --             self.LastClip1 = self:Clip1()
    --         end

    --         lastframeclip1 = self:Clip1()
    --     end

    --     if self:GetReloading() and !(self.ShotgunReload or (self.HybridReload and self:Clip1() == 0)) then
    --         return abouttoload
    --     else
    --         return self.LastClip1 or self:Clip1()
    --     end
    -- end

    local reserve = self:Ammo1()
    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    local abouttoload = math.Clamp(self:GetCapacity() + chamber, 0, reserve + self:Clip1())

    local h = self:GetBuff_Hook("Hook_GetVisualClip")

    if h then return h end

    if self.LastClipOutTime > CurTime() then
        return self:GetLastLoad() or self:Clip1()
    end

    if self.RevolverReload then
        if self:GetReloading() and !(self.ShotgunReload or (self.HybridReload and self:Clip1() == 0)) then
            return abouttoload
        else
            return self:GetLastLoad() or self:Clip1()
        end
    else
        return self:Clip1()
    end
end

function SWEP:GetVisualLoadAmount()
    return self.LastLoadClip1 or self:Clip1()
end

function SWEP:SelectReloadAnimation()
    local ret

    if self.Animations.reload_empty and self:Clip1() == 0 then
        ret = "reload_empty"
    else
        ret = "reload"
    end

    ret = self:GetBuff_Hook("Hook_SelectReloadAnimation", ret) or ret

    return ret
end

function SWEP:ReloadInsert(empty)
    local total = self:GetCapacity()

    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    if !empty then
        total = total + (self:GetChamberSize())
    end

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    if self:Clip1() >= total or self:Ammo1() == 0 or self:GetReqEnd() then
        local ret = "sgreload_finish"

        if empty then
            if self.Animations.sgreload_finish_empty then
                ret = "sgreload_finish_empty"
            end
            if self:GetNeedCycle() then
                self:SetNeedCycle(false)
            end
        end

        ret = self:GetBuff_Hook("Hook_SelectReloadAnimation", ret) or ret

        self:PlayAnimation(ret, mult, true, 0, true, nil, true)
            self:SetReloading(CurTime() + (self:GetAnimKeyTime(ret, true) * mult))
            self:SetTimer(self:GetAnimKeyTime(ret, true) * mult,
            function()
                self:SetNthReload(self:GetNthReload() + 1)
                if self:GetOwner():KeyDown(IN_ATTACK2) then
                    self:EnterSights()
                end
            end)

        self:SetReqEnd(false)
    else
        local insertcount = self:GetBuff_Override("Override_InsertAmount") or 1
        local insertanim = "sgreload_insert"

        local ret = self:GetBuff_Hook("Hook_SelectInsertAnimation", {count = insertcount, anim = insertanim, empty = empty})

        if ret then
            insertcount = ret.count
            insertanim = ret.anim
        end

        local load = self:GetCapacity() + math.min(self:Clip1(), self:GetChamberSize())
        if load - self:Clip1() > self:Ammo1() then load = self:Clip1() + self:Ammo1() end
        self:SetClipInfo(load)
        if game.SinglePlayer() then
            self:CallOnClient("SetClipInfo", tostring(load))
        end

        self:RestoreAmmo(insertcount)

        local time = self:GetAnimKeyTime(insertanim, true)

        self:SetReloading(CurTime() + time * mult)

        self:PlayAnimation(insertanim, mult, true, 0, true, nil, true)
        self:SetTimer(time * mult,
        function()
            self:ReloadInsert(empty)
        end)
    end
end

function SWEP:GetCapacity()
    local clip = self.RegularClipSize or self.Primary.ClipSize

    if !self.RegularClipSize then
        self.RegularClipSize = self.Primary.ClipSize
    end

    local level = 1

    if self:GetBuff_Override("MagExtender") then
        level = level + 1
    end

    if self:GetBuff_Override("MagReducer") then
        level = level - 1
    end

    if level == 0 then
        clip = self.ReducedClipSize
    elseif level == 2 then
        clip = self.ExtendedClipSize
    end

    clip = self:GetBuff("ClipSize", true, clip) or clip

    local ret = self:GetBuff_Hook("Hook_GetCapacity", clip)

    clip = ret or clip

    clip = math.Clamp(clip, 0, math.huge)

    self.Primary.ClipSize = clip

    return clip
end

function SWEP:GetChamberSize()
    return self:GetBuff("ChamberSize") --(self:GetBuff_Override("Override_ChamberSize") or self.ChamberSize) + self:GetBuff_Add("Add_ChamberSize")
end