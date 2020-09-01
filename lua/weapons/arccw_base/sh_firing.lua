local mth      = math
local m_derand = mth.randomseed
local m_rand   = mth.Rand
local m_clamp  = mth.Clamp
local m_fmod   = mth.fmod
local m_max    = mth.max
local m_lerp   = Lerp

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if owner:IsNPC() then self:NPC_Shoot() return end

    if self:GetNWBool("ubgl") then self:ShootUBGL() return end

    if self:GetNextPrimaryFire() >= CurTime() then return end

    if self:GetState() == ArcCW.STATE_CUSTOMIZE then return end

    if self:GetState() ~= ArcCW.STATE_SIGHTS and owner:KeyDown(IN_USE) or self.PrimaryBash then self:Bash() return end

    if self.Throwing then self:PreThrow() return end

    if self:BarrelHitWall() > 0 then return end

    if self:GetState() == ArcCW.STATE_SPRINT and not (self:GetBuff_Override("Override_ShootWhileSprint") or self.ShootWhileSprint) then return end

    if self:Clip1() <= 0 then
        self.BurstCount = 0
        self:DryFire()

        return
    end

    if self:GetNWBool("cycle", false) then return end

    if (self.BurstCount or 0) >= self:GetBurstLength() then return end

    if self:GetCurrentFiremode().Mode == 0 then
        self:ChangeFiremode(false)
        self.Primary.Automatic = false

        return
    end

    if self:GetBuff_Hook("Hook_ShouldNotFire") then return end
  
    m_derand(util.SharedRandom(self.BurstCount, -1337, 1337, CurTime()) * (self:EntIndex() % 30241))

    self.Primary.Automatic = self:ShouldBeAutomatic()

    local fsound = self.ShootSound

    if self:GetBuff_Override("Silencer") then
        fsound = self.ShootSoundSilenced
    end

    local firstsound = self.FirstShootSound

    if self.BurstCount == 0 and firstsound then
        fsound = firstsound

        local firstsil = self.FirstShootSoundSilenced

        if self:GetBuff_Override("Silencer") then
            fsound = firstsil and firstsil or self.ShootSoundSilenced
        end
    end

    local lastsound = self.LastShootSound

    if self:Clip1() == 1 and lastsound then
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

    local dir = owner:EyeAngles()
    local src = self:GetShootSrc()

    if bit.band(util.PointContents(src), CONTENTS_WATER) == CONTENTS_WATER and not (self.CanFireUnderwater or self:GetBuff_Override("Override_CanFireUnderwater")) then
        self:DryFire()

        return
    end

    local spread = ArcCW.MOAToAcc * self.AccuracyMOA * self:GetBuff_Mult("Mult_AccuracyMOA")

    dir = dir + (AngleRand() * self:GetDispersion() / 360 / 60)

    local delay = (self.Delay * (1 / self:GetBuff_Mult("Mult_RPM")))

    delay = self:GetBuff_Hook("Hook_ModifyRPM", delay) or delay

    self:SetNextPrimaryFire(CurTime() + delay)

    local num = self:GetBuff_Override("Override_Num")

    if not num then num = self.Num end

    num = num + self:GetBuff_Add("Add_Num")

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
    bullet.Tracer     = self:GetBuff_Override("Override_TracerNum") or self.TracerNum
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

        if not hit then return end

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

        if not bullet then return end
    
        local doent = shootent and num or bullet.Num
        local minnum = shootent and 1 or 0
    
        if doent > minnum then
            for n = 1, bullet.Num do
                bullet.Num = 1
    
                local dispers = self:GetBuff_Override("Override_ShotgunSpreadDispersion") or self.ShotgunSpreadDispersion
                local offset  = self:GetShotgunSpreadOffset(n)
                local calcoff = dispers and (offset * self:GetDispersion() / 60) or (offset + extraspread)
    
                local ang = owner:EyeAngles() + calcoff
    
                if not self:GetBuff_Override("Override_NoRandSpread") then -- Needs testing
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
    
            if not self:GetBuff_Override("Override_NoRandSpread") then -- Needs testing
                ang = ang + (AngleRand() * spread / 10)
            end
    
            projectiledata.ang = ang + extraspread
    
            self:DoPrimaryFire(true, projectiledata)
        end
    else
        bullet = self:GetBuff_Hook("Hook_FireBullets", bullet)

        if not bullet then return end

        for n = 1, bullet.Num do
            bullet.Num = 1

            if not self:GetBuff_Override("Override_NoRandSpread") then
                local ang = dir + AngleRand() * spread / 5
                bullet.Dir = ang:Forward()
            end

            self:DoPrimaryFire(false, bullet)
        end
    end

    self:DoRecoil()

    owner:DoAnimationEvent(self:GetBuff_Override("Override_AnimShoot") or self.AnimShoot)

    local volume = self.ShootVol * self:GetBuff_Mult("Mult_ShootVol")
    local pitch  = self.ShootPitch * m_rand(1 - self.ShootPitchVariation, 1 + self.ShootPitchVariation) * self:GetBuff_Mult("Mult_ShootPitch")

    volume = m_clamp(volume, 51, 149)
    pitch  = m_clamp(pitch, 51, 149)

    local shouldsupp = SERVER and not game.SinglePlayer()

    if shouldsupp then SuppressHostEvents(owner) end

    self:DoEffects()

    if distancesound then self:MyEmitSound(distancesound, 149, pitch, 0.5, CHAN_WEAPON + 1) end

    if fsound then self:MyEmitSound(fsound, volume, pitch, 1, CHAN_WEAPON) end

    if IsFirstTimePredicted() then self.BurstCount = self.BurstCount + 1 end

    self:TakePrimaryAmmo(1) -- add self.PrimaryTakeAmmo or smth

    self:DoPrimaryAnim()

    if self.ManualAction or self:GetBuff_Override("Override_ManualAction") and not (self.NoLastCycle and self:Clip1() == 0) then
        self:SetNWBool("cycle", true)
    end

    if self:GetCurrentFiremode().Mode < 0 and self.BurstCount == -self:GetCurrentFiremode().Mode then
        local postburst = self:GetCurrentFiremode().PostBurstDelay or 0

        self:SetNextPrimaryFire(CurTime() + postburst)
    end

    self:ApplyAttachmentShootDamage()

    self:GetBuff_Hook("Hook_PostFireBullets")

    if shouldsupp then SuppressHostEvents(nil) end
end

function SWEP:DoPrimaryFire(isent, data)
    local owner = self:GetOwner()

    if isent then
        self:FireRocket(data.ent, data.vel, data.ang)
    else
        owner:LagCompensation(true)
        owner:FireBullets(data)
        owner:LagCompensation(false)
    end
end

function SWEP:DoPrimaryAnim()
    local anim = "fire"

    local inbipod = self:InBipod()
    local empty   = self:Clip1() == 0
    local iron    = self:GetState() == ArcCW.STATE_SIGHTS

    local bipodem = self.Animations.fire_bipod_empty
    local bipod   = self.Animations.fire_bipod

    local ironem  = self.Animations.fire_iron_empty
    local fireir  = self.Animations.fire_iron
    local fireem  = self.Animations.fire_empty

    -- Needs testing
    if inbipod then
        anim = (empty and iron and bipodem) and "fire_bipod_iron_empty" or (empty and bipodem) and "fire_bipod_iron_empty"
                or (empty and iron and ironem) and "fire_iron_empty" or (iron and fireir) and "fire_iron" or "fire"
    elseif iron then
        anim = (empty and ironem) and "fire_iron_empty" or fireir and "fire_iron" or "fire"
    else
        anim = (empty and fireem) and "fire_empty" or "fire"
    end

    if (self.ProceduralIronFire and iron) or (self.ProceduralRegularFire and not iron) then anim = nil end

    anim = self:GetBuff_Hook("Hook_SelectFireAnimation", anim) or anim

    local time = self:GetBuff_Mult("Mult_FireAnimTime", anim) or 1

    if anim then self:PlayAnimation(anim, time, true, 0, false) end
end

function SWEP:DoPenetration(tr, penleft, alreadypenned)
    if CLIENT then return end

    if tr.HitSky then return end

    if penleft <= 0 then return end

    alreadypenned = alreadypenned or {}

    local trent = tr.Entity
    local hitpos, startpos = tr.HitPos, tr.StartPos

    local penmult     = ArcCW.PenTable[tr.MatType] or 1
    local pentracelen = 2
    local curr_ent    = trent

    if not tr.HitWorld then penmult = penmult * 1.5 end

    if trent.mmRHAe then penmult = trent.mmRHAe end

    penmult = penmult * m_rand(0.9, 1.1) * m_rand(0.9, 1.1)

    local dir    = (hitpos - startpos):GetNormalized()
    local endpos = hitpos

    local td  = {}
    td.start  = endpos
    td.endpos = endpos + (dir * pentracelen)
    td.mask   = MASK_SHOT

    local ptr = util.TraceLine(td)

    local ptrent = ptr.Entity

    while penleft > 0 and (not ptr.StartSolid or ptr.AllSolid) and ptr.Fraction < 1 and ptrent == curr_ent do
        penleft = penleft - (pentracelen * penmult)

        td.start  = endpos
        td.endpos = endpos + (dir * pentracelen)
        td.mask   = MASK_SHOT

        ptr = util.TraceLine(td)

        if ptrent ~= curr_ent then
            ptrent = ptr.Entity

            curr_ent = ptrent

            local ptrhp  = ptr.HitPos
            local dist   = (ptrhp - tr.StartPos):Length() * ArcCW.HUToM
            local pdelta = penleft / (self.Penetration * self:GetBuff_Mult("Mult_Penetration"))

            local dmg = DamageInfo()
            dmg:SetDamageType(self:GetBuff_Override("Override_DamageType") or self.DamageType)
            dmg:SetDamage(self:GetDamage(dist, true) * pdelta)
            dmg:SetDamagePosition(ptrhp)

            if IsValid(ptrent) and not table.HasValue(alreadypenned, ptrent) then ptrent:TakeDamageInfo(dmg) end

            penmult = ArcCW.PenTable[ptr.MatType] or 1

            if not ptr.HitWorld then penmult = penmult * 1.5 end

            if ptrent.mmRHAe then penmult = ptrent.mmRHAe end

            penmult = penmult * m_rand(0.9, 1.1) * m_rand(0.9, 1.1)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(0, 0, 255), true)
        end

        if GetConVar("developer"):GetBool() then
            local pdeltap = penleft / self.Penetration
            local colorlr = m_lerp(pdeltap, 0, 255)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(255, colorlr, colorlr), true)
        end

        endpos = endpos + (dir * pentracelen)

        dir = dir + (VectorRand() * 0.025 * penmult)
    end

    if penleft > 0 then
        if (dir:Length() == 0) then return end

        local pdelta = penleft / (self.Penetration * self:GetBuff_Mult("Mult_Penetration"))

        m_derand(self:GetOwner():GetCurrentCommand():CommandNumber() + (self:EntIndex() % 24977))

        local owner = self:GetOwner()

        local bullet = {}
        bullet.Attacker = owner
        bullet.Dir      = dir
        bullet.Src      = endpos
        bullet.Spread   = Vector(spread, spread, spread)
        bullet.Damage   = 0
        bullet.Num      = 1
        bullet.Force    = 0
        bullet.Distance = 33000
        bullet.AmmoType = self.Primary.Ammo
        bullet.Tracer   = 0
        bullet.Callback = function(att, btr, dmg)
            local dist = (btr.HitPos - endpos):Length() * ArcCW.HUToM

            if table.HasValue(alreadypenned, ptr.Entity) then
                dmg:SetDamage(0)
            else
                dmg:SetDamageType(self:GetBuff_Override("Override_DamageType") or self.DamageType)
                dmg:SetDamage(self:GetDamage(dist, true) * pdelta, true)
            end

            self:DoPenetration(btr, penleft)
        end

        owner:FireBullets(bullet)

        local supbullet = {}
        supbullet.Src      = endpos
        supbullet.Dir      = -dir
        supbullet.Damage   = 0
        supbullet.Distance = 8
        supbullet.Tracer   = 0
        supbullet.Force    = 0

        owner:FireBullets(supbullet, true)
    end
end

function SWEP:GetShootSrc()
    local owner = self:GetOwner()
    
    if owner:IsNPC() then return owner:GetShootPos() end

    local dir    = owner:EyeAngles()
    local offset = self:GetBuff_Override("Override_BarrelOffsetHip") or self.BarrelOffsetHip

    if self:GetState() == ArcCW.STATE_SIGHTS then
        offset = self:GetBuff_Override("Override_BarrelOffsetSighted") or self.BarrelOffsetSighted
    end

    local src = owner:EyePos()
    src = src + dir:Right()   * offset[1]
    src = src + dir:Forward() * offset[2]
    src = src + dir:Up()      * offset[3]

    return src
end

function SWEP:GetShotgunSpreadOffset(num)
    local rotate = Angle()
    local spread   = self:GetBuff_Override("Override_ShotgunSpreadPattern") or self.ShotgunSpreadPattern or {}
    local spreadov = self:GetBuff_Override("Override_ShotgunSpreadPatternOverrun") or self.ShotgunSpreadPatternOverrun or { Angle() }

    if istable(spread) and istable(spreadov) then
        spread["BaseClass"]   = nil
        spreadov["BaseClass"] = nil

        if num > #spread then
            if spo then
                num = num - #spread
                num = m_fmod(num, #spreadov) + 1
                rotate = spreadov[num]
            else
                num = m_fmod(num, #spread) + 1
                rotate = spread[num]
            end
        else
            rotate = spread[num]
        end
    end

    local rotate = {}
    rotate.num = num
    rotate.ang = rotate

    rotate = self:GetBuff_Hook("Hook_ShotgunSpreadOffset", rotate).ang

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

        speed = m_clamp(speed / maxspeed, 0, 2)

        hip = hip + (speed * self.MoveDispersion * self:GetBuff_Mult("Mult_MoveDispersion"))
    else
        hip = hip + m_max(self.JumpDispersion * self:GetBuff_Mult("Mult_JumpDispersion"), self.MoveDispersion * self:GetBuff_Mult("Mult_MoveDispersion") * 2)
    end

    if self:InBipod() then hip = hip * ((self.BipodDispersion or 1) * self:GetBuff_Mult("Mult_BipodDispersion") or 0.1) end

    return hip
end

function SWEP:DoShellEject()
    if not game.SinglePlayer() and not IsFirstTimePredicted() then return end

    local owner = self:GetOwner()

    if not IsValid(owner) then return end

    local vm = self

    if not owner:IsNPC() then owner:GetViewModel() end

    local att = vm:GetAttachment(self:GetBuff_Override("Override_CaseEffectAttachment") or self.CaseEffectAttachment or 2)

    if not att then return end

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
    if not game.SinglePlayer() and not IsFirstTimePredicted() then return end

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

    self.Primary.Automatic = false
    self:MyEmitSound(self.ShootDrySound or "weapons/arccw/dryfire.wav", 75, 100, 1, CHAN_ITEM)
    self:SetNextPrimaryFire(CurTime() + 0.25)
end

function SWEP:DoRecoil()
    local single = game.SinglePlayer()

    if not single and not IsFirstTimePredicted() then return end

    if single and self:GetOwner():IsValid() and SERVER then self:CallOnClient("DoRecoil") end

    local rec    = self:GetBuff_Hook("Hook_ModifyRecoil") or {}
    local recoil = rec.Recoil
    local side   = rec.RecoilSide
    local visual = rec.VisualRecoilMul

    local rmul = (recoil or 1) * self:GetBuff_Mult("Mult_Recoil")
    local recv = (visual or 1) * self:GetBuff_Mult("Mult_VisualRecoilMult")
    local recs = (side or 1)   * self:GetBuff_Mult("Mult_RecoilSide")

    local irec = m_rand(-1, 1)
    local recu = m_rand(0.75, 1.25)

    if self:InBipod() then
        local biprec = self.BipodRecoil
        local bipmul = self:GetBuff_Mult("Mult_BipodRecoil")

        rmul = rmul * ((biprec or 1) * bipmul or 0.25)
        recs = recs * ((biprec or 1) * bipmul or 0.25)
    end

    local recoiltbl = self:GetBuff_Override("Override_ShotRecoilTable") or self.ShotRecoilTable

    if recoiltbl and recoiltbl[self.BurstCount] then rmul = rmul * recoiltbl[self.BurstCount] end

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
        self.RecoilPunchBack  = self.Recoil * rmul * m_rand(2, 3)

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = m_clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = self.RecoilSide * 0.1 * irec * recv * rmul
        self.RecoilPunchUp   = m_clamp(self.Recoil * self.RecoilRise * 0.6 * recu * recv * rmul, 0, 0.1)
    end
end

function SWEP:GetBurstLength()
    local len = self:GetCurrentFiremode().Mode

    if not len then return self.BurstCount + 10 end

    local hookedlen = self:GetBuff_Hook("Hook_GetBurstLength", len)

    if len >= 2 then return self.BurstCount + 10 end

    if hookedlen ~= len then return hookedlen end

    if len < 0 then return -len end

    return self.BurstCount + 10
end

function SWEP:ShouldBeAutomatic()
    if self:GetCurrentFiremode().Mode == 1 then return false end

    if self:GetCurrentFiremode().RunawayBurst then return true end

    return true
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

    mul = ((pellet and num == 1) and (1 / ((ovr or 1) + add))) or ((num ~= nbr) and (num / nbr)) or 1

    if not pellet then mul = mul * nbr end

    local dmgmax = self.Damage * self:GetBuff_Mult("Mult_Damage") * mul
    local dmgmin = self.DamageMin * self:GetBuff_Mult("Mult_DamageMin") * mul
    local delta = 1

    local sran = self.Range
    local bran = self:GetBuff_Mult("Mult_Range")

    delta = (dmgmax < dmgmin and (range / (sran / bran))) or (range / (sran * bran))
    delta = m_clamp(delta, 0, 1)

    local lerped = m_lerp(delta, dmgmax, dmgmin)

    return lerped
end

function SWEP:SecondaryAttack()
    return self.Melee2 and self:Bash(true)
end