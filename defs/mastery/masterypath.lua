local MasteryPath = {
	Paths = {},
}

function MasteryPath.AddPath(condition, masteries)
	local mp = { fn = condition, masteries = masteries }
	table.insert(MasteryPath.Paths, mp)
end

function MasteryPath.EvaluatePaths(player)
	-- print("--------------------------------------------")
	-- printf("Evaluate Mastery Paths For Player [%s]", player)
	for _, path in ipairs(MasteryPath.Paths) do
		if path.fn(player) then
			local mastery_manager = player.components.masterymanager
			for _, mastery_name in ipairs(path.masteries) do
				local mastery = mastery_manager:GetMasteryByName(mastery_name)
				-- printf("> Checking Mastery %s...", mastery_name)
				if mastery and not mastery:IsClaimed() then
					-- you're currently on this mastery, but you haven't finished it yet.
					-- break out of the loop
					-- printf(">> Has Mastery %s, but is not finished/ claimed.", mastery_name)
					break
				end

				if not mastery then
					-- you got this far in the loop and found a mastery you don't have yet.
					-- that must mean you've completed all other masteries so far in the path
					-- grant the new mastery, then break the loop.
					-- printf(">> Doesn't have mastery %s, granting it.", mastery_name)
					mastery_manager:AddMasteryByName(mastery_name)
					break
				end
			end
		end
	end
end

-- Hammer Masteries

MasteryPath.AddPath(function(player) return true end,-- player:IsWeaponTypeUnlocked(WEAPON_TYPES.HAMMER) end,
{
	"hammer_focus_multiple_targets",
	"hammer_air_spin",
	"hammer_focus_hits",
	"hammer_focus_hits_destructibles",
	"hammer_thump",
	"hammer_golf_swing",
})

MasteryPath.AddPath(function(player) return player:HasDoneMastery('hammer_focus_hits') end,
{
	"hammer_hitstreak_basic",
	"hammer_hitstreak_fading_L",
	"hammer_hitstreak_advanced"
})

-- Polearm Masteries

MasteryPath.AddPath(function(player) return true end,--player:IsWeaponTypeUnlocked(WEAPON_TYPES.POLEARM) end,
{
	"polearm_focus_hits_tip",
	"polearm_drill_multiple_enemies_basic",
	"polearm_focus_kills",
	"polearm_multithrust_focus",
	"polearm_shove_counterattack",
	"polearm_single_hit",
})

MasteryPath.AddPath(function(player) return player:HasDoneMastery('polearm_focus_kills') end,
{
	"polearm_hitstreak_basic",
	"polearm_hitstreak_advanced",
	"polearm_hitstreak_expert"
})

-- Cannon Masteries

MasteryPath.AddPath(function(player) return true end,--player:IsWeaponTypeUnlocked(WEAPON_TYPES.CANNON) end,
{
	"cannon_perfect_dodge",
	"cannon_quick_rise",
})
MasteryPath.AddPath(function(player) return true end,--player:IsWeaponTypeUnlocked(WEAPON_TYPES.CANNON) end,
{
	"cannon_perfect_reload",
	"cannon_butt_reload",
	"cannon_focus",
	"cannon_focus_shockwave",
})

MasteryPath.AddPath(function(player) return player:HasDoneMastery('cannon_butt_reload') end,
{	"cannon_hitstreak_basic",
	"cannon_hitstreak_heavy",
	"cannon_hitstreak_advanced",
})

-- Shotput Masteries

MasteryPath.AddPath(function(player) return true end,
{
	"shotput_focus_thrown",
	"shotput_focus_spiked",
	"shotput_focus_kills",
	"shotput_focus_rebound",
	"shotput_recall", -- skill use
	"shotput_juggle_melee_kill", -- an extra challenge
})

MasteryPath.AddPath(function(player) return player:HasDoneMastery('shotput_focus_spiked') end,
{
	"shotput_hitstreak_basic",
	"shotput_hitstreak_melee",
	"shotput_hitstreak_master"
})

-- General Masteries
MasteryPath.AddPath(function(player) return true end,
{
	"perfect_dodge",
	"critical_hit",
})

MasteryPath.AddPath(function(player) return true end,
{
	"quick_rise",
	"dodge_cancel",
	"dodge_cancel_on_hit",
	"hitstreak_props",
	"dodge_cancel_hitstreak",
	"dodge_cancel_perfect",
	"hitstreak_perfect_dodge",
})

-- Boss Masteries
MasteryPath.AddPath(function(player) return true end,--player:IsLocationUnlocked("treemon_forest") end,
{
	"megatreemon_kill",
	"megatreemon_kill_ascension_1",
	"megatreemon_kill_ascension_2",
	"megatreemon_kill_ascension_3",
})

MasteryPath.AddPath(function(player) return player:IsLocationUnlocked("owlitzer_forest") end,
{
	"owlitzer_kill",
	"owlitzer_kill_ascension_1",
	"owlitzer_kill_ascension_2",
	"owlitzer_kill_ascension_3",
})

MasteryPath.AddPath(function(player) return player:IsLocationUnlocked("bandi_swamp") end,
{
	"bandicoot_kill",
	"bandicoot_kill_ascension_1",
	"bandicoot_kill_ascension_2",
	"bandicoot_kill_ascension_3",
})

MasteryPath.AddPath(function(player) return player:IsLocationUnlocked("thatcher_swamp") end,
{
	"thatcher_kill",
	"thatcher_kill_ascension_1",
	"thatcher_kill_ascension_2",
	"thatcher_kill_ascension_3",
})

return MasteryPath
