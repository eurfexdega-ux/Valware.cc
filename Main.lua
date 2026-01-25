-- valware.cc -- PART 1: CORE, ADVANCED WALLCHECK & HITBOX SYSTEM
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local IsArsenal = (game.PlaceId == 286090429)
local IsCounterBlox = (game.PlaceId == 301549746)

-- Settings
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
_G.AutoShootEnabled, _G.ShootDelay = false, 0

_G.HitboxEnabled = false
_G.HitboxSize = 13
_G.HitboxTransparency = 0.7

_G.HitboxExtendEnabled = false
_G.HitboxExtendSize = 2
_G.HitboxExtendTransparency = 0.5

_G.AntiAimEnabled, _G.AntiAimSpeed = false, 100
_G.ThirdPersonEnabled, _G.ThirdPersonKey = false, Enum.KeyCode.M
_G.ThirdPersonDist = 12

_G.NoRecoilEnabled, _G.RecoilStrength = false, 1
_G.NoSpreadEnabled = false

_G.EspCharmsEnabled, _G.NightModeEnabled = false, false
_G.WatermarkEnabled, _G.ShowVelocity, _G.ShowNotifs = true, true, true
_G.MenuKey = Enum.KeyCode.End
_G.AccentColor = Color3.fromRGB(0, 255, 120)

-- [[ NEW: ADVANCED WALL CHECK ]] --
local function IsVisible(targetPart)
    if not _G.AimbotWallCheck then return true end
    local char = Player.Character
    if not char then return false end
    
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char, targetPart.Parent, Camera, workspace:FindFirstChild("Ignore")}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    -- Nếu không chạm gì hoặc chạm đúng target thì là visible
    if not result or result.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

-- [[ NEW: OPTIMIZED HITBOX SYSTEM (FIX SKIN) ]] --
local function setupHitbox(v)
    if v == Player then return end
    local function apply(char)
        task.spawn(function()
            while char.Parent and task.wait(0.5) do
                if _G.HitboxEnabled or _G.HitboxExtendEnabled then
                    local targetSize = _G.HitboxEnabled and _G.HitboxSize or _G.HitboxExtendSize
                    local targetAlpha = _G.HitboxEnabled and _G.HitboxTransparency or _G.HitboxExtendTransparency
                    
                    if IsArsenal then
                        local parts = {"HeadHB", "HumanoidRootPart", "RightUpperLeg", "LeftUpperLeg"}
                        for _, pName in pairs(parts) do
                            local p = char:FindFirstChild(pName)
                            if p and p:IsA("BasePart") then
                                p.CanCollide = false
                                p.Transparency = targetAlpha
                                p.Size = Vector3.new(targetSize, targetSize, targetSize)
                            end
                        end
                    else
                        -- Fix Skin Logic: Chỉ phóng to Hitbox Part, không scale Mesh
                        for _, part in ipairs(char:GetChildren()) do
                            if part:IsA("BasePart") and (part.Name:find("Head") or part.Name:find("Hit")) then
                                part.CanCollide = false
                                part.Transparency = targetAlpha
                                part.Size = Vector3.new(targetSize, targetSize, targetSize)
                                
                                -- Chống lỗi skin khổng lồ bằng cách khóa Scale của Mesh bên trong
                                local m = part:FindFirstChildOfClass("SpecialMesh") or part:FindFirstChildOfClass("MeshPart")
                                if m and m:IsA("SpecialMesh") then
                                    m.Scale = Vector3.new(1.001, 1.001, 1.001)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    v.CharacterAdded:Connect(apply)
    if v.Character then apply(v.Character) end
end
for _, v in pairs(Players:GetPlayers()) do setupHitbox(v) end
Players.PlayerAdded:Connect(setupHitbox)

-- No Spread System (Giữ nguyên)
local original_spread = {}
local function scan_for_weapons()
    local targets = {game:GetService("ReplicatedStorage"), Player.Character, Player.Backpack, workspace:FindFirstChild("Weapons")}
    for _, root in pairs(targets) do
        if root then
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local name = v.Name:lower()
                    if name:find("spread") or name:find("recoil") or name:find("accuracy") then
                        if not original_spread[v] then original_spread[v] = v.Value end
                        if _G.NoSpreadEnabled then v.Value = 0 end
                    end
                end
            end
        end
    end
end
-- valware.cc -- PART 2: UI ENGINE & FULL MOVEMENT LOGIC
local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or Player:FindFirstChild("PlayerGui")))
local VelLabel = Instance.new("TextLabel", ScreenGui)
VelLabel.Size = UDim2.new(0, 100, 0, 20); VelLabel.Position = UDim2.new(0.5, -50, 0.5, 50)
VelLabel.BackgroundTransparency = 1; VelLabel.Font = Enum.Font.Code; VelLabel.TextSize = 15; VelLabel.TextColor3 = _G.AccentColor; VelLabel.TextStrokeTransparency = 0

local Watermark = Instance.new("Frame", ScreenGui)
Watermark.Size = UDim2.new(0, 210, 0, 22); Watermark.Position = UDim2.new(0, 10, 0, 10); Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Watermark.BorderSizePixel = 1; Watermark.BorderColor3 = Color3.fromRGB(45, 45, 45)
local WText = Instance.new("TextLabel", Watermark)
WText.Size = UDim2.new(1, 0, 1, 0); WText.BackgroundTransparency = 1; WText.Font = Enum.Font.Code; WText.TextColor3 = Color3.new(1,1,1); WText.TextSize = 11

local function notify(txt)
    if not _G.ShowNotifs then return end
    local nl = Instance.new("TextLabel", ScreenGui)
    nl.Size = UDim2.new(0, 120, 0, 20); nl.Position = UDim2.new(0.5, -60, 0.58, 0)
    nl.BackgroundTransparency = 1; nl.Font = Enum.Font.Code; nl.TextSize = 13; nl.TextColor3 = _G.AccentColor; nl.Text = txt
    task.spawn(function() task.wait(0.4) TweenService:Create(nl, TweenInfo.new(0.3), {TextTransparency = 1}):Play() task.wait(0.3); nl:Destroy() end)
end

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 210, 0, 200); Main.Position = UDim2.new(0.5, -105, 0.5, -100); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.BorderSizePixel = 1; Main.BorderColor3 = Color3.fromRGB(40, 40, 40); Main.Visible = false

local TabBar = Instance.new("Frame", Main); TabBar.Size = UDim2.new(1, 0, 0, 18); TabBar.Position = UDim2.new(0, 0, 0, 4); TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -8, 1, -26); Container.Position = UDim2.new(0, 4, 0, 24); Container.BackgroundTransparency = 1

local function createTab(name, pos)
    local btn = Instance.new("TextButton", TabBar); btn.Size = UDim2.new(0.25, 0, 1, 0); btn.Position = UDim2.new(0.25 * pos, 0, 0, 0); btn.BackgroundTransparency = 1; btn.Text = name; btn.Font = Enum.Font.Code; btn.TextColor3 = (pos == 0 and Color3.new(1,1,1) or Color3.fromRGB(100, 100, 100)); btn.TextSize = 9
    local page = Instance.new("ScrollingFrame", Container); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = (pos == 0); page.CanvasSize = UDim2.new(0, 0, 0, 380); page.ScrollBarThickness = 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 2)
    btn.MouseButton1Click:Connect(function() for _, v in pairs(Container:GetChildren()) do v.Visible = false end for _, v in pairs(TabBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(100, 100, 100) end end page.Visible = true; btn.TextColor3 = Color3.new(1,1,1) end)
    return page
end
local mPage, rPage, vPage, miPage = createTab("MOVE", 0), createTab("RAGE", 1), createTab("VIS", 2), createTab("MISC", 3)

local function addToggle(name, var, parent, keyVar)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 15); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 6, 0, 6); btn.Position = UDim2.new(0, 5, 0.5, -3); btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); btn.Text = ""
    local lbl = Instance.new("TextLabel", f); lbl.Text = name:upper(); lbl.Position = UDim2.new(0, 18, 0, 0); lbl.Size = UDim2.new(1, -18, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); lbl.Font = Enum.Font.Code; lbl.TextSize = 8; lbl.TextXAlignment = 0
    if keyVar then
        local k = Instance.new("TextButton", f); k.Text = "["..(_G[keyVar].Name).."]"; k.Size = UDim2.new(0, 35, 1, 0); k.Position = UDim2.new(1, -40, 0, 0); k.BackgroundTransparency = 1; k.TextColor3 = Color3.fromRGB(80,80,80); k.Font = Enum.Font.Code; k.TextSize = 7
        k.MouseButton1Click:Connect(function() k.Text = "[...]"; local c; c = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then _G[keyVar] = i.KeyCode; k.Text = "["..i.KeyCode.Name.."]"; c:Disconnect() end end) end)
    end
    btn.MouseButton1Click:Connect(function() _G[var] = not _G[var]; btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150) end)
end

-- Full Feature Loop (Movement & Rage)
RunService.Heartbeat:Connect(function(dt)
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    VelLabel.Visible = _G.ShowVelocity; VelLabel.Text = math.floor(Vector2.new(root.Velocity.X, root.Velocity.Z).Magnitude)
    
    -- Movement v2.6 Logic (Giữ nguyên không đổi)
    if _G.BhopEnabled and UserInputService:IsKeyDown(_G.BhopKey) then if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end end
    
    if _G.JumpBugEnabled and UserInputService:IsKeyDown(_G.JumpBugKey ~= Enum.KeyCode.Unknown and _G.JumpBugKey or Enum.KeyCode.Space) then  
        local cast = workspace:Raycast(root.Position, Vector3.new(0, -hum.HipHeight - 2.1, 0))
        if cast and root.Velocity.Y < 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z); notify("JB")
        end
    end  
    
    if _G.PixelSurfEnabled and UserInputService:IsKeyDown(_G.PixelSurfKey) then  
        local ray = workspace:Raycast(root.Position, Camera.CFrame.LookVector * 5)  
        if ray and hum.FloorMaterial == Enum.Material.Air then  
            local v = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            local surfDir = (v - ray.Normal * v:Dot(ray.Normal))  
            root.Velocity = Vector3.new(surfDir.Unit.X * 35, -0.01, surfDir.Unit.Z * 35); notify("PS")  
        end  
    end
    
    -- Aimbot với WallCheck mới
    if _G.AimbotEnabled and UserInputService:IsKeyDown(_G.AimbotKey) then
        local target, dist = nil, _G.AimbotFov
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Player and v.Character then
                local p = v.Character:FindFirstChild("HeadHB") or v.Character:FindFirstChild("Head")
                if p and IsVisible(p) then
                    local pos, os = Camera:WorldToViewportPoint(p.Position)
                    if os then
                        local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if mag < dist then target = p; dist = mag end
                    end
                end
            end
        end
        if target then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), _G.AimbotSmoothness) end
    end
    
    if _G.WalkSpeedEnabled then hum.WalkSpeed = _G.WalkSpeedValue end
    root.Anchored = (_G.AirStuckEnabled and UserInputService:IsKeyDown(_G.AirStuckKey))
end)

-- Rendering & Watermark
RunService.RenderStepped:Connect(function()
    Watermark.Visible = _G.WatermarkEnabled
    WText.Text = string.format(" valware.cc | %d fps | %d ms | beta ", math.floor(1/RunService.RenderStepped:Wait()), math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
end)

UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == _G.MenuKey then Main.Visible = not Main.Visible end
end)
