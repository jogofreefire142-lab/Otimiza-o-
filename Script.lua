-- SERVIÇOS DO ROBLOX
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local jogador = Players.LocalPlayer

-- CRIANDO A INTERFACE (GUI) VIA CÓDIGO
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeOvo"
screenGui.ResetOnSpawn = false

-- Tenta colocar no CoreGui (anti-deletar), se não der, vai pro PlayerGui padrão
local sucesso, erro = pcall(function()
	screenGui.Parent = CoreGui
end)
if not sucesso then
	screenGui.Parent = jogador:WaitForChild("PlayerGui")
end

-- Janela Principal (Pequena e Moderna)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 75)
frame.Position = UDim2.new(0.05, 0, 0.4, 0) -- Canto esquerdo da tela
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true -- Você pode arrastar a interface para onde quiser
frame.Parent = screenGui

-- Arredondar cantos do Frame
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

-- Título
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ VELOCIDADE"
titulo.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado cor de ovo/ouro
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 14
titulo.Parent = frame

-- Campo de Texto para digitar o número
local caixaTexto = Instance.new("TextBox")
caixaTexto.Size = UDim2.new(0, 70, 0, 30)
caixaTexto.Position = UDim2.new(0, 10, 0, 32)
caixaTexto.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
caixaTexto.BorderSizePixel = 0
caixaTexto.Text = "16" -- Velocidade padrão do Roblox
caixaTexto.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaTexto.Font = Enum.Font.SourceSans
caixaTexto.TextSize = 16
caixaTexto.ClearTextOnFocus = false
caixaTexto.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaTexto

-- Botão de Ativar
local botao = Instance.new("TextButton")
botao.Size = UDim2.new(0, 65, 0, 30)
botao.Position = UDim2.new(0, 85, 0, 32)
botao.BackgroundColor3 = Color3.fromRGB(0, 180, 100) -- Verde
botao.BorderSizePixel = 0
botao.Text = "DEFINIR"
botao.TextColor3 = Color3.fromRGB(255, 255, 255)
botao.Font = Enum.Font.SourceSansBold
botao.TextSize = 14
botao.Parent = frame

local botaoCorner = Instance.new("UICorner")
botaoCorner.CornerRadius = UDim.new(0, 5)
botaoCorner.Parent = botao

-- LÓGICA DE VELOCIDADE ATUALIZADA
local function mudarVelocidade()
	local personagem = jogador.Character or jogador.CharacterAdded:Wait()
	local humanoid = personagem:WaitForChild("Humanoid")
	
	-- Converte o texto digitado em número
	local novaVelocidade = tonumber(caixaTexto.Text)
	
	if novaVelocidade then
		humanoid.WalkSpeed = novaVelocidade
		
		-- Efeito visual piscar verde no botão confirmando o clique
		botao.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botao.TextColor3 = Color3.fromRGB(0, 0, 0)
		task.wait(0.1)
		botao.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		botao.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		caixaTexto.Text = "Apenas Números!"
		task.wait(1)
		caixaTexto.Text = tostring(humanoid.WalkSpeed)
	end
end

-- Ativa ao clicar no botão
botao.MouseButton1Click:Connect(mudarVelocidade)

-- Mantém a velocidade ativa mesmo se o seu personagem morrer e renascer
jogador.CharacterAdded:Connect(function(novoPersonagem)
	local humanoid = novoPersonagem:WaitForChild("Humanoid")
	local novaVelocidade = tonumber(caixaTexto.Text)
	if novaVelocidade then
		task.wait(0.5) -- Pequeno delay seguro de carregamento
		humanoid.WalkSpeed = novaVelocidade
	end
end)
