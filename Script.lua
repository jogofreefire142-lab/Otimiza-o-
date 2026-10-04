-- ESPERA O JOGO CARREGAR TOTALMENTE
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- SERVIÇOS UNIVERSAIS DO ROBLOX
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 20)

-- INSTÂNCIA UNIVERSAL DA INTERFACE
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadePosicaoFix"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Janela Principal (Começa no Canto Esquerdo)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.35, 0) -- Posição 1
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
titulo.Text = "⚡ SPEED HYPER v12"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 11
titulo.Parent = frame

-- Campo de Texto (Configurado direto no seu valor ideal manual)
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "255" -- Valor salvo na memória para carregar os itens
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

-- 📱 BOTÃO DE MOVER A ABA DE LUGAR AUTOMATICAMENTE (Substitui o arrastar que bugava)
local botaoMover = Instance.new("TextButton")
botaoMover.Size = UDim2.new(0, 18, 0, 18)
botaoMover.Position = UDim2.new(1, -23, 0, 5)
botaoMover.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
botaoMover.Text = "M"
botaoMoverMoverTextColor3 = Color3.fromRGB(255, 255, 255)
botaoMover.Font = Enum.Font.SourceSansBold
botaoMover.TextSize = 11
botaoMover.Parent = frame

local moverCorner = Instance.new("UICorner")
moverCorner.CornerRadius = UDim.new(1, 0)
moverCorner.Parent = botaoMover

-- Tabela com as posições ideais da tela para não tampar os controles do celular
local posicoes = {
	UDim2.new(0.05, 0, 0.35, 0), -- 1: Esquerda Centro
	UDim2.new(1, -195, 0.15, 0), -- 2: Direita Superior
	UDim2.new(1, -195, 0.65, 0), -- 3: Direita Inferior
	UDim2.new(0.05, 0, 0.15, 0)  -- 4: Esquerda Superior
}
local posicaoAtual = 1

botaoMover.MouseButton1Click:Connect(function()
	posicaoAtual = posicaoAtual + 1
	if posicaoAtual > #posicoes then
		posicaoAtual = 1
	end
	frame.Position = posicoes[posicaoAtual] -- Faz a janela pular pro canto certo na hora
end)

-- =======================================================
-- 🔥 MOVIMENTAÇÃO FISICA E SISTEMA DE FREIO ANTIDESLIZE
-- =======================================================
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

RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart then
			humanoid.WalkSpeed = math.clamp(velocidadeAlvo, 16, 32)
			
			if velocidadeAlvo > 32 then
				if humanoid.MoveDirection.Magnitude > 0 then
					local direcao = humanoid.MoveDirection
					rootPart.AssemblyLinearVelocity = Vector3.new(
						direcao.X * velocidadeAlvo,
						rootPart.AssemblyLinearVelocity.Y, 
						direcao.Z * velocidadeAlvo
					)
				else
					rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
				end
			end
		end
	end
end)
