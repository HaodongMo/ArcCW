function SWEP:TableRandom(table)
	return table[math.random(#table)]
end

function SWEP:MyEmitSound(sound, level, pitch, vol, chan)
    sound = self:GetBuff_Hook("Hook_TranslateSound", sound) or sound

    if istable(sound) then sound = self:TableRandom(sound) end

    self:EmitSound(sound, level, pitch, vol, chan or CHAN_AUTO)
end