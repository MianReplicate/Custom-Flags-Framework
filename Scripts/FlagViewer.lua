-- Register the behaviour
behaviour("FlagViewer")

function FlagViewer:Awake()
	self.frameworkName = "Custom Flag Framework"
	self.TimesChecked = 0

	self.frameworkChecked = false
	self.mutatorObjects = {}
	self.flagObjects = {}
	self.installedFlagMutators = 0
	self.selectedFlagMutator = {
		metadata = {name = ""}
	}
	self.selectedFlag = ""
end

function FlagViewer:Start()
	self.FlagMorpherObject = self.targets.FlagMorpher
	self.FlagMorpher = self.FlagMorpherObject.GetComponent(CapturePoint)
	self.UIText = self.targets["UI Text"].GetComponent(Text)
	self.MutatorTemplate = self.targets.MutatorTemplate
	self.FlagTemplate = self.targets.FlagTemplate
	self.MutatorList = self.targets.MutatorList
	self.FlagList = self.targets.FlagList
	self.ActorSpawn = self.targets.ActorSpawn
	self.Search = self.targets.Search.GetComponent(InputField)
	self.MutatorTemplate.SetActive(false)
	self.FlagTemplate.SetActive(false)

	self.Search.onValueChanged.AddListener(self, "calculateSearch")
	self.UIText.text = "LOADING FLAG VIEWER..."
	print("This is my dummy flag: "..self.FlagMorpher.name)
end

function FlagViewer:Update()
	if(not self.framework) then
		self.TimesChecked  = self.TimesChecked + 1
		local obj = GameObject.Find(self.frameworkName)
		if(obj) then
			self.framework = ScriptedBehaviour.GetScript(obj)
			print("Got framework! Initializing Flag Viewer..")
		end

		if(self.TimesChecked > 100) then
			self.FlagMorpherObject.GetComponent(TriggerScriptedSignal).Send("playFrameworkNotDetected")
		end
	elseif(self.framework and self.framework.FinishedAddingTextures and not self.frameworkChecked) then
		self.frameworkChecked = true
		Screen.UnlockCursor()

		self.installedFlagMutators = self.framework:getLengthOfDict(self.framework.MutatorData)

		for _, mutatorData in pairs(self.framework.MutatorData) do
			self:createMutatorInList(mutatorData)
		end

		local actor = ActorManager.CreateAIActor(Team.Blue)
		actor.SpawnAt(self.ActorSpawn.transform.position, self.ActorSpawn.transform.rotation)

		self:updateText()
	end
end

function FlagViewer:createMutatorInList(mutatorData)
	local mutator = GameObject.Instantiate(self.MutatorTemplate, self.MutatorList.transform)
	local image = mutator.GetComponentInChildren(RawImage)
	local name = mutator.GetComponentInChildren(Text)

	local metadata = mutatorData.metadata
	image.texture = metadata.cover
	name.text = metadata.name

	image.onPointerClick.AddListener(self, "clickedMutator", mutatorData)
	table.insert(self.mutatorObjects, mutator)

	self.flagObjects[mutatorData.metadata.name] = {}

	for _, texData in pairs(mutatorData.textureDatas) do
		self:createFlagInList(metadata.name, texData)
	end

	mutator.SetActive(true)
end

function FlagViewer:createFlagInList(mutatorName, texData)
	local flag = GameObject.Instantiate(self.FlagTemplate, self.FlagList.transform)
	local image = flag.GetComponentInChildren(RawImage)
	local name = flag.GetComponentInChildren(Text)

	image.texture = texData.texture
	name.text = texData.texture.name
	local teamColor = texData.teamColor
	local color = (teamColor and Color(teamColor.r, teamColor.g, teamColor.b)) or Color(255, 255, 255)
	name.color = color

	image.onPointerClick.AddListener(self, "clickedFlag", texData)
	self.flagObjects[mutatorName][texData.texture.name] = flag
end

function FlagViewer:clickedFlag()
	local texData = CurrentEvent.listenerData
	local texture = texData.texture
	local color = texData.teamColor or ColorScheme.GetTeamColor(Team.Blue)
	if(texture.name ~= self.selectedFlag) then
		self.framework:setPointMaterial(self.FlagMorpher, self.framework:createMaterialFromTexture(Team.Blue,texture))
		ColorScheme.setTeamColor(Team.Blue, Color(color.r, color.g, color.b))
		self.selectedFlag = texture.name

		self:updateText()
	end
end

function FlagViewer:clickedMutator()
	local mutatorData = CurrentEvent.listenerData
	if(not self.selectedFlagMutator or (self.selectedFlagMutator and self.selectedFlagMutator.metadata.name ~= mutatorData.metadata.name)) then
		self.selectedFlagMutator = mutatorData

		self:calculateSearch(self.Search.text)
		self:updateText()
	end
end

function FlagViewer:calculateSearch(text)
	if(not text) then return end

	for mutatorName, flags in pairs(self.flagObjects) do
		for _, flag in pairs(flags) do
			flag.SetActive(mutatorName == self.selectedFlagMutator.metadata.name and string.find(flag.GetComponentInChildren(Text).text, text:upper()) ~= nil)
		end
	end
end

function FlagViewer:updateText()
	self.UIText.text = "Framework Version: "..self.framework.version.."\nInstalled Flag Mutators: "..self.installedFlagMutators.."\nSelected Flag Mutator: "..self.selectedFlagMutator.metadata.name.."\nSelected Flag: "..self.selectedFlag
end