--!strict
return function(Service: any,Rules: any,Preferences: any,Visuals: any,Lease: any): number
	local checks=0
	local function check(ok: boolean,message: string) assert(ok,message);checks+=1 end
	local player: any={UserId=777}
	local fixed=10*86400+100
	local function fixture(mode: string)
		local record={profile=Rules.default(Preferences),loaded=true,persistent=true,dirty=false,saving=false,leaving=false,status="READY",version=0,lease="calendar-test",locked=true}
		local stored: any={value=nil,mode=mode,calls=0}
		function stored:UpdateAsync(_key: string,transform: any): any
			self.calls+=1
			if self.mode=="delay" then task.wait(0.15) end
			if self.mode=="fail-before" then error("Injected write failure before commit") end
			local result=transform(self.value)
			if result==nil then return nil end
			self.value=Rules.clean(result,Preferences,Visuals)
			if self.mode=="fail-after" then error("Injected lost response after commit") end
			return self.value
		end
		local lock=Lease.acquire(nil,record.lease,fixed,120)
		local lockStore={UpdateAsync=function(_self: any,_key: string,transform: any) lock=transform(lock);return lock end}
		local service=setmetatable({records={[player]=record},clock=function() return fixed end,store=stored,lockStore=lockStore,notify=function() end},Service)
		return service,record,stored
	end
	local service,record,stored=fixture("success")
	local accepted,reward=service:claimDaily(player)
	check(accepted and reward.skin=="Frostborn" and record.profile.credits==25,"Durable claim applies after confirmation")
	check(stored.value.owned.Frostborn and stored.value.dailyDay==10 and record.status=="SAVED","Stored cursor, balance and ownership agree")
	check(not service:claimDaily(player) and record.profile.credits==25,"Repeated service requests do not grant twice")
	local loaded=Rules.clean(stored.value,Preferences,Visuals)
	check(not Rules.claimDaily(loaded,10),"A fresh service profile cannot replay a committed claim")
	local failed,failedRecord,failedStore=fixture("fail-before")
	check(not failed:claimDaily(player) and failedRecord.profile.credits==0 and not failedRecord.profile.owned.Frostborn,"A failed save never shows a granted reward")
	check(failedRecord.pendingDaily==10 and not failed:canModify(player),"Unknown claims block other profile writes")
	failedStore.mode="success"
	failed:save(player)
	check(failedRecord.profile.credits==25 and failedRecord.pendingDaily==nil,"Autosave recovers the pending claim before ordinary writes")
	local unknown,unknownRecord,unknownStore=fixture("fail-after")
	check(not unknown:claimDaily(player) and unknownRecord.profile.credits==0 and unknownStore.value.credits==25,"Lost response keeps the reward unconfirmed in memory")
	unknownStore.mode="success"
	check(unknown:claimDaily(player) and unknownRecord.profile.credits==25 and unknownStore.value.credits==25,"Idempotent retry does not duplicate the committed reward")
	check(#unknownRecord.profile.ledger==1 and #unknownStore.value.ledger==1,"Unknown-outcome recovery conserves the transaction")
	local parallel,parallelRecord=fixture("delay")
	local done,first=false,false
	task.spawn(function() first=parallel:claimDaily(player);done=true end)
	task.wait(0.02)
	check(not parallel:claimDaily(player),"A simultaneous claim sees the transaction gate")
	local deadline=os.clock()+2
	while not done and os.clock()<deadline do task.wait(0.02) end
	check(done and first and parallelRecord.profile.credits==25,"The in-flight request grants exactly once")
	local session,sessionRecord=fixture("success")
	sessionRecord.persistent=false
	local sessionOk,_,notice=session:claimDaily(player)
	check(sessionOk and notice:find("SESSION PREVIEW",1,true)~=nil and sessionRecord.status:find("SESSION ONLY",1,true)~=nil,"Local preview never claims durable storage")
	return checks
end
