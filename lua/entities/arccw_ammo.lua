AddCSLuaFile()

ENT.Type 					= "anim"
ENT.Base 					= "base_entity"
ENT.RenderGroup             = RENDERGROUP_TRANSLUCENT

ENT.PrintName 				= "Base Ammo"
ENT.Category 				= "ArcCW - Ammo"
ENT.ArcCW_Ammo = true

ENT.Spawnable 				= false
ENT.Model 					= "models/items/sniper_round_box.mdl"
ENT.MaxHealth = 40
ENT.Scale = 1

ENT.AmmoType = "SniperPenetratedRound"
ENT.AmmoCount = 5
ENT.DetonationDamage = 10 -- Per-round damage
ENT.DetonationRadius = 256
ENT.DetonationSound = "weapons/arccw/glock18/glock18-1.wav" -- string or table

ENT.ShellModel = "models/shells/shell_9mm.mdl"
ENT.ShellScale = 1.5

ENT.ResistanceMult = {
    [DMG_BURN] = 5,
    [DMG_BLAST] = 2,
    [DMG_BULLET] = 0.5,
    [DMG_BUCKSHOT] = 0.5,
    [DMG_CLUB] = 0.25,
    [DMG_SLASH] = 0.25,
    [DMG_CRUSH] = 0.25,
}

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetHealth(math.max(math.ceil(self.MaxHealth * GetConVar("arccw_mult_ammohealth"):GetFloat()), 1))
    self.AmmoCount = self.AmmoCount * GetConVar("arccw_mult_ammoamount"):GetFloat()
    self.MaxAmmoCount = self.AmmoCount

    if self.Scale ~= 1 then
        self:SetModelScale(self.Scale)
    end

    if self:SkinCount() > 1 and math.random() <= GetConVar("arccw_ammo_rareskin"):GetFloat() then
        self:SetSkin(math.random(1, self:SkinCount() - 1))
    end

    if SERVER then

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()

        self:SetTrigger(true) -- Enables Touch() to be called even when not colliding
        if GetConVar("arccw_ammo_largetrigger"):GetBool() then
            self:UseTriggerBounds(true, 24)
        end
    end
end

function ENT:ApplyAmmo(ply)
    if self.USED then return end
    self.USED = true -- Prevent multiple uses
    ply:GiveAmmo(self.AmmoCount, self.AmmoType)
    self:Remove()
end

function ENT:DetonateRound()
    local count = math.Clamp(math.random(1, self.MaxAmmoCount / 5), 1, self.AmmoCount)
    -- Default function
    self:FireBullets({
        Attacker = self.Burner,
        Damage = self.DetonationDamage,
        Force = self.DetonationDamage / 5,
        Num = count,
        AmmoType = self.AmmoType,
        Src = self:WorldSpaceCenter(),
        Dir = self:GetUp(),
        Spread = Vector(3, 3, 0),
        IgnoreEntity = self
    })
    self.AmmoCount = self.AmmoCount - count

    self:GetPhysicsObject():AddVelocity(VectorRand() * math.random(30, 50) * self:GetPhysicsObject():GetMass())
    self:GetPhysicsObject():AddAngleVelocity(VectorRand() * math.random(60, 300))

    if self.DetonationSound then
        self:EmitSound(istable(self.DetonationSound) and table.Random(self.DetonationSound) or self.DetonationSound)
    end
end

function ENT:Detonate(wet, attacker)
    if wet then
        self:FireBullets({
            Attacker = attacker,
            Damage = self.DetonationDamage,
            Force = self.DetonationDamage / 5,
            Num = math.max(self.AmmoCount, 50),
            AmmoType = self.AmmoType,
            Src = self:WorldSpaceCenter(),
            Dir = self:GetUp(),
            Spread = Vector(3, 3, 0),
            IgnoreEntity = self
        })
    end

    local e = EffectData()
    e:SetOrigin(self:GetPos())
    util.Effect("Explosion", e)

    util.BlastDamage(self, attacker, self:GetPos(), self.DetonationRadius, self.DetonationDamage * (wet and 0.5 or 1))
    self:Remove()
end

if SERVER then

    function ENT:Use(ply)
        if !ply:IsPlayer() then return end
        self:ApplyAmmo(ply)
    end


    function ENT:Touch(ply)
        if !ply:IsPlayer() or !GetConVar("arccw_ammo_autopickup"):GetBool() then return end
        self:ApplyAmmo(ply)
    end

    function ENT:Burn(attacker)
        self.Burning = true
        self.Burner = attacker
        self:Ignite(30)
        self:SetHealth(-1)
    end

    function ENT:OnTakeDamage(dmginfo)

        if self:Health() <= 0 or self.USED then return end

        self:TakePhysicsDamage(dmginfo)
        self:SetHealth(self:Health() - dmginfo:GetDamage())

        if self:Health() <= 0 then

            self.USED = true

            local cvar = GetConVar("arccw_ammo_detonationmode"):GetInt()

            if cvar == -1 or (!GetConVar("arccw_ammo_chaindet"):GetBool() and dmginfo:GetInflictor().ArcCW_Ammo) then
                -- Go quietly
                local e = EffectData()
                e:SetOrigin(self:GetPos())
                e:SetMagnitude(8)
                e:SetScale(2)
                util.Effect("Sparks", e)
                self:EmitSound("physics/cardboard/cardboard_box_break2.wav", 80, 120)
                self:Remove()
            elseif cvar == 2 and (math.random() <= 0.25 or dmginfo:IsDamageType(DMG_BURN)) then
                -- Fancy ammobox burning
                self:Burn(dmginfo:GetAttacker())
            else
                -- Plain old explosion
                self:Detonate(cvar >= 1, dmginfo:GetAttacker())
            end
        end

    end

    function ENT:Think()
        if self.Burning then

            if self.AmmoCount <= 0 then
                self:Detonate(false, IsValid(self.Burner) and self.Burner or self)
            else
                self:DetonateRound()
            end

            self:NextThink(CurTime() + math.random() * 0.3 + 0.2)
            return true
        end
    end

    -- Do it during the hook so that hit damage numbers show up properly (yes, I am _that_ pedantic)
    hook.Add("EntityTakeDamage", "ArcCW_Ammo", function(ent, dmginfo)
        if ent.ArcCW_Ammo then
            if GetConVar("arccw_mult_ammohealth"):GetFloat() < 0 then
                dmginfo:ScaleDamage(0)
            elseif ent.ResistanceMult then
                -- Only apply one multiplier, and prioritize larger ones
                for k, v in SortedPairsByValue(ent.ResistanceMult, true) do if dmginfo:IsDamageType(k) then dmginfo:ScaleDamage(v) break end end
            end
        end
    end)

elseif CLIENT then

    function ENT:Draw()
        self:DrawModel()

        if !GetConVar("arccw_2d3d"):GetBool() then return end

        if (EyePos() - self:GetPos()):LengthSqr() <= 262144 then -- 512^2
            local ang = LocalPlayer():EyeAngles()

            ang:RotateAroundAxis(ang:Forward(), 180)
            ang:RotateAroundAxis(ang:Right(), 90)
            ang:RotateAroundAxis(ang:Up(), 90)

            cam.Start3D2D(self:WorldSpaceCenter() + Vector(0, 0, (self:OBBMaxs().z - self:OBBMins().z) * 0.5 + 8) , ang, 0.1)
                surface.SetFont("ArcCW_32_Unscaled")

                local w = surface.GetTextSize(self.PrintName)

                surface.SetTextPos(-w / 2, 0)
                surface.SetTextColor(255, 255, 255, 255)
                surface.DrawText(self.PrintName)

                if self.AmmoCount > 1 then
                    w = surface.GetTextSize("×" .. self.AmmoCount)
                    surface.SetTextPos(-w / 2, 25)
                    surface.DrawText("×" .. self.AmmoCount)
                end

                --surface.SetDrawColor(255, 255, 255)
                --surface.SetMaterial(self.Icon or defaulticon)
                --local iw = 64
                --surface.DrawTexturedRect(-iw / 2, -iw - 8, iw, iw)
            cam.End3D2D()
        end
    end

end