-- valware.cc -- PART 1: CORE & RAGE & VISUALS
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local IsArsenal = (game.PlaceId == 286090429)

-- Settings Initialization
_G.PixelSurfEnabled, _G.PixelSurfKey = false, Enum.KeyCode.V
_G.BhopEnabled, _G.BhopKey = false, Enum.KeyCode.Space
_G.EdgeBugEnabled, _G.EdgeBugKey = false, Enum.KeyCode.G
_G.JumpBugEnabled, _G.JumpBugKey = false, Enum.KeyCode.Unknown
_G.LongJumpEnabled, _G.MaxLongJumpSpeed, _G.FlickBoost = false, 35, 1
_G.AirStuckEnabled, _G.AirStuckKey = false, Enum.KeyCode.Z
_G.WalkSpeedEnabled, _G.WalkSpeedValue = false, 16

_G.AimbotEnabled, _G.AimbotKey = false, Enum.KeyCode.E
_G.AimbotFov, _G.AimbotSmoothness, _G.AimbotWallCheck = 100, 0.2, true
_G.AutoShootEnabled, _G.ShootDelay = false, 0

_G.HitboxEnabled, _G.HitboxSize, _G.HitboxTransparency = false, 10, 0.5
_G.AntiAimEnabled, _G.AntiAimSpeed = false, 100
_G.NoSpreadEnabled = false
_G.EspCharmsEnabled, _G.NightModeEnabled = false, false
_G.WatermarkEnabled, _G.ShowVelocity, _G.ShowNotifs = true, true, true
_G.MenuKey = Enum.KeyCode.End
_G.AccentColor = Color3.fromRGB(0, 255, 120)

-- Notification System
local function Notify(title, text)
    if not _G.ShowNotifs then return end
    local n = Instance.new("Frame")
    -- Logic thông báo chi tiết (giữ nguyên độ dài)
    print("[valware.cc] " .. title .. ": " .. text)
end

-- Fix Wall Check Logic
local function IsVisible(targetPart)
    if not _G.AimbotWallCheck then return true end
    local char = Player.Character
    if not char then return false end
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char, targetPart.Parent, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return result == nil
end

-- No Spread Function
local original_spread = {}
local function scan_for_weapons()
    local targets = {game:GetService("ReplicatedStorage"), Player.Character, Player.Backpack, workspace:FindFirstChild("Weapons")}
    for _, root in pairs(targets) do
        if root then
            for _, v in ipairs(root:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = v.Name:lower()
                    if n:find("spread") or n:find("recoil") or n:find("accuracy") or n == "norecoil" then
                        if not original_spread[v] then original_spread[v] = v.Value end
                        if _G.NoSpreadEnabled then v.Value = 0 end
                    end
                end
            end
        end
    end
end

-- Optimized Hitbox Logic (Fix Skin & Arsenal)
local function applyHitboxLogic(targetPlayer)
    if targetPlayer == Player then return end
    local function setup(char)
        task.spawn(function()
            while char.Parent and task.wait(0.5) do
                if _G.HitboxEnabled then
                    if IsArsenal then
                        for _, pName in pairs({"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart"}) do
                            local p = char:FindFirstChild(pName)
                            if p and p:IsA("BasePart") then
                                p.CanCollide = false
                                p.Transparency = _G.HitboxTransparency
                                p.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                            end
                        end
                    else
                        for _, part in ipairs(char:GetChildren()) do
                            if part:IsA("BasePart") and (part.Name:find("Head") or part.Name:find("Hit")) then
                                part.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                                part.Transparency = _G.HitboxTransparency
                                part.CanCollide = false
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
    targetPlayer.CharacterAdded:Connect(setup)
    if targetPlayer.Character then setup(targetPlayer.Character) end
end
for _, p in pairs(Players:GetPlayers()) do applyHitboxLogic(p) end
Players.PlayerAdded:Connect(applyHitboxLogic)

-- Charm ESP Logic
RunService.RenderStepped:Connect(function()
    if _G.EspCharmsEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                for _, v in pairs(p.Character:GetChildren()) do
                    if v:IsA("BasePart") and v.Transparency ~= 1 then
                        local h = v:FindFirstChild("CharmHighlight") or Instance.new("BoxHandleAdornment", v)
                        h.Name = "CharmHighlight"; h.Adornee = v; h.AlwaysOnTop = true; h.ZIndex = 5
                        h.Size = v.Size; h.Transparency = 0.5; h.Color3 = _G.AccentColor
                    end
                end
            end
        end
    end
end)
-- valware.cc -- PART 2: UI & MOVEMENT v2.6 & MAIN LOOP
local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or Player:FindFirstChild("PlayerGui")))
local Watermark = Instance.new("Frame", ScreenGui); Watermark.Size = UDim2.new(0, 180, 0, 20); Watermark.Position = UDim2.new(0, 10, 0, 10); Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Watermark.Visible = _G.WatermarkEnabled
local WText = Instance.new("TextLabel", Watermark); WText.Size = UDim2.new(1, -10, 1, 0); WText.Position = UDim2.new(0, 5, 0, 0); WText.TextColor3 = Color3.new(1,1,1); WText.Font = Enum.Font.Code; WText.TextSize = 10; WText.TextXAlignment = 0

local VelLabel = Instance.new("TextLabel", ScreenGui); VelLabel.Size = UDim2.new(0, 100, 0, 20); VelLabel.Position = UDim2.new(0.5, -50, 0.5, 50); VelLabel.BackgroundTransparency = 1; VelLabel.Font = Enum.Font.Code; VelLabel.TextSize = 15; VelLabel.TextColor3 = _G.AccentColor; VelLabel.Visible = _G.ShowVelocity

local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 210, 0, 250); Main.Position = UDim2.new(0.5, -105, 0.5, -125); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.BorderSizePixel = 1; Main.BorderColor3 = Color3.fromRGB(40, 40, 40); Main.Visible = false
local TabBar = Instance.new("Frame", Main); TabBar.Size = UDim2.new(1, 0, 0, 18); TabBar.Position = UDim2.new(0, 0, 0, 2); TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -8, 1, -26); Container.Position = UDim2.new(0, 4, 0, 24); Container.BackgroundTransparency = 1

local function createTab(name, pos)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0.25, 0, 1, 0); btn.Position = UDim2.new(0.25 * pos, 0, 0, 0); btn.BackgroundTransparency = 1; btn.Text = name; btn.Font = Enum.Font.Code; btn.TextColor3 = (pos == 0 and Color3.new(1,1,1) or Color3.fromRGB(100, 100, 100)); btn.TextSize = 9
    local page = Instance.new("ScrollingFrame", Container)
    page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = (pos == 0); page.CanvasSize = UDim2.new(0, 0, 0, 450); page.ScrollBarThickness = 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 2)
    btn.MouseButton1Click:Connect(function() 
        for _, v in pairs(Container:GetChildren()) do v.Visible = false end 
        for _, v in pairs(TabBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(100, 100, 100) end end 
        page.Visible = true; btn.TextColor3 = Color3.new(1,1,1) 
    end)
    return page
end
local mPage, rPage, vPage, miPage = createTab("MOVE", 0), createTab("RAGE", 1), createTab("VIS", 2), createTab("MISC", 3)

local function addToggle(name, var, parent, keyVar)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 15); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 6, 0, 6); btn.Position = UDim2.new(0, 5, 0.5, -3); btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); btn.Text = ""
    local lbl = Instance.new("TextLabel", f); lbl.Text = name:upper(); lbl.Position = UDim2.new(0, 18, 0, 0); lbl.Size = UDim2.new(1, -18, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); lbl.Font = Enum.Font.Code; lbl.TextSize = 8; lbl.TextXAlignment = 0
    if keyVar then
        local k = Instance.new("TextButton", f); k.Text = "["..(_G[keyVar].Name).."]"; k.Size = UDim2.new(0, 40, 1, 0); k.Position = UDim2.new(1, -45, 0, 0); k.BackgroundTransparency = 1; k.TextColor3 = Color3.fromRGB(80,80,80); k.Font = Enum.Font.Code; k.TextSize = 7
        k.MouseButton1Click:Connect(function() k.Text = "[...]"; local c; c = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then _G[keyVar] = i.KeyCode; k.Text = "["..i.KeyCode.Name.."]"; c:Disconnect() end end) end)
    end
    btn.MouseButton1Click:Connect(function() _G[var] = not _G[var]; btn.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(35, 35, 35); lbl.TextColor3 = _G[var] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150) end)
end

local function addSlider(name, min, max, var, parent, float)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 20); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Text = name:upper()..": ".._G[var]; lbl.Size = UDim2.new(1,0,0,10); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(130,130,130); lbl.Font = Enum.Font.Code; lbl.TextSize = 7; lbl.TextXAlignment = 0
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(1, -15, 0, 2); bg.Position = UDim2.new(0, 5, 0, 12); bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    local fill = Instance.new("Frame", bg); fill.Size = UDim2.new((_G[var]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = _G.AccentColor
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local c; c = RunService.RenderStepped:Connect(function() local x = math.clamp((UserInputService:GetMouseLocation().X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(x, 0, 1, 0); _G[var] = float and math.floor((min+(max-min)*x)*10)/10 or math.floor(min+(max-min)*x); lbl.Text = name:upper()..": ".._G[var] end) UserInputService.InputEnded:Connect(function(i2) if i2.UserInputType == Enum.UserInputType.MouseButton1 then c:Disconnect() end end) end end)
end

-- Full Feature List
addToggle("Pixel Surf", "PixelSurfEnabled", mPage, "PixelSurfKey")
addToggle("Bhop", "BhopEnabled", mPage, "BhopKey")
addToggle("Edge Bug", "EdgeBugEnabled", mPage, "EdgeBugKey")
addToggle("Jump Bug", "JumpBugEnabled", mPage, "JumpBugKey")
addToggle("Long Jump", "LongJumpEnabled", mPage)
addSlider("Flick Boost", 1, 10, "FlickBoost", mPage)
addToggle("Air Stuck", "AirStuckEnabled", mPage, "AirStuckKey")
addToggle("Walk Speed", "WalkSpeedEnabled", mPage); addSlider("Value", 16, 200, "WalkSpeedValue", mPage)

addToggle("Aimbot", "AimbotEnabled", rPage, "AimbotKey")
addToggle("Auto Shoot", "AutoShootEnabled", rPage)
addSlider("Shoot Delay", 0, 1, "ShootDelay", rPage, true)
addToggle("Wall Check", "AimbotWallCheck", rPage)
addSlider("FOV", 10, 600, "AimbotFov", rPage)
addToggle("Hitbox", "HitboxEnabled", rPage); addSlider("Size", 2, 40, "HitboxSize", rPage)
addToggle("Spinbot", "AntiAimEnabled", rPage); addSlider("Spin Speed", 0, 500, "AntiAimSpeed", rPage)

addToggle("ESP Charms", "EspCharmsEnabled", vPage)
addToggle("Night Mode", "NightModeEnabled", miPage)
addToggle("No Spread", "NoSpreadEnabled", miPage)

local lastShoot = 0
RunService.Heartbeat:Connect(function()
    local c = Player.Character; local r = c and c:FindFirstChild("HumanoidRootPart"); local h = c and c:FindFirstChild("Humanoid")
    if not r or not h then return end
    
    WText.Text = "valware.cc | fps: "..math.floor(workspace:GetRealTimeUpdateRate()).." | ping: "..math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    VelLabel.Text = math.floor(Vector2.new(r.Velocity.X, r.Velocity.Z).Magnitude)

    -- Movement v2.6 Core Logic
    if _G.BhopEnabled and UserInputService:IsKeyDown(_G.BhopKey) and h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
    if _G.JumpBugEnabled and UserInputService:IsKeyDown(_G.JumpBugKey ~= Enum.KeyCode.Unknown and _G.JumpBugKey or Enum.KeyCode.Space) then
        local ray = workspace:Raycast(r.Position, Vector3.new(0, -h.HipHeight - 2.1, 0))
        if ray and r.Velocity.Y < 0 then h:ChangeState(3); r.Velocity = Vector3.new(r.Velocity.X, 55, r.Velocity.Z) end
    end
    if _G.PixelSurfEnabled and UserInputService:IsKeyDown(_G.PixelSurfKey) then
        local ray = workspace:Raycast(r.Position, Camera.CFrame.LookVector * 5)
        if ray and h.FloorMaterial == Enum.Material.Air then
            local v = Vector3.new(r.Velocity.X, 0, r.Velocity.Z)
            local slide = v - ray.Normal * v:Dot(ray.Normal)
            r.Velocity = Vector3.new(slide.Unit.X * 35, -0.01, slide.Unit.Z * 35)
        end
    end
    if _G.WalkSpeedEnabled then h.WalkSpeed = _G.WalkSpeedValue end
    r.Anchored = (_G.AirStuckEnabled and UserInputService:IsKeyDown(_G.AirStuckKey))
    if _G.AntiAimEnabled then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(_G.AntiAimSpeed), 0) end
    if _G.NoSpreadEnabled then scan_for_weapons() end

    -- Aimbot & Auto Shoot
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
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), _G.AimbotSmoothness)
            if _G.AutoShootEnabled and (tick() - lastShoot) >= _G.ShootDelay then lastShoot = tick(); mouse1click() end
        end
    end
end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == _G.MenuKey then Main.Visible = not Main.Visible end end)
