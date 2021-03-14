if SERVER then
    util.AddNetworkString("arccw_animation")

    function ArcCW.SendAnimation(ply, slot, sequence, cycle, autokill)
        autokill = autokill or false

        net.Start("arccw_animation")
            net.WriteEntity(ply)
            net.WriteUInt(slot, 3)
            net.WriteUInt(sequence, 10)
            net.WriteFloat(cycle)
            net.WriteBool(autokill)
        net.Broadcast()
    end
else
    net.Receive("arccw_animation", function()
        local ply = net.ReadEntity()
        local slot = net.ReadUInt(3)
        local sequence = net.ReadUInt(10)
        local cycle = net.ReadFloat()
        local bool = net.ReadBool()

        ply:AddVCDSequenceToGestureSlot(slot, sequence, cycle, bool)
    end)
end
