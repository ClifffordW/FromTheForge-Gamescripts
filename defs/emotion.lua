-- All emotions can be triggered from conversations with !
-- agent:
--		!happy
--		!clap
--		Woo hoo!
local emotion = {
	-- emote: An animation expressing a feeling.
	emote = {
		angry = "angry",
		clap = "clap",
		dejected = "dejected",
		dubious = "dubious",
		gesture = "gesture",
		greet = "greet",
		point = "point",
		shrug = "shrug",
		think = "think",

		takeitem = "takeitem", -- takes an item and then puts it away
		eat = "eat", -- takes an item and then eats it
		laugh = "laugh",
		shocked = "shocked",
		nervous = "nervous", --(flitt's nervous twitch)
		eyeroll = "eyeroll",
		gruffnod = "gruffnod",
		bliss = "bliss",
		scared = "scared",
		closedeyes = "closedeyes", -- closes and then opens eyes

		notebook_start = "notebook_start", -- if you use these the npc will write until you tell them to stop
		notebook_stop = "notebook_stop", -- if you use these the npc will write until you tell them to stop
		notebook = "notebook",

		agree = "agree", --(nod)
		disagree = "disagree", --(shake head)

		wavelunn = "wavelunn", --(berna specific emote)
		wink = "wink", --(alphonse specific emote)
		cough = "cough", --(toot specific emote)
		very_sick = "very_sick", --(toot specific emote)
	},
	-- feeling: current emotional state that changes how their face looks.
	feeling = {
		happy = "happy",
		neutral = "neutral",
	},
}

return emotion
