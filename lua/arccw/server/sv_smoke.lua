if CLIENT then return end

ArcCW.NPCsCache = ArcCW.NPCsCache or {}
local npcs = ArcCW.NPCsCache

ArcCW.SmokeCache = ArcCW.SmokeCache or {}
local smokes = ArcCW.SmokeCache

hook.Add("OnEntityCreated", "ArcCW_NPCSmokeCache", function(ent)
    if !ent:IsValid() then return end

    if ent:IsNPC() then
        npcs[#npcs + 1] = ent
    elseif ent.ArcCWSmoke then
        smokes[#smokes + 1] = ent
    end

end)

hook.Add("EntityRemoved", "ArcCW_NPCSmokeCache", function(ent)
    if ent:IsNPC() then
        table.RemoveByValue(npcs, ent)
    elseif ent.ArcCWSmoke then
        table.RemoveByValue(smokes, ent)
    end
end)


function ArcCW:ProcessNPCSmoke()
    if #npcs == 0 or #smokes == 0 then return end

    for _, npc in ipairs(npcs) do
        local target = npc:GetEnemy()

        if !target or !target:IsValid() then continue end

        npc.ArcCW_Smoked_Time = npc.ArcCW_Smoked_Time or 0
        if npc.ArcCW_Smoked_Time > CurTime() then
            if npc.ArcCW_Smoked then
                if npc.ArcCW_Smoked_Target == target then
                    npc:SetSchedule(SCHED_STANDOFF)
                    debugoverlay.Cross(npc:EyePos(), 5, 0.1, Color(50, 0, 0), true)
                    continue
                end
            elseif npc.ArcCW_Smoked_Target != target then
                if npc.ArcCW_Smoked then
                    npc:SetSchedule(SCHED_IDLE_STAND)
                end
                npc.ArcCW_Smoked = false
            else
                continue
            end
        else
            npc.ArcCW_Smoked = false
        end

        local sr = 256
        local maxs = Vector(sr, sr, sr)
        local mins = -maxs

        local rayEnts = ents.FindAlongRay(npc:EyePos(), target:WorldSpaceCenter(), mins, maxs)
        local anysmoke = false

        for _, i in ipairs(rayEnts) do
            if i.ArcCWSmoke then
                anysmoke = true
                break
            end
        end

        if anysmoke then
            -- print("Smoke!")
            npc.ArcCW_Smoked = true
            npc.ArcCW_Smoked_Target = target
            npc:SetSchedule(SCHED_STANDOFF)
            debugoverlay.Line(npc:EyePos(), target:WorldSpaceCenter(), 1, Color(50, 0, 0), true)
        else
            if npc.ArcCW_Smoked then
                npc:SetSchedule(SCHED_IDLE_STAND)
            end
            npc.ArcCW_Smoked = false
        end

        npc.ArcCW_Smoked_Time = CurTime() + 1
    end
end

hook.Add("Think", "ArcCW_NPCSmoke", ArcCW.ProcessNPCSmoke)