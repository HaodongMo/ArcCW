function SWEP:TableRandom(table)
    return table[math.random(#table)]
end

function SWEP:MyEmitSound(fsound, level, pitch, vol, chan)
    -- some retard made this "sound". Fuck you, whoever did that.
    fsound = self:GetBuff_Hook("Hook_TranslateSound", fsound) or fsound

    if istable(fsound) then fsound = self:TableRandom(fsound) end

    self:EmitSound(fsound, level, pitch, vol, chan or CHAN_AUTO)
end