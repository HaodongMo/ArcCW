if game.SinglePlayer() then

hook.Add("EntityTakeDamage", "ArcCW_ETD", function(npc, dmg)
    timer.Simple(0, function()
        if !IsValid(npc) then return end
        if npc:Health() <= 0 then
            net.Start("arccw_sp_health")
            net.WriteEntity(npc)
            net.Broadcast()
        end
    end)
end)

end