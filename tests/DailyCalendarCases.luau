--!strict
return function(Calendar: any,Rules: any,Preferences: any,Visuals: any): number
	local checks=0
	local function check(ok: boolean,message: string) assert(ok,message);checks+=1 end
	local week,index,reset=Calendar.period(4)
	check(week==0 and index==1 and reset==11*86400,"Monday UTC anchor")
	local profile=Rules.default(Preferences)
	for day=4,10 do
		local accepted,reward=Rules.claimDaily(profile,day)
		check(accepted and reward.day==day-3,"Seven scheduled days")
		local before=profile.credits
		check(not Rules.claimDaily(profile,day) and profile.credits==before,"Duplicate request rejected")
		local snapshot=Calendar.snapshot(profile,day*86400+86399)
		check(snapshot.claimed and snapshot.day==day-3,"Claimed tile follows server UTC")
	end
	check(profile.credits==95 and profile.shards==1 and profile.seasonTokens==1,"Weekly economy stays bounded")
	check(profile.owned.Prism and profile.owned.Frostborn and profile.dailyMask==127,"Guaranteed cosmetics and seven bits")
	check(#profile.ledger==7,"Daily rewards have distinct audit entries")
	local reload=Rules.clean(profile,Preferences,Visuals)
	check(reload.owned.Frostborn and not Rules.claimDaily(reload,10),"Serialized claim cannot be replayed")
	check(Rules.claimDaily(reload,11) and reload.dailyMask==1 and reload.owned.Frostborn,"Weekly reset preserves ownership")
	check(Rules.claimDaily(reload,17) and reload.shards==2,"Owned weekly collection gives its disclosed duplicate Shard")
	local missed=Rules.default(Preferences)
	check(Rules.claimDaily(missed,10) and missed.owned.Frostborn,"Sunday reward requires no punitive login streak")
	check(not Rules.claimDaily(missed,9),"Missed days cannot be back-claimed")
	local monday=Calendar.snapshot(missed,11*86400)
	check(monday.day==1 and monday.days[1].status=="AVAILABLE" and monday.days[7].status=="UPCOMING","Week boundary is UTC, not server startup")
	for _,bad in {-1,3.5,math.huge,0/0} do check(not Rules.claimDaily(missed,bad),"Invalid date rejected") end
	local legacy=Rules.clean({version=3,dailyDay=10,owned={Prism=true}},Preferences,Visuals)
	check(legacy.version==4 and legacy.dailyMask==64 and not Rules.claimDaily(legacy,10),"V3 migration preserves the old daily high-water mark")
	check(legacy.owned.Prism,"Migration preserves earned items")
	local cap=Rules.default(Preferences)
	cap.credits,cap.shards,cap.seasonTokens=Rules.MaximumStat,Rules.MaximumStat,Rules.MaximumStat
	local accepted,payout=Rules.claimDaily(cap,9)
	check(accepted and payout.credits==0 and payout.shards==0 and cap.credits==Rules.MaximumStat,"Caps conserve actual ledger deltas")
	check(cap.ledger[1].credits==0 and cap.ledger[1].shards==0,"Cap accounting stays truthful")
	return checks
end
