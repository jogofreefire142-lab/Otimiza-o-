-- SERVIÇOS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer

-- CRIANDO A INTERFACE GRÁFICA SEGURA
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeOvo"
screenGui.ResetOnSpawn = false

-- Fallback de Parent para funcionar em todos os executores mobiles
local pcallSucesso = pcall(function()
	screenGui.Parent = CoreGui
end)
if not pcallSucesso or not screenGui.Parent then
	screenGui.Parent = jogador:WaitForChild("PlayerGui")
end

-- Janela Principal (Compacta para Celular)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.1, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

-- Título
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -25, 0, 25)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ VELOCIDADE EXTRA"
titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 13
titulo.Parent = frame

-- Campo de Texto para digitar o número
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 32)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "50" -- Sugestão de velocidade rápida
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

-- Botão de Ativar / Mudar
local botaoVelocidade = Instance.new("TextButton")
botaoVelocidade.Size = UDim2.new(0, 80, 0, 30)
botaoVelocidade.Position = UDim2.new(0, 90, 0, 32)
botaoVelocidade.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
botaoVelocidade.BorderSizePixel = 0
botaoVelocidade.Text = "DEFINIR"
botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoVelocidade.Font = Enum.Font.SourceSansBold
botaoVelocidade.TextSize = 13
botaoVelocidade.Parent = frame

local botaoCorner = Instance.new("UICorner")
botaoCorner.CornerRadius = UDim.new(0, 5)
botaoCorner.Parent = botaoVelocidade

-- Botão de Minimizar (Ideal para não atrapalhar no celular)
local botaoMinimizar = Instance.new("TextButton")
botaoMinimizar.Size = UDim2.new(0, 20, 0, 20)
botaoMinimizar.Position = UDim2.new(1, -25, 0, 3)
botaoMinimizar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
botaoMinimizar.Text = "-"
botaoMinimizar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMinimizar.Font = Enum.Font.SourceSansBold
botaoMinimizar.TextSize = 14
botaoMinimizar.Parent = frame

local minimizarCorner = Instance.new("UICorner")
minimizarCorner.CornerRadius = UDim.new(1, 0)
minimizarCorner.Parent = botaoMinimizar

local minimizado = false
botaoMinimizar.MouseButton1Click:Connect(function()
	minimizado = not minimizado
	if minimizado then
		frame.Size = UDim2.new(0, 180, 0, 25)
		caixaVelocidade.Visible = false
		botaoVelocidade.Visible = false
		botaoMinimizar.Text = "+"
		botaoMinimizar.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	else
		frame.Size = UDim2.new(0, 180, 0, 75)
		caixaVelocidade.Visible = true
		botaoVelocidade.Visible = true
		botaoMinimizar.Text = "-"
		botaoMinimizar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end)

-- CONFIGURAÇÃO DO LOOP FORÇADO DE VELOCIDADE
local velocidadeAtiva = 16 -- Valor inicial padrão do jogo

botaoVelocidade.MouseButton1Click:Connect(function()
	local valor = tonumber(caixaVelocidade.Text)
	if valor then
		velocidadeAtiva = valor
		
		-- Pisca o botão em branco para confirmar o clique no celular
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)
		task.wait(0.1)
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		caixaVelocidade.Text = "Erro: Números"
		task.wait(1)
		caixaVelocidade.Text = tostring(velocidadeAtiva)
	end
end)

-- Este loop roda a cada frame do jogo (Heartbeat) garantindo que nada tire sua velocidade
RunService.Heartbeat:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed ~= velocidadeAtiva then
			humanoid.WalkSpeed = velocidadeAtiva
		end
	end
end)

-- SISTEMA DE ARRASTAR VIA TOUCH (CELULAR) E MOUSE (PC)
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end)
