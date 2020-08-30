local function addmenu()
    if not vrmod then return end

    vrmod.AddInGameMenuItem("ArcCW Customize", 3, 1, function()
        local wep = LocalPlayer():GetActiveWeapon()

        if not IsValid(wep) or not wep.ArcCW then return end

        wep:ToggleCustomizeHUD(not IsValid(ArcCW.InvHUD))
    end)
end

hook.Add("VRMod_Start", "ArcCW", addmenu)