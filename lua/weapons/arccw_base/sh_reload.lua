

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
    if IsValid(self:GetHolster_Entity()) then return end
    if self:GetHolster_Time() > 0 then return end

    if self:GetOwner():IsNPC() then
        return
    end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then
        return
    end

    -- Switch to UBGL
    if self:GetBuff_Override("UBGL") and self:GetOwner():KeyDown(IN_USE) then
        if self:GetInUBGL() then
            --net.Start("arccw_ubgl")
            --net.WriteBool(false)
            --net.SendToServer()

            self:DeselectUBGL()
        else
            --net.Start("arccw_ubgl")
            --net.WriteBool(true)
            --net.SendToServer()

            self:SelectUBGL()
        end

        return
    end

    if self:GetInUBGL() then
        if self:GetNextSecondaryFire() > CurTime() then return end
            self:ReloadUBGL()
        return
    end

    if self:GetNextPrimaryFire() >= CurTime() then return end
    -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end


    if self.Throwing then return end
    if self.PrimaryBash then return end

    -- with the lite 3D HUD, you may want to check your ammo without reloading
    local Lite3DHUD = self:GetOwner():GetInfo("arccw_hud_3dfun") == "1"
    if self:GetOwner():KeyDown(IN_WALK) and Lite3DHUD then
        return
    end

    if self:GetMalfunctionJam() then
        local r = self:MalfunctionClear()
        if r then return end
    end

    if !self:GetMalfunctionJam() and self:Ammo1() <= 0 and !self:HasInfiniteAmmo() then return end

    if self:HasBottomlessClip() then return end

    if self:GetBuff_Hook("Hook_PreReload") then return end

    -- if we must dump our clip when reloading, our reserve ammo should be more than our clip
    local dumpclip = self:GetBuff_Hook("Hook_ReloadDumpClip")
    if dumpclip and !self:HasInfiniteAmmo() and self:Clip1() >= self:Ammo1() then
        return
    end

    self.LastClip1 = self:Clip1()

    local reserve = self:Ammo1()

    reserve = reserve + self:Clip1()
    if self:HasInfiniteAmmo() then reserve = self:GetCapacity() + self:Clip1() end

    local clip = self:GetCapacity()

    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    if self:GetNeedCycle() then chamber = 0 end

    local load = math.Clamp(clip + chamber, 0, reserve)

    if !self:GetMalfunctionJam() and load <= self:Clip1() then return end

    self:SetBurstCount(0)

    local shouldshotgunreload = self:GetBuff_Override("Override_ShotgunReload")
    local shouldhybridreload = self:GetBuff_Override("Override_HybridReload")

    if shouldshotgunreload == nil then shouldshotgunreload = self.ShotgunReload end
    if shouldhybridreload == nil then shouldhybridreload = self.HybridReload end

    if shouldhybridreload then
        shouldshotgunreload = self:Clip1() != 0
    end

    if shouldshotgunreload and self:GetShotgunReloading() > 0 then return end

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    if shouldshotgunreload then
        local anim = "sgreload_start"
        local insertcount = 0

        local empty = self:Clip1() == 0 --or self:GetNeedCycle()

        if self.Animations.sgreload_start_empty and empty then
            anim = "sgreload_start_empty"
            empty = false
            if (self.Animations.sgreload_start_empty or {}).ForceEmpty == true then
                empty = true
            end

            insertcount = (self.Animations.sgreload_start_empty or {}).RestoreAmmo or 1
        else
            insertcount = (self.Animations.sgreload_start or {}).RestoreAmmo or 0
        end

        anim = self:GetBuff_Hook("Hook_SelectReloadAnimation", anim) or anim

        local time = self:GetAnimKeyTime(anim)
        local time2 = self:GetAnimKeyTime(anim, true)

        if time2 >= time then
            time2 = 0
        end

        if insertcount > 0 then
            self:SetMagUpCount(insertcount)
            self:SetMagUpIn(CurTime() + time2 * mult)
        end
        self:PlayAnimation(anim, mult, true, 0, true, nil, true)

        self:SetReloading(CurTime() + time * mult)

        self:SetShotgunReloading(empty and 4 or 2)
    else
        local anim = self:SelectReloadAnimation()

        if !self.Animations[anim] then print("Invalid animation \"" .. anim .. "\"") return end

        self:PlayAnimation(anim, mult, true, 0, false, nil, true)

        local reloadtime = self:GetAnimKeyTime(anim, true) * mult
        local reloadtime2 = self:GetAnimKeyTime(anim, false) * mult

        self:SetNextPrimaryFire(CurTime() + reloadtime2)
        self:SetReloading(CurTime() + reloadtime2)

        self:SetMagUpCount(0)
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

function SWEP:ReloadTimed()
    -- yeah my function names are COOL and QUIRKY and you can't say a DAMN thing about it.
    self:RestoreAmmo(self:GetMagUpCount() != 0 and self:GetMagUpCount())
    self:SetMagUpCount(0)
    self:SetLastLoad(self:Clip1())
    self:SetNthReload(self:GetNthReload() + 1)
end

function SWEP:Unload()
    if !self:GetOwner():IsPlayer() then return end
    if SERVER and self:Clip1() != ArcCW.BottomlessMagicNumber then
        self:GetOwner():GiveAmmo(self:Clip1(), self.Primary.Ammo or "", true)
    end
    self:SetClip1(0)
end

function SWEP:HasBottomlessClip()
    if GetConVar("arccw_mult_bottomlessclip"):GetBool() then return true end
    if self.BottomlessClip or self:GetBuff_Override("Override_BottomlessClip") then return true end
    return false
end

function SWEP:HasInfiniteAmmo()
    if GetConVar("arccw_mult_infiniteammo"):GetBool() then return true end
    if self:GetBuff_Override("Override_InfiniteAmmo", self.InfiniteAmmo) then return true end
    return false
end

function SWEP:RestoreAmmo(count)
    if self:GetOwner():IsNPC() then return end

    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    if self:GetNeedCycle() then chamber = 0 end

    local clip = self:GetCapacity()

    count = count or (clip + chamber)

    local reserve = (self:HasInfiniteAmmo() and math.huge or self:Ammo1())

    local dumpclip = self:GetBuff_Hook("Hook_ReloadDumpClip")
    if !dumpclip then
        reserve = reserve + self:Clip1()
    end

    local load = math.Clamp(self:Clip1() + count, 0, reserve)
    load = math.Clamp(load, 0, clip + chamber)
    reserve = reserve - load

    if !self:HasInfiniteAmmo() then
        self:GetOwner():SetAmmo(reserve, self.Primary.Ammo, true)
    end
    self:SetClip1(load)
end

-- local lastframeclip1 = 0

SWEP.LastClipOutTime = 0

function SWEP:GetVisualBullets()
    local h = self:GetBuff_Hook("Hook_GetVisualBullets")
    if h then return h end

    local _clip = self:Clip1()
    local _ammo = self:Ammo1()

    if self:HasInfiniteAmmo() then
        _ammo = math.huge
    end
    if self:HasBottomlessClip() then
        _clip = _ammo
    end

    if self.LastClipOutTime > CurTime() then
        return self.LastClip1_B or _clip
    else
        self.LastClip1_B = _clip

        if self:GetReloading() and !(self.ShotgunReload or (self.HybridReload and _clip == 0)) then
            return math.Clamp(_clip + _ammo, 0, self:GetCapacity() + self:GetChamberSize())
        else
            return _clip
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
    if self:HasInfiniteAmmo() then
        reserve = math.huge
    end
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

    if !empty and !self:GetNeedCycle() then
        total = total + (self:GetBuff("ChamberLoadNonEmpty", true) or self:GetChamberSize())
    else
        total = total + (self:GetBuff("ChamberLoadEmpty", true) or 0)
    end

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    if self:Clip1() >= total or (self:Ammo1() == 0 and !self:HasInfiniteAmmo()) or ((self:GetShotgunReloading() == 3 or self:GetShotgunReloading() == 5) and self:Clip1() > 0) then
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

        self:SetShotgunReloading(0)
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

        local time = self:GetAnimKeyTime(insertanim, false)
        local time2 = self:GetAnimKeyTime(insertanim, true)

        if time2 >= time then
            time2 = 0
        end

        self:SetMagUpCount(insertcount)
        self:SetMagUpIn(CurTime() + time2 * mult)

        self:SetReloading(CurTime() + time * mult)

        self:PlayAnimation(insertanim, mult, true, 0, true, nil, true)
        self:SetShotgunReloading(empty and 4 or 2)
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

    clip = math.Clamp(math.Round(clip), 0, math.huge)

    self.Primary.ClipSize = clip

    return clip
end

function SWEP:GetChamberSize()
    return self:GetBuff("ChamberSize") --(self:GetBuff_Override("Override_ChamberSize") or self.ChamberSize) + self:GetBuff_Add("Add_ChamberSize")
end