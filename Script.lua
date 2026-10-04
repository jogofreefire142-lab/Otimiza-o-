if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.3)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

local antigo = PlayerGui:FindFirstChild("PainelVelocidadeDefinitivo2026")
if antigo then
	antigo:Destroy()
end

local personagemAtual
local humanoideAtual
local rootPartAtual

local velocidadeAlvo = 255
local velocidadeAtiva = true

local conexaoWalkSpeed
local conexaoDescendente
local conexaoMovimento
local conexaoPersonagem

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
linhaCima.BorderSizePixel = 0
linhaCima.Parent = frame

local linhaCorner = Instance.new("UICorner")
linhaCorner.CornerRadius = UDim.new(0, 8)
linhaCorner.Parent = linhaCima

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED ULTRA v2026"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "255"
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

local botaoVelocidade = Instance.new("TextButton")
botaoVelocidade.Size = UDim2.new(0, 80, 0, 30)
botaoVelocidade.Position = UDim2.new(0, 90, 0, 35)
botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
botaoVelocidade.BorderSizePixel = 0
botaoVelocidade.Text = "TRAVAR VEL."
botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoVelocidade.Font = Enum.Font.SourceSansBold
botaoVelocidade.TextSize = 12
botaoVelocidade.Parent = frame

local botaoCorner = Instance.new("UICorner")
botaoCorner.CornerRadius = UDim.new(0, 5)
botaoCorner.Parent = botaoVelocidade

local function limparConexoes()
	if conexaoWalkSpeed then
		conexaoWalkSpeed:Disconnect()
		conexaoWalkSpeed = nil
	end

	if conexaoDescendente then
		conexaoDescendente:Disconnect()
		conexaoDescendente = nil
	end
end

local function aplicarVelocidade()
	if not velocidadeAtiva then
		return
	end

	local hum = humanoideAtual

	if hum and hum.Parent then
		if hum.WalkSpeed ~= velocidadeAlvo then
			hum.WalkSpeed = velocidadeAlvo
		end
	end
end

local function prepararPersonagem(personagem)
	limparConexoes()

	personagemAtual = personagem
	humanoideAtual = personagem:WaitForChild("Humanoid", 15)
	rootPartAtual = personagem:WaitForChild("HumanoidRootPart", 15)

	if not humanoideAtual or not rootPartAtual then
		return
	end

	aplicarVelocidade()

	conexaoWalkSpeed = humanoideAtual:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if velocidadeAtiva then
			aplicarVelocidade()
		end
	end)

	conexaoDescendente = personagem.DescendantAdded:Connect(function(objeto)
		if objeto:IsA("Humanoid") and objeto ~= humanoideAtual then
			humanoideAtual = objeto
			aplicarVelocidade()
		end
	end)
end

botaoVelocidade.Activated:Connect(function()
	local valor = tonumber(caixaVelocidade.Text)

	if valor
		and valor == valor
		and valor ~= math.huge
		and valor ~= -math.huge then

		velocidadeAlvo = math.clamp(valor, 0, 1000)
		caixaVelocidade.Text = tostring(velocidadeAlvo)
		velocidadeAtiva = not velocidadeAtiva

		if velocidadeAtiva then
			botaoVelocidade.Text = "TRAVAR VEL."
			aplicarVelocidade()
		else
			botaoVelocidade.Text = "ATIVAR VEL."
		end

		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)

		task.delay(0.08, function()
			if botaoVelocidade and botaoVelocidade.Parent then
				if velocidadeAtiva then
					botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
					botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					botaoVelocidade.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

conexaoPersonagem = jogador.CharacterAdded:Connect(function(novoPersonagem)
	task.wait(0.15)
	prepararPersonagem(novoPersonagem)
end)

if jogador.Character then
	prepararPersonagem(jogador.Character)
end

conexaoMovimento = RunService.PreSimulation:Connect(function(deltaTime)
	local hum = humanoideAtual
	local root = rootPartAtual

	if not velocidadeAtiva then
		return
	end

	if not hum
		or not root
		or not hum.Parent
		or not root.Parent then
		return
	end

	if hum.WalkSpeed ~= velocidadeAlvo then
		hum.WalkSpeed = velocidadeAlvo
	end

	local direcao = hum.MoveDirection

	if direcao.Magnitude > 0 then
		local direcaoUnit = direcao.Unit
		local atual = root.AssemblyLinearVelocity
		local alvoX = direcaoUnit.X * velocidadeAlvo
		local alvoZ = direcaoUnit.Z * velocidadeAlvo

		local suavizacao = 1 - math.exp(-50 * math.max(deltaTime, 0))

		root.AssemblyLinearVelocity = Vector3.new(
			atual.X + (alvoX - atual.X) * suavizacao,
			atual.Y,
			atual.Z + (alvoZ - atual.Z) * suavizacao
		)
	else
		local atual = root.AssemblyLinearVelocity
		local suavizacaoParada = 1 - math.exp(-12 * math.max(deltaTime, 0))

		root.AssemblyLinearVelocity = Vector3.new(
			atual.X + (0 - atual.X) * suavizacaoParada,
			atual.Y,
			atual.Z + (0 - atual.Z) * suavizacaoParada
		)
	end
end)

local arrastando = false
local toqueInicial = Vector2.zero
local posicaoInicial = frame.Position
local inputArraste

titulo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then

		arrastando = true
		inputArraste = input

		toqueInicial = Vector2.new(
			input.Position.X,
			input.Position.Y
		)

		posicaoInicial = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not arrastando then
		return
	end

	if inputArraste
		and inputArraste.UserInputType == Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then

		local diferencaX = input.Position.X - toqueInicial.X
		local diferencaY = input.Position.Y - toqueInicial.Y

		frame.Position = UDim2.new(
			posicaoInicial.X.Scale,
			posicaoInicial.X.Offset + diferencaX,
			posicaoInicial.Y.Scale,
			posicaoInicial.Y.Offset + diferencaY
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == inputArraste
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		arrastando = false
		inputArraste = nil
	end
end)
``` [❶](code://python)
