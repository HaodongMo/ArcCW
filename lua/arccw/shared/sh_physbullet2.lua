ArcCW.PhysBullets = {
}

-- intentionally not 10 despite there being 10 default profiles.
-- for some reason profile indices are previously referenced as zero-indexed but stored as one-indexed
ArcCW.BulletProfileNum = 9
ArcCW.BulletProfileBits = nil
ArcCW.BulletProfiles = {
    [0] = "default0",
    [1] = "default1",
    [2] = "default2",
    [3] = "default3",
    [4] = "default4",
    [5] = "default5",
    [6] = "default6",
    [7] = "default7",
    [8] = "default8",
    [9] = "default9",
}
ArcCW.BulletProfileDict = {
    ["default0"] = {id = 0, name = "default0", color = Color(255, 225, 200)},
    ["default1"] = {id = 1, name = "default1", color = Color(255, 0, 0)},
    ["default2"] = {id = 2, name = "default2", color = Color(0, 255, 0)},
    ["default3"] = {id = 3, name = "default3", color = Color(0, 0, 255)},
    ["default4"] = {id = 4, name = "default4", color = Color(255, 255, 0)},
    ["default5"] = {id = 5, name = "default5", color = Color(255, 0, 255)},
    ["default6"] = {id = 6, name = "default6", color = Color(0, 255, 255)},
    ["default7"] = {id = 7, name = "default7", color = Color(0, 0, 0)},
    ["default8"] = {id = 8, name = "default8", color = Color(100, 255, 100)},
    ["default9"] = {id = 9, name = "default9", color = Color(100, 0, 255)},
--[[]
    ["profile_name"] = {
        color = Color(255, 255, 255),
        sprite_head = Material("effects/whiteflare"), -- set false to not draw a sprite, set nil to use default
        sprite_tail = Material("effects/smoke_trail"), -- ditto
        size = 1, -- Size growth factor of the physbullet (from distance)
        size_min = 1, -- Base size of the physbullet
        tail_length = 0.02, -- as a fraction of the bullet's velocity
        model = "models/weapons/w_bullet.mdl", -- clientside model is not created without this path
        model_nodraw = false, -- true to not draw model
        particle = "myparticle", -- requires a model path; set to nodraw if you don't wish it to be visible

        ThinkBullet = function(bulinfo, bullet) end, -- set bullet.Dead = true to stop processing and delete bullet.
        DrawBullet = function(bulinfo, bullet) end, -- return true to prevent default drawing behavior
        PhysBulletHit = function(bulinfo, bullet, tr) end,
    }
]]
}

local vector_down = Vector(0, 0, 1)

function ArcCW:AddBulletProfile(name, bulinfo)

    if istable(name) and !bulinfo then
        bulinfo = name
        name = tostring(ArcCW.BulletProfileNum + 1)
    end

    local new = !ArcCW.BulletProfileDict[name]
    if new then
        ArcCW.BulletProfileNum = ArcCW.BulletProfileNum + 1
        ArcCW.BulletProfiles[ArcCW.BulletProfileNum] = name
        ArcCW.BulletProfileBits = nil
    end
    ArcCW.BulletProfileDict[name] = bulinfo
    if new then
        ArcCW.BulletProfileDict[name].name = name
        ArcCW.BulletProfileDict[name].id = ArcCW.BulletProfileNum
    end
end

function ArcCW:BulletProfileBitNecessity()
    if !ArcCW.BulletProfileBits then
        ArcCW.BulletProfileBits = math.min(math.ceil(math.log(ArcCW.BulletProfileNum + 1, 2)), 32)
    end
    return ArcCW.BulletProfileBits
end

function ArcCW:SendBullet(bullet, attacker)
    net.Start("arccw_sendbullet", true)
    net.WriteVector(bullet.Pos)
    net.WriteAngle(bullet.Vel:Angle())
    net.WriteFloat(bullet.Vel:Length())
    net.WriteFloat(bullet.Drag)
    net.WriteFloat(bullet.Gravity)
    net.WriteUInt(bullet.Profile or 0, ArcCW:BulletProfileBitNecessity())
    net.WriteBool(bullet.PhysBulletImpact)
    net.WriteEntity(bullet.Weapon)

    if attacker and attacker:IsValid() and attacker:IsPlayer() and !game.SinglePlayer() then
        net.SendOmit(attacker)
    else
        if game.SinglePlayer() then
            net.WriteEntity(attacker)
        end
        net.Broadcast()
    end
end

function ArcCW:ShootPhysBullet(wep, pos, vel, prof, ovr)
    ovr = ovr or {}
    local pbi = ovr.PhysBulletImpact or wep:GetBuff_Override("Override_PhysBulletImpact")
    local num = ovr.Num or wep:GetBuff("Num")

    if !prof then
        prof = wep:GetBuff_Override("Override_PhysTracerProfile", wep.PhysTracerProfile) or 1
    end
    if isstring(prof) then
        prof = ArcCW.BulletProfileDict[prof].id
    end

    local bullet = {
        DamageMax = wep:GetDamage(0) / num,
        DamageMin = wep:GetDamage(math.huge) / num,
        Range = wep:GetBuff("Range"),
        DamageType = wep:GetBuff_Override("Override_DamageType", wep.DamageType),
        Penleft = wep:GetBuff("Penetration"),
        Penetration = wep:GetBuff("Penetration"),
        ImpactEffect = wep:GetBuff_Override("Override_ImpactEffect", wep.ImpactEffect),
        ImpactDecal = wep:GetBuff_Override("Override_ImpactDecal", wep.ImpactDecal),
        PhysBulletImpact = pbi == nil and true or pbi,
        Gravity = wep:GetBuff("PhysBulletGravity"),
        HullSize = wep:GetBuff("HullSize"),
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
        Filter = {wep:GetOwner()},
        Damaged = {},
        Burrowing = false,
        Dead = false,
        Profile = prof
    }
    table.Merge(bullet, ovr)

    table.Add(bullet.Filter, wep.Shields or {})

    local owner = wep:GetOwner()

    --[[]
    if owner and owner:IsNPC() then
        bullet.DamageMax = bullet.DamageMax * GetConVar("arccw_mult_npcdamage"):GetFloat()
        bullet.DamageMin = bullet.DamageMin * GetConVar("arccw_mult_npcdamage"):GetFloat()
    end
    ]]

    if SERVER and owner and owner:IsPlayer() then
        table.Add(bullet.Filter, ArcCW:GetVehicleFilter(owner) or {})
    end

    if bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER then
        bullet.Underwater = true
    end

    table.insert(ArcCW.PhysBullets, bullet)

    -- TODO: This is still bad but unless we can access FLOW_OUTGOING from inside INetChannelInfo I can't think of any better way to do this.
    if owner:IsPlayer() and SERVER then
        --local ping = owner:Ping() / 1000
        --ping = math.Clamp(ping, 0, 0.5)

        -- local latency = util.TimeToTicks((owner:Ping() / 1000) * 0.5)
        local latency = math.floor(engine.TickCount() - owner:GetCurrentCommand():TickCount() - 1) -- FIXME: this math.floor does nothing
        local timestep = engine.TickInterval()

        while latency > 0 do
            ArcCW:ProgressPhysBullet(bullet, timestep)
            latency = latency - 1
        end

        -- while ping > 0 do
        --     ArcCW:ProgressPhysBullet(bullet, timestep)
        --     ping = ping - timestep
        -- end
    end

    if SERVER then
        -- ArcCW:ProgressPhysBullet(bullet, engine.TickInterval())
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
    local profile = net.ReadUInt(ArcCW:BulletProfileBitNecessity())
    local impact = net.ReadBool()
    local weapon = net.ReadEntity()
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
        Attacker = ent or weapon:GetOwner(),
        Gravity = grav,
        Profile = profile,
        PhysBulletImpact = impact,
        Weapon = weapon,
        Filter = {weapon:GetOwner()},
    }

    if bit.band( util.PointContents( pos ), CONTENTS_WATER ) == CONTENTS_WATER then
        bullet.Underwater = true
    end

    table.insert(ArcCW.PhysBullets, bullet)
end)

end

function ArcCW:DoPhysBullets()
    local new = {}
    local deltatime = engine.TickInterval()

    for _, i in pairs(ArcCW.PhysBullets) do
        ArcCW:ProgressPhysBullet(i, deltatime)
        -- On the client, bullets must live for at least one tick so we get to render it
        -- This prevents invisible tracers up close
        if !i.Dead or (CLIENT and CurTime() - i.StartTime <= engine.TickInterval()) then
            table.insert(new, i)
        elseif CLIENT and IsValid(i.CSModel) then
            i.CSModel:Remove()
            if i.CSParticle then
                i.CSParticle:StopEmission()
                i.CSParticle = nil
            end
        end
    end

    ArcCW.PhysBullets = new
end

hook.Add("Tick", "ArcCW_DoPhysBullets", ArcCW.DoPhysBullets)

local function indim(vec, maxdim)
    if math.abs(vec.x) > maxdim or math.abs(vec.y) > maxdim or math.abs(vec.z) > maxdim then
        return false
    else
        return true
    end
end

local ArcCW_BulletGravity = GetConVar("arccw_bullet_gravity")
local ArcCW_BulletDrag = GetConVar("arccw_bullet_drag")
function ArcCW:ProgressPhysBullet(bullet, timestep)
    if bullet.Dead then return end

    local oldpos = bullet.Pos
    local oldvel = bullet.Vel
    local dir = bullet.Vel:GetNormalized()
    local spd = bullet.Vel:Length() * timestep
    local drag = bullet.Drag * spd * spd * (1 / 150000)
    local gravity = timestep * ArcCW_BulletGravity:GetFloat() * (bullet.Gravity or 1)

    local attacker = bullet.Attacker

    if !IsValid(attacker) then
        bullet.Dead = true
        return
    end

    if bullet.Underwater then
        drag = drag * 3
    end

    drag = drag * ArcCW_BulletDrag:GetFloat()

    if spd <= 0.001 then bullet.Dead = true return end

    local bulinfo = ArcCW.BulletProfileDict[ArcCW.BulletProfiles[bullet.Profile or 1] or ""]
    if bulinfo == nil then
        return
    end
    if bulinfo.ThinkBullet then
        bulinfo:ThinkBullet(bullet)
    end

    local newpos = oldpos + (oldvel * timestep)
    local newvel = oldvel - (dir * drag)
    newvel = newvel - (vector_down * gravity)

    if bullet.Imaginary then
        -- the bullet has exited the map, but will continue being visible.
        bullet.Pos = newpos
        bullet.Vel = newvel
        bullet.Travelled = bullet.Travelled + spd

        if CLIENT and !GetConVar("arccw_bullet_imaginary"):GetBool() then
            bullet.Dead = true
        end
    else
        if attacker:IsPlayer() then
            attacker:LagCompensation(true)
        end

        local tr
        if bullet.HullSize then
            local bb = Vector(bullet.HullSize / 2, bullet.HullSize / 2, bullet.HullSize / 2)
            tr = util.TraceHull({
                start = oldpos,
                endpos = newpos,
                filter = bullet.Filter,
                mask = MASK_SHOT,
                mins = -bb,
                maxs = bb,
            })
            if GetConVar("arccw_dev_shootinfo"):GetInt() > 0 then
                debugoverlay.Line(oldpos, tr.HitPos, 5, SERVER and Color(100,100,255) or Color(255,200,100), true)
                debugoverlay.Box(tr.HitPos, -bb, bb, 5, SERVER and Color(100,100,255,0) or Color(255,200,100,0))
            end
        else
            tr = util.TraceLine({
                start = oldpos,
                endpos = newpos,
                filter = bullet.Filter,
                mask = MASK_SHOT
            })
            if GetConVar("arccw_dev_shootinfo"):GetInt() > 0 then
                debugoverlay.Line(oldpos, tr.HitPos, 5, SERVER and Color(100,100,255) or Color(255,200,100), true)
                debugoverlay.Cross(tr.HitPos, 16, 0.05, SERVER and Color(100,100,255) or Color(255,200,100), true)
            end
        end

        if attacker:IsPlayer() then
            attacker:LagCompensation(false)
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

            if attacker:IsPlayer() then
                attacker:LagCompensation(true)
            end

            if SERVER then
                debugoverlay.Cross(tr.HitPos, 5, 5, Color(100,100,255), true)
            else
                debugoverlay.Cross(tr.HitPos, 5, 5, Color(255,200,100), true)
            end

            local eid = tr.Entity:EntIndex()

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
                if IsValid(bullet.Weapon) then
                    bullet.Weapon:GetBuff_Hook("Hook_PhysBulletHit", {bullet = bullet, tr = tr})
                end
                if bullet.PhysBulletHit then
                    bullet:PhysBulletHit(bullet, tr)
                end
                if bulinfo.PhysBulletHit then
                    bulinfo:PhysBulletHit(bullet, tr)
                end
                return
            elseif SERVER then
                local dmgtable
                if IsValid(bullet.Weapon) then
                    bullet.Weapon:GetBuff_Hook("Hook_PhysBulletHit", {bullet = bullet, tr = tr})

                    dmgtable = bullet.Weapon.BodyDamageMults
                    dmgtable = bullet.Weapon:GetBuff_Override("Override_BodyDamageMults") or dmgtable
                end
                if bullet.PhysBulletHit then
                    bullet:PhysBulletHit(bullet, tr)
                end
                if bullet.PhysBulletImpact then

                    local delta = bullet.Travelled / (bullet.Range / ArcCW.HUToM)
                    delta = math.Clamp(delta, 0, 1)
                    -- deal some damage
                    attacker:FireBullets({
                        Src = oldpos,
                        Dir = dir,
                        Distance = spd + 16,
                        Tracer = 0,
                        Damage = 0,
                        IgnoreEntity = bullet.Attacker,
                        Callback = function(catt, ctr, cdmg)
                            ArcCW:BulletCallback(catt, ctr, cdmg, bullet, true)
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

    bullet.OldPos = oldpos

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

local head = Material("particle/fire")
local tracer = Material("effects/smoke_trail")

function ArcCW:DrawPhysBullets()
    cam.Start3D()
    for _, i in pairs(ArcCW.PhysBullets) do

        local pro = i.Profile or 1
        if pro == 7 then continue end -- legacy behavior: 7 is the "invisible" tracer
        local bulinfo = ArcCW.BulletProfileDict[ArcCW.BulletProfiles[pro] or ""]

        if bulinfo == nil then
            print("Failed to find bullet info for profile " .. tostring(i) .. "!")
            continue
        end

        -- Draw function override
        if bulinfo.DrawBullet and bulinfo:DrawBullet(i) then
            continue
        end

        i.VelStart = i.VelStart or Vector(i.Vel)
        i.PosStart = i.PosStart or Vector(i.Pos)

        local rpos = i.Pos

        local vel = i.Vel - LocalPlayer():GetVelocity()
        local veldir = vel:GetNormalized()
        local dampfraction = 1

        -- Solve two problems presented by physbullets
        -- 1: they come out of the player's eyes and it looks jarring
        -- 2: they fly too fast and so tracers aren't that noticeable
        if !i.DampenVelocity then i.DampenVelocity = math.Clamp(math.floor(i.VelStart:Length() ^ (bulinfo.dampen_factor or 0.65)), 128, 4096) end
        if !i.Imaginary and i.Travelled <= i.DampenVelocity then
            if IsValid(i.Weapon) and i.Weapon:GetOwner() == LocalPlayer() then
                -- Lerp towards the muzzle position, effectively slowing and dragging the bullet back.
                -- Bullet will appear to accelerate suddenly near the threshold, but it should be too fast to notice.

                if !i.TracerOrigin then
                    i.TracerOrigin = i.Weapon:GetTracerOrigin() or i.StartPos
                end

                dampfraction = (i.Travelled / i.DampenVelocity) ^ 0.5
                rpos = LerpVector(dampfraction, i.TracerOrigin or i.PosStart, i.Pos)

                if GetConVar("developer"):GetInt() >= 2 then
                    debugoverlay.Cross(i.TracerOrigin, 2, 5, Color(255, 0, 0), true)
                    debugoverlay.Cross(rpos, 8, 5, Color(0, 255, 255), true)
                    debugoverlay.Line(rpos, i.Pos, 5, Color(250, 150, 255), true)
                    debugoverlay.Cross(i.Pos, 4, 5, Color(255, 0, 255), true)
                    debugoverlay.Text(rpos, math.Round(dampfraction, 2), 5)
                end
            else
                -- don't draw too close to the firing position if we can't lerp, or it will look ugly
                continue
            end
        end

        local col = bulinfo.color

        -- TODO: Tracer sizes are still kinda wacky
        local sqrdist = EyePos():DistToSqr(rpos)
        local distgrow = math.log(sqrdist) ^ 0.5
        local size = math.max(0, (bulinfo.size_min or 1) * 0.25 + (bulinfo.size or 1) * distgrow)
        local headsize = size * math.Clamp(sqrdist / 4000000, 1, 16)

        -- Head is less visible on the sides; it's mostly useful for the shooter and target as tracers aren't very visible from front and back
        local dot = EyeAngles():Forward():Dot(veldir)
        dot = math.Clamp(((dot * dot) - 0.5) * 2, 0, 1)
        headsize = headsize * dot
        --size = size * math.Clamp(1 - dot, 0.5, 1)

        if bulinfo.sprite_head != false then
            render.SetMaterial(bulinfo.sprite_head or head)
            render.DrawSprite(rpos, headsize, headsize, col)
        end

        if bulinfo.sprite_tracer != false and !GetConVar("arccw_fasttracers"):GetBool() then
            render.SetMaterial(bulinfo.sprite_tracer or tracer)
            local len = math.min(vel:Length() * (bulinfo.tail_length or 0.015), 512, (rpos - (i.TracerOrigin or i.PosStart)):Length())
            local pos2 = rpos - veldir * len
            if i.TracerOrigin and CurTime() - i.StartTime <= engine.TickInterval() then
                pos2 = rpos - (rpos - i.TracerOrigin):GetNormalized() * len
            end
            render.DrawBeam(rpos, pos2, size * 0.25, 0, 0.5, col)
            debugoverlay.Line(rpos, pos2, 7, Color(0, 255, 0), true)
        end

        if bulinfo.model then
            if !IsValid(i.CSModel) then
                i.CSModel = ClientsideModel(bulinfo.model)
                i.CSModel:SetNoDraw(bulinfo.model_nodraw)
                if bulinfo.particle then
                    i.CSParticle = CreateParticleSystem(i.CSModel, bulinfo.particle, PATTACH_ABSORIGIN_FOLLOW, 1)
                end
            end
            i.CSModel:SetPos(rpos)
            i.CSModel:SetAngles(i.Vel:Angle())
            i.CSModel:SetVelocity(i.Vel)
            if i.CSParticle then
                i.CSParticle:StartEmission()
                i.CSParticle:SetSortOrigin(IsValid(i.Weapon) and i.Weapon:GetShootSrc() or vector_origin)
            end
        end
    end
    cam.End3D()
end

hook.Add("PreDrawEffects", "ArcCW_DrawPhysBullets", ArcCW.DrawPhysBullets)

hook.Add("PostCleanupMap", "ArcCW_CleanPhysBullets", function()
    ArcCW.PhysBullets = {}
end)

-- Can't run now or files after this in load order cannot add them properly
hook.Add("InitPostEntity", "ArcCW_AddPhysBullets", function()
    hook.Run("ArcCW_InitBulletProfiles")
end)