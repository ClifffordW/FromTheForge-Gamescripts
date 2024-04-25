return {
	-- For how long we've been in the 'deposit_currency' state, how many ticks between 'proc'
	-- Start slow to allow precision, but when the player has held for a while speed up because we know they're trying to spend a lot.
	{ ticksinstate = 60, ticks_between_proc = 0, deposits_per_proc = 3 },
	{ ticksinstate = 50, ticks_between_proc = 0, deposits_per_proc = 2 },
	{ ticksinstate = 40, ticks_between_proc = 0, deposits_per_proc = 1 },
	{ ticksinstate = 20, ticks_between_proc = 1, deposits_per_proc = 1 },
	{ ticksinstate = 10, ticks_between_proc = 2, deposits_per_proc = 1 },
	{ ticksinstate = 0, ticks_between_proc = 3, deposits_per_proc = 1 },
}
