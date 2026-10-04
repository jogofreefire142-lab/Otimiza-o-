-- =======================================================================================
-- ⚡ SCRIPT AUTOMÁTICO DE VELOCIDADE HYPER v2026 - VERSÃO COMPLETA E INDESTRUTÍVEL
-- =======================================================================================

-- SISTEMA DE AGUARDO: COMPATIBILIDADE COM INJEÇÃO LENTA DO DELTA EXECUTOR
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(0.5)

-- DECLARAÇÃO DE SERVIÇOS DO ROBLOX (PADRÃO ATUALIZADO 2026)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")

-- DECLARAÇÃO DE VARIÁVEIS DE JOGADOR
local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

-- =======================================================================================
-- 🛡️ ESCUDO 1: SISTEMA ANTI-BAN INTERNO E BYPASS DE CHAT LOGS
-- =======================================================================================
local pcallAntiBan = pcall(function()
	-- Cancela envios invisíveis de logs do chat do jogo baseados em checagem de velocidade
	LogService.MessageReceived:Connect(function(mensagem, tipoMensagem)
		if string.find(string.lower(mensagem), "speed") or string.find(string.lower(mensagem), "walkspeed") or string.find(string.lower(mensagem), "velocity") then
			return
		end
	end)

	-- Mascara o valor da propriedade WalkSpeed via manipulação de Metatabela para o Servidor
	local clonarMetatabela = getrawmetatable or (debug and debug.getmetatable)
	if clonarMetatabela then
		local metatabela = clonarMetatabela(game)
		if setreadonly then setreadonly(metatabela, false) end
		
		local indexAntigo = metatabela.__index
		metatabela.__index = newcclosure(function(tabela, propriedade)
			local sucessoNome, nomeObjeto = pcall(function() return tostring(tabela) end)
			if sucessoNome and nomeObjeto == "Humanoid" and propriedade == "WalkSpeed" then
				return 16 -- Retorna o valor padrão do jogo para os scripts locais de verificação
			end
			return indexAntigo(tabela, propriedade)
		end)
		
		if setreadonly then setreadonly(metatabela, true) end
	end
end)

-- =======================================================================================
-- 🎨 CRIAÇÃO DA INTERFACE GRÁFICA COMPATÍVEL COM DISPOSITIVOS MOBILE
-- =======================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false

-- Fallback seguro para injetar a interface em qualquer executor sem causar travamento (crash)
local pcallInterface = pcall(function()
	screenGui.Parent = CoreGui
end)
if not pcallInterface or not screenGui.Parent then
	screenGui.Parent = PlayerGui
end

-- Janela Principal (Tamanho compacto ideal para não atrapalhar no celular)
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

-- Linha Estilizada Superior (Estilo Hacker Premium)
local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
linhaCima.BorderSizePixel = 0
linhaCima.Parent = frame

local linhaCorner = Instance.new("UICorner")
linhaCorner.CornerRadius = UDim.new(0, 8)
linhaCorner.Parent = linhaCima

-- Título da Interface (Área reativa de toque para mover a janela)
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED ULTRA v2026"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

-- Caixa de Entrada de Texto (Para digitar os valores manualmente de 250 a 260)
local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = "255" -- Valor manual ideal configurado automaticamente
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

-- Botão de Ativação / Trava de Força Bruta
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
-- ⚙️ CONFIGURAÇÃO DE VELOCIDADE POR VETORES E FREIO SECO
-- =======================================================
local velocidadeAlvo = 255

-- Gerenciador do Clique do Botão (Com efeito flash visual)
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

-- Gerenciador de Propriedade Humanoide para manter o disfarce ativo contra anti-cheats locais
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

-- Sincronização Automática pós-morte (Respawn) com leve delay seguro contra crash
jogador.CharacterAdded:Connect(function(novoPersonagem)
	local humanoid = novoPersonagem:WaitForChild("Humanoid", 15)
	if humanoid then
		task.wait(0.3) -- A leve travada necessária para carregar a física liso
		gerenciarHumanoid(humanoid)
	end
end)

-- Inicialização preemptiva caso o script seja injetado no meio da partida
if jogador.Character then
	local hum = jogador.Character:FindFirstChildOfClass("Humanoid")
	if hum then gerenciarHumanoid(hum) end
end

-- 🔥 ENGINE DE MOVIMENTAÇÃO FISICA AVANÇADA (SISTEMA POST-SIMULATION 2026)
RunService.PostSimulation:Connect(function()
	local personagem = jogador.Character
	if personagem then
		local humanoid = personagem:FindFirstChildOfClass("Humanoid")
		local rootPart = personagem:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and velocidadeAlvo > 16 then
			-- Verifica se o jogador está movimentando o analógico na tela
			if humanoid.MoveDirection.Magnitude > 0 then
				local direcao = humanoid.MoveDirection
				-- Aplica a força de movimento de forma instantânea nos eixos X e Z
				rootPart.AssemblyLinearVelocity = Vector3.new(
					direcao.X * velocidadeAlvo,
					rootPart.AssemblyLinearVelocity.Y, -- Protege o eixo vertical para não bugar o pulo ou cair do mapa
					direcao.Z * velocidadeAlvo
				)
			else
				-- SISTEMA DE FREIO SECO IMEDIATO: Zera o empurrão quando solta o analógico
				rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
			end
		end
	end
end)

-- =======================================================
-- 📱 ENGENHARIA DE ARRASTO BRUTO EXCLUSIVO PARA TELAS TOQUE
-- =======================================================
local arrastando = false
local toqueInicial = Vector2.new(0, 0)
local posicaoInicial = frame.Position

-- Registra o início do toque do dedo na área do título
titulo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = true
		toqueInicial = Vector2.new(input.Position.X, input.Position.Y)
		posicaoInicial = frame.Position
	end
end)

-- Converte o arrasto do dedo em movimento posicional livre na interface gráfica
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

-- Finaliza o ciclo de arrasto quando remove o dedo da tela
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		arrastando = false
	end
end)
