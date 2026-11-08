WorldModelRegistry = {}
WorldModelRegistry.Entries = {}
WorldModelRegistry.RawRemove = removeWorldModel
WorldModelRegistry.RawRestore = restoreWorldModel

local function getKey(model, x, y, z)
	return ("%s_%s_%s_%s"):format(tostring(model), tostring(x), tostring(y), tostring(z))
end

function removeWorldModel(model, radius, x, y, z, interior)
	local result = WorldModelRegistry.RawRemove(model, radius, x, y, z, interior)
	if result then
		WorldModelRegistry.Entries[getKey(model, x, y, z)] = {model, radius, x, y, z, interior or 0}
	end
	return result
end

function restoreWorldModel(model, radius, x, y, z, interior)
	local result = WorldModelRegistry.RawRestore(model, radius, x, y, z, interior)
	if result then
		WorldModelRegistry.Entries[getKey(model, x, y, z)] = nil
	end
	return result
end

function WorldModelRegistry.getOutdoorEntries()
	local list = {}
	for _, entry in pairs(WorldModelRegistry.Entries) do
		if (entry[6] == 0 or entry[6] == -1) and entry[2] < 1000 then
			list[#list + 1] = entry
		end
	end
	return list
end
