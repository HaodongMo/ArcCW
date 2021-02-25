local mth      = math
local m_rand   = mth.Rand
local m_lerp   = Lerp

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

function ArcCW:DoPenetration(tr, damage, bullet, penleft, physical, alreadypenned)
    if CLIENT then return end

    if tr.HitSky then return end

    if penleft <= 0 then return end

    alreadypenned = alreadypenned or {}

    local skip = false

    local trent = tr.Entity
    local hitpos, startpos = tr.HitPos, tr.StartPos

    local penmult     = ArcCW.PenTable[tr.MatType] or 1
    local pentracelen = 2
    local curr_ent    = trent
    local startpen = penleft

    if !tr.HitWorld then penmult = penmult * 1.5 end

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

    while !skip and penleft > 0 and (!ptr.StartSolid or ptr.AllSolid) and ptr.Fraction < 1 and ptrent == curr_ent do
        penleft = penleft - (pentracelen * penmult)

        td.start  = endpos
        td.endpos = endpos + (dir * pentracelen)
        td.mask   = MASK_SHOT

        ptr = util.TraceLine(td)

        -- This is apparently never called?
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

        if GetConVar("developer"):GetBool() then
            local pdeltap = penleft / bullet.Penetration
            local colorlr = m_lerp(pdeltap, 0, 255)

            debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(255, colorlr, colorlr), true)
        end

        endpos = endpos + (dir * pentracelen)

        dir = dir + (VectorRand() * 0.025 * penmult)
    end

    if penleft > 0 then
        if (dir:Length() == 0) then return end

        local pdelta = penleft / bullet.Penetration

        local attacker = bullet.Attacker

        if !IsValid(attacker) then
            attacker = game.GetWorld()
        end

        if physical then
            if !ptr.HitWorld then
                alreadypenned[ptr.Entity:EntIndex()] = true
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
                if alreadypenned[ptr.Entity:EntIndex()] then
                    dmg:SetDamage(0)
                else
                    dmg:SetDamageType(bullet.DamageType)
                    dmg:SetDamage(bullet.Weapon:GetDamage(dist, true) * pdelta, true)
                end
                alreadypenned[ptr.Entity:EntIndex()] = true

                ArcCW:DoPenetration(btr, damage, bullet, penleft, false, alreadypenned)

                if GetConVar("developer"):GetBool() then
                    debugoverlay.Line(endpos, endpos + dir * (btr.HitPos - endpos):Length(), 10, Color(150, 150, 150), true)
                end
            end

            attacker:FireBullets(abullet)
        end

        -- if tr.HitWorld then

            local supbullet = {}
            supbullet.Src      = endpos
            supbullet.Dir      = -dir
            supbullet.Damage   = 0
            supbullet.Distance = 8
            supbullet.Tracer   = 0
            supbullet.Force    = 0

            attacker:FireBullets(supbullet, true)

        -- end
    end
end