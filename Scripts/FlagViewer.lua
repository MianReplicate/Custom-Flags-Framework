-- Register the behaviour
behaviour("FlagViewer")

function FlagViewer:Awake()
	self.frameworkName = "Flag Framework(Clone)"
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
	self.MutatorTemplate.SetActive(false)
	self.FlagTemplate.SetActive(false)

	self.UIText.text = "LOADING..."
	print("Hey this is my dummy flag for testing :): "..self.FlagMorpher.name)
end

function FlagViewer:Update()
	if(not self.framework) then
		self.TimesChecked  = self.TimesChecked + 1
		local obj = GameObject.Find(self.frameworkName)
		if(obj) then
			self.framework = ScriptedBehaviour.GetScript(obj)
			print("Got framework! Initializing map..")
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
	mutator.SetActive(true)
end

function FlagViewer:createFlagInList(matData)
	local flag = GameObject.Instantiate(self.FlagTemplate, self.FlagList.transform)
	local image = flag.GetComponentInChildren(RawImage)
	local name = flag.GetComponentInChildren(Text)

	local material = Material(matData.material)
	image.texture = material.mainTexture
	name.text = material.name
	local color = Color(matData.teamColor.r, matData.teamColor.g, matData.teamColor.b)
	name.color = color

	image.onPointerClick.AddListener(self, "clickedFlag", matData)
	table.insert(self.flagObjects, flag)
	flag.SetActive(true)
end

function FlagViewer:clickedFlag()
	local matData = CurrentEvent.listenerData
	local material = matData.material
	local color = matData.teamColor
	if(material.name ~= self.selectedFlag) then
		self.framework:setPointMaterial(self.FlagMorpher, material)
		ColorScheme.setTeamColor(Team.Blue, Color(color.r, color.g, color.b))
		self.selectedFlag = material.name

		self:updateText()
	end
end

function FlagViewer:clickedMutator()
	local mutatorData = CurrentEvent.listenerData
	if(not self.selectedFlagMutator or (self.selectedFlagMutator and self.selectedFlagMutator.metadata.name ~= mutatorData.metadata.name)) then
		self.selectedFlagMutator = mutatorData

		for index, object in pairs(self.flagObjects) do
			GameObject.Destroy(object)
			table.remove(self.flagObjects, index)
		end
	
		for _, matData in pairs(mutatorData.materialDatas) do
			self:createFlagInList(matData)
		end

		self:updateText()
	end
end

function FlagViewer:updateText()
	self.UIText.text = "Installed Flag Mutators: "..self.installedFlagMutators.."\nSelected Flag Mutator: "..self.selectedFlagMutator.metadata.name.."\nSelected Flag: "..self.selectedFlag
end