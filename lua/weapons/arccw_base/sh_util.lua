function SWEP:TableRandom(table)
    return table[math.random(#table)]
end

function SWEP:MyEmitSound(fsound, level, pitch, vol, chan)
    fsound = self:GetBuff_Hook("Hook_TranslateSound", fsound) or fsound

    if istable(fsound) then fsound = self:TableRandom(fsound) end

    if fsound != "" then
		if(self.UseWorldSounds)then
			sound.Play(fsound,self:GetPos(),vol,pitch,1)
		else
			self:EmitSound(fsound, level, pitch, vol, chan or CHAN_AUTO)
		end
    end
end