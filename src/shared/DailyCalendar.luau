--!strict
local Calendar = {}
Calendar.Version = 1
Calendar.DaySeconds = 86400
Calendar.MondayEpochDay = 4
Calendar.Rewards = table.freeze({
	table.freeze({day=1,name="FIELD SUPPLY",credits=5,rarity="Common"}),
	table.freeze({day=2,name="CREDIT RESERVE",credits=8,rarity="Common"}),
	table.freeze({day=3,name="SEASON SUPPLY",credits=10,seasonTokens=1,rarity="Uncommon"}),
	table.freeze({day=4,name="ARMORY FUND",credits=12,rarity="Uncommon"}),
	table.freeze({day=5,name="PRISM CACHE",credits=15,skin="Prism",rarity="Rare"}),
	table.freeze({day=6,name="CHAOS RESERVE",credits=20,shards=1,rarity="Epic"}),
	table.freeze({day=7,name="FROSTBORN COLLECTION",credits=25,skin="Frostborn",duplicateShards=1,rarity="Legendary"}),
})

function Calendar.period(day: number): (number,number,number)
	local week=math.floor((day-Calendar.MondayEpochDay)/7)
	local index=(day-Calendar.MondayEpochDay)%7+1
	return week,index,(Calendar.MondayEpochDay+(week+1)*7)*Calendar.DaySeconds
end

function Calendar.migrate(profile: any, source: any)
	local week,index=Calendar.period(profile.dailyDay)
	if type(source.dailyWeek)=="number" and source.dailyWeek%1==0 and source.dailyWeek>=-1 and source.dailyWeek<=100_000_000
		and type(source.dailyMask)=="number" and source.dailyMask%1==0 and source.dailyMask>=0 and source.dailyMask<=127 then
		profile.dailyWeek,profile.dailyMask=source.dailyWeek,source.dailyMask
	elseif profile.dailyDay>=0 then profile.dailyWeek,profile.dailyMask=week,bit32.lshift(1,index-1) end
end

function Calendar.snapshot(profile: any, now: number): any
	local day=math.floor(now/Calendar.DaySeconds)
	local week,index,reset=Calendar.period(day)
	local mask=if profile.dailyWeek==week then profile.dailyMask else 0
	if profile.dailyDay==day then mask=bit32.bor(mask,bit32.lshift(1,index-1)) end
	local days={}
	for i,reward in Calendar.Rewards do
		local claimed=bit32.band(mask,bit32.lshift(1,i-1))~=0
		local status=if claimed then "CLAIMED" elseif i==index then "AVAILABLE" elseif i<index then "PASSED" else "UPCOMING"
		days[i]={day=i,status=status,reward=reward}
	end
	return {week=week,day=index,serverNow=now,resetAt=reset,nextDaily=(day+1)*Calendar.DaySeconds,claimed=days[index].status=="CLAIMED",days=days}
end

function Calendar.grant(profile: any, day: number, cap: number): (boolean,any)
	if type(day)~="number" or day%1~=0 or day<0 or day>100_000_000 or day<=profile.dailyDay then return false,nil end
	local week,index=Calendar.period(day)
	local mask=if profile.dailyWeek==week then profile.dailyMask else 0
	local bit=bit32.lshift(1,index-1)
	if bit32.band(mask,bit)~=0 then return false,nil end
	local reward=Calendar.Rewards[index]
	local result={id="daily:"..day,day=index,name=reward.name,credits=0,shards=0,seasonTokens=0}
	local duplicate=reward.skin~=nil and profile.owned[reward.skin]==true
	for _,currency in {"credits","shards","seasonTokens"} do
		local amount=(reward[currency] or 0)+(if currency=="shards" and duplicate then reward.duplicateShards or 0 else 0)
		local delta=math.min(amount,cap-profile[currency])
		profile[currency]+=delta
		result[currency]=delta
	end
	if reward.skin and not duplicate then profile.owned[reward.skin]=true; result.skin=reward.skin end
	result.duplicate=duplicate
	profile.dailyDay,profile.dailyWeek,profile.dailyMask=day,week,bit32.bor(mask,bit)
	return true,result
end

return table.freeze(Calendar)
