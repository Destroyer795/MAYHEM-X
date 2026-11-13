--!strict
local SessionLease = {}

function SessionLease.acquire(current: any, owner: string, now: number, ttl: number): any
	if type(current) == "table" and type(current.expiresAt) == "number" and current.expiresAt < math.huge and current.expiresAt > now and current.owner ~= owner then return current end
	return { owner = owner, expiresAt = now + ttl }
end

function SessionLease.renew(current: any, owner: string, now: number, ttl: number): any
	if type(current) ~= "table" or current.owner ~= owner then return current end
	return { owner = owner, expiresAt = now + ttl }
end

function SessionLease.release(current: any, owner: string): any
	if type(current) ~= "table" or current.owner ~= owner then return current end
	return { owner = "", expiresAt = 0 }
end

return table.freeze(SessionLease)
