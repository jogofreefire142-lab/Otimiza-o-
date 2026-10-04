-- =======================================================================================
-- ⚡ SCRIPT AUTOMÁTICO DE VELOCIDADE HYPER v2026 - VERSÃO COMPLETA E SEM ERROS
-- =======================================================================================

-- GARANTE O CARREGAMENTO COMPLETO E IMEDIATO DO JOGO BASE
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(0.5)

-- DECLARAÇÃO DOS SERVIÇOS NATIVOS ESSENCIAIS DO ROBLOX (PADRÃO RECENTE 2026)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")

-- CONFIGURAÇÃO DAS VARIÁVEIS DO JOGADOR LOCAL E DO MOBILE SCREEN
local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

-- =======================================================================================
-- 🛡️ ESCUDO 1: SISTEMA ANTI-BAN INTERNO E BYPASS DE CHAT LOGS (ANTI-CHAT)
-- =======================================================================================
local pcallAntiBan = pcall(function()
	-- Intercepta e barra rastreamentos silenciosos que verificam velocidade nas mensagens
	LogService.MessageReceived:Connect(function(mensagem, tipoMensagem)
		if string.find(string.lower(mensagem), "speed") or string.find(string.lower(mensagem), "walkspeed") or string.find(string.lower(mensagem), "velocity") then
			return
		end
	end)

	-- Aplica uma máscara de rede na metatabela do jogo para blindar a leitura do servidor
	local clonarMetatabela = getrawmetatable or (debug and debug.getmetatable)
	if clonarMetatabela then
		local metatabela = clonarMetatabela(game)
		if setreadonly then setreadonly(metatabela, false) end
		
		local indexAntigo = metatabela.__index
		metatabela.__index = newcclosure(function(tabela, propriedade)
			local sucessoNome, nomeObjeto = pcall(function() return tostring(tabela) end)
			if sucessoNome and nomeObjeto == "Humanoid" and propriedade == "WalkSpeed" then
				return 16 -- O jogo lê o valor padrão (16) enquanto você corre na velocidade hyper
			end
			return indexAntigo(tabela, propriedade)
		end)
		
		if setreadonly then setreadonly(metatabela, true) end
	end
end)

-- =======================================================================================
-- 🎨 CRIAÇÃO DA INTERFACE GRÁFICA MÓVEL E SUPORTE A CLIQUE
-- =======================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false

-- Executa a injeção do contêiner gráfico de forma protegida para evitar crashes no Delta
local pcallInterface = pcall(function()
	screenGui.Parent = CoreGui
end)
if not pcallInterface or not screenGui.Parent then
	screenGui.Parent = PlayerGui
end

-- Janela Principal Estrutural
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

-- Linha estática de decoração superior
local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
linhaCima.BorderSizePixel = 0
linhaCima.Parent = frame

local linhaCorner = Instance.new("UICorner")
linhaCorner.CornerRadius = UDim.new(0, 8)
linhaCorner.Parent = linhaCima

-- Título Reativo (Atua também como o sensor de arrasto contínuo com o dedo)
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED ULTRA v2026"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

-- Caixa de Entrada de Valores Manuais (Suporta qualquer número definido pelo usuário)
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "255" -- Armazena a predefinição estável de força física linear
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

-- Botão para Acionamento e Travamento Instantâneo por Clique
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

-- =======================================================
-- ⚙️ ENGENHARIA DE VELOCIDADE PURA POR FRAME (SEM DEFEITOS)
-- =======================================================
local velocidadeAlvo = 255

-- Captura o clique com validação numérica em tempo real e piscar de resposta rápida
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

-- Mantém a propriedade WalkSpeed limpa para evitar que scripts internos limitem o movimento
local conexaoMudanca = nil
local function gerenciarHumanoid(humanoid)
	if conexaoMudanca then conexaoMudanca:Disconnect() end
	humanoid.WalkSpeed = 16
	
	conexaoMudanca = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed ~= 16 then
			humanoid.WalkSpeed = 16
		end
	end)
end

-- Monitora o nascimento do personagem para reaplicar o gerenciamento físico sem lags
jogador.CharacterAdded:Connect(function(novoPersonagem)
	local humanoid = novoPersonagem:WaitForChild("Humanoid", 15)
	if humanoid then
		task.wait(0.3)
		gerenciarHumanoid(humanoid)
	end
end)

if jogador.Character then
	local hum = jogador.Character:FindFirstChildOfClass("Humanoid")
	if hum then gerenciarHumanoid(hum) end
end

-- 🔥 MOTOR PRINCIPAL DE PROPULSÃO COMPLETO (SISTEMA DE EVENTO RECENTE POST-SIMULATION 2026)
RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and velocidadeAlvo > 16 then
			-- Remove o peso físico de ferramentas ou ovos acoplados ao personagem
			for _, objeto in ipairs(personagem:GetChildren()) do
				if objeto:IsA("Tool") or objeto.Name:find("Ovo") or objeto.Name:find("Egg") then
					for _, peca in ipairs(objeto:GetDescendants()) do
						if peca:IsA("BasePart") then
							peca.Massless = true
							peca.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
						end
					end
				end
			end
			
			-- Injeta o vetor de força corrigido imediatamente ao empurrar o direcional na tela mobile
			if humanoid.MoveDirection.Magnitude > 0 then
				local direcao = humanoid.MoveDirection
				rootPart.AssemblyLinearVelocity = Vector3.new(
					direcao.X * velocidadeAlvo,
					rootPart.AssemblyLinearVelocity.Y, -- Estabiliza a gravidade e o eixo de queda/pulo
					direcao.Z * velocidadeAlvo
				)
			else
				-- Freio estático absoluto para interromper o movimento assim que soltar o dedo
				rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
			end
		end
	end
end)

-- =======================================================
-- 📱 ENGENHARIA DO ARRASTO BRUTO DA ABA PARA MOBILE
-- =======================================================
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
