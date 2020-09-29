function SWEP:Reload()
    if self:GetOwner():IsNPC() then
        return
    end

    if self:GetNWBool("ubgl") then
        if self:GetNextSecondaryFire() > CurTime() then return end
            self:ReloadUBGL()
        return
    end

    if self:GetNextPrimaryFire() >= CurTime() then return end
    --if self:GetNextSecondaryFire() > CurTime() then return end
        -- don't succumb to
                -- californication

    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    if self.Throwing then return end
    if self.PrimaryBash then return end

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
    self.LastLoadClip1 = load - self:Clip1()

    self:SetNWBool("reqend", false)
    self:SetBurstCount(0)

    local shouldshotgunreload = self.ShotgunReload

    if self:GetBuff_Override("Override_ShotgunReload") then
        shouldshotgunreload = true
    end

    if self:GetBuff_Override("Override_ShotgunReload") == false then
        shouldshotgunreload = false
    end

    if self.HybridReload or self:GetBuff_Override("Override_HybridReload") then
        if self:Clip1() == 0 then
            shouldshotgunreload = false
        else
            shouldshotgunreload = true
        end
    end

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    if shouldshotgunreload then
        local anim = "sgreload_start"
        local insertcount = 0

        local empty = (self:Clip1() == 0) or self:GetNWBool("cycle", false)

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

        self:PlayAnimation(anim, mult, true, 0, true)

        self:SetTimer(self:GetAnimKeyTime(anim) * mult,
        function()
            self:ReloadInsert(empty)
        end)
    else
        local anim = self:SelectReloadAnimation()

        -- Yes, this will cause an issue in mag-fed manual action weapons where
        -- despite an empty casing being in the chamber, you can load +1 and 
        -- cycle an empty shell afterwards.
        -- No, I am !in the correct mental state to fix this. - 8Z
        if self:Clip1() == 0 then
            self:SetNWBool("cycle", false)
        end

        if !self.Animations[anim] then print("Invalid animation \"" .. anim .. "\"") return end

        self:PlayAnimation(anim, mult, true, 0, true)
        self:SetTimer(self:GetAnimKeyTime(anim) * mult * 0.95,
        function()
            self:SetNWBool("reloading", false)
            -- if self:GetOwner():KeyDown(IN_ATTACK2) then
            --     self:EnterSights()
            -- end
            self:RestoreAmmo()
        end)
        self.CheckpointAnimation = anim
        self.CheckpointTime = 0

        if self.RevolverReload then
            self.LastClip1 = load
        end
    end

    self:SetNWBool("reloading", true)

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

function SWEP:Unload()
    if !self:GetOwner():IsPlayer() then return end
    if SERVER then
        self:GetOwner():GiveAmmo(self:Clip1(), self.Primary.Ammo, true)
    end
    self:SetClip1(0)
end

function SWEP:RestoreAmmo(count)
    if self:GetOwner():IsNPC() then return end
    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    local clip = self:GetCapacity()

    count = count or (clip + chamber)

    local reserve = self:Ammo1()

    reserve = reserve + self:Clip1()

    local load = math.Clamp(self:Clip1() + count, 0, reserve)

    load = math.Clamp(load, 0, clip + chamber)

    reserve = reserve - load

    -- if load <= self:Clip1() then return end

    if SERVER then
        self:GetOwner():SetAmmo(reserve, self.Primary.Ammo, true)
    end
    self:SetClip1(load)
end

local lastframeclip1 = 0
local lastframeloadclip1 = 0

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

        if self:GetNWBool("reloading") and !(self.ShotgunReload or (self.HybridReload and self:Clip1() == 0)) then
            return abouttoload
        else
            return self:Clip1()
        end
    end
end

function SWEP:GetVisualClip()
    local reserve = self:Ammo1()
    local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
    local abouttoload = math.Clamp(self:GetCapacity() + chamber, 0, reserve + self:Clip1())

    local h = self:GetBuff_Hook("Hook_GetVisualClip")

    if h then return h end
    if self.LastClipOutTime > CurTime() then
        return self.LastClip1 or self:Clip1()
    else
        if !self.RevolverReload then
            self.LastClip1 = self:Clip1()
        else
            if self:Clip1() > lastframeclip1 then
                self.LastClip1 = self:Clip1()
            end

            lastframeclip1 = self:Clip1()
        end

        if self:GetNWBool("reloading") and !(self.ShotgunReload or (self.HybridReload and self:Clip1() == 0)) then
            return abouttoload
        else
            return self:Clip1()
        end
    end
end

function SWEP:GetVisualLoadAmount()
    if self:Clip1() > lastframeloadclip1 then
        local clip = self:GetCapacity()
        local chamber = math.Clamp(self:Clip1(), 0, self:GetChamberSize())
        self.LastLoadClip1 = math.Clamp(clip + chamber, 0, self:Ammo1() + self:Clip1()) - lastframeloadclip1
        if self:GetNWBool("cycle", false) == false and lastframeloadclip1 != 0 then
            self.LastLoadClip1 = self.LastLoadClip1 + 1
        end
    end
    lastframeloadclip1 = self:Clip1()

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

    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    if !empty then
        total = total + (self:GetChamberSize())
    end

    self:SetNWBool("reloading", true)

    local mult = self:GetBuff_Mult("Mult_ReloadTime")

    self:SetNWBool("reloading", false)

    if self:Clip1() >= total or self:Ammo1() == 0 or self:GetNWBool("reqend", false) then
        local ret = "sgreload_finish"

        if empty then
            ret = "sgreload_finish_empty"
            if self:GetNWBool("cycle") then
                self:SetNWBool("cycle", false)
            end
        end

        ret = self:GetBuff_Hook("Hook_SelectReloadAnimation", ret) or ret

        self:PlayAnimation(ret, mult, true, 0, true, nil, true)
            self:SetTimer(self:GetAnimKeyTime(ret) * mult,
            function()
                self:SetNWBool("reloading", false)
                if self:GetOwner():KeyDown(IN_ATTACK2) then
                    self:EnterSights()
                end
            end)

        self:SetNWBool("reqend", false)
    else
        local insertcount = self:GetBuff_Override("Override_InsertAmount") or 1
        local insertanim = "sgreload_insert"

        local ret = self:GetBuff_Hook("Hook_SelectInsertAnimation", {count = insertcount, anim = insertanim, empty = empty})

        if ret then
            insertcount = ret.count
            insertanim = ret.anim
        end

        self:RestoreAmmo(insertcount)

        self:PlayAnimation(insertanim, mult, true, 0, true, nil, true)
        self:SetTimer(self:GetAnimKeyTime(insertanim) * mult,
        function()
            self:ReloadInsert(empty)
        end)
    end

    self:SetNWBool("reloading", true)
end

function SWEP:GetCapacity()
    local clip = self.RegularClipSize or self.Primary.ClipSize
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

    clip = self:GetBuff_Override("Override_ClipSize") or clip

    clip = clip + self:GetBuff_Add("Add_ClipSize")

    local ret = self:GetBuff_Hook("Hook_GetCapacity", clip)

    clip = ret or clip

    clip = math.Clamp(clip, 0, math.huge)

    self.Primary.ClipSize = clip

    return clip
end

function SWEP:GetChamberSize()
    return (self:GetBuff_Override("Override_ChamberSize") or self.ChamberSize) + self:GetBuff_Add("Add_ChamberSize")
end