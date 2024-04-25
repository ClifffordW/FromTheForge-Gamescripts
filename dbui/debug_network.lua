local DebugNodes = require "dbui.debug_nodes"
local DebugSettings = require "debug.inspectors.debugsettings"
local Cosmetic = require "defs.cosmetics.cosmetics"
local lume = require "util.lume"
require "consolecommands"
require "constants"

local DebugNetwork = Class(DebugNodes.DebugNode, function(self)
	DebugNodes.DebugNode._ctor(self, "Debug Network")
	self.options = DebugSettings("DebugNetwork.options")
		:Option("filter_entity_prefabname", "")
end)

DebugNetwork.PANEL_WIDTH = 1000
DebugNetwork.PANEL_HEIGHT = 800

local selectedLocalBlob 
local selectedRemoteClient 
local selectedRemoteBlob
local selectedPlayerID 

local clientGraphs = {}
local totalsendkbps = { 0.0, 0.0 }
local totalrecvkbps = { 0.0, 0.0 }
local maxsendkpbs = 0
local maxrecvkpbs = 0


local function IsHostClientID(clientID)
	-- this will need to change if host migration is supported
	return clientID == 0
end



function DebugNetwork:RenderBadConnectionSimulator(ui)
	if ui:CollapsingHeader("Bad Connection Simulator") then

		local dirty = false
		local sett = TheNet:GetBadNetworkSimulatorState();
		if ui:Checkbox("Enabled", sett.enabled) then
			sett.enabled = not sett.enabled
			dirty = true
		end

		ui:SameLineWithSpace()
		if ui:Button("Reset to defaults") then

			sett.sendLimitKbps = 256
			sett.sendLagMinimumMs = 50
			sett.sendLagMaximumMs = 65		
			sett.sendPacketLossPercentage = 2.5

			sett.receiveLimitKbps = 256
			sett.receiveLagMinimumMs = 50
			sett.receiveLagMaximumMs = 65
			sett.receivePacketLossPercentage = 2.5

			dirty = true		
		end

		-- Simplyfied controls:
		local changed, value
		local throughput = sett.sendLimitKbps
		changed, value = ui:SliderInt("Max Throughput", throughput, 10, 512, "%dkbps")
		if changed then
			throughput = value
			dirty = true
		end

		local lag = sett.sendLagMaximumMs + sett.receiveLagMaximumMs
		changed, value = ui:SliderInt("Lag", lag, 0, 500, "%dms")
		if changed then
			lag = value
			dirty = true
		end

		local loss = sett.sendPacketLossPercentage + sett.receivePacketLossPercentage
		changed, value = ui:SliderFloat("Packet Loss", loss, 0, 10, "%0.1f%%")
		if changed then
			loss = value
			dirty = true
		end

		if dirty == true then

			sett.sendLimitKbps = throughput

			sett.sendLagMaximumMs = lag	* 0.5	
			sett.sendLagMinimumMs = sett.sendLagMaximumMs - 30;	-- Add some variation
			if sett.sendLagMinimumMs < 0 then
				sett.sendLagMinimumMs = 0
			end
			sett.sendPacketLossPercentage = loss * 0.5

			sett.receiveLimitKbps = sett.sendLimitKbps
			sett.receiveLagMaximumMs = sett.sendLagMaximumMs
			sett.receiveLagMinimumMs = sett.sendLagMinimumMs
			sett.receivePacketLossPercentage = sett.sendPacketLossPercentage;

			TheNet:SetBadNetworkSimulatorState(sett);
		end
	end
end



function DebugNetwork:GatherClientsData()
	local clients = TheNet:GetClientList()

	if clients then
		local send_total = 0
		local recv_total = 0

		for k, client in pairs(clients) do

			if not client.islocal then
				if client.isconnected then
					if not clientGraphs[client.id] then
						clientGraphs[client.id] = {}
						clientGraphs[client.id].rtt = {}
						clientGraphs[client.id].packetloss = {}
						clientGraphs[client.id].packetsendperiod = {}
						clientGraphs[client.id].sendkbps = {}
						clientGraphs[client.id].recvkbps = {}
					end

					table.insert(clientGraphs[client.id].rtt, client.rtt)
					table.insert(clientGraphs[client.id].packetloss, client.packetloss)
					table.insert(clientGraphs[client.id].packetsendperiod, client.packetsendperiod * 1000.0)
					table.insert(clientGraphs[client.id].sendkbps, client.sendkbps)
					table.insert(clientGraphs[client.id].recvkbps, client.recvkbps)

					send_total = send_total + client.sendkbps
					recv_total = recv_total + client.recvkbps

					if (#clientGraphs[client.id].rtt > 500) then	-- limit the length of the history
						table.remove(clientGraphs[client.id].rtt, 1)
						table.remove(clientGraphs[client.id].packetloss, 1)
						table.remove(clientGraphs[client.id].packetsendperiod, 1)
						table.remove(clientGraphs[client.id].sendkbps, 1)
						table.remove(clientGraphs[client.id].recvkbps, 1)
					end
				end
			end
		end	

		table.insert(totalsendkbps, send_total)
		table.insert(totalrecvkbps, recv_total)

		if send_total > maxsendkpbs then
			maxsendkpbs = send_total
		end
		if recv_total > maxrecvkpbs then
			maxrecvkpbs = recv_total
		end

		if (#totalsendkbps > 500) then	-- limit the length of the history
			table.remove(totalsendkbps, 1)
			table.remove(totalrecvkbps, 1)
		end

	end

	return clients
end



function DebugNetwork:RenderClients(ui, clients)
	local colors = self.colorscheme
	if ui:CollapsingHeader("Clients") then

		local colw = ui:GetColumnWidth()
	
		ui:Columns(9, "Clients")

		ui:SetColumnWidth(0, colw * 0.05)
		ui:SetColumnWidth(1, colw * 0.15)

		ui:TextColored(colors.header, "ID")
		ui:NextColumn()
		ui:TextColored(colors.header, "Name")
		ui:NextColumn()
		ui:TextColored(colors.header, "Local")
		ui:NextColumn()
		ui:TextColored(colors.header, "Connected")
		ui:NextColumn()
		ui:TextColored(colors.header, "RTT")
		ui:NextColumn()
		ui:TextColored(colors.header, "Loss %")
		ui:NextColumn()
		ui:TextColored(colors.header, "SendKbps")
		ui:NextColumn()
		ui:TextColored(colors.header, "RecvKbps")
		ui:NextColumn()
		ui:TextColored(colors.header, "SendRate")
		ui:NextColumn()

		if clients then
			local send_total = 0
			local recv_total = 0

			for k, client in pairs(clients) do

				ui:Text(tostring(client.id))
				ui:NextColumn()
				ui:Text(client.name .. (IsHostClientID(client.id) and " (host)" or ""))
				ui:NextColumn()
				ui:Text(tostring(client.islocal))
				ui:NextColumn()
				if client.islocal then
					ui:Text("-")	-- isconnected
					ui:NextColumn()
					ui:Text("-")	-- rtt
					ui:NextColumn()
					ui:Text("-")	-- packet loss
					ui:NextColumn()
					ui:Text("-")	-- sendkbps
					ui:NextColumn()
					ui:Text("-")	-- recvkbps
					ui:NextColumn()
					ui:Text("-")	-- packetsendperiod
					ui:NextColumn()
				else
					ui:Text(tostring(client.isconnected))
					ui:NextColumn()

					if client.isconnected then
						--ui:Text(tostring(client.rtt))
						ui:SetNextItemWidth()	-- will set it to -FLT_MIN
						ui:PlotLines("", tostring(math.floor(client.rtt)), clientGraphs[client.id].rtt, 0, 0.0, 800.0, 50.0)
						ui:NextColumn()
						--ui:Text(tostring(client.packetloss) .. "%")
						ui:SetNextItemWidth()	-- will set it to -FLT_MIN
						ui:PlotLines("", string.format("%.1f%%", client.packetloss), clientGraphs[client.id].packetloss, 0, 0.0, 10.0, 50.0)
						ui:NextColumn()
						--ui:Text(tostring(client.sendkbps))
						ui:SetNextItemWidth()	-- will set it to -FLT_MIN
						ui:PlotLines("", tostring(math.floor(client.sendkbps)), clientGraphs[client.id].sendkbps, 0, 0.0, 256.0, 50.0)
						ui:NextColumn()
						--ui:Text(tostring(client.recvkbps))
						ui:SetNextItemWidth()	-- will set it to -FLT_MIN
						ui:PlotLines("", tostring(math.floor(client.recvkbps)), clientGraphs[client.id].recvkbps, 0, 0.0, 256.0, 50.0)
						ui:NextColumn()	
						--ui:Text(tostring(client.packetsendperiod) .. "%")
						ui:SetNextItemWidth()	-- will set it to -FLT_MIN
						ui:PlotLines("", string.format("%.1fms", client.packetsendperiod * 1000.0), clientGraphs[client.id].packetsendperiod, 0, 0.0, 0.1, 50.0)
						ui:NextColumn()

					else 
						clientGraphs[client.id] = nil
						ui:Text("-")	-- rtt
						ui:NextColumn()
						ui:Text("-")	-- packet loss
						ui:NextColumn()
						ui:Text("-")	-- sendkbps
						ui:NextColumn()
						ui:Text("-")	-- recvkbps
						ui:NextColumn()
						ui:Text("-")	-- sendrate
						ui:NextColumn()
					end
				end
			end	
		end

		ui:Columns()
	end
end


function DebugNetwork:RenderPlayers(ui)
	local colors = self.colorscheme
	if ui:CollapsingHeader("Players") then

		local colw = ui:GetColumnWidth()

		ui:Columns(7, "Players")

		ui:TextColored(colors.header, "PlayerID")
		ui:NextColumn()
		ui:TextColored(colors.header, "Name")
		ui:NextColumn()
		ui:TextColored(colors.header, "Local")
		ui:NextColumn()
		ui:TextColored(colors.header, "InputID")
		ui:NextColumn()
		ui:TextColored(colors.header, "ClientID")
		ui:NextColumn()
		ui:TextColored(colors.header, "EntityID")
		ui:NextColumn()
		ui:TextColored(colors.header, "GUID")
		ui:NextColumn()


		for k, playerID in pairs(TheNet:GetPlayerList()) do

			local col = RGB(59, 222, 99)	-- green
			local islocal = TheNet:IsLocalPlayer(playerID)
			if not islocal then
				col = RGB(207, 61, 61) -- red
			end

			ui:TextColored(col, tostring(playerID))
			ui:NextColumn()
			ui:TextColored(col, TheNet:GetPlayerName(playerID) or "")
			ui:NextColumn()
			ui:TextColored(col, tostring(islocal))
			ui:NextColumn()
			ui:TextColored(col, tostring(TheNet:FindInputIDForPlayerID(playerID) or ""))
			ui:NextColumn()
			ui:TextColored(col, tostring(TheNet:FindClientIDForPlayerID(playerID) or ""))
			ui:NextColumn()
			ui:TextColored(col, tostring(TheNet:FindEntityIDForPlayerID(playerID) or ""))
			ui:NextColumn()
			ui:TextColored(col, tostring(TheNet:FindGUIDForPlayerID(playerID) or ""))
			ui:NextColumn()
		end	

		ui:Columns()
	end
end

function DebugNetwork:RenderNetworkState(ui, panel)
	if ui:CollapsingHeader("Host State") then
		if TheNet:IsInGame() then
			local tableFlags <const> = ui.TableFlags.Borders
			local tableKeyWidth <const> = 200
			local gm, gmseqnr = TheNet:GetCurrentGameMode();
			ui:Text("Game Mode: " .. gm .. " SeqNr: " .. tostring(gmseqnr))
			if ui:TreeNode("Room Data", ui.TreeNodeFlags.DefaultOpen) then
				ui:TextColored(BGCOLORS.CYAN, "Simulation Sequence Number: " .. TheNet:GetSimSequenceNumber())
				local roomdata = TheNet:GetRoomData()
				local isRoomLocked = TheNet:GetRoomLockState()
				local isReadyToStartRoom = TheNet:IsReadyToStartRoom()
				local roomCompleteSeqNr, roomIsComplete, enemyHighWater, lastEnemyID = TheNet:GetRoomCompleteState()
				local threatlevel = TheNet:GetThreatLevel()
				if roomdata then
					if ui:BeginTable("roomdata", 2, tableFlags) then
						ui:TableSetupColumn("Room Data", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
						ui:TableSetupColumn("Value")
						ui:TableHeadersRow()

						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Action ID")
							ui:TableNextColumn()
							ui:Text(roomdata.actionID)
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("World Prefab")
							ui:TableNextColumn()
							ui:Text(roomdata.worldPrefab)
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("SceneGen Prefab")
							ui:TableNextColumn()
							ui:Text(roomdata.sceneGenPrefab)
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Room ID")
							ui:TableNextColumn()
							ui:Text(roomdata.roomID)
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Force Reset")
							ui:TableNextColumn()
							ui:Text(roomdata.forceReset and "true" or "false")
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Num Players on Room Change")
							ui:TableNextColumn()
							ui:Text(roomdata.playersOnRoomChange)
						ui:EndTable()
					end
				end
				if ui:BeginTable("roomstatus", 2, tableFlags) then
					ui:TableSetupColumn("Room Status", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Value")
					ui:TableHeadersRow()

					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Room Locked")
						ui:TableNextColumn()
						ui:Text(tostring(isRoomLocked))
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Is Ready To Start Room")
						ui:TableNextColumn()
						ui:Text(tostring(isReadyToStartRoom))
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Threat Level")
						ui:TableNextColumn()
						ui:Text(threatlevel)
					ui:EndTable()
				end
				if ui:BeginTable("roomcomplete", 2, tableFlags) then
					ui:TableSetupColumn("Room Complete", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Value")
					ui:TableHeadersRow()

					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Sequence Number")
						ui:TableNextColumn()
						ui:Text(roomCompleteSeqNr)
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Is Complete")
						ui:TableNextColumn()
						ui:Text(roomIsComplete)
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Enemy High Water")
						ui:TableNextColumn()
						ui:Text(enemyHighWater)
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Last Enemy EntityID")
						ui:TableNextColumn()
						ui:Text(lastEnemyID)
					ui:EndTable()
				end

				if ui:TreeNode("Players on Last Room Change", ui.TreeNodeFlags.DefaultOpen) then
					local colors = self.colorscheme
					ui:Columns(5, "Players on Last Room Change")
					ui:SetColumnWidth(0, 30)
					ui:SetColumnWidth(1, 60)
					ui:SetColumnWidth(2, 60)
					ui:SetColumnWidth(3, 120)
					ui:SetColumnWidth(4, 90)
					ui:TextColored(colors.header, "ID")
					ui:NextColumn()
					ui:TextColored(colors.header, "GUID")
					ui:NextColumn()
					ui:TextColored(colors.header, "NetID")
					ui:NextColumn()
					ui:TextColored(colors.header, "Name")
					ui:NextColumn()
					ui:TextColored(colors.header, "Debug")
					ui:NextColumn()
					local players = TheNet:GetPlayersOnRoomChange()
					for i,player in ipairs(players) do
						ui:Text(player.Network:GetPlayerID())
						ui:NextColumn()
						ui:Text(string.format("%d", player.GUID))
						ui:NextColumn()
						ui:Text(player.Network:GetEntityID())
						ui:NextColumn()
						ui:Text(player:GetCustomUserName())
						ui:NextColumn()
						if ui:Button("Debug##"..i) then
							panel:PushNode(DebugNodes.DebugEntity(Ents[player.GUID]) )
						end
						ui:NextColumn()
					end
					ui:Columns()
					ui:TreePop()
				end
				ui:TreePop()
			end
			if ui:TreeNode("Start Run Data", ui.TreeNodeFlags.DefaultOpen) then
				-- TODO: compare these values to those stored in local systems like worldmap, ascensionmanager, etc.
				local mode, seqNr, dungeon_run_params, quest_params = TheNet:GetRunData()
				if ui:BeginTable("rundata", 2, tableFlags) then
					ui:TableSetupColumn("Run Data", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Value")
					ui:TableHeadersRow()

					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Sequence Number")
						ui:TableNextColumn()
						ui:Text(seqNr)
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Mode")
						ui:TableNextColumn()
						local mode_text = "Unknown"
						if mode == STARTRUNMODE_ARENA then
							mode_text = "Arena"
						elseif mode == STARTRUNMODE_DEFAULT then
							mode_text = "Default"
						end
						ui:Text(mode_text .. " (" .. mode .. ")")
					ui:EndTable()
				end
				if ui:BeginTable("dungeonrunparams", 2, tableFlags) then
					ui:TableSetupColumn("Dungeon Run Params", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Value")
					ui:TableHeadersRow()

					if mode == STARTRUNMODE_ARENA then
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Arena World Prefab")
							ui:TableNextColumn()
							ui:Text(dungeon_run_params.arena_world_prefab)
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Room Type")
							ui:TableNextColumn()
							ui:Text(dungeon_run_params.roomtype)
					elseif mode == STARTRUNMODE_DEFAULT then
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Region ID")
							ui:TableNextColumn()
							ui:Text(dungeon_run_params.region_id)
					end
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Location ID")
						ui:TableNextColumn()
						ui:Text(dungeon_run_params.location_id)
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Seed")
						ui:SameLineWithSpace()
						if ui:Button(ui.icon.copy) then
							ui:SetClipboardText(dungeon_run_params.seed or 0)
						end
						ui:TableNextColumn()
						ui:Text(dungeon_run_params.seed)
					if mode == STARTRUNMODE_DEFAULT then
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text("Alt MapGen ID")
							ui:TableNextColumn()
							ui:Text(dungeon_run_params.alt_mapgen_id)
					end
					ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text("Ascension Level")
						ui:TableNextColumn()
						ui:Text(dungeon_run_params.ascension)
					ui:EndTable()
				end

				local quest_param_names = lume.keys(quest_params)
				table.sort(quest_param_names)
				if ui:BeginTable("questparams", 2, tableFlags) then
					ui:TableSetupColumn("Quest Params", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Value")
					ui:TableHeadersRow()

					for _i,key in ipairs(quest_param_names) do
						ui:TableNextRow()
							ui:TableNextColumn()
							ui:Text(key)
							ui:TableNextColumn()
							ui:Text(quest_params[key])
					end
					ui:EndTable()
				end
				ui:TreePop()
			end
			if TheNet:IsHost() and ui:TreeNode("Run Player Status (Host-Only)") then
				local colors = self.colorscheme
				ui:Columns(2, "Run Player Status")
				ui:SetColumnWidth(0, 30)
				ui:SetColumnWidth(1, 120)
				ui:TextColored(colors.header, "ID")
				ui:NextColumn()
				ui:TextColored(colors.header, "Status")
				ui:NextColumn()
				local statusTable = TheNet:GetRunPlayerStatus()
				for playerID,status in pairs(statusTable) do
					ui:Text(playerID)
					ui:NextColumn()
					ui:Text(status .. " (" .. GetRunPlayerStatusDescription(status) .. ")")
					ui:NextColumn()
				end
				ui:Columns()
				ui:TreePop()
			end
		else
			ui:Text("Not in network game")
		end
	end
end



function DebugNetwork:RenderNetworkEvents(ui, panel)
	if ui:CollapsingHeader("Events") then
		local counters = TheNet:GetEventsCounters()
		if counters then

			local nrColumns = 2
			ui:Columns(nrColumns, "Events Counters")

			local colors = self.colorscheme
			ui:TextColored(colors.header, "Type")
			ui:NextColumn()
			ui:TextColored(colors.header, "Count")
			ui:NextColumn()

			if counters then
				for k, count in pairs(counters) do

					ui:Text(k)
					ui:NextColumn()
					ui:Text(tostring(count))
					ui:NextColumn()
				end
			end
			ui:Columns()
		end
	end
end

function DebugNetwork:RenderEntities(ui, panel)
	if ui:CollapsingHeader("Entities") then

		self.options:SaveIfChanged("filter_entity_prefabname", ui:FilterBar(self.options.filter_entity_prefabname, "Filter entity prefab", "Prefab pattern..."))

		local entities = TheNet:GetEntityList()

		ui:Text("Sim Seq Nr: " .. TheNet:GetSimSequenceNumber())


		local colw = ui:GetColumnWidth()
	
		local nrColumns = 12
		ui:Columns(nrColumns, "Entities")

		local onecolumn = colw / nrColumns;
		ui:SetColumnWidth(0, onecolumn * 0.6)	-- guid
		ui:SetColumnWidth(1, onecolumn * 0.6)	-- id
		ui:SetColumnWidth(2, onecolumn * 1.7)	-- prefab
		ui:SetColumnWidth(3, onecolumn * 1.5)	-- owner
		ui:SetColumnWidth(4, onecolumn * 0.8)	-- minimal
		ui:SetColumnWidth(5, onecolumn * 0.7)	-- seqnr
		ui:SetColumnWidth(6, onecolumn * 0.7)	-- flags
		local colors = self.colorscheme
		ui:TextColored(colors.header, "Guid")
		ui:NextColumn()
		ui:TextColored(colors.header, "ID")
		ui:NextColumn()
		ui:TextColored(colors.header, "Prefab")
		ui:NextColumn()
		ui:TextColored(colors.header, "Owner")
		ui:NextColumn()
		ui:TextColored(colors.header, "Minimal")
		ui:NextColumn()
		ui:TextColored(colors.header, "SeqNr")
		ui:NextColumn()
		ui:TextColored(colors.header, "Flags")
		ui:NextColumn()
		ui:TextColored(colors.header, "CtrlBlob")
		ui:NextColumn()
		ui:TextColored(colors.header, "DataBlob")
		ui:NextColumn()
		ui:TextColored(colors.header, "BlobSize")
		ui:NextColumn()
		ui:TextColored(colors.header, "Debug")
		ui:NextColumn();
		ui:TextColored(colors.header, "Kill")
		ui:NextColumn();

		for k, entity in pairs(entities or table.empty) do
			local ok_prefabname = ui:MatchesFilterBar(self.options.filter_entity_prefabname, entity.prefab or "")
			if ok_prefabname then
				local col = RGB(59, 222, 99)	-- green
				if not entity.islocal then
					col = RGB(207, 61, 61) -- red
				else
					if entity.transferring then
						col = RGB(198, 172, 0)	-- yellow
					end
				end

				ui:TextColored(col, tostring(math.floor(entity.guid)))
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.id))
				ui:NextColumn()
				ui:TextColored(col, entity.prefab)
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.owner))
				ui:NextColumn()
				ui:Checkbox("###" .. k, Ents[entity.guid]:IsMinimal())
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.seqnr))
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.flags))
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.ctrlblobid))
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.datablobid))
				ui:NextColumn()
				ui:TextColored(col, tostring(entity.blobsize))
				ui:NextColumn()
				if ui:Button("Debug##"..k) then
					panel:PushNode(DebugNodes.DebugEntity(Ents[entity.guid]) )
				end
				ui:NextColumn()	
				if entity.islocal then
					if ui:Button("Kill##"..k) then
						local tokillent = Ents[entity.guid]

						if tokillent.components.health ~= nil then
							tokillent.components.health:Kill()
						else
							tokillent:Remove()
						end
					end
				end
				ui:NextColumn()
			end
		end

		ui:Columns()
	end
end



local WORLD_CATEGORIES = {
	"FLAG",
    "REGION",
    "LOCATION",
}


local selectedWorldCategory
local selectedWorldItem

function DebugNetwork:RenderTestWorldUnlocks(ui)
	ui:Columns(4)
		ui:SetColumnWidth(0, 150)
		ui:SetColumnWidth(1, 200)
		ui:SetColumnWidth(2, 300)
		ui:SetColumnWidth(3, 160)

		ui:Text("IsUnlocked ")
		ui:NextColumn()
	
		-- Combo box for category:
		local index = 1
		for i, v in ipairs(WORLD_CATEGORIES) do
			if v == selectedWorldCategory then
				index = i
			end
		end
		selectedWorldCategory = WORLD_CATEGORIES[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##WorldCategory1", index, WORLD_CATEGORIES)
		if changed then
			selectedWorldCategory = WORLD_CATEGORIES[idx]
		end


		ui:NextColumn()

		ui:SetNextItemWidth()
		local changed, new_item = ui:InputText("##WorldItem1", selectedWorldItem)
		if changed then
			selectedWorldItem = new_item
		end

		ui:NextColumn()

		-- Result:
	
		if TheWorldData:IsUnlocked(selectedWorldCategory, selectedWorldItem or "") then
			ui:TextColored(UICOLORS.GREEN, "TRUE")
		else
			ui:TextColored(UICOLORS.RED, "FALSE")
		end
	ui:Columns()
end


function DebugNetwork:RenderNetworkWorldData(ui)
	if TheNet:IsInGame() then
		local data = TheWorldData:GetSaveData();

		if data and data["Unlocks"] then
			local unlocks = data["Unlocks"]

			self:RenderTestWorldUnlocks(ui)

			ui:Text("Size in bytes: ".. TheWorldData:GetSize())

			for _, cat in pairs(WORLD_CATEGORIES) do
				if ui:TreeNode(cat .. "##WorldCategory", ui.TreeNodeFlags.DefaultClosed) then
					if unlocks[cat] then
						ui:Indent()
						for item, value in pairs(unlocks[cat]) do
							ui:Text(item)
						end
						ui:Unindent()
					end
					ui:TreePop()
				end
			end

--				if ui:Button("Dump worlddata") then
--					dumptable(data)
--				end
		end
	else
		ui:Text("Not in network game")
	end
end

function DebugNetwork:RenderNetworkWorldDataPanel(ui)
	if ui:CollapsingHeader("WorldData") then
		self:RenderNetworkWorldData(ui)
	end
end


local PLAYER_CATEGORIES = {
	"RECIPE",
	"ENEMY",
	"CONSUMABLE",
	"ARMOUR",
	"WEAPON_TYPE",
	"POWER",
--	"UNLOCKABLE_COSMETIC",
--	"PURCHASABLE_COSMETIC",
	"FLAG",
--	"ASCENSION_LEVEL",
	"LOCATION",
	"REGION",
}

local selectedPlayerCategory
local selectedPlayerItem

function DebugNetwork:RenderTestPlayerUnlocks(playerID, ui)
	ui:Columns(4)
		ui:SetColumnWidth(0, 150)
		ui:SetColumnWidth(1, 200)
		ui:SetColumnWidth(2, 300)
		ui:SetColumnWidth(3, 160)

		ui:Text("IsUnlocked ")
		ui:NextColumn()
	
		-- Combo box for category:
		local index = 1
		for i, v in ipairs(PLAYER_CATEGORIES) do
			if v == selectedPlayerCategory then
				index = i
			end
		end
		selectedPlayerCategory = PLAYER_CATEGORIES[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##Category1", index, PLAYER_CATEGORIES)
		if changed then
			selectedPlayerCategory = PLAYER_CATEGORIES[idx]
		end


		ui:NextColumn()

		ui:SetNextItemWidth()
		local changed, new_item = ui:InputText("##Item1", selectedPlayerItem)
		if changed then
			selectedPlayerItem = new_item
		end

		ui:NextColumn()

		-- Result:
	
		local unlocked = ThePlayerData:IsUnlocked(playerID, selectedPlayerCategory, selectedPlayerItem or "")
		if unlocked then
			ui:TextColored(UICOLORS.GREEN, "TRUE")
		else
			ui:TextColored(UICOLORS.RED, "FALSE")
		end

		ui:SameLineWithSpace()
		if selectedPlayerItem and selectedPlayerItem~="" and ui:Button("Toggle") then
			ThePlayerData:SetIsUnlocked(playerID, selectedPlayerCategory, selectedPlayerItem, not unlocked)
		end
	ui:Columns()
end


local Biomes = require"defs.biomes"

local AllLocations
local function FindAllLocations()
	if not AllLocations then
		AllLocations = {}
		for id, def in pairs(Biomes.locations) do
			if def.type == Biomes.location_type.DUNGEON then
				table.insert(AllLocations, id)
			end
		end
		table.sort(AllLocations)
	end
end


local AllRegions
local function FindAllRegions()
	if not AllRegions then
		AllRegions = {}
		for id, def in pairs(Biomes.regions) do
			table.insert(AllRegions, string.upper(id))
		end
		table.sort(AllRegions)
	end

end

local AllWeaponTypes
local function FindAllWeaponTypes()
	if not AllWeaponTypes then
		AllWeaponTypes = {}
		for name, _ in pairs(WEAPON_TYPES) do
			table.insert(AllWeaponTypes, name)
		end
		table.sort(AllWeaponTypes)
	end
end


local selectedPlayerLocation
local selectedPlayerWeapon

function DebugNetwork:RenderTestPlayerAscension(playerID, ui)
	ui:Columns(4)
		ui:SetColumnWidth(0, 150)
		ui:SetColumnWidth(1, 200)
		ui:SetColumnWidth(2, 300)
		ui:SetColumnWidth(3, 160)

		ui:Text("Ascension Level ")
		ui:NextColumn()
	
		-- Combo box for location:
		FindAllLocations()

		local index = 1
		for i, v in ipairs(AllLocations) do
			if v == selectedPlayerLocation then
				index = i
			end
		end
		selectedPlayerLocation = AllLocations[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##Location1", index, AllLocations)
		if changed then
			selectedPlayerLocation = AllLocations[idx]
		end


		ui:NextColumn()

		-- Combo box for weapon:
		local index = 1
		FindAllWeaponTypes()
		for i, v in ipairs(AllWeaponTypes) do
			if v == selectedPlayerWeapon then
				index = i
			end
		end
		selectedPlayerWeapon = AllWeaponTypes[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##Weapon1", index, AllWeaponTypes)
		if changed then
			selectedPlayerWeapon = AllWeaponTypes[idx]
		end

		ui:NextColumn()

		-- Result:
		local level = ThePlayerData:GetCompletedAscensionLevel(playerID, selectedPlayerLocation, selectedPlayerWeapon) or -1;
		ui:Text(tostring(level))

		ui:BeginDisabled(level <= -1)
			ui:SameLineWithSpace()
			if ui:Button("-##AscMinus", 40) then
				ThePlayerData:SetAscensionLevelCompleted(playerID, selectedPlayerLocation, selectedPlayerWeapon, level-1)			
			end
		ui:EndDisabled()

		ui:BeginDisabled(level > 14)
			ui:SameLineWithSpace()
			if ui:Button("+##AscPlus", 40) then
				ThePlayerData:SetAscensionLevelCompleted(playerID, selectedPlayerLocation, selectedPlayerWeapon, level+1)			
			end
		ui:EndDisabled()

	ui:Columns()
end

local selectedPlayerCosmeticCategory
local selectedPlayerCosmeticItem

local allCosmeticCategories
local allCosmetics
local function FindAllCosmetics()
	if not allCosmetics then
		allCosmetics = {}
		allCosmeticCategories = Cosmetic.GetOrderedSlots()

		for cat, items in pairs(Cosmetic.Items) do
			for itemname, params in pairs(items) do
				if not allCosmetics[cat] then
					allCosmetics[cat] = {}
				end

				table.insert(allCosmetics[cat], itemname)
			end
		end


		-- Sort them alphabetically:
		for cat, items in pairs(allCosmetics) do
			table.sort(items)
		end
	end
end

function DebugNetwork:RenderTestPlayerCosmetics(playerID, ui)
	FindAllCosmetics()

	ui:Columns(4)
		ui:SetColumnWidth(0, 150)
		ui:SetColumnWidth(1, 200)
		ui:SetColumnWidth(2, 300)
		ui:SetColumnWidth(3, 160)

		ui:Text("Is Cosmetic Unlocked")
		ui:NextColumn()


		-- Combo box for category:
		local index = 1
		for i, v in ipairs(allCosmeticCategories) do
			if v == selectedPlayerCosmeticCategory then
				index = i
			end
		end
		selectedPlayerCosmeticCategory = allCosmeticCategories[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##CosmeticCategory1", index, allCosmeticCategories)
		if changed then
			selectedPlayerCosmeticCategory = allCosmeticCategories[idx]
		end


		ui:NextColumn()

		-- Combo box for all items:
		index = 1
		local items = allCosmetics[selectedPlayerCosmeticCategory] or {}
		for i, v in ipairs(items) do
			if v == selectedPlayerCosmeticItem then
				index = i
			end
		end
		selectedPlayerCosmeticItem = items[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##CosmeticItem1", index, items)
		if changed then
			selectedPlayerCosmeticItem = items[idx]
		end

		ui:NextColumn()

		-- Result:
	
		local unlocked = ThePlayerData:IsCosmeticUnlocked(playerID, selectedPlayerCosmeticCategory, selectedPlayerCosmeticItem or "")
		if unlocked then
			ui:TextColored(UICOLORS.GREEN, "TRUE")
		else
			ui:TextColored(UICOLORS.RED, "FALSE")
		end

		ui:SameLineWithSpace()
		if selectedPlayerCosmeticItem and selectedPlayerCosmeticItem~="" and ui:Button("Toggle") then
			ThePlayerData:SetIsCosmeticUnlocked(playerID, selectedPlayerCosmeticCategory, selectedPlayerCosmeticItem, not unlocked)
		end

	ui:Columns()
end



local selectedPlayerHeartRegion
local selectedPlayerHeartIndex

function DebugNetwork:RenderTestPlayerHeartLevels(playerID, ui)
	ui:Columns(4)
		ui:SetColumnWidth(0, 150)
		ui:SetColumnWidth(1, 200)
		ui:SetColumnWidth(2, 300)
		ui:SetColumnWidth(3, 160)

		ui:Text("Heart Level ")
		ui:NextColumn()
	
		-- Combo box for location:
		FindAllRegions();

		local index = 1
		for i, v in ipairs(AllRegions) do
			if v == selectedPlayerHeartRegion then
				index = i
			end
		end
		selectedPlayerHeartRegion = AllRegions[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##HeartRegion1", index, AllRegions)
		if changed then
			selectedPlayerHeartRegion = AllRegions[idx]
		end


		ui:NextColumn()

		-- Combo box for index:
		local index = 1
		local allPossibleIndices = { "1", "2" }
		for i, v in ipairs(allPossibleIndices) do
			if v == selectedPlayerHeartIndex then
				index = i
			end
		end
		selectedPlayerHeartIndex = allPossibleIndices[index]

		ui:SetNextItemWidth()
		local changed, idx = ui:Combo("##HeartIndex1", index, allPossibleIndices)
		if changed then
			selectedPlayerHeartIndex = allPossibleIndices[idx]
		end

		ui:NextColumn()

		-- Result:
		local level = ThePlayerData:GetHeartLevel(playerID, selectedPlayerHeartRegion, selectedPlayerHeartIndex) or 0;
		ui:Text(tostring(level))

		ui:BeginDisabled(level == 0)
			ui:SameLineWithSpace()
			if ui:Button("-##HeartMinus", 40) then
				ThePlayerData:SetHeartLevel(playerID, selectedPlayerHeartRegion, selectedPlayerHeartIndex, level-1)			
			end
		ui:EndDisabled()

		ui:BeginDisabled(level > 14)
			ui:SameLineWithSpace()
			if ui:Button("+##HeartPlus", 40) then
				ThePlayerData:SetHeartLevel(playerID, selectedPlayerHeartRegion, selectedPlayerHeartIndex, level+1)			
			end
		ui:EndDisabled()
	ui:Columns()
end

local show_synced = true
local show_unsynced = true
local COLOR_SYNCED <const> = WEBCOLORS.CYAN
local COLOR_UNSYNCED <const> = WEBCOLORS.ORANGE

function DebugNetwork:RenderNetworkPlayerDataUnlocksForPlayer(ui, playerID)
	local data = ThePlayerData:GetSaveData(playerID);

	if data then
		self:RenderTestPlayerUnlocks(playerID, ui)
		self:RenderTestPlayerAscension(playerID, ui)
		self:RenderTestPlayerCosmetics(playerID, ui)
		self:RenderTestPlayerHeartLevels(playerID, ui)

		ui:Text("Size in bytes: ".. ThePlayerData:GetSize(playerID))

		-- Render all flags:
		if data["Unlocks"] then
			if ui:CollapsingHeader("Unlocks") then
				if ui:Checkbox("###ShowSynced", show_synced) then
					show_synced = not show_synced
				end
				ui:SameLineWithSpace(5)
				ui:Text("Show")
				ui:SameLineWithSpace(5)
				ui:TextColored(COLOR_SYNCED, "synced")

				ui:SameLineWithSpace(20)

				if ui:Checkbox("###ShowUnsynced", show_unsynced) then
					show_unsynced = not show_unsynced
				end
				ui:SameLineWithSpace(5)
				ui:Text("Show")
				ui:SameLineWithSpace(5)
				ui:TextColored(COLOR_UNSYNCED, "unsynced")

				local unlocks = data["Unlocks"]

				for _, cat in ipairs(PLAYER_CATEGORIES) do
					local is_synced = ThePlayerData:IsCategorySynced(cat)
					local color = is_synced and COLOR_SYNCED or COLOR_UNSYNCED
					if is_synced and show_synced or not is_synced and show_unsynced then
						if ui:TreeNode(cat .. "##PlayerCategory", ui.TreeNodeFlags.DefaultClosed) then
							if unlocks[cat] then
								ui:Indent()	

								-- Sort the items alphabetically
								local items = {}
								for item, value in pairs(unlocks[cat]) do
									table.insert(items, item)
								end
								table.sort(items)
								
								for _, item in ipairs(items) do
									ui:TextColored(color, item);
								end
								ui:Unindent()
							end
							ui:TreePop()
						end
					end
				end
			end
		end
		if data["Ascension"] then
			if ui:CollapsingHeader("Ascension Levels") then
				local ascension = data["Ascension"]

				for location, weapons in pairs(ascension) do
					if ui:TreeNode(location .. "##PlayerLocation", ui.TreeNodeFlags.DefaultClosed) then
						if weapons then
							ui:Indent()	
							for weapon, level in pairs(weapons) do
								ui:Text(weapon .. "  - Level " .. level);
							end
							ui:Unindent()
						end
						ui:TreePop()
					end
				end
			end
		end
		if data["Cosmetics"] then
			if ui:CollapsingHeader("Cosmetics") then
				local cosmetics = data["Cosmetics"]

				for cat, items in pairs(cosmetics) do
					if ui:TreeNode(cat .. "##PlayerCosmeticCategory", ui.TreeNodeFlags.DefaultClosed) then
						if cosmetics[cat] then
							ui:Indent()	

							-- Sort the items alphabetically
							local items = {}
							for item, value in pairs(cosmetics[cat]) do
								table.insert(items, item)
							end
							table.sort(items)

							for _, item in ipairs(items) do
								ui:Text(item);
							end
							ui:Unindent()
						end
						ui:TreePop()
					end
				end
			end
		end
		if data["HeartLevels"] then
			if ui:CollapsingHeader("Heart Levels") then
				local heartlevels = data["HeartLevels"]

				for reg, items in pairs(heartlevels ) do
					if ui:TreeNode(reg .. "##PlayerHeartRegion", ui.TreeNodeFlags.DefaultClosed) then
						if heartlevels[reg] then
							ui:Indent()	
							for item, level in pairs(heartlevels[reg]) do
								ui:Text(item .. "  - Level " .. level);
							end
							ui:Unindent()
						end
						ui:TreePop()
					end
				end
			end
		end
		if data["CharacterCreator"] then
			if ui:CollapsingHeader("Character Creator") then
				local ccdata = data["CharacterCreator"]

				ui:Text("Species: " .. ccdata.species)

				local ccdata_bodyparts = lume.sort(lume.keys(ccdata.bodyparts))
				local ccdata_colorgroups = lume.sort(lume.keys(ccdata.colorgroups))
				local tableKeyWidth <const> = 200
				local tableFlags <const> = ui.TableFlags.Borders
				if ui:BeginTable("charactercreator_bodyparts", 2, tableFlags) then
					ui:TableSetupColumn("Body Part", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Name")
					ui:TableHeadersRow()
					for _i,k in ipairs(ccdata_bodyparts) do
						ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text(k)
						ui:TableNextColumn()
						ui:Text(ccdata.bodyparts[k])
					end
					ui:EndTable()
				end
				if ui:BeginTable("charactercreator_colorgroups", 2, tableFlags) then
					ui:TableSetupColumn("Color Group", ui.TableColumnFlags.WidthFixed, tableKeyWidth)
					ui:TableSetupColumn("Name")
					ui:TableHeadersRow()
					for _i,k in ipairs(ccdata_colorgroups) do
						ui:TableNextRow()
						ui:TableNextColumn()
						ui:Text(k)
						ui:TableNextColumn()
						ui:Text(ccdata.colorgroups[k])
					end
					ui:EndTable()
				end
			end
		end
	end
end

function DebugNetwork:RenderNetworkPlayerData(ui, panel)
	if ui:CollapsingHeader("PlayerData") then
		if TheNet:IsInGame() then
			local playernames = {}
			local playerIDs = {}

			for _, playerID in ipairs(TheNet:GetPlayerList()) do
				table.insert(playernames, TheNet:GetPlayerName(playerID) or "")
				table.insert(playerIDs, playerID)
			end

			local index = 1
			-- Find the previously selected player:
			for i, v in ipairs(playerIDs) do
				if v == selectedPlayerID then
					index = i
				end
			end
			selectedPlayerID = playerIDs[index]

			local changed, idx = ui:Combo("Players##1", index, playernames)
			if changed then
				selectedPlayerID = playerIDs[idx]
			end

			if selectedPlayerID ~= nil then
				ui:Indent()
				self:RenderNetworkPlayerDataUnlocksForPlayer(ui, selectedPlayerID);
				ui:Unindent()	
			end
		else
			ui:Text("Not in network game")
		end
	end
end



function DebugNetwork:RenderLocalBlobs(ui, panel)
	if ui:CollapsingHeader("Blobs (Local)") then
		if not TheNet:ShowBlobDebugger() then
			local localblobs = TheNet:GetLocalBlobs()
			if localblobs then
				local index = 1

				-- Find the previously selected blobID:
				for i, v in ipairs(localblobs) do
					if v == selectedLocalBlob then
						index = i
					end
				end
				selectedLocalBlob = localblobs[index]

				local changed, idx = ui:Combo("Blobs##1", index, localblobs)
				if changed then
					selectedLocalBlob = localblobs[idx]
				end

				if selectedLocalBlob ~= nil then
					ui:BeginChild("HexViewer##1", 0, 200, true, ui.WindowFlags.HorizontalScrollbar)
						TheNet:ViewLocalBlob(selectedLocalBlob)
					ui:EndChild()
				end
			end
		end
	end
end

function DebugNetwork:RenderRemoteBlobs(ui, panel)
	if ui:CollapsingHeader("Blobs (Remote)") then
		local clients = TheNet:GetRemoteClientsList()

		if clients then
			local index = 1

			-- Find the previously selected blobID:
			for i, v in ipairs(clients) do
				if v == selectedRemoteClient then
					index = i
				end
			end
			selectedRemoteClient = clients[index]

			local changed, idx = ui:Combo("Remote Client##1", index, clients)
			if changed then
				selectedRemoteClient = clients[idx]
			end

			if selectedRemoteClient ~= nil then
				local remoteblobs = TheNet:GetRemoteBlobs(selectedRemoteClient)
				if remoteblobs then
					local index2 = 1

					-- Find the previously selected blobID:
					for i, v in ipairs(remoteblobs) do
						if v == selectedRemoteBlob then
							index2 = i
						end
					end
					selectedRemoteBlob = remoteblobs[index2]

					local changed, idx = ui:Combo("Blobs##2", index2, remoteblobs)
					if changed then
						selectedRemoteBlob = remoteblobs[idx]
					end

					if selectedRemoteBlob ~= nil and selectedRemoteClient ~= nil then
						ui:BeginChild("HexViewer##2", 0, 200, true, ui.WindowFlags.HorizontalScrollbar)
						TheNet:ViewRemoteBlob(selectedRemoteBlob, selectedRemoteClient)
						ui:EndChild()
					end
				end
			end
		end
	end
end

function DebugNetwork:RenderPanel( ui, panel )

	local clients = self:GatherClientsData()

	-- Render the total kbps being send and received from this machine:
	ui:Columns(2, "Graphs")
	local colw = ui:GetColumnWidth()

--	ui:SetColumnWidth(0, colw * 0.5)
--	ui:SetColumnWidth(1, colw * 0.5)

	local sendval = totalsendkbps and #totalsendkbps > 0 and  math.floor(totalsendkbps[#totalsendkbps]) or 0.0
	ui:SetNextItemWidth()	-- will set it to -FLT_MIN
	ui:PlotLines("", "send "..tostring(sendval).."kbps (max = "..tostring(math.floor(maxsendkpbs))..")", totalsendkbps, 0, 0.0, 256.0, 80.0)
	ui:NextColumn()

	local recvval = totalrecvkbps and #totalrecvkbps > 0 and math.floor(totalrecvkbps[#totalrecvkbps]) or 0.0
	ui:SetNextItemWidth()	-- will set it to -FLT_MIN
	ui:PlotLines("", "recv "..tostring(recvval).."kbps (max = "..tostring(math.floor(maxrecvkpbs))..")", totalrecvkbps, 0, 0.0, 256.0, 80.0)
	ui:Columns()

	panel.open_next_in_new_panel = true


	-- Render the checkbox to show network ownership:
	local showing = TheSim:GetDebugRenderEnabled() and TheSim:GetDebugNetworkRenderEnabled()
	if ui:Checkbox("Show Network Ownership dots (Shift-Alt-N)", showing) then
		TheSim:SetDebugRenderEnabled(true)
		TheSim:SetDebugNetworkRenderEnabled(not TheSim:GetDebugNetworkRenderEnabled())
	end



	-- Render the list of clients:
	self:RenderClients(ui, clients)
	self:RenderBadConnectionSimulator(ui)

	self:RenderNetworkState(ui, panel)
	self:RenderNetworkWorldDataPanel(ui)
	self:RenderNetworkPlayerData(ui, panel)
	self:RenderPlayers(ui)
	self:RenderNetworkEvents(ui, panel)
	
	-- Render the list of entities:
	self:RenderEntities(ui, panel)


	-- Blobs:
	self:RenderLocalBlobs(ui, panel)
	self:RenderRemoteBlobs(ui, panel)

end

DebugNodes.DebugNetwork = DebugNetwork

return DebugNetwork
