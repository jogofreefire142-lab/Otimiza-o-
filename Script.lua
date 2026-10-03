-- ESPERA O JOGO CARREGAR TOTALMENTE NO CELULAR DELE
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(1) -- Pausa de segurança para o Delta processar a injeção

-- SERVIÇOS UNIVERSAIS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 20)
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer

-- INSTÂNCIA UNIVERSAL DA INTERFACE (Injeta direto no PlayerGui para evitar bugs no Delta Mobile)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDeltaFix"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Janela Principal (Idêntica à versão que você gostou)
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

-- Título
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -25, 0, 25)
titulo.Position = UDim2.new(0, 5, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ BYPASS INDESTRUTÍVEL"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

-- Campo de Texto
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "60"
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

-- LÓGICA DE VELOCIDADE TRAVADA
local velocidadeAlvo = 16
local conexaoMudanca = nil

local function travarHumanoid(humanoid)
	if conexaoMudanca then conexaoMudanca:Disconnect() end
	humanoid.WalkSpeed = velocidadeAlvo
	
	conexaoMudanca = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed ~= velocidadeAlvo then
			humanoid.WalkSpeed = velocidadeAlvo
		end
	end)
end

jogador.CharacterAdded:Connect(function(personagem)
	local humanoid = personagem:WaitForChild("Humanoid", 10)
	if humanoid then
		task.wait(0.2)
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

RunService.PreRender:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed ~= velocidadeAlvo then
			humanoid.WalkSpeed = velocidadeAlvo
		end
	end
end)

if jogador.Character then
	local hum = jogador.Character:FindFirstChildOfClass("Humanoid")
	if hum then travarHumanoid(hum) end
end

-- ARRASTAR MOBILE / TOUCH
local arrastando, inputArrastar, inicioArrastar, posicaoInicial
local function atualizarPosicao(input)
	local diferenca = input.Position - inicioArrastar
	frame.Position = UDim2.new(posicaoInicial.X.Scale, posicaoInicial.X.Offset + diferenca.X, posicaoInicial.Y.Scale, posicaoInicial.Y.Offset + diferenca.Y)
end

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = true
		inicioArrastar = input.Position
		posicaoInicial = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then arrastando = false end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		inputArrastar = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == inputArrastar and arrastando then atualizarPosicao(input) end
end)
