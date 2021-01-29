function SWEP:CanAkimboAttack()
    local owner = self:GetOwner()

    -- Should we not fire? But first.
    if self:GetBuff_Hook("Hook_ShouldNotFireAkimboFirst") then return end

    -- Inoperable
    if self:GetReloading(true) then return end

    -- If we are an NPC, do our own little methods
    if owner:IsNPC() then return end

    -- Too early, come back later.
    if self:GetNextSecondaryFire() >= CurTime() then return end

    -- Coostimzing
    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return end

    -- Too close to a wall
    if self:BarrelHitWall() > 0 then return end

    -- Can't shoot while sprinting
    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return end

    -- Maximum burst shots
    if self:GetBuff_Override("Akimbo_BurstLength") and (self:GetBurstCount(true) or 0) >= self:GetBuff_Override("Akimbo_BurstLength") then return end

    -- Respect primary safety
    if self:GetCurrentFiremode().Mode == 0 then
        return
    end

    -- Should we not fire?
    if self:GetBuff_Hook("Hook_ShouldNotFireAkimbo") then return end

    -- We made it
    return true
end

function SWEP:SelectAkimboAnimation(anim)
    local tbl = self:GetBuff_Override("Akimbo_Animations")
    if !tbl then return end

    if self:GetState() == ArcCW.STATE_SIGHTS and tbl[anim .. "_iron"] then
        anim = anim .. "_iron"
    end

    if self:GetState() == ArcCW.STATE_SIGHTS and tbl[anim .. "_sights"] then
        anim = anim .. "_sights"
    end

    if self:GetState() == ArcCW.STATE_SIGHTS and tbl[anim .. "_sight"] then
        anim = anim .. "_sight"
    end

    if self:GetState() == ArcCW.STATE_SPRINT and tbl[anim .. "_sprint"] then
        anim = anim .. "_sprint"
    end

    if self:InBipod() and tbl[anim .. "_bipod"] then
        anim = anim .. "_bipod"
    end

    if self:Clip2() == 0 and tbl[anim .. "_empty"] then
        anim = anim .. "_empty"
    end

    if !tbl[anim] then return end

    return anim
end

function SWEP:DryFireAkimbo()
    local anim = (self:GetBuff_Override("Akimbo_Animations") or {}).fire_dry

    if anim then
        return self:DoLHIKAnimation("fire_dry", anim.Time)
    end
    self:MyEmitSound(self.ShootDrySound or "weapons/arccw/dryfire.wav", 75, 100, 1, CHAN_ITEM) -- TODO make sound belong to akimbo?
    self:SetNextSecondaryFire(CurTime() + 0.25)
end

function SWEP:GetAkimboDamage(range, pellet)
    local ovr = self:GetBuff_Override("Override_Akimbo_Num", nil)
    local add = self:GetBuff_Add("Add_Akimbo_Num") or 0

    local num = self:GetBuff_Override("Akimbo_Num") or 1
    local nbr = (ovr or num) + add
    local mul = 1

    mul = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num != nbr) and (num / nbr)) or 1

    if !pellet then mul = mul * nbr end

    local dmgmax = self:GetBuff("Akimbo_Damage") * mul
    local dmgmin = self:GetBuff("Akimbo_DamageMin") * mul
    local delta = 1

    local mran = self.RangeMin or 0
    local sran = self.Range
    local bran = self:GetBuff_Mult("Mult_Akimbo_Range")
    local vran = self:GetBuff_Mult("Mult_Akimbo_RangeMin")

    if range < mran * bran * vran then
        return dmgmax
    else
        delta = (dmgmax < dmgmin and (range / (sran / bran))) or (range / (sran * bran))
        delta = math.Clamp(delta, 0, 1)
    end

    local lerped = Lerp(delta, dmgmax, dmgmin)

    return lerped
end

function SWEP:AkimboAttack()
    local owner = self:GetOwner()

    self.Secondary.Automatic = true

    if !self:CanAkimboAttack() then return end

    local clip = self:Clip2()
    local aps = self:GetBuff("Akimbo_AmmoPerShot", true) or 1

    if self:GetBuff_Override("Akimbo_BottomlessClip") then
        clip = self:Ammo2()

        if self:GetBuff_Override("Akimbo_InfiniteAmmo") then
            clip = 10
        end
    end

    if clip < aps then
        self:SetBurstCount(0, true)
        self:DryFireAkimbo()

        self.Secondary.Automatic = false

        return
    end

    local desync = GetConVar("arccw_desync"):GetBool()
    local desyncnum = (desync and math.random()) or 0
    math.randomseed(math.Round(util.SharedRandom(self:GetBurstCount(), -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)

    self.Secondary.Automatic = true

    local dir = owner:GetAimVector()
    local src = self:GetShootSrc()

    if bit.band(util.PointContents(src), CONTENTS_WATER) == CONTENTS_WATER and !(self.CanFireUnderwater or self:GetBuff_Override("Override_CanFireUnderwater")) then
        self:DryFireAkimbo()

        return
    end

    local spread = ArcCW.MOAToAcc * self:GetBuff("Akimbo_AccuracyMOA")

    dir:Rotate(Angle(0, ArcCW.StrafeTilt(self), 0))

    dir = dir + VectorRand() * self:GetDispersion() / 360 / 60

    local delay = 60 / self:GetBuff_Override("Akimbo_RPM")

    self:SetNextSecondaryFire(CurTime() + delay)
    self:SetNextPrimaryFireSlowdown(CurTime() + delay) -- shadow for ONLY fire time

    local num = self:GetBuff("Akimbo_Num")

    local tracernum = self:GetBuff_Override("Akimbo_TracerNum") or self.TracerNum or 1
    local lastout = self:GetBuff_Override("Akimbo_TracerFinalMag") or self.TracerFinalMag or 0

    if lastout >= clip then
        tracernum = 1
    end

    local bullet      = {}
    bullet.Attacker   = owner
    bullet.Dir        = dir
    bullet.Src        = src
    bullet.Spread     = Vector(0, 0, 0) --Vector(spread, spread, spread)
    bullet.Damage     = 0
    bullet.Num        = num
    bullet.Force      = (self:GetAkimboDamage(0) + self:GetAkimboDamage(self:GetBuff("Range"))) / 50
    bullet.Distance   = 33000
    bullet.AmmoType   = self.Primary.Ammo
    bullet.HullSize   = (self:GetBuff_Override("Akimbo_HullSize", 0))
    bullet.Tracer     = game.SinglePlayer() and tracernum or 0
    bullet.TracerName = self:GetBuff_Override("Akimbo_Tracer") or self.Tracer
    bullet.Callback   = function(att, tr, dmg)

        local hitpos, hitnormal = tr.HitPos, tr.HitNormal
        local trent = tr.Entity

        local dist = (hitpos - src):Length() * ArcCW.HUToM
        local pen  = self:GetBuff("Penetration")

        if SERVER then
            debugoverlay.Cross(hitpos, 5, 5, Color(255, 0, 0), true)
        else
            debugoverlay.Cross(hitpos, 5, 5, Color(0, 0, 255), true)
        end

        if !game.SinglePlayer() and CLIENT and !(tracernum == 0 or clip % tracernum != 0) then
            local fx = EffectData()
            fx:SetStart(self:GetTracerOrigin(true))
            fx:SetOrigin(tr.HitPos)
            fx:SetScale(5000)
            util.Effect(bullet.TracerName or "tracer", fx)
        end

        local randfactor = self:GetBuff("DamageRand")
        local mul = 1
        if randfactor > 0 then
            mul = mul * math.Rand(1 - randfactor, 1 + randfactor)
        end

        local hit   = {}
        hit.att     = att
        hit.tr      = tr
        hit.dmg     = dmg
        hit.range   = dist
        hit.damage  = self:GetDamage(dist, true) * mul
        hit.dmgtype = self:GetBuff_Override("Override_DamageType") or self.DamageType
        hit.penleft = pen

        hit = self:GetBuff_Hook("Hook_BulletHit", hit)

        if !hit then return end

        dmg:SetDamageType(hit.dmgtype)
        dmg:SetDamage(hit.damage)

        local effect = self.ImpactEffect
        local decal  = self.ImpactDecal

        if dmg:GetDamageType() == DMG_BURN and hit.range <= self.Range then
            local dmgtype = num == 1 and DMG_BULLET or DMG_BUCKSHOT

            dmg:SetDamageType(dmgtype)

            effect = "arccw_incendiaryround"
            decal  = "FadingScorch"

            if SERVER then
                if vFireInstalled then
                    CreateVFire(trent, hitpos, hitnormal, hit.damage * 0.02)
                else
                    trent:Ignite(1, 0)
                end
            end
        end

        if SERVER then self:TryBustDoor(trent, dmg) end

        self:DoPenetration(tr, hit.penleft, { [trent:EntIndex()] = true })

        effect = self:GetBuff_Override("Override_ImpactEffect") or effect

        if effect then
            local ed = EffectData()
            ed:SetOrigin(hitpos)
            ed:SetNormal(hitnormal)

            util.Effect(effect, ed)
        end

        decal = self:GetBuff_Override("Override_ImpactDecal") or decal

        if decal then util.Decal(decal, tr.StartPos, hitpos - (hitnormal * 16), self:GetOwner()) end
    end

    local shootent = self:GetBuff("Akimbo_ShootEntity", true) --self:GetBuff_Override("Override_ShootEntity", self.ShootEntity)
    local shpatt   = self:GetBuff_Override("Akimbo_ShotgunSpreadPattern", self.ShotgunSpreadPattern)
    local shpattov = self:GetBuff_Override("Akimbo_ShotgunSpreadPatternOverrun", self.ShotgunSpreadPatternOverrun)

    local extraspread = AngleRand() * self:GetDispersion() / 360 / 60

    local projectiledata = {}

    if shpatt or shpattov or shootent then
        if shootent then
            projectiledata.ent = shootent
            projectiledata.vel = self:GetBuff("Akimbo_MuzzleVelocity") * ArcCW.HUToM
            --(self:GetBuff_Override("Override_MuzzleVelocity") or self.MuzzleVelocity) * ArcCW.HUToM * self:GetBuff_Mult("Mult_MuzzleVelocity")
        end

        bullet = self:GetBuff_Hook("Hook_FireBulletsAkimbo", bullet)

        if !bullet then return end

        local doent = shootent and num or bullet.Num
        local minnum = shootent and 1 or 0

        if doent > minnum then
            for n = 1, bullet.Num do
                bullet.Num = 1

                local dispers = self:GetBuff_Override("Akimbo_ShotgunSpreadDispersion") or self.ShotgunSpreadDispersion
                local offset  = self:GetShotgunSpreadOffset(n)
                local calcoff = dispers and (offset * self:GetDispersion() / 360 / 60) or (offset + extraspread)

                local ang = owner:EyeAngles()
                ang:RotateAroundAxis(owner:EyeAngles():Right(), -1 * calcoff.p)
                ang:RotateAroundAxis(owner:EyeAngles():Up(), calcoff.y)
                ang:RotateAroundAxis(owner:EyeAngles():Forward(), calcoff.r)

                if !self:GetBuff_Override("Akimbo_NoRandSpread") then -- Needs testing
                    ang = ang + AngleRand() * spread / 5
                end

                if shootent then
                    projectiledata.ang = ang

                    self:DoPrimaryFire(true, projectiledata)
                else
                    bullet.Dir = ang:Forward()

                    self:DoPrimaryFire(false, bullet)
                end
            end
        elseif shootent then
            local ang = owner:EyeAngles()

            if !self:GetBuff_Override("Akimbo_NoRandSpread") then
                ang = (dir + VectorRand() * spread / 5):Angle()
            end

            projectiledata.ang = ang

            self:DoPrimaryFire(true, projectiledata)
        end
    else
        if !bullet then return end

        for n = 1, bullet.Num do
            bullet.Num = 1
            math.randomseed(math.Round(util.SharedRandom(n, -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)
            if !self:GetBuff_Override("Akimbo_NoRandSpread") then
                bullet.Dir = dir + VectorRand() * spread
            end
            bullet = self:GetBuff_Hook("Hook_FireBulletsAkimbo", bullet) or bullet

            self:DoPrimaryFire(false, bullet)
        end
    end

    -- TODO akimbo recoil
    self:DoRecoil()

    --self:SetNthShot(self:GetNthShot() + 1)

    owner:DoAnimationEvent(self:GetBuff_Override("Akimbo_AnimShoot") or self.AnimShoot)

    local shouldsupp = SERVER and !game.SinglePlayer()

    if shouldsupp then SuppressHostEvents(owner) end

    self:DoEffects(true)

    self:TakeSecondaryAmmo(aps)

    self:SetBurstCount(self:GetBurstCount() + 1, true)

    if self:GetBuff_Override("Akimbo_BottomlessClip") and self:Clip2() > 0 then
        self:Unload(true)
    end

    --self:DoShootSound()
    --self:DoPrimaryAnim()

    if self:GetBuff_Override("Akimbo_ShootSound") then
        local volume = self:GetBuff_Override("Akimbo_ShootVol") or 100
        local pitch = self:GetBuff_Override("Akimbo_ShootPitch") or 100
        self:MyEmitSound(self:GetBuff_Override("Akimbo_ShootSound"), volume, pitch, 1, CHAN_WEAPON + 2)

        if self:GetBuff_Override("Akimbo_DistantShootSound") then
            self:MyEmitSound(self:GetBuff_Override("Akimbo_DistantShootSound"), 130, pitch, 1, CHAN_WEAPON - 2)
        end
    end
    if self:GetBuff_Override("Akimbo_BurstLength") and self:GetBurstCount(true) == self:GetBuff_Override("Akimbo_BurstLength") then
        local postburst = (self:GetCurrentFiremode().PostBurstDelay or 0)
        self:SetNextSecondaryFire(CurTime() + postburst)
    end

    --[[] -- Oh god I hope I don't need to implement manual action akimbos
    if (self:GetIsManualAction()) and !(self.NoLastCycle and self:Clip2() == 0) then
        local fireanim = self:GetBuff_Hook("Hook_SelectFireAnimation") or self:SelectAnimation("fire")
        local firedelay = self.Animations[fireanim].MinProgress or 0
        self:SetNeedCycle(true)
        self:SetWeaponOpDelay(CurTime() + firedelay)
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end
    ]]

    -- ???
    --self:ApplyAttachmentShootDamage()

    self:GetBuff_Hook("Hook_PostFireBulletsAkimbo")

    if shouldsupp then SuppressHostEvents(nil) end
end

function SWEP:AkimboReload()
    if self:GetOwner():IsNPC() then
        return
    end

    local ammotype = game.GetAmmoID(self:GetBuff_Override("Akimbo_Ammo"))

    if self:GetNextSecondaryFire() > CurTime() then return end
    if self:GetOwner():GetAmmoCount(ammotype) <= 0 then return end

    --self:GetBuff_Hook("Hook_PreReload")

    self.LastClip2 = self:Clip2()

    local reserve = self:GetOwner():GetAmmoCount(ammotype)

    reserve = reserve + self:Clip2()

    local clip = self:GetCapacity()

    local chamber = math.Clamp(self:Clip2(), 0, self:GetChamberSize())

    local load = math.Clamp(clip + chamber, 0, reserve)

    if load <= self:Clip2() then return end

    self:SetBurstCount(0, true)

    -- TODO Akimbo shotgun reloads... how the fuck would you reload with one hand like that?

    local anim = self:SelectAkimboReloadAnimation()
    anim = anim and self:GetBuff_Override("Akimbo_Animations")[anim]
    if !anim then return end

    self:DoLHIKAnimation(anim.Source, anim.Time)
    if anim.SoundTable then self:PlaySoundTable(anim.SoundTable) end

    self:SetNextSecondaryFire(CurTime() + anim.Time)
    self:SetReloading(CurTime() + anim.Time, true)

    self:SetMagUpIn2(CurTime() + anim.Time * (anim.MinProgress or 1))

    --self:GetBuff_Hook("Hook_PostReload")
end

function SWEP:SelectAkimboReloadAnimation()
    local ret

    local tbl = self:GetBuff_Override("Akimbo_Animations")
    if !tbl then return end

    if tbl.reload_empty and self:Clip2() == 0 then
        ret = "reload_empty"
    else
        ret = "reload"
    end

    ret = self:GetBuff_Hook("Hook_SelectAkimboReloadAnimation", ret) or ret

    return ret
end

function SWEP:RestoreAkimboAmmo(count)
    if self:GetOwner():IsNPC() then return end
    local chamber = math.Clamp(self:Clip2(), 0, self:GetBuff_Override("Akimbo_ChamberSize") or 1)
    local clip = self:GetBuff_Override("Akimbo_Capacity") --self:GetCapacity()

    if self:HasInfiniteAmmo() then
        self:SetClip2(clip + chamber)
        return
    end

    count = count or (clip + chamber)

    local reserve = self:GetOwner():GetAmmoCount(game.GetAmmoID(self:GetBuff_Override("Akimbo_Ammo")))

    reserve = reserve + self:Clip2()

    local load = math.Clamp(self:Clip2() + count, 0, reserve)

    load = math.Clamp(load, 0, clip + chamber)

    reserve = reserve - load

    -- if load <= self:Clip2() then return end

    --if SERVER then
        self:GetOwner():SetAmmo(reserve, self.Secondary.Ammo, true)
    --end
    self:SetClip2(load)
end
