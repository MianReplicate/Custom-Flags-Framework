-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

local function isCommand(syntax)
	return syntax:match("{(.*)}")
end

local function cloneDict(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local function dictToArray(t)
    local list = {}

    for k, v in pairs(t) do
        table.insert(list, {
            key = k,
            value = v
        })
    end

    return list
end

local function shuffleArray(arr)
    for i = #arr, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
    return arr
end

local function findResults(str)
    local results = {}

    local commaStartingIdx = 1  -- Start looking from the first character
    local braceStartingIdx = nil
    local additionalBraces = 0

    for i = 1, #str do
        local char = str:sub(i, i)

        if(char == "{") then
          if(not braceStartingIdx) then
              braceStartingIdx = i
          else
              additionalBraces = additionalBraces + 1
          end
        elseif(char == "}") then
          if(additionalBraces > 0) then
            additionalBraces = additionalBraces - 1
          else
              table.insert(results, str:sub(braceStartingIdx, i))
              braceStartingIdx = nil
              commaStartingIdx = i + 1 -- Move start index after the closing brace
          end
        end

        if(not braceStartingIdx) then
            if(char == ",") then
                if(commaStartingIdx and commaStartingIdx < i) then
                    table.insert(results, str:sub(commaStartingIdx, i - 1))
                end
                commaStartingIdx = i + 1 -- Move index to next character
            end
        end
    end

    -- Add the last segment if no trailing comma
    if(commaStartingIdx <= #str) then
        table.insert(results, str:sub(commaStartingIdx))
    end

    return results
end

local function findArgResults(str)
    local results = {}

    local colonStartingIndex = 1
    local braceCount = 0

    for i = 1, #str do
        local char = str:sub(i, i)
        
        if(char == "{") then
          braceCount = braceCount + 1
        elseif(char == "}") then
          braceCount = braceCount - 1
        end
		
		if(char == ":" and braceCount <= 0)then
            table.insert(results, str:sub(colonStartingIndex, i-1))
            colonStartingIndex = i + 1 -- Move start index after the closing brace
        end

    end
    table.insert(results, str:sub(colonStartingIndex, #str))

    return results
end

local function randomPercentage()
	return math.random(1, 100) / 100
end

local function findValue(tble, value)
	for i, _value in ipairs(tble) do
		if(_value == value) then
			return i;
		end
	end
end

local function getRandomKeyFromDict(dict)
	local names = {}
	for name, _ in pairs(dict) do
		table.insert(names, name)
	end

	local randomName = names[math.random(1, #names)]
	return randomName
end

local function getRandomValueFromDict(dict)
	return dict[getRandomKeyFromDict(dict)]
end

local function containsString(str, look)
    local startPos, endPos = str:find(look)

    while startPos do
        local before = startPos == 1 or not str:sub(startPos - 1, startPos - 1):match("%a")
        local after = endPos == #str or not str:sub(endPos + 1, endPos + 1):match("%a")

        if before and after then
            return true
        end

        startPos, endPos = str:find(look, endPos + 1)
    end

    return false
end

local function getLengthOfDict(dict)
	local count = 0
	for _, _ in pairs(dict) do
		count = count + 1
	end
	return count;
end

local function getTeams()
	if(Extensions.Get("lovebites")) then
		return MultiTeamBattleDataExtensions.GetTeams()
	end

	return {
		[Team.Blue] = "Blue",
		[Team.Red] = "Red",
		[Team.Neutral] = "Neutral"
	}
end

function MianFlagFramework:passesBlacklist(nameToMatch)
	local isInList = false
	nameToMatch = nameToMatch:upper()
	for name in string.gmatch(self.Blacklist, "([^,]+)") do
		if(name:upper():gsub(" %(CLONE%)", "") == nameToMatch) then
			isInList = true
			break
		end
	end

	if(isInList and self.IsWhitelist) then
		return true
	elseif(not isInList and not self.IsWhitelist) then
		return true
	end

	return false
end

function MianFlagFramework:getAllReplaceableMaterials(gameObject)
	local materials = {}
	local function checkRenderer(renderer)
		if(renderer.enabled) then
			if(renderer.gameObject.name:upper() ~= "SOLDIER") then
				for _, material in ipairs(renderer.materials) do
					if(self:canBeReplacedWithFlagTexture(renderer.material)) then
						table.insert(materials, material)
					end
				end
			end
		end
	end

	for _, renderer in ipairs(gameObject.GetComponentsInChildren(MeshRenderer)) do
		checkRenderer(renderer)
	end

	for _, renderer in ipairs(gameObject.GetComponentsInChildren(SkinnedMeshRenderer)) do
		checkRenderer(renderer)
	end

	return materials
end

function MianFlagFramework:canBeReplacedWithFlagTexture(material)
	local nameLength = #material.name
	if(nameLength >= 4) then
		local name = ""
		name = material.name:upper()

		if((self.AggressiveFlagSearch and name:match("FLAG")) or containsString(name, "FLAG")) then return true end
		
		if(nameLength >= 8) then
			name = material.name:upper()
			if(name) == "CFF_FLAG" then return true end
		end
	end
end

function MianFlagFramework:Awake()
	self.version = "3.0.3"
	self.gameObject.name = "Custom Flag Framework"
	self.Actors = ActorManager.actors
	self.Flags = ActorManager.capturePoints

	local config = self.script.mutator.configuration
	self.ChangeTeamNamesToFlagName = config.GetBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = config.GetBool("ChangeTeamColorToFlagColor")
	self.ChangeScoreboardToTeamFlag = config.GetBool("ChangeScoreboardToTeamFlag")
	self.IgnoreFailedCapturePoint = config.GetBool("IgnoreFailedCapturePoint")
	self.AlertedUser = config.GetBool("IgnoreFailedCapturePoint")
	self.AvoidDupeColors = config.GetBool("AvoidDupeColors")
	self.FunnyMode = config.GetBool("FunnyMode")
	self.AvoidDupeData = config.GetBool("AvoidDupeData")
	self.ApplyTextureToVehicles = config.GetBool("ApplyTextureToVehicles")
	self.ApplyTextureToWeapons = config.GetBool("ApplyTextureToWeapons")
	self.AggressiveFlagSearch = config.GetBool("AggressiveFlagSearch")
	self.ChanceInGroup = config.GetRange("ChanceInGroup") / 100
	self.ChanceFromPoint = config.GetRange("ChanceFromPoint") / 100
	self.ExecuteConfigForTeam = config.GetDropdown("ExecuteConfigForTeam")
	self.AssignedMeshes = config.GetString("Meshes")
	self.AssignedVoices = config.GetString("Voices")
	self.DebugMode = config.GetBool("DebugMode")
	self.SetIndividualActorColor = config.GetBool("SetActorColorToFlagColor")
	self.Blacklist = config.GetString("Blacklist")
	self.IsWhitelist = config.GetBool("IsWhitelist")
	self.IsCloth = self.targets.IsCloth
	self.TemplateMaterial = self.targets.TemplateMaterial
	self.RegisteringPacks = false
	self.OverlayLabel = GameObject.Find("Ingame UI Container(Clone)/New Ingame UI/Overlay Label Element/Overlay Label")
	self.VictoryText = GameObject.Find("Ingame UI Container(Clone)/Victory UI Canvas/Victory Panel/Victory Focus/Victory Text")
	self.OldVehicleTextures = {}

	self.TeamToData = {}
	-- Mutator -> metadata, meshes, flags
	self.MutatorPacks = {}
	self.CachedGroups = {
		meshes = {},
		flags = {},
		combined = {},
	}
	self.CachedTextureToMaterials = {}

	-- Actors are assigned datas
	self.ActorsToTexture = {}
	self.ActorsHaveListener = {}

	self.TeamToActors = {}
	self.ActorsToStoredMeshRenderer = {}

	self.TextureForSpawn = {}
	self.UserLists = {}
	self.FlagToMeshes = {}
	self.FlagToVoices = {}
	self.PlayerData = {
		flags = {},
		meshes = {},
		flagsArray = {},
		meshesArray = {}
	}

	self.VanillaTeamList = {[Team.Blue] = "Blue",[Team.Red] = "Red"}
	self.TeamToName = getTeams()

	self.TeamVoiceMutators = {

	}

	for team, _ in pairs(self.TeamToName) do
		self.TeamToActors[team] = {}
	end

	self.commandContext = {
		type = nil,
		allowDupes = false
	}

	self.runnableStringCommands = {
		VOICE = function(flags, voices)
			if(self.commandContext.type ~= "voices") then 
				error("VOICE command cannot be used in this field!")
			end
			if(#voices <= 0) then self:log("No voices given for flags to use") return end
			if(#voices > 1) then self:log("Cannot assign more than one voice to a flag") return end
			for _, flag in ipairs(flags) do
				self.FlagToVoices[flag:upper()] = voices[1]
			end
		end,
		ACCESSORY = function(flags, meshes)
			if(self.commandContext.type ~= "meshes") then
				error("ACCESSORY command cannot be used in this field!")
			end

			local meshTable = {}
			for _, mesh in ipairs(meshes) do
				mesh = mesh:upper()
				local data = self:getData("meshes", mesh)
				if(data) then
					table.insert(meshTable, data)
				else
					self:log(mesh.." is not a valid accessory!")
				end
			end

			for _, flag in ipairs(flags) do
				self.FlagToMeshes[flag:upper()] = meshTable
			end
		end,
		PLAYER = function(operation, list)
			local operator = operation[1]
			if(operator == "FLAGS") then
				for _, name in ipairs(list) do
					local data = self:getData("flags", name)
					if(data) then
						self.PlayerData.flags[name] = data
						table.insert(self.PlayerData.flagsArray, data)
					end
				end
			elseif(operator == "MESHES") then
				for _, name in ipairs(list) do
					local data = self:getData("meshes", name)
					if(data) then
						self.PlayerData.meshes[name] = data
						table.insert(self.PlayerData.meshesArray, data)
					end
				end
			end
		end,
		LIST = function(operation, name, list)
			local operator = operation[1]
			name = name[1]

			if(operator and name) then
				name = name:upper()
				if(operator == "ADD" and list) then
					self.UserLists[name] = list
				elseif(operator == "GET") then
					return self.UserLists[name]
				end
			end
		end,
		COUNT = function(list)
			local count
			local exist = list[1]
			if(not exist) then
				count = getLengthOfDict(list)
			else
				count = #list
			end
			return {count}
		end,
		OPERATOR = function(operator, numToOperate, numbers)
			operator = operator[1]
			local finalNum = numToOperate[1]
			for _, number in ipairs(numbers) do
				if(operator == "ADD") then
					finalNum = finalNum + number
				elseif(operator == "MULTIPLY") then
					finalNum = finalNum * number
				elseif(operator == "DIVIDE") then
					finalNum = finalNum / number
				end
			end
			finalNum = math.ceil(finalNum)

			return {finalNum}
		end,
		ALLMUTATORS = function(type, exclude)
			type = type[1]:lower() -- either "FLAGS" or "MESHES"
			local names = {}
			for name, _ in pairs(self:getMutatorsWithType(type, exclude)) do
				table.insert(names, name)
			end
			return names
		end,
		ALL = function(mutatorIds)
			local names = {}
			local type = self.commandContext.useTypes and self.commandContext.type
			local unusedDatas = self:getAllNonUsedDatas(type)
			for _, mutatorId in ipairs(mutatorIds) do
				local datas = self:getDatasFromMutator(type, mutatorId)
				if(datas) then
					for name, _ in pairs(datas) do
						if(not unusedDatas or self.commandContext.allowDupes or unusedDatas[name]) then
							table.insert(names, name)
						end
					end
				end
			end
			return names
		end,
		RANDOMIZE = function(datas, amount)
			local testing = amount[1]
			amount = tonumber(testing)

			if(not amount) then
				error(tostring(testing).." is not a number!")
			end

			local randomizationPool = {}
			local unusedDatas = self:getAllNonUsedDatas(self.commandContext.useTypes and self.commandContext.type)
			for _, name in ipairs(datas) do
				if(not unusedDatas or self.commandContext.allowDupes or unusedDatas[name]) then
					table.insert(randomizationPool, name)
				end
			end

			local names = {}
			while(amount > 0) do
				if(#randomizationPool <= 0) then break end -- no more to pull from :<

				local randomIndex = math.random(1, #randomizationPool)
				local randomName = randomizationPool[randomIndex]
				table.remove(randomizationPool, randomIndex)
				amount = amount - 1

				table.insert(names, randomName)
			end

			return names
		end,
		TEAMNAME = function(flags, name)
			if(self.commandContext.type ~= "flags") then return nil end

			name = name[1]
			for _, flagName in ipairs(flags) do
				local texData = self:getData("flags", flagName)
				texData.teamName = name
			end
		end,
		TEAMCOLOR = function(flags, color)
			if(self.commandContext.list ~= "flags") then return nil end

			local newColor = Color(tonumber(color[1])/255, tonumber(color[2])/255, tonumber(color[3])/255)
			for _, flagName in ipairs(flags) do
				local texData = self:getData("flags", flagName)
				texData.teamColor = newColor
			end
		end,
		FLAGCOLOR = function(flags, color)
			if(self.commandContext.list ~= "flags") then return nil end

			local newColor = Color(tonumber(color[1])/255, tonumber(color[2])/255, tonumber(color[3])/255)
			for _, flagName in ipairs(flags) do
				local texData = self:getData("flags", flagName)
				texData.overrideMaterialColor = newColor
			end
		end
	}

	for team, _ in pairs(self.TeamToName) do
		self.TeamToData[team] = {
			flags = {},
			meshes = {},
			flagsArray = {},
			meshesArray = {}
		}
	end

	for _, actor in ipairs(self.Actors) do
		if(actor.team) ~= Team.Neutral then 
			table.insert(self.TeamToActors[actor.team], actor)
		 end
	end
end

function MianFlagFramework:Start()
	self:log("Starting framework version "..self.version)
    self.RegisteringPacks = true
    local scriptedBehaviours = GameObject.FindObjectsOfType(ScriptedBehaviour)
    for _, behaviour in ipairs(scriptedBehaviours) do
		if(behaviour.self ~= nil) then
			if(behaviour.self.CustomFlags ~= nil) then
				self:addFlagPack(behaviour.self)
			end
			if(behaviour.self.CustomMeshes ~= nil) then
				self:addMeshPack(behaviour.self)
			end
		end
    end
    self.RegisteringPacks = false
    self.FinishedAddingPacks = true
	self:log("Finished registering all packs! Starting the configuration...")

	for _, actor in ipairs(ActorManager.actors) do
		if(self.TeamToName[actor.team] == nil) then
			self:log("Detected Multi-Teams Battle but Love Bites is not installed!")
			self.gameObject.GetComponent(TriggerScriptedSignal).Send("detectedMTWithoutLB")
			return
		end
	end
	
	for _, capturePoint in ipairs(self.Flags) do
		self:autoSetPointMaterial(capturePoint)
		self.script.AddValueMonitor("pendingOwner", "onPendingOwnerChanged", capturePoint)
	end

	local searchForTeamVoiceMutators = {
		"TeamVoicesMutator(Eagle)(Clone)",
		"TeamVoicesMutator(Raven)(Clone)"
	}

	for _, name in ipairs(searchForTeamVoiceMutators) do
		local obj = self.gameObject.Find(name)
		if(obj ~= nil) then
			local component = obj.GetComponent(ScriptedBehaviour)
			if(component.self.AddActorOverride ~= nil) then
				table.insert(self.TeamVoiceMutators, component)
			end
		end
	end

	if(#self.TeamVoiceMutators > 0) then
		self:log("Detected Team Voices!")
	end

	if(Extensions.Get("lovebites")) then
		self:log("Detected Mian's Love Bites!")
	end

	GameEvents.onCapturePointCaptured.AddListener(self,"autoSetPointMaterial")
	GameEvents.onCapturePointNeutralized.AddListener(self,"autoSetPointMaterial")
	GameEvents.onActorSpawn.AddListener(self, "onActorSpawn")
	GameEvents.onMatchEnd.AddListener(self, "onMatchEnd")

	if(self.ApplyTextureToVehicles) then
		GameEvents.onVehicleSpawn.AddListener(self, "onVehicleSpawned")
	end

	local TeamToName = cloneDict(self.TeamToName)
	TeamToName[Team.Neutral] = nil
	TeamToName = dictToArray(TeamToName)

	local decision = self.ExecuteConfigForTeam

	if(decision == 0 or decision == 1) then
		for index, value in ipairs(TeamToName) do
			if(value.key == (decision == 0 and "Blue") or value.key == (decision == 1 and "Red")) then
				table.insert(TeamToName, table.remove(TeamToName, index), 1);
				break
			end
		end
	else
		TeamToName = shuffleArray(TeamToName)
	end

	self.commandContext = {
		type = "meshes",
		allowDupes = true
	}
	self:executeStringList(self.AssignedMeshes)

	self.commandContext = {
		type = "voices",
		allowDupes = true
	}
	self:executeStringList(self.AssignedVoices)

	-- Indexes will still work with enums, so do not worry about team
	local index = -1

	for _, pair in pairs(TeamToName) do
		local team = pair.key
		local name = pair.value
		index = index + 1

		local vanillaTeamName = self.VanillaTeamList[team]
		local configuration
		if(vanillaTeamName) then 
			configuration = self.script.mutator.configuration.GetString(vanillaTeamName.."FlagTextures")
		else
			configuration = self:findTexturesForExtraTeam(name, self.script.mutator.configuration.GetString("ExtraFlagTextures")) or ""
		end

		local texDatas = {}

		self.commandContext = {
			type = "flags",
			useType = true
		}

		local results = self:executeStringList(configuration)
		for _, _name in ipairs(results) do
			_name = _name:upper()
			local data = self:getData(self.commandContext.type, _name)
			if(data) then
				self:putDataForTeam(team, data)
				table.insert(texDatas, data)
			else
				self:log(_name.." is an invalid flag! Did you name it incorrectly?")
			end
		end

		local firstTexData = texDatas[1]
		local lastTexData = texDatas[#texDatas]

		if(firstTexData and lastTexData) then
			local teamSpecific = (team == Team.Blue and "Team Panel") or (team == Team.Red and "Team Panel (1)") or ("MTB Scoreboard Column "..index)
			if(self.ChangeTeamNamesToFlagName) then
				local name = (firstTexData == lastTexData and firstTexData.teamName:upper()) or firstTexData.teamName:upper().." ALLIES"
		
				GameManager.SetTeamName(team, name)
				GameObject.Find("Scoreboard Canvas/Panel/"..teamSpecific.."/Header Panel/Text Team").GetComponent(Text).text = name
			end
	
			if(self.ChangeTeamColorToFlagColor) then
				local color = firstTexData.teamColor or ColorScheme.GetTeamColor(team)

				local keepLoopin = true
				while(keepLoopin and self.AvoidDupeColors) do
					local check = false

					for _, _pair in pairs(TeamToName) do
						local _team = _pair.key
						if(_team ~= team) then
							local otherTeamColor = ColorScheme.GetTeamColor(_team)
							if(otherTeamColor.r == color.r and otherTeamColor.g == color.g and otherTeamColor.b == color.b) then
								color.r = math.random(0, 255) / 255
								color.g = math.random(0, 255) / 255
								color.b = math.random(0, 255) / 255
								check = true
								break
							end
						end
					end

					keepLoopin = check
				end

				color = Color(color.r, color.g, color.b)
				local funnyColor = Color(color.r * 255, color.g * 255, color.b * 255)
				ColorScheme.SetTeamColor(team, (self.FunnyMode and funnyColor) or color)
				color.a = 0.392
				GameObject.Find("Scoreboard Canvas/Panel/"..teamSpecific.."/Header Panel").GetComponent(Image).color = color
			end

			if(self.ChangeScoreboardToTeamFlag) then
				local teamPanelImage = GameObject.Find("Scoreboard Canvas/Panel/"..teamSpecific).GetComponent(Image)
				-- local a = teamPanelImage.color.a
				teamPanelImage.material = self:createOrGetExistingMaterialFromTexture("UI", firstTexData.texture, nil, 1, teamPanelImage.material)
				local color = Color(0.6, 0.6, 0.6, 0.5)
				teamPanelImage.color = color
			end

			self.TextureForSpawn[team] = {texture=firstTexData.texture}
		end

		for _, capturePoint in pairs(self.Flags) do
			if(capturePoint.owner == team) then
				local texData = self:getAndIncrementRunnerUp(team)
				if(texData) then
					self:setPointMaterial(capturePoint, self:createOrGetExistingMaterialFromTexture("Flags", texData.texture, texData.overrideMaterialColor))
				end
			end
		end
	end

	if(self.ApplyTextureToVehicles) then
		for _, vehicle in ipairs(ActorManager.vehicles) do
			self:onVehicleSpawned(vehicle)
		end
	end
end
-- The two functions below are to handle compatiblity with old mutator packs
function MianFlagFramework:addTextureData()
	error("Detected an outdated flag mutator script! Please get the newest lua file from GitHub. This function is only here to tell you this. Otherwise it does absolutely nothing.")
end

function MianFlagFramework:addTexturePack(mutatorName, mutator)
	mutator.CustomFlagToTeamColors = mutator.CustomFlagTeamColors
	mutator.CustomFlagTeamColors = nil
end

function MianFlagFramework:validatePack(mutatorData, validateTable)
	if(not mutatorData) then
		error("A pack is trying to add data without metadata! Cannot proceed")
	end

	if(not self.RegisteringPacks) then
		-- Many packs for CFF have already been made, so we have to just ignore them if they are trying to add data.
		return false
	end

	local name = mutatorData.gameObject.name:upper():gsub("%(CLONE%)", ""):gsub("%s", "")
	if(self.MutatorPacks[name]) then
		self:log("<color=RED>A pack with the name, "..name..", is already known. The developer should really change the name of this pack but for now, we can use fallback code to register the pack under a different name. Please tell the developer to change their pack's name</color>")
		local dupe = 0
		local tryName
		repeat
			dupe = dupe + 1
			tryName = name.."_"..dupe
		until not self.MutatorPacks[tryName]
		name = tryName
	end

	for key, validate in pairs(validateTable) do
		validate = validate or function(value)
			if(value == nil) then
				error(name.." is missing some required metadata, please get the newest lua file from one of my template packs if you are the developer. The missing metadata is: "..key)
			end
		end
		validate(mutatorData[key])
	end

	return true, name
end

function MianFlagFramework:addMeshPack(mutatorData)
	local name = mutatorData.gameObject.name:upper()
	local softFailed = false
	local success, errormsg = pcall(function()
		local canRun, _name = self:validatePack(mutatorData, {
			cover = nil,
			CustomMeshes = nil,
		})
		if(not canRun) then
			softFailed = true
			return
		end
		name = _name or name
		mutatorData.name = name

		local mutatorTable = self.MutatorPacks[name] or {
			metadata = mutatorData
		}
		mutatorTable.meshes = {}

		if(#mutatorData.CustomMeshes <= 0) then
			self:log("Migrating old mesh pack to new format: "..name)

			local customMeshes = mutatorData.dataContainer.GetGameObjectArray("Mesh")

			for _, mesh in ipairs(customMeshes) do
				local renderer = mesh.GetComponent(SkinnedMeshRenderer)
				table.insert(mutatorData.CustomMeshes, {mesh=renderer.sharedMesh, materials=renderer.materials})
			end
		end

		for _, meshData in pairs(mutatorData.CustomMeshes) do
			local mesh = meshData.mesh
			local materials = meshData.materials
			local name = mesh.name:upper()
			mesh.name = name
			
			local nameToUse = mesh.name
			local alreadyExists = self:getData(nameToUse)

			if(alreadyExists and self.AvoidDupeData) then
				local repeatCount = 0
				local testName = nameToUse
				repeat
					repeatCount = repeatCount + 1
					testName = nameToUse.."_"..repeatCount
				until not self:getData(testName)
				nameToUse = testName
			end
			mesh.name = nameToUse

			local meshGroup = {
				mesh=mesh,
				name = nameToUse,
				materials = materials
			}
			mutatorTable.meshes[nameToUse] = meshGroup
			self:cacheData("meshes", nameToUse, meshGroup)
		end
		
		self.MutatorPacks[name] = mutatorTable
	end)

	if(success) then
		if(not softFailed) then
			self:debug("Added new pack: "..name)			
		end 
	else
		self:log("Failed to load pack: "..name)
		self:log("<color=red>Error: "..errormsg.."</color>")
	end
end

function MianFlagFramework:addFlagPack(mutatorData)
	local name = "Unknown"
	local success, errormsg = pcall(function()
		local canRun, _name = self:validatePack(mutatorData, {
			cover = function() end,
			CustomFlags = function() end,
			CustomFlagToTeamColors = function(value)
				if(value == nil and mutatorData.CustomFlagTeamColors == nil) then
					error("CustomFlagToTeamColors is missing for "..name)
				end
			end
		})
		if(not canRun) then return end
		name = _name or name
		mutatorData.name = name
		
		local mutatorTable = self.MutatorPacks[name] or {
			metadata = mutatorData
		}
		mutatorTable.flags = {}

		for index, texture in pairs(mutatorData.CustomFlags) do
			texture.name = texture.name:upper()
			local nameToUse = texture.name
			local alreadyExists = self:getData(nameToUse)

			if(alreadyExists and self.AvoidDupeData) then
				local repeatCount = 0
				local testName = nameToUse
				repeat
					repeatCount = repeatCount + 1
					testName = nameToUse.."_"..repeatCount
				until not self:getData(testName)
				nameToUse = testName
			end
			self:debug("Adding flag texture: "..nameToUse)
			texture.name = nameToUse
			local CustomFlagToTeamColors = mutatorData.CustomFlagToTeamColors or mutatorData.CustomFlagTeamColors
			local flagGroup = {
				texture=texture,
				name = nameToUse,
				teamColor=CustomFlagToTeamColors[index] or Color(math.random(1, 255)/255, math.random(1, 255)/255, math.random(1, 255)/255, 1),
				teamName=nameToUse,
				overrideMaterialColor=nil
			}
			mutatorTable.flags[nameToUse] = flagGroup
			self:cacheData("flags", nameToUse, flagGroup)
		end
		
		self.MutatorPacks[name] = mutatorTable
	end)

	if(success) then
		self:debug("Added new pack: "..name)
	else
		self:warn("Failed to load pack: "..name)
		self:warn("Error: "..errormsg)
	end
end

function MianFlagFramework:createOrGetExistingMaterialFromTexture(list, texture, overrideColor, overrideScale, overrideMaterial)
	local material = self.CachedTextureToMaterials[texture.name] or Material(overrideMaterial or self.TemplateMaterial)
	self:updateMaterialFromTexture(material, texture, overrideColor, overrideScale)

	if(not self.CachedTextureToMaterials[list]) then
		self.CachedTextureToMaterials[list] = {}
	end
	self.CachedTextureToMaterials[list][texture.name] = material
	return material
end

function MianFlagFramework:updateMaterialFromTexture(material, texture, overrideColor, overrideScale)
	material.SetTexture("_MainTex", texture)
	material.name = texture.name:upper()

	local yScale = overrideScale or (self.IsCloth.activeSelf and 1.4) or 1
	material.SetTextureScale("_MainTex", Vector2(1, yScale))

	if(overrideColor) then
		material.color = Color(overrideColor[1],overrideColor[2],overrideColor[3],1)
	end
end

function MianFlagFramework:getAllNonUsedDatas(type)
	local givenDatas = self:getDatas(type)
	for _, datas in pairs(self.TeamToData) do
		local lists = {}
		if(not type) then
			for name, list in pairs(datas) do
				if(name ~= "flagsArray" and name ~= "meshesArray") then
					table.insert(lists, list)
				end
			end
		elseif(datas[type]) then
			table.insert(lists, datas[type])
		end
		
		for _, dataList in ipairs(lists) do
			for name, _ in pairs(dataList) do
				if(givenDatas[name]) then
					givenDatas[name] = nil
				end
			end
		end
	end
	return givenDatas
end

function MianFlagFramework:putDataForTeam(team, data)
	if(not team or not data) then
		return
	end

	local name = data.name:upper()
	local displayName = self:getNameFlair(data)

	local type = (data.texture and "flags") or "meshes"
	if(self.TeamToData[team][type][name]) then
		self:log(displayName.." was already added into "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright).."!")
		return
	end
	
	self.TeamToData[team][type][name] = data
	table.insert(self.TeamToData[team][type.."Array"], data)

	self:debug(displayName.." was added to "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright))
end

-- Use externally if needed to validate configuration
function MianFlagFramework:validateConfiguration(config)
	local results, hasFailedSomewhere = self:executeStringList(config)
	for _, _name in ipairs(results) do
		_name = _name:upper()
		local data = self:getData(self.commandContext.type, _name)
		if(not data) then
			self:log(_name.." is an invalid flag! Did you name it incorrectly?")
			hasFailedSomewhere = true
		end
	end
	return not hasFailedSomewhere
end

function MianFlagFramework:executeCommandFromSyntax(syntax)
	syntax = syntax:upper()
	local _, endIndex, command = syntax:find("([^:]+)")
	local argStrings = syntax:sub(endIndex+2)

	local commandFunction = self.runnableStringCommands[command]
	if(commandFunction) then
		local args = {}
		for _, arg in ipairs(findArgResults(argStrings)) do
			local returnArg = {}
			for _, listArg in ipairs(findResults(arg)) do
				local command = isCommand(listArg)
				if(command) then
					local _, argsFromCommand = self:executeCommandFromSyntax(command)
					if(argsFromCommand) then
						for _, newArg in pairs(argsFromCommand) do
							table.insert(returnArg, newArg)
						end
					end
				else
					table.insert(returnArg, listArg)
				end
			end
			table.insert(args, returnArg)
		end

		local success, returnValue = pcall(commandFunction, table.unpack(args))

		if(not success) then
			self:log("<color=red>Syntax failed: "..syntax.."</color>")
			if(returnValue) then
				self:log("<color=red>"..returnValue.."</color>")
			end
		end

		return success, returnValue
	end
end

function MianFlagFramework:executeStringList(string)
	local hasFailedSomewhere = false
	local list = {}
	for _, name in ipairs(findResults(string)) do
		local command = isCommand(name)
		local success, results = nil, nil
		if(command) then
			success, results = self:executeCommandFromSyntax(command)
			if(success and results) then
				for _, _name in ipairs(results) do
					table.insert(list, _name)						
				end
			end
		end

		-- Was success explicitly set to false?
		if(success == false) then
			hasFailedSomewhere = true
		end

		if(not success) then
			table.insert(list, name)
		end
	end
	return list, hasFailedSomewhere
end

function MianFlagFramework:findTexturesForExtraTeam(teamName, string)
	for part in string:gmatch("[^/]+") do
		if(part:sub(1, #teamName) == teamName) then
			return part:sub(#teamName + 3)
		end
	end
end

function MianFlagFramework:Update()
	for team, teamTexture in pairs(self.TextureForSpawn) do
		if(teamTexture.added) then
			teamTexture.added = teamTexture.added - Time.deltaTime
			if(teamTexture.added <= 0) then
				self.TextureForSpawn[team] = nil
			end
		end
	end
end

function MianFlagFramework:getRunnerUp(team)
	local name = self.TeamToName[team]
	self["runnerUp"..name] = self["runnerUp"..name] or 1
	local runnerUp = self["runnerUp"..name]
	local texData = self.TeamToData[team].flagsArray[runnerUp]

	return texData
end

function MianFlagFramework:getAndIncrementRunnerUp(team)
	local name = self.TeamToName[team]
	local runnerUp = self:getRunnerUp(team)
	local num = self["runnerUp"..name]
	num = num + 1
	if(num > #self.TeamToData[team].flagsArray) then
		num = 1
	end
	self["runnerUp"..name] = num
	return runnerUp
end

function MianFlagFramework:onMatchEnd(team)
	if(self.VictoryText and self.VictoryText.activeSelf and self.ChangeTeamNamesToFlagName and (Player.team == Team.Neutral or Player.team == nil or team == Player.team)) then
		local text = self.VictoryText.GetComponent(Text)
		text.text = GameManager.GetTeamName(team).." VICTORY"
	end
end

function MianFlagFramework:ApplyTextureToTarget(target, texture)
    if not target then return false end

    local changed = false
    local materials = self:getAllReplaceableMaterials(target)

	for _, material in ipairs(materials) do
		material.SetTexture("_MainTex", texture)
		material.color = Color(1, 1, 1, 1)
		changed = true
	end

    return changed
end

function MianFlagFramework:onDriverChange()
	local vehicle = CurrentEvent.listenerData
	local driver = vehicle.driver

	local materials = self:getAllReplaceableMaterials(vehicle.gameObject)
	for _, material in ipairs(materials) do
		local texture = (driver and self.ActorsToTexture[driver]) or self.OldVehicleTextures[material]
		material.SetTexture("_MainTex", texture)
		if(not self.OldVehicleTextures[material] and texture and (not driver or texture ~= self.ActorsToTexture[driver])) then
			self.OldVehicleTextures[material] = texture
		elseif(driver and texture == self.ActorsToTexture[driver]) then
			material.color = Color(1, 1, 1, 1)
		end
	end
end

function MianFlagFramework:seatDriver()
	if(not CurrentEvent.listenerData) then return end
	return CurrentEvent.listenerData.driver
end

function MianFlagFramework:onVehicleSpawned(vehicle)
	self:debug("Checking if "..vehicle.vehicleInfo.name.." passes the blacklist..")
	if(not self:passesBlacklist(vehicle.vehicleInfo.name)) then
		self:debug(vehicle.vehicleInfo.name.." does not pass the blacklist!")
		return
	end

	self.script.AddValueMonitor("seatDriver", "onDriverChange", vehicle)

	local materials = self:getAllReplaceableMaterials(vehicle.gameObject)

	for _, material in ipairs(materials) do
		material.SetTexture("_MainTex", nil)
		material.color = Color(1, 1, 1, 1)
	end
end

function MianFlagFramework:monitorActiveWeapon()
	if(not CurrentEvent.listenerData and CurrentEvent.listenerData.isDead) then return end
	return CurrentEvent.listenerData.activeWeapon
end

function MianFlagFramework:onSwapWeapon(weapon, actor)
	local actor = actor or CurrentEvent.listenerData

	if not weapon or (actor.activeSeat and actor.activeSeat.hasActiveWeapon) then return end

	self:debug("Checking if "..weapon.gameObject.name.." passes the blacklist..")
	if(not self:passesBlacklist(weapon.gameObject.name)) then
		self:debug(weapon.gameObject.name.." does not pass the blacklist!")
		return
	end

    local texture = self.ActorsToTexture[actor]
    if not texture then return end

    local weaponChanged = self:ApplyTextureToTarget(weapon.gameObject, texture)

    if weaponChanged and actor.isPlayer then
        self:ApplyTextureToTarget(actor.transform.gameObject, texture)
    end
end

function MianFlagFramework:onActorSpawn(actor)
	self.GameStarted = true

	if(self.ApplyTextureToWeapons and not self.ActorsHaveListener[actor]) then
		self.script.AddValueMonitor("monitorActiveWeapon", "onSwapWeapon", actor)
		self.ActorsHaveListener[actor] = true
	end

	local team = actor.team
	if(not team) then return end
	local datas = (actor.isPlayer and self.PlayerData) or self.TeamToData[actor.team]

	local texture = not actor.isPlayer and randomPercentage() <= self.ChanceInGroup and self.TextureForSpawn[team] and self.TextureForSpawn[team].texture
	local willRandomize = actor.isPlayer or texture or randomPercentage() <= (1 - self.ChanceFromPoint)
	if(not texture and not willRandomize) then
		local closestFlag = nil
		local closestMagnitude = math.huge

		for _, capturePoint in ipairs(self.Flags) do
			if(capturePoint.owner == actor.team
			and capturePoint.flagRenderer
			and capturePoint.flagRenderer.material
			and capturePoint.flagRenderer.material.mainTexture
			and datas.flags[capturePoint.flagRenderer.material.mainTexture.name]) then
				local magnitude = (capturePoint.transform.position - actor.position).magnitude
				if(magnitude < closestMagnitude) then
					closestFlag = capturePoint
					closestMagnitude = magnitude
				end
			end
		end

		if(closestFlag) then
			texture = closestFlag.flagRenderer.material.mainTexture
		end
	end

	if(not texture) then
		local length = #datas.flagsArray
		if(actor.isPlayer and length <= 0) then
			datas = self.TeamToData[actor.team]
			length = #datas.flagsArray
		end
		if(length > 0) then
			texture = datas.flagsArray[math.random(1, length)].texture
			willRandomize = true
		end
	end

	if(texture) then
		self.ActorsToTexture[actor] = texture
		if(willRandomize and not actor.isPlayer) then
			self.TextureForSpawn[team] = {texture=texture,added=1}
		end
	end

	datas = self.FlagToVoices
	local voicePack = texture and datas[texture.name]
	if(voicePack) then
		self:debug("Assigning " ..voicePack.. " to " ..actor.name)
		for _, component in ipairs(self.TeamVoiceMutators) do
			component.self:AddActorOverride(actor, voicePack)
		end
	end

	-- Accessories handled here
	datas = (actor.isPlayer and #self.PlayerData.meshesArray > 0 and self.PlayerData) or self.FlagToMeshes

	actor.RemoveAccessories()

	local randomizationPool = {}
	if(datas == self.PlayerData) then
		for _, data in ipairs(datas.meshesArray) do
			table.insert(randomizationPool, data)
		end
	elseif(texture and datas[texture.name]) then
		for _, data in ipairs(datas[texture.name]) do
			table.insert(randomizationPool, data)
		end
	end

	local skillLevel = (actor.isPlayer and SkillLevel.Elite) or actor.aiController.skillLevel
	local skillToNumber = {
		[SkillLevel.Beginner] = 1,
		[SkillLevel.Normal] = 2,
		[SkillLevel.Veteran] = 3,
		[SkillLevel.Elite] = 4
	}
	local count = skillToNumber[skillLevel]
	while(count > 0 and #randomizationPool > 0) do
		count = count - 1
		local random = math.random(1, #randomizationPool)
		local meshData = randomizationPool[random]
		self:addMeshDataToActor(actor, texture, meshData)
		table.remove(randomizationPool, random)
	end

	if(Extensions.Get("lovebites") and self.SetIndividualActorColor and texture) then
		local data = self:getData("flags", texture.name)
		if(data) then 
			ColorSchemeExtensions.OverrideActorColor(actor, self:getData("flags", texture.name).teamColor)
		end
	end

	self:onSwapWeapon(actor.activeWeapon, actor) -- doesn't run on initial spawn, so we gotta do it ourselves
end

function MianFlagFramework:addMeshDataToActor(actor, texture, meshData)
	local flagMaterial = self:createOrGetExistingMaterialFromTexture("Flat", texture, nil, 1)
	local materials = {}
	for _, material in ipairs(meshData.materials) do
		if(self:canBeReplacedWithFlagTexture(material)) then
			table.insert(materials, flagMaterial)
		else
			table.insert(materials, material)
		end
	end
	actor.AddAccessory(meshData.mesh, materials)
end

function MianFlagFramework:autoSetPointMaterial(capturePoint, newOwner)
	local ownerToUse = self:getOwner(capturePoint)

	if(not ownerToUse or not self.OverlayLabel) then
		return -- prob just game restarting or smth
	end

	local datas = self.TeamToData[ownerToUse]
	local texture

	if(capturePoint.flagRenderer
	and capturePoint.flagRenderer.material
	and capturePoint.flagRenderer.material.mainTexture
	and (datas.flags[capturePoint.flagRenderer.material.mainTexture.name] or (ownerToUse == Player.actor.team and self.PlayerData.flags[capturePoint.flagRenderer.material.mainTexture.name]))) then
		texture = capturePoint.flagRenderer.material.mainTexture
	end
	
	local friendlyActor = self:findFirstFriendlyActorWithinCapturePoint(capturePoint)
	if(friendlyActor and friendlyActor.squad) then
		friendlyActor = friendlyActor.squad.leader or friendlyActor
	end

	local randomNum = math.random(1, #datas.flagsArray)
	if(ownerToUse ~= Team.Neutral) then
		texture = texture
		or (friendlyActor and self.ActorsToTexture[friendlyActor])
		or (self.GameStarted and datas.flagsArray[randomNum] and datas.flagsArray[randomNum].texture)
		or (self:getRunnerUp(ownerToUse) and self:getAndIncrementRunnerUp(ownerToUse).texture)
	end

	if(not texture) then
		if(self.RegisteringPacks and ownerToUse ~= Team.Neutral) then
			self:debug("No textures to use for "..ColorScheme.FormatTeamColor(self.TeamToName[ownerToUse], ownerToUse, ColorVariant.Bright)..": Using DEFAULT")
		end
		if(capturePoint.flagRenderer ~= nil) then
			capturePoint.flagRenderer.material.SetTexture("_MainTex", nil)
			capturePoint.flagRenderer.material.name = "DEFAULT"
		end
		return
	end

	local texData = self:getData("flags", texture.name)

	if(newOwner == ownerToUse) then
		-- This means that the capture point was neutralized
		if(self.OverlayLabel.activeSelf) then
			local textComponent = self.OverlayLabel.GetComponent(Text)
			local _, endI = textComponent.text:find("</color>")
			local nameString = textComponent.text:sub(1, endI)
			local endingString = textComponent.text:sub(endI+1)
	
			local displayName = (self.ChangeTeamNamesToFlagName and texData.teamName) or nameString
			local tColor = (self.ChangeTeamColorToFlagColor and texData.teamColor) or ColorScheme.GetTeamColor(newOwner)
			local color = Color(tColor.r, tColor.g, tColor.b)
			local colorTag = ColorScheme.RichTextColorTag(color)
			local stringToUse = colorTag..displayName.."</color>"..endingString
	
			textComponent.text = stringToUse
		end

		self.TextureForSpawn[capturePoint] = nil
	end
	
	self:setPointMaterial(capturePoint, self:createOrGetExistingMaterialFromTexture("Flags", texture))
end

function MianFlagFramework:setPointMaterial(capturePoint, material)
	local success = pcall(function() 
		capturePoint.flagRenderer.material = material
	end)
	if(not success) then
		if(not self.AlertedUser) then
			self.AlertedUser = true
			self.gameObject.GetComponent(TriggerScriptedSignal).Send("capturePointNotCompatible")
		end
		self:log("<color=#FF0000>Failed to change "..capturePoint.name:upper().."'s flag!</color>")
	end
end

function MianFlagFramework:getOwner(capturePoint)
	return capturePoint.pendingOwner or capturePoint.owner
end

function MianFlagFramework:getMutatorMetadata(list, name)
	local mutatorData = list[string.upper(name)]
	if(not mutatorData) then
		error(name:upper().." is not a valid mutator!")
	end
	return mutatorData.metadata
end

function MianFlagFramework:getDatasFromMutator(listType, name)
	local mutatorData = self.MutatorPacks[name]
	if(not mutatorData) then
		error(name:upper().." is not a valid mutator!")
	end
	local datas = {}
	if(not listType) then
		local validTypes = {"flags", "meshes"}
		for _, type in ipairs(validTypes) do
			local givenDatas = mutatorData[type]
			if(givenDatas) then
				for _name, data in pairs(givenDatas) do
					datas[_name] = data
				end
			end
		end
	else
		datas = mutatorData[listType]
	end

	return datas
end

function MianFlagFramework:getData(type, name)
	if(not name) then
		name = type
		type = nil
	end

	return self:getDatas(type)[name]
end

function MianFlagFramework:getDatas(type)
	type = type or "combined"
	return self.CachedGroups[type]
end

function MianFlagFramework:cacheData(type, name, group)
	self.CachedGroups[type][name] = group
	self.CachedGroups.combined[name] = group
end

function MianFlagFramework:getMutatorsWithType(type, exclude)
	local mutatorPacks = {}
	for name, mutatorPack in pairs(self.MutatorPacks) do
		if(mutatorPack[type] and (not exclude or (exclude and not findValue(exclude, name)))) then
			mutatorPacks[name] = mutatorPack
		end
	end
	return mutatorPacks
end

function MianFlagFramework:findFirstFriendlyActorWithinCapturePoint(capturePoint)
	local team = self:getOwner(capturePoint)
	if(not team or team == Team.Neutral) then return end
	
	local toUse = self.TeamToActors[team]
	for _, actor in ipairs(toUse) do
		if(actor.currentCapturePoint == capturePoint) then
			return actor
		end
	end
end

function MianFlagFramework:pendingOwner()
	return CurrentEvent.listenerData.pendingOwner
end

function MianFlagFramework:onPendingOwnerChanged()
	self:autoSetPointMaterial(CurrentEvent.listenerData)
end

function MianFlagFramework:getNameFlair(data)
	if(not data) then return "" end
	local colorToUse = data.teamColor or Color(1, 1, 1)
	return ColorScheme.RichTextColorTag(Color(colorToUse.r, colorToUse.g, colorToUse.b))..data.name.."</color>"
end

function MianFlagFramework:debug(...)
	if(self.DebugMode or Debug.isTestMode) then
		self:log(...)
	end
end

function MianFlagFramework:log(...)
	local string = "<color=#fc0fc0>[Custom Flag Framework]:</color> "
	for _, extraArg in ipairs({...}) do
		string = string..tostring(extraArg)
	end
	print(string)
end

function MianFlagFramework:warn(...)
	local string = "<color=#fc0fc0>[Custom Flag Framework]:</color> <color=#FFFF00>"
	for _, extraArg in ipairs({...}) do
		string = string..tostring(extraArg)
	end
	string = string.."</color>"
	print(string)
end