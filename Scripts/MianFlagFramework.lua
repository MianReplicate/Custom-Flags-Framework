-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

local function isCommand(syntax)
	return syntax:match("{(.*)}")
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

function MianFlagFramework:canBeReplacedWithFlagTexture(material)
	return #material.name >= 4 and material.name:sub(1, 4):upper() == "FLAG"
end

function MianFlagFramework:Awake()
	self.version = "2.1.0"
	self.gameVersion = "30"
	self.gameObject.name = "Custom Flag Framework"
	self.Actors =  ActorManager.actors
	self.Flags = ActorManager.capturePoints
	self.ChangeTeamNamesToFlagName = self.script.mutator.GetConfigurationBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = self.script.mutator.GetConfigurationBool("ChangeTeamColorToFlagColor")
	self.ChangeScoreboardToTeamFlag = self.script.mutator.GetConfigurationBool("ChangeScoreboardToTeamFlag")
	self.AlwaysRandomizeActorFlag = self.script.mutator.GetConfigurationBool("AlwaysRandomizeActorFlag")
	self.DefaultWaitTimer = self.script.mutator.GetConfigurationInt("WaitForMutators")
	self.IgnoreFailedCapturePoint = self.script.mutator.GetConfigurationBool("IgnoreFailedCapturePoint")
	self.AlertedUser = self.script.mutator.GetConfigurationBool("IgnoreFailedCapturePoint")
	self.AvoidDupeColors = self.script.mutator.GetConfigurationBool("AvoidDupeColors")
	self.FunnyMode = self.script.mutator.GetConfigurationBool("FunnyMode")
	self.AvoidDupeData = self.script.mutator.GetConfigurationBool("AvoidDupeData")
	self.ExecuteConfigForTeam = self.script.mutator.GetConfigurationDropdown("ExecuteConfigForTeam")
	self.AssignedMeshes = self.script.mutator.GetConfigurationString("Meshes")
	self.IsCloth = self.targets.IsCloth
	self.TemplateMaterial = self.targets.TemplateMaterial
	self.WaitTimer = self.DefaultWaitTimer
	self.FinishedAddingPacks = false
	self.OverlayLabel = GameObject.Find("Ingame UI Container(Clone)/New Ingame UI/Overlay Label Element/Overlay Label")
	self.VictoryText = GameObject.Find("Ingame UI Container(Clone)/Victory UI Canvas/Victory Panel/Victory Focus/Victory Text")
	self.OldVehicleTextures = {}

	-- This shows all the textures for one team
	self.TeamToName = {
		[Team.Blue] = "Blue",
		[Team.Red] = "Red", 
		[Team.Neutral] = "Neutral"
	}

	self.OppositeTeam = {
		[Team.Blue] = Team.Red,
		[Team.Red] = Team.Blue
	}

	self.TeamToData = {}
	-- Mutator -> metadata, meshes, flags
	self.MutatorPacks = {}
	self.CachedTextureToMaterials = {}

	-- Actors are assigned datas
	self.ActorsToTexture = {}

	self.TeamToActors = {}
	self.ActorsToStoredMeshRenderer = {}

	self.TextureForSpawn = {}
	self.UserLists = {}
	self.FlagToMeshes = {}
	self.PlayerData = {}

	for team, _ in pairs(self.OppositeTeam) do
		self.TeamToActors[team] = {}
	end

	self.commandContext = {
		type = nil,
		allowDupes = false
	}
	self.runnableStringCommands = {
		ACCESSORY = function(flags, meshes)
			if(self.commandContext.type ~= "meshes") then return end

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
						self.PlayerData[name] = data			
					end
				end
			elseif(operator == "MESHES") then
				for _, name in ipairs(list) do
					local data = self:getData("meshes", name)
					if(data) then
						self.PlayerData[name] = data			
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
				count = self:getLengthOfDict(list)
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
		ALLMUTATORS = function(type)
			type = type[1]:lower() -- either "FLAGS" or "MESHES"
			local names = {}
			for name, _ in pairs(self:retrieveMutatorsWithType(type)) do
				table.insert(names, name)
			end
			return names
		end,
		ALL = function(mutatorIds)
			local names = {}
			local type = self.commandContext.useTypes and self.commandContext.type
			local unusedDatas = self:getAllNonUsedDatas(type)
			for _, mutatorId in ipairs(mutatorIds) do
				local success, datas = pcall(self.getDatasFromMutator, self, type, mutatorId)
				if(success and datas) then
					for name, _ in pairs(datas) do
						if(not unusedDatas or unusedDatas[name] or self.commandContext.allowDupes) then
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
				error("Invalid amount: "..testing)
			end

			local randomizationPool = {}
			local unusedDatas = self:getAllNonUsedDatas(self.commandContext.useTypes and self.commandContext.type)
			for _, name in ipairs(datas) do
				if(not unusedDatas or unusedDatas[name] or self.commandContext.allowDupes) then
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
		self.TeamToData[team] = {}
	end

	for _, actor in ipairs(self.Actors) do
		if(actor.team) ~= Team.Neutral then 
			table.insert(self.TeamToActors[actor.team], actor)
		 end
	end
end

function MianFlagFramework:Start()
	for _, capturePoint in ipairs(self.Flags) do
		self:autoSetPointMaterial(capturePoint)
		self.script.AddValueMonitor("pendingOwner", "onPendingOwnerChanged", capturePoint)
	end

	GameEvents.onCapturePointCaptured.AddListener(self,"autoSetPointMaterial")
	GameEvents.onCapturePointNeutralized.AddListener(self,"autoSetPointMaterial")
	GameEvents.onActorSpawn.AddListener(self, "onActorSpawn")
	GameEvents.onMatchEnd.AddListener(self, "onMatchEnd")
	GameEvents.onVehicleSpawn.AddListener(self, "onVehicleSpawned")
end
-- The two functions below are to handle compatiblity with old mutator packs
function MianFlagFramework:addTextureData()
	error("Detected an outdated flag mutator script! Please get the newest lua file from GitHub. This function is only here to tell you this. Otherwise it does absolutely nothing.")
end

function MianFlagFramework:addTexturePack(mutatorName, mutator)
	mutator.name = mutatorName
	mutator.CustomFlagToTeamColors = mutator.CustomFlagTeamColors
	mutator.CustomFlagTeamColors = nil
	self:addFlagPack(mutator)
end

function MianFlagFramework:validatePack(mutatorData, validateTable)
	if(not mutatorData) then
		error("A pack is trying to add data without metadata! Cannot proceed")
	end

	if(self.FinishedAddingPacks) then
		error("A pack tried to add data outside of registration period. Try increasing the wait time in the framework settings.")
	end

	for key, validate in pairs(validateTable) do
		if(not mutatorData[key]) then
			local name = mutatorData.name or "A pack"
			error(name.." is missing some required metadata, please get the newest lua file from one of my template packs if you are the developer. The missing metadata is: "..key)
		elseif(validate) then
			validate(mutatorData[key])
		end
	end

	local name = mutatorData.name
	if(self.MutatorPacks[name]) then
		self:log("<color=RED>A pack with the name, "..name..", is already known. The developer should really change the name of this pack but for now, we can use fallback code to register the pack under a different name. Please tell the developer to change their pack's name</color>")
		local dupe = 0
		local tryName
		repeat
			dupe = dupe + 1
			tryName = name.."_"..dupe
		until not self.MutatorPacks[tryName]
		mutatorData.name = tryName
	end

	return true
end

function MianFlagFramework:addMeshPack(mutatorData)
	local canRun = self:validatePack(mutatorData, {
		cover = nil,
		CustomMeshes = nil,
		name = function(value)
			if(value:match("{") or value:match("}") or value:match(":")) then
				error(value.." is an invalid name! Cannot have {, }, or : in the name!")
			else
				mutatorData.name = value:upper()
			end
		end
	})
	if(not canRun) then return end
	local name = mutatorData.name

	local success, errormsg = pcall(function()
		local mutatorTable = self.MutatorPacks[name] or {
			metadata = mutatorData
		}
		mutatorTable.meshes = {}

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
			mutatorTable.meshes[nameToUse] = {
				mesh=mesh,
				name = nameToUse,
				materials = materials
			}
		end
		
		self.MutatorPacks[name] = mutatorTable
	end)

	if(success) then
		self:log("Added new pack: "..name)
	else
		self:log("Failed to load pack: "..name)
		self:log("<color=red>Error: "..errormsg.."</color>")
	end
	self.WaitTimer = self.DefaultWaitTimer
end

function MianFlagFramework:addFlagPack(mutatorData)
	local canRun = self:validatePack(mutatorData, {
		cover = nil,
		CustomFlags = nil,
		CustomFlagToTeamColors = nil,
		name = function(value)
			if(value:match("{") or value:match("}") or value:match(":")) then
				error(value.." is an invalid name! Cannot have {, }, or : in the name!")
			else
				mutatorData.name = value:upper()
			end
		end
	})
	if(not canRun) then return end
	local name = mutatorData.name

	local success, errormsg = pcall(function()
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
			texture.name = nameToUse
			mutatorTable.flags[nameToUse] = {
				texture=texture,
				name = nameToUse,
				teamColor=mutatorData.CustomFlagToTeamColors[index],
				teamName=nameToUse,
				overrideMaterialColor=nil
			}
		end
		
		self.MutatorPacks[name] = mutatorTable
	end)

	if(success) then
		self:log("Added new pack: "..name)
	else
		self:log("Failed to load pack: "..name)
		self:log("Error: "..errormsg)
	end
	self.WaitTimer = self.DefaultWaitTimer
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
		for name, _ in pairs(datas) do
			if(givenDatas[name]) then
				givenDatas[name] = nil
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

	if(self.TeamToData[team][name]) then
		self:log(displayName.." was already added into "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright).."!")
		return
	end

	self.TeamToData[team][name] = data

	self:log(displayName.." was added to "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright))
end

function MianFlagFramework:Update()
	if(not self.FinishedAddingPacks) then
		self.WaitTimer = self.WaitTimer - Time.deltaTime

		if(self.WaitTimer <= 0) then
			self.FinishedAddingPacks = true

			self:log("All packs seem to have been added: Starting framework version "..self.version)
			local TeamToName = self.TeamToName
			TeamToName[Team.Neutral] = nil
			local decision = self.ExecuteConfigForTeam
			local firstTeam
			if(decision == 0) then
				firstTeam = Team.Blue
			elseif(decision == 1) then
				firstTeam = Team.Red
			else
				firstTeam = self:getRandomKeyFromDict(TeamToName)
			end
			local secondTeam = (Team.Blue ~= firstTeam and Team.Blue) or (Team.Red ~= firstTeam and Team.Red)
			TeamToName = {
				[firstTeam] = self.TeamToName[firstTeam],
				[secondTeam] = self.TeamToName[secondTeam]
			}

			local lastTeam = false
			
			local function executeCommandFromSyntax(syntax)
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
								local _, argsFromCommand = executeCommandFromSyntax(command)
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

			local function executeStringList(string)
				local list = {}
				for _, name in ipairs(findResults(string)) do
					local command = isCommand(name)
					local success, results = false, nil
					if(command) then
						success, results = executeCommandFromSyntax(command)
						if(success and results) then
							for _, _name in ipairs(results) do
								table.insert(list, _name)						
							end
						end
					end

					if(not success) then
						table.insert(list, name)
					end
				end
				return list
			end

			self.commandContext = {
				type = "meshes",
				allowDupes = true
			}
			executeStringList(self.AssignedMeshes)

			for team, name in pairs(TeamToName) do
				local textures = self.script.mutator.GetConfigurationString(name.."FlagTextures")
				local texDatas = {}

				self.commandContext = {
					type = "flags",
					useType = true
				}

				local results = executeStringList(textures)
				for _, _name in ipairs(results) do
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
					local teamSpecific = (team == Team.Blue and "") or (team == Team.Red and " (1)")
					if(self.ChangeTeamNamesToFlagName) then
						local name = (firstTexData == lastTexData and firstTexData.teamName:upper()) or firstTexData.teamName:upper().." ALLIES"
				
						GameManager.SetTeamName(team, name)
						GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific.."/Header Panel/Text Team").GetComponent(Text).text = name
					end
			
					if(self.ChangeTeamColorToFlagColor) then
						local color = firstTexData.teamColor or ColorScheme.GetTeamColor(team)
						if(lastTeam) then
							local otherTeamColor = ColorScheme.GetTeamColor(self.OppositeTeam[team])
							if(otherTeamColor.r == color.r and otherTeamColor.g == color.g and otherTeamColor.b == color.b and self.AvoidDupeColors) then
								color.r = math.random(0, 255) / 255
								color.g = math.random(0, 255) / 255
								color.b = math.random(0, 255) / 255
							end
						end
						color = Color(color.r, color.g, color.b)
						local funnyColor = Color(color.r * 255, color.g * 255, color.b * 255)
						ColorScheme.SetTeamColor(team, (self.FunnyMode and funnyColor) or color)
						color.a = 0.392
						GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific.."/Header Panel").GetComponent(Image).color = color
					end

					if(self.ChangeScoreboardToTeamFlag) then
						local teamPanelImage = GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific).GetComponent(Image)
						local a = teamPanelImage.color.a
						teamPanelImage.material = self:createOrGetExistingMaterialFromTexture("UI", firstTexData.texture, nil, 1, teamPanelImage.material)
						local color = Color(0.6, 0.6, 0.6, a)
						teamPanelImage.color = color
					end

					for _, capturePoint in pairs(self.Flags) do
						if(capturePoint.owner == team) then
							self:setPointMaterial(capturePoint, self:createOrGetExistingMaterialFromTexture("Flags", firstTexData.texture, firstTexData.overrideMaterialColor))
						end
					end

					self.TextureForSpawn[team] = {texture=firstTexData.texture}
				end

				lastTeam = true
			end
		
			for _, vehicle in ipairs(ActorManager.vehicles) do
				self:onVehicleSpawned(vehicle)
			end
		end
	end

	for team, teamTexture in pairs(self.TextureForSpawn) do
		if(teamTexture.added) then
			teamTexture.added = teamTexture.added - Time.deltaTime
			if(teamTexture.added <= 0) then
				self.TextureForSpawn[team] = nil
			end
		end
	end
end

function MianFlagFramework:onMatchEnd(team)
	if(self.VictoryText and self.VictoryText.activeSelf and self.ChangeTeamNamesToFlagName) then
		local text = self.VictoryText.GetComponent(Text)
		text.text = GameManager.GetTeamName(team).." VICTORY"
	end
end

function MianFlagFramework:onDriverChanged()
	local vehicle = CurrentEvent.listenerData
	local driver = vehicle.driver

	local meshRenderers = {} 
	for _, renderer in ipairs(vehicle.gameObject.GetComponentsInChildren(MeshRenderer)) do
		table.insert(meshRenderers, renderer)
	end
	for _, renderer in ipairs(vehicle.gameObject.GetComponentsInChildren(SkinnedMeshRenderer)) do
		table.insert(meshRenderers, renderer)
	end
	for _, meshRenderer in ipairs(meshRenderers) do
		for _, material in ipairs(meshRenderer.materials) do
			if(self:canBeReplacedWithFlagTexture(material)) then
				local texture = (driver and self.ActorsToTexture[driver]) or self.OldVehicleTextures[material]
				material.SetTexture("_MainTex", texture)
				if(not self.OldVehicleTextures[material] and texture and (not driver or texture ~= self.ActorsToTexture[driver])) then
					self.OldVehicleTextures[material] = texture
				elseif(driver and texture == self.ActorsToTexture[driver]) then
					material.color = Color(1, 1, 1, 1)
				end
			end
		end
	end
end

function MianFlagFramework:vehicleDriver()
	if(not CurrentEvent.listenerData) then return end
	return CurrentEvent.listenerData.driver
end

function MianFlagFramework:onVehicleSpawned(vehicle)
	self.script.AddValueMonitor("vehicleDriver", "onDriverChanged", vehicle)
end

function MianFlagFramework:onActorSpawn(actor)
	local team = actor.team
	if(not team) then return end
	local datas = (actor.isPlayer and self.PlayerData) or self.TeamToData[actor.team]

	local texture = not actor.isPlayer and not self.AlwaysRandomizeActorFlag and math.random(1, 5) <= 4 and self.TextureForSpawn[team] and self.TextureForSpawn[team].texture
	local willRandomize = actor.isPlayer or texture or math.random(1, 10) > 5 or self.AlwaysRandomizeActorFlag
	if(not texture and not willRandomize) then
		local closestFlag = nil
		local closestMagnitude = math.huge

		for _, capturePoint in ipairs(self.Flags) do
			if(capturePoint.owner == actor.team 
			and capturePoint.flagRenderer 
			and capturePoint.flagRenderer.material 
			and capturePoint.flagRenderer.material.mainTexture 
			and datas[capturePoint.flagRenderer.material.mainTexture.name]) then
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
		local length = self:getLengthOfDictWithKeyInTable("texture", datas)
		if(actor.isPlayer and length <= 0) then
			datas = self.TeamToData[actor.team]
			length = self:getLengthOfDictWithKeyInTable("texture", datas)
		end
		if(length > 0) then
			texture = self:findRandomTableInDictWithKey("texture", datas).texture
			willRandomize = true
		end
	end

	if(texture) then
		self.ActorsToTexture[actor] = texture
		if(willRandomize and not actor.isPlayer) then
			self.TextureForSpawn[team] = {texture=texture,added=1}
		end
	end

	-- Accessories handled here
	local datas = (actor.isPlayer and self:getLengthOfDictWithKeyInTable("mesh", self.PlayerData) > 0 and self.PlayerData) or self.FlagToMeshes

	-- the below is really hacky code used to replace our already added accessories' materials. Preferably we shouldn't do this but like fuck all
	-- local skinnedMeshRenderers = {}
	-- for _, meshRenderer in ipairs(actor.gameObject.GetComponentsInChildren(SkinnedMeshRenderer)) do
	-- 	table.insert(skinnedMeshRenderers, meshRenderer)
	-- end
	-- for _, meshRenderer in ipairs(actor.transform.Find("Soldier Ragdoll").gameObject.GetComponentsInChildren(SkinnedMeshRenderer)) do
	-- 	table.insert(skinnedMeshRenderers, meshRenderer)
	-- end

	-- local found = false
	-- for _, meshRenderer in ipairs(skinnedMeshRenderers) do
	-- 	for _, data in pairs(datas) do
	-- 		if(meshRenderer.sharedMesh == data.mesh) then
	-- 			meshRenderer.material = self:createOrGetExistingMaterialFromTexture("Meshes", texture, nil, 1)
	-- 			found = true
	-- 			break
	-- 		end 
	-- 	end
	-- end
	-- STEEL PLEASE ADD REMOVEACCESSORY SO I DONT NEED TO DO THE ABOVE OK

	-- if(not found) then
	actor.RemoveAccessories()

	local randomizationPool = {}
	if(datas == self.PlayerData) then
		for _, _datas in pairs(datas) do
			if(_datas.mesh) then
				table.insert(randomizationPool, _datas)
			end
		end
	elseif(texture and datas[texture.name]) then
		for _, data in ipairs(datas[texture.name]) do
			if(data.mesh) then
				table.insert(randomizationPool, data)
			end
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
	and (datas[capturePoint.flagRenderer.material.mainTexture.name] or (ownerToUse == Player.actor.team and self.PlayerData[capturePoint.flagRenderer.material.mainTexture.name]))) then 
		texture = capturePoint.flagRenderer.material.mainTexture
	end
	
	local friendlyActor = self:findFirstFriendlyActorWithinCapturePoint(capturePoint)
	if(friendlyActor and friendlyActor.squad) then
		friendlyActor = friendlyActor.squad.leader or friendlyActor
	end

	texture = texture or (friendlyActor and self.ActorsToTexture[friendlyActor]) or self:findRandomTableInDictWithKey("texture", datas)

	if(not texture) then
		if(self.FinishedAddingPacks and newOwner ~= Team.Neutral) then
			self:log("No textures to use for "..ColorScheme.FormatTeamColor(self.TeamToName[ownerToUse], ownerToUse, ColorVariant.Bright)..": Using DEFAULT") 			
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

	for _name, data in pairs(self:getDatas(type)) do
		if(_name == name) then
			return data
		end
	end

	return nil
end

function MianFlagFramework:getDatas(type)
	local datas = {}
	for _, mutatorPack in pairs(self.MutatorPacks) do
		if(type) then
			local givenDatas = mutatorPack[type]
			if(givenDatas) then
				for name, data in pairs(givenDatas) do
					datas[name] = data
				end
			end
		else
			for _, givenDatas in pairs(mutatorPack) do
				for name, data in pairs(givenDatas) do
					datas[name] = data
				end
			end
		end
	end
	return datas
end

function MianFlagFramework:retrieveMutatorsWithType(type)
	local mutatorPacks = {}
	for name, mutatorPack in pairs(self.MutatorPacks) do
		if(mutatorPack[type]) then
			mutatorPacks[name] = mutatorPack
		end
	end
	return mutatorPacks
end

function MianFlagFramework:findRandomTableInDictWithKey(key, dict)
	local add = {}
	for _, tble in pairs(dict) do
		if(tble[key]) then
			table.insert(add, tble)
		end
	end
	return add[math.random(1, #add)]
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

function MianFlagFramework:isInArray(tble, value)
	for i, _value in ipairs(tble) do
		if(_value == value) then
			return i;
		end
	end
end

function MianFlagFramework:getRandomValueFromDict(dict)
	return dict[self:getRandomKeyFromDict(dict)]
end

function MianFlagFramework:getRandomKeyFromDict(dict)
	local names = {}
	for name, _ in pairs(dict) do
		table.insert(names, name)
	end

	local randomName = names[math.random(1, #names)]
	return randomName
end

function MianFlagFramework:getLengthOfDictWithKeyInTable(key, dict)
	local count = 0
	for _, tble in pairs(dict) do
		if(tble[key]) then
			count = count + 1;
		end
	end
	return count;
end

function MianFlagFramework:getLengthOfDict(dict)
	local count = 0
	for _, _ in pairs(dict) do
		count = count + 1
	end
	return count;
end

function MianFlagFramework:getNameFlair(data)
	if(not data) then return "" end
	local colorToUse = data.teamColor or Color(1, 1, 1)
	return ColorScheme.RichTextColorTag(Color(colorToUse.r, colorToUse.g, colorToUse.b))..data.name.."</color>"
end

function MianFlagFramework:log(...)
	local string = "<color=#fc0fc0>[Custom Flag Framework]:</color> "
	for _, extraArg in ipairs({...}) do
		string = string..tostring(extraArg)
	end
	print(string)
end