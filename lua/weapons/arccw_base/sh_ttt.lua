function SWEP:OnRestore()
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    return 2.5
end

function SWEP:IsEquipment()
    return WEPS.IsEquipment(self)
end

SWEP.IsSilent = false
SWEP.AutoSpawnable = nil -- If not set, automatically set to true in InitPostEntity 

-- The OnDrop() hook is useless for this as it happens AFTER the drop. OwnerChange
-- does not occur when a drop happens for some reason. Hence this thing.
function SWEP:PreDrop()
    if self.Throwing then
        if self:GetNWBool("grenadeprimed") then
            self:Throw()
        end
    else
        if SERVER and IsValid(self:GetOwner()) and self.Primary.Ammo != "none" then
            local ammo = self:Ammo1()

            -- Do not drop ammo if we have another gun that uses this type
            for _, w in ipairs(self:GetOwner():GetWeapons()) do
                if IsValid(w) and w != self and w:GetPrimaryAmmoType() == self:GetPrimaryAmmoType() then
                ammo = 0
                end
            end

            self.StoredAmmo = ammo

            if ammo > 0 then
                self:GetOwner():RemoveAmmo(ammo, self.Primary.Ammo)
            end
        end
    end

    net.Start("arccw_togglecustomize")
        net.WriteBool(false)
    net.Send(self:GetOwner())
    self:ToggleCustomizeHUD(false)
end

function SWEP:DampenDrop()
    -- For some reason gmod drops guns on death at a speed of 400 units, which
    -- catapults them away from the body. Here we want people to actually be able
    -- to find a given corpse's weapon, so we override the velocity here and call
    -- this when dropping guns on death.
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
        phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
    end
end

SWEP.StoredAmmo = 0

-- Picked up by player. Transfer of stored ammo and such.
function SWEP:Equip(newowner)
    if SERVER then
        if self:IsOnFire() then
            self:Extinguish()
        end

        self.fingerprints = self.fingerprints or {}

        if !table.HasValue(self.fingerprints, newowner) then
            table.insert(self.fingerprints, newowner)
        end
    end

    if SERVER and IsValid(newowner) and self.StoredAmmo > 0 and self.Primary.Ammo != "none" then
        local ammo = newowner:GetAmmoCount(self.Primary.Ammo)
        local given = math.min(self.StoredAmmo, self.Primary.ClipMax - ammo)

        newowner:GiveAmmo( given, self.Primary.Ammo)
        self.StoredAmmo = 0
    end
end

function SWEP:WasBought(buyer)
    if self.TTT_DoNotAttachOnBuy then return end

    for i, k in pairs(self.Attachments) do
        k.RandomChance = 100
    end
    if GetConVar("arccw_ttt_atts"):GetBool() then
        self:NPC_SetupAttachments()
    end
end

function SWEP:TTT_PostAttachments()
    self.IsSilent = self:GetBuff_Override("Suppressor")

    if !self.IsSilent and self.ShootVol * self:GetBuff_Mult("Mult_ShootVol") <= 90 then
        self.IsSilent = true
    end
end

function SWEP:TTT_Init()
    if engine.ActiveGamemode() != "terrortown" then return end

    if SERVER then
        self.fingerprints = {}
    end

    if self.Throwing then
        self.Primary.ClipMax = 0
    end

    if self.ForgetDefaultBehavior then return end

    self.Primary.ClipMax = ArcCW.TTTAmmo_To_ClipMax[self.Primary.Ammo] or self.RegularClipSize * 2 or self.Primary.ClipSize * 2

    -- This will overwrite mag reducers, so give it a bit of time
    timer.Simple(0.1, function()
        if !IsValid(self) then return end
        self:SetClip1(self:GetCapacity() or self.RegularClipSize or self.Primary.ClipSize)
        self.Primary.DefaultClip = self:GetCapacity()
    end)

    if self.Throwing and self.Primary.Ammo and !self.ForceDefaultClip then
        self.Primary.Ammo = "none"
        self.Primary.DefaultClip = 0
        self:SetClip1(-1)
        self.Singleton = true
    end
end