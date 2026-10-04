-- ESPERA O JOGO CARREGAR TOTALMENTE PARA EVITAR ERROS DE INJEÇÃO
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- SERVIÇOS UNIVERSAIS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 15)

-- INSTÂNCIA ANTICRASH DA INTERFACE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelMobileInfinito"
screenGui.ResetOnSpawn = false

-- Filtro de compatibilidade para injetar sem dar erro nos executores de celular
local pcallSucesso = pcall(function()
	screenGui.Parent = CoreGui
end)
if not pcallSucesso or not screenGui.Parent then
	screenGui.Parent = PlayerGui
end

-- Janela Principal (Desenhada para o Touch do Celular)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.1, 0, 0.4, 0)
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

-- Título (Área do Toque para arrastar)
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED PRO MOBILE"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

-- Campo de Texto (Configuração manual salva em 255)
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

-- Botão Forçar
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

-- ⚙️ LÓGICA DE VELOCIDADE COMPATÍVEL E ULTRA-LEVE (Com Freio)
local velocidadeAlvo = 16
local conexaoMudanca = nil

local function travarHumanoid(humanoid)
	if conexaoMudanca then conexaoMudanca:Disconnect() end
	humanoid.WalkSpeed = math.clamp(velocidadeAlvo, 16, 32)
	
	conexaoMudanca = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed ~= math.clamp(velocidadeAlvo, 16, 32) then
			humanoid.WalkSpeed = math.clamp(velocidadeAlvo, 16, 32)
		end
	end)
end

jogador.CharacterAdded:Connect(function(personagem)
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	if humanoid then
		task.wait(0.3)
		travarHumanoid(humanoid)
	end
end)

botaoVelocidade.MouseButton1Click:Connect(function()
	local num = tonumber(caixaVelocidade.Text)
	if num then
		velocidadeAlvo = num
		local personagem = jogador.Character
		if personagem then
			local humanoid = personagem:FindFirstChildOfClass("Humanoid")
			if humanoid then travarHumanoid(humanoid) end
		end
		
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)
		task.wait(0.08)
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
		botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

-- SISTEMA DE MOVIMENTAÇÃO COM FREIO SECO (Para velocidades brutas de 250-260)
RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and velocidadeAlvo > 32 then
			if humanoid.MoveDirection.Magnitude > 0 then
				local direcao = humanoid.MoveDirection
				rootPart.AssemblyLinearVelocity = Vector3.new(
					direcao.X * velocidadeAlvo,
					rootPart.AssemblyLinearVelocity.Y, 
					direcao.Z * velocidadeAlvo
				)
			else
				-- Freia na hora sem deixar patinar com o ovo grande
				rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
			end
		end
	end
end)

if jogador.Character then
	local hum = jogador.Character:FindFirstChildOfClass("Humanoid")
	if hum then travarHumanoid(hum) end
end

-- 📱 SISTEMA DE ARRASTO INTELIGENTE COMPATÍVEL COM TOQUE EM CELULAR
local arrastando = false
local toqueInicial = Vector2.new(0, 0)
local posicaoInicial = frame.Position

titulo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = true
		toqueInicial = Vector2.new(input.Position.X, input.Position.Y)
		posicaoInicial = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = false
	end
end)
