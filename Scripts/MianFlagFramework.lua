-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

local function splitString(string, separator)
	return string:gmatch("([^"..separator.."]+)")
end

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


function MianFlagFramework:Awake()
	self.version = "2.0.0"
	self.gameObject.name = "Custom Flag Framework"
	self.Flags = ActorManager.capturePoints
	self.ChangeTeamNamesToFlagName = self.script.mutator.GetConfigurationBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = self.script.mutator.GetConfigurationBool("ChangeTeamColorToFlagColor")
	self.DefaultWaitTimer = self.script.mutator.GetConfigurationInt("WaitForMutators")
	self.IgnoreFailedCapturePoint = self.script.mutator.GetConfigurationBool("IgnoreFailedCapturePoint")
	self.AlertedUser = self.script.mutator.GetConfigurationBool("IgnoreFailedCapturePoint")

	-- This shows all the textures for one team
	self.TeamToTexture = {}
	self.MutatorData = {}

	self.runnableStringCommands = {
		ALLMUTATORS = function()
			local names = {}
			for name, _ in pairs(self.MutatorData) do
				table.insert(names, name)
			end
			return names
		end,
		ALL = function(mutatorIds)
			local names = {}
			local unusedFlags = self:getAllNonUsedTextureDatas()
			for _, mutatorId in ipairs(mutatorIds) do
				local success, texDatas = pcall(self.getTextureDatasFromMutator, self, mutatorId)
				if(success and texDatas) then
					for name, _ in pairs(texDatas) do
						if(not unusedFlags or unusedFlags[name]) then
							table.insert(names, name)
						end
					end
				end
			end
			return names
		end,
		RANDOMIZE = function(flags, amount)
			if(amount ~= "EXACT") then
				amount = tonumber(amount[1])
			else
				amount = nil
			end

			if(not amount) then
				error("Invalid amount: "..amount)
			end

			local randomizationPool = {}
			local unusedFlags = self:getAllNonUsedTextureDatas()
			for _, name in ipairs(flags) do
				if(not unusedFlags or unusedFlags[name]) then
					table.insert(randomizationPool, name)
				end
			end

			if(amount == 'EXACT') then
				amount = #flags
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
			name = name[1]
			for _, flagName in ipairs(flags) do
				local texData = self:getTextureData(flagName)
				texData.teamName = name
			end
		end,
		TEAMCOLOR = function(flags, color)
			local newColor = Color(tonumber(color[1]), tonumber(color[2]), tonumber(color[3]))
			for _, flagName in ipairs(flags) do
				local texData = self:getTextureData(flagName)
				texData.teamColor = newColor
			end
		end,
		FLAGCOLOR = function(flags, color)
			local newColor = Color(tonumber(color[1]), tonumber(color[2]), tonumber(color[3]))
			for _, flagName in ipairs(flags) do
				local texData = self:getTextureData(flagName)
				texData.overrideMaterialColor = newColor
			end
		end
	}
	self.WaitTimer = self.DefaultWaitTimer
	self.FinishedAddingTextures = false
	self.IsCloth = self.targets.IsCloth
	self.TemplateMaterial = self.targets.TemplateMaterial
	self.OverlayLabel = GameObject.Find("Ingame UI Container(Clone)/New Ingame UI/Overlay Label Element/Overlay Label")

	self.TeamToName = {
		[Team.Blue] = "Blue",
		[Team.Red] = "Red", 
		[Team.Neutral] = "Neutral"
	}

	for team, _ in pairs(self.TeamToName) do
		self.TeamToTexture[team] = {}
	end
end

function MianFlagFramework:Start()
	for _, capturePoint in pairs(self.Flags) do
		self:autoSetPointMaterial(capturePoint)
		self.script.AddValueMonitor("pendingOwner", "onPendingOwnerChanged", capturePoint)
	end

	GameEvents.onCapturePointCaptured.AddListener(self,"autoSetPointMaterial")
	GameEvents.onCapturePointNeutralized.AddListener(self,"autoSetPointMaterial")
end

-- The two functions below are to handle compatiblity with old mutator packs
function MianFlagFramework:addTextureData()
	error("Detected an outdated flag mutator script! Please get the newest lua file from GitHub. This function is only here to tell you this. Otherwise it does absolutely nothing.")
end

function MianFlagFramework:addTexturePack(mutatorName, mutator)
	mutator.name = mutatorName
	mutator.customFlags = mutator.CustomFlags
	mutator.CustomFlags = nil
	mutator.customFlagToTeamColors = mutator.CustomFlagTeamColors
	mutator.CustomFlagTeamColors = nil
	self:addFlagPack(mutator)
end
--
function MianFlagFramework:addFlagPack(mutatorData)
	if(not mutatorData) then
		error("A flag pack is trying to add flag textures without metadata! Cannot proceed")
	end

	local required = {
		cover = nil,
		customFlags = nil,
		customFlagToTeamColors = nil,
		name = function(value)
			if(value:match("{") or value:match("}") or value:match(":")) then
				error(value.." is an invalid name! Cannot have {, }, or : in the name!")
			else
				mutatorData.name = value:upper()
			end
		end
	}

	for key, validate in pairs(required) do
		if(not mutatorData[key]) then
			local name = mutatorData.name or "A flag pack"
			error(name.." is missing some required metadata, please get the newest lua file from one of my template flag packs if you are the developer. The missing metadata is: "..key)
		elseif(validate) then
			validate(mutatorData[key])
		end
	end
	
	local name = mutatorData.name

	if(self.FinishedAddingTextures) then
		error(name.." just tried to add flag textures outside of registration period. Try increasing the wait time in the framework settings.")
	end

	if(self.MutatorData[name]) then
		self:log("<color=RED>A flag mutator with the name, "..name..", is already known. The developer should really change the name of this mutator but for now, we can use fallback code to register the mutator under a different name. Please tell the developer to change their mutator's name</color>")
		local dupe = 0
		local tryName
		repeat
			dupe = dupe + 1
			tryName = name.."_"..dupe
		until not self.MutatorData[tryName]
		name = tryName
	end

	self.AddingFlagPack = true
	local mutatorTable = {
		metadata = mutatorData,
		textureDatas = {}
	}

	for index, texture in pairs(mutatorData.customFlags) do
		texture.name = texture.name:upper()
		local nameToUse = texture.name

		local alreadyExists = self:getTextureData(nameToUse)
		if(alreadyExists) then
			local repeatCount = 0
			local testName = nameToUse
			repeat
				repeatCount = repeatCount + 1
				testName = nameToUse.."_"..repeatCount
			until not self:getTextureData(testName)
			nameToUse = testName
		end
		texture.name = nameToUse
		mutatorTable.textureDatas[nameToUse] = {texture=texture,teamColor=mutatorData.customFlagToTeamColors[index],teamName=texture.name,overrideMaterialColor=nil}
	end
	
	self.MutatorData[name] = mutatorTable
	self.WaitTimer = self.DefaultWaitTimer
	self.AddingFlagPack = false

	self:log("Added new texture pack: "..name)
end

function MianFlagFramework:createMaterialFromTexData(team, texData, texture)
	local material = Material(self.TemplateMaterial)
	if(not texData) then
		material.SetTexture("_MainTex", texture)
		material.name = texture.name:upper()
	else
		material.SetTexture("_MainTex", texData.texture)
		material.name = texData.teamName:upper()
	end

	local yScale = (self.IsCloth.activeSelf and 1.4) or 1
	material.SetTextureScale("_MainTex", Vector2(1, yScale))

	if(texData) then
		local customFlagColor = texData.overrideMaterialColor
		if(customFlagColor) then
			material.color = Color(customFlagColor[1],customFlagColor[2],customFlagColor[3],1)
		end
	end

	return material
end

function MianFlagFramework:getMutatorMetadata(name)
	local mutatorData = self.MutatorData[string.upper(name)]
	if(not mutatorData) then
		error(name:upper().." is not a valid flag mutator!")
	end
	return mutatorData.metadata
end

function MianFlagFramework:getTextureDatasFromMutator(name)
	local mutatorData = self.MutatorData[string.upper(name)]
	if(not mutatorData) then
		error(name:upper().." is not a valid flag mutator!")
	end
	return mutatorData.textureDatas
end

function MianFlagFramework:filterTextureDatasForMutator(mutatorId, texDatas)
	local mutatorTexDatas = self:getTextureDatasFromMutator(mutatorId)
	for name, _ in pairs(texDatas) do
		if(not mutatorTexDatas[name]) then
			texDatas[name] = nil
		end
	end
	return texDatas
end

function MianFlagFramework:getTextureData(name)
	for _, mutatorData in pairs(self.MutatorData) do
		local texData = mutatorData.textureDatas[string.upper(name)]
		if(texData) then
			return texData
		end
	end

	return nil
end

function MianFlagFramework:getAllTextureDatas(waitForFinish)
	if(waitForFinish) then return nil end

	local TextureData = {}

	for _, mutatorData in pairs(self.MutatorData) do
		for name, texData in pairs(mutatorData.textureDatas) do
			TextureData[name] = texData
		end
	end

	return TextureData
end

function MianFlagFramework:getAllNonUsedTextureDatas()
	local texDatas = self:getAllTextureDatas()
	for _, textures in pairs(self.TeamToTexture) do
		for name, _ in pairs(textures) do
			if(texDatas[name]) then
				texDatas[name] = nil
			end
		end
	end
	return texDatas
end

function MianFlagFramework:putTextureForTeam(team, texData)
	if(not team or not texData) then
		return
	end

	local texture = texData.texture
	local name = texture.name:upper()
	local displayName = self:getTexNameFlair(texData)

	if(not self:getTextureData(name)) then
		error(displayName.." is not a stored flag texture! Please add it first and then use it")
	end

	if(self.TeamToTexture[team][name]) then
		self:log(displayName.." was already added into "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright).."!")
		return
	end

	self.TeamToTexture[team][name] = texture

	self:log(displayName.." was added to "..ColorScheme.FormatTeamColor(self.TeamToName[team], team, ColorVariant.Bright))
end

function MianFlagFramework:Update()
	if(not self.FinishedAddingTextures) then
		if(not self.AddingFlagPack) then
			self.WaitTimer = self.WaitTimer - Time.deltaTime
		end

		if(self.WaitTimer <= 0) then
			self.FinishedAddingTextures = true

			self:log("All textures seem to have been added: Starting framework version "..self.version)
			local TeamToName = self.TeamToName
			TeamToName[Team.Neutral] = nil
			local firstTeam = self:getRandomKeyFromDict(TeamToName)
			local secondTeam = (Team.Blue ~= firstTeam and Team.Blue) or (Team.Red ~= firstTeam and Team.Red)
			TeamToName = {
				[firstTeam] = self.TeamToName[firstTeam],
				[secondTeam] = self.TeamToName[secondTeam]
			}
			
			for team, name in pairs(TeamToName) do
				local textures = self.script.mutator.GetConfigurationString(name.."FlagTextures")
				local texDatas = {}
	
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
									local success, argsFromCommand = executeCommandFromSyntax(command)
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

				if(self:getLengthOfDict(self:getAllTextureDatas()) > 0) then
					for _, name in ipairs(findResults(textures)) do
						
						local command = isCommand(name)
						local success, results = false, nil
						if(command) then
							success, results = executeCommandFromSyntax(command)
							if(results) then
								for _, _name in ipairs(results) do
									local texData = self:getTextureData(_name)
									if(texData) then
										self:putTextureForTeam(team, texData)
										table.insert(texDatas, texData)
									else
										self:log(_name.." is an invalid texture! Did you name it incorrectly?")
									end
								end
							end
						end

						if(not success) then
							local texData = self:getTextureData(name)
							if(texData) then
								self:putTextureForTeam(team, texData)
								table.insert(texDatas, texData)
							else
								self:log(name.." is an invalid texture! Did you name it incorrectly?")
							end
						end
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
						ColorScheme.SetTeamColor(team, Color(color.r, color.g, color.b))
						color.a = 0.392
						GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific.."/Header Panel").GetComponent(Image).color = color
					end

					for _, capturePoint in pairs(self.Flags) do
						if(capturePoint.owner == team) then
							self:setPointMaterial(capturePoint, self:createMaterialFromTexData(team, firstTexData))
						end
					end
				end
			end
		end
	end
end

function MianFlagFramework:autoSetPointMaterial(capturePoint, newOwner)
	local ownerToUse = capturePoint.pendingOwner or capturePoint.owner
	local textures = self.TeamToTexture[ownerToUse]
	local length = self:getLengthOfDict(textures)

	if(not ownerToUse or not self.OverlayLabel) then
		return -- prob just game restarting or smth
	end

	if(length <= 0) then
		self:log("No textures to use for "..ColorScheme.FormatTeamColor(self.TeamToName[ownerToUse], ownerToUse, ColorVariant.Bright)) 
		return
	end

	local texture
	for _, _texture in pairs(textures) do
		if(capturePoint.flagRenderer.material.mainTexture == _texture) then 
			texture = _texture
		end
	end
	texture = texture or self:getRandomValueFromDict(textures)
	local texData = self:getTextureData(texture.name)

	if(newOwner == ownerToUse and self.OverlayLabel.activeSelf) then
		-- This means that the capture point was neutralized
		local textComponent = self.OverlayLabel.GetComponent(Text)
		local start, endI = textComponent.text:find("</color>")
		local endingString = textComponent.text:sub(endI+1)

		local displayName = (self.ChangeTeamNamesToFlagName and texData.teamName) or self.TeamToName[newOwner]
		local tColor = (self.ChangeTeamColorToFlagColor and texData.teamColor) or ColorScheme.GetTeamColor(newOwner)
		local color = Color(tColor.r, tColor.g, tColor.b)
		local colorTag = ColorScheme.RichTextColorTag(color)
		local stringToUse = colorTag..displayName.."</color>"..endingString

		textComponent.text = stringToUse
	end

	self:setPointMaterial(capturePoint, self:createMaterialFromTexData(ownerToUse, texData, texture))
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

function MianFlagFramework:pendingOwner()
	return CurrentEvent.listenerData.pendingOwner
end

function MianFlagFramework:onPendingOwnerChanged()
	self:autoSetPointMaterial(CurrentEvent.listenerData)
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

function MianFlagFramework:getLengthOfDict(dict)
	local count = 0
	for _, _ in pairs(dict) do
		count = count + 1
	end
	return count;
end

function MianFlagFramework:log(...)
	print("<color=#fc0fc0>[Custom Flag Framework]:</color>", ...)
end

function MianFlagFramework:getTexNameFlair(texData)
	if(not texData) then return "" end
	local colorToUse = texData.teamColor or Color(255, 255, 255)
	return ColorScheme.RichTextColorTag(Color(colorToUse.r, colorToUse.g, colorToUse.b))..texData.texture.name.."</color>"
end