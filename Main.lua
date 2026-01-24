-- valware.cc -- 
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local IsArsenal = (game.PlaceId == 286090429)

-- Settings & Keybinds Initialization
_G.PixelSurfEnabled, _G.PixelSurfKey = false, Enum.KeyCode.V
_G.BhopEnabled, _G.BhopKey = false, Enum.KeyCode.Space
_G.EdgeBugEnabled, _G.EdgeBugKey = false, Enum.KeyCode.G
_G.JumpBugEnabled, _G.JumpBugKey = false, Enum.KeyCode.Unknown
_G.LongJumpEnabled, _G.MaxLongJumpSpeed, _G.FlickBoost = false, 35, 1
_G.AirStuckEnabled, _G.AirStuckKey = false, Enum.KeyCode.Z
_G.WalkSpeedEnabled, _G.WalkSpeedValue = false, 16

_G.AimbotEnabled, _G.AimbotKey = false, Enum.KeyCode.E
_G.AimbotPart, _G.AimbotSmoothness = "Head", 0.2
_G.AimbotFov, _G.AimbotWallCheck = 100, true

_G.HitboxEnabled, _G.HitboxSize, _G.HitboxTransparency = false, 13, 0.7
_G.HitboxExtendEnabled, _G.HitboxExtendSize, _G.HitboxExtendTransparency = false, 2, 0.5

_G.AntiAimEnabled, _G.AntiAimSpeed = false, 100
_G.NoSpreadEnabled = false

_G.EspCharmsEnabled, _G.NightModeEnabled = false, false
_G.WatermarkEnabled, _G.ShowVelocity, _G.ShowNotifs = true, true, true
_G.MenuKey = Enum.KeyCode.End
_G.AccentColor = Color3.fromRGB(0, 255, 120)

-- No Spread System
local original_spread = {}
local rep = game:GetService("ReplicatedStorage")
local function find_spread_values(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("spread") or name:find("recoil") or name:find("accuracy") or 
               name == "land" or name == "jump" or name == "crouch" or 
               name == "move" or name == "stand" or name == "norecoil" then
                if not original_spread[v] then original_spread[v] = v.Value end
            end
        end
    end
end
local function apply_no_spread_all()
    for v, _ in pairs(original_spread) do if v and v.Parent then v.Value = 0 end end
end
local function restore_spread_all()
    for v, original_val in pairs(original_spread) do if v and v.Parent then v.Value = original_val end end
end
local function scan_for_weapons()
    if rep then find_spread_values(rep) end
    if Player.Character then find_spread_values(Player.Character) end
    if Player.Backpack then find_spread_values(Player.Backpack) end
    local weapons_folder = workspace:FindFirstChild("Weapons")
    if weapons_folder then find_spread_values(weapons_folder) end
end

-- Hitbox Logic
task.spawn(function()
    while task.wait(0.2) do
        if IsArsenal and _G.HitboxEnabled then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= Player and v.Character then
                    for _, pName in pairs({"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart"}) do
                        local p = v.Character:FindFirstChild(pName)
                        if p and p:IsA("BasePart") then p.CanCollide = false; p.Transparency = _G.HitboxTransparency; p.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize) end
                    end
                end
            end
        elseif not IsArsenal and _G.HitboxExtendEnabled then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= Player and v.Character then
                    local head = v.Character:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then head.CanCollide = false; head.Transparency = _G.HitboxExtendTransparency; head.Size = Vector3.new(_G.HitboxExtendSize, _G.HitboxExtendSize, _G.HitboxExtendSize) end
                end
            end
        end
    end
end)

-- Charms & Visibility
local function ApplyCharms(v)
    if v == Player then return end
    local function add(char)
        if not char then return end
        local h = char:FindFirstChild("ValCharms") or Instance.new("Highlight")
        h.Name = "ValCharms"; h.Parent = char; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.FillColor = _G.AccentColor; h.Enabled = _G.EspCharmsEnabled
    end
    v.CharacterAdded:Connect(add); if v.Character then add(v.Character) end
end
for _, v in pairs(Players:GetPlayers()) do ApplyCharms(v) end
Players.PlayerAdded:Connect(ApplyCharms)

local function IsVisible(targetPart)
    if not _G.AimbotWallCheck then return true end
    local char = Player.Character; if not char then return false end
    local params = RaycastParams.new(); params.FilterDescendantsInstances = {char, targetPart.Parent, Camera}; params.FilterType = Enum.RaycastFilterType.Exclude
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 500, params)
    return ray == nil
end

local function GetClosestPlayer()
    local target, dist = nil, _G.AimbotFov
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player and v.Character then
            local p = v.Character:FindFirstChild("HeadHB") or v.Character:FindFirstChild("Head")
            local h = v.Character:FindFirstChildOfClass("Humanoid")
            if p and h and h.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Position)
                if onScreen and IsVisible(p) then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist then target = p; dist = mag end
                end
            end
        end
    end
    return target
end
-- valware.cc -- PART 2
local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or Player:FindFirstChild("PlayerGui")))
local VelLabel = Instance.new("TextLabel", ScreenGui); VelLabel.Size = UDim2.new(0, 100, 0, 20); VelLabel.Position = UDim2.new(0.5, -50, 0.5, 50); VelLabel.BackgroundTransparency = 1; VelLabel.Font = Enum.Font.Code; VelLabel.TextSize = 15; VelLabel.TextColor3 = _G.AccentColor; VelLabel.TextStrokeTransparency = 0

local Watermark = Instance.new("Frame", ScreenGui); Watermark.Size = UDim2.new(0, 210, 0, 22); Watermark.Position = UDim2.new(0, 10, 0, 10); Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Watermark.BorderSizePixel = 1; Watermark.BorderColor3 = Color3.fromRGB(45, 45, 45)
local WText = Instance.new("TextLabel", Watermark); WText.Size = UDim2.new(1, 0, 1, 0); WText.BackgroundTransparency = 1; WText.Font = Enum.Font.Code; WText.TextColor3 = Color3.new(1,1,1); WText.TextSize = 11

local function notify(txt)
    if not _G.ShowNotifs then return end
    local nl = Instance.new("TextLabel", ScreenGui); nl.Size = UDim2.new(0, 120, 0, 20); nl.Position = UDim2.new(0.5, -60, 0.58, 0); nl.BackgroundTransparency = 1; nl.Font = Enum.Font.Code; nl.TextSize = 13; nl.TextColor3 = _G.AccentColor; nl.Text = txt
    task.spawn(function() task.wait(0.4) TweenService:Create(nl, TweenInfo.new(0.3), {TextTransparency = 1}):Play() task.wait(0.3); nl:Destroy() end)
end

local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 210, 0, 200); Main.Position = UDim2.new(0.5, -105, 0.5, -100); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.BorderSizePixel = 1; Main.BorderColor3 = Color3.fromRGB(40, 40, 40); Main.Visible = false
local RGBLine = Instance.new("Frame", Main); RGBLine.Size = UDim2.new(1, 0, 0, 2); RGBLine.BorderSizePixel = 0
local Grad = Instance.new("UIGradient", RGBLine); Grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.5, _G.AccentColor), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))})

local TabBar = Instance.new("Frame", Main); TabBar.Size = UDim2.new(1, 0, 0, 18); TabBar.Position = UDim2.new(0, 0, 0, 2); TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -8, 1, -26); Container.Position = UDim2.new(0, 4, 0, 24); Container.BackgroundTransparency = 1

local dragging, dragStart, startPos
TabBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

local function createTab(name, pos)
    local btn = Instance.new("TextButton", TabBar); btn.Size = UDim2.new(0.25, 0, 1, 0); btn.Position = UDim2.new(0.25 * pos, 0, 0, 0); btn.BackgroundTransparency = 1; btn.Text = name; btn.Font = Enum.Font.Code; btn.TextColor3 = (pos == 0 and Color3.new(1,1,1) or Color3.fromRGB(100, 100, 100)); btn.TextSize = 9
    local page = Instance.new("ScrollingFrame", Container); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = (pos == 0); page.CanvasSize = UDim2.new(0, 0, 0, 400); page.ScrollBarThickness = 0; Instance.new("UIListLayout", page).Padding = UDim.new(0, 2)
    btn.MouseButton1Click:Connect(function() for _, v in pairs(Container:GetChildren()) do v.Visible = false end for _, v in pairs(TabBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(100, 100, 100) end end page.Visible = true; btn.TextColor3 = Color3.new(1,1,1) end)
    return page
end
local mPage, rPage, vPage, miPage = createTab("MOVE", 0), createTab("RAGE", 1), createTab("VIS", 2), createTab("MISC", 3)

local function addToggle(name, var, parent, keyVar, callback)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 15); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 6, 0, 6); btn.Position = UDim2.new(0, 5, 0.5, -3); btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); btn.BorderSizePixel = 0; btn.Text = ""
    local lbl = Instance.new("TextLabel", f); lbl.Text = name:upper(); lbl.Position = UDim2.new(0, 18, 0, 0); lbl.Size = UDim2.new(1, -18, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); lbl.Font = Enum.Font.Code; lbl.TextSize = 8; lbl.TextXAlignment = 0
    
    if keyVar then
        local k = Instance.new("TextButton", f); k.Text = "["..(_G[keyVar].Name).."]"; k.Size = UDim2.new(0, 40, 1, 0); k.Position = UDim2.new(1, -45, 0, 0); k.BackgroundTransparency = 1; k.TextColor3 = Color3.fromRGB(80,80,80); k.Font = Enum.Font.Code; k.TextSize = 7; k.TextXAlignment = 2
        k.MouseButton1Click:Connect(function() k.Text = "[...]"; local c; c = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then _G[keyVar] = i.KeyCode; k.Text = "["..i.KeyCode.Name.."]"; c:Disconnect() end end) end)
    end
    btn.MouseButton1Click:Connect(function() _G[var] = not _G[var]; btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); if callback then callback(_G[var]) end end)
end

local function addSlider(name, min, max, var, parent, isFloat)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 20); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Text = name:upper()..": ".._G[var]; lbl.Size = UDim2.new(1,0,0,10); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(130,130,130); lbl.Font = Enum.Font.Code; lbl.TextSize = 7; lbl.TextXAlignment = 0
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(1, -15, 0, 2); bg.Position = UDim2.new(0, 5, 0, 12); bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); bg.BorderSizePixel = 0
    local fill = Instance.new("Frame", bg); fill.Size = UDim2.new((_G[var]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = _G.AccentColor; fill.BorderSizePixel = 0
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local con; con = RunService.RenderStepped:Connect(function() local x = math.clamp((UserInputService:GetMouseLocation().X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(x, 0, 1, 0); local val = min + (max-min)*x; _G[var] = isFloat and math.floor(val*10)/10 or math.floor(val); lbl.Text = name:upper()..": ".._G[var] end) UserInputService.InputEnded:Connect(function(i2) if i2.UserInputType == Enum.UserInputType.MouseButton1 then con:Disconnect() end end) end end)
end

-- Tabs Config
addToggle("Pixel Surf", "PixelSurfEnabled", mPage, "PixelSurfKey")
addToggle("Edge Bug", "EdgeBugEnabled", mPage, "EdgeBugKey")
addToggle("Jump Bug", "JumpBugEnabled", mPage, "JumpBugKey")
addToggle("Long Jump", "LongJumpEnabled", mPage)
addSlider("Max LJ Speed", 20, 100, "MaxLongJumpSpeed", mPage)
addSlider("Flick Boost", 1, 10, "FlickBoost", mPage)
addToggle("Bhop", "BhopEnabled", mPage, "BhopKey")
addToggle("Air Stuck", "AirStuckEnabled", mPage, "AirStuckKey")
addToggle("Walk Speed", "WalkSpeedEnabled", mPage)
addSlider("Speed Value", 16, 200, "WalkSpeedValue", mPage)

addToggle("Aimbot", "AimbotEnabled", rPage, "AimbotKey")
addToggle("Wall Check", "AimbotWallCheck", rPage)
addSlider("FOV", 10, 800, "AimbotFov", rPage)
addSlider("Smoothness", 0, 1, "AimbotSmoothness", rPage, true)

if IsArsenal then addToggle("Arsenal Hitbox", "HitboxEnabled", rPage); addSlider("HB Size", 2, 25, "HitboxSize", rPage)
else addToggle("Hitbox Extend", "HitboxExtendEnabled", rPage); addSlider("HE Size", 2, 15, "HitboxExtendSize", rPage) end

addToggle("Spin Bot", "AntiAimEnabled", rPage); addSlider("Spin Speed", 0, 250, "AntiAimSpeed", rPage)
addToggle("ESP Charms", "EspCharmsEnabled", vPage)
addToggle("Night Mode", "NightModeEnabled", vPage)
addToggle("Velocity", "ShowVelocity", miPage)
addToggle("No Spread", "NoSpreadEnabled", miPage, nil, function(v) if v then scan_for_weapons() apply_no_spread_all() else restore_spread_all() end end)

-- Main Loop
RunService.Heartbeat:Connect(function(dt)
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    VelLabel.Visible = _G.ShowVelocity; VelLabel.Text = math.floor(Vector2.new(root.Velocity.X, root.Velocity.Z).Magnitude)
    if _G.WalkSpeedEnabled then hum.WalkSpeed = _G.WalkSpeedValue else hum.WalkSpeed = 16 end
    Lighting.ClockTime = _G.NightModeEnabled and 1 or 14
    if _G.AntiAimEnabled then hum.AutoRotate = false; root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(_G.AntiAimSpeed * dt * 10), 0) else hum.AutoRotate = true end

    local moveParams = RaycastParams.new(); moveParams.FilterDescendantsInstances = {char}; moveParams.FilterType = Enum.RaycastFilterType.Exclude  
    if _G.JumpBugEnabled and UserInputService:IsKeyDown(_G.JumpBugKey ~= Enum.KeyCode.Unknown and _G.JumpBugKey or Enum.KeyCode.Space) then  
        local cast = workspace:Raycast(root.Position, Vector3.new(0, -hum.HipHeight - 2.1, 0), moveParams)
        if cast and root.Velocity.Y < 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping); root.AssemblyLinearVelocity = Vector3.new(root.Velocity.X * 1.1, (hum.JumpPower > 0 and hum.JumpPower or 50) + 5, root.Velocity.Z * 1.1); notify("JB") end
    end  
    if _G.EdgeBugEnabled and UserInputService:IsKeyDown(_G.EdgeBugKey) then  
        if not workspace:Raycast(root.Position, Vector3.new(0, -5, 0), moveParams) and hum.FloorMaterial == Enum.Material.Air and root.Velocity.Y < -5 then root.AssemblyLinearVelocity = Vector3.new(root.Velocity.X, -0.001, root.Velocity.Z); notify("EB") end  
    end
    if _G.LongJumpEnabled and hum.FloorMaterial == Enum.Material.Air then  
        local _, curYaw = Camera.CFrame:ToEulerAnglesYXZ(); local diff = math.abs(curYaw - (LastCameraYaw or 0))  
        if diff > 0.02 then local addForce = Camera.CFrame.LookVector * (diff * 18 * (_G.FlickBoost or 1)); local targetVel = root.Velocity + Vector3.new(addForce.X, 0.5, addForce.Z)
            if Vector3.new(targetVel.X, 0, targetVel.Z).Magnitude > _G.MaxLongJumpSpeed then local flat = Vector3.new(targetVel.X, 0, targetVel.Z).Unit * _G.MaxLongJumpSpeed; root.Velocity = Vector3.new(flat.X, targetVel.Y, flat.Z) else root.Velocity = targetVel end
            if Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude >= 30 then notify("LJ") end end; LastCameraYaw = curYaw  
    end  
    if _G.PixelSurfEnabled and UserInputService:IsKeyDown(_G.PixelSurfKey) then  
        local ray = workspace:Raycast(root.Position, Camera.CFrame.LookVector * 5, moveParams)  
        if ray and hum.FloorMaterial == Enum.Material.Air then hum:ChangeState(Enum.HumanoidStateType.Freefall); SurfTimer = (SurfTimer or 0) + dt; if SurfTimer >= 1 then SurfSpeed = math.min((SurfSpeed or 20) + 1, 100); SurfTimer = 0 end; local surfDir = (Vector3.new(root.Velocity.X, 0, root.Velocity.Z) - ray.Normal * Vector3.new(root.Velocity.X, 0, root.Velocity.Z):Dot(ray.Normal)); root.Velocity = Vector3.new(surfDir.Unit.X * (SurfSpeed or 20), -0.01, surfDir.Unit.Z * (SurfSpeed or 20)); notify("PS") else SurfSpeed, SurfTimer = 20, 0 end  
    end
    if _G.BhopEnabled and UserInputService:IsKeyDown(_G.BhopKey) then if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end end  
    root.Anchored = (_G.AirStuckEnabled and UserInputService:IsKeyDown(_G.AirStuckKey))
end)

RunService.RenderStepped:Connect(function()
    for _, v in pairs(Players:GetPlayers()) do if v ~= Player and v.Character then local h = v.Character:FindFirstChild("ValCharms") if h then h.Enabled = _G.EspCharmsEnabled end end end
    Grad.Offset = Vector2.new(math.sin(tick() * 1.5) * 0.5, 0); Watermark.Visible = _G.WatermarkEnabled; WText.Text = string.format(" valware.cc | %d fps | %d ms | beta ", math.floor(1/RunService.RenderStepped:Wait()), math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
    if _G.AimbotEnabled and IsTargeting then local t = GetClosestPlayer(); if t then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), _G.AimbotSmoothness) end end
end)

UserInputService.InputBegan:Connect(function(i, g) if not g then if i.KeyCode == _G.MenuKey then Main.Visible = not Main.Visible end; if i.KeyCode == _G.AimbotKey then IsTargeting = true end end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == _G.AimbotKey then IsTargeting = false end end)
