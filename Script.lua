local UniverseID = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://roblox.com"..game.PlaceId.."/universe")).universeId

-- Pula a Key e carrega a versão keyless modificada da comunidade
if game.PlaceId == 1537690962 or game.PlaceId == 4079902982 then
    loadstring(game:HttpGet("https://githubusercontent.com"))()
elseif game.PlaceId == 10260193230 then 
    loadstring(game:HttpGet("https://githubusercontent.com"))()
elseif game.PlaceId == 7449423635 or game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 122478697296975 or UniverseID == 994732206 then
    loadstring(game:HttpGet("https://githubusercontent.com"))()
elseif game.PlaceId == 4520749081 or game.PlaceId == 6381829480 or game.PlaceId == 15759515082 or game.PlaceId == 5931540094 then 
    repeat task.wait() until game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild("DataLoaded") and game.Players.LocalPlayer:FindFirstChild("DataLoaded").Value
    loadstring(game:HttpGet("https://githubusercontent.com"))()
else
    -- Fallback seguro sem chave para os outros modos de jogo
    loadstring(game:HttpGet("https://githubusercontent.com"))()
end
