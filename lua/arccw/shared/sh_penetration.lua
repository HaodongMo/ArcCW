local mth      = math
local m_rand   = mth.Rand
local m_lerp   = Lerp

local function draw_debug()
    return (CLIENT or game.SinglePlayer()) and GetConVar("arccw_dev_shootinfo"):GetInt() >= 2
end

function ArcCW:GetRicochetChance(penleft, tr)
    if !GetConVar("arccw_enable_ricochet"):GetBool() then return 0 end
    local degree = tr.HitNormal:Dot((tr.StartPos - tr.HitPos):GetNormalized())

    local ricmult = ArcCW.PenTable[tr.MatType] or 1

    -- 0 at 1
    -- 100 at 0

    local c = Lerp(degree, math.min(penleft * ricmult * 2, 45), 0)

    -- c = c * GetConVar("arccw_ricochet_mult"):GetFloat()

    -- c = 100

    return math.Clamp(c, 0, 100)
end

function ArcCW:IsPenetrating(ptr, ptrent)
    if ptrent:IsWorld() then
        return ptr.Contents != CONTENTS_EMPTY
    elseif IsValid(ptrent) then

        local withinbounding = false
        local hboxset = ptrent:GetHitboxSet()
        local hitbone = ptrent:GetHitBoxBone(ptr.HitBox, hboxset)
        if hitbone then
            -- If we hit a hitbox, compare against that hitbox only
            local mins, maxs = ptrent:GetHitBoxBounds(ptr.HitBox, hboxset)
            local bonepos, boneang = ptrent:GetBonePosition(hitbone)
            mins = mins * 1.1
            maxs = maxs * 1.1
            local lpos = WorldToLocal(ptr.HitPos, ptr.HitNormal:Angle(), bonepos, boneang)

            withinbounding = lpos:WithinAABox(mins, maxs)
            if draw_debug() then
                debugoverlay.BoxAngles(bonepos, mins, maxs, boneang, 5, Color(255, 255, 255, 10))
            end
        elseif util.PointContents(ptr.HitPos) != CONTENTS_EMPTY then
            -- Otherwise default to rotated OBB
            local mins, maxs = ptrent:OBBMins(), ptrent:OBBMaxs()
            withinbounding = ptrent:WorldToLocal(ptr.HitPos):WithinAABox(mins, maxs)
            if draw_debug() then
                debugoverlay.BoxAngles(ptrent:GetPos(), mins, maxs, ptrent:GetAngles(), 5, Color(255, 255, 255, 10))
            end
        end
        if draw_debug() then
            debugoverlay.Cross(ptr.HitPos, withinbounding and 4 or 6, 5, withinbounding and Color(255, 255, 0) or Color(128, 255, 0), true)
        end


        return withinbounding
    end
    return false
end

function ArcCW:DoPenetration(tr, damage, bullet, penleft, physical, alreadypenned)
    local hitpos, startpos = tr.HitPos, tr.StartPos
    local dir    = (hitpos - startpos):GetNormalized()

    if CLIENT then
        return
    end

    if tr.HitSky then return end

    if penleft <= 0 then return end

    alreadypenned = alreadypenned or {}

    local skip = false

    local trent = tr.Entity

    local penmult     = ArcCW.PenTable[tr.MatType] or 1
    local pentracelen = 4
    local curr_ent    = trent
    local startpen = penleft

    if !tr.HitWorld then penmult = penmult * 1.5 end

    if trent.mmRHAe then penmult = trent.mmRHAe end

    penmult = penmult * m_rand(0.9, 1.1) * m_rand(0.9, 1.1)

    local endpos = hitpos

    local td  = {}
    td.start  = endpos
    td.endpos = endpos + (dir * pentracelen)
    td.mask   = MASK_SHOT

    local ptr = util.TraceLine(td)

    local ptrent = ptr.Entity

    if ArcCW:GetRicochetChance(penleft, tr) > math.random(0, 100) then
        local degree = tr.HitNormal:Dot((tr.StartPos - tr.HitPos):GetNormalized())
        if degree == 0 or degree == 1 then return end
        sound.Play(ArcCW.RicochetSounds[math.random(#ArcCW.RicochetSounds)], tr.HitPos)
        if (tr.Normal:Length() == 0) then return end
        -- ACT3_ShootPBullet(tr.HitPos, ((2 * degree * tr.HitNormal) + tr.Normal) * (vel * math.Rand(0.25, 0.75)), owner, inflictor, bulletid, false, 1, penleft, dist)
        -- return

        dir = (2 * degree * tr.HitNormal) + tr.Normal
        ang = dir:Angle()
        ang = ang + (AngleRand() * (1 - degree) * 15 / 360)
        dir = ang:Forward()

        local d = math.Rand(0.25, 0.95)

        penleft = penleft * d

        skip = true
    end

    if !GetConVar("arccw_enable_penetration"):GetBool() then return end

    local factor = 1
    while !skip and penleft > 0 and ArcCW:IsPenetrating(ptr, ptrent) and ptr.Fraction < 1 and ptrent == curr_ent do
        penleft = penleft - (pentracelen * penmult) * factor

        -- Prevent extremely long penetrations (such as with glass)
        factor = factor * 1.05

        td.start  = endpos
        td.endpos = endpos + (dir * pentracelen)
        td.mask   = MASK_SHOT

        ptr = util.TraceLine(td)

        -- This is never called because curr_ent is never updated, genius
        -- Damage is handled in abullet.Callback anyways
        --[[]
        if ptrent != curr_ent then
            ptrent = ptr.Entity

            curr_ent = ptrent

            local ptrhp  = ptr.HitPos
            -- local dist   = (ptrhp - tr.StartPos):Length() * ArcCW.HUToM
            local pdelta = penleft / bullet.Penetration

            local dmg = DamageInfo()
            dmg:SetDamageType(bullet.DamageType)
            dmg:SetDamage(damage * pdelta)
            dmg:SetDamagePosition(ptrhp)

            if IsValid(ptrent) and !alreadypenned[ptrent:EntIndex()] then ptrent:TakeDamageInfo(dmg) end

            penmult = ArcCW.PenTable[ptr.MatType] or 1

            if !ptr.HitWorld then penmult = penmult * 1.5 end

            if ptrent.mmRHAe then penmult = ptrent.mmRHAe end

            penmult = penmult * m_rand(0.9, 1.1) * m_rand(0.9, 1.1)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(0, 0, 255), true)
        end
        ]]

        if draw_debug() then
            local pdeltap = penleft / bullet.Penetration
            local colorlr = m_lerp(pdeltap, 0, 255)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(255, colorlr, colorlr), true)
        end

        endpos = endpos + (dir * pentracelen)

        dir = dir + (VectorRand() * 0.025 * penmult)
    end

    if penleft > 0 then
        if (dir:Length() == 0) then return end

        -- Recover penetration lost from extra distance in the trace
        --penleft = penleft + ptr.Fraction * pentracelen / penmult

        if draw_debug() then
            debugoverlay.Text(endpos + Vector(0, 0, 2), "(" .. math.Round(penleft, 2) .. "mm)", 5)
        end

        local pdelta = penleft / bullet.Penetration

        local attacker = bullet.Attacker

        if !IsValid(attacker) then
            attacker = game.GetWorld()
        end

        if physical then
            if !ptr.HitWorld then
                alreadypenned[ptrent:EntIndex()] = true
            end

            local newbullet = {}
            newbullet.DamageMin = bullet.DamageMin or 1
            newbullet.DamageMax = bullet.DamageMax or 10
            newbullet.Range = bullet.Range or 100
            newbullet.DamageType = bullet.DamageType or DMG_BULLET
            newbullet.Penleft = penleft
            newbullet.Penetration = bullet.Penetration
            newbullet.Num = bullet.Num or 1
            newbullet.Pos = endpos
            local spd = bullet.Vel:Length()
            newbullet.Attacker = bullet.Attacker
            newbullet.Vel = dir * spd * (penleft / startpen)
            newbullet.Drag = bullet.Drag or 1
            newbullet.Travelled = bullet.Travelled + (endpos - hitpos):Length()
            newbullet.Damaged = alreadypenned
            newbullet.Profile = bullet.Profile or 1
            newbullet.Gravity = bullet.Gravity or 1
            newbullet.StartTime = bullet.StartTime or CurTime()
            newbullet.PhysBulletImpact = bullet.PhysBulletImpact or true
            newbullet.Weapon = bullet.Weapon

            if bit.band( util.PointContents( endpos ), CONTENTS_WATER ) == CONTENTS_WATER then
                newbullet.Underwater = true
            end

            table.insert(ArcCW.PhysBullets, newbullet)

            ArcCW:SendBullet(newbullet)
        else
            local abullet = {}
            abullet.Attacker = owner
            abullet.Dir      = dir
            abullet.Src      = endpos
            abullet.Spread   = Vector(0, 0, 0)
            abullet.Damage   = 0
            abullet.Num      = 1
            abullet.Force    = 0
            abullet.Distance = 33000
            abullet.Tracer   = 0
            --abullet.IgnoreEntity = ptr.Entity
            abullet.Callback = function(att, btr, dmg)
                local dist = bullet.Travelled * ArcCW.HUToM
                bullet.Travelled = bullet.Travelled + (btr.HitPos - endpos):Length()

                if alreadypenned[btr.Entity:EntIndex()] then
                    dmg:SetDamage(0)
                else
                    dmg:SetDamageType(bullet.DamageType)
                    dmg:SetDamage(bullet.Weapon:GetDamage(dist, true) * pdelta, true)
                end

                if draw_debug() then
                    local e = endpos + dir * (btr.HitPos - endpos):Length()
                    debugoverlay.Line(endpos, e, 10, Color(150, 150, 150), true)
                    debugoverlay.Cross(e, 3, 10, alreadypenned[btr.Entity:EntIndex()] and Color(0, 128, 255) or Color(255, 128, 0), true)
                    debugoverlay.Text(e, math.Round(penleft, 1) .. "mm", 10)
                end
                if (CLIENT or game.SinglePlayer()) and GetConVar("arccw_dev_shootinfo"):GetInt() >= 1 and IsValid(btr.Entity) and !alreadypenned[btr.Entity:EntIndex()] then
                    local str = string.format("%ddmg/%dm(%d%%)", math.floor(bullet.Weapon:GetDamage(dist)), dist, math.Round((1 - bullet.Weapon:GetRangeFraction(dist)) * 100))
                    debugoverlay.Text(btr.Entity:WorldSpaceCenter(), str, 5)
                end

                alreadypenned[btr.Entity:EntIndex()] = true

                ArcCW:DoPenetration(btr, damage, bullet, penleft, false, alreadypenned)

                -- if !game.SinglePlayer() and CLIENT then
                    local fx = EffectData()
                    fx:SetStart(tr.HitPos)
                    fx:SetOrigin(btr.HitPos)
                    util.Effect("arccw_ricochet", fx)
                -- end
            end

            attacker:FireBullets(abullet)
        end

        --[[
        local atk = bullet.Attacker

        local supbullet = {}
            supbullet.Src      = hitpos
            supbullet.Dir      = -dir
            supbullet.Damage   = 0
            supbullet.Distance = 8
            supbullet.Tracer   = 0
            supbullet.Force    = 0

            attacker:FireBullets(supbullet, true)
        ]]

    end
end

function ArcCW:BulletCallback(att, tr, dmg, bullet, phys)

    local wep = phys and bullet.Weapon or bullet
    local hitpos, hitnormal = tr.HitPos, tr.HitNormal
    local trent = tr.Entity

    local dist = (phys and bullet.Travelled or (hitpos - tr.StartPos):Length() ) * ArcCW.HUToM
    local pen  = IsValid(wep) and wep:GetBuff("Penetration") or bullet.Penleft

    if GetConVar("arccw_dev_shootinfo"):GetInt() >= 1 then
        debugoverlay.Cross(hitpos, 1, 5, SERVER and Color(255, 0, 0) or Color(0, 0, 255), true)
    end

    local randfactor = IsValid(wep) and wep:GetBuff("DamageRand") or 0
    local mul = 1
    if randfactor > 0 then
        mul = mul * math.Rand(1 - randfactor, 1 + randfactor)
    end

    local delta = !IsValid(wep) and math.Clamp(bullet.Travelled / (bullet.Range / ArcCW.HUToM), 0, 1) or wep:GetRangeFraction(dist)
    local calc_damage = (!IsValid(wep) and Lerp(delta, bullet.DamageMax, bullet.DamageMin) or wep:GetDamage(dist, true)) * mul
    local dmgtyp = !IsValid(wep)  and bullet.DamageType or wep:GetBuff_Override("Override_DamageType", wep.DamageType) or DMG_BULLET

    local hit   = {}
    hit.att     = att
    hit.tr      = tr
    hit.dmg     = dmg
    hit.range   = dist
    hit.damage  = calc_damage
    hit.dmgtype = dmgtyp
    hit.penleft = pen

    if IsValid(wep) then
        hit = wep:GetBuff_Hook("Hook_BulletHit", hit)

        if !hit then return end
    end

    if bullet.Damaged and bullet.Damaged[tr.Entity:EntIndex()] then
        dmg:SetDamage(0)
    else
        dmg:SetDamageType(hit.dmgtype)
        dmg:SetDamage(hit.damage)
    end

    local dmgtable
    if phys and IsValid(bullet.Weapon) then
        dmgtable = bullet.Weapon:GetBuff_Override("Override_BodyDamageMults", bullet.Weapon.BodyDamageMults)
    elseif IsValid(wep) then
        dmgtable = wep:GetBuff_Override("Override_BodyDamageMults", wep.BodyDamageMults)
    else
        dmgtable = bullet.BodyDamageMults
    end

    if dmgtable then
        local hg = tr.HitGroup
        local gam = ArcCW.LimbCompensation[engine.ActiveGamemode()] or ArcCW.LimbCompensation[1]
        if dmgtable[hg] then
            dmg:ScaleDamage(dmgtable[hg])

            -- cancelling gmod's stupid default values (but only if we have a multiplier)
            if GetConVar("arccw_bodydamagemult_cancel"):GetBool() and gam[hg] then dmg:ScaleDamage(gam[hg]) end
        end
    end

    if IsValid(att) and att:IsNPC() then
        dmg:ScaleDamage(wep:GetBuff_Mult("Mult_DamageNPC") or 1)
    end

    local effect = phys and bullet.ImpactEffect or (IsValid(wep) and wep:GetBuff_Override("Override_ImpactEffect", wep.ImpactEffect))
    local decal  = phys and bullet.ImpactDecal or (IsValid(wep) and wep:GetBuff_Override("Override_ImpactDecal", wep.ImpactDecal))

    -- Do our handling of damage types, if not ignored by the gun or some attachment
    if IsValid(wep) and !wep:GetBuff_Override("Override_DamageTypeHandled", wep.DamageTypeHandled) then
        local _, maxrng = wep:GetMinMaxRange()
        -- ignite target
        if dmg:IsDamageType(DMG_BURN) and hit.range <= maxrng then
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
        -- explode target
        if dmg:IsDamageType(DMG_BLAST) then
            if dmg:GetDamage() >= 200 then
                effect = "Explosion"
                decal  = "Scorch"
            else
                effect = "arccw_incendiaryround"
                decal  = "FadingScorch"
            end
            dmg:ScaleDamage(0.5) -- half applied as explosion and half done to hit target
            util.BlastDamageInfo(dmg, tr.HitPos, math.Clamp(dmg:GetDamage(), 48, 256))
            dmg:SetDamageType(dmg:GetDamageType() - DMG_BLAST)
        end
        -- damage helicopters
        if dmg:IsDamageType(DMG_BULLET) and !dmg:IsDamageType(DMG_AIRBOAT)
                and IsValid(hit.tr.Entity) and hit.tr.Entity:GetClass() == "npc_helicopter" then
            dmg:SetDamageType(dmg:GetDamageType() + DMG_AIRBOAT)
            dmg:ScaleDamage(0.1) -- coostimizable?
        elseif dmg:GetDamageType() != DMG_BLAST and IsValid(hit.tr.Entity) and hit.tr.Entity:GetClass() == "npc_combinegunship" then
            dmg:SetDamageType(DMG_BLAST)
            dmg:ScaleDamage(0.05)
            -- there is a damage threshold of 50 for damaging gunships
            if dmg:GetDamage() < 50 and dmg:GetDamage() / 200 >= math.random() then
                dmg:SetDamage(50)
            end
        end

        -- pure DMG_BUCKSHOT do not create blood decals, somehow
        if dmg:GetDamageType() == DMG_BUCKSHOT then
            dmg:SetDamageType(dmg:GetDamageType() + DMG_BULLET)
        end
    end

    if SERVER and IsValid(wep) then wep:TryBustDoor(trent, dmg) end

    -- INCONSISTENCY: For physbullet, the entire bullet is copied; hitscan bullets reset some attributes in SWEP:DoPenetration (most notably damage)
    -- For now, we just reset some changes as a temporary workaround
    if !IsValid(wep) then
        bullet.Damage = calc_damage
        bullet.DamageType = dmgtyp
        ArcCW:DoPenetration(tr, hit.damage, bullet, bullet.Penleft, true, bullet.Damaged)
    else
        wep:DoPenetration(tr, hit.penleft, { [trent:EntIndex()] = true })
    end

    if effect then
        local ed = EffectData()
        ed:SetOrigin(hitpos)
        ed:SetNormal(hitnormal)
        util.Effect(effect, ed)
    end

    if decal then
        util.Decal(decal, tr.StartPos, hitpos - (hitnormal * 16), wep:GetOwner())
    end

    if (CLIENT or game.SinglePlayer()) and (!phys or SERVER) and GetConVar("arccw_dev_shootinfo"):GetInt() >= 1 then
        local str = string.format("%ddmg/%dm(%d%%)", math.floor(dmg:GetDamage()), dist, math.Round((1 - delta) * 100))
        debugoverlay.Text(hitpos, str, 10)
        print(str)
    end

    if IsValid(wep) then
        wep:GetBuff_Hook("Hook_PostBulletHit", hit)
    end
end