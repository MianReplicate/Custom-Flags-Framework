-- Register the behaviour
behaviour("FlagViewer")

local function cloneTable(tble)
	local newTble = {}
	for key, value in pairs(tble) do
		newTble[key] = (type(value) == 'table' and cloneTable(value)) or value
	end
	return newTble
end

local lists = {}
local list = {}

function list.retrieveList(transform)
	return lists[transform]
end

function list.createNewList(transform, text, noCategories)
	local self = cloneTable(list)
	self.objects = {}
	self.viewables = {}
	self.categoryVisualizer = text
	if(not noCategories) then
		self.currentCategory = 1
		self.maxCategory = 0
		self.showEachCategory = 21
	end
	self.transform = transform

	lists[transform] = self

	return self
end

function list:changeToCategory(categoryNum)
	if(self.currentCategory == nil) then 
		for i = 1, #self.viewables, 1 do
			self.viewables[i].object.SetActive(true)
		end
		return
	end
	if(categoryNum > self.maxCategory) then
		categoryNum = 1
	elseif(categoryNum <= 0) then
		categoryNum = self.maxCategory
	end
	self.currentCategory = categoryNum

	local start = ((self.currentCategory - 1) * self.showEachCategory) + 1
	for i = 1, #self.viewables, 1 do
		local viewable = self.viewables[i]
		if(viewable) then
			self.viewables[i].object.SetActive(i >= start and i < start + self.showEachCategory)
		end
	end

	if(self.categoryVisualizer) then
		self.categoryVisualizer.text = self.currentCategory.."/"..self.maxCategory
	end
end

function list:resetViewables()
	for _, objectData in pairs(self.viewables) do
		objectData.object.SetActive(false)
	end
	self.viewables = {}
end

function list:makeObjectViewable(object)
	if(self.objects[object]) then
		table.insert(self.viewables, object)
	end
end

function list:refreshViewables()
	if(self.currentCategory) then
		self.maxCategory = math.ceil(#self.viewables / self.showEachCategory)
		self:changeToCategory(math.min(self.currentCategory, self.maxCategory))
	else
		self:changeToCategory()
	end
end

function list:getTransform()
	return self.transform
end

function list:addObject(object)
	self.objects[object] = object
end

function list:getObjects()
	return self.objects
end

function FlagViewer:Awake()
	self.frameworkName = "Custom Flag Framework"
	self.TimesChecked = 0

	self.frameworkChecked = false
	self.flagObjects = {}
	self.installedFlagMutators = 0
	self.selectedMutator = {
		metadata = {name = ""}
	}
	self.creatorEditor = {}
	self.commands = {
		LIST = "LIST:ADD_OR_GET:ADD_NAMES_HERE",
		COUNT = "COUNT:SOME_LIST",
		OPERATOR = "OPERATOR:OPERATION_TO_USE:A_NUMBER_TO_START:NUMBERS",
		ALLMUTATORS = "ALLMUTATORS:FLAGS_OR_MESHES",
		ALL = "ALL:MUTATOR_IDS",
		RANDOMIZE = "RANDOMIZE:DATAS:A_NUMBER",
		PLAYER = "PLAYER:FLAGS_OR_MESHES:ADD_NAMES_HERE",
		ACCESSORY = "ACCESSORY:FLAGS:MESHES",
		TEAMNAME = "TEAMNAME:FLAGS:EXAMPLE_NAME",
		TEAMCOLOR= "TEAMCOLOR:FLAGS:255,255,255",
		FLAGCOLOR= "FLAGCOLOR:FLAGS:255,255,255"
	}
	self.inputables = {}
	self.updateCameraTo = {
		x = 0,
		y = 90,
		z = 0
	}
	self.selectedFlag = nil
	self.selectedMesh = nil
end

function FlagViewer:addInputable(inputField)
	table.insert(self.inputables, inputField)
end

function FlagViewer:isFocusedOnAnyInput()
	for _, input in ipairs(self.inputables) do
		if(input.isFocused) then return true end
	end
	return false
end

function FlagViewer:Start()
	self.Camera = self.targets.Camera
	self.FlagMorpherObject = self.targets.FlagMorpher
	self.FlagMorpher = self.FlagMorpherObject.GetComponent(CapturePoint)
	self.UIText = self.targets["UI Text"].GetComponent(Text)
	self.MutatorTemplate = self.targets.MutatorTemplate
	self.FlagTemplate = self.targets.FlagTemplate
	self.MeshTemplate = self.targets.MeshTemplate
	self.MutatorList = self.targets.MutatorList
	self.FlagList = self.targets.FlagList
	self.CategoryCounter = self.targets.CategoryCounter
	self.Forward = self.targets.Forward.GetComponent(Button)
	self.Backward = self.targets.Backward.GetComponent(Button)
	self.ActorSpawn = self.targets.ActorSpawn
	self.Search = self.targets.Search.GetComponent(InputField)
	self.Flags = self.targets.FlagsButton.GetComponent(Button)
	self.Meshes = self.targets.AccessoriesButton.GetComponent(Button)
	self.onFlags = true
	self.demoActor = self.targets.DemoActor
	self.accessory = self.targets.Accessory
	self.ActorYRotation = 0
	self.Creator = {
		Search = self.targets.CreatorSearch.GetComponent(InputField),
		Output = self.targets.CreatorOutput.GetComponent(InputField),
		Content = self.targets.CreatorContent,
		Forward = self.targets.CreatorForward.GetComponent(Button),
		Backward = self.targets.CreatorBackward.GetComponent(Button),
		CategoryCounter = self.targets.CreatorCategoryCounter,
		CommandTemplate = self.targets.CommandTemplate,
		CommandContent = self.targets.CommandContent,
		Flags = self.targets.FlagsCreatorButton.GetComponent(Button),
		Mutators = self.targets.MutatorsCreatorButton.GetComponent(Button),
		Accessories = self.targets.AccessoriesCreatorButton.GetComponent(Button),
		currentlyOn = "flags"
	}
	self.MutatorTemplate.SetActive(false)
	self.FlagTemplate.SetActive(false)
	self.MeshTemplate.SetActive(false)

	self.mutatorList = list.createNewList(self.MutatorList.transform, nil, true)
	self.defaultList = list.createNewList(self.FlagList.transform, self.CategoryCounter.GetComponentInChildren(Text))
	self.creatorList = list.createNewList(self.Creator.Content.transform, self.Creator.CategoryCounter.GetComponentInChildren(Text))

	self.Search.onValueChanged.AddListener(self, "calculateSearch", {list=self.defaultList, conditionFunction=self.conditionForMainList})
	self.Creator.Search.onValueChanged.AddListener(self, "calculateSearch", {list=self.creatorList, conditionFunction=self.conditionForCreator})

	self.Forward.onClick.AddListener(self, "clickedForward")
	self.Backward.onClick.AddListener(self, "clickedBackward")
	self.Creator.Forward.onClick.AddListener(self, "clickedForwardCreator")
	self.Creator.Backward.onClick.AddListener(self, "clickedBackwardCreator")
	self.Creator.Flags.onClick.AddListener(self, "filterFlagCreator")
	self.Creator.Mutators.onClick.AddListener(self, "filterMutatorCreator")
	self.Creator.Accessories.onClick.AddListener(self, "filterAccessoryCreator")
	self.Flags.onClick.AddListener(self, "filterFlag")
	self.Meshes.onClick.AddListener(self, "filterMesh")

	self.Creator.Output.onEndEdit.AddListener(self, "outputExited")

	self:addInputable(self.Search)
	self:addInputable(self.Creator.Search)
	self:addInputable(self.Creator.Output)

	self.targets.CommandTemplate.SetActive(false)

	for commandName, _ in pairs(self.commands) do
		local command = GameObject.Instantiate(self.Creator.CommandTemplate, self.Creator.CommandContent.transform)
		local name = command.GetComponentInChildren(Text)
		name.text = commandName
		command.GetComponent(Button).onClick.AddListener(self, "triggerCommand", commandName)
		command.SetActive(true)
	end

	self.UIText.text = "LOADING FLAG VIEWER..."
	self:log("This is my dummy flag: "..self.FlagMorpher.name)
end

function FlagViewer:Update()
	if(not self.framework) then
		self.TimesChecked  = self.TimesChecked + 1
		local obj = GameObject.Find(self.frameworkName)
		if(obj) then
			self.framework = ScriptedBehaviour.GetScript(obj)
			self:log("Got framework! Initializing Flag Viewer..")
		end

		if(self.TimesChecked > 100 and not self.Told) then
			self.Told = true
			self.FlagMorpherObject.GetComponent(TriggerScriptedSignal).Send("playFrameworkNotDetected")
		end
	elseif(self.framework and self.framework.FinishedAddingPacks and not self.frameworkChecked) then
		self.frameworkChecked = true
		Screen.UnlockCursor()

		local installedFlagMutators = 0
		local installedMeshMutators = 0
		local packs = self.framework.MutatorPacks

		for _, pack in pairs(packs) do
			if(pack["meshes"]) then
				installedMeshMutators = installedMeshMutators + 1
			end
			if(pack["flags"]) then
				installedFlagMutators = installedFlagMutators + 1
			end
		end

		self.installedFlagMutators = installedFlagMutators
		self.installedMeshMutators = installedMeshMutators

		for _, mutatorData in pairs(self.framework.MutatorPacks) do
			self.mutatorList:makeObjectViewable(self:createMutatorInList(mutatorData, self.mutatorList, "clickedMutator"))
			self:createMutatorInList(mutatorData, self.creatorList, "clickedMutatorCreatorButton", self.FlagTemplate)

			local flags = mutatorData.flags
			local meshes = mutatorData.meshes
			if(flags) then
				for _, data in pairs(flags) do
					self:createFlagInList(mutatorData.metadata.name, data, self.defaultList, "clickedFlag")
					self:createFlagInList(nil, data, self.creatorList, "clickedFlagCreator", self.FlagTemplate)
				end
			end

			if(meshes) then
				for _, data in pairs(meshes) do
					self:createMeshInList(mutatorData.metadata.name, data, self.defaultList, "clickedMesh")
					self:createMeshInList(nil, data, self.creatorList, "clickedMeshCreator", self.MeshTemplate)
				end
			end
		end

		self.mutatorList:refreshViewables()
		self.creatorList:refreshViewables()

		self:updateText()
	end


	self.ActorYRotation = math.max(0, math.min(360, self.ActorYRotation + 0.35))
	if(self.ActorYRotation == 360) then
		self.ActorYRotation = 0
	end

	local rotation = self.demoActor.transform.rotation
	local euler = Quaternion.Euler(rotation.eulerAngles.x, self.ActorYRotation, rotation.eulerAngles.z)
	self.demoActor.transform.rotation = euler

	local toSet = {}
	for key, toValue in pairs(self.updateCameraTo) do
		local oldValue = self.Camera.transform.rotation.eulerAngles[key]
		local newValue = oldValue
		if(oldValue < toValue) then
			newValue = newValue + 0.5
			newValue = math.min(newValue, toValue)
		elseif(oldValue > toValue) then
			newValue = newValue - 0.5
			newValue = math.max(newValue, toValue)
		end
		toSet[key] = newValue
	end

	local euler = Quaternion.Euler(toSet.x, toSet.y, toSet.z)
	self.Camera.transform.rotation = euler
end

function FlagViewer:createMutatorInList(mutatorData, list, functionName, optionalTemplate)
	local mutator = GameObject.Instantiate(optionalTemplate or self.MutatorTemplate, list:getTransform())
	local image = mutator.GetComponentInChildren(RawImage)
	local name = mutator.GetComponentInChildren(Text)

	local metadata = mutatorData.metadata
	image.texture = metadata.cover
	name.text = metadata.name

	if(self[functionName]) then
		image.onPointerClick.AddListener(self, functionName, mutatorData)		
	end

	local object = {
		metadata = nil,
		object = mutator
	}
	list:addObject(object)

	return object
end

function FlagViewer:createMeshInList(mutatorName, data, list, functionName, optionalTemplate)
	local mesh = GameObject.Instantiate(optionalTemplate or self.MeshTemplate, list:getTransform())
	local name = mesh.GetComponentInChildren(Text)
	local button = mesh.GetComponentInChildren(Button)

	name.text = data.name

	if(self[functionName]) then
		button.onPointerClick.AddListener(self, functionName,data)		
	end
	local object = {
		metadata = {
			mutatorOwner = mutatorName,
			data = data
		},
		object = mesh
	}
	list:addObject(object)

	return object
end

function FlagViewer:createFlagInList(mutatorName, data, list, functionName, optionalTemplate)
	local flag = GameObject.Instantiate(optionalTemplate or self.FlagTemplate, list:getTransform())
	local image = flag.GetComponentInChildren(RawImage)
	local name = flag.GetComponentInChildren(Text)

	image.texture = data.texture
	name.text = data.name
	local teamColor = data.teamColor
	local color = (teamColor and Color(teamColor.r, teamColor.g, teamColor.b)) or Color(255, 255, 255)
	name.color = color

	if(self[functionName]) then
		image.onPointerClick.AddListener(self, functionName, data)		
	end
	local object = {
		metadata = {
			mutatorOwner = mutatorName,
			data = data
		},
		object = flag
	}
	list:addObject(object)

	return object
end

function FlagViewer:clickedFlag()
	local texData = CurrentEvent.listenerData
	local color = texData.teamColor or ColorScheme.GetTeamColor(Team.Blue)
	if(texData ~= self.selectedFlag) then
		self.framework:setPointMaterial(self.FlagMorpher, self.framework:createOrGetExistingMaterialFromTexture("Flags", texData.texture))
		self.demoActor.GetComponentInChildren(SkinnedMeshRenderer).material.color = Color(color.r, color.g, color.b)
		self.selectedFlag = texData

		self.ignoreListener = true
		self:clickedMesh(self.selectedMesh)
		self.ignoreListener = false
		self:updateText()
	end
end

function FlagViewer:clickedMesh(meshData)
	meshData = (not self.ignoreListener and CurrentEvent.listenerData) or meshData
	if((meshData ~= self.selectedMesh or meshData ~= CurrentEvent.listenerData) and meshData) then
		self.selectedMesh = meshData

		if(self.selectedFlag ~= nil) then
			local flagMaterial = self.framework:createOrGetExistingMaterialFromTexture("Flat", self.selectedFlag.texture, nil, 1)
			local materials = {}
			for _, material in ipairs(meshData.materials) do
				if(self.framework:canBeReplacedWithFlagTexture(material)) then
					table.insert(materials, flagMaterial)
				else
					table.insert(materials, material)
				end
			end

			self.accessory.SetActive(true)
			local skMR = self.accessory.GetComponent(SkinnedMeshRenderer)
			skMR.sharedMesh = meshData.mesh
			skMR.materials = materials
		end

		self:updateText()
	end
end

function FlagViewer:clickedMutator()
	local mutatorData = CurrentEvent.listenerData
	if(not self.selectedMutator or (self.selectedMutator and self.selectedMutator.metadata.name ~= mutatorData.metadata.name)) then
		self.selectedMutator = mutatorData

		self:calculateSearch(self.Search.text, self.defaultList, self.conditionForMainList)
		self:updateText()
	end
end

function FlagViewer:conditionForMainList(objectData)
	local metadata = objectData.metadata
	local isFlag = metadata.data.texture ~= nil
	return ((not isFlag and not self.onFlags) or (isFlag and self.onFlags)) and (type(metadata) ~= "table" or not metadata.mutatorOwner or metadata.mutatorOwner == self.selectedMutator.metadata.name)
end

function FlagViewer:conditionForCreator(objectData)
	local whatIsThis = (objectData.metadata == nil and "mutators") or (objectData.metadata.data.texture and "flags") or (objectData.metadata.data.mesh and "meshes")
	return whatIsThis == self.Creator.currentlyOn
end

function FlagViewer:clickedForward()
	self.defaultList:changeToCategory(self.defaultList.currentCategory + 1)
end

function FlagViewer:clickedBackward()
	self.defaultList:changeToCategory(self.defaultList.currentCategory - 1)
end

function FlagViewer:clickedForwardCreator()
	self.creatorList:changeToCategory(self.creatorList.currentCategory + 1)
end

function FlagViewer:clickedBackwardCreator()
	self.creatorList:changeToCategory(self.creatorList.currentCategory - 1)
end

function FlagViewer:filterFlagCreator()
	self.Creator.currentlyOn = "flags"
	self:calculateSearch(self.Creator.Search.text, self.creatorList, self.conditionForCreator)
end

function FlagViewer:filterMutatorCreator()
	self.Creator.currentlyOn = "mutators"
	self:calculateSearch(self.Creator.Search.text, self.creatorList, self.conditionForCreator)
end

function FlagViewer:filterAccessoryCreator()
	self.Creator.currentlyOn = "meshes"
	self:calculateSearch(self.Creator.Search.text, self.creatorList, self.conditionForCreator)
end

function FlagViewer:filterFlag()
	self.onFlags = true
	self:calculateSearch(self.Search.text, self.defaultList, self.conditionForMainList)
end

function FlagViewer:filterMesh()
	self.onFlags = false
	self:calculateSearch(self.Search.text, self.defaultList, self.conditionForMainList)
end

function FlagViewer:triggerCommand()
	local commandString = self.commands[CurrentEvent.listenerData]
	if(commandString) then
		self:addToOutput(self:wrapCommand(commandString))
	end
end

function FlagViewer:clickedFlagCreator()
	local texData = CurrentEvent.listenerData
	self:addToOutput(texData.texture.name)
end

function FlagViewer:clickedMeshCreator()
	local meshData = CurrentEvent.listenerData
	self:addToOutput(meshData.mesh.name)
end

function FlagViewer:clickedMutatorCreatorButton()
	local mutatorData = CurrentEvent.listenerData
	self:addToOutput(mutatorData.metadata.name)
end

function FlagViewer:calculateSearch(text, list, conditionFunction)
	if(not text) then return end
	list = list or CurrentEvent.listenerData.list
	conditionFunction = conditionFunction or (CurrentEvent.listenerData and CurrentEvent.listenerData.conditionFunction)

	list:resetViewables()
	for _, objectData in pairs(list:getObjects()) do
		local object = objectData.object
		local canBeActive = (not conditionFunction or conditionFunction(self, objectData)) and string.find(object.GetComponentInChildren(Text).text, text:upper()) ~= nil
		if(canBeActive) then
			list:makeObjectViewable(objectData)
		end
	end

	list:refreshViewables()
end

function FlagViewer:cameraRight()
	if(self:isFocusedOnAnyInput()) then return end
	self.updateCameraTo.y = 90
end

function FlagViewer:cameraLeft()
	if(self:isFocusedOnAnyInput()) then return end
	self.updateCameraTo.y = 0
end

function FlagViewer:addToOutput(string)
	local text = self.Creator.Output.text
	local caretPosition = self.creatorEditor.caretPosition or 0
	local anchorPos = self.creatorEditor.selectionAnchorPosition
	local focusPos = self.creatorEditor.selectionFocusPosition
	if(#text > 0) then
		if(anchorPos and focusPos and anchorPos ~= focusPos) then
			local temp = 0
			if(anchorPos > focusPos) then
				temp = focusPos
				focusPos = anchorPos
				anchorPos = temp
			end
			text = text:sub(1, anchorPos)..string..text:sub(focusPos + 1, #text)
		elseif(caretPosition == 0) then
			local commaFound = text:sub(1, 1) == ','
			if(commaFound) then
				text = string..text
			else
				text = string..","..text
			end
		elseif(caretPosition == #text) then
			local commaFound = text:sub(#text, #text) == ','
			if(commaFound) then
				text = text..string
			else
				text = text..","..string
			end
		elseif(anchorPos and focusPos) then
			text = text:sub(1, anchorPos)..string..text:sub(focusPos + 1, #text)
		end
	else
		text = text..string
	end

	self.creatorEditor.caretPosition = 0
	self.creatorEditor.selectionAnchorPosition = 0
	self.creatorEditor.selectionFocusPosition = 0
	self.Creator.Output.text = text
end

function FlagViewer:outputExited()
	self.creatorEditor.caretPosition = self.Creator.Output.caretPosition
	self.creatorEditor.selectionAnchorPosition = self.Creator.Output.selectionAnchorPosition
	self.creatorEditor.selectionFocusPosition = self.Creator.Output.selectionFocusPosition
end

function FlagViewer:wrapCommand(command)
	return "{"..command.."}"
end

function FlagViewer:updateText()
	self.UIText.text = "Framework Version: "..self.framework.version.."\nInstalled Flag Mutators: "..self.installedFlagMutators.."\nInstalled Mesh Mutators: "..self.installedMeshMutators.."\nSelected Mutator: "..self.selectedMutator.metadata.name.."\nSelected Flag: "..self.framework:getNameFlair(self.selectedFlag).."\nSelected Mesh: "..self.framework:getNameFlair(self.selectedMesh)
end

function FlagViewer:log(...)
	local string = "<color=#00ff00>[Flag Viewer]:</color> "
	for _, extraArg in ipairs({...}) do
		string = string..tostring(extraArg)
	end
	print(string)
end