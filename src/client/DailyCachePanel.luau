--!strict
local TweenService=game:GetService("TweenService")
local Theme=require(script.Parent.Theme)
local Preview=require(script.Parent.Preview)
local Panel={}
local weekday={"MON","TUE","WED","THU","FRI","SAT","SUN"}

local function place(item: GuiObject,x: number,y: number,w: number,h: number)
	item.Position,item.Size=UDim2.fromOffset(math.round(x),math.round(y)),UDim2.fromOffset(math.max(0,math.round(w)),math.max(0,math.round(h)))
end

local function amounts(reward: any,owned: any): string
	local parts={tostring(reward.credits).." CREDITS"}
	local shards=(reward.shards or 0)+(if reward.skin and owned[reward.skin] then reward.duplicateShards or 0 else 0)
	if shards>0 then table.insert(parts,shards.." CHAOS SHARD"..(if shards>1 then "S" else "")) end
	if (reward.seasonTokens or 0)>0 then table.insert(parts,reward.seasonTokens.." SEASON TOKEN"..(if reward.seasonTokens>1 then "S" else "")) end
	if reward.skin and not owned[reward.skin] then table.insert(parts,string.upper(reward.skin).." FINISH") end
	return table.concat(parts,"\n")
end

function Panel.build(self: any,page: Frame)
	self.dailyTitle=Theme.text(page,"Title","DAILY CACHE",UDim2.new(),UDim2.new(),32,Theme.Ink,true)
	self.dailySubtitle=Theme.text(page,"Subtitle","SEVEN UTC DAYS. GUARANTEED REWARDS.",UDim2.new(),UDim2.new(),11,Theme.Cyan)
	self.dailyStorage=Theme.text(page,"StorageStatus","",UDim2.new(),UDim2.new(),12,Theme.Muted)
	self.dailyProgress=Theme.bar(page,"CalendarProgress",UDim2.new(),UDim2.new(),Theme.Action)
	self.dailyProgressText=Theme.text(page,"ProgressLabel","",UDim2.new(),UDim2.new(),12,Theme.Muted)
	local rail=Instance.new("ScrollingFrame")
	rail.Name,rail.BackgroundTransparency,rail.BorderSizePixel="WeekRail",1,0
	rail.ScrollingDirection,rail.ScrollBarThickness=Enum.ScrollingDirection.X,1
	rail.ScrollBarImageColor3=Theme.Metal
	rail.Parent=page
	self.dailyRail=rail
	self.dailyTiles={}
	for day=1,7 do
		local tile=Theme.button(page,"Day"..day,"",UDim2.new(),UDim2.new(),function()
			if day==7 then self.draftShop="Frostborn";self.collectionFilter="SIGNATURE";self:open("Shop")
			else self.dailyFocus=day end
		end,true)
		local border=tile:FindFirstChildOfClass("UIStroke")
		local name=Theme.text(tile,"Day",string.format("DAY %02d",day),UDim2.fromOffset(14,12),UDim2.new(1,-28,0,22),16,Theme.Ink,true)
		local status=Theme.text(tile,"Status","",UDim2.fromOffset(14,38),UDim2.new(1,-28,0,18),10,Theme.Muted)
		local glyph=Theme.text(tile,"RewardGlyph","",UDim2.fromOffset(14,60),UDim2.new(1,-28,0,40),30,Theme.Action,true)
		glyph.Font=Theme.FontNumeric
		Theme.icon(tile,if day==6 then 4 elseif day==7 or day==5 then 3 else 9)
		local icon=tile.Icon
		icon.Position,icon.Size=UDim2.new(1,-35,0,67),UDim2.fromOffset(16,16)
		local reward=Theme.text(tile,"Reward","",UDim2.fromOffset(14,105),UDim2.new(1,-28,0,54),12,Theme.Ink,true)
		local rarity=Theme.text(tile,"Rarity","",UDim2.new(0,14,1,-26),UDim2.new(1,-28,0,18),10,Theme.Muted)
		self.dailyTiles[day]={tile=tile,name=name,status=status,glyph=glyph,reward=reward,rarity=rarity,border=border}
	end
	self.dailyFeature=Preview.new(self.dailyTiles[7].tile)
	self.dailyFeature.frame.Name="WeeklyRewardPreview"
	self.dailyFeature.frame.ZIndex=2
	self.dailyInspect=Theme.button(page,"InspectWeekly","INSPECT WEEKLY REWARD",UDim2.new(),UDim2.new(),function()
		self.draftShop="Frostborn";self.collectionFilter="SIGNATURE";self:open("Shop")
	end,true)
	self.dailyClock=Theme.text(page,"Clock","",UDim2.new(),UDim2.new(),12,Theme.Muted)
	self.dailyButton=Theme.button(page,"Claim","CLAIM REWARD",UDim2.new(),UDim2.new(),function() self.callbacks.daily() end)
	self.dailyReveal=Theme.frame(page,"RewardReceipt",UDim2.new(),UDim2.new(),Theme.Panel)
	self.dailyReveal.Visible=false
	self.dailyReveal.ZIndex=8
	self.dailyReceiptTitle=Theme.text(self.dailyReveal,"Title","",UDim2.fromOffset(18,10),UDim2.new(1,-72,0,24),18,Theme.Action,true)
	self.dailyReceiptBody=Theme.text(self.dailyReveal,"Details","",UDim2.fromOffset(18,40),UDim2.new(1,-36,0,50),13,Theme.Ink)
	self.dailyReceiptTitle.ZIndex,self.dailyReceiptBody.ZIndex=9,9
	local dismiss=Theme.button(self.dailyReveal,"Dismiss","X",UDim2.new(1,-44,0,5),UDim2.fromOffset(38,38),function() self.dailyReveal.Visible=false end,true)
	dismiss.ZIndex=9
end

function Panel.render(self: any,style: any)
	if self.page~="Daily" then return end
	local page=self.pages.Daily
	local w=page.AbsoluteSize.X
	local compact=w<650
	local calendar=style.profile and style.profile.calendar
	local owned=style.owned or {}
	place(self.dailyTitle,0,0,w,40)
	place(self.dailySubtitle,0,46,w,22)
	place(self.dailyProgress.Parent,0,if compact then 696 else 82,w*(if compact then 1 else 0.66),3)
	place(self.dailyProgressText,0,if compact then 704 else 89,w,32)
	local tileW=if compact then (w-10)/2 else (w*0.66-20)/3
	local tileH=if compact then 166 else 162
	local gridY=124
	for day=1,6 do
		local entry=self.dailyTiles[day]
		entry.tile.Parent=if compact then self.dailyRail else page
		local column=if compact then (day-1)%2 else (day-1)%3
		local row=math.floor((day-1)/(if compact then 2 else 3))
		place(entry.tile,if compact then (day-1)*154 else column*(tileW+10),if compact then 0 else gridY+row*(tileH+10),if compact then 146 else tileW,tileH)
		place(entry.glyph,14,58,(if compact then 146 else tileW)-28,30)
		place(entry.reward,14,96,(if compact then 146 else tileW)-28,42)
	end
	self.dailyRail.Visible=compact
	place(self.dailyRail,0,160,w,176)
	self.dailyRail.CanvasSize=UDim2.fromOffset(6*154,0)
	local featureY=if compact then 354 else gridY
	local featureX=if compact then 0 else w*0.66+16
	local featureW=if compact then w else w-featureX
	local featureH=if compact then 202 else tileH*2+10
	place(self.dailyTiles[7].tile,featureX,featureY,featureW,featureH)
	place(self.dailyFeature.frame,4,52,featureW-8,featureH-140)
	self.dailyTiles[7].glyph.Visible=false
	place(self.dailyTiles[7].reward,14,featureH-82,featureW-28,54)
	if compact then
		place(self.dailyFeature.frame,featureW*0.44,54,featureW*0.56-8,featureH-68)
		place(self.dailyTiles[7].reward,14,68,featureW*0.42-14,100)
		place(self.dailyTiles[7].rarity,14,featureH-40,featureW*0.42,28)
	else
		place(self.dailyTiles[7].rarity,14,featureH-26,featureW-28,18)
	end
	local bottom=if compact then featureY+featureH+14 else gridY+tileH*2+24
	place(self.dailyButton,0,bottom,if compact then w else w*0.42,48)
	if compact then place(self.dailyButton,0,106,w,44) end
	place(self.dailyInspect,if compact then 0 else w*0.45,bottom,w*(if compact then 1 else 0.55),48)
	place(self.dailyClock,0,bottom+(if compact then 54 else 58),w,42)
	if compact then
		place(self.dailyProgress.Parent,0,bottom+104,w,3)
		place(self.dailyProgressText,0,bottom+112,w,32)
	end
	place(self.dailyStorage,if compact then 0 else w*0.48,if compact then 72 else 0,w*(if compact then 1 else 0.52),if compact then 30 else 58)
	if not compact and self.content.AbsoluteSize.Y<550 then
		place(self.dailyTitle,0,0,w*0.63,40)
		place(self.dailyButton,w*0.65,0,w*0.35,44)
		place(self.dailyStorage,w*0.65,52,w*0.35,66)
		place(self.dailySubtitle,0,46,w*0.62,28)
		place(self.dailyProgressText,0,89,w*0.64,32)
	end
	page.Size=UDim2.fromOffset(w,math.max(page.Size.Y.Offset,bottom+(if compact then 164 else 172)))
	place(self.dailyReveal,0,math.min(bottom,self.content.CanvasPosition.Y+70),w,104)
	if not calendar then
		self.dailyButton.Active=false;self.dailyButton.Text="AVAILABLE SOON"
		self.dailyStorage.Text="Waiting for the server profile and UTC calendar."
		return
	end
	local claimed=0
	self.dailySubtitle.Text=string.format("DAY %02d / %s / RESET %s UTC",calendar.day,weekday[calendar.day],os.date("!%d %b 00:00",calendar.resetAt))
	if compact and self.dailyRailWeek~=calendar.week then
		self.dailyRailWeek=calendar.week
		self.dailyRail.CanvasPosition=Vector2.new(math.clamp((math.min(calendar.day,6)-1)*154,0,math.max(0,6*154-w)),0)
	end
	for day,entry in self.dailyTiles do
		local data=calendar.days[day]
		local active=day==calendar.day
		if data.status=="CLAIMED" then claimed+=1 end
		entry.name.Text=string.format("DAY %02d / %s",day,weekday[day])
		entry.status.Text=data.status..(if active then " / TODAY" else "")
		entry.glyph.Text="+"..data.reward.credits
		entry.status.TextColor3=if data.status=="CLAIMED" then Theme.Action elseif active then Theme.Cyan else Theme.Muted
		entry.tile.BackgroundColor3=if active then Theme.Navy else Theme.Panel
		entry.tile.BackgroundTransparency=if active or day==7 then 0 else 0.4
		entry.border.Color=if day==7 then Theme.Gold else Theme.Cyan
		entry.border.Transparency=if active or self.dailyFocus==day then 0 elseif day==7 then 0.35 else 0.88
		entry.reward.Text=data.reward.name.."\n"..amounts(data.reward,owned)
		entry.rarity.Text=string.upper(data.reward.rarity)..(if day==7 then " / GUARANTEED" else "")
	end
	self.dailyProgress.Size=UDim2.fromScale(claimed/7,1)
	self.dailyProgressText.Text=claimed.." / 7 CLAIMED THIS WEEK / NO LOGIN STREAK REQUIRED"
	self.dailyButton.Active=(style.ready or style.profile.dailyRecovery) and not style.profile.dailyBusy and (not calendar.claimed or style.profile.dailyRecovery)
	self.dailyButton.Text=if style.profile.dailyBusy then "CONFIRMING REWARD..." elseif style.profile.dailyRecovery then "RETRY CLAIM" elseif calendar.claimed then "CLAIMED" else "CLAIM REWARD"
	local now=calendar.serverNow+math.max(0,os.clock()-(style.receivedAt or os.clock()))
	self.dailyClock.Text="WEEKLY RESET / "..os.date("!%d %b %Y 00:00 UTC",calendar.resetAt).."\nNEXT UTC DAY / "..math.max(0,math.floor((calendar.nextDaily-now)/3600)).."h "..math.max(0,math.floor((calendar.nextDaily-now)%3600/60)).."m"
	self.dailyStorage.Text=if style.profile.persistent then "PROFILE / "..style.profile.status.." / CURRENT UTC DAY ONLY"
		else "SESSION PREVIEW / REWARDS ARE NOT SAVED\nLocal Studio claims reset after leaving."
	self.dailyStorage.TextColor3=if style.profile.persistent then Theme.Muted else Theme.Cyan
	self.dailyFeature:show("weapon","Vanguard","Frostborn",1,"Vector","Standard")
	local receipt=style.dailyReward
	if receipt and self.dailyReceiptId~=receipt.id then
		self.dailyReceiptId=receipt.id
		self.dailyReveal.Visible=true
		self.dailyReceiptTitle.Text=string.format("DAY %02d / REWARD CONFIRMED",receipt.day)
		self.dailyReceiptBody.Text=amounts(receipt,{}):gsub("\n"," / ").."\n"..(if style.profile.persistent then "Saved to your profile." else "Session preview only. Not saved.")
		local tile=self.dailyTiles[receipt.day].tile
		local scale=tile:FindFirstChildOfClass("UIScale")
		if scale and not self.reducedMotion then scale.Scale=1.035;TweenService:Create(scale,TweenInfo.new(0.3),{Scale=1}):Play() end
	end
end

return Panel
