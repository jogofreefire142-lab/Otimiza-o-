-- =========================================================
-- SPEED ULTRA V8.3
-- V8.2 + CORREÇÃO DE VELOCIDADE NO CARRY
-- Otimiza apenas os efeitos selecionados em 35%; os outros 65% do visual permanecem intocados.: sem remover texturas, materiais ou sombras

-- =========================================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.15)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

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

-- =========================================================
-- AMBIENTE / INSTANCIA UNICA
-- Evita que uma execucao nova deixe conexoes da antiga vivas.
-- =========================================================

local Env = _G
pcall(function()
	if type(getgenv) == "function" then
		local generated = getgenv()
		if type(generated) == "table" then
			Env = generated
		end
	end
end)
local REGISTRY_KEY = "__SPEED_ULTRA_INSTANCE"

pcall(function()
	local oldCleanup = Env[REGISTRY_KEY]
	if type(oldCleanup) == "function" then
		oldCleanup("RELOAD")
	end
end)

-- =========================================================
-- CONFIGURACAO
-- =========================================================

local Config = {
	DEFAULT_SPEED = 255,
	-- Em objetos fisicos grandes, velocidade muito alta pode provocar
	-- correcao de rede/recuo. O valor normal continua alto; o modo pesado
	-- usa um limite mais estavel.
	CARRY_SPEED = 255,
	-- O carry usa a mesma velocidade configurada.
	-- Em vez de reduzir a velocidade para objetos grandes, o script evita
	-- reaplicar WalkSpeed repetidamente enquanto a interacao fisica ocorre.
	CARRY_HANDOFF_GRACE = 0.35,
	CARRY_REAPPLY_INTERVAL = 0.70,
	CARRY_SPEED_RECOVERY_DELAY = 0.55,
	CARRY_SPEED_TOLERANCE = 0.50,

	-- Estabilização adaptativa para objetos carregados de tamanhos diferentes.
	-- Objetos pequenos não são alterados. Objetos grandes ficam sem massa
	-- física efetiva durante o carry; os muito grandes também não colidem.
	CARRY_ADAPTIVE_PHYSICS = true,
	CARRY_PHYSICS_SCAN_INTERVAL = 0.45,
	CARRY_MEDIUM_SIZE = 5,
	CARRY_LARGE_SIZE = 8,
	CARRY_XL_SIZE = 13,
	CARRY_MEDIUM_MASS = 35,
	CARRY_LARGE_MASS = 80,
	CARRY_XL_MASS = 180,
	CARRY_LARGE_MASSLESS = true,
	CARRY_LARGE_NO_COLLISION = true,
	CARRY_XL_MASSLESS = true,
	CARRY_XL_NO_COLLISION = true,

	MIN_SPEED = 0,
	MAX_SPEED = 1000,

	MOVEMENT_MODE = "WalkSpeed", -- "WalkSpeed" ou "Hybrid"

	ACCELERATION = 55,
	DECELERATION = 16,

	MAX_HORIZONTAL_VELOCITY = 1500,
	MAX_DELTA_TIME = 0.10,

	WATCHDOG_INTERVAL = 0.75,
	CARRY_SCAN_INTERVAL = 0.20,

	RECOVERY_WINDOW = 30,
	MAX_RECOVERIES = 6,
	RECOVERY_COOLDOWN = 1,

	LOCK_WALKSPEED = true,
	SAFE_APPLY = true,

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

	GUI_NAME = "SpeedUltra_2026",

	-- Posicao inicial. Depois do arraste, a posicao pode ser lembrada.
	START_SIDE = "Left", -- "Left" / "Right"
	START_Y = 200,
	EDGE_MARGIN = 10,
	REMEMBER_POSITION = true,

	-- Otimizacao leve: reduz cerca de 35% dos efeitos selecionados dos efeitos,
	-- preservando a maior parte do visual do mapa.
	OPTIMIZATION_STRENGTH = 0.35,
	QUALITY_DROP_LEVELS = 1,
	MIN_QUALITY_LEVEL = 5,
	-- Limite de trabalho por fatia para evitar pico de CPU/renderizacao.
	OPTIMIZE_FRAME_BUDGET = 0.0025,
	OPTIMIZE_ONCE = false,
	OPTIMIZE_MAX_SECONDS = 4,

	DEBUG = false,

}

-- =========================================================
-- ESTADO
-- =========================================================

local State = {
	Alive = true,
	Enabled = true,

	TargetSpeed = Config.DEFAULT_SPEED,

	Carrying = false,
	CarriedObject = nil,

	Character = nil,
	Humanoid = nil,
	RootPart = nil,

	OriginalWalkSpeed = nil,

	CharacterGeneration = 0,
	PreparationToken = 0,
	Preparing = false,

	RecoveryWindowStart = os.clock(),
	RecoveryCount = 0,
	LastRecovery = 0,

	CarryScanPending = false,
	LastCarryScan = 0,
	CarryStartedAt = 0,
	LastCarrySpeedApply = 0,
	CarrySpeedAppliedForCycle = false,
	CarrySpeedRecoveryPending = false,

	CarrySizeClass = "NONE",
	CarrySizeMax = 0,
	CarryMass = 0,
	CarryPhysicsContainer = nil,
	CarryPhysicsOriginals = {},
	LastCarryPhysicsScan = 0,

	Dragging = false,
	DragStart = Vector2.zero,
	PanelStart = Vector2.zero,

	Camera = nil,

	Optimizing = false,
	Optimized = false,
	OptimizeToken = 0,
	OptimizationGeneration = 0,
	OptimizationOriginals = {},
	OptimizationOriginalQuality = nil,

	Collapsed = false,
	ApplyingSpeed = false,
	CleaningUp = false
}

local Connections = {
	Global = {},
	Character = {},
	Camera = {},
	Gui = {}
}

local Frame
local ScreenGui
local Status
local SpeedBox
local Toggle
local OptimizeButton
local CollapseButton
local SideButton
local Body
local Title

-- =========================================================
-- DEBUG
-- =========================================================

local function Debug(...)
	if Config.DEBUG then
		warn("[SPEED ULTRA V8.3]", ...)
	end
end

-- =========================================================
-- CONNECTION MANAGER
-- =========================================================

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

local function DisconnectAll()
	DisconnectGroup(Connections.Global)
	DisconnectGroup(Connections.Character)
	DisconnectGroup(Connections.Camera)
	DisconnectGroup(Connections.Gui)
end

local function SetConnection(group, key, connection)
	Disconnect(group[key])
	group[key] = connection
end

-- =========================================================
-- SEGURANCA NUMERICA
-- =========================================================

local function IsFiniteNumber(value)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function IsFiniteVector3(value)
	if typeof(value) ~= "Vector3" then
		return false
	end

	return IsFiniteNumber(value.X)
		and IsFiniteNumber(value.Y)
		and IsFiniteNumber(value.Z)
end

local function NormalizeSpeed(value)
	if not IsFiniteNumber(value) then
		return nil
	end

	return math.clamp(value, Config.MIN_SPEED, Config.MAX_SPEED)
end

local function SafeText(label, value)
	if not State.Alive or not label then
		return
	end

	pcall(function()
		if label.Parent then
			label.Text = tostring(value)
		end
	end)
end

-- =========================================================
-- GUI ANTIGA / LIMPEZA
-- =========================================================

-- Remove qualquer GUI anterior do Speed Ultra, inclusive de versões antigas.
pcall(function()
	for _, child in ipairs(PlayerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			local name = child.Name
			if name == Config.GUI_NAME
				or string.sub(name, 1, 10) == "SpeedUltra"
			then
				child:Destroy()
			end
		end
	end
end)

-- =========================================================
-- GUI
-- =========================================================

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = Config.GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
	ScreenGui.DisplayOrder = 999
end)

ScreenGui.Parent = PlayerGui

Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.Size = UDim2.fromOffset(225, 190)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 9)
FrameCorner.Parent = Frame

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 3)
Accent.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
Accent.BorderSizePixel = 0
Accent.Parent = Frame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.Position = UDim2.fromOffset(0, 3)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Frame

Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -42, 1, 0)
Title.Position = UDim2.fromOffset(8, 0)
Title.BackgroundTransparency = 1
Title.Text = "SPEED ULTRA V8.3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Header

CollapseButton = Instance.new("TextButton")
CollapseButton.Size = UDim2.fromOffset(28, 24)
CollapseButton.Position = UDim2.new(1, -34, 0, 3)
CollapseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CollapseButton.BorderSizePixel = 0
CollapseButton.Text = "—"
CollapseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CollapseButton.Font = Enum.Font.SourceSansBold
CollapseButton.TextSize = 14
CollapseButton.AutoButtonColor = true
CollapseButton.Parent = Header

local CollapseCorner = Instance.new("UICorner")
CollapseCorner.CornerRadius = UDim.new(0, 5)
CollapseCorner.Parent = CollapseButton

Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -10, 1, -38)
Body.Position = UDim2.fromOffset(5, 34)
Body.BackgroundTransparency = 1
Body.Parent = Frame

SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.fromOffset(85, 29)
SpeedBox.Position = UDim2.fromOffset(5, 3)
SpeedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpeedBox.BorderSizePixel = 0
SpeedBox.Text = tostring(State.TargetSpeed)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.Font = Enum.Font.SourceSans
SpeedBox.TextSize = 16
SpeedBox.ClearTextOnFocus = false
SpeedBox.TextEditable = true
SpeedBox.Parent = Body

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 5)
SpeedCorner.Parent = SpeedBox

local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.fromOffset(95, 29)
ApplyButton.Position = UDim2.fromOffset(95, 3)
ApplyButton.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
ApplyButton.BorderSizePixel = 0
ApplyButton.Text = "APLICAR"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.Font = Enum.Font.SourceSansBold
ApplyButton.TextSize = 12
ApplyButton.Parent = Body

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 5)
ApplyCorner.Parent = ApplyButton

Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(85, 27)
Toggle.Position = UDim2.fromOffset(5, 39)
Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Toggle.BorderSizePixel = 0
Toggle.Text = "SISTEMA: ON"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextSize = 11
Toggle.Parent = Body

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 5)
ToggleCorner.Parent = Toggle

Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(130, 27)
Status.Position = UDim2.fromOffset(95, 39)
Status.BackgroundTransparency = 1
Status.Text = "INICIANDO"
Status.TextColor3 = Color3.fromRGB(170, 170, 170)
Status.Font = Enum.Font.SourceSans
Status.TextSize = 10
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextTruncate = Enum.TextTruncate.AtEnd
Status.Parent = Body

OptimizeButton = Instance.new("TextButton")
OptimizeButton.Size = UDim2.fromOffset(120, 27)
OptimizeButton.Position = UDim2.fromOffset(5, 74)
OptimizeButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
OptimizeButton.BorderSizePixel = 0
OptimizeButton.Text = "OTIMIZA"
OptimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OptimizeButton.Font = Enum.Font.SourceSansBold
OptimizeButton.TextSize = 11
OptimizeButton.Parent = Body

local OptimizeCorner = Instance.new("UICorner")
OptimizeCorner.CornerRadius = UDim.new(0, 5)
OptimizeCorner.Parent = OptimizeButton

SideButton = Instance.new("TextButton")
SideButton.Size = UDim2.fromOffset(60, 27)
SideButton.Position = UDim2.fromOffset(130, 74)
SideButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
SideButton.BorderSizePixel = 0
SideButton.Text = "LADO"
SideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SideButton.Font = Enum.Font.SourceSansBold
SideButton.TextSize = 10
SideButton.Parent = Body

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 5)
SideCorner.Parent = SideButton


-- =========================================================
-- STATUS
-- =========================================================

local function SetStatus(text)
	if not State.Alive then
		return
	end

	SafeText(Status, text)
end

local function RefreshStatus()
	if not State.Alive then
		return
	end


	if State.Optimizing then
		SetStatus("OTIMIZANDO...")
		return
	end

	if State.Optimized then
		if State.Carrying then
			SetStatus("OTIMIZADO 35% • CARRY")
		else
			SetStatus("OTIMIZADO 35% • ON")
		end
		return
	end

	if not State.Enabled then
		SetStatus("DESATIVADO")
		return
	end

	if State.Carrying then
		local carryClass = State.CarrySizeClass
		if carryClass == "LARGE" or carryClass == "XL" then
			SetStatus("CARRY " .. carryClass .. " • " .. tostring(Config.CARRY_SPEED))
		else
			SetStatus("CARRY • " .. tostring(Config.CARRY_SPEED))
		end
		return
	end

	if not State.Character then
		SetStatus("AGUARDANDO")
		return
	end

	if not State.Humanoid then
		SetStatus("CARREGANDO")
		return
	end

	SetStatus("ATIVO • " .. tostring(State.TargetSpeed))
end

-- =========================================================
-- RECOVERY
-- =========================================================

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

-- =========================================================
-- CHARACTER VALIDATION
-- =========================================================

local function ValidCharacter(character, generation, token)
	return State.Alive
		and Player.Character == character
		and State.Character == character
		and State.CharacterGeneration == generation
		and State.PreparationToken == token
end

-- =========================================================
-- CARRY ATTRIBUTES
-- =========================================================

local function CheckCarryAttributes(object)
	if not Config.DETECT_ATTRIBUTES or not object then
		return false
	end

	for _, attributeName in ipairs(Config.CARRY_ATTRIBUTES) do
		local value = nil

		local ok = pcall(function()
			value = object:GetAttribute(attributeName)
		end)

		if ok then
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
	end

	return false
end

-- =========================================================
-- CARRY TAGS
-- =========================================================

local function CheckCarryTags(object)
	if not Config.DETECT_TAGS or not object then
		return false
	end

	for _, tagName in ipairs(Config.CARRY_TAGS) do
		local found = false

		pcall(function()
			found = CollectionService:HasTag(object, tagName)
		end)

		if found then
			return true
		end
	end

	return false
end

-- =========================================================
-- CARRY TOOL
-- =========================================================

local function CheckCarryTool(character)
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

-- =========================================================
-- CARRY CONSTRAINT
-- =========================================================

local function CheckCarryConstraint(character)
	if not Config.DETECT_CONSTRAINTS then
		return false, nil
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("WeldConstraint")
			or object:IsA("Weld")
			or object:IsA("Motor6D") then

			local p0 = nil
			local p1 = nil

			pcall(function()
				p0 = object.Part0
				p1 = object.Part1
			end)

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
	end

	return false, nil
end

-- =========================================================
-- CARRY DETECTOR
-- =========================================================

local function DetectCarry()
	local character = State.Character

	if not character or not character.Parent then
		return false, nil
	end

	if CheckCarryAttributes(character) then
		return true, character
	end

	if CheckCarryTags(character) then
		return true, character
	end

	local toolFound, tool = CheckCarryTool(character)

	if toolFound then
		return true, tool
	end

	for _, object in ipairs(character:GetDescendants()) do
		if CheckCarryAttributes(object) then
			return true, object
		end

		if CheckCarryTags(object) then
			return true, object
		end
	end

	local found, external = CheckCarryConstraint(character)

	if found then
		return true, external
	end

	return false, nil
end

-- =========================================================
-- CARRY PHYSICS / TAMANHO ADAPTATIVO
-- =========================================================

local function IsExternalCarryObject(object)
	if not object or not State.Character then
		return false
	end

	local ok, external = pcall(function()
		return object ~= State.Character
			and not object:IsDescendantOf(State.Character)
	end)

	return ok and external
end

local function ResolveCarryContainer(object)
	if not IsExternalCarryObject(object) then
		return nil
	end

	if object:IsA("Model") or object:IsA("Tool") then
		return object
	end

	if object:IsA("BasePart") then
		local model = nil
		pcall(function()
			model = object:FindFirstAncestorOfClass("Model")
		end)

		if model and IsExternalCarryObject(model) then
			return model
		end

		return object
	end

	local model = nil
	pcall(function()
		model = object:FindFirstAncestorOfClass("Model")
	end)

	if model and IsExternalCarryObject(model) then
		return model
	end

	return object
end

local function CollectCarryParts(container)
	local parts = {}

	if not container then
		return parts
	end

	if container:IsA("BasePart") then
		local connected = nil

		pcall(function()
			connected = container:GetConnectedParts(true)
		end)

		if type(connected) == "table" then
			for _, part in ipairs(connected) do
				if part
					and part:IsA("BasePart")
					and not (State.Character and part:IsDescendantOf(State.Character))
				then
					parts[#parts + 1] = part
				end
			end
		end

		if #parts == 0 then
			parts[1] = container
		end

		return parts
	end

	local ok, descendants = pcall(function()
		return container:GetDescendants()
	end)

	if ok and descendants then
		for _, object in ipairs(descendants) do
			if object:IsA("BasePart")
				and not (State.Character and object:IsDescendantOf(State.Character))
			then
				parts[#parts + 1] = object
			end
		end
	end

	return parts
end

local function MeasureCarryObject(container)
	if not container then
		return 0, 0, "NONE"
	end

	local parts = CollectCarryParts(container)
	local maxSize = 0
	local mass = 0

	local okName, lowerName = pcall(function()
		return string.lower(container.Name or "")
	end)

	if not okName then
		lowerName = ""
	end

	for _, part in ipairs(parts) do
		pcall(function()
			local size = part.Size
			if typeof(size) == "Vector3" then
				maxSize = math.max(maxSize, size.X, size.Y, size.Z)
			end
		end)

		pcall(function()
			if not part.Anchored then
				local partMass = part:GetMass()
				if IsFiniteNumber(partMass) and partMass > 0 then
					mass += partMass
				end
			end
		end)
	end

	-- Para Models, o bounding box e mais representativo do tamanho total.
	if container:IsA("Model") then
		pcall(function()
			local _, boxSize = container:GetBoundingBox()
			if typeof(boxSize) == "Vector3" then
				maxSize = math.max(maxSize, boxSize.X, boxSize.Y, boxSize.Z)
			end
		end)
	end

	local namedLarge = lowerName:find("large", 1, true)
		or lowerName:find("giant", 1, true)
		or lowerName:find("huge", 1, true)
		or lowerName:find("mega", 1, true)
		or lowerName:find("big", 1, true)
		or lowerName:find("grande", 1, true)
		or lowerName:find("gigante", 1, true)

	local class

	if maxSize >= Config.CARRY_XL_SIZE
		or mass >= Config.CARRY_XL_MASS
	then
		class = "XL"
	elseif maxSize >= Config.CARRY_LARGE_SIZE
		or mass >= Config.CARRY_LARGE_MASS
		or namedLarge
	then
		class = "LARGE"
	elseif maxSize >= Config.CARRY_MEDIUM_SIZE
		or mass >= Config.CARRY_MEDIUM_MASS
	then
		class = "MEDIUM"
	else
		class = "SMALL"
	end

	return maxSize, mass, class
end

local function ClearCarryPhysics()
	for part, original in pairs(State.CarryPhysicsOriginals) do
		if part and part.Parent and type(original) == "table" then
			if original.Massless ~= nil then
				pcall(function()
					part.Massless = original.Massless
				end)
			end

			if original.CanCollide ~= nil then
				pcall(function()
					part.CanCollide = original.CanCollide
				end)
			end
		end
	end

	State.CarryPhysicsOriginals = {}
	State.CarryPhysicsContainer = nil
	State.CarrySizeClass = "NONE"
	State.CarrySizeMax = 0
	State.CarryMass = 0
	State.LastCarryPhysicsScan = 0
end

local function ApplyCarryPartPhysics(part, class)
	if not part
		or not part:IsA("BasePart")
		or not part.Parent
		or part.Anchored
	or (State.Character and part:IsDescendantOf(State.Character))
	then
		return
	end

	if not State.CarryPhysicsOriginals[part] then
		State.CarryPhysicsOriginals[part] = {
			Massless = part.Massless,
			CanCollide = part.CanCollide
		}
	end

	if (class == "LARGE" and Config.CARRY_LARGE_MASSLESS)
		or (class == "XL" and Config.CARRY_XL_MASSLESS)
	then
		pcall(function()
			part.Massless = true
		end)
	end

	if (class == "LARGE" and Config.CARRY_LARGE_NO_COLLISION)
		or (class == "XL" and Config.CARRY_XL_NO_COLLISION)
	then
		pcall(function()
			part.CanCollide = false
		end)
	end
end

local function ApplyCarryPhysics(object, force)
	if not Config.CARRY_ADAPTIVE_PHYSICS or not object then
		return
	end

	local container = ResolveCarryContainer(object)

	if not container then
		ClearCarryPhysics()
		return
	end

	local now = os.clock()

	if not force
		and container == State.CarryPhysicsContainer
		and now - State.LastCarryPhysicsScan < Config.CARRY_PHYSICS_SCAN_INTERVAL
	then
		return
	end

	if container ~= State.CarryPhysicsContainer then
		ClearCarryPhysics()
		State.CarryPhysicsContainer = container
	end

	State.LastCarryPhysicsScan = now

	local maxSize, mass, class = MeasureCarryObject(container)
	State.CarrySizeMax = maxSize
	State.CarryMass = mass
	State.CarrySizeClass = class

	if class ~= "LARGE" and class ~= "XL" then
		return
	end

	local parts = CollectCarryParts(container)
	for _, part in ipairs(parts) do
		ApplyCarryPartPhysics(part, class)
	end
end

local function GetCarryGrace()
	if State.CarrySizeClass == "XL" then
		return math.max(Config.CARRY_HANDOFF_GRACE, 0.90)
	elseif State.CarrySizeClass == "LARGE" then
		return math.max(Config.CARRY_HANDOFF_GRACE, 0.65)
	elseif State.CarrySizeClass == "MEDIUM" then
		return math.max(Config.CARRY_HANDOFF_GRACE, 0.45)
	end

	return Config.CARRY_HANDOFF_GRACE
end

-- =========================================================
-- SPEED
-- =========================================================

local function GetDesiredSpeed()
	if State.Carrying then
		return NormalizeSpeed(Config.CARRY_SPEED) or State.TargetSpeed
	end

	return NormalizeSpeed(State.TargetSpeed) or Config.DEFAULT_SPEED
end

local function ApplySpeed(force)
	if not State.Alive
		or not State.Enabled
		or not Config.LOCK_WALKSPEED
		or State.ApplyingSpeed
	then
		return false
	end

	local humanoid = State.Humanoid

	if not humanoid
		or not humanoid.Parent
		or humanoid.Health <= 0
	then
		return false
	end

	local now = os.clock()
	local desired = GetDesiredSpeed()

	if not IsFiniteNumber(desired) then
		return false
	end

	if State.Carrying then
		-- Pequena janela somente na entrada do carry. Depois dela, a velocidade
		-- volta a ser mantida em 255 de forma controlada, em vez de ser
		-- abandonada pelo resto do ciclo.
		local sinceCarry = now - State.CarryStartedAt
		if sinceCarry >= 0 and sinceCarry < GetCarryGrace() then
			return true
		end

		if not force and now - State.LastCarrySpeedApply < Config.CARRY_REAPPLY_INTERVAL then
			return true
		end
	end

	local current = humanoid.WalkSpeed
	if IsFiniteNumber(current)
		and math.abs(current - desired) <= Config.CARRY_SPEED_TOLERANCE
	then
		if State.Carrying then
			State.LastCarrySpeedApply = now
			State.CarrySpeedAppliedForCycle = true
		end
		return true
	end

	State.ApplyingSpeed = true

	local success = pcall(function()
		humanoid.WalkSpeed = desired
	end)

	State.ApplyingSpeed = false

	if success and State.Carrying then
		State.LastCarrySpeedApply = now
		State.CarrySpeedAppliedForCycle = true
	end

	return success
end

-- =========================================================
-- CARRY UPDATE / DEBOUNCE
-- =========================================================

local function UpdateCarryState(force)
	if not State.Alive or not State.Character then
		return
	end

	local now = os.clock()

	if not force
		and now - State.LastCarryScan < Config.CARRY_SCAN_INTERVAL
	then
		-- Mesmo sem nova detecção, atualize apenas a parte física adaptativa
		-- no intervalo próprio, sem tocar na velocidade.
		if State.Carrying and State.CarriedObject then
			ApplyCarryPhysics(State.CarriedObject, false)
		end
		return
	end

	State.LastCarryScan = now

	local carrying, object = false, nil

	local ok = pcall(function()
		carrying, object = DetectCarry()
	end)

	if not ok then
		return
	end

	local wasCarrying = State.Carrying
	local oldObject = State.CarriedObject

	State.Carrying = carrying
	State.CarriedObject = object

	if carrying and (not wasCarrying or object ~= oldObject) then
		State.CarryStartedAt = now
		State.CarrySpeedRecoveryPending = false
		State.LastCarrySpeedApply = 0
		State.CarrySpeedAppliedForCycle = false

		ApplyCarryPhysics(object, true)

		-- Se a velocidade ja era 255 no instante do encaixe, considere-a
		-- aplicada e nao force outra escrita depois. Isso e especialmente
		-- importante para ovos grandes, onde a escrita tardia pode coincidir
		-- com a estabilizacao da montagem fisica.
		local humanoid = State.Humanoid
		local desired = GetDesiredSpeed()

		if humanoid
			and humanoid.Parent
			and IsFiniteNumber(desired)
			and math.abs(humanoid.WalkSpeed - desired) < 0.01
		then
			State.CarrySpeedAppliedForCycle = true
			State.LastCarrySpeedApply = now
		end

	elseif carrying then
		ApplyCarryPhysics(object, false)

	elseif not carrying then
		if wasCarrying then
			ClearCarryPhysics()
		end

		State.CarryStartedAt = 0
		State.LastCarrySpeedApply = 0
		State.CarrySpeedAppliedForCycle = false
		State.CarrySpeedRecoveryPending = false
	end

	ApplySpeed(false)
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
			UpdateCarryState(false)
		end
	end)
end

-- =========================================================
-- PREPARE CHARACTER
-- =========================================================

local function PrepareCharacter(character, isRecovery)
	if not State.Alive
		or not character
		or not character.Parent
		or State.Preparing
	then
		return
	end

	if isRecovery then
		if not CanRecover() then
			SetStatus("RECUPERACAO LIMITADA")
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

	State.Character = character
	State.Humanoid = nil
	State.RootPart = nil
	State.Carrying = false
	State.CarriedObject = nil
	State.OriginalWalkSpeed = nil
	State.CarryScanPending = false
	State.LastCarryScan = 0
	State.CarryStartedAt = 0
	State.LastCarrySpeedApply = 0
	State.CarrySpeedAppliedForCycle = false
	State.CarrySpeedRecoveryPending = false
	ClearCarryPhysics()

	SetStatus("CARREGANDO...")

	local humanoid = nil

	pcall(function()
		humanoid = character:WaitForChild("Humanoid", 15)
	end)

	if not ValidCharacter(character, generation, token) then
		State.Preparing = false
		return
	end

	if not humanoid then
		State.Preparing = false
		SetStatus("ERRO HUMANOID")
		return
	end

	local originalSpeed = humanoid.WalkSpeed

	if IsFiniteNumber(originalSpeed) then
		State.OriginalWalkSpeed = originalSpeed
	end

	local root = nil

	pcall(function()
		root = character:WaitForChild("HumanoidRootPart", 15)
	end)

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
			if not State.Alive
				or not State.Enabled
				or not Config.LOCK_WALKSPEED
				or State.ApplyingSpeed
			then
				return
			end

			if not ValidCharacter(character, generation, token) then
				return
			end

			if humanoid.Health <= 0 then
				return
			end

			-- Nao reescreva imediatamente. Agende uma recuperacao pequena
			-- para devolver 255 sem entrar em loop de propriedades.
			if State.Carrying then
				if State.CarrySpeedRecoveryPending then
					return
				end

				State.CarrySpeedRecoveryPending = true
				task.delay(Config.CARRY_SPEED_RECOVERY_DELAY, function()
					State.CarrySpeedRecoveryPending = false

					if not State.Alive
						or not State.Carrying
						or State.Humanoid ~= humanoid
						or not humanoid.Parent
					then
						return
					end

					ApplySpeed(true)
				end)
				return
			end

			ApplySpeed(false)
		end)
	)

	SetConnection(
		Connections.Character,
		"Died",
		humanoid.Died:Connect(function()
			State.Carrying = false
			State.CarriedObject = nil
			State.CarryStartedAt = 0
			State.LastCarrySpeedApply = 0
			State.CarrySpeedAppliedForCycle = false
			State.CarrySpeedRecoveryPending = false
			ClearCarryPhysics()
			SetStatus("MORTO • AGUARDANDO")
		end)
	)

	UpdateCarryState(true)
	ApplySpeed()

	State.Preparing = false
	RefreshStatus()

	Debug("Personagem preparado.")
end

-- =========================================================
-- VELOCIDADE
-- =========================================================

local function SetTargetSpeed()
	if not State.Alive or not SpeedBox then
		return
	end

	local text = ""

	pcall(function()
		text = string.gsub(SpeedBox.Text, "%s+", "")
	end)

	if text == "" then
		SpeedBox.Text = tostring(State.TargetSpeed)
		RefreshStatus()
		return
	end

	local value = tonumber(text)
	local speed = NormalizeSpeed(value)

	if not speed then
		SpeedBox.Text = tostring(State.TargetSpeed)
		SetStatus("VALOR INVALIDO")

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

SetConnection(Connections.Gui, "Apply", ApplyButton.Activated:Connect(SetTargetSpeed))
SetConnection(Connections.Gui, "SpeedFocus", SpeedBox.FocusLost:Connect(SetTargetSpeed))

-- =========================================================
-- TOGGLE
-- =========================================================

SetConnection(Connections.Gui, "Toggle", Toggle.Activated:Connect(function()
	if not State.Alive then
		return
	end

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
			and IsFiniteNumber(original)
		then
			pcall(function()
				humanoid.WalkSpeed = original
			end)
		end
	end

	RefreshStatus()
end))

-- =========================================================
-- POSICAO / LADO
-- =========================================================

local POSITION_KEY = "__SPEED_ULTRA_V81_POSITION"

local function GetPanelLimits()
	local camera = workspace.CurrentCamera

	if not camera or not Frame then
		return nil
	end

	local viewport
	local ok = pcall(function()
		viewport = camera.ViewportSize
	end)

	if not ok or typeof(viewport) ~= "Vector2" then
		return nil
	end

	local frameSize = Frame.AbsoluteSize
	local maxX = math.max(0, viewport.X - frameSize.X)
	local maxY = math.max(0, viewport.Y - frameSize.Y)

	return maxX, maxY
end

local function ClampPanelPosition(x, y)
	local maxX, maxY = GetPanelLimits()

	if not maxX or not maxY then
		return x, y
	end

	return math.clamp(x, 0, maxX), math.clamp(y, 0, maxY)
end

local function UpdateSideButton()
	if not SideButton then
		return
	end

	local x = Frame.AbsolutePosition.X
	local maxX = select(1, GetPanelLimits()) or 0

	if x >= maxX * 0.5 then
		SideButton.Text = "LADO: DIR"
	else
		SideButton.Text = "LADO: ESQ"
	end
end

local function SetPanelSide(side)
	local maxX, maxY = GetPanelLimits()

	if not maxX or not maxY then
		return
	end

	local targetX

	if side == "Right" then
		targetX = math.max(0, maxX - Config.EDGE_MARGIN)
	else
		targetX = Config.EDGE_MARGIN
	end

	local currentY = Frame.AbsolutePosition.Y
	local targetY = math.clamp(currentY, 0, maxY)

	Frame.Position = UDim2.fromOffset(targetX, targetY)
	UpdateSideButton()

	if Config.REMEMBER_POSITION then
		Env[POSITION_KEY] = {
			x = targetX,
			y = targetY
		}
	end
end

local function ApplySavedOrDefaultPosition()
	local maxX, maxY = GetPanelLimits()

	if not maxX or not maxY then
		return
	end

	local x
	local y

	if Config.REMEMBER_POSITION
		and type(Env[POSITION_KEY]) == "table"
		and IsFiniteNumber(Env[POSITION_KEY].x)
		and IsFiniteNumber(Env[POSITION_KEY].y)
	then
		x = Env[POSITION_KEY].x
		y = Env[POSITION_KEY].y
	else
		x = Config.EDGE_MARGIN
		y = Config.START_Y

		if Config.START_SIDE == "Right" then
			x = maxX - Config.EDGE_MARGIN
		end
	end

	x, y = ClampPanelPosition(x, y)
	Frame.Position = UDim2.fromOffset(x, y)
	UpdateSideButton()
end

SetConnection(Connections.Gui, "Side", SideButton.Activated:Connect(function()
	if not State.Alive then
		return
	end

	local maxX = select(1, GetPanelLimits()) or 0
	local currentX = Frame.AbsolutePosition.X

	if currentX < maxX * 0.5 then
		SetPanelSide("Right")
	else
		SetPanelSide("Left")
	end
end))

-- =========================================================
-- RECOLHER / ABRIR
-- =========================================================

local ExpandedSize = UDim2.fromOffset(225, 190)
local CollapsedSize = UDim2.fromOffset(150, 35)

local function SetCollapsed(collapsed)
	if not State.Alive then
		return
	end

	State.Collapsed = collapsed
	Body.Visible = not collapsed

	if collapsed then
		Frame.Size = CollapsedSize
		CollapseButton.Text = "+"
		Title.Text = "SPEED ULTRA V8.3"
	else
		Frame.Size = ExpandedSize
		CollapseButton.Text = "—"
		Title.Text = "SPEED ULTRA V8.3"
	end

	local x = Frame.AbsolutePosition.X
	local y = Frame.AbsolutePosition.Y
	x, y = ClampPanelPosition(x, y)
	Frame.Position = UDim2.fromOffset(x, y)
	UpdateSideButton()
end

SetConnection(Connections.Gui, "Collapse", CollapseButton.Activated:Connect(function()
	SetCollapsed(not State.Collapsed)
end))

-- =========================================================
-- OTIMIZACAO
-- =========================================================

local function SaveOriginal(object, property, value)
	if not object then
		return
	end

	local record = State.OptimizationOriginals[object]
	if not record then
		record = {}
		State.OptimizationOriginals[object] = record
	end

	if record[property] == nil then
		record[property] = value
	end
end

local function RestoreOptimizedObjects()
	State.OptimizeToken += 1
	State.OptimizationGeneration += 1

	for object, properties in pairs(State.OptimizationOriginals) do
		if object and object.Parent then
			for property, value in pairs(properties) do
				pcall(function()
					object[property] = value
				end)
			end
		end
	end

	State.OptimizationOriginals = {}

	if State.OptimizationOriginalQuality ~= nil then
		pcall(function()
			local settings = UserSettings():GetService("UserGameSettings")
			settings.SavedQualityLevel = State.OptimizationOriginalQuality
		end)
	end

	State.OptimizationOriginalQuality = nil
	State.Optimizing = false
	State.Optimized = false
	State.OptimizationGeneration += 1

	if OptimizeButton and OptimizeButton.Parent then
		OptimizeButton.Text = "OTIMIZA 35%"
	end

	RefreshStatus()
end

local function OptimizeGraphics()
	if not State.Alive then
		return
	end

	-- Segundo toque: desfaz a otimização anterior.
	if State.Optimized and not State.Optimizing then
		if OptimizeButton then
			OptimizeButton.Text = "RESTAURANDO..."
		end
		SetStatus("RESTAURANDO...")

		task.spawn(function()
			RestoreOptimizedObjects()
		end)
		return
	end

	if State.Optimizing then
		return
	end

	State.Optimizing = true
	State.Optimized = false
	State.OptimizeToken += 1
	State.OptimizationGeneration += 1

	local optimizeToken = State.OptimizeToken
	local generation = State.OptimizationGeneration
	local reduction = math.clamp(Config.OPTIMIZATION_STRENGTH, 0, 0.75)
	local keepFactor = 1 - reduction

	if OptimizeButton then
		OptimizeButton.Text = "OTIMIZANDO..."
	end
	SetStatus("OTIMIZANDO 35%...")

	-- Guarda a qualidade original apenas uma vez por ciclo.
	pcall(function()
		local settings = UserSettings():GetService("UserGameSettings")
		if State.OptimizationOriginalQuality == nil then
			State.OptimizationOriginalQuality = settings.SavedQualityLevel
		end

		local saved = settings.SavedQualityLevel
		local currentLevel = tonumber(tostring(saved):match("(%d+)$"))

		if currentLevel and currentLevel >= Config.MIN_QUALITY_LEVEL then
			local target = math.max(
				Config.MIN_QUALITY_LEVEL,
				currentLevel - math.max(0, math.floor(Config.QUALITY_DROP_LEVELS))
			)

			if target < currentLevel then
				local targetEnum = Enum.SavedQualitySetting["QualityLevel" .. tostring(target)]
				if targetEnum then
					settings.SavedQualityLevel = targetEnum
				end
			end
		end
	end)

	-- Remove somente os dois pós-efeitos mais caros para este modo leve.
	pcall(function()
		for _, effect in ipairs(Lighting:GetChildren()) do
			if not State.Alive or State.OptimizeToken ~= optimizeToken then
				return
			end

			if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") then
				SaveOriginal(effect, "Enabled", effect.Enabled)
				pcall(function()
					effect.Enabled = false
				end)
			end
		end
	end)

	-- Caminhada incremental. O limite de tempo evita ficar preso em mapas enormes.
	task.spawn(function()
		local stack = {workspace}
		local changed = 0
		local visited = 0
		local sliceStart = os.clock()
		local wholeStart = sliceStart
		local budget = math.clamp(
			tonumber(Config.OPTIMIZE_FRAME_BUDGET) or 0.0025,
			0.0005,
			0.006
		)
		local maxSeconds = math.max(2, tonumber(Config.OPTIMIZE_MAX_SECONDS) or 8)
		local partial = false

		local function ProcessObject(object)
			if not object then
				return
			end

			visited += 1

			pcall(function()
				if object:IsA("ParticleEmitter") then
					local rate = object.Rate
					if IsFiniteNumber(rate) and rate > 0 then
						SaveOriginal(object, "Rate", rate)
						object.Rate = math.max(0, rate * keepFactor)
						changed += 1
					end

				elseif object:IsA("Trail") then
					local lifetime = object.Lifetime
					if IsFiniteNumber(lifetime) and lifetime > 0 then
						SaveOriginal(object, "Lifetime", lifetime)
						object.Lifetime = math.max(0.05, lifetime * keepFactor)
						changed += 1
					end

				elseif object:IsA("Smoke") then
					local opacity = object.Opacity
					local size = object.Size
					if IsFiniteNumber(opacity) then
						SaveOriginal(object, "Opacity", opacity)
						object.Opacity = math.clamp(opacity * keepFactor, 0, 1)
					end
					if IsFiniteNumber(size) then
						SaveOriginal(object, "Size", size)
						object.Size = math.max(0.1, size * (1 - reduction * 0.5))
					end
					changed += 1

				elseif object:IsA("Fire") then
					local size = object.Size
					local heat = object.Heat
					if IsFiniteNumber(size) then
						SaveOriginal(object, "Size", size)
						object.Size = math.max(0.1, size * (1 - reduction * 0.5))
					end
					if IsFiniteNumber(heat) then
						SaveOriginal(object, "Heat", heat)
						object.Heat = heat * keepFactor
					end
					changed += 1
				end
			end)
		end

		while #stack > 0 do
			if not State.Alive or State.OptimizeToken ~= optimizeToken or State.OptimizationGeneration ~= generation then
				return
			end

			if os.clock() - wholeStart >= maxSeconds then
				partial = true
				break
			end

			local parent = stack[#stack]
			stack[#stack] = nil

			local children
			local ok = pcall(function()
				children = parent:GetChildren()
			end)

			if ok and children then
				for _, object in ipairs(children) do
					if not State.Alive or State.OptimizeToken ~= optimizeToken or State.OptimizationGeneration ~= generation then
						return
					end

					ProcessObject(object)
					stack[#stack + 1] = object

					if os.clock() - sliceStart >= budget then
						sliceStart = os.clock()
						RunService.Heartbeat:Wait()
					end

					if os.clock() - wholeStart >= maxSeconds then
						partial = true
						break
					end
				end
			end
		end

		if not State.Alive or State.OptimizeToken ~= optimizeToken or State.OptimizationGeneration ~= generation then
			return
		end

		State.Optimizing = false
		State.Optimized = true

		if OptimizeButton then
			OptimizeButton.Text = "OTIMIZADO 35%"
		end

		if partial then
			SetStatus("OTIMIZADO 35% • PARCIAL")
		else
			SetStatus("OTIMIZADO 35% • " .. tostring(changed) .. " EFEITOS")
		end

		task.delay(1.5, function()
			if State.Alive and State.Optimized and not State.Optimizing then
				RefreshStatus()
			end
		end)
	end)
end

SetConnection(Connections.Gui, "Optimize", OptimizeButton.Activated:Connect(OptimizeGraphics))

-- =========================================================
-- HYBRID
-- =========================================================

if Config.MOVEMENT_MODE == "Hybrid" then
	SetConnection(
		Connections.Global,
		"PreSimulation",
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
				or root.Anchored
			then
				return
			end

			if not IsFiniteNumber(deltaTime) then
				return
			end

			local velocity = root.AssemblyLinearVelocity

			if not IsFiniteVector3(velocity) then
				return
			end

			local moveVelocity = nil
			local gotMoveVelocity = pcall(function()
				moveVelocity = humanoid:GetMoveVelocity()
			end)

			if not gotMoveVelocity or not IsFiniteVector3(moveVelocity) then
				return
			end

			local dt = math.clamp(deltaTime, 0, Config.MAX_DELTA_TIME)
			local alpha = 1 - math.exp(-Config.ACCELERATION * dt)

			local newX = velocity.X + (moveVelocity.X - velocity.X) * alpha
			local newZ = velocity.Z + (moveVelocity.Z - velocity.Z) * alpha

			if not IsFiniteNumber(newX) or not IsFiniteNumber(newZ) then
				return
			end

			local horizontal = math.sqrt(newX * newX + newZ * newZ)

			if not IsFiniteNumber(horizontal) then
				return
			end

			if horizontal > Config.MAX_HORIZONTAL_VELOCITY then
				local ratio = Config.MAX_HORIZONTAL_VELOCITY / horizontal
				newX *= ratio
				newZ *= ratio
			end

			if math.abs(newX - velocity.X) > 0.05
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
	)
end

-- =========================================================
-- DRAG
-- =========================================================

local function BeginDrag(input)
	if not State.Alive then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseButton1
	then
		return
	end

	State.Dragging = true
	State.DragStart = Vector2.new(input.Position.X, input.Position.Y)
	State.PanelStart = Vector2.new(Frame.AbsolutePosition.X, Frame.AbsolutePosition.Y)
end

local function UpdateDrag(input)
	if not State.Alive or not State.Dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseMovement
	then
		return
	end

	local current = Vector2.new(input.Position.X, input.Position.Y)
	local delta = current - State.DragStart

	local x = State.PanelStart.X + delta.X
	local y = State.PanelStart.Y + delta.Y

	x, y = ClampPanelPosition(x, y)

	Frame.Position = UDim2.fromOffset(x, y)
	UpdateSideButton()

	if Config.REMEMBER_POSITION then
		Env[POSITION_KEY] = {x = x, y = y}
	end
end

local function EndDrag(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then
		State.Dragging = false
	end
end

SetConnection(Connections.Gui, "TitleDragStart", Header.InputBegan:Connect(BeginDrag))
SetConnection(Connections.Gui, "TitleDragStart2", Title.InputBegan:Connect(BeginDrag))
SetConnection(Connections.Global, "InputChanged", UserInputService.InputChanged:Connect(UpdateDrag))
SetConnection(Connections.Global, "InputEnded", UserInputService.InputEnded:Connect(EndDrag))

-- =========================================================
-- CAMERA
-- =========================================================

local function BindCamera()
	DisconnectGroup(Connections.Camera)

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	State.Camera = camera

	SetConnection(
		Connections.Camera,
		"Viewport",
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if not State.Alive then
				return
			end

			local x = Frame.AbsolutePosition.X
			local y = Frame.AbsolutePosition.Y
			x, y = ClampPanelPosition(x, y)
			Frame.Position = UDim2.fromOffset(x, y)
			UpdateSideButton()

			if Config.REMEMBER_POSITION then
				Env[POSITION_KEY] = {x = x, y = y}
			end
		end)
	)
end

BindCamera()

SetConnection(
	Connections.Global,
	"CameraChanged",
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCamera)
)

-- =========================================================
-- CHARACTER EVENTS
-- =========================================================

SetConnection(
	Connections.Global,
	"CharacterAdded",
	Player.CharacterAdded:Connect(function(character)
		if not State.Alive then
			return
		end

		task.defer(function()
			if State.Alive and character == Player.Character then
				PrepareCharacter(character, false)
			end
		end)
	end)
)

SetConnection(
	Connections.Global,
	"CharacterRemoving",
	Player.CharacterRemoving:Connect(function(character)
		if character ~= State.Character then
			return
		end

		local humanoid = State.Humanoid
		local original = State.OriginalWalkSpeed

		if humanoid
			and humanoid.Parent
			and IsFiniteNumber(original)
		then
			pcall(function()
				humanoid.WalkSpeed = original
			end)
		end

		State.CharacterGeneration += 1
		State.PreparationToken += 1

		DisconnectGroup(Connections.Character)
		ClearCarryPhysics()

		State.Character = nil
		State.Humanoid = nil
		State.RootPart = nil
		State.Carrying = false
		State.CarriedObject = nil
		State.CarryStartedAt = 0
		State.LastCarrySpeedApply = 0
		State.CarrySpeedAppliedForCycle = false
		State.OriginalWalkSpeed = nil
		State.Preparing = false
		State.CarryScanPending = false
		State.LastCarryScan = 0

		SetStatus("PERSONAGEM REMOVIDO")
	end)
)

-- =========================================================
-- WATCHDOG
-- =========================================================

task.spawn(function()
	while State.Alive do
		task.wait(Config.WATCHDOG_INTERVAL)

		if not State.Alive then
			break
		end

		local character = Player.Character

		if not character then
			RefreshStatus()
		elseif character ~= State.Character then
			if not State.Preparing then
				PrepareCharacter(character, false)
			end
		elseif not State.Humanoid or not State.Humanoid.Parent then
			if not State.Preparing then
				PrepareCharacter(character, true)
			end
		elseif not State.RootPart or not State.RootPart.Parent then
			if not State.Preparing then
				PrepareCharacter(character, true)
			end
		else
			UpdateCarryState(false)
			ApplySpeed(false)
		end
	end
end)

-- =========================================================
-- LIMPEZA / AUTODESTRUICAO
-- =========================================================

local function Cleanup(reason)
	if State.CleaningUp then
		return
	end

	State.CleaningUp = true
	State.Alive = false
	State.OptimizeToken += 1
	State.Dragging = false

	local humanoid = State.Humanoid
	local original = State.OriginalWalkSpeed

	if humanoid
		and humanoid.Parent
		and IsFiniteNumber(original)
	then
		pcall(function()
			humanoid.WalkSpeed = original
		end)
	end

	ClearCarryPhysics()
	DisconnectAll()


	if ScreenGui then
		pcall(function()
			ScreenGui:Destroy()
		end)
	end

	if Env[REGISTRY_KEY] == Cleanup then
		Env[REGISTRY_KEY] = nil
	end

	Debug("Cleanup:", reason or "UNKNOWN")
end

Env[REGISTRY_KEY] = Cleanup

SetConnection(
	Connections.Gui,
	"GuiDestroying",
	ScreenGui.Destroying:Connect(function()
		if not State.CleaningUp then
			Cleanup("GUI_DESTROYED")
		end
	end)
)

-- =========================================================
-- INICIALIZACAO
-- =========================================================

ApplySavedOrDefaultPosition()

if Player.Character then
	PrepareCharacter(Player.Character, false)
else
	SetStatus("AGUARDANDO")
end

RefreshStatus()

Debug("Speed Ultra V8.3 iniciado.")

-- =========================================================
-- FIM
-- =========================================================
