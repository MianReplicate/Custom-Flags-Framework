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
	self.currentCategory = math.max(1, math.min(categoryNum, self.maxCategory))

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
	self.selectedFlagMutator = {
		metadata = {name = ""}
	}
	self.creatorEditor = {}
	self.commands = {
		ALLMUTATORS = "ALLMUTATORS",
		ALL = "ALL:REPLACE_WITH_MUTATOR_IDS",
		RANDOMIZE = "RANDOMIZE:REPLACE_WITH_FLAGS:HOW_MANY_TO_RANDOMIZE",
		TEAMNAME = "TEAMNAME:REPLACE_WITH_FLAGS:EXAMPLE_NAME",
		TEAMCOLOR= "TEAMCOLOR:REPLACE_WITH_FLAGS:255,255,255",
		FLAGCOLOR= "FLAGCOLOR:REPLACE_WITH_FLAGS:255,255,255"
	}
	self.inputables = {}
	self.updateCameraTo = {
		x = 0,
		y = 90,
		z = 0
	}
	self.selectedFlag = nil
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
	self.MutatorList = self.targets.MutatorList
	self.FlagList = self.targets.FlagList
	self.CategoryCounter = self.targets.CategoryCounter
	self.Forward = self.targets.Forward.GetComponent(Button)
	self.Backward = self.targets.Backward.GetComponent(Button)
	self.ActorSpawn = self.targets.ActorSpawn
	self.Search = self.targets.Search.GetComponent(InputField)
	self.Creator = {
		Search = self.targets.CreatorSearch.GetComponent(InputField),
		Output = self.targets.CreatorOutput.GetComponent(InputField),
		Content = self.targets.CreatorContent,
		Template = self.targets.CreatorTemplate,
		Forward = self.targets.CreatorForward.GetComponent(Button),
		Backward = self.targets.CreatorBackward.GetComponent(Button),
		CategoryCounter = self.targets.CreatorCategoryCounter,
		CommandTemplate = self.targets.CommandTemplate,
		CommandContent = self.targets.CommandContent
	}
	self.MutatorTemplate.SetActive(false)
	self.FlagTemplate.SetActive(false)

	self.mutatorList = list.createNewList(self.MutatorList.transform, nil, true)
	self.flagList = list.createNewList(self.FlagList.transform, self.CategoryCounter.GetComponentInChildren(Text))
	self.creatorList = list.createNewList(self.Creator.Content.transform, self.Creator.CategoryCounter.GetComponentInChildren(Text))

	self.Search.onValueChanged.AddListener(self, "calculateSearch", self.flagList)
	self.Creator.Search.onValueChanged.AddListener(self, "calculateSearch", self.creatorList)

	self.Forward.onClick.AddListener(self, "clickedForward")
	self.Backward.onClick.AddListener(self, "clickedBackward")
	self.Creator.Forward.onClick.AddListener(self, "clickedForwardCreator")
	self.Creator.Backward.onClick.AddListener(self, "clickedBackwardCreator")

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
	elseif(self.framework and self.framework.FinishedAddingTextures and not self.frameworkChecked) then
		self.frameworkChecked = true
		Screen.UnlockCursor()

		self.installedFlagMutators = self.framework:getLengthOfDict(self.framework.MutatorData)

		for _, mutatorData in pairs(self.framework.MutatorData) do
			self.mutatorList:makeObjectViewable(self:createMutatorInList(mutatorData, self.mutatorList, "clickedMutator"))
			self.creatorList:makeObjectViewable(self:createMutatorInList(mutatorData, self.creatorList, "clickedMutatorCreator", self.Creator.Template))

			for _, texData in pairs(mutatorData.textureDatas) do
				self:createFlagInList(mutatorData.metadata.name, texData, self.flagList, "clickedFlag")
				self.creatorList:makeObjectViewable(self:createFlagInList(nil, texData, self.creatorList, "clickedFlagCreator", self.Creator.Template))
			end
		end

		self.mutatorList:refreshViewables()
		self.creatorList:refreshViewables()

		local actor = ActorManager.CreateAIActor(Team.Blue)
		actor.SpawnAt(self.ActorSpawn.transform.position, self.ActorSpawn.transform.rotation)

		self:updateText()
	end

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
	self.Camera.transform.SetPositionAndRotation(self.Camera.transform.position, euler)
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

function FlagViewer:createFlagInList(mutatorName, texData, list, functionName, optionalTemplate)
	local flag = GameObject.Instantiate(optionalTemplate or self.FlagTemplate, list:getTransform())
	local image = flag.GetComponentInChildren(RawImage)
	local name = flag.GetComponentInChildren(Text)

	image.texture = texData.texture
	name.text = texData.texture.name
	local teamColor = texData.teamColor
	local color = (teamColor and Color(teamColor.r, teamColor.g, teamColor.b)) or Color(255, 255, 255)
	name.color = color

	if(self[functionName]) then
		image.onPointerClick.AddListener(self, functionName, texData)		
	end
	local object = {
		metadata = {
			mutatorOwner = mutatorName,
			texData = texData
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
		self.framework:setPointMaterial(self.FlagMorpher, self.framework:createMaterialFromTexData(Team.Blue,texData))
		ColorScheme.setTeamColor(Team.Blue, Color(color.r, color.g, color.b))
		self.selectedFlag = texData

		self:updateText()
	end
end

function FlagViewer:clickedMutator()
	local mutatorData = CurrentEvent.listenerData
	if(not self.selectedFlagMutator or (self.selectedFlagMutator and self.selectedFlagMutator.metadata.name ~= mutatorData.metadata.name)) then
		self.selectedFlagMutator = mutatorData

		self:calculateSearch(self.Search.text, self.flagList)
		self:updateText()
	end
end

function FlagViewer:clickedForward()
	self.flagList:changeToCategory(self.flagList.currentCategory + 1)
end

function FlagViewer:clickedBackward()
	self.flagList:changeToCategory(self.flagList.currentCategory - 1)
end

function FlagViewer:clickedForwardCreator()
	self.creatorList:changeToCategory(self.creatorList.currentCategory + 1)
end

function FlagViewer:clickedBackwardCreator()
	self.creatorList:changeToCategory(self.creatorList.currentCategory - 1)
end

function FlagViewer:triggerCommand()
	local commandString = self.commands[CurrentEvent.listenerData]
	if(commandString) then
		self:addToOutput(self:wrapCommand(commandString))
	end
end

function FlagViewer:clickedFlagCreator()
	local texData = CurrentEvent.listenerData
	local command = self.creatorEditor.addingCommand
	if(not command) then
		self:addToOutput(texData.texture.name)
	end
end

function FlagViewer:clickedMutatorCreator()
	local mutatorData = CurrentEvent.listenerData
	local command = self.creatorEditor.addingCommand
	if(not command) then
		self:addToOutput(mutatorData.metadata.name)
	end
end

function FlagViewer:calculateSearch(text, list)
	if(not text) then return end
	list = list or CurrentEvent.listenerData
	list:resetViewables()
	for _, objectData in pairs(list:getObjects()) do
		local metadata = objectData.metadata
		local object = objectData.object
		local foundOwner = type(metadata) ~= "table" or not metadata.mutatorOwner or metadata.mutatorOwner == self.selectedFlagMutator.metadata.name
		local canBeActive = foundOwner and string.find(object.GetComponentInChildren(Text).text, text:upper()) ~= nil
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
	if(#text > 0) then
		if(caretPosition == 1) then
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
		elseif(self.creatorEditor.selectionAnchorPosition and self.creatorEditor.selectionFocusPosition) then
			text = text:sub(1, self.creatorEditor.selectionAnchorPosition - 1)..string..text:sub(self.creatorEditor.selectionFocusPosition, #text)
		end
	else
		text = text..string
	end
	self.Creator.Output.text = text
end

function FlagViewer:outputExited()
	self.creatorEditor.caretPosition = self.Creator.Output.caretPosition + 1
	self.creatorEditor.selectionAnchorPosition = self.Creator.Output.selectionAnchorPosition + 1
	self.creatorEditor.selectionFocusPosition = self.Creator.Output.selectionFocusPosition + 1
end

function FlagViewer:wrapCommand(command)
	return "{"..command.."}"
end

function FlagViewer:log(...)
	print("<color=#00ff00>[Flag Viewer]:</color>", ...)
end

function FlagViewer:updateText()
	self.UIText.text = "Framework Version: "..self.framework.version.."\nInstalled Flag Mutators: "..self.installedFlagMutators.."\nSelected Flag Mutator: "..self.selectedFlagMutator.metadata.name.."\nSelected Flag: "..self.framework:getTexNameFlair(self.selectedFlag)
end