local M = {}

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

function M.run()
	local miru = require "miru"

	local count = miru.signal(1)
	assert_equal(count(), 1, "signal reads initial value")
	count(2)
	assert_equal(count(), 2, "signal writes next value")

	local effect_runs = 0
	local observed
	local effect = miru.effect(function()
		effect_runs = effect_runs + 1
		observed = count()
	end)
	assert_equal(effect_runs, 1, "effect runs immediately")
	assert_equal(observed, 2, "effect observes signal")
	count(3)
	assert_equal(effect_runs, 2, "effect reruns after signal write")
	assert_equal(observed, 3, "effect observes updated signal")
	effect:stop()
	count(4)
	assert_equal(effect_runs, 2, "stopped effect does not rerun")

	local memo_runs = 0
	local doubled = miru.memo(function()
		memo_runs = memo_runs + 1
		return count() * 2
	end)
	assert_equal(memo_runs, 0, "memo is lazy before first read")
	assert_equal(doubled(), 8, "memo computes on first read")
	assert_equal(memo_runs, 1, "memo computed once")
	assert_equal(doubled(), 8, "memo returns cached value")
	assert_equal(memo_runs, 1, "memo cache is reused")
	count(5)
	assert_equal(memo_runs, 1, "memo is invalidated lazily")
	assert_equal(doubled(), 10, "memo recomputes after dependency changes")
	assert_equal(memo_runs, 2, "memo recomputed once after invalidation")

	local source = miru.signal(2)
	local plus_runs = 0
	local plus_one = miru.memo(function()
		plus_runs = plus_runs + 1
		return source() + 1
	end)
	local chain_runs = 0
	local chained = miru.memo(function()
		chain_runs = chain_runs + 1
		return plus_one() * 3
	end)
	assert_equal(chained(), 9, "chained memo computes through dependency")
	assert_equal(plus_runs, 1, "source memo runs once")
	assert_equal(chain_runs, 1, "chained memo runs once")
	source(3)
	assert_equal(plus_runs, 1, "source memo invalidates lazily")
	assert_equal(chain_runs, 1, "chained memo invalidates lazily")
	assert_equal(chained(), 12, "chained memo recomputes through invalidated dependency")
	assert_equal(plus_runs, 2, "source memo recomputes once")
	assert_equal(chain_runs, 2, "chained memo recomputes once")

	local use_left = miru.signal(true)
	local left = miru.signal "left"
	local right = miru.signal "right"
	local branch_runs = 0
	local selected = miru.memo(function()
		branch_runs = branch_runs + 1
		return use_left() and left() or right()
	end)
	assert_equal(selected(), "left", "branch memo reads active branch")
	assert_equal(branch_runs, 1, "branch memo runs once")
	right "unused"
	assert_equal(selected(), "left", "inactive branch write does not invalidate memo")
	assert_equal(branch_runs, 1, "inactive branch dependency is not tracked")
	use_left(false)
	assert_equal(selected(), "unused", "branch switch reads right branch")
	assert_equal(branch_runs, 2, "branch switch invalidates memo")
	left "unused-left"
	assert_equal(selected(), "unused", "old branch write does not invalidate memo")
	assert_equal(branch_runs, 2, "old branch dependency was cleaned up")

	local batched_runs = 0
	local batched_value
	local batched = miru.signal(0)
	miru.effect(function()
		batched_runs = batched_runs + 1
		batched_value = batched()
	end)
	assert_equal(batched_runs, 1, "batched effect starts once")
	miru.batch(function()
		batched(1)
		batched(2)
	end)
	assert_equal(batched_runs, 2, "batched writes rerun effect once")
	assert_equal(batched_value, 2, "batched effect observes final value")

	local untracked_runs = 0
	local untracked_source = miru.signal "a"
	miru.effect(function()
		untracked_runs = untracked_runs + 1
		miru.untrack(function()
			return untracked_source()
		end)
	end)
	assert_equal(untracked_runs, 1, "untracked effect starts once")
	untracked_source "b"
	assert_equal(untracked_runs, 1, "untracked read does not subscribe effect")

	assert_equal(miru.get(42), 42, "get returns static value")
	assert_equal(miru.get(count), 5, "get reads signal value")
end

return M
