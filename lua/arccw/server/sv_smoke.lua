function ArcCW:ProcessNPCSmoke()
    for _, npc in pairs(ents.GetAll()) do
        if !npc then continue end
        if !npc:IsValid() then continue end
        if !npc:IsNPC() then continue end

        local target = npc:GetEnemy()

        if !target then continue end
        if !IsValid(target) then continue end

        npc.ArcCW_Smoked_Time = npc.ArcCW_Smoked_Time or 0

        if npc.ArcCW_Smoked then
            if npc.ArcCW_Target == target then
                if npc.ArcCW_Smoked_Time > CurTime() then
                    npc:SetCondition(COND_WEAPON_SIGHT_OCCLUDED)
                    continue
                else
                    npc.ArcCW_Smoked = false
                end
            end
        elseif npc.ArcCW_Smoked_Time > CurTime() then
            continue
        end

        local sr = 450
        local maxs = Vector(sr, sr, sr)
        local mins = -maxs

        local smokes = ents.FindAlongRay(npc:EyePos(), target:WorldSpaceCenter(), mins, maxs)
        local anysmoke = false

        for _, i in pairs(smokes) do
            if i.ArcCWSmoke then anysmoke = true break end
        end

        if anysmoke then
            npc.ArcCW_Smoked = true
            npc.ArcCW_Smoked_Target = target
            npc:SetCondition(COND_WEAPON_SIGHT_OCCLUDED)
        else
            npc.ArcCW_Smoked = false
            npc:SetCondition(COND_WEAPON_HAS_LOS)
        end

        npc.ArcCW_Smoked_Time = CurTime() + 1
    end
end

hook.Add("Think", "ArcCW_NPCSmoke", ArcCW.ProcessNPCSmoke)