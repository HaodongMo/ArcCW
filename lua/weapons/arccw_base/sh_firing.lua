function SWEP:PrimaryAttack()
    if self:GetOwner():IsNPC() then
        self:NPC_Shoot()
        return
    end

    if self:GetNextPrimaryFire() >= CurTime() then return end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return end

    if self:GetState() != ArcCW.STATE_SIGHTS and self:GetOwner():KeyDown(IN_USE) or self.PrimaryBash then
        self:Bash()
        return
    end

    if self.Throwing then
        self:PreThrow()
        return
    end

    if self:BarrelHitWall() > 0 then return end
    if self:GetState() == ArcCW.STATE_SPRINT and !(self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return end

    if self:GetNWBool("ubgl") then
        self:ShootUBGL()
        return
    end

    if self:Clip1() <= 0 then self.BurstCount = 0 self:DryFire() return end
    if self:GetNWBool("cycle", false) then return end
    if self.BurstCount >= self:GetBurstLength() then return end
    if self:GetCurrentFiremode().Mode == 0 then
        self:ChangeFiremode(false)
        self.Primary.Automatic = false
        return
    end

    if self:GetBuff_Hook("Hook_ShouldNotFire") then return end

    math.randomseed(self:GetOwner():GetCurrentCommand():CommandNumber() + (self:EntIndex() % 30241))

    self.Primary.Automatic = self:ShouldBeAutomatic()

    local ss = self.ShootSound

    if self:GetBuff_Override("Silencer") then
        ss = self.ShootSoundSilenced
    end

    if self.BurstCount == 0 and self.FirstShootSound then
        ss = self.FirstShootSound

        if self:GetBuff_Override("Silencer") then
            if self.FirstShootSoundSilenced then
                ss = self.FirstShootSoundSilenced
            else
                ss = self.ShootSoundSilenced
            end
        end
    end

    if self:Clip1() == 1 and self.LastShootSound then
        ss = self.LastShootSound

        if self:GetBuff_Override("Silencer") then
            if self.LastShootSoundSilenced then
                ss = self.LastShootSoundSilenced
            else
                ss = self.ShootSoundSilenced
            end
        end
    end

    ss = self:GetBuff_Hook("Hook_GetShootSound", ss)

    local dss = self.DistantShootSound

    if self:GetBuff_Override("Silencer") then
        dss = nil
    end

    dss = self:GetBuff_Hook("Hook_GetDistantShootSound", dss)

    local dir = self:GetOwner():EyeAngles()

    local src = self:GetShootSrc()

    if bit.band( util.PointContents( src ), CONTENTS_WATER ) == CONTENTS_WATER and !(self.CanFireUnderwater or self:GetBuff_Override("Override_CanFireUnderwater")) then
        self:DryFire()
        return
    end

    local spread = ArcCW.MOAToAcc * self.AccuracyMOA * self:GetBuff_Mult("Mult_AccuracyMOA")

    dir = dir + (AngleRand() * self:GetDispersion() / 360 / 60)

    local delay = (self.Delay * (1 / self:GetBuff_Mult("Mult_RPM")))

    delay = self:GetBuff_Hook("Hook_ModifyRPM", delay) or delay

    self:SetNextPrimaryFire(CurTime() + delay)

    -- if IsFirstTimePredicted() then

        local num = self:GetBuff_Override("Override_Num")

        if !num then
            num = self.Num
        end

        num = num + self:GetBuff_Add("Add_Num")

        local btabl = {
            Attacker = self:GetOwner(),
            Damage = 0,
            Force = 5 / num,
            Distance = 33000,
            Num = num,
            Tracer = self:GetBuff_Override("Override_TracerNum") or self.TracerNum,
            TracerName = self:GetBuff_Override("Override_Tracer") or self.Tracer,
            AmmoType = self.Primary.Ammo,
            Dir = dir:Forward(),
            Src = src,
            Spread = Vector(spread, spread, spread),
            Callback = function(att, tr, dmg)
                local dist = (tr.HitPos - src):Length() * ArcCW.HUToM

                local pen = self.Penetration * self:GetBuff_Mult("Mult_Penetration")

                -- local frags = math.random(1, self.Frangibility)

                -- for i = 1, frags do
                --     self:DoPenetration(tr, (self.Penetration / frags) - 0.5, tr.Entity)
                -- end

                local ret = self:GetBuff_Hook("Hook_BulletHit", {
                    range = dist,
                    damage = self:GetDamage(dist, true),
                    dmgtype = self:GetBuff_Override("Override_DamageType") or self.DamageType,
                    penleft = pen,
                    att = att,
                    tr = tr,
                    dmg = dmg
                })

                if !ret then return end

                dmg:SetDamageType(ret.dmgtype)
                dmg:SetDamage(ret.damage)

                if dmg:GetDamageType() == DMG_BURN and ret.range <= self.Range then
                    if num == 1 then
                        dmg:SetDamageType(DMG_BULLET)
                    else
                        dmg:SetDamageType(DMG_BUCKSHOT)
                    end
                    local fx = EffectData()
                    fx:SetOrigin(tr.HitPos)
                    util.Effect("arccw_incendiaryround", fx)

                    util.Decal("FadingScorch", tr.StartPos, tr.HitPos - (tr.HitNormal * 16), self:GetOwner())

                    if SERVER then
                        if vFireInstalled then
                            CreateVFire(tr.Entity, tr.HitPos, tr.HitNormal, ret.damage * 0.02)
                        else
                            tr.Entity:Ignite(1, 0)
                        end
                    end
                end

                self:DoPenetration(tr, ret.penleft, {tr.Entity})
            end
        }

        local se = self:GetBuff_Override("Override_ShootEntity") or self.ShootEntity

        local sp = self:GetBuff_Override("Override_ShotgunSpreadPattern") or self.ShotgunSpreadPattern
        local spo = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or self.ShotgunSpreadPatternOverrun

        if sp or spo then
            btabl = self:GetBuff_Hook("Hook_FireBullets", btabl)

            if !btabl then return end
            -- if btabl.Num == 0 then return end

            local spd = AngleRand() * self:GetDispersion() / 360 / 60

            if btabl.Num > 0 then
                for n = 1, btabl.Num do
                    btabl.Num = 1
                    local ang
                    if self:GetBuff_Override("Override_ShotgunSpreadDispersion") or self.ShotgunSpreadDispersion then
                        ang = self:GetOwner():EyeAngles() + (self:GetShotgunSpreadOffset(n) * self:GetDispersion() / 60)
                    else
                        ang = self:GetOwner():EyeAngles() + self:GetShotgunSpreadOffset(n) + spd
                    end

                    ang = ang + AngleRand() * spread / 10

                    btabl.Dir = ang:Forward()

                    self:GetOwner():LagCompensation(true)

                    self:GetOwner():FireBullets(btabl)

                    self:GetOwner():LagCompensation(false)
                end
            end
        elseif se then
            if num > 1 then
                local spd = AngleRand() * self:GetDispersion() / 360 / 60

                for n = 1, btabl.Num do
                    btabl.Num = 1
                    local ang
                    if self:GetBuff_Hook("Override_ShotgunSpreadDispersion") or self.ShotgunSpreadDispersion then
                        ang = self:GetOwner():EyeAngles() + (self:GetShotgunSpreadOffset(n) * self:GetDispersion() / 360 / 60)
                    else
                        ang = self:GetOwner():EyeAngles() + self:GetShotgunSpreadOffset(n) + spd
                    end

                    ang = ang + AngleRand() * spread / 10

                    self:FireRocket(se, self.MuzzleVelocity * ArcCW.HUToM * self:GetBuff_Mult("Mult_MuzzleVelocity"), ang)
                end
            elseif num > 0 then
                local spd = AngleRand() * self:GetDispersion() / 360 / 60
                local ang = self:GetOwner():EyeAngles() + (AngleRand() * spread / 10)

                self:FireRocket(se, self.MuzzleVelocity * ArcCW.HUToM * self:GetBuff_Mult("Mult_MuzzleVelocity"), ang + spd)
            end
        else
            btabl = self:GetBuff_Hook("Hook_FireBullets", btabl)

            if !btabl then return end
            if btabl.Num > 0 then

                self:GetOwner():LagCompensation(true)

                self:GetOwner():FireBullets(btabl)

                self:GetOwner():LagCompensation(false)

            end
        end

        self:DoRecoil()

        self:GetOwner():DoAnimationEvent(self:GetBuff_Override("Override_AnimShoot") or self.AnimShoot)

        local svol = self.ShootVol * self:GetBuff_Mult("Mult_ShootVol")
        local spitch = self.ShootPitch * math.Rand(0.95, 1.05) * self:GetBuff_Mult("Mult_ShootPitch")

        svol = math.Clamp(svol, 51, 149)
        spitch = math.Clamp(spitch, 51, 149)

        if SERVER and !game.SinglePlayer() then
            SuppressHostEvents(self:GetOwner())
        end

        self:DoEffects()

        if dss then
            -- sound.Play(self.DistantShootSound, self:GetPos(), 149, self.ShootPitch * math.Rand(0.95, 1.05), 1)
            self:EmitSound(dss, 149, spitch, 0.5, CHAN_WEAPON + 1)
        end

        if ss then
            self:EmitSound(ss, svol, spitch, 1, CHAN_WEAPON)
        end

        if IsFirstTimePredicted() then
            self.BurstCount = self.BurstCount + 1
        end

        self:TakePrimaryAmmo(1)

        local ret = "fire"

        if self:Clip1() == 0 and self.Animations.fire_iron_empty and self:GetState() == ArcCW.STATE_SIGHTS then
            ret = "fire_iron_empty"
        elseif self:Clip1() == 0 and self.Animations.fire_empty and self:GetState() != ArcCW.STATE_SIGHTS then
            ret = "fire_empty"
        else
            if self:GetState() == ArcCW.STATE_SIGHTS and self.Animations.fire_iron then
                ret = "fire_iron"
            else
                ret = "fire"
            end
        end

        if self.ProceduralIronFire and self:GetState() == ArcCW.STATE_SIGHTS then
            ret = nil
        elseif self.ProceduralRegularFire and self:GetState() != ArcCW.STATE_SIGHTS then
            ret = nil
        end


        ret = ret or self:GetBuff_Hook("Hook_SelectFireAnimation", ret)

        if ret then
            self:PlayAnimation(ret, 1, true, 0, false)
        end

        if self.ManualAction or self:GetBuff_Override("Override_ManualAction") then
            if !(self.NoLastCycle and self:Clip1() == 0) then
                self:SetNWBool("cycle", true)
            end
        end

        if self:GetCurrentFiremode().Mode < 0 and self.BurstCount == -self:GetCurrentFiremode().Mode then
            local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

            self:SetNextPrimaryFire(CurTime() + postburst)
        end

        self:GetBuff_Hook("Hook_PostFireBullets")

        if SERVER and !game.SinglePlayer() then
            SuppressHostEvents(nil)
        end
    -- end

    math.randomseed(CurTime() + (self:EntIndex() % 31259))
end

function SWEP:DoPenetration(tr, penleft, alreadypenned)
    if CLIENT then return end
    alreadypenned = alreadypenned or {}
    if penleft <= 0 then return end

    if tr.HitSky then return end

    local penmult = ArcCW.PenTable[tr.MatType] or 1
    local pentracelen = 2

    local curr_ent = tr.Entity

    if !tr.HitWorld then
        penmult = penmult * 1.5
    end

    if tr.Entity.mmRHAe then
        penmult = tr.Entity.mmRHAe
    end

    penmult = penmult * math.random(0.9, 1.1) * math.random(0.9, 1.1)

    local dir = (tr.HitPos - tr.StartPos):GetNormalized()
    local endpos = tr.HitPos

    local ptr = util.TraceLine({
        start = endpos,
        endpos = endpos + (dir * pentracelen),
        mask = MASK_SHOT
    })

    while penleft > 0 and (!ptr.StartSolid or ptr.AllSolid) and ptr.Fraction < 1 and ptr.Entity == curr_ent do
        penleft = penleft - (pentracelen * penmult)

        ptr = util.TraceLine({
            start = endpos,
            endpos = endpos + (dir * pentracelen),
            mask = MASK_SHOT
        })

        if ptr.Entity != curr_ent then
            curr_ent = ptr.Entity

            local dist = (ptr.HitPos - tr.StartPos):Length() * ArcCW.HUToM
            local pdelta = penleft / (self.Penetration * self:GetBuff_Mult("Mult_Penetration"))

            local dmg = DamageInfo()

            dmg:SetDamageType(self:GetBuff_Override("Override_DamageType") or self.DamageType)
            dmg:SetDamage(self:GetDamage(dist) * pdelta, true)
            dmg:SetDamagePosition(ptr.HitPos)

            if IsValid(ptr.Entity) and !table.HasValue(alreadypenned, ptr.Entity) then
                ptr.Entity:TakeDamageInfo(dmg)
            end

            penmult = ArcCW.PenTable[ptr.MatType] or 1

            if !ptr.HitWorld then
                penmult = penmult * 1.5
            end

            if ptr.Entity.mmRHAe then
                penmult = ptr.Entity.mmRHAe
            end

            penmult = penmult * math.random(0.9, 1.1) * math.random(0.9, 1.1)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(0, 0, 255), true)
        end

        if GetConVar("developer"):GetBool() then
            local pdeltap = penleft / self.Penetration

            local c = Lerp(pdeltap, 0, 255)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(255,c, c), true)
        end

        endpos = endpos + (dir * pentracelen)

        dir = dir + (VectorRand() * 0.025 * penmult)
    end

    if penleft > 0 then
        -- print("bullet penetrated with " .. penleft .. "mm pen left")
        --print(vel)
        if (dir:Length() == 0) then return end

        local pdelta = penleft / (self.Penetration * self:GetBuff_Mult("Mult_Penetration"))

        self:GetOwner():FireBullets( {
            Attacker = self:GetOwner(),
            Damage = 0,
            Force = 0,
            Distance = 33000,
            Num = 1,
            Tracer = 0,
            AmmoType = self.Primary.Ammo,
            Dir = dir,
            Src = endpos,
            Spread = Vector(spread, spread, spread),
            Callback = function(att, btr, dmg)
                local dist = (btr.HitPos - endpos):Length() * ArcCW.HUToM

                if table.HasValue(alreadypenned, ptr.Entity) then
                    dmg:SetDamage(0)
                else
                    dmg:SetDamageType(self:GetBuff_Override("Override_DamageType") or self.DamageType)
                    dmg:SetDamage(self:GetDamage(dist) * pdelta, true)
                end

                self:DoPenetration(btr, penleft)
            end
        } )

        self:GetOwner():FireBullets({
            Damage = 0,
            Src = endpos,
            Dir = -dir,
            Distance = 8,
            Tracer = 0,
            Force = 0
        }, true)

        -- debugoverlay.Line(endpos, endpos + (dir * 3), 10, Color(0, 255, 0), true)
    --else
        --print("bullet stopped")
    end
end

function SWEP:GetShootSrc()
    if self:GetOwner():IsNPC() then return self:GetOwner():GetShootPos() end

    local dir = self:GetOwner():EyeAngles()
    local offset = self:GetBuff_Override("Override_BarrelOffsetHip") or self.BarrelOffsetHip

    if self:GetState() == ArcCW.STATE_SIGHTS then
        offset = self:GetBuff_Override("Override_BarrelOffsetSighted") or self.BarrelOffsetSighted
    end

    local src = self:GetOwner():EyePos()

    src = src + dir:Right() * offset[1]
    src = src + dir:Forward() * offset[2]
    src = src + dir:Up() * offset[3]

    return src
end

function SWEP:GetShotgunSpreadOffset(n)
    local r = Angle(0, 0, 0)
    local sp = self:GetBuff_Override("Override_ShotgunSpreadPattern") or self.ShotgunSpreadPattern or {}
    local spo = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or self.ShotgunSpreadPatternOverrun or {Angle(0, 0, 0)}

    if istable(sp) and istable(spo) then
        sp["BaseClass"] = nil
        spo["BaseClass"] = nil

        if n > #sp then
            if spo then
                n = n - #sp
                n = math.fmod(n, #spo) + 1
                r = spo[n]
            else
                n = math.fmod(n, #sp) + 1
                r = sp[n]
            end
        else
            r = sp[n]
        end
    end

    r = self:GetBuff_Hook("Hook_ShotgunSpreadOffset", {n = n, ang = r}).ang

    return r or Angle(0, 0, 0)
end

function SWEP:GetDispersion()
    local delta = self:GetSightDelta()

    -- This number now only applies when partially scoping in
    -- If you unscope partway through, GetSightDelta treats your progress as zero,
    -- effectively giving you a window to "quickscope". None of that!
    local hip = delta * self:GetBuff_Mult("Mult_HipDispersion") * self.HipDispersion

    if self:GetState() == ArcCW.STATE_SIGHTS and delta <= 0 then
        hip = self.SightsDispersion * self:GetBuff_Mult("Mult_SightsDispersion")
    elseif self:GetState() != ArcCW.STATE_SIGHTS then -- Ignore delta when zooming out
        hip = self:GetBuff_Mult("Mult_HipDispersion") * self.HipDispersion
    end

    -- Move Dispersion
    local spd = self:GetOwner():GetAbsVelocity():Length()
    local maxspeed = self:GetOwner():GetWalkSpeed() * self.SpeedMult * self:GetBuff_Mult("Mult_SpeedMult")
    if self:GetState() == ArcCW.STATE_SIGHTS then
        maxspeed = maxspeed * self.SightedSpeedMult * self:GetBuff_Mult("Mult_SightedSpeedMult")
    end
    spd = math.Clamp(spd / maxspeed, 0, 2)
    hip = hip + (spd * self.MoveDispersion * self:GetBuff_Mult("Mult_MoveDispersion"))

    if !self:GetOwner():OnGround() then
        hip = hip + self.JumpDispersion * self:GetBuff_Mult("Mult_JumpDispersion")
    end

    -- Bipod
    if self:InBipod() then
        hip = hip * (self:GetBuff_Mult("Mult_BipodDispersion") or 0.1)
    end

    return hip
end

function SWEP:DoShellEject()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    if !IsValid(self:GetOwner()) then return end

    local vm = self

    if !self:GetOwner():IsNPC() then
        self:GetOwner():GetViewModel()
    end

    local posang = vm:GetAttachment(self.CaseEffectAttachment)

    if !posang then return end

    local pos = posang.Pos
    local ang = posang.Ang

    local fx = EffectData()
    fx:SetOrigin(pos)
    fx:SetAngles(ang)
    fx:SetAttachment(self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)
    fx:SetScale(1)
    fx:SetEntity(self)
    fx:SetNormal(ang:Forward())
    fx:SetMagnitude(100)

    util.Effect("arccw_shelleffect", fx)
end

function SWEP:DoEffects()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end

    local fx = EffectData()
    fx:SetScale(1)
    fx:SetAttachment(self:GetBuff_Override("Override_MuzzleEffectAttachment") or self.MuzzleEffectAttachment or 1)
    fx:SetEntity(self)

    if self:GetBuff_Hook("Hook_PreDoEffects", {fx = fx}) == false then return end

    util.Effect("arccw_muzzleeffect", fx)
end

function SWEP:DryFire()
    if self.Animations.fire_dry then
        self:PlayAnimation("fire_dry", 1, true, 0, true)
        return
    end

    self.Primary.Automatic = false

    self:EmitSound("weapons/arccw/dryfire.wav", 75, 100, 1, CHAN_ITEM)
    self:SetNextPrimaryFire(CurTime() + 0.25)
end

function SWEP:DoRecoil()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end
    if game.SinglePlayer() and self:GetOwner():IsValid() and SERVER then
        self:CallOnClient("DoRecoil")
    end

    -- if !game.SinglePlayer() and SERVER then return end

    local r = math.Rand(-1, 1)
    local ru = math.Rand(0.75, 1.25)

    local m = 1 * self:GetBuff_Mult("Mult_Recoil")
    local rs = 1 * self:GetBuff_Mult("Mult_RecoilSide")
    local vsm = 1 * self:GetBuff_Mult("Mult_VisualRecoilMult")

    if self:InBipod() then
        m = m * (self:GetBuff_Mult("Mult_BipodRecoil") or 0.25)
        rs = rs * (self:GetBuff_Mult("Mult_BipodRecoil") or 0.25)
    end

    local vpa = Angle(0, 0, 0)

    vpa = vpa + ((self:GetBuff_Override("Override_RecoilDirection") or self.RecoilDirection) * self.Recoil * m * vsm)

    vpa = vpa + ((self:GetBuff_Override("Override_RecoilDirectionSide") or self.RecoilDirectionSide) * r * self.RecoilSide * m * vsm)

    vpa = vpa * (self.RecoilPunch or 1) * self:GetBuff_Mult("Mult_RecoilPunch")

    self:GetOwner():ViewPunch(vpa)
    -- self:SetNWFloat("recoil", self.Recoil * m)
    -- self:SetNWFloat("recoilside", r * self.RecoilSide * m)

    local ang = self:GetOwner():GetViewPunchAngles()

    ang[1] = math.Clamp(ang[1], -180, 180)
    ang[2] = math.Clamp(ang[2], -180, 180)
    ang[3] = math.Clamp(ang[3], -180, 180)

    self:GetOwner():SetViewPunchAngles(ang)

    if CLIENT or game.SinglePlayer() then
        vsm = vsm * self.VisualRecoilMult

        self.RecoilAmount = self.RecoilAmount + (self.Recoil * m)
        self.RecoilAmountSide = self.RecoilAmountSide + (r * self.RecoilSide * m * rs)

        self.RecoilPunchBack = self.Recoil * 2.5 * m

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = r * self.RecoilSide * m * 0.1 * vsm
        self.RecoilPunchUp = math.Clamp(ru * self.Recoil * m * 0.6 * vsm * self.RecoilRise, 0, 0.5)
    end
end

function SWEP:GetBurstLength()
    local bl = self:GetCurrentFiremode().Mode

    if !self:GetCurrentFiremode().Mode then
        return self.BurstCount + 10
    end

    local hsb = self:GetBuff_Hook("Hook_GetBurstLength", bl)

    if bl >= 2 then return self.BurstCount + 10 end

    if hsb != bl then return hsb end

    if bl < 0 then return -bl end

    return self.BurstCount + 10
end

function SWEP:ShouldBeAutomatic()
    if self:GetCurrentFiremode().Mode == 1 then return false end

    if self:GetCurrentFiremode().RunawayBurst then return true end

    return true
end

function SWEP:FireAnimationEvent( pos, ang, event, options )
    return true
end

function SWEP:GetDamage(range, pellet)
    local num = (self:GetBuff_Override("Override_Num") or self.Num) + self:GetBuff_Add("Add_Num")
    local dmult = 1

    if pellet then
        dmult = 1
    elseif num then
        dmult = self.Num / dmult
    end

    local dmgmax = self.Damage * self:GetBuff_Mult("Mult_Damage") * dmult
    local dmgmin = self.DamageMin * self:GetBuff_Mult("Mult_DamageMin") * dmult

    local delta = 1

    if dmgmax < dmgmin then
        delta = range / (self.Range / self:GetBuff_Mult("Mult_Range"))
    else
        delta = range / (self.Range * self:GetBuff_Mult("Mult_Range"))
    end

    delta = math.Clamp(delta, 0, 1)

    local amt = Lerp(delta, dmgmax, dmgmin)

    return amt
end

function SWEP:SecondaryAttack()
    if self.Melee2 then
        self:Bash(true)
        return
    end
end