--!strict
return table.freeze({
	Remote = table.freeze({ Action = "Action", State = "State", Effect = "Effect", Feed = "Feed" }),
	Action = table.freeze({ Ready = "Ready", Queue = "Queue", Switch = "Switch", Fire = "Fire", Melee = "Melee", Reload = "Reload", Ability = "Ability" }),
	Phase = table.freeze({ Waiting = "Waiting", Intermission = "Intermission", Loading = "Loading", Countdown = "Countdown", Active = "Active", Results = "Results" }),
})
