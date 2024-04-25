local Quip = require "questral.quip"

local C = Quip.CreateGlobalQuipContent()

-- These Emotes aren't real quest dialogue emotes! They're just tags used by HuntProgressWidget.
--
-- Don't add any "agent:" to these quips! They're not processed by conversations.
C:AddQuips {
	Quip("huntprogressscreen", "abandoned")
		:Emote("confused")
		:PossibleStrings({
			"Did you forget something at home?",
			"Did you leave the oven on? ...Do we even have an oven?",
		}),
	Quip("huntprogressscreen", "lost_boss", "bandicoot")
		:Emote("confused")
		:PossibleStrings({
			"What a sneaky rascal!",
			"<i>Two</> of them? Well that hardly seems fair.",
			"Was I seeing double?",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "floracrane")
		:Emote("confused")
		:PossibleStrings({
			"All that whirling and twirling... makes me dizzy!",
			"Did she <i>kick</i> you? That seems rude.",
			"I know you can beak her! I-I mean, beat her. Sorry.",
		}),
	Quip("huntprogressscreen", "lost_early")
		:Emote("confused")
		:PossibleStrings({
			"H-Hunter? You okay? How many claws am I holding up?",
		}),
	Quip("huntprogressscreen", "lost_boss", "bandicoot")
		:Emote("frustrated")
		:PossibleStrings({
			"That gal may look fox-like, but she's no cousin of mine.",
		}),
	Quip("huntprogressscreen", "lost_boss", "general")
		:Emote("frustrated")
		:PossibleStrings({
			"The Boss won this round, but we'll be back.",
			"You nearly had it!",
		}),
	Quip("huntprogressscreen", "lost_boss", "megatreemon")
		:Emote("frustrated")
		:PossibleStrings({
			"First she slaps my {name.damselfly}, and now this?!",
		}),
	Quip("huntprogressscreen", "lost_boss", "owlitzer")
		:Emote("frustrated")
		:PossibleStrings({
			"Shoot! You were so close!",
			"Grr... couldn't it just let you win??",
			"No fair! You were so close!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "floracrane")
		:Emote("frustrated")
		:PossibleStrings({
			"How dare that bird!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "gourdo")
		:Emote("frustrated")
		:PossibleStrings({
			"Hey! Who taught {name_multiple.gourdo} to team up?",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "yammo")
		:Emote("frustrated")
		:PossibleStrings({
			"Next time, let's squash that squash!",
		}),
	Quip("huntprogressscreen", "lost_early")
		:Emote("frustrated")
		:PossibleStrings({
			"Can't they just leave you alone!",
		}),
	Quip("huntprogressscreen", "abandoned")
		:Emote("motivational")
		:PossibleStrings({
			"Alright, hold tight Hunter.",
			"Sending down the rope now!",
			"Alright, Hunter. Let's head home.",
			"Don't feel bad about running away.\nI do it all the time!",
			"You tucked tail very bravely, Hunter.",
			"Next stop-- home!",
		}),
	Quip("huntprogressscreen", "lost_beat_miniboss")
		:Emote("motivational")
		:PossibleStrings({
			"Don't be discouraged. You made it halfway through the Hunt!",
		}),
	Quip("huntprogressscreen", "lost_boss", "general")
		:Emote("motivational")
		:PossibleStrings({
			"You almost won that Hunt!",
			"That Boss better watch its back once you're feeling better!",
			"Let's head back and brainstorm new strategies.",
			"Live to fight another day, Hunter.",
		}),
	Quip("huntprogressscreen", "lost_boss", "megatreemon")
		:Emote("motivational")
		:PossibleStrings({
			"Heyyy, you really whittled her down!",
			"Don't worry, Hunter. You'll have plenty more chances.",
			"Don't give up!",
		}),
	Quip("huntprogressscreen", "lost_boss", "owlitzer")
		:Emote("motivational")
		:PossibleStrings({
			"Hang on! {name.npc_scout} to the rescue!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "gourdo")
		:Emote("motivational")
		:PossibleStrings({
			"Joke's on them! You'll just keep coming back, and they've got no way to stop you.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "yammo")
		:Emote("motivational")
		:PossibleStrings({
			"Don't be discouraged... I know you can win!",
			"Don't give up!",
		}),
	Quip("huntprogressscreen", "lost_early")
		:Emote("motivational")
		:PossibleStrings({
			"Don't worry Hunter, I've got you.",
			"I'll get you back home, Hunter.",
			"Ready for a little {name.damselfly} ride?",
		}),
	Quip("huntprogressscreen", "won")
		:Emote("motivational")
		:PossibleStrings({
			"I knew you could do it, Hunter!",
			"I love a successful Hunt!",
			"A fine day's work, Hunter.",
			"Another step closer to taking back the Rotwood!",
			"Mark another win for the {name_multiple.foxtails}.",
		}),
	Quip("huntprogressscreen", "lost_boss", "bandicoot")
		:Emote("nervous")
		:PossibleStrings({
			"Ah. They say a coyote is most dangerous when it's cornered.",
			"Woah, she went feral at the end there!",
		}),
	Quip("huntprogressscreen", "lost_boss", "megatreemon")
		:Emote("nervous")
		:PossibleStrings({
			"Let's make like a tree and get the heck outta here!",
			"Hold on Hunter, I'm getting you out of there!",
		}),
	Quip("huntprogressscreen", "lost_boss", "owlitzer")
		:Emote("nervous")
		:PossibleStrings({
			"Yeesh, talk about birds of prey!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "floracrane")
		:Emote("nervous")
		:PossibleStrings({
			"That beak looked pretty s-sharp!",
			"Hold on Hunter, I've got you!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "general")
		:Emote("nervous")
		:PossibleStrings({
			"That thing sure is nasty.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "gourdo")
		:Emote("nervous")
		:PossibleStrings({
			"Holy guacamole! Are you okay??",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "groak")
		:Emote("nervous")
		:PossibleStrings({
			"T-that thing was disgusting!",
			"Yeesh. That guy makes my hackles stand on end.",
			"I think you can dodge through the shockwave from his fist slams.\nS-sorry if that was obvious.",
			"I always feel like I need a bath after flying over this bog.",
			"Let's go home, rest up, then give it another try.",
			"Don't worry. Even the best Hunters take their lumps.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "yammo")
		:Emote("nervous")
		:PossibleStrings({
			"That {name.yammo}'s club s-sure looks spiky.",
			"Let's go get you fixed up.",
		}),
	Quip("huntprogressscreen", "lost_early")
		:Emote("nervous")
		:PossibleStrings({
			"Let's get you outta here!",
			"Phew! I'm rescuing you just in the nick of time!",
			"Hold on, I'll pull you up!",
			"Hey, Hunter? Oh, you're unconscious. Sorry!",
			"Hang on, Hunter!",
		}),
	Quip("huntprogressscreen", "lost_boss", "bandicoot")
		:Emote("sad")
		:PossibleStrings({
			"Well jeez, she didn't have to laugh so hard at us.",
		}),
	Quip("huntprogressscreen", "lost_boss", "general")
		:Emote("sad")
		:PossibleStrings({
			"That didn't hurt, did it?",
		}),
	Quip("huntprogressscreen", "lost_boss", "megatreemon")
		:Emote("sad")
		:PossibleStrings({
			"You nearly had her!",
		}),
	Quip("huntprogressscreen", "lost_boss", "owlitzer")
		:Emote("sad")
		:PossibleStrings({
			"Why does an owl need teeth??",
			"I nearly jumped outta my pelt when it flew up here!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "general")
		:Emote("sad")
		:PossibleStrings({
			"Y-you'll get that thing next time!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "groak")
		:Emote("sad")
		:PossibleStrings({
			"At least now we can go home and get away from that smell.",
			"Hunter, you gotta kill that thing.\nMy peace of mind depends on it.",
		}),
	Quip("huntprogressscreen", "lost_early")
		:Emote("sad")
		:PossibleStrings({
			"Hunter? <i>HUNTERRRR!</i>",
		}),
	Quip("huntprogressscreen", "abandoned")
		:Emote("skeptical")
		:PossibleStrings({
			"Got cold feet, huh?",
			"Sometimes you just gotta cut your losses.",
			"It's good to have a healthy fear of {name_multiple.rot}.",
		}),
	Quip("huntprogressscreen", "lost_boss", "bandicoot")
		:Emote("skeptical")
		:PossibleStrings({
			"Can't quite put my claw on it, but...\nSomething seems a little off about one of those copies.",
			"If you let her rage long enough, she's bound to tucker herself out.",
			"She's got too much {name.konjur} in her system to fully conceal herself.\nKeep an eye on the veins of those rocks.",
			"Did you see that? She was taunting you!\nAlmost like she <i>wanted</i> you to attack her.",
		}),
	Quip("huntprogressscreen", "lost_boss", "general")
		:Emote("skeptical")
		:PossibleStrings({
			"If you ask me, it's only a matter of time 'til you win.",
			"Perhaps we need to take a different approach...",
			"You're sure to win now that we know its moves.",
		}),
	Quip("huntprogressscreen", "lost_boss", "megatreemon")
		:Emote("skeptical")
		:PossibleStrings({
			"You put up a good fight, Hunter.",
			"I'm starting to not like trees very much.",
			"Rest well Hunter, you did good getting this far.",
			"It's okay to focus on dodging while she bombards you with roots.\nOnly strike when you feel confident.",
			"If you knock out those mines during the lull in her attacks,\nthey're less likely to surprise you at inopportune times.",
		}),
	Quip("huntprogressscreen", "lost_boss", "owlitzer")
		:Emote("skeptical")
		:PossibleStrings({
			"Hm... Looks like it puts eyes on whoever it's about to divebomb.",
			"Keep your head on a swivel, Hunter.\nErr, so to speak.",
			"You didn't go down easy! Good work, Hunter.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "floracrane")
		:Emote("skeptical")
		:PossibleStrings({
			"This {name.floracrane} has nice footwork, I'll give her that.",
			"You put up a good fight, Hunter.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "gourdo")
		:Emote("skeptical")
		:PossibleStrings({
			"If you see them drop a healing seed, make sure to knock it out!",
			"Did you see that? Their butt slams always come in threes.",
			"You'll get those creeps next time, I know it.",
			"And here I thought veggies were supposed to be good for you.",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "groak")
		:Emote("skeptical")
		:PossibleStrings({
			"I know you can do it, Hunter. Don't let that guy win!",
		}),
	Quip("huntprogressscreen", "lost_during_miniboss", "yammo")
		:Emote("skeptical")
		:PossibleStrings({
			"Looks like there's an opening for some free hits while his club is stuck in the dirt.",
			"It looks like that {name.yammo}'s attacks have a blind spot.\nHe can't hit you while you're behind him.",
		}),
}

-- TEMP: This is how I generated the quips.
--~ local iterator = require "util.iterator"
--~ require "strings.strings"

--~ local moods = {}
--~ local function add(tag, t)
--~ 	print("add():", tag, t.mood, t.text)
--~ 	local m = moods[t.mood] or {}
--~ 	moods[t.mood] = m
--~ 	local tagged = m[tag] or {}
--~ 	m[tag] = tagged
--~ 	t.text = t.text:gsub("\n", "\\n")
--~ 	table.insert(tagged, t.text)
--~ end
--~ for key,val in pairs(STRINGS.UI.HUNTPROGRESSSCREEN) do
--~ 	for _,t in ipairs(val) do
--~ 		add(key, t)
--~ 	end
--~ 	for prefab,list in pairs(val) do
--~ 		local k = key..'", "'.. prefab
--~ 		for _,t in ipairs(list) do
--~ 			add(k, t)
--~ 		end
--~ 	end
--~ end
--~ local file = io.open("/code/FromTheForge/data/scripts/content/quests/scout/dgn_huntprogress_quips2.lua", "w")
--~ for mood,val in iterator.sorted_pairs(moods) do
--~ 	for tag,text in iterator.sorted_pairs(val) do
--~ 		local msg = [=[
--~ 	Quip("huntprogressscreen", "%s")
--~ 		:Emote("%s")
--~ 		:PossibleStrings({
--~ "%s
--~ 		}),
--~ ]=]
--~ 			file:write(msg:format(tag:lower(), mood:lower(), table.concat(text, "\",\n\"") .. '",'))
--~ 	end
--~ end
--~ file:close()


return C
