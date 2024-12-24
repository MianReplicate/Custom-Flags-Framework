-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

function MianFlagFramework:Awake()
	self.version = 1.0.0 -- were now keeping track of framework versions lmfao, i forgot to do this before, mb
	self.gameObject.name = "Custom Flag Framework"
	self.Flags = ActorManager.capturePoints
	self.ChangeTeamNamesToFlagName = self.script.mutator.GetConfigurationBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = self.script.mutator.GetConfigurationBool("ChangeTeamColorToFlagColor")
	self.DefaultWaitTimer = self.script.mutator.GetConfigurationInt("WaitForMutators")


	-- This shows all the textures for one team
	self.TeamToTexture = {}
	self.MutatorData = {}

	-- NEW WORK IN PROGRESS UPDATED SYNTAX
	-- {TEAM:NAME:{FLAG}:TEAMNAME}
	-- {TEAM:COLOR:{FLAG}:255,255,255}
	-- {MUTATOR:{MUTATORID}:ALL}
	-- {MUTATOR:{MUTATORID}:RANDOMIZE} = {MUTATOR:MIANPOLITICALFLAGS,MIANPRIDEFLAGS:RANDOMIZE}
	self.runnableStringCommands = {
		["MUTATOR"] = function (mutatorId, decision, amount)
			local textureDatas = self:getTextureDatasFromMutator(mutatorId)
			if(textureDatas) then
				local texDatas = {}
				if(decision == "ALL") then
					texDatas = textureDatas
				elseif(decision == "RANDOMIZE") then
					amount = tonumber(amount)
					if(not amount) then
						error("Invalid amount: "..amount)
					end

					local randomizationPool = {}
					for name, _ in pairs(self:filterTextureDatasForMutator(mutatorId, self:getAllNonUsedTextureDatas())) do
						table.insert(randomizationPool, name)
					end
					while(amount > 0) do
						if(#randomizationPool <= 0) then break end -- no more to pull from :<

						local randomIndex = math.random(1, #randomizationPool)
						local randomTex = randomizationPool[randomIndex]
						table.remove(randomizationPool, randomIndex)
						amount = amount - 1

						table.insert(texDatas, self:getTextureData(randomTex))
					end
				elseif(decision == "FIRST" or decision == "LAST") then
					amount = tonumber(amount)
					if(not amount) then
						error("Invalid amount: "..amount)
					end

					local pool = {}
					for name, _ in pairs(textureDatas) do
						table.insert(pool, name)
					end

					for i = 1, amount, 1 do
						local indexToUse = (decision == "FIRST" and i) or (#pool + 1) - i
						table.insert(texDatas, self:getTextureData(pool[indexToUse]))
					end
				end

				return texDatas
			else
				error("Invalid mutator id: "..mutatorId)
			end
		end,
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
	self.TeamToFlagColor = {
		[Team.Blue] = {},
		[Team.Red] = {}
	}

	for team, name in pairs(self.TeamToName) do
		if(name ~= "Neutral") then
			local color = self.script.mutator.GetConfigurationString(name.."FlagColor")
			for value in string.gmatch(color, '([^,]+)') do
				local number = tonumber(value) or 255
				table.insert(self.TeamToFlagColor[team], math.max(0, math.min(255, number)) / 255)
			end
		end
	end

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

-- The two functions below are deprecated, they will be removed sometime in the future..
function MianFlagFramework:addTextureData()
	error("Detected an outdated flag mutator script! Please get the newest lua file from GitHub. This function is only here to tell you this. Otherwise it does absolutely nothing.")
end

function MianFlagFramework:addTexturePack(mutatorName, mutator)
	self:log("<color=RED>You are using a deprecated function for the Custom Flags Framework. This is only here to prevent old mutators from breaking. Please get the newest lua file for flag packs from GitHub.</color>")
	mutator.mutatorName = mutatorName
	mutator.customFlags = mutator.CustomFlags
	mutator.customFlagToTeamColors = mutator.CustomFlagTeamColors
	self:addFlagPack(mutator)
end
--

function MianFlagFramework:addFlagPack(mutatorData)
	if(not mutatorData) then
		error("A flag pack is trying to add flag textures without metadata! Cannot proceed")
	end

	local required = {
		"cover",
		"customFlags",
		"customFlagToTeamColors",
		["mutatorName"] = function(value)
			if(value:match("{") or value:match("}") or value:match(":")) then
				error(value.." is an invalid name! Cannot have {, }, or : in the name!")
			end
		end
	}

	for key, validate in pairs(required) do
		if(not mutatorData[key]) then
			error("A flag pack is missing some required metadata, please get the newest lua file from one of my template flag packs if you are the developer. The missing metadata is: "..key)
		elseif(validate) then
			validate(mutatorData[key])
		end
	end
	
	local mutatorName = mutatorData.mutatorName
	mutatorData.mutatorName = mutatorName:upper()

	if(self.FinishedAddingTextures) then
		error(mutatorName.." just tried to add flag textures outside of registration period. Try increasing the wait time in the framework settings.")
	end

	if(self.MutatorData[mutatorName]) then
		self:log("<color=RED>A flag mutator with the name, "..mutatorName..", is already known. The developer should really change the name of this mutator but for now, we can use fallback code to register the mutator under a different name. Please tell the developer to change their mutator's name</color>")
		local dupe = 0
		local tryName
		repeat
			dupe = dupe + 1
			tryName = mutatorName.."_"..dupe
		until not self.MutatorData[tryName]
		mutatorName = tryName
	end

	local mutatorData = {name=mutatorName,cover=mutatorData.cover}
	local mutatorTable = {
		metadata = mutatorData,
		textureDatas = {}
	}

	for index, texture in pairs(mutatorData.customFlags) do
		texture.name = texture.name:upper()
		mutatorTable.textureDatas[texture.name] = {texture=texture,teamColor=mutatorData.customFlagToTeamColors[index]}
	end
	
	self.MutatorData[mutatorName] = mutatorTable
	self.WaitTimer = self.DefaultWaitTimer

	self:log("Added new texture pack: "..mutatorName)
end

function MianFlagFramework:createMaterialFromTexture(team, texture)
	local material = Material(self.TemplateMaterial)
	material.SetTexture("_MainTex", texture)
	material.name = texture.name:upper()
	local yScale = (self.IsCloth.activeSelf and 1.4) or 1
	material.SetTextureScale("_MainTex", Vector2(1, yScale))
	local customFlagColor = self.TeamToFlagColor[team]
	material.color = Color(customFlagColor[1],customFlagColor[2],customFlagColor[3],1)

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
		self.WaitTimer = self.WaitTimer - Time.deltaTime
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

				local function isSyntax(syntax)
					return syntax:match("{(.*)}")
				end
	
				local function runSyntaxCheck(name)
					if(isSyntax(name)) then
						local syntax = name:upper()
						local begin, endI, command = syntax:find("([^:]+)")
						local splitCommandData = syntax:sub(endI+1)
						local commandFunction = self.runnableStringCommands[command]
						if(commandFunction) then
							local args = {}
							
							for arg in splitCommandData:gmatch('([^:]+)') do
								local returnArg
								for listArg in splitCommandData:gmatch('([^,]+)') do
									returnArg = returnArg or {}
									table.insert(returnArg, listArg)
								end
								returnArg = returnArg or arg
								table.insert(args, returnArg)
							end
		
							for index, arg in pairs(args) do
								if(isSyntax(arg)) then
									args[index] = runSyntaxCheck(arg)
								end
							end
		
							local success, returnValue = pcall(commandFunction, table.unpack(args))
		
							if(not success) then
								self:log("<color=red>Syntax failed: "..syntax.."</color>")
								if(returnValue) then
									self:log("<color=red>"..returnValue.."</color>")
								end
							else
								local returnedArgs = {}
								for _, arg in pairs(returnValue) do
									table.insert(returnedArgs, arg)
								end
								return returnedArgs
							end
						end
					else
						local texData = self:getTextureData(name)
						if(texData) then
							self:putTextureForTeam(team, texData)
							table.insert(texDatas, texData)
						else
							self:log(name.." is an invalid texture! Did you name it incorrectly?")
						end
					end
				end

				if(self:getLengthOfDict(self:getAllTextureDatas()) > 0) then
					for name in textures:gmatch('([^,]+)') do
						-- runSyntaxCheck(name)
						
						local syntax = isSyntax(name)
						if(syntax) then
							syntax = syntax:upper()
							local begin, endI, command = syntax:find("([^:]+)")
							local splitCommandData = syntax:sub(endI+1)
							local commandFunction = self.runnableStringCommands[command]
							if(commandFunction) then
								local args = {}
								
								for arg in splitCommandData:gmatch('([^:]+)') do
									table.insert(args, arg)
								end

								local success, returnValue = pcall(commandFunction, table.unpack(args))

								if(not success) then
									self:log("Failed to get textures from command: "..syntax)
									if(returnValue) then
										self:log(returnValue)
									end
								else
									for _, texData in pairs(returnValue) do
										self:putTextureForTeam(team, texData)
										table.insert(texDatas, texData)
									end
								end
							end
						else
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
						local name = (firstTexData == lastTexData and firstTexData.texture.name:upper()) or firstTexData.texture.name:upper().." ALLIES"
				
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
							self:setPointMaterial(capturePoint, self:createMaterialFromTexture(team, firstTexData.texture))
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

	if(newOwner == ownerToUse and self.OverlayLabel.activeSelf) then
		-- This means that the capture point was neutralized
		local textComponent = self.OverlayLabel.GetComponent(Text)
		local start, endI = textComponent.text:find("</color>")
		local endingString = textComponent.text:sub(endI+1)

		local texData = self:getTextureData(texture.name)
		local displayName = (self.ChangeTeamNamesToFlagName and texture.name) or self.TeamToName[newOwner]
		local tColor = (self.ChangeTeamColorToFlagColor and texData.teamColor) or ColorScheme.GetTeamColor(newOwner)
		local color = Color(tColor.r, tColor.g, tColor.b)
		local colorTag = ColorScheme.RichTextColorTag(color)
		local stringToUse = colorTag..displayName.."</color>"..endingString

		textComponent.text = stringToUse
	end

	self:setPointMaterial(capturePoint, self:createMaterialFromTexture(ownerToUse, texture))
end

function MianFlagFramework:setPointMaterial(capturePoint, material)
	capturePoint.flagRenderer.material = material
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
	return ColorScheme.RichTextColorTag(Color(texData.teamColor.r, texData.teamColor.g, texData.teamColor.b))..texData.texture.name.."</color>"
end
