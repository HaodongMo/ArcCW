ArcCW.PhysBullets = {
}

ArcCW.BulletProfiles = {
    [1] = Color(255, 180, 100),
    [2] = Color(255, 0, 0),
    [3] = Color(0, 255, 0),
    [4] = Color(0, 0, 255),
    [5] = Color(255, 255, 0),
    [6] = Color(255, 0, 255),
    [7] = Color(0, 255, 255),
    [8] = Color(0, 0, 0),
}

function ArcCW:SendBullet(bullet, attacker)
    net.Start("arccw_sendbullet", true)
    net.WriteVector(bullet.Pos)
    net.WriteAngle(bullet.Vel:Angle())
    net.WriteFloat(bullet.Vel:Length())
    net.WriteFloat(bullet.Drag)
    net.WriteFloat(bullet.Gravity)
    net.WriteUInt((bullet.Profile - 1) or 1, 3)
    net.WriteBool(bullet.PhysBulletImpact)

    if attacker and attacker:IsValid() and attacker:IsPlayer() and !game.SinglePlayer() then
        net.SendOmit(attacker)
    else
        if game.SinglePlayer() then
            net.WriteEntity(attacker)
        end
        net.Broadcast()
    end
end

function ArcCW:ShootPhysBullet(wep, pos, vel, prof)
    local pbi = wep:GetBuff_Override("Override_PhysBulletImpact")
    local num = wep:GetBuff_Override("Override_Num") or wep.Num
    local bullet = {
        DamageMax = wep:GetDamage(0) / num,
        DamageMin = wep:GetDamage(wep:GetBuff("Range")) / num,
        Range = wep:GetBuff("Range"),
        DamageType = wep:GetBuff_Override("Override_DamageType") or wep.DamageType,
        Penleft = wep:GetBuff("Penetration"),
        Penetration = wep:GetBuff("Penetration"),
        ImpactEffect = wep:GetBuff_Override("Override_ImpactEffect") or wep.ImpactEffect,
        ImpactDecal = wep:GetBuff_Override("Override_ImpactDecal") or wep.ImpactDecal,
        PhysBulletImpact = pbi == nil and true or pbi,
        Gravity = wep:GetBuff("PhysBulletGravity"),
        Num = num,
        Pos = pos,
        Vel = vel,
        Drag = wep:GetBuff("PhysBulletDrag"),
        Travelled = 0,
        StartTime = CurTime(),
        Imaginary = false,
        Underwater = false,
        WeaponClass = wep:GetClass(),
        Weapon = wep,
        Attacker = wep:GetOwner(),
        Damaged = {},
        Burrowing = false,
        Dead = false,
        Profile = prof or wep:GetBuff_Override("Override_PhysTracerProfile") or wep.PhysTracerProfile or 0
    }

    if wep:GetOwner() and wep:GetOwner():IsNPC() then
        bullet.DamageMax = bullet.DamageMax * GetConVar("arccw_mult_npcdamage"):GetFloat()
        bullet.DamageMin = bullet.DamageMin * GetConVar("arccw_mult_npcdamage"):GetFloat()
    end

    if bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER then
        bullet.Underwater = true
    end

    table.insert(ArcCW.PhysBullets, bullet)

    if wep:GetOwner():IsPlayer() then
        local ping = wep:GetOwner():Ping() / 1000
        ping = math.Clamp(ping, 0, 0.3)
        local timestep = 0.025

        while ping > 0 do
            ArcCW:ProgressPhysBullet(bullet, math.min(timestep, ping))
            ping = ping - timestep
        end
    end

    if SERVER then
        ArcCW:SendBullet(bullet, wep:GetOwner())
    end
end

if CLIENT then

net.Receive("arccw_sendbullet", function(len, ply)
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local vel = net.ReadFloat()
    local drag = net.ReadFloat()
    local grav = net.ReadFloat()
    local profile = net.ReadUInt(3) + 1
    local impact = net.ReadBool()
    local ent = nil

    if game.SinglePlayer() then
        ent = net.ReadEntity()
    end

    local bullet = {
        Pos = pos,
        Vel = ang:Forward() * vel,
        Travelled = 0,
        StartTime = CurTime(),
        Imaginary = false,
        Underwater = false,
        Dead = false,
        Damaged = {},
        Drag = drag,
        Attacker = ent,
        Gravity = grav,
        Profile = profile,
        PhysBulletImpact = impact,
    }

    if bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER then
        bullet.Underwater = true
    end

    table.insert(ArcCW.PhysBullets, bullet)
end)

end

function ArcCW:DoPhysBullets()
    local new = {}
    for _, i in pairs(ArcCW.PhysBullets) do
        ArcCW:ProgressPhysBullet(i, FrameTime())

        if !i.Dead then
            table.insert(new, i)
        end
    end

    ArcCW.PhysBullets = new
end

hook.Add("Think", "ArcCW_DoPhysBullets", ArcCW.DoPhysBullets)

local function indim(vec, maxdim)
    if math.abs(vec.x) > maxdim or math.abs(vec.y) > maxdim or math.abs(vec.z) > maxdim then
        return false
    else
        return true
    end
end

function ArcCW:ProgressPhysBullet(bullet, timestep)
    timestep = timestep or FrameTime()

    if bullet.Dead then return end

    local oldpos = bullet.Pos
    local oldvel = bullet.Vel
    local dir = bullet.Vel:GetNormalized()
    local spd = bullet.Vel:Length() * timestep
    local drag = bullet.Drag * spd * spd * (1 / 150000)
    local gravity = timestep * GetConVar("arccw_bullet_gravity"):GetFloat() * (bullet.Gravity or 1)

    if bullet.Underwater then
        drag = drag * 3
    end

    drag = drag * GetConVar("arccw_bullet_drag"):GetFloat()

    if spd <= 0.001 then bullet.Dead = true return end

    local newpos = oldpos + (oldvel * timestep)
    local newvel = oldvel - (dir * drag)
    newvel = newvel - (Vector(0, 0, 1) * gravity)

    if bullet.Imaginary then
        -- the bullet has exited the map, but will continue being visible.
        bullet.Pos = newpos
        bullet.Vel = newvel
        bullet.Travelled = bullet.Travelled + spd

        if CLIENT and !GetConVar("arccw_bullet_imaginary"):GetBool() then
            bullet.Dead = true
        end
    else
        local tr = util.TraceLine({
            start = oldpos,
            endpos = newpos,
            filter = bullet.Attacker,
            mask = MASK_SHOT
        })

        if SERVER then
            debugoverlay.Line(oldpos, tr.HitPos, 5, Color(100,100,255), true)
        else
            debugoverlay.Line(oldpos, tr.HitPos, 5, Color(255,200,100), true)
        end

        if tr.HitSky then
            if CLIENT and GetConVar("arccw_bullet_imaginary"):GetBool() then
                bullet.Imaginary = true
            else
                bullet.Dead = true
            end

            bullet.Pos = newpos
            bullet.Vel = newvel
            bullet.Travelled = bullet.Travelled + spd

            if SERVER then
                bullet.Dead = true
            end
        elseif tr.Hit then
            bullet.Travelled = bullet.Travelled + (oldpos - tr.HitPos):Length()
            bullet.Pos = tr.HitPos
            -- if we're the client, we'll get the bullet back when it exits.
            local attacker = bullet.Attacker
            local eid = tr.Entity:EntIndex()

            if !IsValid(attacker) then
                attacker = game.GetWorld()
            end

            if SERVER then
                debugoverlay.Cross(tr.HitPos, 5, 5, Color(100,100,255), true)
            else
                debugoverlay.Cross(tr.HitPos, 5, 5, Color(255,200,100), true)
            end

            if attacker:IsPlayer() then
                attacker:LagCompensation(true)
            end

            if CLIENT then
                -- do an impact effect and forget about it
                if !game.SinglePlayer() and bullet.PhysBulletImpact then
                    attacker:FireBullets({
                        Src = oldpos,
                        Dir = dir,
                        Distance = spd + 16,
                        Tracer = 0,
                        Damage = 0,
                        IgnoreEntity = bullet.Attacker
                    })
                end
                bullet.Dead = true
                return
            elseif SERVER then
                if IsValid(bullet.Weapon) then
                    bullet.Weapon:GetBuff_Hook("Hook_PhysBulletHit", {bullet = bullet, tr = tr})
                end
                if bullet.PhysBulletImpact then
                    local delta = bullet.Travelled / (bullet.Range / ArcCW.HUToM)
                    delta = math.Clamp(delta, 0, 1)
                    local dmg = Lerp(delta, bullet.DamageMax, bullet.DamageMin)
                    -- deal some damage
                    attacker:FireBullets({
                        Src = oldpos,
                        Dir = dir,
                        Distance = spd + 16,
                        Tracer = 0,
                        Damage = 0,
                        IgnoreEntity = bullet.Attacker,
                        Callback = function(catt, ctr, cdmg)
                            local hit   = {}
                            hit.att     = catt
                            hit.tr      = ctr
                            hit.dmg     = cdmg
                            hit.range   = bullet.Travelled
                            hit.damage  = dmg
                            hit.dmgtype = bullet.DamageType
                            hit.penleft = bullet.Penleft

                            if IsValid(bullet.Weapon) then
                                hit = bullet.Weapon:GetBuff_Hook("Hook_BulletHit", hit)

                                if !hit then return end
                            end

                            if bullet.Damaged[ctr.Entity:EntIndex()] then
                                cdmg:SetDamage(0)
                            else
                                cdmg:SetDamage(dmg)
                                cdmg:SetDamageType(bullet.DamageType)
                            end

                            if bullet.DamageType == DMG_BURN and delta < 1 then
                                cdmg:SetDamageType(DMG_BULLET)

                                if bullet.Num > 1 then
                                    cdmg:SetDamageType(DMG_BUCKSHOT)
                                end

                                if vFireInstalled then
                                    CreateVFire(ctr.Entity, ctr.HitPos, ctr.HitNormal, dmg * 0.02)
                                else
                                    ctr.Entity:Ignite(1, 0)
                                end
                            end

                            ArcCW.TryBustDoor(ctr.Entity, cdmg)

                            if bullet.ImpactEffect then
                                local ed = EffectData()
                                ed:SetOrigin(ctr.HitPos)
                                ed:SetNormal(ctr.HitNormal)

                                util.Effect(bullet.ImpactEffect, ed)
                            end

                            if bullet.ImpactDecal then
                                util.Decal(bullet.ImpactDecal, ctr.StartPos, ctr.HitPos - (ctr.HitNormal * 16), bullet.Attacker)
                            end

                            ArcCW:DoPenetration(ctr, dmg, bullet, bullet.Penleft, true, bullet.Damaged)
                        end
                    }, true)
                end
                bullet.Damaged[eid] = true
                bullet.Dead = true
            end

            if attacker:IsPlayer() then
                attacker:LagCompensation(false)
            end
        else
            -- bullet did not impact anything
            bullet.Pos = tr.HitPos
            bullet.Vel = newvel
            bullet.Travelled = bullet.Travelled + spd

            if bullet.Underwater then
                if bit.band( util.PointContents( tr.HitPos ), CONTENTS_WATER ) != CONTENTS_WATER then
                    local utr = util.TraceLine({
                        start = tr.HitPos,
                        endpos = oldpos,
                        filter = bullet.Attacker,
                        mask = MASK_WATER
                    })

                    if utr.Hit then
                        local fx = EffectData()
                        fx:SetOrigin(utr.HitPos)
                        fx:SetScale(10)
                        util.Effect("gunshotsplash", fx)
                    end

                    bullet.Underwater = false
                end
            else
                if bit.band( util.PointContents( tr.HitPos ), CONTENTS_WATER ) == CONTENTS_WATER then
                    local utr = util.TraceLine({
                        start = oldpos,
                        endpos = tr.HitPos,
                        filter = bullet.Attacker,
                        mask = MASK_WATER
                    })

                    if utr.Hit then
                        local fx = EffectData()
                        fx:SetOrigin(utr.HitPos)
                        fx:SetScale(10)
                        util.Effect("gunshotsplash", fx)
                    end

                    bullet.Underwater = true
                end
            end
        end
    end

    local MaxDimensions = 16384 * 4
    local WorldDimensions = 16384

    if bullet.StartTime <= (CurTime() - GetConVar("arccw_bullet_lifetime"):GetFloat()) then
        bullet.Dead = true
    elseif !indim(bullet.Pos, MaxDimensions) then
        bullet.Dead = true
    elseif !indim(bullet.Pos, WorldDimensions) then
        bullet.Imaginary = true
    end
end

local head = Material("effects/whiteflare")
local tracer = Material("effects/smoke_trail")

function ArcCW:DrawPhysBullets()
    cam.Start3D()
    for _, i in pairs(ArcCW.PhysBullets) do
        if i.StartTime >= CurTime() - 0.1 then
            if i.Travelled <= (i.Vel:Length() * 0.01) then continue end
        end

        local size = 1

        size = size * math.log(EyePos():DistToSqr(i.Pos) - math.pow(256, 2))

        -- print(size)

        size = math.Clamp(size, 0, math.huge)

        local delta = (EyePos():DistToSqr(i.Pos) / math.pow(20000, 2))

        size = math.pow(size, Lerp(delta, 1, 2))

        local pro = (i.Profile + 1) or 1

        if pro == 8 then continue end

        local col = ArcCW.BulletProfiles[pro] or ArcCW.BulletProfiles[1]

        -- cam.Start3D()

        render.SetMaterial(head)
        render.DrawSprite(i.Pos, size, size, col)

        render.SetMaterial(tracer)
        render.DrawBeam(i.Pos, i.Pos - i.Vel:GetNormalized() * math.min(i.Vel:Length() * 0.02, 512), size * 0.75, 0, 1, col)

        -- cam.End3D()
    end
    cam.End3D()
end

hook.Add("PreDrawEffects", "ArcCW_DrawPhysBullets", ArcCW.DrawPhysBullets)

hook.Add("PostCleanupMap", "ArcCW_CleanPhysBullets", function()
    ArcCW.PhysBullets = {}
end)