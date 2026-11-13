--!strict
return function(Lease: any): number
	local acquired = Lease.acquire(nil, "server-a", 100, 120)
	assert(acquired.owner == "server-a" and acquired.expiresAt == 220, "A new lease must belong to its server for the configured lifetime")
	assert(Lease.acquire(acquired, "server-b", 150, 120) == acquired, "An active foreign lease cannot be stolen")
	local expired = Lease.acquire(acquired, "server-b", 221, 120)
	assert(expired.owner == "server-b" and expired.expiresAt == 341, "An expired lease must permit a new server")
	local renewed = Lease.renew(acquired, "server-a", 200, 120)
	assert(renewed.owner == "server-a" and renewed.expiresAt == 320, "The owning server must be able to renew its lease")
	assert(Lease.renew(acquired, "server-b", 200, 120) == acquired, "A foreign server cannot renew another owner's lease")
	local released = Lease.release(acquired, "server-a")
	assert(released ~= nil and released.expiresAt == 0, "Release must write an expired record, because nil would cancel UpdateAsync")
	assert(Lease.acquire(released, "server-b", 150, 120).owner == "server-b", "A released lease must allow immediate rejoin without waiting for expiry")
	assert(Lease.release(acquired, "server-b") == acquired, "Release cannot clear another server's lease")
	assert(Lease.acquire({ owner = "corrupt", expiresAt = math.huge }, "server-a", 100, 120).owner == "server-a", "Invalid infinite expiry data cannot lock a profile forever")
	assert(Lease.release(nil, "server-a") == nil, "Releasing a missing lease must leave it missing")
	return 10
end
