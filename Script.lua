local VelocidadeDesejada = 260
local Player = game:GetService("Players").LocalPlayer

local function AplicarVelocidade(character)
    -- Garante que o componente de física humana carregou completamente
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    -- Aplica a velocidade de 260 imediatamente
    humanoid.WalkSpeed = VelocidadeDesejada
    
    -- O sinal reativo inteligente que você curtiu: só trabalha se o jogo tentar te frear
    local connection
    connection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not humanoid or not humanoid.Parent then
            if connection then connection:Disconnect() end
            return
        end
        if humanoid.WalkSpeed ~= VelocidadeDesejada then
            humanoid.WalkSpeed = VelocidadeDesejada
        end
    end)
end

-- Ativa de forma segura no personagem atual
if Player.Character then
    task.defer(AplicarVelocidade, Player.Character)
end

-- Monitora perfeitamente os próximos respawns sem falhar
Player.CharacterAdded:Connect(function(character)
    task.defer(AplicarVelocidade, character)
end)
