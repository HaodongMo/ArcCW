hook.Add("EntityTakeDamage", "ArcCW_DoAttDMG", function(ent, dmg)
    if !ent:IsPlayer() then return end

    local wpn = ent:GetActiveWeapon()

    if !wpn.ArcCW then return end

    for i, k in pairs(wpn.Attachments) do
        if !k.Installed then continue end
        local atttbl = ArcCW.AttachmentTable[k.Installed]

        if atttbl.Hook_PlayerTakeDamage then
            atttbl.Hook_PlayerTakeDamage(wpn, {slot = i, atthp = k.HP, dmg = dmg})
        end
    end

    wpn:SendAttHP()
end)