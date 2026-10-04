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
screenGui.Name = "PainelVelocidadeFinalFix"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Janela Principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.4, 0) -- Esquerda por padrão
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
titulo.Size = UDim2.new(1, -50, 0, 25)
titulo.Position = UDim2.new(0, 5, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED HYPER v10"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 11
titulo.Parent = frame

-- Campo de Texto
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

-- BOTÕES DE MUDAR A ABA DE LADO (Perfeitos para celular)
local botaoMoverEsquerda = Instance.new("TextButton")
local botaoMoverDireita = Instance.new("TextButton")

botaoMoverEsquerda.Size = UDim2.new(0, 16, 0, 16)
botaoMoverEsquerda.Position = UDim2.new(1, -42, 0, 6)
botaoMoverEsquerda.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
botaoMoverEsquerda.Text = "<"
botaoMoverEsquerda.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMoverEsquerda.Font = Enum.Font.SourceSansBold
botaoMoverEsquerda.TextSize = 11
botaoMoverEsquerda.Parent = frame
local esqCorner = Instance.new("UICorner") esqCorner.CornerRadius = UDim.new(0, 4) esqCorner.Parent = botaoMoverEsquerda

botaoMoverDireita.Size = UDim2.new(0, 16, 0, 16)
botaoMoverDireita.Position = UDim2.new(1, -24, 0, 6)
botaoMoverDireita.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
botaoMoverDireita.Text = ">"
botaoMoverDireita.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMoverDireita.Font = Enum.Font.SourceSansBold
botaoMoverDireita.TextSize = 11
botaoMoverDireita.Parent = frame
local dirCorner = Instance.new("UICorner") dirCorner.CornerRadius = UDim.new(0, 4) dirCorner.Parent = botaoMoverDireita

botaoMoverEsquerda.MouseButton1Click:Connect(function()
	frame.Position = UDim2.new(0.05, 0, 0.4, 0)
end)

botaoMoverDireita.MouseButton1Click:Connect(function()
	frame.Position = UDim2.new(1, -195, 0.4, 0)
end)

-- LOGICA DE COMPORTAMENTO DA VELOCIDADE
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

-- 🔥 SISTEMA DE MOVIMENTAÇÃO COM FREIO INSTANTÂNEO ANTIDESLIZE
RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart then
			humanoid.WalkSpeed = math.clamp(velocidadeAlvo, 16, 32)
			
			if velocidadeAlvo > 32 then
				if humanoid.MoveDirection.Magnitude > 0 then
					-- EMPURRÃO ATIVO: Jogador está correndo
					local direcao = humanoid.MoveDirection
					rootPart.AssemblyLinearVelocity = Vector3.new(
						direcao.X * velocidadeAlvo,
						rootPart.AssemblyLinearVelocity.Y, 
						direcao.Z * velocidadeAlvo
					)
				else
					-- FREIO ATIVADO: Jogador soltou o analógico, zera a força X e Z na hora para não deslizar
					rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
				end
			end
		end
	end
end)
