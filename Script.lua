--// =========================================================
--// SPEED ULTRA V6.1
--// OTIMIZADO + CORRIGIDO
--//
--// FOCO:
--// • baixo custo
--// • recuperação segura
--// • controle de estado
--// • respawn robusto
--// • WalkSpeed como modo principal
--// • Hybrid opcional
--// • limpeza correta
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
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


--// =========================================================
--// CLIENT CHECK
--// =========================================================

if not RunService:IsClient() then
	return
end

local Player = Players.LocalPlayer

if not Player then
	return
end

local PlayerGui = Player:WaitForChild(
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

	-- Velocidade
	DEFAULT_SPEED = 255,
	MIN_SPEED = 0,
	MAX_SPEED = 1000,

	-- Movimento
	--
	-- WalkSpeed:
	-- caminho mais leve
	--
	-- Hybrid:
	-- WalkSpeed + ajuste físico
	--
	MOVEMENT_MODE = "WalkSpeed",

	-- Física Hybrid
	ACCELERATION = 55,
	DECELERATION = 16,

	MAX_HORIZONTAL_VELOCITY = 1500,
	MAX_DELTA_TIME = 0.10,

	-- Watchdog
	WATCHDOG_INTERVAL = 0.75,

	-- Recuperação do Watchdog
	RECOVERY_WINDOW = 30,
	MAX_RECOVERIES = 6,
	RECOVERY_COOLDOWN = 1,

	-- Proteção
	LOCK_WALKSPEED = true,

	-- Recurso experimental.
	-- Mantido desligado por padrão.
	ENABLE_OBJECT_PHYSICS = false,

	-- GUI
	GUI_NAME = "SpeedUltraV61_2026",

	-- Diagnóstico
	DIAGNOSTICS = false,
	DEBUG = false,
}


--// =========================================================
--// VALIDAÇÃO DA CONFIG
--// =========================================================

local function IsFiniteNumber(value)

	return
		type(value) == "number"
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


local function ValidateConfig()

	if not IsFiniteNumber(
		Config.DEFAULT_SPEED
	) then

		Config.DEFAULT_SPEED = 255

	end

	if not IsFiniteNumber(
		Config.MIN_SPEED
	) then

		Config.MIN_SPEED = 0

	end

	if not IsFiniteNumber(
		Config.MAX_SPEED
	) then

		Config.MAX_SPEED = 1000

	end

	if Config.MAX_SPEED
		< Config.MIN_SPEED then

		Config.MAX_SPEED =
			Config.MIN_SPEED + 1

	end

	Config.DEFAULT_SPEED =
		NormalizeSpeed(
			Config.DEFAULT_SPEED
		)
		or Config.MIN_SPEED

	Config.ACCELERATION =
		math.max(
			0.01,
			tonumber(
				Config.ACCELERATION
			) or 55
		)

	Config.DECELERATION =
		math.max(
			0.01,
			tonumber(
				Config.DECELERATION
			) or 16
		)

	Config.MAX_HORIZONTAL_VELOCITY =
		math.max(
			Config.MAX_SPEED,
			tonumber(
				Config.MAX_HORIZONTAL_VELOCITY
			) or 1500
		)

	Config.MAX_DELTA_TIME =
		math.clamp(
			tonumber(
				Config.MAX_DELTA_TIME
			) or 0.10,
			0.01,
			0.25
		)

	Config.WATCHDOG_INTERVAL =
		math.max(
			0.20,
			tonumber(
				Config.WATCHDOG_INTERVAL
			) or 0.75
		)

	Config.RECOVERY_WINDOW =
		math.max(
			5,
			tonumber(
				Config.RECOVERY_WINDOW
			) or 30
		)

	Config.MAX_RECOVERIES =
		math.max(
			1,
			math.floor(
				tonumber(
					Config.MAX_RECOVERIES
				) or 6
			)
		)

	Config.RECOVERY_COOLDOWN =
		math.max(
			0.1,
			tonumber(
				Config.RECOVERY_COOLDOWN
			) or 1
		)

	if Config.MOVEMENT_MODE ~= "WalkSpeed"
		and Config.MOVEMENT_MODE ~= "Hybrid" then

		Config.MOVEMENT_MODE = "WalkSpeed"

	end

end


ValidateConfig()


--// =========================================================
--// ESTADO CENTRAL
--// =========================================================

local State = {

	Alive = true,

	Enabled = true,

	TargetSpeed =
		Config.DEFAULT_SPEED,

	Character = nil,
	Humanoid = nil,
	RootPart = nil,

	-- Controle de geração
	CharacterGeneration = 0,
	PreparationToken = 0,

	-- Impede preparação dupla
	Preparing = false,

	-- Velocidade original do Humanoid
	OriginalWalkSpeed = nil,

	-- Watchdog
	RecoveryWindowStart = 0,
	RecoveryCount = 0,
	LastRecovery = 0,

	-- Diagnóstico
	LastSpeedApply = 0,
	LastPhysicsStep = 0,

	PhysicsWrites = 0,
	InvalidVelocityCount = 0,
	MispredictionCount = 0,

	-- GUI
	Dragging = false,
	DragStart = Vector2.zero,
	PanelStart = Vector2.zero,

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
			"[SPEED ULTRA V6.1]",
			...
		)

	end

end


--// =========================================================
--// CONNECTION MANAGER
--// =========================================================

local function Disconnect(
	connection
)

	if not connection then
		return
	end

	pcall(function()

		connection:Disconnect()

	end)

end


local function DisconnectGroup(
	group
)

	for name, connection in
		pairs(group) do

		Disconnect(
			connection
		)

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
--// VECTOR VALIDATION
--// =========================================================

local function IsFiniteVector3(
	value
)

	if typeof(value)
		~= "Vector3" then

		return false
	end

	return
		IsFiniteNumber(value.X)
		and
		IsFiniteNumber(value.Y)
		and
		IsFiniteNumber(value.Z)

end


--// =========================================================
--// GUI DUPLICADA
--// =========================================================

local oldGui =
	PlayerGui:FindFirstChild(
		Config.GUI_NAME
	)

if oldGui then

	pcall(function()

		oldGui:Destroy()

	end)

end


--// =========================================================
--// SCREEN GUI
--// =========================================================

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
--// =========================================================

local Frame =
	Instance.new(
		"Frame"
	)

Frame.Name =
	"Main"

Frame.Size =
	UDim2.fromOffset(
		210,
		116
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
--// =========================================================

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
--// =========================================================

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
	"⚡ SPEED ULTRA V6.1"

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
--// =========================================================

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
--// =========================================================

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
--// TOGGLE BUTTON
--// =========================================================

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
		72
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
--// =========================================================

local Status =
	Instance.new(
		"TextLabel"
	)

Status.Size =
	UDim2.fromOffset(
		110,
		27
	)

Status.Position =
	UDim2.fromOffset(
		100,
		72
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"INICIANDO..."

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
--// STATUS FUNCTIONS
--// =========================================================

local function SetStatus(
	text
)

	if not State.Alive then
		return
	end

	if not Status
		or not Status.Parent then

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
--// CHARACTER VALIDATION
--// =========================================================

local function ValidCharacter(
	character,
	generation,
	token
)

	if not State.Alive then
		return false
	end

	if Player.Character
		~= character then

		return false
	end

	if State.Character
		~= character then

		return false
	end

	if State.CharacterGeneration
		~= generation then

		return false
	end

	if State.PreparationToken
		~= token then

		return false
	end

	return true

end


--// =========================================================
--// RECOVERY CONTROL
--// =========================================================

local function CanRecover()

	local now =
		os.clock()

	if
		now - State.RecoveryWindowStart
		> Config.RECOVERY_WINDOW
	then

		State.RecoveryWindowStart =
			now

		State.RecoveryCount = 0

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

		State.RecoveryCount = 0

	end

	State.RecoveryCount += 1
	State.LastRecovery = now

end


--// =========================================================
--// CHARACTER CLEANUP
--// =========================================================

local function CleanupCharacter()

	DisconnectGroup(
		Connections.Character
	)

	State.Character = nil
	State.Humanoid = nil
	State.RootPart = nil
	State.OriginalWalkSpeed = nil

end


--// =========================================================
--// RESTORE ORIGINAL WALKSPEED
--// =========================================================

local function RestoreOriginalWalkSpeed()

	local humanoid =
		State.Humanoid

	local original =
		State.OriginalWalkSpeed

	if not humanoid
		or not humanoid.Parent then

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
--// APPLY WALKSPEED
--// =========================================================

local function ApplyWalkSpeed()

	if not State.Alive then
		return false
	end

	if not State.Enabled then
		return false
	end

	local humanoid =
		State.Humanoid

	if not humanoid
		or not humanoid.Parent then

		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local speed =
		NormalizeSpeed(
			State.TargetSpeed
		)

	if not speed then
		return false
	end

	if humanoid.WalkSpeed
		== speed then

		return true

	end

	local success =
		pcall(function()

			humanoid.WalkSpeed =
				speed

		end)

	if success then

		State.LastSpeedApply =
			os.clock()

	end

	return success

end


--// =========================================================
--// PREPARE CHARACTER
--//
--// isRecovery:
--// true  = reparação detectada pelo watchdog
--// false = nascimento normal / inicialização
--// =========================================================

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

	-- Não reconstruir um personagem que já está correto.
	if
		not isRecovery
		and character == State.Character
		and State.Humanoid
		and State.RootPart
	then

		return

	end

	if isRecovery then

		if not CanRecover() then

			SetStatus(
				"RECUPERAÇÃO LIMITADA"
			)

			return

		end

		RegisterRecovery()

	end

	-- IMPORTANTE:
	-- o estado Preparing fica TRUE antes do cleanup.
	State.Preparing = true

	State.CharacterGeneration += 1
	State.PreparationToken += 1

	local generation =
		State.CharacterGeneration

	local token =
		State.PreparationToken

	-- Cleanup NÃO altera Preparing.
	CleanupCharacter()

	State.Character =
		character

	SetStatus(
		"CARREGANDO..."
	)

	--// -----------------------------------------------------
	--// HUMANOID
	--// -----------------------------------------------------

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

		State.Preparing = false

		return

	end

	if not humanoid then

		State.Preparing = false

		SetStatus(
			"ERRO • HUMANOID"
		)

		return

	end

	-- Salva a velocidade original ANTES de alterar.
	State.OriginalWalkSpeed =
		humanoid.WalkSpeed

	--// -----------------------------------------------------
	--// ROOTPART
	--// -----------------------------------------------------

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

		State.Preparing = false

		return

	end

	if not root then

		State.Preparing = false

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
	--// WALKSPEED PROPERTY WATCH
	--// -----------------------------------------------------

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

				if humanoid.WalkSpeed
					~= State.TargetSpeed then

					ApplyWalkSpeed()

				end

			end
		)
	)

	--// -----------------------------------------------------
	--// DEATH
	--// -----------------------------------------------------

	SetConnection(
		Connections.Character,
		"Died",

		humanoid.Died:Connect(
			function()

				if State.Alive then

					SetStatus(
						"MORTO • AGUARDANDO"
					)

				end

			end
		)
	)

	--// -----------------------------------------------------
	--// OPTIONAL OBJECT PHYSICS
	--// -----------------------------------------------------
	--
	-- Mantido separado do caminho principal.
	-- Não roda por padrão.
	-- -----------------------------------------------------

	if Config.ENABLE_OBJECT_PHYSICS then

		for _, object in
			ipairs(
				character:GetDescendants()
			) do

			if object:IsA(
				"BasePart"
			) then

				local name =
					string.lower(
						object.Name
					)

				if
					string.find(
						name,
						"egg",
						1,
						true
					)

					or

					string.find(
						name,
						"ovo",
						1,
						true
					)
				then

					pcall(function()

						object.Massless =
							true

					end)

				end

			end

		end

	end

	--// -----------------------------------------------------
	--// APLICAÇÃO INICIAL
	--// -----------------------------------------------------

	if State.Enabled
		and Config.LOCK_WALKSPEED then

		ApplyWalkSpeed()

	end

	-- Última validação antes de liberar o estado.
	if ValidCharacter(
		character,
		generation,
		token
	) then

		State.Preparing =
			false

		RefreshStatus()

		Debug(
			"Personagem preparado:",
			character.Name,
			"geração:",
			generation
		)

	else

		State.Preparing =
			false

	end

end


--// =========================================================
--// SPEED INPUT
--// =========================================================

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

	local numeric =
		tonumber(text)

	local normalized =
		NormalizeSpeed(numeric)

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

	if State.Enabled
		and Config.LOCK_WALKSPEED then

		ApplyWalkSpeed()

	end

	RefreshStatus()

end


--// =========================================================
--// TOGGLE
--// =========================================================

local function ToggleSystem()

	if not State.Alive then
		return
	end

	State.Enabled =
		not State.Enabled

	if State.Enabled then

		Toggle.Text =
			"SISTEMA: ON"

		ApplyWalkSpeed()

	else

		Toggle.Text =
			"SISTEMA: OFF"

		-- Correção importante:
		-- ao desligar, volta à velocidade original.
		RestoreOriginalWalkSpeed()

	end

	RefreshStatus()

end


--// =========================================================
--// BUTTONS
--// =========================================================

SetConnection(
	Connections.Global,
	"ApplyButton",

	ApplyButton.Activated:Connect(
		function()

			SetTargetSpeed()

		end
	)
)


SetConnection(
	Connections.Global,
	"FocusLost",

	SpeedBox.FocusLost:Connect(
		function()

			SetTargetSpeed()

		end
	)
)


SetConnection(
	Connections.Global,
	"Toggle",

	Toggle.Activated:Connect(
		function()

			ToggleSystem()

		end
	)
)


--// =========================================================
--// HYBRID PHYSICS
--// =========================================================

local function PhysicsAssist(
	deltaTime
)

	if Config.MOVEMENT_MODE
		~= "Hybrid" then

		return

	end

	if not State.Alive
		or not State.Enabled then

		return

	end

	local humanoid =
		State.Humanoid

	local root =
		State.RootPart

	if not humanoid
		or not root then

		return

	end

	if not humanoid.Parent
		or not root.Parent then

		return

	end

	if humanoid.Health <= 0
		or root.Anchored then

		return

	end

	local currentVelocity =
		root.AssemblyLinearVelocity

	if not IsFiniteVector3(
		currentVelocity
	) then

		State.InvalidVelocityCount += 1

		pcall(function()

			root.AssemblyLinearVelocity =
				Vector3.zero

		end)

		return

	end

	if not IsFiniteNumber(
		deltaTime
	) then

		return

	end

	local dt =
		math.clamp(
			deltaTime,
			0,
			Config.MAX_DELTA_TIME
		)

	local moveVelocity =
		humanoid:GetMoveVelocity()

	if not IsFiniteVector3(
		moveVelocity
	) then

		return

	end

	local currentX =
		currentVelocity.X

	local currentZ =
		currentVelocity.Z

	local horizontal =
		math.sqrt(
			currentX * currentX
			+
			currentZ * currentZ
		)

	-- Limite contra aceleração absurda.
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

	--// -----------------------------------------------------
	--// ACELERAÇÃO
	--// -----------------------------------------------------

	if
		math.abs(targetX)
		> 0.001

		or

		math.abs(targetZ)
		> 0.001

	then

		local alpha =
			1 - math.exp(
				-Config.ACCELERATION
				* dt
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

		if
			math.abs(
				newX - currentVelocity.X
			) > 0.05

			or

			math.abs(
				newZ - currentVelocity.Z
			) > 0.05
		then

			local success =
				pcall(function()

					root.AssemblyLinearVelocity =
						Vector3.new(
							newX,
							currentVelocity.Y,
							newZ
						)

				end)

			if success then
				State.PhysicsWrites += 1
			end

		end

	else

		--// -------------------------------------------------
		--// DESACELERAÇÃO
		--// -------------------------------------------------

		local alpha =
			1 - math.exp(
				-Config.DECELERATION
				* dt
			)

		local newX =
			currentX
			+
			(0 - currentX)
			* alpha

		local newZ =
			currentZ
			+
			(0 - currentZ)
			* alpha

		if
			math.abs(
				newX - currentVelocity.X
			) > 0.05

			or

			math.abs(
				newZ - currentVelocity.Z
			) > 0.05
		then

			local success =
				pcall(function()

					root.AssemblyLinearVelocity =
						Vector3.new(
							newX,
							currentVelocity.Y,
							newZ
						)

				end)

			if success then
				State.PhysicsWrites += 1
			end

		end

	end

	State.LastPhysicsStep =
		os.clock()

end


--// =========================================================
--// PRE SIMULATION
--//
--// CORREÇÃO DE OTIMIZAÇÃO:
--// só conectamos este evento se Hybrid estiver ativo.
--// =========================================================

if Config.MOVEMENT_MODE
	== "Hybrid"
then

	SetConnection(
		Connections.Global,
		"PreSimulation",

		RunService.PreSimulation:Connect(
			function(deltaTime)

				PhysicsAssist(
					deltaTime
				)

			end
		)
	)

end


--// =========================================================
--// CHARACTER ADDED
--// =========================================================

SetConnection(
	Connections.Global,
	"CharacterAdded",

	Player.CharacterAdded:Connect(
		function(character)

			if not State.Alive then
				return
			end

			-- task.defer reduz espera desnecessária
			-- e deixa a nova árvore do personagem iniciar.
			task.defer(
				function()

					if not State.Alive then
						return
					end

					if character
						~= Player.Character then

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
--// =========================================================

SetConnection(
	Connections.Global,
	"CharacterRemoving",

	Player.CharacterRemoving:Connect(
		function(character)

			if character
				== State.Character then

				-- Invalida imediatamente qualquer
				-- preparação antiga.
				State.CharacterGeneration += 1
				State.PreparationToken += 1

				CleanupCharacter()

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
--//
--// Não usa Heartbeat.
--// É periódico e portanto executado apenas
--// quando realmente necessário.
--// =========================================================

local function Watchdog()

	if not State.Alive then
		return
	end

	local character =
		Player.Character

	--// ---------------------------------------------
	--// SEM PERSONAGEM
	--// ---------------------------------------------

	if not character then

		if State.Character then

			CleanupCharacter()

		end

		RefreshStatus()

		return

	end

	--// ---------------------------------------------
	--// PERSONAGEM TROCADO
	--// ---------------------------------------------

	if character
		~= State.Character then

		if not State.Preparing then

			PrepareCharacter(
				character,
				false
			)

		end

		return

	end

	--// ---------------------------------------------
	--// HUMANOID PERDIDO
	--// ---------------------------------------------

	if not State.Humanoid
		or not State.Humanoid.Parent then

		if not State.Preparing then

			PrepareCharacter(
				character,
				true
			)

		end

		return

	end

	--// ---------------------------------------------
	--// ROOT PERDIDO
	// ---------------------------------------------

	if not State.RootPart
		or not State.RootPart.Parent then

		if not State.Preparing then

			PrepareCharacter(
				character,
				true
			)

		end

		return

	end

	--// ---------------------------------------------
	--// WALKSPEED
	// ---------------------------------------------

	if State.Enabled
		and Config.LOCK_WALKSPEED
		and State.Humanoid.Health > 0
	then

		if State.Humanoid.WalkSpeed
			~= State.TargetSpeed then

			ApplyWalkSpeed()

		end

	end

end


--// =========================================================
--// WATCHDOG THREAD
--// =========================================================

task.spawn(
	function()

		while State.Alive do

			task.wait(
				Config.WATCHDOG_INTERVAL
			)

			if State.Alive then

				local success,
					errorMessage =
					pcall(
						Watchdog
					)

				if not success then

					Debug(
						"Watchdog:",
						errorMessage
					)

				end

			end

		end

	end
)


--// =========================================================
--// CAMERA LIMITS
--// =========================================================

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

	if not IsFiniteNumber(x)
		or not IsFiniteNumber(y)
	then

		return 25, 200

	end

	local maxX, maxY =
		GetPanelLimits()

	if not maxX
		or not maxY then

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
		or not Frame.Parent then

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
--// =========================================================

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
--// DRAG MOVE
--// =========================================================

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

			local position =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)

			local delta =
				position
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
--// DRAG END
--// =========================================================

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
--// CAMERA BIND
--// =========================================================

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
			function()

				RepositionPanel()

			end
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
		function()

			BindCamera()

		end
	)
)

BindCamera()


--// =========================================================
--// MISPREDICTION DIAGNOSTIC
--//
--// Apenas contador.
--// Não tenta contrariar a autoridade do servidor.
--// =========================================================

if Config.DIAGNOSTICS then

	pcall(function()

		SetConnection(
			Connections.Global,
			"Misprediction",

			RunService.Misprediction:Connect(
				function()

					if State.Alive then

						State.MispredictionCount += 1

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
--// SHUTDOWN
--// =========================================================

local function Shutdown()

	if not State.Alive then
		return
	end

	State.Alive =
		false

	-- Invalida callbacks antigos.
	State.CharacterGeneration += 1
	State.PreparationToken += 1

	State.Preparing =
		false

	-- Restaura a velocidade antes de eliminar
	-- a referência do Humanoid.
	RestoreOriginalWalkSpeed()

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

	State.OriginalWalkSpeed =
		nil

	State.Dragging =
		false

	if ScreenGui then

		pcall(function()

			ScreenGui:Destroy()

		end)

	end

	Debug(
		"Speed Ultra V6.1 encerrado."
	)

end


--// =========================================================
--// SCRIPT DESTROY
--// =========================================================

if script then

	pcall(function()

		script.Destroying:Connect(
			Shutdown
		)

	end)

end


--// =========================================================
--// START
--// =========================================================

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

Debug(
	"Speed Ultra V6.1 iniciado."
)
