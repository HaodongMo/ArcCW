function SWEP:MyEmitSound(soundn, level, pitch, vol, chan)
    soundn = self:GetBuff_Hook("Hook_TranslateSound", soundn) or soundn

    if istable(soundn) then
        soundn = table.Random(soundn)
    end

    self:EmitSound(soundn, level, pitch, vol, chan)
end