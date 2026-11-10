--!strict
local StyleRules = {}

function StyleRules.new(): any
	return { skin = "Pulse", operative = "Vanguard", owned = { Pulse = true, Glacier = true }, dailyDay = -1, revision = 0 }
end

function StyleRules.apply(record: any, catalog: any, command: any, payload: any, day: number): (boolean, string)
	if command == "Select" then
		if type(payload) ~= "table" or type(payload.id) ~= "string" or #payload.id > 24 then return false, "Invalid style selection." end
		if payload.kind == "skin" and catalog.skin(payload.id) and record.owned[payload.id] then
			record.skin = payload.id
		elseif payload.kind == "operative" and catalog.operative(payload.id) then
			record.operative = payload.id
		else return false, "Claim this style before equipping it." end
		record.revision += 1
		return true, "Style equipped. Combat stats are unchanged."
	elseif command == "Claim" then
		if type(payload) ~= "string" or #payload > 24 then return false, "Invalid collection item." end
		local entry = catalog.skin(payload)
		if not entry or entry.source ~= "shop" then return false, "This style is not a Style Lab item." end
		if record.owned[payload] then return true, "Already in your session collection." end
		record.owned[payload] = true
		record.revision += 1
		return true, "Added to your session collection. Select it in Collection."
	elseif command == "Daily" then
		if record.dailyDay == day then return false, "Cache already claimed for today in this server." end
		record.dailyDay = day
		record.owned.Prism = true
		record.revision += 1
		return true, "Prism trial added for this server session."
	end
	return false, "Unknown presentation request."
end

return table.freeze(StyleRules)
