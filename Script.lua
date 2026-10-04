-- ESPERA O JOGO CARREGAR TOTALMENTE
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- SERVIÇOS UNIVERSAIS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 20)

-- INSTÂNCIA UNIVERSAL DA INTERFACE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeUltra"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Janela Principal
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
titulo.Size = UDim2.new(1, -30, 0, 25)
titulo.Position = UDim2.new(0, 5, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED HYPER v7"
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
caixaVelocidade.Text = "255" -- Configurado com o seu valor ideal automaticamente!
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

-- MINI BOTÃO DE MINIMIZAR
local botaoMinimizar = Instance.new("TextButton")
botaoMinimizar.Size = UDim2.new(0, 18, 0, 18)
botaoMinimizar.Position = UDim2.new(1, -23, 0, 5)
botaoMinimizar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
botaoMinimizar.Text = "-"
botaoMinimizar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMinimizar.Font = Enum.Font.SourceSansBold
botaoMinimizar.TextSize = 12
botaoMinimizar.Parent = frame

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(1, 0)
miniCorner.Parent = botaoMinimizar

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
		botaoMinimizar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	end
end)

-- 🛡️ SISTEMA CALIBRADO PARA FORÇA BRUTA (250+)
local velocidadeAlvo = 16

botaoVelocidade.MouseButton1Click:Connect(function()
	local num = tonumber(caixaVelocidade.Text)
	if num then
		velocidadeAlvo = num
		
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)
		task.wait(0.08)
		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
		botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

-- LOOP ADAPTADO DE POST-SIMULATION PARA EVITAR O TELEPORTE DO ROBLOX
RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart then
			-- Força WalkSpeed nativo baixo para o anti-cheat do jogo ler valores menores e não puxar
			humanoid.WalkSpeed = math.clamp(velocidadeAlvo, 16, 32)
			
			-- Se estiver se movendo, injeta a velocidade monstruosa direto no vetor de física linear
			if humanoid.MoveDirection.Magnitude > 0 and velocidadeAlvo > 32 then
				local direcao = humanoid.MoveDirection
				-- Aplica o valor real (Ex: 250 ou 260) diretamente nos eixos X e Z, travando o Y para não bugar no chão
				rootPart.AssemblyLinearVelocity = Vector3.new(
					direcao.X * velocidadeAlvo,
					rootPart.AssemblyLinearVelocity.Y, 
					direcao.Z * velocidadeAlvo
				)
			end
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
