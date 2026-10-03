-- SERVIÇOS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer

-- INSTÂNCIA ANTICRASH DA INTERFACE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadePro"
screenGui.ResetOnSpawn = false

local pcallSucesso = pcall(function()
	screenGui.Parent = CoreGui
end)
if not pcallSucesso or not screenGui.Parent then
	screenGui.Parent = jogador:WaitForChild("PlayerGui")
end

-- Janela Principal Moderna e Compacta
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.1, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

-- Linha Estilizada Superior (Visual Hacker)
local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
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
titulo.Text = "⚡ BYPASS SPEED v3"
titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 13
titulo.Parent = frame

-- Campo de Texto Inteligente
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
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

-- Botão de Ativar Premium
local botaoVelocidade = Instance.new("TextButton")
botaoVelocidade.Size = UDim2.new(0, 80, 0, 30)
botaoVelocidade.Position = UDim2.new(0, 90, 0, 35)
botaoVelocidade.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
botaoVelocidade.BorderSizePixel = 0
botaoVelocidade.Text = "FORÇAR"
botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoVelocidade.Font = Enum.Font.SourceSansBold
botaoVelocidade.TextSize = 13
botaoVelocidade.Parent = frame

local botaoCorner = Instance.new("UICorner")
botaoCorner.CornerRadius = UDim.new(0, 5)
botaoCorner.Parent = botaoVelocidade

-- Botão Minimizar Redondo
local botaoMinimizar = Instance.new("TextButton")
botaoMinimizar.Size = UDim2.new(0, 18, 0, 18)
botaoMinimizar.Position = UDim2.new(1, -23, 0, 6)
botaoMinimizar.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
botaoMinimizar.Text = "-"
botaoMinimizar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMinimizar.Font = Enum.Font.SourceSansBold
botaoMinimizar.TextSize = 12
botaoMinimizar.Parent = frame

local minimizarCorner = Instance.new("UICorner")
minimizarCorner.CornerRadius = UDim.new(1, 0)
minimizarCorner.Parent = botaoMinimizar

local minimizado = false
botaoMinimizar.MouseButton1Click:Connect(function()
	minimizado = not minimizado
	if minimizado then
		frame.Size = UDim2.new(0, 180, 0, 28)
		caixaVelocidade.Visible = false
		botaoVelocidade.Visible = false
		botaoMinimizar.Text = "+"
		botaoMinimizar.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
	else
		frame.Size = UDim2.new(0, 180, 0, 75)
		caixaVelocidade.Visible = true
		botaoVelocidade.Visible = true
		botaoMinimizar.Text = "-"
		botaoMinimizar.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

-- CONTROLE LOGÍCO DA VELOCIDADE MESTRE
local velocidadeAlvo = 16

botaoVelocidade.MouseButton1Click:Connect(function()
	local num = tonumber(caixaVelocidade.Text)
	if num then
		velocidadeAlvo = num
		
		-- Feedback Visual (Efeito Flash de Confirmação)
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)
		task.wait(0.08)
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
		botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

-- SISTEMA BYPASS: ENGANA O ANTI-CHEAT DO JOGO (Metatable Hooking)
-- Se o executor suportar gmt/hookmetamethod, ele esconde a velocidade real contra scripts do servidor.
local clonarMetatabela = getrawmetatable or debug.getmetatable
if clonarMetatabela then
	local metatabela = clonarMetatabela(game)
	if setreadonly then setreadonly(metatabela, false) end
	
	local indexAntigo = metatabela.__index
	metatabela.__index = newcclosure(function(tabela, propriedade)
		if tostring(tabela) == "Humanoid" and propriedade == "WalkSpeed" then
			return 16 -- Sempre finge para o jogo que a velocidade é a padrão
		end
		return indexAntigo(tabela, propriedade)
	end)
end

-- LOOP DE ALTA PRECISÃO (Roda antes da renderização física do cenário)
RunService.PreSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Forçagem direta sem trancar a física do boneco
			if humanoid.WalkSpeed ~= velocidadeAlvo then
				humanoid.WalkSpeed = velocidadeAlvo
			end
		end
	end
end)

-- ARRASTAR ADAPTADO PARA MOBILE (Touch Inteligente que não desliza sozinho)
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
	if input == inputArrastar and arrastando then
		atualizarPosicao(input)
	end
end)
