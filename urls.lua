local URLS = {
	mod_forum = "https://forums.kleientertainment.com/forums/forum/260-rotwood/",
	coming_soon = "https://forums.kleientertainment.com/forums/forum/260-rotwood/",
}
if Platform.IsRail() then
	URLS.klei_bug_tracker = "http://plat.tgp.qq.com/forum/index.html#/2000004?type=11"
elseif Platform.IsNotConsole() then
	URLS.klei_bug_tracker = "https://forums.kleientertainment.com/klei-bug-tracker/rotwood-playtest/"
end

return URLS
