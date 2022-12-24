function SWEP:CanPrimaryAttack()
    local owner = self:GetOwner()

    -- Should we not fire? But first.
    if self:GetBuff_Hook("Hook_ShouldNotFireFirst") then return end

    -- We're holstering
    if IsValid(self:GetHolster_Entity()) then return end
    if self:GetHolster_Time() > 0 then return end

    -- Disabled (currently used only by deploy)
    if self:GetState() == ArcCW.STATE_DISABLE then return end

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

    -- A priority animation is playing (reloading, cycling, firemode etc)
    if self:GetPriorityAnim() then return end

    -- Inoperable, but internally (burst resetting for example)
    if self:GetWeaponOpDelay() > CurTime() then return end

    -- Safety's on, dipshit
    if self:GetCurrentFiremode().Mode == 0 then
        self:ChangeFiremode(false)
        self:SetNextPrimaryFire(CurTime())
        self.Primary.Automatic = false
        return
    end

    -- If we are an NPC, do our own little methods
    if owner:IsNPC() then self:NPC_Shoot() return end

    -- If we are in a UBGL, shoot the UBGL, not the gun
    if self:GetInUBGL() then self:ShootUBGL() return end

    -- Too early, come back later.
    if self:GetNextPrimaryFire() >= CurTime() then return end

    -- Gun is locked from heat.
    if self:GetHeatLocked() then return end

    -- Attempting a bash
    if self:GetState() != ArcCW.STATE_SIGHTS and owner:KeyDown(IN_USE) or self.PrimaryBash then self:Bash() return end

    -- Throwing weapon
    if self.Throwing then self:PreThrow() return end

    -- Too close to a wall
    if self:BarrelHitWall() > 0 then return end

    -- Can't shoot while sprinting
    if self:GetNWState() == ArcCW.STATE_SPRINT and !self:CanShootWhileSprint() then return end

    -- Maximum burst shots
    if (self:GetBurstCount() or 0) >= self:GetBurstLength() then return end

    -- We need to cycle
    if self:GetNeedCycle() then return end

    -- If we have a trigger delay, make sure its progress is done
    if self:GetBuff_Override("Override_TriggerDelay", self.TriggerDelay) and ((!self:GetBuff_Override("Override_TriggerCharge", self.TriggerCharge) and self:GetTriggerDelta() < 1)
            or (self:GetBuff_Override("Override_TriggerCharge", self.TriggerCharge) and self:IsTriggerHeld())) then
        return
    end

    -- Should we not fire?
    if self:GetBuff_Hook("Hook_ShouldNotFire") then return end

    -- We made it
    return true
end

function SWEP:TakePrimaryAmmo(num)
    if self:HasBottomlessClip() or self:Clip1() <= 0 then
        if self:Ammo1() <= 0 then return end
        if self:HasInfiniteAmmo() then return end
        self:GetOwner():RemoveAmmo(num, self:GetPrimaryAmmoType())
    return end
    self:SetClip1(self:Clip1() - num)
end

function SWEP:ApplyRandomSpread(dir, spread)
    local radius = math.Rand(0, 1)
    local theta = math.Rand(0, math.rad(360))
    local bulletang = dir:Angle()
    local forward, right, up = bulletang:Forward(), bulletang:Right(), bulletang:Up()
    local x = radius * math.sin(theta)
    local y = radius * math.cos(theta)

    dir:Set(dir + right * spread * x + up * spread * y)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    self.Primary.Automatic = true

    if !self:CanPrimaryAttack() then return end

    local clip = self:Clip1()
    local aps = self:GetBuff("AmmoPerShot")

    if self:HasBottomlessClip() then
        clip = self:Ammo1()
        if self:HasInfiniteAmmo() then
            clip = math.huge
        end
    end

    if clip < aps then
        self:SetBurstCount(0)
        self:DryFire()

        self.Primary.Automatic = false

        return
    end

    local dir = (owner:EyeAngles() + self:GetFreeAimOffset()):Forward() --owner:GetAimVector()
    local src = self:GetShootSrc()

    if bit.band(util.PointContents(src), CONTENTS_WATER) == CONTENTS_WATER and !(self.CanFireUnderwater or self:GetBuff_Override("Override_CanFireUnderwater")) then
        self:DryFire()
        return
    end

    if self:GetMalfunctionJam() then
        self:DryFire()
        return
    end

    -- Try malfunctioning
    local mal = self:DoMalfunction(false)
    if mal == true then
        local anim = "fire_jammed"
        self:PlayAnimation(anim, 1, true, 0, true)
        return
    end

    self:GetBuff_Hook("Hook_PreFireBullets")

    local desync = GetConVar("arccw_desync"):GetBool()
    local desyncnum = (desync and math.random()) or 0
    math.randomseed(math.Round(util.SharedRandom(self:GetBurstCount(), -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)

    self.Primary.Automatic = true

    local spread = ArcCW.MOAToAcc * self:GetBuff("AccuracyMOA")
    local disp = self:GetDispersion() * ArcCW.MOAToAcc / 10

    --dir:Rotate(Angle(0, ArcCW.StrafeTilt(self), 0))
    --dir = dir + VectorRand() * disp

    self:ApplyRandomSpread(dir, disp)

    if (CLIENT or game.SinglePlayer()) and GetConVar("arccw_dev_shootinfo"):GetInt() >= 3 and disp > 0 then
        local dev_tr = util.TraceLine({
            start = src,
            endpos = src + owner:GetAimVector() * 33000,
            mask = MASK_SHOT,
            filter = {self, self:GetOwner()}
        })
        local dist = (dev_tr.HitPos - src):Length()
        local r = dist / (1 / math.tan(disp)) -- had to google "trig cheat sheet to figure this one out"
        local a = owner:GetAimVector():Angle()
        local r_sqrt = r / math.sqrt(2)
        debugoverlay.Line(dev_tr.HitPos - a:Up() * r, dev_tr.HitPos + a:Up() * r, 5, color_white, true)
        debugoverlay.Line(dev_tr.HitPos - a:Right() * r, dev_tr.HitPos + a:Right() * r, 5, color_white, true)
        debugoverlay.Line(dev_tr.HitPos - a:Right() * r_sqrt - a:Up() * r_sqrt, dev_tr.HitPos + a:Right() * r_sqrt + a:Up() * r_sqrt, 5, color_white, true)
        debugoverlay.Line(dev_tr.HitPos - a:Right() * r_sqrt + a:Up() * r_sqrt, dev_tr.HitPos + a:Right() * r_sqrt - a:Up() * r_sqrt, 5, color_white, true)
        debugoverlay.Text(dev_tr.HitPos, math.Round(self:GetDispersion(), 1) .. "MOA (" .. math.Round(disp, 3) .. "°)", 5)
    end

    local delay = self:GetFiringDelay()

    local curtime = CurTime()
    local curatt = self:GetNextPrimaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
        curatt = curtime
    end

    self:SetNextPrimaryFire(curatt + delay)
    self:SetNextPrimaryFireSlowdown(curatt + delay) -- shadow for ONLY fire time

    local num = self:GetBuff("Num")

    num = num + self:GetBuff_Add("Add_Num")

    local tracer = self:GetBuff_Override("Override_Tracer", self.Tracer)
    local tracernum = self:GetBuff_Override("Override_TracerNum", self.TracerNum)
    local lastout = self:GetBuff_Override("Override_TracerFinalMag", self.TracerFinalMag)
    if lastout >= clip then
        tracernum = 1
        tracer = self:GetBuff_Override("Override_TracerFinal", self.TracerFinal) or self:GetBuff_Override("Override_Tracer", self.Tracer)
    end
    local dmgtable = self.BodyDamageMults
    dmgtable = self:GetBuff_Override("Override_BodyDamageMults") or dmgtable

    -- drive by is cool
    src = ArcCW:GetVehicleFireTrace(self:GetOwner(), src, dir) or src

    local bullet      = {}
    bullet.Attacker   = owner
    bullet.Dir        = dir
    bullet.Src        = src
    bullet.Spread     = Vector(0, 0, 0) --Vector(spread, spread, spread)
    bullet.Damage     = 0
    bullet.Num        = num

    local sglove = math.ceil(num / 3)
    bullet.Force      = self:GetBuff("Force", true) or math.Clamp( ( (50 / sglove) / ( (self:GetBuff("Damage") + self:GetBuff("DamageMin")) / (self:GetBuff("Num") * 2) ) ) * sglove, 1, 3 )
                        -- Overperforming weapons get the jerf, underperforming gets boost
    bullet.Distance   = self:GetBuff("Distance", true) or 33300
    -- Setting AmmoType makes the engine look for the tracer effect on the ammo instead of TracerName!
    --bullet.AmmoType   = self.Primary.Ammo
    bullet.HullSize   = self:GetBuff("HullSize")
    bullet.Tracer     = tracernum or 0
    bullet.TracerName = tracer
    bullet.Weapon     = self
    bullet.Callback = function(att, tr, dmg)
        ArcCW:BulletCallback(att, tr, dmg, self)
    end

    local shootent = self:GetBuff("ShootEntity", true) --self:GetBuff_Override("Override_ShootEntity", self.ShootEntity)
    local shpatt   = self:GetBuff_Override("Override_ShotgunSpreadPattern", self.ShotgunSpreadPattern)
    local shpattov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun", self.ShotgunSpreadPatternOverrun)

    local extraspread = AngleRand() * self:GetDispersion() * ArcCW.MOAToAcc / 10

    local projectiledata = {}

    if shpatt or shpattov or shootent then
        if shootent then
            projectiledata.ent = shootent
            projectiledata.vel = self:GetBuff("MuzzleVelocity")
        end

        bullet = self:GetBuff_Hook("Hook_FireBullets", bullet)

        if !bullet then return end

        local doent = shootent and num or bullet.Num
        local minnum = shootent and 1 or 0

        if doent > minnum then
            for n = 1, bullet.Num do
                bullet.Num = 1

                local dispers = self:GetBuff_Override("Override_ShotgunSpreadDispersion", self.ShotgunSpreadDispersion)
                local offset  = self:GetShotgunSpreadOffset(n)
                local calcoff = dispers and (offset * self:GetDispersion() * ArcCW.MOAToAcc / 10) or offset

                local ang = owner:EyeAngles() + self:GetFreeAimOffset()
                local ang2 = Angle(ang)
                ang2:RotateAroundAxis(ang:Right(), -1 * calcoff.p)
                ang2:RotateAroundAxis(ang:Up(), calcoff.y)
                ang2:RotateAroundAxis(ang:Forward(), calcoff.r)

                if !self:GetBuff_Override("Override_NoRandSpread", self.NoRandSpread) then -- Needs testing
                    ang2 = ang2 + AngleRand() * spread / 5
                end

                if shootent then
                    projectiledata.ang = ang2

                    self:DoPrimaryFire(true, projectiledata)
                else
                    bullet.Dir = ang2:Forward()

                    self:DoPrimaryFire(false, bullet)
                end
            end
        elseif shootent then
            local ang = owner:EyeAngles() + self:GetFreeAimOffset()

            if !self:GetBuff_Override("Override_NoRandSpread", self.NoRandSpread) then
               -- ang = (dir + VectorRand() * spread / 5):Angle()

                local newdir = Vector(dir)
                self:ApplyRandomSpread(newdir, spread / 5)
                ang = newdir:Angle()
            end

            projectiledata.ang = ang

            self:DoPrimaryFire(true, projectiledata)
        end
    else
        if !bullet then return end

        for n = 1, bullet.Num do
            bullet.Num = 1
            local dirry = Vector(dir.x, dir.y, dir.z)
            math.randomseed(math.Round(util.SharedRandom(n, -1337, 1337, !game.SinglePlayer() and self:GetOwner():GetCurrentCommand():CommandNumber() or CurTime()) * (self:EntIndex() % 30241)) + desyncnum)
            if !self:GetBuff_Override("Override_NoRandSpread", self.NoRandSpread) then
                self:ApplyRandomSpread(dirry, spread)
                bullet.Dir = dirry
            end
            bullet = self:GetBuff_Hook("Hook_FireBullets", bullet) or bullet

            self:DoPrimaryFire(false, bullet)
        end
    end

    self:DoRecoil()

    self:SetNthShot(self:GetNthShot() + 1)

    owner:DoAnimationEvent(self:GetBuff_Override("Override_AnimShoot") or self.AnimShoot)

    local shouldsupp = SERVER and !game.SinglePlayer()

    if shouldsupp then SuppressHostEvents(owner) end

    self:DoEffects()

    self:SetBurstCount(self:GetBurstCount() + 1)

    self:TakePrimaryAmmo(aps)

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
        self:SetWeaponOpDelay(CurTime() + (firedelay * self:GetBuff_Mult("Mult_CycleTime")))
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    self:ApplyAttachmentShootDamage()

    self:AddHeat(self:GetBuff("HeatGain"))

    mal = self:DoMalfunction(true)
    if mal == true then
        local anim = "fire_jammed"
        self:PlayAnimation(anim, 1, true, 0, true)
    end

    if self:GetCurrentFiremode().Mode == 1 then
        self.LastTriggerTime = -1 -- Cannot fire again until trigger released
        self.LastTriggerDuration = 0
    end

    self:GetBuff_Hook("Hook_PostFireBullets")

    if shouldsupp then SuppressHostEvents(nil) end
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
        distancesound = self.DistantShootSoundSilenced
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
        vel = self:GetBuff("Range") * 3.5

        if self:GetBuff("DamageMin") > self:GetBuff("Damage") then
            vel = vel * 2
        end
        vel = math.Clamp(vel, 200, 1000)
    end

    vel = vel / ArcCW.HUToM

    vel = vel * self:GetBuff_Mult("Mult_PhysBulletMuzzleVelocity")

    vel = vel * GetConVar("arccw_bullet_velocity"):GetFloat()

    return vel
end

function SWEP:DoPrimaryFire(isent, data)
    local clip = self:Clip1()
    if self:HasBottomlessClip() then
        if !self:GetOwner():IsPlayer() then
            clip = math.huge
        else
            clip = self:Ammo1()
        end
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
            local tracernum = data.Tracer or 1
            local phystracer = self:GetBuff_Override("Override_PhysTracerProfile", self.PhysTracerProfile)
            local lastout = self:GetBuff_Override("Override_TracerFinalMag", self.TracerFinalMag)
            if lastout >= self:Clip1() then
                phystracer = self:GetBuff_Override("Override_PhysTracerProfileFinal", self.PhysTracerProfileFinal) or phystracer
            elseif tracernum == 0 or clip % tracernum != 0 then
                phystracer = 7
            end

            local vel = self:GetMuzzleVelocity()

            vel = vel * data.Dir:GetNormalized()

            ArcCW:ShootPhysBullet(self, data.Src, vel, phystracer or 0)
        else
            owner:FireBullets(data, true)
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
        Damage = self:GetDamage((tr.HitPos - tr.StartPos):Length() * ArcCW.HUToM),
        DamageType = self:GetBuff_Override("Override_DamageType") or self.DamageType,
        Weapon = self,
        Penetration = self:GetBuff("Penetration"),
        Attacker = self:GetOwner(),
        Travelled = (tr.HitPos - tr.StartPos):Length()
    }

    ArcCW:DoPenetration(tr, bullet.Damage, bullet, penleft, false, alreadypenned)
end

function SWEP:GetFiringDelay()
    local delay = (self.Delay * (1 / self:GetBuff_Mult("Mult_RPM")))
    delay = self:GetBuff_Hook("Hook_ModifyRPM", delay) or delay

    return delay
end

function SWEP:GetShootSrc()
    local owner = self:GetOwner()

    if !IsValid(owner) then return self:GetPos() end
    if owner:IsNPC() then return owner:GetShootPos() end

    local dir    = owner:EyeAngles()
    local offset = Vector(0, 0, 0)

    if self:GetOwner():Crouching() then
        offset = self:GetBuff_Override("Override_BarrelOffsetCrouch") or self.BarrelOffsetCrouch or offset
    end

    if self:GetNWState() == ArcCW.STATE_SIGHTS then
        offset = LerpVector(self:GetNWSightDelta(), offset, self:GetBuff_Override("Override_BarrelOffsetSighted", self.BarrelOffsetSighted) or offset)
    else
        offset = LerpVector(1 - self:GetNWSightDelta(), offset, self:GetBuff_Override("Override_BarrelOffsetHip", self.BarrelOffsetHip) or offset)
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

    if vrmod and vrmod.IsPlayerInVR(owner) then return 0 end

    local hipdisp = self:GetBuff("HipDispersion")
    local sights  = self:GetState() == ArcCW.STATE_SIGHTS

    local hip = hipdisp

    local sightdisp = self:GetBuff("SightsDispersion")
    if sights then hip = Lerp(self:GetNWSightDelta(), sightdisp, hipdisp) end

    local speed = owner:GetAbsVelocity():Length()
    local maxspeed = owner:GetWalkSpeed() * self:GetBuff("SpeedMult")
    if sights then maxspeed = maxspeed * self:GetBuff("SightedSpeedMult") end
    speed = math.Clamp(speed / maxspeed, 0, 2)

    if owner:OnGround() or owner:WaterLevel() > 0 and owner:GetMoveType() != MOVETYPE_NOCLIP then
        hip = hip + speed * self:GetBuff("MoveDispersion")
    elseif owner:GetMoveType() != MOVETYPE_NOCLIP then
        hip = hip + math.max(speed * self:GetBuff("MoveDispersion"), self:GetBuff("JumpDispersion"))
    end

    if self:InBipod() then hip = hip * (self.BipodDispersion * self:GetBuff_Mult("Mult_BipodDispersion")) end

    if GetConVar("arccw_mult_crouchdisp"):GetFloat() != 1 and owner:OnGround() and owner:Crouching() then
        hip = hip * GetConVar("arccw_mult_crouchdisp"):GetFloat()
    end

    if GetConVar("arccw_freeaim"):GetInt() == 1 and !sights then
        hip = hip ^ 0.9
    end

    --local t = hook.Run("ArcCW_ModDispersion", self, {dispersion = hip})
    --hip = t and t.dispersion or hip
    hip = self:GetBuff_Hook("Hook_ModDispersion", hip) or hip

    return hip
end

function SWEP:DoShellEject(atti)
    local eff = self:GetBuff_Override("Override_ShellEffect") or self.ShellEffect or "arccw_shelleffect"

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

function SWEP:DoEffects(att)
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local ed = EffectData()
    ed:SetStart(self:GetShootSrc())
    ed:SetOrigin(self:GetShootSrc())
    ed:SetScale(1)
    ed:SetEntity(self)
    ed:SetAttachment(att or self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1)

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

    -- math.randomseed(self:GetBurstLength() + (self.Recoil * 409) + (self.RecoilSide * 519))

    local rec = {
        Recoil = 1,
        RecoilSide = 1,
        VisualRecoilMul = 1
    }
    rec = self:GetBuff_Hook("Hook_ModifyRecoil", rec) or rec

    local recoil = rec.Recoil
    local side   = rec.RecoilSide
    local visual = rec.VisualRecoilMul

    local rmul = (recoil or 1) * self:GetBuff_Mult("Mult_Recoil")
    local recv = (visual or 1) * self:GetBuff_Mult("Mult_VisualRecoilMult")
    local recs = (side or 1)   * self:GetBuff_Mult("Mult_RecoilSide")

    -- local rrange = math.Rand(-recs, recs) * self.RecoilSide

    -- local irec = math.Rand(rrange - 1, rrange + 1)
    -- local recu = math.Rand(0.5, 1)

    local irec = math.Rand(-1, 1)
    local recu = 1

    if self:InBipod() then
        local b = self.BipodRecoil * self:GetBuff_Mult("Mult_BipodRecoil")

        rmul = rmul * b
        recs = recs * b
        recv = recv * b
    end

    local recoiltbl = self:GetBuff_Override("Override_ShotRecoilTable") or self.ShotRecoilTable

    if recoiltbl and recoiltbl[self:GetBurstCount()] then rmul = rmul * recoiltbl[self:GetBurstCount()] end

    if GetConVar("arccw_mult_crouchrecoil"):GetFloat() != 1 and self:GetOwner():OnGround() and self:GetOwner():Crouching() then
        rmul = rmul * GetConVar("arccw_mult_crouchrecoil"):GetFloat()
    end

    local punch = Angle()

    punch = punch + (self:GetBuff_Override("Override_RecoilDirection", self.RecoilDirection) * math.max(self.Recoil, 0.25) * recu * recv * rmul)
    punch = punch + (self:GetBuff_Override("Override_RecoilDirectionSide", self.RecoilDirectionSide) * math.max(self.RecoilSide, 0.25) * irec * recv * rmul)
    punch = punch + Angle(0, 0, 90) * math.Rand(-1, 1) * math.Clamp(self.Recoil, 0.25, 1) * recv * rmul * 0.01
    punch = punch * (self.RecoilPunch or 1) * self:GetBuff_Mult("Mult_RecoilPunch")

    self:SetFreeAimAngle(self:GetFreeAimAngle() - punch)

    if CLIENT then self:OurViewPunch(punch) end

    if CLIENT or single then
        recv = recv * self.VisualRecoilMult

        self.RecoilAmount     = self.RecoilAmount + (self.Recoil * rmul * recu)
        self.RecoilAmountSide = self.RecoilAmountSide + (self.RecoilSide * irec * recs * rmul)
        self.RecoilPunchBack  = math.Clamp(self.RecoilAmount * recv * 5, 1, 5)

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = self.RecoilSide * 0.1 * irec * recv * rmul
        self.RecoilPunchUp   = self.RecoilRise * 0.1 * recu
    end

    -- math.randomseed(CurTime() + (self:EntIndex() * 3))
end

function SWEP:GetBurstLength()
    local clip = self:Clip1()
    if self:HasBottomlessClip() then
        clip = self:Ammo1()
        if self:HasInfiniteAmmo() then
            clip = math.huge
        end
    end
    --if clip == 0 then return 1 end

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

function SWEP:IsRampupWeapon()
    local ovr = self:GetBuff_Override("Override_IsRampupWeapon")
    if ovr != nil then return ovr end
    return self:GetBuff("Damage") < self:GetBuff("DamageMin")
end

function SWEP:GetMinMaxRange()
    local decrease = !self:IsRampupWeapon()

    local min = self:GetBuff_Override("Override_RangeMin", self.RangeMin or 0)
    local max = self:GetBuff_Override("Override_Range", self.Range)
    local min_add = self:GetBuff_Add("Add_RangeMin")
    local max_add = self:GetBuff_Add("Add_Range")
    local min_mult = self:GetBuff_Mult("Mult_RangeMin")
    local max_mult = self:GetBuff_Mult("Mult_Range")

    if decrease then
        -- MinRange is also affected by Mult_Range, this is intentional
        local total_min = math.max((min + min_add) * min_mult * max_mult, 0)
        return total_min, math.max((max + max_add) * max_mult, total_min)
    else
        -- For "rampup weapons" (dmgmin > dmg), range buffs *decrease* range, as it ramps up damage quicker
        -- After all, +Range is supposed to be a positive buff no matter the kind of gun
        local total_min = math.max((min - min_add) / min_mult / max_mult, 0)
        return total_min, math.max((max - max_add) / max_mult, total_min)
    end
end

function SWEP:GetRangeFraction(range)
    local min, max = self:GetMinMaxRange()
    if range < min then
        return 0
    else
        return math.Clamp((range - min) / (max - min), 0, 1)
    end
end

function SWEP:GetDamage(range, pellet)
    local ovr = self:GetBuff_Override("Override_Num")
    local add = self:GetBuff_Add("Add_Num")
    local mul = self:GetBuff_Mult("Mult_Num")

    local num = self.Num
    local nbr = (ovr or num) * mul + add
    local factor = 1

    -- Total damage should be unchanged regardless of whether the weapon originally fired 1 pellet or > 1
    -- If pellet is set, we return per-pellet damage instead of total damage
    if pellet and num == 1 then
        factor = 1 / ((ovr or 1) * mul + add)
    elseif num != nbr then
        factor = num / nbr
    end

    --factor = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num != nbr) and (num / nbr)) or 1

    if !pellet then factor = factor * nbr end

    local dmgmax = self:GetBuff("Damage") * factor
    local dmgmin = self:GetBuff("DamageMin") * factor
    local delta = self:GetRangeFraction(range)

    local lerped = Lerp(delta, dmgmax, dmgmin)

    return lerped
end

function SWEP:SecondaryAttack()
    return self.Melee2 and self:Bash(true)
end

function SWEP:CanShootWhileSprint()
    return GetConVar("arccw_mult_shootwhilesprinting"):GetBool() or self:GetBuff_Override("Override_ShootWhileSprint", self.ShootWhileSprint)
end
