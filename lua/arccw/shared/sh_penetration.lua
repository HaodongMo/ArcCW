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

function ArcCW:IsPenetrating(ptr, ptrent)
    if ptrent:IsWorld() then
        return !ptr.StartSolid or ptr.AllSolid
    elseif IsValid(ptrent) then
        local mins, maxs = ptrent:WorldSpaceAABB()
        local wsc = ptrent:WorldSpaceCenter()
        -- Expand the bounding box by a bit to account for hitboxes outside it
        -- This is more consistent but less accurate
        mins = mins + (mins - wsc) * 0.25
        maxs = maxs + (maxs - wsc) * 0.25
        local withinbounding = ptr.HitPos:WithinAABox(mins, maxs)
        if GetConVar("arccw_dev_shootinfo"):GetInt() >= 2 then
            --debugoverlay.Box(Vector(0, 0, 0), mins, maxs, 5, Color(255, 255, 255, 50))
            --debugoverlay.Cross(mins, 4, 5, Color(128, 0, 0), true)
            --debugoverlay.Cross(maxs, 4, 5, Color(128, 0, 0), true)
            debugoverlay.Cross(ptr.HitPos, withinbounding and 2 or 6, 5, withinbounding and Color(255, 255, 0) or Color(128, 255, 0), true)
        end

        if withinbounding then return true end
        --[[]
        -- Check whether the point is inside the hitbox
        -- Requires some math that I can't be bothered to solve
        if ptr.HitBox > 0 then
            local mins2, maxs2 = ptrent:GetHitBoxBounds(ptr.HitBox, ptr.HitGroup)
            local bonepos, boneang = ptrent:GetBonePosition(ptrent:GetHitBoxBone(ptr.HitBox, ptrent:GetHitboxSet()))
            if GetConVar("developer"):GetBool() then
                debugoverlay.BoxAngles(bonepos, mins2, maxs2, boneang, 5, Color(255, 255, 255, 50))
                debugoverlay.Axis(bonepos, boneang, 16, 5, true)
            end
        end
        ]]
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
    local pentracelen = 4 --2 originally, but this should be less costly
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

    while !skip and penleft > 0 and ArcCW:IsPenetrating(ptr, ptrent) and ptr.Fraction < 1 and ptrent == curr_ent do
        penleft = penleft - (pentracelen * penmult)

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

        if GetConVar("arccw_dev_shootinfo"):GetInt() >= 2 then
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

                if GetConVar("arccw_dev_shootinfo"):GetInt() >= 2 then
                    local e = endpos + dir * (btr.HitPos - endpos):Length()
                    debugoverlay.Line(endpos, e, 10, Color(150, 150, 150), true)
                    debugoverlay.Cross(e, 3, 10, alreadypenned[btr.Entity:EntIndex()] and Color(0, 128, 255) or Color(255, 128, 0), true)
                    debugoverlay.Text(e, math.Round(penleft, 1) .. "mm", 10)
                end
                if GetConVar("arccw_dev_shootinfo"):GetInt() >= 1 and IsValid(btr.Entity) and !alreadypenned[btr.Entity:EntIndex()] then
                    local str = string.format("%ddmg/%dm(%d%%)", dmg:GetDamage(), dist, math.Round((1 - bullet.Weapon:GetRangeFraction(dist)) * 100))
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