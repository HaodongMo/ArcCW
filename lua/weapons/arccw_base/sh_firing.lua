function SWEP:CanAttack(is_secondary)
    local owner = self:GetOwner()

    -- Should we not fire? But first.
    if self:GetBuff_Hook("Hook_ShouldNotFireFirst") then return end

    -- Inoperable
    if self:GetReloading(is_secondary) then return end

    -- Inoperable, but internally (burst resetting for example)
    if self:GetWeaponOpDelay() > CurTime() then return end

    -- If we are an NPC, do our own little methods
    if owner:IsNPC() then self:NPC_Shoot() return end

    -- If we are in a UBGL, shoot the UBGL, not the gun
    if self:GetInUBGL() then self:ShootUBGL() return end

    -- Too early, come back later.
    if self:GetNextPrimaryFire() >= CurTime() then return end

    -- Gun is locked from heat.
    if self:GetHeatLocked() then return end

    -- Coostimzing
    if self:GetState() == ArcCW.STATE_CUSTOMIZE then
        if CLIENT and ArcCW.Inv_Hidden then
            ArcCW.Inv_Hidden = false
            gui.EnableScreenClicker(true)
        elseif game.SinglePlayer() then
            -- Kind of ugly hack: in SP this is only called serverside so we ask client to do the same check
            self:CallOnClient("CanPrimaryAttack")
        end
        return
    end

    -- Attempting a bash
    if self:GetState() != ArcCW.STATE_SIGHTS and owner:KeyDown(IN_USE) or self.PrimaryBash then self:Bash() return end

    -- Throwing weapon
    if self.Throwing then self:PreThrow() return end

    -- Too close to a wall
    if self:BarrelHitWall() > 0 then return end

    -- Can't shoot while sprinting
    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return end

    -- Maximum burst shots
    if (self:GetBurstCount() or 0) >= self:GetBurstLength() then return end

    -- We need to cycle
    if self:GetNeedCycle() then return end

    -- Safety's on, dipshit
    if self:GetCurrentFiremode().Mode == 0 then
        self:ChangeFiremode(false)
        self:SetNextPrimaryFire(CurTime())
        self.Primary.Automatic = false
        return
    end

    -- If we have a trigger delay, make sure its progress is done
    if self:GetBuff_Override("Override_TriggerDelay", self.TriggerDelay) and self:GetTriggerDelta() < 1 then
        return
    end

    -- Should we not fire?
    if self:GetBuff_Hook("Hook_ShouldNotFire") then return end

    -- We made it
    return true
end

function SWEP:CanPrimaryAttack()
    return self:CanAttack(false)
end

function SWEP:CanSecondaryAttack()
    return self:CanAttack(true)
end

-- Fires the weapon according to its stats.
-- If refname is provided, fires reftbl using secondary fire.
function SWEP:FireWeapon(refname)

    local owner = self:GetOwner()
    local clip = refname and self:Clip2() or self:Clip1()
    local aps = self:GetBuffRef("AmmoPerShot", refname)
    local reftbl = self:GetRefTable(refname)
    local is_secondary = isstring(refname) and refname != ""

    if is_secondary then
        self.Secondary.Automatic = true
    else
        self.Primary.Automatic = true
    end

    -- TODO HasBottomlessClip and HasInfiniteAmmo support refname
    if self:HasBottomlessClip(is_secondary) then
        clip = refname and self:Ammo2() or self:Ammo1()

        if self:HasInfiniteAmmo() then
            clip = 10
        end
    end

    if clip < aps then
        self:SetBurstCount(0, is_secondary)
        self:DryFire(is_secondary)
        if is_secondary then
            self.Secondary.Automatic = false
        else
            self.Primary.Automatic = false
        end
        return
    end

    if bit.band(util.PointContents(self:GetShootSrc()), CONTENTS_WATER) == CONTENTS_WATER and !self:GetBuffRef("CanFireUnderwater", refname) then
        self:DryFire(is_secondary)
        return
    end

    if !is_secondary then
        if self:GetMalfunctionJam() then
            self:DryFire()
            return
        else
            -- Try malfunctioning
            local mal = self:DoMalfunction()
            if mal == true then
                return
            end
        end
    end

    local dir = owner:GetAimVector()
    local src = self:GetShootSrc()

    local desync = GetConVar("arccw_desync"):GetBool()
    local desyncnum = (desync and math.random()) or 0
    math.randomseed(math.Round(util.SharedRandom(self:GetBurstCount(), -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)


    local spread = ArcCW.MOAToAcc * self:GetBuffRef("AccuracyMOA", refname)

    dir:Rotate(Angle(0, ArcCW.StrafeTilt(self), 0))
    dir = dir + VectorRand() * self:GetDispersion(refname) * ArcCW.MOAToAcc / 10
    local delay = self:GetFiringDelay()

    local curtime = CurTime()
    local curatt = is_secondary and self:GetNextSecondaryFire() or self:GetNextPrimaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
        curatt = curtime
    end

    if is_secondary then
        self:SetNextSecondaryFire(curatt + delay)
    else
        self:SetNextPrimaryFire(curatt + delay)
        self:SetNextPrimaryFireSlowdown(curatt + delay) -- shadow for ONLY fire time
    end

    local num = self:GetBuff_Override("Override_Num", reftbl.Num, refname)
    num = num + self:GetBuff_Add("Add_Num", refname)
    --local num = self:GetBuffRef("Num", refname)

    local tracernum = self:GetBuff_Override("Override_TracerNum", reftbl.TracerNum, refname)
    local lastout = self:GetBuff_Override("Override_TracerFinalMag", reftbl.TracerFinalMag, refname)

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
    bullet.Force      = (self:GetDamage(0) + self:GetDamage(math.huge)) / 50
    bullet.Distance   = 33000
    bullet.AmmoType   = self.Primary.Ammo
    bullet.HullSize   = self:GetBuffRef("HullSize", refname)
    bullet.Tracer     = tracernum or 0
    bullet.TracerName = self:GetBuffRef("TracerName", refname)
    bullet.Weapon     = self
    bullet.Callback   = function(att, tr, dmg)
        local hitpos, hitnormal = tr.HitPos, tr.HitNormal
        local trent = tr.Entity

        local dist = (hitpos - src):Length() * ArcCW.HUToM
        local pen  = self:GetBuffRef("Penetration", refname)

        if SERVER then
            debugoverlay.Cross(hitpos, 5, 5, Color(255, 0, 0), true)
        else
            debugoverlay.Cross(hitpos, 5, 5, Color(0, 0, 255), true)
        end

        --[[if !game.SinglePlayer() and CLIENT and !(tracernum == 0 or clip % tracernum != 0) then
            local fx = EffectData()
            fx:SetStart(self:GetTracerOrigin())
            fx:SetOrigin(tr.HitPos)
            fx:SetScale(5000)
            fx:SetEntity(self)
            util.Effect(bullet.TracerName or "tracer", fx)
        end]]

        local randfactor = self:GetBuffRef("DamageRand", refname)
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
        hit.dmgtype = self:GetBuff_Override("Override_DamageType", reftbl.DamageType, refname)
        hit.penleft = pen

        hit = self:GetBuff_Hook("Hook_BulletHit", hit, refname)

        if !hit then return end

        dmg:SetDamageType(hit.dmgtype)
        dmg:SetDamage(hit.damage)

        local effect = reftbl.ImpactEffect
        local decal  = reftbl.ImpactDecal

        if dmg:IsDamageType(DMG_BURN) and self:GetRangeFraction(hit.range) < 1 then
            dmg:SetDamageType(dmg:GetDamageType() - DMG_BURN)

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

        if GetConVar("developer"):GetInt() >= 2 then
            debugoverlay.Text(hitpos, string.format("%ddmg/%dm(%d%%)", dmg:GetDamage(), dist, math.Round((1 - self:GetRangeFraction(dist)) * 100)), 5)
        end
    end

    local shootent = self:GetBuff("ShootEntity", true) --self:GetBuff_Override("Override_ShootEntity", self.ShootEntity)
    local shpatt   = self:GetBuff_Override("Override_ShotgunSpreadPattern", self.ShotgunSpreadPattern)
    local shpattov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun", self.ShotgunSpreadPatternOverrun)

    local extraspread = AngleRand() * self:GetDispersion() * ArcCW.MOAToAcc / 10

    local projectiledata = {}

    if shpatt or shpattov or shootent then
        if shootent then
            projectiledata.ent = shootent
            projectiledata.vel = self:GetBuff("MuzzleVelocity") * ArcCW.HUToM
            --(self:GetBuff_Override("Override_MuzzleVelocity") or self.MuzzleVelocity) * ArcCW.HUToM * self:GetBuff_Mult("Mult_MuzzleVelocity")
        end

        bullet = self:GetBuff_Hook("Hook_FireBullets", bullet)

        if !bullet then return end

        local doent = shootent and num or bullet.Num
        local minnum = shootent and 1 or 0

        if doent > minnum then
            for n = 1, bullet.Num do
                bullet.Num = 1

                local dispers = self:GetBuff_Override("Override_ShotgunSpreadDispersion") or self.ShotgunSpreadDispersion
                local offset  = self:GetShotgunSpreadOffset(n)
                local calcoff = dispers and (offset * self:GetDispersion() * ArcCW.MOAToAcc / 10) or (offset + extraspread)

                local ang = owner:EyeAngles()
                ang:RotateAroundAxis(owner:EyeAngles():Right(), -1 * calcoff.p)
                ang:RotateAroundAxis(owner:EyeAngles():Up(), calcoff.y)
                ang:RotateAroundAxis(owner:EyeAngles():Forward(), calcoff.r)

                if !self:GetBuff_Override("Override_NoRandSpread") then -- Needs testing
                    ang = ang + AngleRand() * spread / 5
                end

                if shootent then
                    projectiledata.ang = ang

                    self:Shoot(true, projectiledata)
                else
                    bullet.Dir = ang:Forward()

                    self:Shoot(false, bullet)
                end
            end
        elseif shootent then
            local ang = owner:EyeAngles()

            if !self:GetBuff_Override("Override_NoRandSpread") then
                ang = (dir + VectorRand() * spread / 5):Angle()
            end

            projectiledata.ang = ang

            self:Shoot(true, projectiledata)
        end
    else
        if !bullet then return end

        for n = 1, bullet.Num do
            bullet.Num = 1
            math.randomseed(math.Round(util.SharedRandom(n, -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)
            if !self:GetBuff_Override("Override_NoRandSpread") then
                bullet.Dir = dir + VectorRand() * spread
            end
            bullet = self:GetBuff_Hook("Hook_FireBullets", bullet) or bullet

            self:Shoot(false, bullet)
        end
    end
    owner:DoAnimationEvent(self:GetBuff_Override("Override_AnimShoot") or self.AnimShoot)

    local shouldsupp = SERVER and !game.SinglePlayer()

    if shouldsupp then SuppressHostEvents(owner) end

    self:DoEffects()

    self:DoRecoil(refname)

    if is_secondary then
        self:TakeSecondaryAmmo(aps)
    else
        self:SetNthShot(self:GetNthShot() + 1)
        self:TakePrimaryAmmo(aps)
    end

    self:SetBurstCount(self:GetBurstCount() + 1)

    if self:HasBottomlessClip(is_secondary) and ((is_secondary and self:Clip2() > 0) or (!is_secondary and self:Clip1() > 0)) then
        self:Unload(is_secondary)
    end

    self:DoShootSound()
    self:DoPrimaryAnim()

    if self:GetCurrentFiremode().Mode < 0 and self:GetBurstCount() == self:GetBurstLength() then
        local postburst = (self:GetCurrentFiremode().PostBurstDelay or 0)
        self:SetWeaponOpDelay(CurTime() + postburst * self:GetBuff_Mult("Mult_PostBurstDelay") + self:GetBuff_Add("Add_PostBurstDelay"))
    end

    if (self:GetIsManualAction()) and !(self.NoLastCycle and self:Clip1() == 0) then
        local fireanim = self:GetBuff_Hook("Hook_SelectFireAnimation") or self:SelectAnimation("fire")
        local firedelay = self.Animations[fireanim].MinProgress or 0
        self:SetNeedCycle(true)
        self:SetWeaponOpDelay(CurTime() + firedelay)
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    self:ApplyAttachmentShootDamage()

    self:AddHeat(1)

    self:GetBuff_Hook("Hook_PostFireBullets")

    if shouldsupp then SuppressHostEvents(nil) end
end

function SWEP:PrimaryAttack()
    if !self:CanPrimaryAttack() then return end
    self:FireWeapon(false)
end

function SWEP:SecondaryAttack()
    --return self.Melee2 and self:Bash(true)
    if self.Melee2 then
        return self:Bash(true)
    elseif isstring(self:GetBuff_Override("UBGL2")) and self:GetBuff_Override("UBGL2_SecondaryFire") then
        if !self:CanSecondaryAttack() then return end
        self:FireWeapon(self:GetBuff_Override("UBGL2"))
    end
end

function SWEP:TryBustDoor(ent, dmg)
    ArcCW.TryBustDoor(ent, dmg)
end

function SWEP:DoShootSound(sndoverride, dsndoverride, voloverride, pitchoverride)
    local fsound = self.ShootSound
    local suppressed = self:GetBuff_Override("Silencer")

    if suppressed then
        fsound = self.ShootSoundSilenced
    end

    local firstsound = self.FirstShootSound

    if self:GetBurstCount() == 1 and firstsound then
        fsound = firstsound

        local firstsil = self.FirstShootSoundSilenced

        if suppressed then
            fsound = firstsil and firstsil or self.ShootSoundSilenced
        end
    end

    local lastsound = self.LastShootSound

    local clip = self:Clip1()

    if clip == 1 and lastsound then
        fsound = lastsound

        local lastsil = self.LastShootSoundSilenced

        if suppressed then
            fsound = lastsil and lastsil or self.ShootSoundSilenced
        end
    end

    fsound = self:GetBuff_Hook("Hook_GetShootSound", fsound)

    local distancesound = self.DistantShootSound

    if suppressed then
        distancesound = nil
    end

    distancesound = self:GetBuff_Hook("Hook_GetDistantShootSound", distancesound)

    local spv = self.ShootPitchVariation
    local volume = self.ShootVol
    local pitch  = self.ShootPitch * math.Rand(1 - spv, 1 + spv) * self:GetBuff_Mult("Mult_ShootPitch")

    local v = GetConVar("arccw_weakensounds"):GetFloat()

    volume = volume - v

    volume = volume * self:GetBuff_Mult("Mult_ShootVol")

    volume = math.Clamp(volume, 51, 149)
    pitch  = math.Clamp(pitch, 0, 255)

    if    sndoverride        then    fsound    = sndoverride end
    if    dsndoverride    then    distancesound = dsndoverride end
    if    voloverride        then    volume    = voloverride end
    if    pitchoverride    then    pitch    = pitchoverride end

    if distancesound then self:MyEmitSound(distancesound, 149, pitch, 0.5, CHAN_WEAPON + 1) end

    if fsound then self:MyEmitSound(fsound, volume, pitch, 1, CHAN_WEAPON) end

    local data = {
        sound   = fsound,
        volume  = volume,
        pitch   = pitch,
    }

    self:GetBuff_Hook("Hook_AddShootSound", data)
end

function SWEP:GetMuzzleVelocity()
    local vel = self:GetBuff_Override("Override_PhysBulletMuzzleVelocity", self.PhysBulletMuzzleVelocity)

    if !vel then
        vel = math.Clamp(self:GetBuff("Range"), 30, 300) * 8 * self:GetBuff_Mult("Mult_Range")

        if self.DamageMin > self.Damage then
            vel = vel * 3
        end
    end

    vel = vel / ArcCW.HUToM

    vel = vel * self:GetBuff_Mult("Mult_PhysBulletMuzzleVelocity")

    vel = vel * GetConVar("arccw_bullet_velocity"):GetFloat()

    return vel
end

function SWEP:Shoot(isent, data, refname)
    local clip = refname and self:Clip2() or self:Clip1()
    if self:HasBottomlessClip(refname) then
        clip = refname and self:Ammo2() or self:Ammo1()
    end
    local owner = self:GetOwner()

    local shouldphysical = GetConVar("arccw_bullet_enable"):GetBool()

    if self.AlwaysPhysBullet or self:GetBuff_Override("Override_AlwaysPhysBullet") then
        shouldphysical = true
    end

    if self.NeverPhysBullet or self:GetBuff_Override("Override_NeverPhysBullet") then
        shouldphysical = false
    end

    if isent then
        self:FireRocket(data.ent, data.vel, data.ang, self.PhysBulletDontInheritPlayerVelocity)
    else
        -- if !game.SinglePlayer() and !IsFirstTimePredicted() then return end
        if !IsFirstTimePredicted() then return end

        if shouldphysical then
            local tracernum = data.TracerNum or 1
            local prof

            if tracernum == 0 or clip % tracernum != 0 then
                prof = 7
            end

            local vel = self:GetMuzzleVelocity()

            vel = vel * data.Dir:GetNormalized()

            ArcCW:ShootPhysBullet(self, data.Src, vel, prof)
        else
            if owner:IsPlayer() then
                owner:LagCompensation(true)
                if SERVER and !game.SinglePlayer() then SuppressHostEvents(owner) end
            end
            owner:FireBullets(data)
            if owner:IsPlayer() then
                owner:LagCompensation(false)
                if SERVER and !game.SinglePlayer() then SuppressHostEvents(nil) end
            end
        end
    end
end

function SWEP:DoPrimaryAnim()
    local anim = "fire"

    local inbipod = self:InBipod()
    local iron    = self:GetState() == ArcCW.STATE_SIGHTS

    -- Needs testing
    if inbipod then
        anim = self:SelectAnimation("fire_bipod") or self:SelectAnimation("fire") or anim
    else
        anim = self:SelectAnimation("fire") or anim
    end

    if (self.ProceduralIronFire and iron) or (self.ProceduralRegularFire and !iron) then anim = nil end

    anim = self:GetBuff_Hook("Hook_SelectFireAnimation", anim) or anim

    local time = self:GetBuff_Mult("Mult_FireAnimTime") or 1

    if anim then self:PlayAnimation(anim, time, true, 0, false) end
end

function SWEP:DoPenetration(tr, penleft, alreadypenned)
    local bullet = {
        Damage = self:GetDamage((tr.HitPos - tr.StartPos):Length() * ArcCW.HUToM),
        DamageType = self:GetBuff_Override("Override_DamageType") or self.DamageType,
        Weapon = self,
        Penetration = self:GetBuff("Penetration"),
        Attacker = self:GetOwner(),
        Travelled = (tr.HitPos - tr.StartPos):Length()
    }

    ArcCW:DoPenetration(tr, bullet.Damage, bullet, penleft, false, alreadypenned)
end

function SWEP:GetFiringDelay(refname)
    local reftbl = self:GetRefTable(refname)
    local delay = (reftbl.Delay * (1 / self:GetBuff_Mult("Mult_RPM", refname) + self:GetBuff_Add("Add_RPM", refname)))
    delay = self:GetBuff_Hook("Hook_ModifyRPM", delay) or delay
    return delay
end

function SWEP:GetShootSrc(refname) -- TODO refname
    local owner = self:GetOwner()

    if owner:IsNPC() then return owner:GetShootPos() end

    local dir    = owner:EyeAngles()
    local offset = self:GetBuff_Override("Override_BarrelOffsetHip") or self.BarrelOffsetHip

    if self:GetOwner():Crouching() then
        offset = self:GetBuff_Override("Override_BarrelOffsetCrouch") or self.BarrelOffsetCrouch or offset
    end

    if self:GetState() == ArcCW.STATE_SIGHTS then
        offset = self:GetBuff_Override("Override_BarrelOffsetSighted") or self.BarrelOffsetSighted or offset
    end

    local src = owner:EyePos()


    src = src + dir:Right()   * offset[1]
    src = src + dir:Forward() * offset[2]
    src = src + dir:Up()      * offset[3]

    return src
end

function SWEP:GetShotgunSpreadOffset(num, refname)
    local reftbl = self:GetRefTable(refname)
    local rotate = Angle()
    local spreadpt = self:GetBuff_Override("Override_ShotgunSpreadPattern") or reftbl.ShotgunSpreadPattern or {}
    local spreadov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or reftbl.ShotgunSpreadPatternOverrun or { Angle() }

    if istable(spreadpt) and istable(spreadov) then
        spreadpt["BaseClass"] = nil
        spreadov["BaseClass"] = nil

        if num > #spreadpt then
            if spo then
                num = num - #spreadpt
                num = math.fmod(num, #spreadov) + 1
                rotate = spreadov[num]
            else
                num = math.fmod(num, #spreadpt) + 1
                rotate = spreadpt[num]
            end
        else
            rotate = spreadpt[num]
        end
    end

    local rottoang = {}
    rottoang.num = num
    rottoang.ang = rotate

    rotate = self:GetBuff_Hook("Hook_ShotgunSpreadOffset", rottoang, refname).ang

    return rotate or Angle()
end

function SWEP:GetDispersion(refname)
    local owner = self:GetOwner()
    local delta = self:GetSightDelta()

    if vrmod and vrmod.IsPlayerInVR(owner) then return 0 end

    local hipdisp = self:GetBuffRef("HipDispersion", refname)
    local sights  = self:GetState() == ArcCW.STATE_SIGHTS

    local hip = hipdisp

    local sightdisp = self:GetBuffRef("SightsDispersion", refname)
    if sights then hip = Lerp(delta, sightdisp, hipdisp) end

    if owner:OnGround() or owner:WaterLevel() > 0 or owner:GetMoveType() == MOVETYPE_NOCLIP then
        local speed    = owner:GetAbsVelocity():Length()
        local maxspeed = owner:GetWalkSpeed() * self:GetBuffRef("SpeedMult", refname)

        if sights then maxspeed = maxspeed * self:GetBuffRef("SightedSpeedMult", refname) end

        speed = math.Clamp(speed / maxspeed, 0, 2)

        hip = hip + (speed * self:GetBuffRef("MoveDispersion", refname))
    else
        hip = hip + self:GetBuffRef("JumpDispersion", refname)
    end

    if self:InBipod() then hip = hip * ((self.BipodDispersion or 1) * self:GetBuff_Mult("Mult_BipodDispersion") or 0.1) end

    if GetConVar("arccw_mult_crouchdisp"):GetFloat() != 1 and owner:OnGround() and owner:Crouching() then
        hip = hip * GetConVar("arccw_mult_crouchdisp"):GetFloat()
    end

    --local t = hook.Run("ArcCW_ModDispersion", self, {dispersion = hip})
    --hip = t and t.dispersion or hip
    hip = self:GetBuff_Hook("Hook_ModDispersion", hip, refname) or hip

    return hip
end

function SWEP:DoShellEject(atti)
    local eff = self:GetBuff_Override("Override_ShellEffect") or "arccw_shelleffect"

    if eff == "NONE" then return end

    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local vm = self

    if !owner:IsNPC() then owner:GetViewModel() end

    local att = vm:GetAttachment(atti or self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)

    if !att then return end

    local pos, ang = att.Pos, att.Ang

    if pos and ang and self.ShellEjectPosCorrection then
        local up = ang:Up()
        local right = ang:Right()
        local forward = ang:Forward()
        pos = pos + up * self.ShellEjectPosCorrection.z + right * self.ShellEjectPosCorrection.x + forward * self.ShellEjectPosCorrection.y
    end

    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetAngles(ang)
    ed:SetAttachment(atti or self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)
    ed:SetScale(1)
    ed:SetEntity(self)
    ed:SetNormal(ang:Forward())
    ed:SetMagnitude(100)

    local efov = {}
    efov.eff = eff
    efov.fx  = ed

    if self:GetBuff_Hook("Hook_PreDoEffects", efov) == true then return end

    util.Effect(eff, ed)
end

function SWEP:DoEffects(att, is_secondary)
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local ed = EffectData()
    ed:SetScale(1)
    ed:SetEntity(self)
    ed:SetAttachment(att or self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1)

    local efov = {}
    efov.eff = "arccw_muzzleeffect"
    efov.fx  = ed

    self:SetEffectLastSecondary(is_secondary)

    if self:GetBuff_Hook("Hook_PreDoEffects", efov) == true then return end

    util.Effect("arccw_muzzleeffect", ed)
end

function SWEP:DryFire(refname)
    local tbl = self:GetRefTable(refname)
    if tbl.Animations.fire_dry then
        if tbl.Animations.fire_dry.IsLHIKAnim then
            return self:DoLHIKAnimation("fire_dry", tbl.Animations.fire_dry.Time)
        else
            return self:PlayAnimation("fire_dry", 1, true, 0, true)
        end
    end
    self:MyEmitSound(tbl.ShootDrySound or "weapons/arccw/dryfire.wav", 75, 100, 1, CHAN_ITEM)
    self:SetNextPrimaryFire(CurTime() + 0.25)
end

function SWEP:DoRecoil(refname)
    local single = game.SinglePlayer()
    if !single and !IsFirstTimePredicted() then return end
    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("DoRecoil", refname) end

    local reftable = self:GetRefTable(refname)
    local is_secondary = isstring(refname)

    -- math.randomseed(self:GetBurstLength() + (self.Recoil * 409) + (self.RecoilSide * 519))

    local rec = {
        Recoil = 1,
        RecoilSide = 1,
        VisualRecoilMul = 1
    }
    rec = self:GetBuff_Hook("Hook_ModifyRecoil", rec) or rec

    local stat_up = reftable.Recoil
    local stat_side = reftable.RecoilSide
    local stat_rise = reftable.RecoilRise

    local recoil = rec.Recoil
    local side   = rec.RecoilSide
    local visual = rec.VisualRecoilMul

    local rmul = (recoil or 1) * self:GetBuff_Mult("Mult_Recoil", refname)
    local recv = (visual or 1) * self:GetBuff_Mult("Mult_VisualRecoilMult", refname)
    local recs = (side or 1)   * self:GetBuff_Mult("Mult_RecoilSide", refname)

    -- local rrange = math.Rand(-recs, recs) * self.RecoilSide

    -- local irec = math.Rand(rrange - 1, rrange + 1)
    -- local recu = math.Rand(0.5, 1)

    local irec = math.Rand(-1, 1)
    local recu = 1

    if self:InBipod() then
        local biprec = reftable.BipodRecoil
        local bipmul = self:GetBuff_Mult("Mult_BipodRecoil", refname)

        local b = ((biprec or 1) * bipmul or 0.25)

        rmul = rmul * b
        recs = recs * b
        recv = recv * b
    end

    local recoiltbl = self:GetBuffRef("ShotRecoilTable", refname, true)

    if recoiltbl and recoiltbl[self:GetBurstCount(is_secondary)] then rmul = rmul * recoiltbl[self:GetBurstCount(is_secondary)] end

    if GetConVar("arccw_mult_crouchrecoil"):GetFloat() != 1 and self:GetOwner():OnGround() and self:GetOwner():Crouching() then
        rmul = rmul * GetConVar("arccw_mult_crouchrecoil"):GetFloat()
    end

    local punch = Angle()

    punch = punch + (self:GetBuffRef("RecoilDirection", refname) * math.max(stat_up, 0.25) * recu * recv * rmul)
    punch = punch + (self:GetBuffRef("RecoilDirectionSide", refname) * math.max(stat_side, 0.25) * irec * recv * rmul)
    punch = punch + Angle(0, 0, 90) * math.Rand(-1, 1) * math.Clamp(stat_up, 0.25, 1) * recv * rmul * 0.01
    punch = punch * (self.RecoilPunch or 1) * self:GetBuff_Mult("Mult_RecoilPunch", refname)

    if CLIENT then self:OurViewPunch(punch) end

    if CLIENT or single then
        recv = recv * reftable.VisualRecoilMult

        self.RecoilAmount     = self.RecoilAmount + (stat_up * rmul * recu)
        self.RecoilAmountSide = self.RecoilAmountSide + (stat_side * irec * recs * rmul)
        self.RecoilPunchBack  = math.Clamp(self.RecoilAmount * recv * 5, 1, 5)

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = stat_side * 0.1 * irec * recv * rmul
        self.RecoilPunchUp   = stat_rise * 0.1 * recu
    end

    -- math.randomseed(CurTime() + (self:EntIndex() * 3))
end

function SWEP:GetBurstLength(refname)
    local is_secondary = isstring(refname) and refname != ""
    local clip = is_secondary and self:Clip2() or self:Clip1()
    if self:HasBottomlessClip(is_secondary) then
        clip = is_secondary and self:Ammo2() or self:Ammo1()
    end
    if clip == 0 then return 1 end

    local len = self:GetCurrentFiremode().Mode

    if !len then return self:GetBurstCount(refname) + 10 end

    local hookedlen = self:GetBuff_Hook("Hook_GetBurstLength", len, refname)

    if len == 1 then return 1 end
    if len >= 2 then return self:GetBurstCount(refname) + 10 end

    if hookedlen != len then return hookedlen end

    if len < 0 then return -len end

    return self:GetBurstCount(refname) + 10
end

function SWEP:FireAnimationEvent(pos, ang, event, options)
    return true
end

function SWEP:GetRangeFraction(range, refname)
    local reftbl = self:GetRefTable(refname)
    local decrease = self:GetBuffRef("Damage", refname) < self:GetBuffRef("DamageMin", refname)
    local mran = reftbl.RangeMin or 0
    local sran = reftbl.Range
    local bran = self:GetBuff_Mult("Mult_Range", refname)
    local vran = self:GetBuff_Mult("Mult_RangeMin", refname)

    if range < mran * bran * vran then
        return 0
    else
        range = range - mran * bran * vran
        if decrease then
            return math.Clamp(range / (sran / bran), 0, 1)
        else
            return math.Clamp(range / (sran * bran), 0, 1)
        end
    end
end

function SWEP:GetDamage(range, pellet, refname)
    local reftbl = self:GetRefTable(refname)
    local ovr = self:GetBuff_Override("Override_Num", nil, refname)
    local add = self:GetBuff_Add("Add_Num", refname)

    local num = reftbl.Num
    local nbr = (ovr or num) + add
    local mul = 1

    mul = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num != nbr) and (num / nbr)) or 1

    if !pellet then mul = mul * nbr end

    local dmgmax = self:GetBuffRef("Damage", refname) * mul
    local dmgmin = self:GetBuffRef("DamageMin", refname) * mul
    local delta = self:GetRangeFraction(range, refname)

    local lerped = Lerp(delta, dmgmax, dmgmin)

    return lerped
end