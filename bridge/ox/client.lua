if GetResourceState("ox_core") ~= "started" then error("ox_core is not started") end

local ox = {}

return ox