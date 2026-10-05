-- SPEED ULTRA V8
-- Projeto de teste
-- Velocidade + Carry + Recovery

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.15)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

if not RunService:IsClient() then
	return
end

local Player = Players.LocalPlayer
if not Player then
	return
end

local PlayerGui = Player:WaitForChild("PlayerGui", 30)
if not PlayerGui then
	return
end

local Config = {
	DEFAULT_SPEED = 255,
	CARRY_SPEED = 255,
	MIN_SPEED = 0,
	MAX_SPEED = 1000,

	MOVEMENT_MODE = "WalkSpeed",

	ACCELERATION = 55,
	DECELERATION = 16,
	MAX_HORIZONTAL_VELOCITY = 1500,

	WATCHDOG_INTERVAL = 0.75,
	RECOVERY_WINDOW = 30,
	MAX_RECOVERIES = 6,
	RECOVERY_COOLDOWN = 1,

	LOCK_WALKSPEED = true,

	DETECT_TOOLS = true,
	DETECT_ATTRIBUTES = true,
	DETECT_TAGS = true,
	DETECT_CONSTRAINTS = true,

	CARRY_ATTRIBUTES = {
		"Carrying",
		"IsCarrying",
		"HasCarry",
		"CarryingObject",
		"IsCarryingObject",
		"Holding",
		"IsHolding",
		"HasObject"
	},

	CARRY_TAGS = {
		"Carry",
		"Carried",
		"CarryObject",
		"Carrying",
		"Held",
		"HeavyObject"
	},

	GUI_NAME = "SpeedUltraV8_2026",
	DEBUG = false
}

local State = {
	Alive = true,
	Enabled = true,

	TargetSpeed = Config.DEFAULT_SPEED,

	Carrying = false,
	CarriedObject = nil,
	CarryScanPending = false,

	Character = nil,
	Humanoid = nil,
	RootPart = nil,

	OriginalWalkSpeed = nil,

	CharacterGeneration = 0,
	PreparationToken = 0,
	Preparing = false,

	RecoveryWindowStart = 0,
	RecoveryCount = 0,
	LastRecovery = 0,

	Dragging = false,
	DragStart = Vector2.zero,
	PanelStart = Vector2.zero
}

local Connections = {
	Global = {},
	Character = {},
	Camera = {}
}

local function Debug(...)
	if Config.DEBUG then
		warn("[SPEED ULTRA V8]", ...)
	end
end

local function Disconnect(connection)
	if not connection then
		return
	end

	pcall(function()
		connection:Disconnect()
	end)
end

local function DisconnectGroup(group)
	for key, connection in pairs(group) do
		Disconnect(connection)
		group[key] = nil
	end
end

local function SetConnection(group, key, connection)
	Disconnect(group[key])
	group[key] = connection
end

local function IsFiniteNumber(value)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function NormalizeSpeed(value)
	if not IsFiniteNumber(value) then
		return nil
	end

	return math.clamp(
		value,
		Config.MIN_SPEED,
		Config.MAX_SPEED
	)
end

local oldGui = PlayerGui:FindFirstChild(Config.GUI_NAME)

if oldGui then
	pcall(function()
		oldGui:Destroy()
	end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = Config.GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(215, 120)
Frame.Position = UDim2.fromOffset(25, 200)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 9)
Corner.Parent = Frame

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 3)
Accent.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
Accent.BorderSizePixel = 0
Accent.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 25)
Title.Position = UDim2.fromOffset(8, 5)
Title.BackgroundTransparency = 1
Title.Text = "SPEED ULTRA V8"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Frame

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.fromOffset(85, 29)
SpeedBox.Position = UDim2.fromOffset(10, 36)
SpeedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpeedBox.BorderSizePixel = 0
SpeedBox.Text = tostring(State.TargetSpeed)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.Font = Enum.Font.SourceSans
SpeedBox.TextSize = 16
SpeedBox.ClearTextOnFocus = false
SpeedBox.Parent = Frame

local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.fromOffset(90, 29)
ApplyButton.Position = UDim2.fromOffset(105, 36)
ApplyButton.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
ApplyButton.BorderSizePixel = 0
ApplyButton.Text = "APLICAR"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.Font = Enum.Font.SourceSansBold
ApplyButton.TextSize = 12
ApplyButton.Parent = Frame

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(85, 27)
Toggle.Position = UDim2.fromOffset(10, 73)
Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Toggle.BorderSizePixel = 0
Toggle.Text = "SISTEMA: ON"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextSize = 11
Toggle.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(115, 27)
Status.Position = UDim2.fromOffset(100, 73)
Status.BackgroundTransparency = 1
Status.Text = "INICIANDO"
Status.TextColor3 = Color3.fromRGB(170, 170, 170)
Status.Font = Enum.Font.SourceSans
Status.TextSize = 10
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

local function SetStatus(text)
	if not State.Alive then
		return
	end

	if Status and Status.Parent then
		Status.Text = tostring(text)
	end
end

local function RefreshStatus()
	if not State.Alive then
		return
	end

	if not State.Enabled then
		SetStatus("DESATIVADO")
	elseif State.Carrying then
		SetStatus("CARRY • " .. tostring(Config.CARRY_SPEED))
	elseif not State.Character then
		SetStatus("AGUARDANDO")
	elseif not State.Humanoid then
		SetStatus("CARREGANDO")
	else
		SetStatus("ATIVO • " .. tostring(State.TargetSpeed))
	end
end

local function CanRecover()
	local now = os.clock()

	if now - State.RecoveryWindowStart > Config.RECOVERY_WINDOW then
		State.RecoveryWindowStart = now
		State.RecoveryCount = 0
	end

	if now - State.LastRecovery < Config.RECOVERY_COOLDOWN then
		return false
	end

	return State.RecoveryCount < Config.MAX_RECOVERIES
end

local function RegisterRecovery()
	local now = os.clock()

	if now - State.RecoveryWindowStart > Config.RECOVERY_WINDOW then
		State.RecoveryWindowStart = now
		State.RecoveryCount = 0
	end

	State.RecoveryCount += 1
	State.LastRecovery = now
end

local function ValidCharacter(character, generation, token)
	return State.Alive
		and Player.Character == character
		and State.Character == character
		and State.CharacterGeneration == generation
		and State.PreparationToken == token
end

local function CheckAttributes(object)
	if not Config.DETECT_ATTRIBUTES or not object then
		return false
	end

	for _, attributeName in ipairs(Config.CARRY_ATTRIBUTES) do
		local value = object:GetAttribute(attributeName)

		if value == true then
			return true
		end

		if type(value) == "number" and value > 0 then
			return true
		end

		if type(value) == "string" and value ~= "" then
			return true
		end
	end

	return false
end

local function CheckTags(object)
	if not Config.DETECT_TAGS or not object then
		return false
	end

	for _, tagName in ipairs(Config.CARRY_TAGS) do
		if CollectionService:HasTag(object, tagName) then
			return true
		end
	end

	return false
end

local function CheckTool(character)
	if not Config.DETECT_TOOLS then
		return false, nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return true, child
		end
	end

	return false, nil
end

local function CheckExternalConstraint(character)
	if not Config.DETECT_CONSTRAINTS then
		return false, nil
	end

	for _, object in ipairs(character:GetDescendants()) do
		local p0
		local p1

		if object:IsA("WeldConstraint")
			or object:IsA("Weld")
			or object:IsA("Motor6D") then

			p0 = object.Part0
			p1 = object.Part1

		elseif object:IsA("AlignPosition")
			or object:IsA("AlignOrientation")
			or object:IsA("RopeConstraint")
			or object:IsA("RodConstraint")
			or object:IsA("SpringConstraint")
			or object:IsA("BallSocketConstraint")
			or object:IsA("HingeConstraint")
			or object:IsA("PrismaticConstraint")
			or object:IsA("CylindricalConstraint")
			or object:IsA("UniversalConstraint") then

			local a0 = object.Attachment0
			local a1 = object.Attachment1

			if a0 and a0.Parent and a0.Parent:IsA("BasePart") then
				p0 = a0.Parent
			end

			if a1 and a1.Parent and a1.Parent:IsA("BasePart") then
				p1 = a1.Parent
			end
		end

		if p0 and p1 then
			local inside0 = p0:IsDescendantOf(character)
			local inside1 = p1:IsDescendantOf(character)

			if inside0 ~= inside1 then
				if inside0 then
					return true, p1
				else
					return true, p0
				end
			end
		end
	end

	return false, nil
end

local function DetectCarry()
	local character = State.Character

	if not character then
		return false, nil
	end

	if CheckAttributes(character) then
		return true, character
	end

	if CheckTags(character) then
		return true, character
	end

	local toolFound, tool = CheckTool(character)

	if toolFound then
		return true, tool
	end

	for _, object in ipairs(character:GetDescendants()) do
		if CheckAttributes(object) or CheckTags(object) then
			return true, object
		end
	end

	local constraintFound, external = CheckExternalConstraint(character)

	if constraintFound then
		return true, external
	end

	return false, nil
end

local function GetDesiredSpeed()
	if State.Carrying then
		return NormalizeSpeed(Config.CARRY_SPEED) or State.TargetSpeed
	end

	return NormalizeSpeed(State.TargetSpeed) or Config.DEFAULT_SPEED
end

local function ApplySpeed()
	if not State.Alive
		or not State.Enabled
		or not Config.LOCK_WALKSPEED then

		return false
	end

	local humanoid = State.Humanoid

	if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
		return false
	end

	local desired = GetDesiredSpeed()

	if humanoid.WalkSpeed == desired then
		return true
	end

	local success = pcall(function()
		humanoid.WalkSpeed = desired
	end)

	if success then
		State.LastSpeedApply = os.clock()
	end

	return success
end

local function UpdateCarryState()
	if not State.Alive or not State.Character then
		return
	end

	local carrying, object = DetectCarry()

	if carrying ~= State.Carrying then
		Debug("Carry mudou:", carrying)
	end

	State.Carrying = carrying
	State.CarriedObject = object

	ApplySpeed()
	RefreshStatus()
end

local function ScheduleCarryScan()
	if not State.Alive or State.CarryScanPending then
		return
	end

	State.CarryScanPending = true

	task.defer(function()
		State.CarryScanPending = false

		if State.Alive then
			UpdateCarryState()
		end
	end)
end

local function PrepareCharacter(character, isRecovery)
	if not State.Alive or not character or State.Preparing then
		return
	end

	if isRecovery then
		if not CanRecover() then
			SetStatus("RECUPERAÇÃO LIMITADA")
			return
		end

		RegisterRecovery()
	end

	State.Preparing = true

	State.CharacterGeneration += 1
	State.PreparationToken += 1

	local generation = State.CharacterGeneration
	local token = State.PreparationToken

	DisconnectGroup(Connections.Character)

	State.Character = nil
	State.Humanoid = nil
	State.RootPart = nil
	State.Carrying = false
	State.CarriedObject = nil
	State.OriginalWalkSpeed = nil
	State.CarryScanPending = false

	State.Character = character

	SetStatus("CARREGANDO...")

	local humanoid = character:WaitForChild("Humanoid", 15)

	if not ValidCharacter(character, generation, token) then
		State.Preparing = false
		return
	end

	if not humanoid then
		State.Preparing = false
		SetStatus("ERRO HUMANOID")
		return
	end

	State.OriginalWalkSpeed = humanoid.WalkSpeed

	local root = character:WaitForChild("HumanoidRootPart", 15)

	if not ValidCharacter(character, generation, token) then
		State.Preparing = false
		return
	end

	if not root then
		State.Preparing = false
		SetStatus("ERRO ROOT")
		return
	end

	State.Humanoid = humanoid
	State.RootPart = root

	SetConnection(
		Connections.Character,
		"ChildAdded",
		character.ChildAdded:Connect(ScheduleCarryScan)
	)

	SetConnection(
		Connections.Character,
		"ChildRemoved",
		character.ChildRemoved:Connect(ScheduleCarryScan)
	)

	SetConnection(
		Connections.Character,
		"DescendantAdded",
		character.DescendantAdded:Connect(ScheduleCarryScan)
	)

	SetConnection(
		Connections.Character,
		"DescendantRemoving",
		character.DescendantRemoving:Connect(ScheduleCarryScan)
	)

	SetConnection(
		Connections.Character,
		"WalkSpeed",
		humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if State.Alive
				and State.Enabled
				and Config.LOCK_WALKSPEED
				and ValidCharacter(character, generation, token)
				and humanoid.Health > 0 then

				ApplySpeed()
			end
		end)
	)

	SetConnection(
		Connections.Character,
		"Died",
		humanoid.Died:Connect(function()
			State.Carrying = false
			State.CarriedObject = nil
			SetStatus("MORTO")
		end)
	)

	UpdateCarryState()
	ApplySpeed()

	State.Preparing = false
	RefreshStatus()
end

local function SetTargetSpeed()
	local clean = string.gsub(SpeedBox.Text, "%s+", "")

	if clean == "" then
		SpeedBox.Text = tostring(State.TargetSpeed)
		RefreshStatus()
		return
	end

	local value = tonumber(clean)
	local speed = NormalizeSpeed(value)

	if not speed then
		SpeedBox.Text = tostring(State.TargetSpeed)
		SetStatus("VALOR INVÁLIDO")

		task.delay(1, function()
			if State.Alive then
				RefreshStatus()
			end
		end)

		return
	end

	State.TargetSpeed = speed
	SpeedBox.Text = tostring(speed)

	ApplySpeed()
	RefreshStatus()
end

local function ToggleSystem()
	State.Enabled = not State.Enabled

	if State.Enabled then
		Toggle.Text = "SISTEMA: ON"
		ApplySpeed()
	else
		Toggle.Text = "SISTEMA: OFF"

		local humanoid = State.Humanoid
		local original = State.OriginalWalkSpeed

		if humanoid
			and humanoid.Parent
			and IsFiniteNumber(original) then

			pcall(function()
				humanoid.WalkSpeed = original
			end)
		end
	end

	RefreshStatus()
end

ApplyButton.Activated:Connect(SetTargetSpeed)
SpeedBox.FocusLost:Connect(SetTargetSpeed)
Toggle.Activated:Connect(ToggleSystem)

if Config.MOVEMENT_MODE == "Hybrid" then
	RunService.PreSimulation:Connect(function(deltaTime)
		if not State.Alive or not State.Enabled then
			return
		end

		local humanoid = State.Humanoid
		local root = State.RootPart

		if not humanoid
			or not root
			or not humanoid.Parent
			or not root.Parent
			or humanoid.Health <= 0
			or root.Anchored then

			return
		end

		if not IsFiniteNumber(deltaTime) then
			return
		end

		local velocity = root.AssemblyLinearVelocity

		if typeof(velocity) ~= "Vector3"
			or not IsFiniteNumber(velocity.X)
			or not IsFiniteNumber(velocity.Y)
			or not IsFiniteNumber(velocity.Z) then

			return
		end

		local moveVelocity = humanoid:GetMoveVelocity()

		if typeof(moveVelocity) ~= "Vector3" then
			return
		end

		local dt = math.clamp(deltaTime, 0, 0.1)

		local currentX = velocity.X
		local currentZ = velocity.Z

		local targetX = moveVelocity.X
		local targetZ = moveVelocity.Z

		local moving =
			math.abs(targetX) > 0.001
			or math.abs(targetZ) > 0.001

		local rate =
			moving
			and Config.ACCELERATION
			or Config.DECELERATION

		if not moving then
			targetX = 0
			targetZ = 0
		end

		local alpha =
			1 - math.exp(-rate * dt)

		local newX =
			currentX
			+ (targetX - currentX) * alpha

		local newZ =
			currentZ
			+ (targetZ - currentZ) * alpha

		if
			math.abs(newX - velocity.X) > 0.05
			or math.abs(newZ - velocity.Z) > 0.05
		then

			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(
					newX,
					velocity.Y,
					newZ
				)
			end)
		end
	end)
end

Player.CharacterAdded:Connect(function(character)
	task.defer(function()
		if State.Alive and character == Player.Character then
			PrepareCharacter(character, false)
		end
	end)
end)

Player.CharacterRemoving:Connect(function(character)
	if character ~= State.Character then
		return
	end

	local humanoid = State.Humanoid
	local original = State.OriginalWalkSpeed

	if humanoid
		and humanoid.Parent
		and IsFiniteNumber(original) then

		pcall(function()
			humanoid.WalkSpeed = original
		end)
	end

	State.CharacterGeneration += 1
	State.PreparationToken += 1

	DisconnectGroup(Connections.Character)

	State.Character = nil
	State.Humanoid = nil
	State.RootPart = nil
	State.Carrying = false
	State.CarriedObject = nil
	State.OriginalWalkSpeed = nil
	State.Preparing = false
	State.CarryScanPending = false

	SetStatus("PERSONAGEM REMOVIDO")
end)

task.spawn(function()
	while State.Alive do
		task.wait(Config.WATCHDOG_INTERVAL)

		if not State.Alive then
			break
		end

		local character = Player.Character

		if not character then
			RefreshStatus()
			continue
		end

		if character ~= State.Character then
			if not State.Preparing then
				PrepareCharacter(character, false)
			end
			continue
		end

		if not State.Humanoid
			or not State.Humanoid.Parent then

			if not State.Preparing then
				PrepareCharacter(character, true)
			end

			continue
		end

		if not State.RootPart
			or not State.RootPart.Parent then

			if not State.Preparing then
				PrepareCharacter(character, true)
			end

			continue
		end

		UpdateCarryState()
		ApplySpeed()
	end
end)

local function GetPanelLimits()
	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize

	return
		math.max(0, viewport.X - Frame.AbsoluteSize.X),
		math.max(0, viewport.Y - Frame.AbsoluteSize.Y)
end

local function ClampPanel(x, y)
	local maxX, maxY = GetPanelLimits()

	if not maxX or not maxY then
		return x, y
	end

	return
		math.clamp(x, 0, maxX),
		math.clamp(y, 0, maxY)
end

Title.InputBegan:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then

		State.Dragging = true

		State.DragStart = Vector2.new(
			input.Position.X,
			input.Position.Y
		)

		State.PanelStart = Vector2.new(
			Frame.AbsolutePosition.X,
			Frame.AbsolutePosition.Y
		)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not State.Dragging then
		return
	end

	if
		input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseMovement
	then

		return
	end

	local current = Vector2.new(
		input.Position.X,
		input.Position.Y
	)

	local delta = current - State.DragStart

	local x = State.PanelStart.X + delta.X
	local y = State.PanelStart.Y + delta.Y

	x, y = ClampPanel(x, y)

	Frame.Position = UDim2.fromOffset(x, y)
end)

UserInputService.InputEnded:Connect(function(input)
	if
		input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then

		State.Dragging = false
	end
end)

local camera = workspace.CurrentCamera

if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local x, y = ClampPanel(
			Frame.AbsolutePosition.X,
			Frame.AbsolutePosition.Y
		)

		Frame.Position = UDim2.fromOffset(x, y)
	end)
end

if Player.Character then
	PrepareCharacter(Player.Character, false)
else
	SetStatus("AGUARDANDO")
end

RefreshStatus()
