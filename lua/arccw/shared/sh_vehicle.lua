-- returns a table of entities to ignore (the player's vehicle)
function ArcCW:GetVehicleFilter(ply)
    if !GetConVar("arccw_driveby"):GetBool() or !IsValid(ply) or !ply:IsPlayer() then return {} end

    local tbl = {}
    local veh = ply:GetVehicle()

    if simfphys then
        -- gredwitch, why do you think it's a good idea to create the simfphys table yourself???
        -- people might need to do dependency checks, you know
        local car = ply.GetSimfphys and ply:GetSimfphys()
        if IsValid(car) then
            table.insert(tbl, car)
            if SERVER then
                table.insert(tbl, car.DriverSeat)
                for _, seat in ipairs(car.pSeat) do
                    table.insert(tbl, seat)
                    if IsValid(seat:GetDriver()) then
                        table.insert(tbl, seat:GetDriver())
                    end
                end
                table.Add(tbl, car.Wheels or {})
            else
                table.insert(tbl, veh) -- should be the pod
                -- client doesn't know what the wheels/passenger seats are
                -- iterate over all wheels and seats. inefficient, but its client so whatever
                for _, w in ipairs(ents.FindByClass("gmod_sent_vehicle_fphysics_wheel")) do
                    if w:GetBaseEnt() == car then
                        table.insert(tbl, w)
                    end
                end
                for _, s in ipairs(ents.FindByClass("prop_vehicle_prisoner_pod")) do
                    if s:GetParent() == car then
                        table.insert(tbl, s)
                        if IsValid(s:GetDriver()) then
                            table.insert(tbl, s:GetDriver())
                        end
                    end
                end
            end
        elseif IsValid(veh) then
            table.insert(tbl, veh)
        end
    elseif IsValid(veh) then
        table.insert(tbl, veh)
    end

    return tbl
end

-- returns a new source to fire from, this should be moved right outside the vehicle
-- since we can't ignore multiple entities in FireBullets, this is the only solution
function ArcCW:GetVehicleFireTrace(ply, src, dir)
    if !GetConVar("arccw_driveby"):GetBool() then return src end
    local tbl = ArcCW:GetVehicleFilter(ply)
    if table.Count(tbl) == 0 then return src end

    -- Make some traces from the outside to find a good spot
    local trace_dist = {256, 128, 64}
    for i = 1, #trace_dist do
        local tr = util.TraceLine({
            start = src + dir * trace_dist[i],
            endpos = src,
            ignoreworld = true,
            mask = MASK_SHOT
        })
        if IsValid(tr.Entity) and table.HasValue(tbl, tr.Entity) then
            return tr.HitPos + tr.HitNormal * 4
        end
    end
    return src
end