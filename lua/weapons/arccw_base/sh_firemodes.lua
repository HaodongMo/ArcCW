function SWEP:ChangeFiremode(pred)
    pred = pred or true
    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes

    fmt["BaseClass"] = nil

    if table.Count(fmt) == 1 then return end

    local fmi = self:GetNWInt("firemode", 1)
    local lastfmi = fmi

    fmi = fmi + 1

    if fmi > table.Count(fmt) then
       fmi = 1
    end

    if !fmt[fmi] then fmi = 1 end

    self:SetNWInt("firemode", fmi)

    if SERVER then
        if pred then
            SuppressHostEvents(self:GetOwner())
        end
        self:EmitSound(self.FiremodeSound, 75, 100, 1, CHAN_ITEM + 2)
        if pred then
            SuppressHostEvents(NULL)
        end
    else
       self:EmitSound(self.FiremodeSound, 75, 100, 1, CHAN_ITEM + 2)
    end

    local a = tostring(lastfmi) .. "_to_" .. tostring(fmi)

    self:SetShouldHoldType()

    if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint(self:GetFiremodeName() .. "|" .. self:GetFiremodeBars())
        end
    end

    if self.Animations[a] then
        self:PlayAnimation(a)
    elseif self.Animations.changefiremode then
        self:PlayAnimation("changefiremode")
    end
end

function SWEP:GetCurrentFiremode()
    local fmt = self:GetBuff_Override("Override_Firemodes") or self.Firemodes

    if self:GetNWInt("firemode", 1) > table.Count(fmt) then
        self:SetNWInt("firemode", 1)
    end

    return fmt[self:GetNWInt("firemode", 1)]
end

function SWEP:GetFiremodeName()
    if self:GetNWBool("ubgl", false) then
        return self:GetBuff_Override("UBGL_PrintName") or "UBGL"
    end

    local fm = self:GetCurrentFiremode()

    if fm.PrintName then return fm.PrintName end

    local mode = fm.Mode

    if mode == 0 then return "SAFE" end
    if mode == 1 then return "SEMI" end
    if mode >= 2 then return "AUTO" end
    if mode < 0 then return tostring(-mode) .. "BST" end
end

function SWEP:GetFiremodeBars()
    if self:GetNWBool("ubgl", false) then
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