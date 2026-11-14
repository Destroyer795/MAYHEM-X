--!strict
return function(Rules: any, Visuals: any): number
	local count = 0
	local function expect(value: boolean) assert(value, "Session cosmetic rule failed"); count += 1 end
	local record = Rules.new()
	expect(record.owned.Pulse and record.owned.Glacier and not record.owned.Orchid)
	local accepted = Rules.apply(record, Visuals, "Select", { kind = "skin", id = "Orchid" }, 1)
	expect(not accepted and record.skin == "Pulse")
	accepted = Rules.apply(record, Visuals, "Claim", "Orchid", 1)
	expect(accepted and record.owned.Orchid)
	local revision = record.revision
	Rules.apply(record, Visuals, "Claim", "Orchid", 1)
	expect(record.revision == revision)
	accepted = Rules.apply(record, Visuals, "Select", { kind = "skin", id = "Orchid" }, 1)
	expect(accepted and record.skin == "Orchid")
	revision = record.revision
	Rules.apply(record, Visuals, "Select", { kind = "skin", id = "Orchid" }, 1)
	expect(record.revision == revision)
	accepted = Rules.apply(record, Visuals, "Select", { kind = "operative", id = "Spectre" }, 1)
	expect(accepted and record.operative == "Spectre")
	for _, payload in { "Prism", "Pulse", "not-an-item", {}, 100 } do
		accepted = Rules.apply(record, Visuals, "Claim", payload, 1)
		expect(not accepted)
	end
	accepted = Rules.apply(record, Visuals, "Select", { kind = "damage", id = "Pulse" }, 1)
	expect(not accepted and record.damage == nil)
	accepted = Rules.apply(record, Visuals, "Select", { kind = "operative", id = string.rep("X", 100) }, 1)
	expect(not accepted)
	accepted = Rules.apply(record, Visuals, "Daily", nil, 1)
	expect(not accepted and not record.owned.Prism and record.dailyDay == -1)
	revision = record.revision
	accepted = Rules.apply(record, Visuals, "Daily", nil, 1)
	expect(not accepted and record.revision == revision)
	accepted = Rules.apply(record, Visuals, "Daily", nil, 2)
	expect(not accepted and record.dailyDay == -1)
	expect(Rules.new().dailyDay == -1 and not Rules.new().owned.Orchid)
	accepted = Rules.apply(record, Visuals, "RewardKills", { kills = 1000 }, 2)
	expect(not accepted and record.kills == nil)
	return count
end
