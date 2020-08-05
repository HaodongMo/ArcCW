if not vrmod then return end

timer.Simple(0,function()
    --[[]
    vrmod.AddInGameMenuItem("ArcCW Customize", 6, 0, function()
        local wpn = LocalPlayer():GetActiveWeapon()
        if not IsValid(wpn) or not wpn.ArcCW then return end

        wpn:ToggleCustomizeHUD(not IsValid(ArcCW.InvHUD))
    end)
    ]]
end)