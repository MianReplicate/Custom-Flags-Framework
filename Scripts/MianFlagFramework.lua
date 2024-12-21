-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

function MianFlagFramework:Awake()
	self.Flags = ActorManager.capturePoints
	self.ChangeTeamNamesToFlagName = self.script.mutator.GetConfigurationBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = self.script.mutator.GetConfigurationBool("ChangeTeamColorToFlagColor")
	self.DefaultWaitTimer = self.script.mutator.GetConfigurationInt("WaitForMutators")


	-- This shows all the textures for one team
	self.TeamToTexture = {}
	self.MutatorData = {}

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

function MianFlagFramework:addTextureData(mutatorData, texture, teamColor)
	if(not mutatorData) then
		error("No mutator data found, it was trying to add: "..texture.name)
	end
	local mutatorName = mutatorData.name:upper()
	local cover = mutatorData.cover
	mutatorData.name = mutatorName
	if(not mutatorName) then
		error("A mutator just tried to add a texture without a mutator id!")
	elseif(mutatorName and (mutatorName:match("{") or mutatorName:match("}") or mutatorName:match(":"))) then
		error(mutatorName.." is an invalid name! Cannot have {, }, or : in the name!")
	end
	if(not cover) then
		error(mutatorName.." failed to provide us with a cover we can use!")
	end
	if(self.FinishedAddingTextures) then
		error(mutatorName.." just tried to add a texture outside of registration period. Cannot add "..texture.name)
	end
	if(not texture) then
		error("No texture provided by "..mutatorName.."!")
	end
	local name = texture.name:upper()
	if(self:getTextureData(name)) then
		error("There is already a material added with this name: "..name)
	end
	texture.name = name
	
	local mutatorTable = self.MutatorData[string.upper(mutatorName)] or {
		metadata = mutatorData,
		textureDatas = {}
	}
	mutatorTable.textureDatas[name] = {texture=texture,teamColor=teamColor}
	
	self.MutatorData[string.upper(mutatorName)] = self.MutatorData[string.upper(mutatorName)] or mutatorTable
	self.WaitTimer = self.DefaultWaitTimer

	print("Created and added new material from "..mutatorName..": "..name)
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
	if(self.IndexedTextureData) then return self.IndexedTextureData end
	if(waitForFinish) then return nil end

	local TextureData = {}

	for _, mutatorData in pairs(self.MutatorData) do
		for name, texData in pairs(mutatorData.textureDatas) do
			TextureData[name] = texData
		end
	end

	self.IndexedTextureData = TextureData
	return self.IndexedTextureData
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

function MianFlagFramework:putTextureForTeam(team, texture)
	if(not team or not texture) then
		return
	end

	local name = texture.name:upper()
	if(not self:getTextureData(name)) then
		error(name.." is not a stored flag texture! Please add it first and then use it")
	end

	if(self.TeamToTexture[team][name]) then
		print(name.." was already added into "..self.TeamToName[team].."!")
		return
	end

	self.TeamToTexture[team][name] = texture

	print(name.." was added to "..self.TeamToName[team])
end

function MianFlagFramework:Update()
	if(not self.FinishedAddingTextures) then
		self.WaitTimer = self.WaitTimer - Time.deltaTime
		if(self.WaitTimer <= 0) then
			self.FinishedAddingTextures = true

			print("All textures seem to have been added: Starting framework..")

			for team, name in pairs(self.TeamToName) do
				if(name ~= "Neutral") then
					local textures = self.script.mutator.GetConfigurationString(name.."FlagTextures")
					local texDatas = {}
					self.IndexedTextureData = nil
					if(self:getLengthOfDict(self:getAllTextureDatas()) > 0) then
						for name in textures:gmatch('([^,]+)') do
							local commandData = name:match("{(.*)}")
							if(commandData) then
								commandData = commandData:upper()
								local begin, endI, command = commandData:find("([^:]+)")
								local splitCommandData = commandData:sub(endI+1)
								local commandFunction = self.runnableStringCommands[command]
								if(commandFunction) then
									local args = {}
									
									for arg in splitCommandData:gmatch('([^:]+)') do
										table.insert(args, arg)
									end

									local success, returnValue = pcall(commandFunction, table.unpack(args))

									if(not success) then
										print("Failed to get textures from command: "..commandData)
										if(returnValue) then
											print(returnValue)
										end
									else
										for _, texData in pairs(returnValue) do
											table.insert(texDatas, texData)
										end
									end
								end
							else
								local texData = self:getTextureData(name)
								if(texData) then
									table.insert(texDatas, texData)
								else
									print(name.." is an invalid texture! Did you name it incorrectly?")
								end
							end
						end
					end

					for _, texData in pairs(texDatas) do
						self:putTextureForTeam(team, texData.texture)
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
end

function MianFlagFramework:autoSetPointMaterial(capturePoint, newOwner)
	local ownerToUse = capturePoint.pendingOwner or capturePoint.owner
	local textures = self.TeamToTexture[ownerToUse]
	local length = self:getLengthOfDict(textures)

	if(length <= 0) then
		print("No textures to use for "..self.TeamToName[ownerToUse]) 
		return
	end

	local texture
	for _, _texture in pairs(textures) do
		if(capturePoint.flagRenderer.material.mainTexture == _texture) then 
			texture = _texture
		end
	end
	texture = texture or self:getRandomFromDict(textures)

	if(newOwner == ownerToUse and self.OverlayLabel.activeSelf) then
		-- This means that the capture point was neutralized
		local textComponent = self.OverlayLabel.GetComponent(Text)
		local start, endI = textComponent.text:find("</color>")
		local endingString = textComponent.text:sub(endI+1)

		local texData = self:getTextureData(texture.name)
		local displayName = (self.ChangeTeamNamesToFlagName and texture.name) or self.TeamToName[newOwner]
		local tColor = texData.teamColor
		local color = Color(tColor.r, tColor.g, tColor.b)
		local colorTag = (self.ChangeTeamColorToFlagColor and ColorScheme.RichTextColorTag(color)) or ColorScheme.GetTeamColor(newOwner)
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

function MianFlagFramework:getRandomFromDict(dict)
	local names = {}
	for name, _ in pairs(dict) do
		table.insert(names, name)
	end

	local randomName = names[math.random(1, #names)]
	return dict[randomName]
end

function MianFlagFramework:getLengthOfDict(dict)
	local count = 0
	for _, _ in pairs(dict) do
		count = count + 1
	end
	return count;
end