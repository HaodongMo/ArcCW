function SWEP:TableRandom(table)
    return table[math.random(#table)]
end

function SWEP:MyEmitSound(fsound, level, pitch, vol, chan, useWorld)
    fsound = self:GetBuff_Hook("Hook_TranslateSound", fsound) or fsound

    if istable(fsound) then fsound = self:TableRandom(fsound) end

    if fsound != "" then
		if useWorld then
			sound.Play(fsound, self.Owner:GetShootPos(), level, pitch, vol)
		else
			self:EmitSound(fsound, level, pitch, vol, chan or CHAN_AUTO)
		end
    end
end