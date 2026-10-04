if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(0.3)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local PlayerGui = jogador:WaitForChild("PlayerGui", 30)

local personagemAtual
local humanoideAtual
local rootPartAtual
local velocidadeAlvo = 255
local conexaoMudanca
local conexaoDescendente

local function tornarObjetoLeve(objeto)
	if not objeto then
		return
	end

	if objeto:IsA("Tool") or objeto.Name:find("Ovo") or objeto.Name:find("Egg") then
		if objeto:IsA("BasePart") then
			objeto.Massless = true
			pcall(function()
				objeto.CustomPhysicalProperties = PhysicalProperties.new(
					0.0001,
					0,
					0,
					0,
					0
				)
			end)
		end

		for _, peca in ipairs(objeto:GetDescendants()) do
			if peca:IsA("BasePart") then
				peca.Massless = true
				pcall(function()
					peca.CustomPhysicalProperties = PhysicalProperties.new(
						0.0001,
						0,
						0,
						0,
						0
					)
				end)
			end
		end
	end
end

local function prepararPersonagem(personagem)
	if conexaoDescendente then
		conexaoDescendente:Disconnect()
		conexaoDescendente = nil
	end

	personagemAtual = personagem
	humanoideAtual = personagem:WaitForChild("Humanoid", 15)
	rootPartAtual = personagem:WaitForChild("HumanoidRootPart", 15)

	for _, objeto in ipairs(personagem:GetChildren()) do
		tornarObjetoLeve(objeto)
	end

	conexaoDescendente = personagem.DescendantAdded:Connect(function(objeto)
		if objeto:IsA("Tool")
			or objeto.Name:find("Ovo")
			or objeto.Name:find("Egg") then
			tornarObjetoLeve(objeto)
		end
	end)

	if conexaoMudanca then
		conexaoMudanca:Disconnect()
		conexaoMudanca = nil
	end

	if humanoideAtual then
		humanoideAtual.WalkSpeed = velocidadeAlvo

		conexaoMudanca = humanoideAtual:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if humanoideAtual
				and humanoideAtual.Parent
				and humanoideAtual.WalkSpeed ~= velocidadeAlvo then
				humanoideAtual.WalkSpeed = velocidadeAlvo
			end
		end)
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelVelocidadeDefinitivo2026"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local sucessoCoreGui = pcall(function()
	screenGui.Parent = CoreGui
end)

if not sucessoCoreGui or not screenGui.Parent then
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
titulo.Text = "SPEED"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.Font = Enum.Font.SourceSansBold
titulo.TextSize = 12
titulo.Parent = frame

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

botaoVelocidade.Activated:Connect(function()
	local num = tonumber(caixaVelocidade.Text)

	if num and num == num and num ~= math.huge and num ~= -math.huge then
		velocidadeAlvo = math.clamp(num, 0, 1000)

		if humanoideAtual and humanoideAtual.Parent then
			humanoideAtual.WalkSpeed = velocidadeAlvo
		end

		botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		botaoVelocidade.TextColor3 = Color3.fromRGB(0, 0, 0)

		task.delay(0.08, function()
			if botaoVelocidade and botaoVelocidade.Parent then
				botaoVelocidade.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
				botaoVelocidade.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	else
		caixaVelocidade.Text = tostring(velocidadeAlvo)
	end
end)

jogador.CharacterAdded:Connect(prepararPersonagem)

if jogador.Character then
	prepararPersonagem(jogador.Character)
end

RunService.PostSimulation:Connect(function()
	local humanoide = humanoideAtual
	local root = rootPartAtual

	if not humanoide
		or not root
		or not humanoide.Parent
		or not root.Parent then
		return
	end

	if humanoide.WalkSpeed ~= velocidadeAlvo then
		humanoide.WalkSpeed = velocidadeAlvo
	end

	if humanoide.MoveDirection.Magnitude <= 0 then
		return
	end

	local direcao = humanoide.MoveDirection
	local atual = root.AssemblyLinearVelocity

	local alvoX = direcao.X * velocidadeAlvo
	local alvoZ = direcao.Z * velocidadeAlvo

	local fatorDeslize = 0.7

	root.AssemblyLinearVelocity = Vector3.new(
		atual.X + (alvoX - atual.X) * fatorDeslize,
		atual.Y,
		atual.Z + (alvoZ - atual.Z) * fatorDeslize
	)
end)

local arrastando = false
local toqueInicial = Vector2.zero
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
