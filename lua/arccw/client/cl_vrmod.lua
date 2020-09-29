local function addmenu()
    if !vrmod then return end

    vrmod.AddInGameMenuItem("ArcCW Customize", 3, 1, function()
        local wep = LocalPlayer():GetActiveWeapon()

        if !IsValid(wep) or !wep.ArcCW then return end

        wep:ToggleCustomizeHUD(!IsValid(ArcCW.InvHUD))
    end)
end

hook.Add("VRMod_Start", "ArcCW", addmenu)