--!strict
return function(Rules: any, Config: any): number
	local checks = 0
	local function expect(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	for health = 1, 100, 11 do
		for shield = 0, 40, 5 do
			for amount = 0, 160, 7 do
				local nextHealth, nextShield = Rules.damage(health, shield, amount)
				expect(nextHealth >= 0 and nextHealth <= health, "Health must remain in range")
				expect(nextShield >= 0 and nextShield <= shield, "Shield must remain in range")
				expect(nextHealth + nextShield == math.max(0, health + shield - amount), "Damage must be conserved")
			end
		end
	end
	for ammo = 0, Config.Rifle.Magazine do
		for reserve = 0, Config.Rifle.Reserve do
			local loaded, remaining = Rules.reload(ammo, reserve, Config.Rifle.Magazine)
			expect(loaded + remaining == ammo + reserve, "Reload must conserve ammunition")
			expect(loaded <= Config.Rifle.Magazine and remaining >= 0, "Reload must respect capacity and reserves")
		end
	end
	local accepted, tokens = Rules.spend(3, 10, 10, 2, 3, 1)
	expect(accepted and tokens == 2, "First request must spend a token")
	accepted, tokens = Rules.spend(tokens, 10, 10, 2, 3, 3)
	expect(not accepted and tokens == 2, "Burst requests cannot borrow tokens")
	accepted, tokens = Rules.spend(0, 10, 10.5, 2, 3, 1)
	expect(accepted and tokens == 0, "Tokens must refill at the configured rate")
	accepted, tokens = Rules.spend(0, 10, 100, 2, 3, 4)
	expect(not accepted and tokens == 3, "Idle time cannot exceed burst capacity")
	accepted, tokens = Rules.spend(0, 10, 9, 2, 3, 1)
	expect(not accepted and tokens == 0, "Backwards time cannot mint tokens")
	local done, winner, reason = Rules.outcome({ 7, 9 }, false)
	expect(not done and winner == nil, "Multiple survivors keep the round running")
	done, winner = Rules.outcome({ 7 }, false)
	expect(done and winner == 7, "Exactly one survivor wins")
	done, winner, reason = Rules.outcome({}, false)
	expect(done and winner == nil and reason == "No survivors", "Simultaneous eliminations produce no winner")
	done, winner, reason = Rules.outcome({ 7, 9 }, true)
	expect(done and winner == nil and reason == "Time limit: draw", "Timeout cannot award an arbitrary winner")
	done, winner = Rules.outcome({ 7 }, true)
	expect(done and winner == 7, "A final survivor wins on the timeout tick")
	for _, edge in { { "Waiting", "Intermission" }, { "Intermission", "Waiting" }, { "Intermission", "Loading" }, { "Loading", "Countdown" }, { "Loading", "Results" }, { "Countdown", "Results" }, { "Countdown", "Active" }, { "Active", "Results" }, { "Results", "Waiting" } } do
		expect(Rules.canTransition(edge[1], edge[2]), "Legal transition must be accepted")
	end
	expect(not Rules.canTransition("Active", "Loading"), "An active round cannot load another round")
	expect(not Rules.canTransition("Results", "Results"), "Results cannot be awarded twice")
	expect(not Rules.canTransition("Missing", "Waiting"), "Unknown states must be rejected")
	expect(Rules.finite(0) and Rules.finite(-12.5), "Finite numbers must be accepted")
	expect(not Rules.finite(0 / 0) and not Rules.finite(math.huge) and not Rules.finite(-math.huge), "Non-finite numbers must be rejected")
	expect(not Rules.finite("1") and not Rules.finite({}), "Non-numeric requests must be rejected")
	expect(Config.Match.Capacity == 16 and Config.Match.MinimumPlayers >= 2, "Production rounds need at least two contenders and sixteen slots")
	return checks
end
