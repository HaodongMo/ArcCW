function SWEP:CanPrimaryAttack()
    local owner = self:GetOwner()
    if owner:IsNPC() then self:NPC_Shoot() return end

    if self:GetInUBGL() then self:ShootUBGL() return end

    if self:GetNextPrimaryFire() >= CurTime() then return end

    if self:GetHeatLocked() then return end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return end

    if self:GetState() != ArcCW.STATE_SIGHTS and owner:KeyDown(IN_USE) or self.PrimaryBash then self:Bash() return end

    if self.Throwing then self:PreThrow() return end

    if self:BarrelHitWall() > 0 then return end

    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return end

    if (self:GetBurstCount() or 0) >= self:GetBurstLength() then return end

    if self:GetNeedCycle() then return end

    if self:GetCurrentFiremode().Mode == 0 then
        self:ChangeFiremode(false)
        --self.Primary.Automatic = false

        return
    end

    if self:GetBuff_Hook("Hook_ShouldNotFire") then return end

    return true
end



function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    self.Primary.Automatic = true

    if !self:CanPrimaryAttack() then return end

    local clip = self:Clip1()
    local aps = self:GetBuff_Override("Override_AmmoPerShot") or self.AmmoPerShot

    if self:HasBottomlessClip() then
        clip = self:Ammo1()

        if self:HasInfiniteAmmo() then
            clip = 10
        end
    end

    if clip < aps then
        self:SetBurstCount(0)
        self:DryFire()

        self.Primary.Automatic = false

        return
    end


    local desync = GetConVar("arccw_desync"):GetBool()
    local desyncnum = (desync and math.random()) or 0
    math.randomseed(math.Round(util.SharedRandom(self:GetBurstCount(), -1337, 1337, self:GetOwner():GetCurrentCommand():CommandNumber()) * (self:EntIndex() % 30241)) + desyncnum)

    self.Primary.Automatic = true

    local dir = owner:EyeAngles()
    local src = self:GetShootSrc()

    if bit.band(util.PointContents(src), CONTENTS_WATER) == CONTENTS_WATER and !(self.CanFireUnderwater or self:GetBuff_Override("Override_CanFireUnderwater")) then
        self:DryFire()

        return
    end

    local spread = ArcCW.MOAToAcc * self.AccuracyMOA * self:GetBuff_Mult("Mult_AccuracyMOA")

    dir = dir + (AngleRand() * self:GetDispersion() / 360 / 60)

    local delay = (self.Delay * (1 / self:GetBuff_Mult("Mult_RPM")))

    delay = self:GetBuff_Hook("Hook_ModifyRPM", delay) or delay

    self:SetNextPrimaryFire(CurTime() + delay)

    local num = self:GetBuff_Override("Override_Num")

    if !num then num = self.Num end

    num = num + self:GetBuff_Add("Add_Num")

    local tracernum = self:GetBuff_Override("Override_TracerNum") or self.TracerNum
    local lastout = self:GetBuff_Override("Override_TracerFinalMag") or self.TracerFinalMag

    if lastout >= clip then
        tracernum = 1
    end

    local bullet      = {}
    bullet.Attacker   = owner
    bullet.Dir        = dir:Forward()
    bullet.Src        = src
    bullet.Spread     = Vector(spread, spread, spread)
    bullet.Damage     = 0
    bullet.Num        = num
    bullet.Force      = 1 / num
    bullet.Distance   = 33000
    bullet.AmmoType   = self.Primary.Ammo
    bullet.HullSize   = (self:GetBuff_Override("Override_HullSize") or self.HullSize or 0) + self:GetBuff_Add("Add_HullSize")
    bullet.Tracer     = tracernum
    bullet.TracerName = self:GetBuff_Override("Override_Tracer") or self.Tracer
    bullet.Callback   = function(att, tr, dmg)
        local hitpos, hitnormal = tr.HitPos, tr.HitNormal
        local trent = tr.Entity

        local dist = (hitpos - src):Length() * ArcCW.HUToM
        local pen  = self.Penetration * self:GetBuff_Mult("Mult_Penetration")

        if SERVER then
            debugoverlay.Cross(hitpos, 5, 5, Color(255, 0, 0), true)
        else
            debugoverlay.Cross(hitpos, 5, 5, Color(0, 0, 255), true)
        end

        local hit   = {}
        hit.att     = att
        hit.tr      = tr
        hit.dmg     = dmg
        hit.range   = dist
        hit.damage  = self:GetDamage(dist, true)
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

        if SERVER then ArcCW.TryBustDoor(trent, dmg) end

        self:DoPenetration(tr, hit.penleft, { trent })

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

    local shootent = self:GetBuff_Override("Override_ShootEntity") or self.ShootEntity
    local shpatt   = self:GetBuff_Override("Override_ShotgunSpreadPattern") or self.ShotgunSpreadPattern
    local shpattov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or self.ShotgunSpreadPatternOverrun

    local extraspread = AngleRand() * self:GetDispersion() / 360 / 60

    local projectiledata = {}

    if shpatt or shpattov or shootent then
        if shootent then
            projectiledata.ent = shootent
            projectiledata.vel = (self:GetBuff_Override("Override_MuzzleVelocity") or self.MuzzleVelocity) * ArcCW.HUToM * self:GetBuff_Mult("Mult_MuzzleVelocity")
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
                local calcoff = dispers and (offset * self:GetDispersion() / 60) or (offset + extraspread)

                local ang = owner:EyeAngles() + calcoff

                if !self:GetBuff_Override("Override_NoRandSpread") then -- Needs testing
                    ang = ang + AngleRand() * spread / 10
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

            if !self:GetBuff_Override("Override_NoRandSpread") then -- Needs testing
                ang = ang + (AngleRand() * spread / 10)
            end

            projectiledata.ang = ang + extraspread

            self:DoPrimaryFire(true, projectiledata)
        end
    else
        bullet = self:GetBuff_Hook("Hook_FireBullets", bullet)

        if !bullet then return end

        for n = 1, bullet.Num do
            bullet.Num = 1
            math.randomseed(math.Round(util.SharedRandom(n, -1337, 1337, self:GetOwner():GetCurrentCommand():CommandNumber()) * (self:EntIndex() % 30241)) + desyncnum)
            if !self:GetBuff_Override("Override_NoRandSpread") then
                local ang = dir + AngleRand() * spread / 5
                bullet.Dir = ang:Forward()
            end

            self:DoPrimaryFire(false, bullet)
        end
    end

    self:DoRecoil()

    owner:DoAnimationEvent(self:GetBuff_Override("Override_AnimShoot") or self.AnimShoot)

    local shouldsupp = SERVER and !game.SinglePlayer()

    if shouldsupp then SuppressHostEvents(owner) end

    self:DoEffects()

    if IsFirstTimePredicted() then self:TakePrimaryAmmo(aps) end

    self:SetBurstCount(self:GetBurstCount() + 1)

    if self:HasBottomlessClip() then
        if self:Clip1() > 0 then
            self:Unload()
        end
    end

    self:DoShootSound()
    self:DoPrimaryAnim()

    if (self.ManualAction or self:GetBuff_Override("Override_ManualAction")) and !(self.NoLastCycle and clip == 0) then
        local fireanim = self:GetBuff_Hook("Hook_SelectFireAnimation") or self:SelectAnimation("fire")
        local firedelay = self.Animations[fireanim].MinProgress or 0
        self:SetNeedCycle(true)
        self.DelayCycleAnim = CurTime() + firedelay / self:GetBuff_Mult("Mult_RPM")
    end

    if self:GetCurrentFiremode().Mode < 0 and self:GetBurstCount() == -self:GetCurrentFiremode().Mode then
        local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

        self:SetNextPrimaryFire(CurTime() + postburst)
    end

    self:ApplyAttachmentShootDamage()

    self:AddHeat()

    self:GetBuff_Hook("Hook_PostFireBullets")

    if shouldsupp then SuppressHostEvents(nil) end
end

function SWEP:DoShootSound(sndoverride, dsndoverride, voloverride, pitchoverride)
    local fsound = self.ShootSound

    if self:GetBuff_Override("Silencer") then
        fsound = self.ShootSoundSilenced
    end

    local firstsound = self.FirstShootSound

    if self:GetBurstCount() == 0 and firstsound then
        fsound = firstsound

        local firstsil = self.FirstShootSoundSilenced

        if self:GetBuff_Override("Silencer") then
            fsound = firstsil and firstsil or self.ShootSoundSilenced
        end
    end

    local lastsound = self.LastShootSound

    local clip = self:Clip1()

    if clip == 1 and lastsound then
        fsound = lastsound

        local lastsil = self.LastShootSoundSilenced

        if self:GetBuff_Override("Silencer") then
            fsound = lastsil and lastsil or self.ShootSoundSilenced
        end
    end

    fsound = self:GetBuff_Hook("Hook_GetShootSound", fsound)

    local distancesound = self.DistantShootSound

    if self:GetBuff_Override("Silencer") then
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
    pitch  = math.Clamp(pitch, 51, 149)

    if	sndoverride		then	fsound	= sndoverride end
    if	dsndoverride	then	distancesound = dsndoverride end
    if	voloverride		then	volume	= voloverride end
    if	pitchoverride	then	pitch	= pitchoverride end

    if distancesound then self:MyEmitSound(distancesound, 149, pitch, 0.5, CHAN_WEAPON + 1) end

    if fsound then self:MyEmitSound(fsound, volume, pitch, 1, CHAN_WEAPON) end

    self:GetBuff_Hook("Hook_AddShootSound", fsound, volume, pitch)
end

function SWEP:DoPrimaryFire(isent, data)
    local clip = self:Clip1()
    if self:HasBottomlessClip() then
        clip = self:Ammo1()
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
        self:FireRocket(data.ent, data.vel, data.ang)
    else
        if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

        if shouldphysical then
            local vel = self.PhysBulletMuzzleVelocity

            local tracernum = data.Tracer
            local prof

            if tracernum == 0 or clip % tracernum != 0 then
                prof = 7
            end

            if !vel then
                vel = self.Range * self:GetBuff_Mult("Mult_Range") * 5.5

                if self.DamageMin > self.Damage then
                    vel = vel * 3
                end
            end

            vel = vel / ArcCW.HUToM

            vel = vel * self:GetBuff_Mult("Mult_PhysBulletMuzzleVelocity") * self:GetBuff_Mult("Mult_Range")

            vel = vel * GetConVar("arccw_bullet_velocity"):GetFloat()

            vel = vel * data.Dir:GetNormalized()

            ArcCW:ShootPhysBullet(self, data.Src, vel, prof)
        else
            if owner:IsPlayer() then
                owner:LagCompensation(true)
            end
            owner:FireBullets(data)
            if owner:IsPlayer() then
                owner:LagCompensation(false)
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

    local time = self:GetBuff_Mult("Mult_FireAnimTime", anim) or 1

    if anim then self:PlayAnimation(anim, time, true, 0, false) end
end

function SWEP:DoPenetration(tr, penleft, alreadypenned)
    local bullet = {
        Damage = self:GetDamage((tr.HitPos - tr.StartPos):Length()),
        DamageType = self:GetBuff_Override("Override_DamageType") or self.DamageType,
        Weapon = self,
        Penetration = self.Penetration * self:GetBuff_Mult("Mult_Penetration"),
        Attacker = self:GetOwner(),
        Travelled = (tr.HitPos - tr.StartPos):Length()
    }

    ArcCW:DoPenetration(tr, bullet.Damage, bullet, penleft, false, {})
end

function SWEP:GetShootSrc()
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

function SWEP:GetShotgunSpreadOffset(num)
    local rotate = Angle()
    local spreadpt = self:GetBuff_Override("Override_ShotgunSpreadPattern") or self.ShotgunSpreadPattern or {}
    local spreadov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or self.ShotgunSpreadPatternOverrun or { Angle() }

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

    rotate = self:GetBuff_Hook("Hook_ShotgunSpreadOffset", rottoang).ang

    return rotate or Angle()
end

function SWEP:GetDispersion()
    local owner = self:GetOwner()
    local delta = self:GetSightDelta()

    if vrmod and vrmod.IsPlayerInVR(owner) then return 0 end

    local hipdisp = self:GetBuff_Mult("Mult_HipDispersion")
    local sights  = self:GetState() == ArcCW.STATE_SIGHTS

    local hip = delta * hipdisp * self.HipDispersion

    if sights then hip = (delta <= 0) and (self.SightsDispersion * self:GetBuff_Mult("Mult_SightsDispersion")) or (hipdisp * self.HipDispersion) end

    if owner:OnGround() or owner:WaterLevel() > 0 or owner:GetMoveType() == MOVETYPE_NOCLIP then
        local speed    = owner:GetAbsVelocity():Length()
        local maxspeed = owner:GetWalkSpeed() * self.SpeedMult * self:GetBuff_Mult("Mult_SpeedMult")

        if sights then maxspeed = maxspeed * self.SightedSpeedMult * self:GetBuff_Mult("Mult_SightedSpeedMult") end

        speed = math.Clamp(speed / maxspeed, 0, 2)

        hip = hip + (speed * self.MoveDispersion * self:GetBuff_Mult("Mult_MoveDispersion"))
    else
        hip = hip + math.max(self.JumpDispersion * self:GetBuff_Mult("Mult_JumpDispersion"), self.MoveDispersion * self:GetBuff_Mult("Mult_MoveDispersion") * 2)
    end

    if self:InBipod() then hip = hip * ((self.BipodDispersion or 1) * self:GetBuff_Mult("Mult_BipodDispersion") or 0.1) end

    return hip
end

function SWEP:DoShellEject()
    local owner = self:GetOwner()

    if !IsValid(owner) then return end

    local vm = self

    if !owner:IsNPC() then owner:GetViewModel() end

    local att = vm:GetAttachment(self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)

    if !att then return end

    local pos, ang = att.Pos, att.Ang

    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetAngles(ang)
    ed:SetAttachment(self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)
    ed:SetScale(1)
    ed:SetEntity(self)
    ed:SetNormal(ang:Forward())
    ed:SetMagnitude(100)

    local efov = {}
    efov.eff = "arccw_shelleffect"
    efov.fx  = ed

    if self:GetBuff_Hook("Hook_PreDoEffects", efov) == true then return end

    util.Effect("arccw_shelleffect", ed)
end

function SWEP:DoEffects()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local ed = EffectData()
    ed:SetScale(1)
    ed:SetEntity(self)
    ed:SetAttachment(self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1)

    local efov = {}
    efov.eff = "arccw_muzzleeffect"
    efov.fx  = ed

    if self:GetBuff_Hook("Hook_PreDoEffects", efov) == true then return end

    util.Effect("arccw_muzzleeffect", ed)
end

function SWEP:DryFire()

    if self.Animations.fire_dry then
        return self:PlayAnimation("fire_dry", 1, true, 0, true)
    end
    self:MyEmitSound(self.ShootDrySound or "weapons/arccw/dryfire.wav", 75, 100, 1, CHAN_ITEM)
    self:SetNextPrimaryFire(CurTime() + 0.25)
end

function SWEP:DoRecoil()
    local single = game.SinglePlayer()

    if !single and !IsFirstTimePredicted() then return end

    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("DoRecoil") end

    local rec    = self:GetBuff_Hook("Hook_ModifyRecoil") or {}
    local recoil = rec.Recoil
    local side   = rec.RecoilSide
    local visual = rec.VisualRecoilMul

    local rmul = (recoil or 1) * self:GetBuff_Mult("Mult_Recoil")
    local recv = (visual or 1) * self:GetBuff_Mult("Mult_VisualRecoilMult")
    local recs = (side or 1)   * self:GetBuff_Mult("Mult_RecoilSide")

    local irec = math.Rand(-1, 1)
    local recu = math.Rand(0.75, 1.25)

    if self:InBipod() then
        local biprec = self.BipodRecoil
        local bipmul = self:GetBuff_Mult("Mult_BipodRecoil")

        local b = ((biprec or 1) * bipmul or 0.25)

        rmul = rmul * b
        recs = recs * b
        recv = recv / b
    end

    local recoiltbl = self:GetBuff_Override("Override_ShotRecoilTable") or self.ShotRecoilTable

    if recoiltbl and recoiltbl[self:GetBurstCount()] then rmul = rmul * recoiltbl[self:GetBurstCount()] end

    rmul = rec and recoil or rmul
    recv = rec and visual or recv
    recs = rec and side or recs

    local punch = Angle()
    punch = punch + ((self:GetBuff_Override("Override_RecoilDirection") or self.RecoilDirection) * self.Recoil * recv * rmul)
    punch = punch + ((self:GetBuff_Override("Override_RecoilDirectionSide") or self.RecoilDirectionSide) * self.RecoilSide * irec * recv * rmul)
    punch = punch * (self.RecoilPunch or 1) * self:GetBuff_Mult("Mult_RecoilPunch")

    if CLIENT then self:OurViewPunch(punch) end

    if CLIENT or single then
        recv = recv * self.VisualRecoilMult

        self.RecoilAmount     = self.RecoilAmount + (self.Recoil * rmul)
        self.RecoilAmountSide = self.RecoilAmountSide + (self.RecoilSide * irec * recs * rmul)
        self.RecoilPunchBack  = math.Clamp(self.Recoil * recv * math.Rand(2, 3), 0, 2)

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = self.RecoilSide * 0.1 * irec * recv * rmul
        self.RecoilPunchUp   = math.Clamp(self.Recoil * self.RecoilRise * 0.6 * recu * recv * rmul, 0, 0.1)
    end
end

function SWEP:GetBurstLength()
    local clip = self:Clip1()
    if self:HasBottomlessClip() then
        clip = self:Ammo1()
    end
    if clip == 0 then return 1 end

    local len = self:GetCurrentFiremode().Mode

    if !len then return self:GetBurstCount() + 10 end

    local hookedlen = self:GetBuff_Hook("Hook_GetBurstLength", len)

    if len == 1 then return 1 end
    if len >= 2 then return self:GetBurstCount() + 10 end

    if hookedlen != len then return hookedlen end

    if len < 0 then return -len end

    return self:GetBurstCount() + 10
end

function SWEP:FireAnimationEvent(pos, ang, event, options)
    return true
end

function SWEP:GetDamage(range, pellet)
    local ovr = self:GetBuff_Override("Override_Num")
    local add = self:GetBuff_Add("Add_Num")

    local num = self.Num
    local nbr = (ovr or num) + add
    local mul = 1

    mul = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num != nbr) and (num / nbr)) or 1

    if !pellet then mul = mul * nbr end

    local dmgmax = self.Damage * self:GetBuff_Mult("Mult_Damage") * mul
    local dmgmin = self.DamageMin * self:GetBuff_Mult("Mult_DamageMin") * mul
    local delta = 1

    local sran = self.Range
    local bran = self:GetBuff_Mult("Mult_Range")

    delta = (dmgmax < dmgmin and (range / (sran / bran))) or (range / (sran * bran))
    delta = math.Clamp(delta, 0, 1)

    local lerped = Lerp(delta, dmgmax, dmgmin)

    return lerped
end

function SWEP:SecondaryAttack()
    return self.Melee2 and self:Bash(true)
end
