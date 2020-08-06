local function addmenu()
    if not vrmod then return end
    vrmod.AddInGameMenuItem("ArcCW Customize", 3, 1, function()
        local wpn = LocalPlayer():GetActiveWeapon()
        if not IsValid(wpn) or not wpn.ArcCW then return end

        wpn:ToggleCustomizeHUD(not IsValid(ArcCW.InvHUD))
    end)
end

hook.Add("VRMod_Start", "ArcCW", addmenu)