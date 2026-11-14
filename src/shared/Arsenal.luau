--!strict
local Config = require(script.Parent.Config)
local Arsenal = {}
Arsenal.Firearms = table.freeze({"Vector", "Needle", "Mantis", "Breaker"})
Arsenal.Melee = table.freeze({"Rift", "Talon", "Maul"})
Arsenal.GunKits = table.freeze({"Standard", "Precision", "Quickdraw"})
Arsenal.MeleeKits = table.freeze({"Balanced", "Reach", "Tempo"})
Arsenal.Items = table.freeze({
	Vector = table.freeze({id="Vector", name="VECTOR-18", category="ASSAULT RIFLE", model="VectorRifle", slot=1, damage=Config.Rifle.Damage, interval=Config.Rifle.Interval, range=Config.Rifle.Range, magazine=Config.Rifle.Magazine, reserve=Config.Rifle.Reserve, reload=Config.Rifle.ReloadTime, pellets=1, spread=0, size=Vector3.new(0.5,1,3.5), recoil=1, description="Balanced automatic fire. A reliable general-purpose rifle."}),
	Needle = table.freeze({id="Needle", name="NEEDLE-30", category="SUBMACHINE GUN", model="NeedleSMG", slot=1, damage=12, interval=0.115, range=180, magazine=30, reserve=120, reload=2, pellets=1, spread=1.2, size=Vector3.new(0.5,1,2.7), recoil=0.6, description="Fast close-range pressure. More rounds, wider dispersion."}),
	Mantis = table.freeze({id="Mantis", name="MANTIS-10", category="MARKSMAN RIFLE", model="MantisDMR", slot=1, damage=36, interval=0.4, range=300, magazine=10, reserve=60, reload=2.2, pellets=1, spread=0.1, size=Vector3.new(0.55,1.15,4.8), recoil=1.7, description="Deliberate precision shots. High impact, a small magazine and slower handling."}),
	Breaker = table.freeze({id="Breaker", name="BREAKER-6", category="SCATTERGUN", model="BreakerShotgun", slot=1, damage=12, interval=0.85, range=90, magazine=6, reserve=36, reload=2.6, pellets=6, spread=6, size=Vector3.new(0.7,1.3,3.3), recoil=2.2, description="Six server-cast pellets per shell. Dominates close lanes, loses consistency at distance."}),
	Rift = table.freeze({id="Rift", name="RIFT BLADE", category="SWORD", model="RiftBlade", slot=2, damage=Config.Blade.Damage, interval=Config.Blade.Interval, range=Config.Blade.Range, dot=Config.Blade.MinimumDot, size=Vector3.new(0.75,4.1,0.3), description="Long, controlled cuts. Balanced reach and recovery."}),
	Talon = table.freeze({id="Talon", name="TALON", category="COMBAT KNIFE", model="TalonKnife", slot=2, damage=24, interval=0.43, range=5.8, dot=0.35, size=Vector3.new(0.5,1.8,0.22), description="Quick close-range strikes. Short reach demands commitment."}),
	Maul = table.freeze({id="Maul", name="GRAV-MAUL", category="IMPACT HAMMER", model="MaulHammer", slot=2, damage=54, interval=1.05, range=7.2, dot=0.4, size=Vector3.new(1.9,3.5,0.8), description="Heavy, deliberate impacts. Strong hits with a long recovery window."}),
})
Arsenal.KitDescriptions = table.freeze({
	Standard="Factory balance. Full magazine and standard reload.",
	Precision="Optic and stabilizer: 12% more range, 20% smaller magazine. No damage bonus.",
	Quickdraw="Compact stock: 15% faster reload, 15% less range. No damage bonus.",
	Balanced="Standard guard and grip. Original reach and recovery.",
	Reach="Extended haft: +0.7 stud reach, 15% slower recovery.",
	Tempo="Light grip: 15% faster recovery, 15% less damage.",
})

function Arsenal.valid(key: string, value: any): boolean
	if type(value) ~= "string" then return false end
	local list = if key=="primaryWeapon" then Arsenal.Firearms elseif key=="meleeWeapon" then Arsenal.Melee elseif key=="gunKit" then Arsenal.GunKits elseif key=="meleeKit" then Arsenal.MeleeKits else nil
	return list ~= nil and table.find(list, value) ~= nil
end

function Arsenal.resolve(id: string?, kit: string?): any
	local base = Arsenal.Items[id or "Vector"] or Arsenal.Items.Vector
	local item = table.clone(base)
	item.kit = if base.slot==1 then (if table.find(Arsenal.GunKits, kit) then kit else "Standard") else (if table.find(Arsenal.MeleeKits, kit) then kit else "Balanced")
	if item.kit=="Precision" then item.range*=1.12; item.magazine=math.max(1,math.floor(item.magazine*0.8)); item.recoil*=0.8
	elseif item.kit=="Quickdraw" then item.reload*=0.85; item.range*=0.85
	elseif item.kit=="Reach" then item.range+=0.7; item.interval*=1.15
	elseif item.kit=="Tempo" then item.interval*=0.85; item.damage=math.floor(item.damage*0.85) end
	return table.freeze(item)
end

function Arsenal.loadout(preferences: any): (any, any)
	return Arsenal.resolve(if Arsenal.valid("primaryWeapon", preferences.primaryWeapon) then preferences.primaryWeapon else "Vector", preferences.gunKit), Arsenal.resolve(if Arsenal.valid("meleeWeapon", preferences.meleeWeapon) then preferences.meleeWeapon else "Rift", preferences.meleeKit)
end

return table.freeze(Arsenal)
