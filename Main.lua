-- valware.cc -- PART 1
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
_G.AutoShootEnabled, _G.AutoShootDelay = false, 0.1

_G.HitboxEnabled, _G.HitboxSize, _G.HitboxTransparency = false, 13, 0.7
_G.HitboxExtendEnabled, _G.HitboxExtendSize, _G.HitboxExtendTransparency = false, 10, 0.5

_G.AntiAimEnabled, _G.AntiAimSpeed = false, 100
_G.NoSpreadEnabled = false

_G.EspCharmsEnabled, _G.NightModeEnabled = false, false
_G.WatermarkEnabled, _G.ShowVelocity, _G.ShowNotifs = true, true, true
_G.MenuKey = Enum.KeyCode.End
_G.AccentColor = Color3.fromRGB(0, 255, 120)

-- No Spread Logic
local original_spread = {}
local function find_spread_values(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("spread") or name:find("recoil") or name:find("accuracy") or name == "land" or name == "jump" or name == "crouch" or name == "move" or name == "stand" or name == "norecoil" then
                if not original_spread[v] then original_spread[v] = v.Value end
            end
        end
    end
end
local function apply_no_spread_all() for v, _ in pairs(original_spread) do if v and v.Parent then v.Value = 0 end end end
local function restore_spread_all() for v, original_val in pairs(original_spread) do if v and v.Parent then v.Value = original_val end end end
local function scan_for_weapons()
    local rep = game:GetService("ReplicatedStorage")
    if rep then find_spread_values(rep) end
    if Player.Character then find_spread_values(Player.Character) end
    if Player.Backpack then find_spread_values(Player.Backpack) end
end

-- ESP Charms & Hitbox Logic (Face Fix)
local function applyCharmsAndHitbox(p)
    if p == Player then return end
    local function setup(char)
        if not char then return end
        
        -- ESP Charms Setup
        local highlight = char:FindFirstChild("ValCharms") or Instance.new("Highlight")
        highlight.Name = "ValCharms"
        highlight.Parent = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = _G.AccentColor
        highlight.Enabled = _G.EspCharmsEnabled

        char:WaitForChild("Humanoid", 10)
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and (part.Name:find("Head") or part.Name:find("Hit")) then
                -- Store visuals to hide them later
                local visuals = {}
                for _, v in ipairs(part:GetChildren()) do
                    if v:IsA("Decal") or v:IsA("Texture") then table.insert(visuals, v) end
                end

                task.spawn(function()
                    while char.Parent do
                        if _G.HitboxExtendEnabled then
                            part.Size = Vector3.new(_G.HitboxExtendSize, _G.HitboxExtendSize, _G.HitboxExtendSize)
                            part.Transparency = _G.HitboxExtendTransparency
                            part.CanCollide = false
                            -- Hide face/textures
                            for _, v in ipairs(visuals) do v.Transparency = 1 end
                            
                            local mesh = part:FindFirstChildOfClass("SpecialMesh") or part:FindFirstChildOfClass("MeshPart")
                            if mesh and mesh:IsA("SpecialMesh") then 
                                mesh.Scale = Vector3.new(_G.HitboxExtendSize, _G.HitboxExtendSize, _G.HitboxExtendSize) 
                            end
                        else
                            -- Reset only if not in special game like Arsenal
                            if not IsArsenal then 
                                part.Size = Vector3.new(1, 1, 1)
                                part.Transparency = 0
                                for _, v in ipairs(visuals) do v.Transparency = 0 end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end
    end
    p.CharacterAdded:Connect(setup)
    if p.Character then setup(p.Character) end
end

Players.PlayerAdded:Connect(applyCharmsAndHitbox)
for _, p in ipairs(Players:GetPlayers()) do applyCharmsAndHitbox(p) end

-- Aimbot Visibility Check
local function IsVisible(targetPart)
    if not _G.AimbotWallCheck then return true end
    local char = Player.Character
    if not char then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, targetPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000, params)
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
local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 210, 0, 210); Main.Position = UDim2.new(0.5, -105, 0.5, -105); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.BorderSizePixel = 1; Main.BorderColor3 = Color3.fromRGB(40, 40, 40); Main.Visible = false
local RGBLine = Instance.new("Frame", Main); RGBLine.Size = UDim2.new(1, 0, 0, 2); RGBLine.BorderSizePixel = 0
local Grad = Instance.new("UIGradient", RGBLine); Grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.5, _G.AccentColor), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))})

local TabBar = Instance.new("Frame", Main); TabBar.Size = UDim2.new(1, 0, 0, 18); TabBar.Position = UDim2.new(0, 0, 0, 2); TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -8, 1, -26); Container.Position = UDim2.new(0, 4, 0, 24); Container.BackgroundTransparency = 1

local function createTab(name, pos)
    local btn = Instance.new("TextButton", TabBar); btn.Size = UDim2.new(0.25, 0, 1, 0); btn.Position = UDim2.new(0.25 * pos, 0, 0, 0); btn.BackgroundTransparency = 1; btn.Text = name; btn.Font = Enum.Font.Code; btn.TextColor3 = (pos == 0 and Color3.new(1,1,1) or Color3.fromRGB(100, 100, 100)); btn.TextSize = 9
    local page = Instance.new("ScrollingFrame", Container); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = (pos == 0); page.CanvasSize = UDim2.new(0, 0, 0, 400); page.ScrollBarThickness = 0; Instance.new("UIListLayout", page).Padding = UDim.new(0, 2)
    btn.MouseButton1Click:Connect(function() for _, v in pairs(Container:GetChildren()) do v.Visible = false end for _, v in pairs(TabBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(100, 100, 100) end end page.Visible = true; btn.TextColor3 = Color3.new(1,1,1) end)
    return page
end

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

local mPage, rPage, vPage, miPage = createTab("MOVE", 0), createTab("RAGE", 1), createTab("VIS", 2), createTab("MISC", 3)

-- Full Movement v2.6 Setup
addToggle("Pixel Surf", "PixelSurfEnabled", mPage, "PixelSurfKey")
addToggle("Jump Bug", "JumpBugEnabled", mPage, "JumpBugKey")
addToggle("Edge Bug", "EdgeBugEnabled", mPage, "EdgeBugKey")
addToggle("Long Jump", "LongJumpEnabled", mPage)
addSlider("Max LJ Speed", 20, 100, "MaxLongJumpSpeed", mPage)
addSlider("Flick Boost", 1, 10, "FlickBoost", mPage)
addToggle("Bhop", "BhopEnabled", mPage, "BhopKey")
addToggle("Walk Speed", "WalkSpeedEnabled", mPage); addSlider("Speed Value", 16, 200, "WalkSpeedValue", mPage)

-- Rage & Hitbox Setup
addToggle("Aimbot", "AimbotEnabled", rPage, "AimbotKey")
addSlider("FOV", 10, 800, "AimbotFov", rPage)
addToggle("Auto Shoot", "AutoShootEnabled", rPage); addSlider("Shoot Delay", 0, 1, "AutoShootDelay", rPage, true)
addToggle("Hitbox Extend", "HitboxExtendEnabled", rPage); addSlider("HE Size", 2, 25, "HitboxExtendSize", rPage)
addSlider("HE Transp", 0, 1, "HitboxExtendTransparency", rPage, true)

-- Visuals Setup
addToggle("ESP Charms", "EspCharmsEnabled", vPage)
addToggle("Night Mode", "NightModeEnabled", vPage)
addToggle("No Spread", "NoSpreadEnabled", miPage, nil, function(v) if v then scan_for_weapons() apply_no_spread_all() else restore_spread_all() end end)

-- Final Execution Loops
local lastShoot = 0
RunService.Heartbeat:Connect(function(dt)
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    if _G.WalkSpeedEnabled then hum.WalkSpeed = _G.WalkSpeedValue else hum.WalkSpeed = 16 end
    Lighting.ClockTime = _G.NightModeEnabled and 1 or 14

    -- Movement 2.6 Logic Execution
    local moveParams = RaycastParams.new(); moveParams.FilterDescendantsInstances = {char}; moveParams.FilterType = Enum.RaycastFilterType.Exclude  
    if _G.BhopEnabled and UserInputService:IsKeyDown(_G.BhopKey) then if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end end  
    if _G.JumpBugEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then  
        local cast = workspace:Raycast(root.Position, Vector3.new(0, -hum.HipHeight - 2.1, 0), moveParams)
        if cast and root.Velocity.Y < 0 then hum:ChangeState(Enum.HumanoidStateType.Jumping); root.AssemblyLinearVelocity = Vector3.new(root.Velocity.X * 1.1, 55, root.Velocity.Z * 1.1) end
    end
end)

RunService.RenderStepped:Connect(function()
    Grad.Offset = Vector2.new(math.sin(tick() * 1.5) * 0.5, 0)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player and v.Character then
            local h = v.Character:FindFirstChild("ValCharms")
            if h then h.Enabled = _G.EspCharmsEnabled end
        end
    end

    if _G.AimbotEnabled and IsTargeting then 
        local t = GetClosestPlayer()
        if t then 
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), _G.AimbotSmoothness)
            if _G.AutoShootEnabled and tick() - lastShoot >= _G.AutoShootDelay then
                mouse1press(); task.wait(0.01); mouse1release()
                lastShoot = tick()
            end
        end 
    end
end)

UserInputService.InputBegan:Connect(function(i, g) if not g then if i.KeyCode == _G.MenuKey then Main.Visible = not Main.Visible end; if i.KeyCode == _G.AimbotKey then IsTargeting = true end end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == _G.AimbotKey then IsTargeting = false end end)
