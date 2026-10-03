-- SERVIÇOS DO ROBLOX
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local jogador = Players.LocalPlayer

-- INSTÂNCIA SEGURA DA INTERFACE (Evita crash em executores mobiles)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelUniversalOvo"
screenGui.ResetOnSpawn = false

-- Tenta colocar no CoreGui (Anti-deletar). Se o executor mobile não deixar, joga pro PlayerGui automaticamente
local pcallSucesso = pcall(function()
	screenGui.Parent = CoreGui
end)

if not pcallSucesso or not screenGui.Parent then
	screenGui.Parent = jogador:WaitForChild("PlayerGui")
end

-- Janela Principal (Compacta e responsiva para telas de celular)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 115)
frame.Position = UDim2.new(0.1, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

-- Título
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ ROUBE UM OVO - MULTI"
titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 13
titulo.Parent = frame

--- --- SEÇÃO DE VELOCIDADE --- ---
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 32)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "50"
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner1 = Instance.new("UICorner")
caixaCorner1.CornerRadius = UDim.new(0, 5)
caixaCorner1.Parent = caixaVelocidade

local botaoVelocidade = Instance.new("TextButton")
botaoVelocidade.Size = UDim2.new(0, 80, 0, 30)
botaoVelocidade.Position = UDim2.new(0, 90, 0, 32)
botaoVelocidade.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
botaoVelocidade.BorderSizePixel = 0
botaoVelocidade.Text = "CORRER"
botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoVelocidade.Font = Enum.Font.SourceSansBold
botaoVelocidade.TextSize = 13
botaoVelocidade.Parent = frame

local botaoCorner1 = Instance.new("UICorner")
botaoCorner1.CornerRadius = UDim.new(0, 5)
botaoCorner1.Parent = botaoVelocidade

--- --- SEÇÃO DE PULO --- ---
local caixaPulo = Instance.new("TextBox")
caixaPulo.Size = UDim2.new(0, 75, 0, 30)
caixaPulo.Position = UDim2.new(0, 10, 0, 72)
caixaPulo.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
caixaPulo.BorderSizePixel = 0
caixaPulo.Text = "50"
caixaPulo.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaPulo.Font = Enum.Font.SourceSans
caixaPulo.TextSize = 16
caixaPulo.ClearTextOnFocus = false
caixaPulo.Parent = frame

local caixaCorner2 = Instance.new("UICorner")
caixaCorner2.CornerRadius = UDim.new(0, 5)
caixaCorner2.Parent = caixaPulo

local botaoPulo = Instance.new("TextButton")
botaoPulo.Size = UDim2.new(0, 80, 0, 30)
botaoPulo.Position = UDim2.new(0, 90, 0, 72)
botaoPulo.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
botaoPulo.BorderSizePixel = 0
botaoPulo.Text = "PULAR"
botaoPulo.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoPulo.Font = Enum.Font.SourceSansBold
botaoPulo.TextSize = 13
botaoPulo.Parent = frame

local botaoCorner2 = Instance.new("UICorner")
botaoCorner2.CornerRadius = UDim.new(0, 5)
botaoCorner2.Parent = botaoPulo

-- BOTÃO MINIMIZAR (Essencial para celular não tampar a tela inteira)
local botaoFechar = Instance.new("TextButton")
botaoFechar.Size = UDim2.new(0, 20, 0, 20)
botaoFechar.Position = UDim2.new(1, -25, 0, 3)
botaoFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
botaoFechar.Text = "-"
botaoFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoFechar.Font = Enum.Font.SourceSansBold
botaoFechar.TextSize = 14
botaoFechar.Parent = frame

local fecharCorner = Instance.new("UICorner")
fecharCorner.CornerRadius = UDim.new(1, 0) -- Deixa redondo
fecharCorner.Parent = botaoFechar

local minimizado = false
botaoFechar.MouseButton1Click:Connect(function()
	minimizado = not minimizado
	if minimizado then
		frame.Size = UDim2.new(0, 180, 0, 25)
		caixaVelocidade.Visible = false
		botaoVelocidade.Visible = false
		caixaPulo.Visible = false
		botaoPulo.Visible = false
		botaoFechar.Text = "+"
		botaoFechar.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	else
		frame.Size = UDim2.new(0, 180, 0, 115)
		caixaVelocidade.Visible = true
		botaoVelocidade.Visible = true
		caixaPulo.Visible = true
		botaoPulo.Visible = true
		botaoFechar.Text = "-"
		botaoFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end)

-- LÓGICA DE MODIFICAÇÕES REESCRITA COM PROTEÇÃO COMPLETA
local function aplicarModificacoes()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local novaVelocidade = tonumber(caixaVelocidade.Text)
			local novoPulo = tonumber(caixaPulo.Text)
			
			if novaVelocidade then humanoid.WalkSpeed = novaVelocidade end
			if novoPulo then 
				humanoid.UseJumpPower = true
				humanoid.JumpPower = novoPulo 
			end
		end
	end
end

-- Ativação por clique/toque na tela
botaoVelocidade.MouseButton1Click:Connect(aplicarModificacoes)
botaoPulo.MouseButton1Click:Connect(aplicarModificacoes)

-- Mantém ativo após morrer (Loop de verificação ultra seguro para celular)
jogador.CharacterAdded:Connect(function(novoPersonagem)
	local humanoid = novoPersonagem:WaitForChild("Humanoid", 10)
	if humanoid then
		task.wait(0.7) -- Delay preciso para evitar falha de carregamento em telefones lentos
		aplicarModificacoes()
	end
end)

-- SISTEMA DE ARRASTAR COMPATÍVEL COM TOQUE EM CELULAR (TOUCH) E MOUSE
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
