--// =========================================================
--// SPEED ULTRA V7.1
--// CARRY ENGINE • CORREÇÃO COMPLETA
--//
--// OBJETIVO:
--// • velocidade configurável
--// • suporte a estado de carregamento
--// • detector de Carry genérico
--// • suporte a celular
--// • recuperação de respawn
--// • proteção contra conexões duplicadas
--// • modo WalkSpeed leve
--// • modo Hybrid opcional
--//
--// PROJETO DE TESTE
--// NÃO IMPLEMENTA BYPASS / ANTI-CHEAT
--// =========================================================


--// =========================================================
--// BOOT
--// =========================================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.15)


--// =========================================================
--// SERVIÇOS
--// =========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")


--// =========================================================
--// CLIENT
--// =========================================================

if not RunService:IsClient() then
	return
end

local Player = Players.LocalPlayer

if not Player then
	return
end

local PlayerGui =
	Player:WaitForChild(
		"PlayerGui",
		30
	)

if not PlayerGui then
	return
end


--// =========================================================
--// CONFIGURAÇÃO
--// =========================================================

local Config = {

	--// ---------------------------------------------
	--// VELOCIDADE
	--// ---------------------------------------------

	DEFAULT_SPEED = 255,
	CARRY_SPEED = 255,

	MIN_SPEED = 0,
	MAX_SPEED = 1000,


	--// ---------------------------------------------
	--// MOVIMENTO
	--// ---------------------------------------------
	--
	-- WalkSpeed = caminho mais leve
	-- Hybrid    = WalkSpeed + assistência física
	--

	MOVEMENT_MODE = "WalkSpeed",


	--// ---------------------------------------------
	--// FÍSICA HYBRID
	--// ---------------------------------------------

	ACCELERATION = 55,
	DECELERATION = 16,

	MAX_HORIZONTAL_VELOCITY = 1500,
	MAX_DELTA_TIME = 0.10,


	--// ---------------------------------------------
	--// WATCHDOG
	--// ---------------------------------------------

	WATCHDOG_INTERVAL = 0.75,


	--// ---------------------------------------------
	--// RECUPERAÇÃO
	--// ---------------------------------------------

	RECOVERY_WINDOW = 30,
	MAX_RECOVERIES = 6,
	RECOVERY_COOLDOWN = 1,


	--// ---------------------------------------------
	--// PROTEÇÃO
	--// ---------------------------------------------

	LOCK_WALKSPEED = true,


	--// ---------------------------------------------
	--// CARRY DETECTOR
	--// ---------------------------------------------

	DETECT_TOOLS = true,

	DETECT_ATTRIBUTES = true,

	DETECT_TAGS = true,

	DETECT_CONSTRAINTS = true,


	--// ---------------------------------------------
	--// ATRIBUTOS CONSIDERADOS COMO CARRY
	--// ---------------------------------------------

	CARRY_ATTRIBUTES = {

		"Carrying",
		"IsCarrying",
		"HasCarry",
		"CarryingObject",
		"IsCarryingObject",
		"Holding",
		"IsHolding",
		"HasObject",

	},


	--// ---------------------------------------------
	--// TAGS CONSIDERADAS COMO CARRY
	// ---------------------------------------------

	CARRY_TAGS = {

		"Carried",
		"Carry",
		"CarryObject",
		"Carrying",
		"Held",
		"HeavyObject",

	},


	--// ---------------------------------------------
	--// GUI
	// ---------------------------------------------

	GUI_NAME =
		"SpeedUltraV71_2026",


	--// ---------------------------------------------
	--// DEBUG
	// ---------------------------------------------

	DEBUG = false,

	DIAGNOSTICS = false,

}


--// =========================================================
--// ESTADO
// =========================================================

local State = {

	Alive = true,

	Enabled = true,


	--// Velocidade configurada pelo usuário.
	TargetSpeed =
		Config.DEFAULT_SPEED,


	--// Estado de Carry.
	Carrying = false,

	CarriedObject = nil,

	CarryScanPending = false,


	--// Personagem.
	Character = nil,

	Humanoid = nil,

	RootPart = nil,


	--// Velocidade original.
	OriginalWalkSpeed = nil,


	--// Geração do personagem.
	CharacterGeneration = 0,

	PreparationToken = 0,

	Preparing = false,


	--// Recuperação.
	RecoveryWindowStart = 0,

	RecoveryCount = 0,

	LastRecovery = 0,


	--// Diagnóstico.
	LastSpeedApply = 0,

	LastPhysicsStep = 0,

	PhysicsWrites = 0,

	InvalidVelocityCount = 0,

	MispredictionCount = 0,


	--// Drag.
	Dragging = false,

	DragStart = Vector2.zero,

	PanelStart = Vector2.zero,


	--// Camera.
	Camera = nil,

}


--// =========================================================
--// CONEXÕES
--// =========================================================

local Connections = {

	Global = {},

	Character = {},

	Camera = {},

}


--// =========================================================
--// DEBUG
--// =========================================================

local function Debug(...)

	if Config.DEBUG then

		warn(
			"[SPEED ULTRA V7.1]",
			...
		)

	end

end


--// =========================================================
--// CONEXÃO SEGURA
--// =========================================================

local function Disconnect(connection)

	if not connection then
		return
	end

	pcall(function()

		connection:Disconnect()

	end)

end


local function DisconnectGroup(group)

	for name, connection in
		pairs(group) do

		Disconnect(connection)

		group[name] = nil

	end

end


local function SetConnection(
	group,
	name,
	connection
)

	Disconnect(
		group[name]
	)

	group[name] =
		connection

end


--// =========================================================
--// SEGURANÇA NUMÉRICA
--// =========================================================

local function IsFiniteNumber(value)

	return
		type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge

end


local function IsFiniteVector3(value)

	if typeof(value)
		~= "Vector3"
	then

		return false

	end

	return
		IsFiniteNumber(value.X)
		and
		IsFiniteNumber(value.Y)
		and
		IsFiniteNumber(value.Z)

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


--// =========================================================
--// CONFIG VALIDATION
--// =========================================================

local function ValidateConfig()

	Config.DEFAULT_SPEED =
		NormalizeSpeed(
			Config.DEFAULT_SPEED
		)
		or 255


	Config.CARRY_SPEED =
		NormalizeSpeed(
			Config.CARRY_SPEED
		)
		or Config.DEFAULT_SPEED


	Config.ACCELERATION =
		math.max(
			0.01,
			tonumber(
				Config.ACCELERATION
			)
			or 55
		)


	Config.DECELERATION =
		math.max(
			0.01,
			tonumber(
				Config.DECELERATION
			)
			or 16
		)


	Config.MAX_HORIZONTAL_VELOCITY =
		math.max(
			Config.MAX_SPEED,
			tonumber(
				Config.MAX_HORIZONTAL_VELOCITY
			)
			or 1500
		)


	Config.MAX_DELTA_TIME =
		math.clamp(
			tonumber(
				Config.MAX_DELTA_TIME
			)
			or 0.10,
			0.01,
			0.25
		)


	Config.WATCHDOG_INTERVAL =
		math.max(
			0.20,
			tonumber(
				Config.WATCHDOG_INTERVAL
			)
			or 0.75
		)


	Config.RECOVERY_WINDOW =
		math.max(
			5,
			tonumber(
				Config.RECOVERY_WINDOW
			)
			or 30
		)


	Config.MAX_RECOVERIES =
		math.max(
			1,
			math.floor(
				tonumber(
					Config.MAX_RECOVERIES
				)
				or 6
			)
		)


	Config.RECOVERY_COOLDOWN =
		math.max(
			0.10,
			tonumber(
				Config.RECOVERY_COOLDOWN
			)
			or 1
		)


	if Config.MOVEMENT_MODE ~= "WalkSpeed"
		and Config.MOVEMENT_MODE ~= "Hybrid"
	then

		Config.MOVEMENT_MODE =
			"WalkSpeed"

	end

end


ValidateConfig()


--// =========================================================
--// GUI EXISTENTE
// =========================================================

local OldGui =
	PlayerGui:FindFirstChild(
		Config.GUI_NAME
	)

if OldGui then

	pcall(function()

		OldGui:Destroy()

	end)

end


--// =========================================================
--// SCREEN GUI
// =========================================================

local ScreenGui =
	Instance.new(
		"ScreenGui"
	)

ScreenGui.Name =
	Config.GUI_NAME

ScreenGui.ResetOnSpawn =
	false

ScreenGui.IgnoreGuiInset =
	true

ScreenGui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
	PlayerGui


--// =========================================================
--// FRAME
// =========================================================

local Frame =
	Instance.new(
		"Frame"
	)

Frame.Name =
	"Main"

Frame.Size =
	UDim2.fromOffset(
		215,
		120
	)

Frame.Position =
	UDim2.fromOffset(
		25,
		200
	)

Frame.BackgroundColor3 =
	Color3.fromRGB(
		15,
		15,
		15
	)

Frame.BorderSizePixel =
	0

Frame.Active =
	true

Frame.Parent =
	ScreenGui


local FrameCorner =
	Instance.new(
		"UICorner"
	)

FrameCorner.CornerRadius =
	UDim.new(
		0,
		9
	)

FrameCorner.Parent =
	Frame


--// =========================================================
--// ACCENT
// =========================================================

local Accent =
	Instance.new(
		"Frame"
	)

Accent.Size =
	UDim2.new(
		1,
		0,
		0,
		3
	)

Accent.BackgroundColor3 =
	Color3.fromRGB(
		255,
		0,
		100
	)

Accent.BorderSizePixel =
	0

Accent.Parent =
	Frame


--// =========================================================
--// TITLE
// =========================================================

local Title =
	Instance.new(
		"TextLabel"
	)

Title.Size =
	UDim2.new(
		1,
		-16,
		0,
		25
	)

Title.Position =
	UDim2.fromOffset(
		8,
		5
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"⚡ SPEED ULTRA V7.1"

Title.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Title.Font =
	Enum.Font.SourceSansBold

Title.TextSize =
	12

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Active =
	true

Title.Parent =
	Frame


--// =========================================================
--// SPEED BOX
// =========================================================

local SpeedBox =
	Instance.new(
		"TextBox"
	)

SpeedBox.Size =
	UDim2.fromOffset(
		85,
		29
	)

SpeedBox.Position =
	UDim2.fromOffset(
		10,
		36
	)

SpeedBox.BackgroundColor3 =
	Color3.fromRGB(
		30,
		30,
		30
	)

SpeedBox.BorderSizePixel =
	0

SpeedBox.Text =
	tostring(
		State.TargetSpeed
	)

SpeedBox.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

SpeedBox.Font =
	Enum.Font.SourceSans

SpeedBox.TextSize =
	16

SpeedBox.ClearTextOnFocus =
	false

SpeedBox.TextEditable =
	true

SpeedBox.Parent =
	Frame


local SpeedCorner =
	Instance.new(
		"UICorner"
	)

SpeedCorner.CornerRadius =
	UDim.new(
		0,
		5
	)

SpeedCorner.Parent =
	SpeedBox


--// =========================================================
--// APPLY BUTTON
// =========================================================

local ApplyButton =
	Instance.new(
		"TextButton"
	)

ApplyButton.Size =
	UDim2.fromOffset(
		90,
		29
	)

ApplyButton.Position =
	UDim2.fromOffset(
		105,
		36
	)

ApplyButton.BackgroundColor3 =
	Color3.fromRGB(
		255,
		0,
		100
	)

ApplyButton.BorderSizePixel =
	0

ApplyButton.Text =
	"APLICAR"

ApplyButton.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

ApplyButton.Font =
	Enum.Font.SourceSansBold

ApplyButton.TextSize =
	12

ApplyButton.Parent =
	Frame


local ApplyCorner =
	Instance.new(
		"UICorner"
	)

ApplyCorner.CornerRadius =
	UDim.new(
		0,
		5
	)

ApplyCorner.Parent =
	ApplyButton


--// =========================================================
--// TOGGLE
// =========================================================

local Toggle =
	Instance.new(
		"TextButton"
	)

Toggle.Size =
	UDim2.fromOffset(
		85,
		27
	)

Toggle.Position =
	UDim2.fromOffset(
		10,
		73
	)

Toggle.BackgroundColor3 =
	Color3.fromRGB(
		45,
		45,
		45
	)

Toggle.BorderSizePixel =
	0

Toggle.Text =
	"SISTEMA: ON"

Toggle.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Toggle.Font =
	Enum.Font.SourceSansBold

Toggle.TextSize =
	11

Toggle.Parent =
	Frame


local ToggleCorner =
	Instance.new(
		"UICorner"
	)

ToggleCorner.CornerRadius =
	UDim.new(
		0,
		5
	)

ToggleCorner.Parent =
	Toggle


--// =========================================================
--// STATUS
// =========================================================

local Status =
	Instance.new(
		"TextLabel"
	)

Status.Size =
	UDim2.fromOffset(
		115,
		27
	)

Status.Position =
	UDim2.fromOffset(
		100,
		73
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"INICIANDO"

Status.TextColor3 =
	Color3.fromRGB(
		170,
		170,
		170
	)

Status.Font =
	Enum.Font.SourceSans

Status.TextSize =
	10

Status.TextXAlignment =
	Enum.TextXAlignment.Left

Status.Parent =
	Frame


--// =========================================================
--// STATUS
// =========================================================

local function SetStatus(text)

	if not State.Alive then
		return
	end

	if not Status
		or not Status.Parent
	then

		return

	end

	Status.Text =
		tostring(text)

end


local function RefreshStatus()

	if not State.Alive then
		return
	end

	if not State.Enabled then

		SetStatus(
			"DESATIVADO"
		)

		return

	end

	if State.Carrying then

		SetStatus(
			"CARRY • "
			.. tostring(
				Config.CARRY_SPEED
			)

		)

		return

	end

	if not State.Character then

		SetStatus(
			"AGUARDANDO"
		)

		return

	end

	if not State.Humanoid then

		SetStatus(
			"CARREGANDO"
		)

		return

	end

	SetStatus(
		"ATIVO • "
		.. tostring(
			State.TargetSpeed
		)
	)

end


--// =========================================================
--// RECOVERY
// =========================================================

local function CanRecover()

	local now =
		os.clock()

	if
		now - State.RecoveryWindowStart
		> Config.RECOVERY_WINDOW
	then

		State.RecoveryWindowStart =
			now

		State.RecoveryCount =
			0

	end

	if
		now - State.LastRecovery
		< Config.RECOVERY_COOLDOWN
	then

		return false

	end

	return
		State.RecoveryCount
		< Config.MAX_RECOVERIES

end


local function RegisterRecovery()

	local now =
		os.clock()

	if
		now - State.RecoveryWindowStart
		> Config.RECOVERY_WINDOW
	then

		State.RecoveryWindowStart =
			now

		State.RecoveryCount =
			0

	end

	State.RecoveryCount +=
		1

	State.LastRecovery =
		now

end


--// =========================================================
--// CHARACTER VALID
// =========================================================

local function ValidCharacter(
	character,
	generation,
	token
)

	return

		State.Alive

		and

		Player.Character
			== character

		and

		State.Character
			== character

		and

		State.CharacterGeneration
			== generation

		and

		State.PreparationToken
			== token

end


--// =========================================================
--// CHARACTER CLEANUP
// =========================================================

local function CleanupCharacter()

	DisconnectGroup(
		Connections.Character
	)

	State.Character =
		nil

	State.Humanoid =
		nil

	State.RootPart =
		nil

	State.Carrying =
		false

	State.CarriedObject =
		nil

	State.OriginalWalkSpeed =
		nil

	State.CarryScanPending =
		false

end


--// =========================================================
--// RESTORE ORIGINAL SPEED
// =========================================================

local function RestoreOriginalSpeed()

	local humanoid =
		State.Humanoid

	local original =
		State.OriginalWalkSpeed

	if not humanoid
		or not humanoid.Parent
	then

		return

	end

	if not IsFiniteNumber(
		original
	) then

		return

	end

	pcall(function()

		humanoid.WalkSpeed =
			original

	end)

end


--// =========================================================
--// CARRY ATTRIBUTE VALUE
// =========================================================

local function IsCarryAttributeValue(
	value
)

	if value == true then
		return true
	end

	if typeof(value)
		== "Instance"
	then

		return value ~= nil

	end

	if type(value)
		== "string"
	then

		return value ~= ""

	end

	if type(value)
		== "number"
	then

		return value > 0

	end

	return false

end


--// =========================================================
--// CHECK CARRY ATTRIBUTES
// =========================================================

local function CheckCarryAttributes(
	object
)

	if not Config.DETECT_ATTRIBUTES then
		return false
	end

	if not object then
		return false
	end

	for _, attributeName in
		ipairs(
			Config.CARRY_ATTRIBUTES
		) do

		local value =
			object:GetAttribute(
				attributeName
			)

		if IsCarryAttributeValue(
			value
		) then

			return true

		end

	end

	return false

end


--// =========================================================
--// CHECK CARRY TAGS
// =========================================================

local function CheckCarryTags(
	object
)

	if not Config.DETECT_TAGS then
		return false
	end

	if not object then
		return false
	end

	for _, tagName in
		ipairs(
			Config.CARRY_TAGS
		) do

		if CollectionService:HasTag(
			object,
			tagName
		) then

			return true

		end

	end

	return false

end


--// =========================================================
--// CHECK TOOL
// =========================================================

local function CheckCarryTool(
	character
)

	if not Config.DETECT_TOOLS then
		return false, nil
	end

	if not character then
		return false, nil
	end

	for _, child in
		ipairs(
			character:GetChildren()
		) do

		if child:IsA("Tool") then

			return true, child

		end

	end

	return false, nil

end


--// =========================================================
--// CHECK CONSTRAINT PART
// =========================================================

local function GetConstraintPart(
	attachment
)

	if not attachment then
		return nil
	end

	if not attachment:IsA(
		"Attachment"
	) then

		return nil

	end

	local parent =
		attachment.Parent

	if parent
		and parent:IsA("BasePart")
	then

		return parent

	end

	return nil

end


--// =========================================================
--// CHECK EXTERNAL CONSTRAINT
// =========================================================

local function CheckExternalConstraints(
	character
)

	if not Config.DETECT_CONSTRAINTS then
		return false, nil
	end

	if not character then
		return false, nil
	end

	--// -----------------------------------------------------
	--// Primeiro: constraints clássicos com Part0 / Part1.
	// -----------------------------------------------------

	for _, object in
		ipairs(
			character:GetDescendants()
		) do

		if object:IsA(
			"WeldConstraint"
		) then

			local p0 =
				object.Part0

			local p1 =
				object.Part1

			if p0 and p1 then

				local inside0 =
					p0:IsDescendantOf(
						character
					)

				local inside1 =
					p1:IsDescendantOf(
						character
					)

				if inside0 ~= inside1 then

					if inside0 then
						return true, p1
					else
						return true, p0
					end

				end

			end


		elseif object:IsA(
			"Weld"
		)
		then

			local p0 =
				object.Part0

			local p1 =
				object.Part1

			if p0 and p1 then

				local inside0 =
					p0:IsDescendantOf(
						character
					)

				local inside1 =
					p1:IsDescendantOf(
						character
					)

				if inside0 ~= inside1 then

					if inside0 then
						return true, p1
					else
						return true, p0
					end

				end

			end


		elseif object:IsA(
			"Motor6D"
		)
		then

			local p0 =
				object.Part0

			local p1 =
				object.Part1

			if p0 and p1 then

				local inside0 =
					p0:IsDescendantOf(
						character
					)

				local inside1 =
					p1:IsDescendantOf(
						character
					)

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


	--// -----------------------------------------------------
	--// Segundo: constraints baseados em Attachment.
	// -----------------------------------------------------

	for _, object in
		ipairs(
			character:GetDescendants()
		) do

		local a0
		local a1

		if object:IsA(
			"AlignPosition"
		)
		or object:IsA(
			"AlignOrientation"
		)
		or object:IsA(
			"RopeConstraint"
		)
		or object:IsA(
			"RodConstraint"
		)
		or object:IsA(
			"SpringConstraint"
		)
		or object:IsA(
			"BallSocketConstraint"
		)
		or object:IsA(
			"HingeConstraint"
		)
		or object:IsA(
			"CylindricalConstraint"
		)
		or object:IsA(
			"PrismaticConstraint"
		)
		or object:IsA(
			"UniversalConstraint"
		)
		then

			a0 =
				object.Attachment0

			a1 =
				object.Attachment1

		end

		if a0 and a1 then

			local p0 =
				GetConstraintPart(
					a0
				)

			local p1 =
				GetConstraintPart(
					a1
				)

			if p0 and p1 then

				local inside0 =
					p0:IsDescendantOf(
						character
					)

				local inside1 =
					p1:IsDescendantOf(
						character
					)

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


--// =========================================================
--// CARRY DETECTOR
--// =========================================================

local function DetectCarry()

	local character =
		State.Character

	if not character then

		return false, nil

	end


	--// -----------------------------------------------------
	--// ATTRIBUTE DO CHARACTER
	// -----------------------------------------------------

	if CheckCarryAttributes(
		character
	) then

		return true, character

	end


	--// -----------------------------------------------------
	--// TAG DO CHARACTER
	// -----------------------------------------------------

	if CheckCarryTags(
		character
	) then

		return true, character

	end


	--// -----------------------------------------------------
	--// TOOL
	// -----------------------------------------------------

	local toolFound,
		tool =
		CheckCarryTool(
			character
		)

	if toolFound then

		return true, tool

	end


	--// -----------------------------------------------------
	--// OBJETOS DESCENDENTES
	// -----------------------------------------------------

	if Config.DETECT_ATTRIBUTES
		or Config.DETECT_TAGS
	then

		for _, object in
			ipairs(
				character:GetDescendants()
			) do

			if object == character then
				continue
			end

			if Config.DETECT_ATTRIBUTES
				and CheckCarryAttributes(
					object
				)
			then

				return true, object

			end

			if Config.DETECT_TAGS
				and CheckCarryTags(
					object
				)
			then

				return true, object

			end

		end

	end


	--// -----------------------------------------------------
	--// CONSTRAINTS
	// -----------------------------------------------------

	local constraintFound,
		externalObject =
		CheckExternalConstraints(
			character
		)

	if constraintFound then

		return true,
			externalObject

	end


	return false, nil

end


--// =========================================================
--// DESIRED SPEED
// =========================================================

local function GetDesiredSpeed()

	if State.Carrying then

		return
			NormalizeSpeed(
				Config.CARRY_SPEED
			)
			or
			State.TargetSpeed

	end

	return
		NormalizeSpeed(
			State.TargetSpeed
		)
		or
		Config.DEFAULT_SPEED

end


--// =========================================================
--// APPLY SPEED
// =========================================================

local function ApplySpeed()

	if not State.Alive then
		return false
	end

	if not State.Enabled then
		return false
	end

	if not Config.LOCK_WALKSPEED then
		return false
	end

	local humanoid =
		State.Humanoid

	if not humanoid
		or not humanoid.Parent
	then

		return false

	end

	if humanoid.Health <= 0 then
		return false
	end

	local desired =
		GetDesiredSpeed()

	if not desired then
		return false
	end

	if humanoid.WalkSpeed
		== desired
	then

		return true

	end

	local success =
		pcall(function()

			humanoid.WalkSpeed =
				desired

		end)

	if success then

		State.LastSpeedApply =
			os.clock()

	end

	return success

end


--// =========================================================
--// UPDATE CARRY
// =========================================================

local function UpdateCarryState()

	if not State.Alive then
		return
	end

	if not State.Character then
		return
	end

	local carrying,
		object =
		DetectCarry()

	local changed =
		carrying
		~= State.Carrying

	State.Carrying =
		carrying

	State.CarriedObject =
		object

	if changed then

		Debug(
			"Carry:",
			carrying,
			"Objeto:",
			object
		)

	end

	if State.Enabled then

		ApplySpeed()

	end

	RefreshStatus()

end


--// =========================================================
--// SCHEDULE CARRY SCAN
// =========================================================
--
-- Evita dezenas de GetDescendants()
-- quando vários objetos entram juntos.
-- =========================================================

local function ScheduleCarryScan()

	if not State.Alive then
		return
	end

	if State.CarryScanPending then
		return
	end

	State.CarryScanPending =
		true

	task.defer(
		function()

			State.CarryScanPending =
				false

			if not State.Alive then
				return
			end

			UpdateCarryState()

		end
	)

end


--// =========================================================
--// PREPARE CHARACTER
// =========================================================

local function PrepareCharacter(
	character,
	isRecovery
)

	if not State.Alive then
		return
	end

	if not character then
		return
	end

	if State.Preparing then
		return
	end

	--// Recuperação só usa o budget quando
	--// realmente foi necessário reconstruir.
	if isRecovery then

		if not CanRecover() then

			SetStatus(
				"RECUPERAÇÃO LIMITADA"
			)

			return

		end

		RegisterRecovery()

	end

	State.Preparing =
		true

	State.CharacterGeneration +=
		1

	State.PreparationToken +=
		1

	local generation =
		State.CharacterGeneration

	local token =
		State.PreparationToken

	--// Limpeza antiga.
	DisconnectGroup(
		Connections.Character
	)

	State.Character =
		nil

	State.Humanoid =
		nil

	State.RootPart =
		nil

	State.Carrying =
		false

	State.CarriedObject =
		nil

	State.OriginalWalkSpeed =
		nil

	State.CarryScanPending =
		false

	--// Novo personagem.
	State.Character =
		character

	SetStatus(
		"CARREGANDO..."
	)


	--// -----------------------------------------------------
	--// HUMANOID
	// -----------------------------------------------------

	local humanoid =
		character:WaitForChild(
			"Humanoid",
			15
		)

	if not ValidCharacter(
		character,
		generation,
		token
	) then

		State.Preparing =
			false

		return

	end

	if not humanoid then

		State.Preparing =
			false

		SetStatus(
			"ERRO • HUMANOID"
		)

		return

	end

	-- Salva a velocidade original somente
	-- uma vez para este personagem.
	State.OriginalWalkSpeed =
		humanoid.WalkSpeed


	--// -----------------------------------------------------
	--// ROOT
	// -----------------------------------------------------

	local root =
		character:WaitForChild(
			"HumanoidRootPart",
			15
		)

	if not ValidCharacter(
		character,
		generation,
		token
	) then

		State.Preparing =
			false

		return

	end

	if not root then

		State.Preparing =
			false

		SetStatus(
			"ERRO • ROOTPART"
		)

		return

	end

	State.Humanoid =
		humanoid

	State.RootPart =
		root


	--// -----------------------------------------------------
	// CARRY EVENTS
	// -----------------------------------------------------

	SetConnection(
		Connections.Character,
		"ChildAdded",

		character.ChildAdded:Connect(
			function()

				ScheduleCarryScan()

			end
		)
	)


	SetConnection(
		Connections.Character,
		"ChildRemoved",

		character.ChildRemoved:Connect(
			function()

				ScheduleCarryScan()

			end
		)
	)


	SetConnection(
		Connections.Character,
		"DescendantAdded",

		character.DescendantAdded:Connect(
			function()

				ScheduleCarryScan()

			end
		)
	)


	SetConnection(
		Connections.Character,
		"DescendantRemoving",

		character.DescendantRemoving:Connect(
			function()

				ScheduleCarryScan()

			end
		)
	)


	--// -----------------------------------------------------
	// ATTRIBUTE CHANGE
	// -----------------------------------------------------

	SetConnection(
		Connections.Character,
		"AttributeChanged",

		character.AttributeChanged:Connect(
			function()

				ScheduleCarryScan()

			end
		)
	)


	--// -----------------------------------------------------
	// WALKSPEED GUARD
	// -----------------------------------------------------

	SetConnection(
		Connections.Character,
		"WalkSpeed",

		humanoid:GetPropertyChangedSignal(
			"WalkSpeed"
		):Connect(
			function()

				if not State.Alive then
					return
				end

				if not State.Enabled then
					return
				end

				if not Config.LOCK_WALKSPEED then
					return
				end

				if not ValidCharacter(
					character,
					generation,
					token
				) then

					return

				end

				if humanoid.Health <= 0 then
					return
				end

				ApplySpeed()

			end
		)
	)


	--// -----------------------------------------------------
	// MORTE
	// -----------------------------------------------------

	SetConnection(
		Connections.Character,
		"Died",

		humanoid.Died:Connect(
			function()

				if not State.Alive then
					return
				end

				State.Carrying =
					false

				State.CarriedObject =
					nil

				SetStatus(
					"MORTO • AGUARDANDO"
				)

			end
		)
	)


	--// -----------------------------------------------------
	// PRIMEIRO CARRY SCAN
	// -----------------------------------------------------

	UpdateCarryState()


	--// -----------------------------------------------------
	// VELOCIDADE INICIAL
	// -----------------------------------------------------

	if State.Enabled
		and Config.LOCK_WALKSPEED
	then

		ApplySpeed()

	end


	--// -----------------------------------------------------
	// FINAL
	// -----------------------------------------------------

	if ValidCharacter(
		character,
		generation,
		token
	) then

		State.Preparing =
			false

		RefreshStatus()

		Debug(
			"Personagem pronto:",
			character.Name
		)

	else

		State.Preparing =
			false

	end

end


--// =========================================================
--// SPEED INPUT
// =========================================================

local function SetTargetSpeed()

	if not State.Alive then
		return
	end

	local text =
		string.gsub(
			SpeedBox.Text,
			"%s+",
			""
		)

	if text == "" then

		SpeedBox.Text =
			tostring(
				State.TargetSpeed
			)

		RefreshStatus()

		return

	end

	local value =
		tonumber(text)

	local normalized =
		NormalizeSpeed(value)

	if not normalized then

		SpeedBox.Text =
			tostring(
				State.TargetSpeed
			)

		SetStatus(
			"VALOR INVÁLIDO"
		)

		task.delay(
			1,
			function()

				if State.Alive then

					RefreshStatus()

				end

			end
		)

		return

	end

	State.TargetSpeed =
		normalized

	SpeedBox.Text =
		tostring(
			normalized
		)

	if State.Enabled then

		ApplySpeed()

	end

	RefreshStatus()

end


--// =========================================================
--// TOGGLE
// =========================================================

local function ToggleSystem()

	if not State.Alive then
		return
	end

	State.Enabled =
		not State.Enabled

	if State.Enabled then

		Toggle.Text =
			"SISTEMA: ON"

		ApplySpeed()

	else

		Toggle.Text =
			"SISTEMA: OFF"

		RestoreOriginalSpeed()

	end

	RefreshStatus()

end


--// =========================================================
--// BUTTON CONNECTIONS
// =========================================================

SetConnection(
	Connections.Global,
	"ApplyButton",

	ApplyButton.Activated:Connect(
		SetTargetSpeed
	)
)


SetConnection(
	Connections.Global,
	"FocusLost",

	SpeedBox.FocusLost:Connect(
		SetTargetSpeed
	)
)


SetConnection(
	Connections.Global,
	"Toggle",

	Toggle.Activated:Connect(
		ToggleSystem
	)
)


--// =========================================================
--// HYBRID PHYSICS
// =========================================================

local function PhysicsAssist(
	deltaTime
)

	if Config.MOVEMENT_MODE
		~= "Hybrid"
	then

		return

	end

	if not State.Alive
		or not State.Enabled
	then

		return

	end

	local humanoid =
		State.Humanoid

	local root =
		State.RootPart

	if not humanoid
		or not root
	then

		return

	end

	if not humanoid.Parent
		or not root.Parent
	then

		return

	end

	if humanoid.Health <= 0
		or root.Anchored
	then

		return

	end

	if not IsFiniteNumber(
		deltaTime
	) then

		return

	end

	local velocity =
		root.AssemblyLinearVelocity

	if not IsFiniteVector3(
		velocity
	) then

		State.InvalidVelocityCount +=
			1

		pcall(function()

			root.AssemblyLinearVelocity =
				Vector3.zero

		end)

		return

	end

	local dt =
		math.clamp(
			deltaTime,
			0,
			Config.MAX_DELTA_TIME
		)

	-- API atual do Humanoid.
	local moveVelocity =
		humanoid:GetMoveVelocity()

	if not IsFiniteVector3(
		moveVelocity
	) then

		return

	end

	local currentX =
		velocity.X

	local currentZ =
		velocity.Z

	local horizontal =
		math.sqrt(
			currentX * currentX
			+
			currentZ * currentZ
		)

	--// Hard cap.
	if horizontal
		> Config.MAX_HORIZONTAL_VELOCITY
	then

		local ratio =
			Config.MAX_HORIZONTAL_VELOCITY
			/ horizontal

		currentX *= ratio
		currentZ *= ratio

	end

	local targetX =
		moveVelocity.X

	local targetZ =
		moveVelocity.Z

	local moving =
		math.abs(targetX)
			> 0.001

		or

		math.abs(targetZ)
			> 0.001

	local rate

	if moving then

		rate =
			Config.ACCELERATION

	else

		rate =
			Config.DECELERATION

		targetX =
			0

		targetZ =
			0

	end

	local alpha =
		1 - math.exp(
			-rate * dt
		)

	local newX =
		currentX
		+
		(targetX - currentX)
		* alpha

	local newZ =
		currentZ
		+
		(targetZ - currentZ)
		* alpha

	if not IsFiniteNumber(newX)
		or not IsFiniteNumber(newZ)
	then

		return

	end

	local differenceX =
		math.abs(
			newX -
			velocity.X
		)

	local differenceZ =
		math.abs(
			newZ -
			velocity.Z
		)

	-- Só escreve quando a diferença realmente existe.
	if differenceX <= 0.05
		and differenceZ <= 0.05
	then

		return

	end

	local success =
		pcall(function()

			root.AssemblyLinearVelocity =
				Vector3.new(
					newX,
					velocity.Y,
					newZ
				)

		end)

	if success then

		State.PhysicsWrites +=
			1

		State.LastPhysicsStep =
			os.clock()

	end

end


--// =========================================================
--// PRE SIMULATION
// =========================================================

if Config.MOVEMENT_MODE
	== "Hybrid"
then

	SetConnection(
		Connections.Global,
		"PreSimulation",

		RunService.PreSimulation:Connect(
			PhysicsAssist
		)
	)

end


--// =========================================================
--// CHARACTER ADDED
// =========================================================

SetConnection(
	Connections.Global,
	"CharacterAdded",

	Player.CharacterAdded:Connect(
		function(character)

			if not State.Alive then
				return
			end

			task.defer(
				function()

					if not State.Alive then
						return
					end

					if character
						~= Player.Character
					then

						return

					end

					PrepareCharacter(
						character,
						false
					)

				end
			)

		end
	)
)


--// =========================================================
--// CHARACTER REMOVING
// =========================================================

SetConnection(
	Connections.Global,
	"CharacterRemoving",

	Player.CharacterRemoving:Connect(
		function(character)

			if character
				== State.Character
			then

				-- Restaura antes de limpar a referência.
				RestoreOriginalSpeed()

				State.CharacterGeneration +=
					1

				State.PreparationToken +=
					1

				DisconnectGroup(
					Connections.Character
				)

				State.Character =
					nil

				State.Humanoid =
					nil

				State.RootPart =
					nil

				State.Carrying =
					false

				State.CarriedObject =
					nil

				State.OriginalWalkSpeed =
					nil

				State.Preparing =
					false

				SetStatus(
					"PERSONAGEM REMOVIDO"
				)

			end

		end
	)
)


--// =========================================================
--// WATCHDOG
// =========================================================

task.spawn(
	function()

		while State.Alive do

			task.wait(
				Config.WATCHDOG_INTERVAL
			)

			if not State.Alive then
				break
			end

			local character =
				Player.Character

			--// ---------------------------------------------
			--// SEM CHARACTER
			// ---------------------------------------------

			if not character then

				if State.Character then

					DisconnectGroup(
						Connections.Character
					)

					State.Character =
						nil

					State.Humanoid =
						nil

					State.RootPart =
						nil

				end

				RefreshStatus()

				continue

			end


			--// ---------------------------------------------
			--// CHARACTER DIFERENTE
			// ---------------------------------------------

			if character
				~= State.Character
			then

				if not State.Preparing then

					PrepareCharacter(
						character,
						false
					)

				end

				continue

			end


			--// ---------------------------------------------
			--// HUMANOID PERDIDO
			// ---------------------------------------------

			if not State.Humanoid
				or not State.Humanoid.Parent
			then

				if not State.Preparing then

					PrepareCharacter(
						character,
						true
					)

				end

				continue

			end


			--// ---------------------------------------------
			// ROOT PERDIDO
			// ---------------------------------------------

			if not State.RootPart
				or not State.RootPart.Parent
			then

				if not State.Preparing then

					PrepareCharacter(
						character,
						true
					)

				end

				continue

			end


			--// ---------------------------------------------
			// CARRY
			// ---------------------------------------------

			UpdateCarryState()


			--// ---------------------------------------------
			// WALKSPEED
			// ---------------------------------------------

			if State.Enabled
				and Config.LOCK_WALKSPEED
				and State.Humanoid.Health > 0
			then

				local desired =
					GetDesiredSpeed()

				if
					State.Humanoid.WalkSpeed
					~= desired
				then

					ApplySpeed()

				end

			end

		end

	end
)


--// =========================================================
--// PANEL LIMITS
// =========================================================

local function GetPanelLimits()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport =
		camera.ViewportSize

	local width =
		Frame.AbsoluteSize.X

	local height =
		Frame.AbsoluteSize.Y

	return

		math.max(
			0,
			viewport.X - width
		),

		math.max(
			0,
			viewport.Y - height
		)

end


local function ClampPanel(
	x,
	y
)

	local maxX, maxY =
		GetPanelLimits()

	if not maxX
		or not maxY
	then

		return x, y

	end

	return

		math.clamp(
			x,
			0,
			maxX
		),

		math.clamp(
			y,
			0,
			maxY
		)

end


local function RepositionPanel()

	if not Frame
		or not Frame.Parent
	then

		return

	end

	local x =
		Frame.AbsolutePosition.X

	local y =
		Frame.AbsolutePosition.Y

	x, y =
		ClampPanel(
			x,
			y
		)

	Frame.Position =
		UDim2.fromOffset(
			x,
			y
		)

end


--// =========================================================
--// DRAG START
// =========================================================

SetConnection(
	Connections.Global,
	"DragStart",

	Title.InputBegan:Connect(
		function(input)

			local valid =

				input.UserInputType
					== Enum.UserInputType.Touch

				or

				input.UserInputType
					== Enum.UserInputType.MouseButton1

			if not valid then
				return
			end

			State.Dragging =
				true

			State.DragStart =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)

			State.PanelStart =
				Vector2.new(
					Frame.AbsolutePosition.X,
					Frame.AbsolutePosition.Y
				)

		end
	)
)


--// =========================================================
//// DRAG MOVE
// =========================================================

SetConnection(
	Connections.Global,
	"DragMove",

	UserInputService.InputChanged:Connect(
		function(input)

			if not State.Dragging then
				return
			end

			if

				input.UserInputType
					~= Enum.UserInputType.Touch

				and

				input.UserInputType
					~= Enum.UserInputType.MouseMovement

			then

				return

			end

			local current =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)

			local delta =
				current
				- State.DragStart

			local x =
				State.PanelStart.X
				+ delta.X

			local y =
				State.PanelStart.Y
				+ delta.Y

			x, y =
				ClampPanel(
					x,
					y
				)

			Frame.Position =
				UDim2.fromOffset(
					x,
					y
				)

		end
	)
)


--// =========================================================
//// DRAG END
// =========================================================

SetConnection(
	Connections.Global,
	"DragEnd",

	UserInputService.InputEnded:Connect(
		function(input)

			if

				input.UserInputType
					== Enum.UserInputType.Touch

				or

				input.UserInputType
					== Enum.UserInputType.MouseButton1

			then

				State.Dragging =
					false

			end

		end
	)
)


--// =========================================================
//// CAMERA
// =========================================================

local function BindCamera()

	DisconnectGroup(
		Connections.Camera
	)

	local camera =
		workspace.CurrentCamera

	State.Camera =
		camera

	if not camera then
		return
	end

	SetConnection(
		Connections.Camera,
		"Viewport",

		camera:GetPropertyChangedSignal(
			"ViewportSize"
		):Connect(
			RepositionPanel
		)
	)

	RepositionPanel()

end


SetConnection(
	Connections.Global,
	"CameraChanged",

	workspace:GetPropertyChangedSignal(
		"CurrentCamera"
	):Connect(
		BindCamera
	)
)

BindCamera()


--// =========================================================
//// MISPREDICTION DIAGNOSTIC
// =========================================================

if Config.DIAGNOSTICS then

	pcall(function()

		SetConnection(
			Connections.Global,
			"Misprediction",

			RunService.Misprediction:Connect(
				function()

					if State.Alive then

						State.MispredictionCount +=
							1

						Debug(
							"Misprediction:",
							State.MispredictionCount
						)

					end

				end
			)
		)

	end)

end


--// =========================================================
//// SHUTDOWN
// =========================================================

local function Shutdown()

	if not State.Alive then
		return
	end

	State.Alive =
		false

	State.CharacterGeneration +=
		1

	State.PreparationToken +=
		1

	State.Preparing =
		false

	-- Restaura antes de perder a referência.
	RestoreOriginalSpeed()

	DisconnectGroup(
		Connections.Global
	)

	DisconnectGroup(
		Connections.Character
	)

	DisconnectGroup(
		Connections.Camera
	)

	State.Character =
		nil

	State.Humanoid =
		nil

	State.RootPart =
		nil

	State.Carrying =
		false

	State.CarriedObject =
		nil

	State.Dragging =
		false

	if ScreenGui then

		pcall(function()

			ScreenGui:Destroy()

		end)

	end

	Debug(
		"Speed Ultra V7.1 encerrado."
	)

end


--// =========================================================
//// SCRIPT DESTROYING
// =========================================================

if script then

	pcall(function()

		script.Destroying:Connect(
			Shutdown
		)

	end)

end


--// =========================================================
//// INICIALIZAÇÃO
// =========================================================

State.TargetSpeed =
	NormalizeSpeed(
		State.TargetSpeed
	)
	or Config.DEFAULT_SPEED

SpeedBox.Text =
	tostring(
		State.TargetSpeed
	)


if Player.Character then

	PrepareCharacter(
		Player.Character,
		false
	)

else

	SetStatus(
		"AGUARDANDO"
	)

end


RefreshStatus()


--// =========================================================
//// END
// =========================================================
