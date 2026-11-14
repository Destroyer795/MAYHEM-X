--!strict
return function(Arsenal: any, Preferences: any): number
	local checks=0
	local function check(value: boolean, label: string)
		assert(value,label)
		checks+=1
	end
	check(#Arsenal.Firearms==4 and #Arsenal.Melee==3,"Seven distinct weapons")
	local models={}
	for id,base in Arsenal.Items do
		check(not models[base.model],"Distinct source model for "..id)
		models[base.model]=true
		local kits=if base.slot==1 then Arsenal.GunKits else Arsenal.MeleeKits
		for _,kit in kits do
			local item=Arsenal.resolve(id,kit)
			check(table.isfrozen(item),"Frozen life definition")
			check(item.range>0 and item.damage>0 and item.interval>=0.1,"Bounded combat values")
			if item.slot==1 then
				check(item.pellets>=1 and item.pellets<=6 and item.magazine>=1 and item.reload>=1,"Bounded firearm budget")
				check(item.damage==base.damage,"Firearm sidegrades never increase damage")
				if kit=="Precision" then check(item.range>base.range and item.magazine<base.magazine,"Precision tradeoff") end
				if kit=="Quickdraw" then check(item.reload<base.reload and item.range<base.range,"Handling tradeoff") end
			else
				if kit=="Reach" then check(item.range>base.range and item.interval>base.interval,"Reach tradeoff") end
				if kit=="Tempo" then check(item.interval<base.interval and item.damage<base.damage,"Tempo tradeoff") end
			end
		end
	end
	local invalid=Preferences.merge(Preferences.Defaults,{primaryWeapon="Maul",meleeWeapon="Vector",gunKit="Tempo",meleeKit="Precision",damage=999,credits=999})
	check(invalid.primaryWeapon=="Vector" and invalid.meleeWeapon=="Rift","Cross-slot IDs rejected")
	check(invalid.gunKit=="Standard" and invalid.meleeKit=="Balanced","Cross-slot kits rejected")
	check(invalid.damage==nil and invalid.credits==nil,"Client cannot author combat or currency")
	local selected=Preferences.merge(Preferences.Defaults,{primaryWeapon="Breaker",meleeWeapon="Talon",gunKit="Quickdraw",meleeKit="Reach"})
	local gun,melee=Arsenal.loadout(selected)
	selected.primaryWeapon="Needle"
	check(gun.id=="Breaker" and melee.id=="Talon","Selected life definition is detached from later preference edits")
	check(Arsenal.resolve("bad","bad").id=="Vector","Unknown IDs fall back safely")
	check(Arsenal.Items.Vector.magazine==18,"Base balance remains unchanged")
	return checks
end
