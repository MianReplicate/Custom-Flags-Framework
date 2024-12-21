-- Originally created by Red. Modified by MianReplicate

-- A flag framework that allows for flag mutators to be much more compatible with each other while maintaining performance, allowing for additional customization and removing redundant code

behaviour("MianFlagFramework")

function MianFlagFramework:Awake()
	self.Flags = ActorManager.capturePoints
	self.OverrideVanillaFlagColor = self.script.mutator.GetConfigurationBool("OverrideVanillaFlagColor")
	self.ChangeTeamNamesToFlagName = self.script.mutator.GetConfigurationBool("ChangeTeamNamesToFlagName")
	self.ChangeTeamColorToFlagColor = self.script.mutator.GetConfigurationBool("ChangeTeamColorToFlagColor")
	self.DefaultWaitTimer = self.script.mutator.GetConfigurationInt("WaitForMutators")


	-- This shows all the materials for one team
	self.TeamToMaterial = {}
	self.MutatorData = {}

	self.runnableStringCommands = {
		["MUTATOR"] = function (mutatorId, decision, amount)
			local materialDatas = self:getMaterialDatasFromMutator(mutatorId)
			if(materialDatas) then
				local matDatas = {}
				if(decision == "ALL") then
					matDatas = materialDatas
				elseif(decision == "RANDOMIZE") then
					amount = tonumber(amount)
					if(not amount) then
						error("Invalid amount: "..amount)
					end

					local randomizationPool = {}
					for name, _ in pairs(self:filterMaterialDatasForMutator(mutatorId, self:getAllNonUsedMaterialDatas())) do
						table.insert(randomizationPool, name)
					end

					while(amount > 0) do
						if(#randomizationPool <= 0) then break end -- no more to pull from :<

						local randomIndex = math.random(1, #randomizationPool)
						local randomMat = randomizationPool[randomIndex]
						table.remove(randomizationPool, randomIndex)
						amount = amount - 1

						table.insert(matDatas, self:getMaterialData(randomMat))
					end
				elseif(decision == "FIRST" or decision == "LAST") then
					amount = tonumber(amount)
					if(not amount) then
						error("Invalid amount: "..amount)
					end

					local pool = {}
					for name, _ in pairs(materialDatas) do
						table.insert(pool, name)
					end

					for i = 1, amount, 1 do
						local indexToUse = (decision == "FIRST" and i) or (#pool + 1) - i
						table.insert(matDatas, self:getMaterialData(pool[indexToUse]))
					end
				end

				return matDatas
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
		self.TeamToMaterial[team] = {}
	end
end

function MianFlagFramework:Start()
	for _, capturePoint in pairs(self.Flags) do
		local team = capturePoint.owner
		if(not self.TeamToMaterial[team].FALLBACK) then
			print("Adding temporary material for "..self.TeamToName[team])
			self.TeamToMaterial[team].FALLBACK = capturePoint.flagRenderer.material

			if(self.OverrideVanillaFlagColor and team ~= Team.Neutral) then
				local customFlagColor = self.TeamToFlagColor[capturePoint.owner]
				self.TeamToMaterial[capturePoint.owner].FALLBACK.color = Color(customFlagColor[1],customFlagColor[2],customFlagColor[3],1)
			end
		end

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
	if(not texture or not teamColor) then
		error("No texture or team color provided by "..mutatorName.."!")
	end
	local name = texture.name:upper()
	if(self:getMaterialData(name)) then
		error("There is already a material added with this name: "..name)
	end
	
	local mutatorTable = self.MutatorData[string.upper(mutatorName)] or {
		metadata = mutatorData,
		materialDatas = {}
	}
	local material = Material(self.TemplateMaterial)
	material.SetTexture("_MainTex", texture)
	material.name = texture.name:upper()
	local yScale = (self.IsCloth.activeSelf and 1.4) or 1
	material.SetTextureScale("_MainTex", Vector2(1, yScale))
	mutatorTable.materialDatas[name] = {material=material,teamColor=teamColor}
	
	self.MutatorData[string.upper(mutatorName)] = self.MutatorData[string.upper(mutatorName)] or mutatorTable
	self.WaitTimer = self.DefaultWaitTimer

	print("Created and added new material from "..mutatorName..": "..name)
end

function MianFlagFramework:getMutatorMetadata(name)
	local mutatorData = self.MutatorData[string.upper(name)]
	if(not mutatorData) then
		error(name:upper().." is not a valid flag mutator!")
	end
	return mutatorData.metadata
end

function MianFlagFramework:getMaterialDatasFromMutator(name)
	local mutatorData = self.MutatorData[string.upper(name)]
	if(not mutatorData) then
		error(name:upper().." is not a valid flag mutator!")
	end
	return mutatorData.materialDatas
end

function MianFlagFramework:filterMaterialDatasForMutator(mutatorId, matDatas)
	local mutatorMatDatas = self:getMaterialDatasFromMutator(mutatorId)
	for name, _ in pairs(matDatas) do
		if(not mutatorMatDatas[name]) then
			matDatas[name] = nil
		end
	end
	return matDatas
end

function MianFlagFramework:getMaterialData(name)
	for _, mutatorData in pairs(self.MutatorData) do
		local matData = mutatorData.materialDatas[string.upper(name)]
		if(matData) then
			return matData
		end
	end

	return nil
end

function MianFlagFramework:getAllMaterialDatas(waitForFinish)
	if(self.IndexedMaterialData) then return self.IndexedMaterialData end
	if(waitForFinish) then return nil end

	local MaterialData = {}

	for _, mutatorData in pairs(self.MutatorData) do
		for name, matData in pairs(mutatorData.materialDatas) do
			MaterialData[name] = matData
		end
	end

	self.IndexedMaterialData = MaterialData
	return self.IndexedMaterialData
end

function MianFlagFramework:getAllNonUsedMaterialDatas()
	local matDatas = self:getAllMaterialDatas()
	for _, materials in pairs(self.TeamToMaterial) do
		for name, _ in pairs(materials) do
			if(matDatas[name]) then
				matDatas[name] = nil
			end
		end
	end
	return matDatas
end

function MianFlagFramework:putFlagMaterialForTeam(team, material)
	if(not team or not material) then
		return
	end

	local name = material.name:upper()
	if(not self:getMaterialData(name)) then
		error(name.." is not a stored flag material! Please add it first and then use it")
	end

	if(self.TeamToMaterial[team][name]) then
		print(name.." was already added into "..self.TeamToName[team].."!")
		return
	end

	local customFlagColor = self.TeamToFlagColor[team]
	material.color = Color(customFlagColor[1],customFlagColor[2],customFlagColor[3],1)

	self.TeamToMaterial[team][name] = material
	self.TeamToMaterial[team].FALLBACK = nil -- No need for a fallback anymore

	print(name.." was added to "..self.TeamToName[team])
end

function MianFlagFramework:Update()
	if(not self.FinishedAddingTextures) then
		self.WaitTimer = self.WaitTimer - Time.deltaTime
		if(self.WaitTimer <= 0) then
			self.FinishedAddingTextures = true

			print("All materials seem to have been created: Starting framework..")

			for team, name in pairs(self.TeamToName) do
				if(name ~= "Neutral") then
					local materials = self.script.mutator.GetConfigurationString(name.."FlagMaterial")
					local matDatas = {}
					self.IndexedMaterialData = nil
					if(self:getLengthOfDict(self:getAllMaterialDatas()) > 0) then
						for name in materials:gmatch('([^,]+)') do
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
										print("Failed to get materials from command: "..commandData)
										if(returnValue) then
											print(returnValue)
										end
									else
										for _, matData in pairs(returnValue) do
											table.insert(matDatas, matData)
										end
									end
								end
							else
								local matData = self:getMaterialData(name)
								if(matData) then
									table.insert(matDatas, matData)
								else
									print(name.." is an invalid material! Did you name it incorrectly?")
								end
							end
						end
					end

					for _, matData in pairs(matDatas) do
						self:putFlagMaterialForTeam(team, matData.material)
					end

					local firstMaterial = matDatas[1]
					local lastMaterial = matDatas[#matDatas]

					if(firstMaterial and lastMaterial) then
						local teamSpecific = (team == Team.Blue and "") or (team == Team.Red and " (1)")
						if(self.ChangeTeamNamesToFlagName) then
							local name = (firstMaterial == lastMaterial and firstMaterial.material.name:upper()) or firstMaterial.material.name:upper().." ALLIES"
					
							GameManager.SetTeamName(team, name)
							GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific.."/Header Panel/Text Team").GetComponent(Text).text = name
						end
				
						if(self.ChangeTeamColorToFlagColor) then
							local color = firstMaterial.teamColor
							ColorScheme.SetTeamColor(team, Color(color.r, color.g, color.b))
							color.a = 0.392
							GameObject.Find("Scoreboard Canvas/Panel/Team Panel"..teamSpecific.."/Header Panel").GetComponent(Image).color = color
						end

						for _, capturePoint in pairs(self.Flags) do
							if(capturePoint.owner == team) then
								self:setPointMaterial(capturePoint, firstMaterial.material)
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
	local materials = self.TeamToMaterial[ownerToUse]
	local length = self:getLengthOfDict(materials)

	if(length <= 0) then
		print("No materials to use for "..self.TeamToName[ownerToUse]) 
		return
	end

	local material
	for _, _material in pairs(materials) do
		if(capturePoint.flagRenderer.material.mainTexture == _material.mainTexture) then 
			material = _material
		end
	end
	material = material or self:getRandomFromDict(materials)

	if(newOwner == ownerToUse and self.OverlayLabel.activeSelf) then
		-- This means that the capture point was neutralized
		local textComponent = self.OverlayLabel.GetComponent(Text)
		local start, endI = textComponent.text:find("</color>")
		local endingString = textComponent.text:sub(endI+1)

		local matData = self:getMaterialData(material.name)
		local displayName = (self.ChangeTeamNamesToFlagName and matData.material.name) or self.TeamToName[newOwner]
		local tColor = matData.teamColor
		local color = Color(tColor.r, tColor.g, tColor.b)
		local colorTag = (self.ChangeTeamColorToFlagColor and ColorScheme.RichTextColorTag(color)) or ColorScheme.GetTeamColor(newOwner)
		local stringToUse = colorTag..displayName.."</color>"..endingString

		textComponent.text = stringToUse
	end

	self:setPointMaterial(capturePoint, material)
end

function MianFlagFramework:setPointMaterial(capturePoint, material)
	capturePoint.flagRenderer.material = material
	if(self:isOurMaterial(material) or self.OverrideVanillaFlagColor) then
		-- Have to be special here since Ravenfield just changes the color of their cloths for the teams
		capturePoint.flagRenderer.material.color = material.color
	end
	capturePoint.flagRenderer.material.SetTextureScale("_MainTex", material.GetTextureScale("_MainTex"))
end

function MianFlagFramework:pendingOwner()
	return CurrentEvent.listenerData.pendingOwner
end

function MianFlagFramework:onPendingOwnerChanged()
	self:autoSetPointMaterial(CurrentEvent.listenerData)
end

function MianFlagFramework:isSameMaterial(material, material2)
	return material.mainTexture == material2.mainTexture
end

function MianFlagFramework:isOurMaterial(material)
	for _, matData in pairs(self:getAllMaterialDatas()) do
		if(matData.material == material) then
			return matData.material
		end
	end

	return false;
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