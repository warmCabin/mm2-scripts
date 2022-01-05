
local names = {
  "Mega Buster",
  "Atomic Fire",
  "Air Shooter",
  "Leaf Shield",
  "Bubble Lead",
  "Quick Boomerang",
  "Time Stopper",
  "Metal Blade",
  "Crash Bomber"
}

emu.registerafter(function()

  local weaponIndex = memory.readbyte(0xA9)
  local name = names[weaponIndex + 1] -- Mega Man 2 is a good game that indexes its shit by 0.
  
  gui.text(10, 20, string.format("($%02X)", memory.readbyte(0xA9)))
  
  if name then 
    gui.text(10, 10, name)
  else
    gui.text(10, 10, string.format("Item %d", weaponIndex - 8))
  end

end)
