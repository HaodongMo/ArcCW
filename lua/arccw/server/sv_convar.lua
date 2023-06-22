if CLIENT then return end

net.Receive("arccw_sendconvar", function(len, ply)
    local command = net.ReadString()

    if !ply:IsAdmin() then return end
    if game.SinglePlayer() then return end
    if string.sub(command, 1, 5) != "arccw" then return end

    local cmds = string.Split(command, " ")

    local timername = "change" .. cmds[1]

    if timer.Exists(timername) then
        timer.Remove(timername)
    end

    local args = {}
    for i, k in pairs(cmds) do
        if k == " " then continue end
        k = string.Trim(k, " ")

        table.insert(args, k)
    end

    timer.Create(timername, 0.25, 1, function()
        RunConsoleCommand(args[1], args[2])
        print("Changed " .. args[1] .. " to " .. args[2] .. ".")
    end)
end)