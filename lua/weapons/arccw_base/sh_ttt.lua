function SWEP:OnRestore()
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    return 2.5
end

function SWEP:IsEquipment()
    return WEPS.IsEquipment(self)
end

SWEP.IsSilent = false
SWEP.AutoSpawnable = true

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
    for i, k in pairs(self.Attachments) do
        k.RandomChance = 100
    end
    if GetConVar("arccw_ttt_atts"):GetBool() then
        self:NPC_SetupAttachments()
    end
end

function SWEP:TTT_PostAttachments()
    self.IsSilent = self:GetBuff_Override("Suppressor")

    if !self.IsSilent then
        if self.ShootVol * self:GetBuff_Mult("Mult_ShootVol") <= 90 then
            self.IsSilent = true
        end
    end
end

function SWEP:TTT_Init()
    if engine.ActiveGamemode() != "terrortown" then return end

    if SERVER then
        self.fingerprints = {}
    else
        local class = self:GetClass()
        local path = "arccw/weaponicons/" .. class
        local path2 = "arccw/ttticons/" .. class
        local mat2 = Material(path2)

        if !mat2:IsError() then
            self.Icon = path2
        elseif !Material(path):IsError() then
            self.Icon = path
        end
    end

    if self.Throwing then
        self.Primary.ClipMax = 0
    end

    if self.ForgetDefaultBehavior then return end

    --[[]
    if self.Kind != WEAPON_EQUIP1 and self.Kind != WEAPON_EQUIP2 then
        if !self.CanBuy then
            if self.Slot == 0 then
                -- melee weapons
                self.Slot = 6
                self.Kind = WEAPON_EQUIP1
            elseif self.Slot == 1 then
                -- sidearms
                self.Kind = WEAPON_PISTOL
            elseif self.Slot == 2 then
                -- primaries
                self.Kind = WEAPON_HEAVY
            else
                -- idk
                self.Slot = 2
                self.Kind = WEAPON_HEAVY
            end

            if self.Throwing then
                self.Slot = 3
                self.Kind = WEAPON_NADE
            end
        end
    end
    ]]
    if ArcCW.Ammo_To_TTTAmmo[self.Primary.Ammo] then
        self.Primary.Ammo = ArcCW.Ammo_To_TTTAmmo[self.Primary.Ammo]
    end
    --self.AmmoEnt = ArcCW.TTTAmmo_To_Ent[self.Primary.Ammo] or ""

    self.Primary.ClipMax = ArcCW.TTTAmmo_To_ClipMax[self.Primary.Ammo] or self.RegularClipSize or self.Primary.ClipSize

    self:SetClip1(self:GetCapacity())
    self.Primary.DefaultClip = self:GetCapacity()

    if self.Throwing then
        self.Primary.Ammo = "none"
        self.Primary.DefaultClip = 0
        self:SetClip1(-1)
        self.Singleton = true
    end
end