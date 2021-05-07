function SWEP:ChangeFiremode(pred)
    pred = pred or true
    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes

    fmt["BaseClass"] = nil

    if table.Count(fmt) == 1 then return end

    local fmi = self:GetFireMode()
    local lastfmi = fmi

    fmi = fmi + 1

    if fmi > table.Count(fmt) then
       fmi = 1
    end

    local altsafety = SERVER and (self:GetOwner():GetInfo("arccw_altsafety") == "1") or CLIENT and (GetConVar("arccw_altsafety"):GetBool())
    if altsafety and !self:GetOwner():KeyDown(IN_WALK) and fmt[fmi] and fmt[fmi].Mode == 0 then
        -- Skip safety when walk key is not down
        fmi = (fmi + 1 > table.Count(fmt)) and 1 or (fmi + 1)
    elseif altsafety and self:GetOwner():KeyDown(IN_WALK) then
        if fmt[lastfmi] and fmt[lastfmi].Mode == 0 then
            -- Find the first non-safety firemode
            local nonsafe_fmi = nil
            for i, fm in pairs(fmt) do
                if fm.Mode != 0 then nonsafe_fmi = i break end
            end
            fmi = nonsafe_fmi or fmi
        else
            -- Find the safety firemode
            local safety_fmi = nil
            for i, fm in pairs(fmt) do
                if fm.Mode == 0 then safety_fmi = i break end
            end
            fmi = safety_fmi or fmi
        end
    end

    if !fmt[fmi] then fmi = 1 end

    self:SetFireMode(fmi)
    --timer.Simple(0, function() self:RecalcAllBuffs() end)
    -- Absolutely, totally, completely ENSURE client has changed the value before attempting recalculation
    -- Waiting one tick will not work on dedicated servers
    local id = "ArcCW_RecalcWait_" .. self:EntIndex()
    timer.Create(id, 0.01, 0, function()
        if !IsValid(self) then timer.Remove(id) return end
        if self:GetFireMode() == fmi then
            self:RecalcAllBuffs()
            timer.Remove(id)
        end
    end)

    if lastfmi != fmi then
        if SERVER then
            if pred then
                SuppressHostEvents(self:GetOwner())
            end
            self:MyEmitSound(self.FiremodeSound, 75, 100, 1, CHAN_ITEM + 2)
            if pred then
                SuppressHostEvents(NULL)
            end
        else
           self:MyEmitSound(self.FiremodeSound, 75, 100, 1, CHAN_ITEM + 2)
        end
    end

    local a = tostring(lastfmi) .. "_to_" .. tostring(fmi)

    self:SetShouldHoldType()

    --[[if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint(self:GetFiremodeName() .. "|" .. self:GetFiremodeBars())
        end
    end]]

    if self.Animations[a] then
        self:PlayAnimation(a)
    elseif self.Animations.changefiremode then
        self:PlayAnimation("changefiremode")
    end
    if self:GetCurrentFiremode().Mode == 0 or self:GetBuff_Hook("Hook_ShouldNotSight") then
        self:ExitSights()
    end
end

function SWEP:GetCurrentFiremode()
    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes

    if self:GetFireMode() > table.Count(fmt) then
        self:SetFireMode(1)
    end

    return fmt[self:GetFireMode()]
end

function SWEP:GetFiremodeName()
    if self:GetBuff_Hook("Hook_FiremodeName") then return self:GetBuff_Hook("Hook_FiremodeName") end

    if self:GetInUBGL() then
        return self:GetBuff_Override("UBGL_PrintName") and self:GetBuff_Override("UBGL_PrintName") or ArcCW.GetTranslation("fcg.ubgl")
    end

    local fm = self:GetCurrentFiremode()

    if fm.PrintName then return fm.PrintName end

    local mode = fm.Mode

    if mode == 0 then return ArcCW.GetTranslation("fcg.safe") end
    if mode == 1 then return ArcCW.GetTranslation("fcg.semi") end
    if mode >= 2 then return ArcCW.GetTranslation("fcg.auto") end
    if mode < 0 then return string.format(ArcCW.GetTranslation("fcg.burst"), tostring(-mode)) end
end

function SWEP:GetFiremodeBars()
    if self:GetBuff_Hook("Hook_FiremodeBars") then return self:GetBuff_Hook("Hook_FiremodeBars") end

    if self:GetInUBGL() then
        return "____-"
    end

    local fm = self:GetCurrentFiremode()

    if fm.CustomBars then return fm.CustomBars end

    local mode = fm.Mode

    if mode == 0 then return "_____" end
    if mode == 1 then return "-____" end
    if mode >= 2 then return "-----" end
    if mode == -2 then return "--___" end
    if mode == -3 then return "---__" end
    if mode == -4 then return "----_" end

    return "-----"
end