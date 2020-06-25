hook.Add( "OnEntityCreated", "ArcCW_DefaultClip", function(ent)
    if !ent.ArcCW then return end

    if ent.Primary.DefaultClip <= 0 then return end

    ent.Primary.DefaultClip = ent.Primary.ClipSize * 3

   if ent.Primary.ClipSize >= 100 then
      ent.Primary.DefaultClip = ent.Primary.ClipSize * 2
   end
end)