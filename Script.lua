-- =======================================================================================
-- ⚡ SCRIPT AUTOMÁTICO DE VELOCIDADE HYPER v2026 - PARTE 1 DE 2
-- =======================================================================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(0.3)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

local personagemAtual = jogador.Character
local humanoideAtual = personagemAtual and personagemAtual:FindFirstChildOfClass("Humanoid")
local rootPartAtual = personagemAtual and personagemAtual:FindFirstChild("HumanoidRootPart")

local velocidadeAlvo = 255
local conexaoMudanca = nil

-- =======================================================
-- 🛠️ GERENCIAMENTO DO HUMANOID
-- =======================================================

local function gerenciarHumanoid(humanoid)
	if conexaoMudanca then
		conexaoMudanca:Disconnect()
		conexaoMudanca = nil
	end

	if not humanoid or not humanoid.Parent then
		return
	end

	humanoid.WalkSpeed = velocidadeAlvo

	conexaoMudanca = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid and humanoid.Parent and humanoid.WalkSpeed ~= velocidadeAlvo then
			humanoid.WalkSpeed = velocidadeAlvo
		end
	end)
end

-- =======================================================
-- 🛡️ BLOCO DE TESTE/PROTEÇÃO
-- =======================================================

local pcallAntiBan = pcall(function()
	LogService.MessageReceived:Connect(function(mensagem, tipoMensagem)
		local texto = string.lower(tostring(mensagem))

		if string.find(texto, "speed")
			or string.find(texto, "walkspeed")
			or string.find(texto, "velocity") then
			return
		end
	end)

	local clonarMetatabela = getrawmetatable or (debug and debug.getmetatable)

	if clonarMetatabela and setreadonly and newcclosure then
		local metatabela = clonarMetatabela(game)

		if metatabela then
			setreadonly(metatabela, false)

			local indexAntigo = metatabela.__index

			if indexAntigo then
				metatabela.__index = newcclosure(function(tabela, propriedade)
					local sucessoNome, nomeObjeto = pcall(function()
						return tostring(tabela)
					end)

					if sucessoNome
						and nomeObjeto == "Humanoid"
						and propriedade == "WalkSpeed" then
						return velocidadeAlvo
					end

					return indexAntigo(tabela, propriedade)
				end)
			end

			setreadonly(metatabela, true)
		end
	end
end)

-- =======================================================
-- 🎨 INTERFACE
-- =======================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false

local pcallInterface = pcall(function()
	screenGui.Parent = CoreGui
end)

if not pcallInterface or not screenGui.Parent then
	screenGui.Parent = PlayerGui
end

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

local linhaCima = Instance.new("Frame")
linhaCima.Size = UDim2.new(1, 0, 0, 3)
linhaCima.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
linhaCima.BorderSizePixel = 0
linhaCima.Parent = frame

local linhaCorner = Instance.new("UICorner")
linhaCorner.CornerRadius = UDim.new(0, 8)
linhaCorner.Parent = linhaCima

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 25)
titulo.Position = UDim2.new(0, 0, 0, 3)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ SPEED ULTRA v2026"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

local caixaVelocidade = Instance.new("TextBox")
caixaVelocidade.Size = UDim2.new(0, 75, 0, 30)
caixaVelocidade.Position = UDim2.new(0, 10, 0, 35)
caixaVelocidade.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
caixaVelocidade.BorderSizePixel = 0
caixaVelocidade.Text = tostring(velocidadeAlvo)
caixaVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
caixaVelocidade.Font = Enum.Font.SourceSans
caixaVelocidade.TextSize = 16
caixaVelocidade.ClearTextOnFocus = false
caixaVelocidade.Parent = frame

local caixaCorner = Instance.new("UICorner")
caixaCorner.CornerRadius = UDim.new(0, 5)
caixaCorner.Parent = caixaVelocidade

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
-- ⚡ BOTÃO DE VELOCIDADE
-- =======================================================

botaoVelocidade.Activated:Connect(function()
	local num = tonumber(caixaVelocidade.Text)

	if num then
		velocidadeAlvo = num

		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)

		if humanoideAtual then
			gerenciarHumanoid(humanoideAtual)
		end

		task.wait(0.08)

		if botaoVelocidade and botaoVelocidade.Parent then
			botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
			botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

-- =======================================================
-- 🔄 RESPAWN
-- =======================================================

jogador.CharacterAdded:Connect(function(novoPersonagem)
	personagemAtual = novoPersonagem

	humanoideAtual = novoPersonagem:WaitForChild("Humanoid", 15)
	rootPartAtual = novoPersonagem:WaitForChild("HumanoidRootPart", 15)

	task.wait(0.2)

	if humanoideAtual then
		gerenciarHumanoid(humanoideAtual)
	end
end)

-- =======================================================
-- 🚀 INICIALIZAÇÃO
-- =======================================================

if humanoideAtual then
	gerenciarHumanoid(humanoideAtual)
end

-- =======================================================
-- 🔥 MOTOR DE MOVIMENTAÇÃO
-- =======================================================

RunService.PostSimulation:Connect(function()
	local char = personagemAtual or jogador.Character
	local hum = humanoideAtual or (char and char:FindFirstChildOfClass("Humanoid"))
	local root = rootPartAtual or (char and char:FindFirstChild("HumanoidRootPart"))

	if not char or not hum or not root then
		return
	end

	if velocidadeAlvo > 16 and root:IsA("BasePart") then

		-- Mantém a otimização original dos objetos carregados
		for _, objeto in ipairs(char:GetChildren()) do
			if objeto:IsA("Tool")
				or objeto.Name:find("Ovo")
				or objeto.Name:find("Egg") then

				for _, peca in ipairs(objeto:GetDescendants()) do
					if peca:IsA("BasePart") and not peca.Massless then
						peca.Massless = true

						local sucesso = pcall(function()
							peca.CustomPhysicalProperties = PhysicalProperties.new(
								0.0001,
								0,
								0,
								0,
								0
							)
						end)

						if not sucesso then
							-- Mantém o restante do motor funcionando
						end
					end
				end
			end
		end

		-- Movimento pela direção do Humanoid
		if hum.MoveDirection.Magnitude > 0 then
			local direcao = hum.MoveDirection
			local velocidadeVertical = root.AssemblyLinearVelocity.Y

			root.AssemblyLinearVelocity = Vector3.new(
				direcao.X * velocidadeAlvo,
				velocidadeVertical,
				direcao.Z * velocidadeAlvo
			)
		end
	end
end)

-- =======================================================
-- 📱 ARRASTO MOBILE
-- =======================================================

local arrastando = false
local toqueInicial = Vector2.new(0, 0)
local posicaoInicial = frame.Position

titulo.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		arrastando = true
		toqueInicial = Vector2.new(
			input.Position.X,
			input.Position.Y
		)

		posicaoInicial = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not arrastando then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

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
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		arrastando = false
	end
end)
