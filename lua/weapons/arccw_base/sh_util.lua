function SWEP:MyEmitSound(soundn, level, pitch, vol, chan)
    if istable(soundn) then
        soundn = table.Random(soundn)
    end

    self:EmitSound(soundn, level, pitch, vol, chan)
end