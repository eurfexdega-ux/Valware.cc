-- valware.cc | Part 1 --
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

_G.PixelSurfEnabled, _G.PixelSurfKey = false, Enum.KeyCode.V
_G.BhopEnabled, _G.BhopKey = false, Enum.KeyCode.Space
_G.EdgeBugEnabled, _G.EdgeBugKey = false, Enum.KeyCode.C
_G.JumpBugEnabled, _G.JumpBugKey = false, Enum.KeyCode.Unknown
_G.LongJumpEnabled, _G.MaxLongJumpSpeed, _G.FlickBoost = false, 35, 1
_G.AirStuckEnabled, _G.AirStuckKey = false, Enum.KeyCode.T
_G.WalkSpeedEnabled, _G.WalkSpeedValue = false, 16
_G.AimbotEnabled, _G.AimbotKey = false, Enum.KeyCode.E
_G.AimbotPart, _G.AimbotSmoothness = "Head", 0.2
_G.AimbotFov, _G.AimbotWallCheck = 100, true
_G.HitboxEnabled, _G.HitboxSize, _G.HitboxTransparency = false, 2, 0.7
_G.HitboxExtendEnabled, _G.HitboxExtendSize, _G.HitboxExtendTransparency = false, 2, 0.5
_G.AntiAimEnabled, _G.AntiAimSpeed = false, 100
_G.NoRecoilEnabled, _G.RecoilStrength = false, 1
_G.NoSpreadEnabled = false
_G.EspCharmsEnabled, _G.NightModeEnabled = false, false
_G.WatermarkEnabled, _G.ShowVelocity, _G.ShowNotifs = true, true, true
_G.MenuKey = Enum.KeyCode.End
_G.AccentColor = Color3.fromRGB(0, 255, 120)

local original_spread = {}
local function find_spread_values(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("NumberValue") then
            local name = v.Name:lower()
            if name:find("spread") or name:find("recoil") or name:find("accuracy") then
                if not original_spread[v] then original_spread[v] = v.Value end
            end
        end
    end
end

local function apply_no_spread_all() for v, _ in pairs(original_spread) do if v and v.Parent then v.Value = 0 end end end
local function restore_spread_all() for v, ov in pairs(original_spread) do if v and v.Parent then v.Value = ov end end end

local function scan_for_weapons()
    find_spread_values(game:GetService("ReplicatedStorage"))
    if Player.Character then find_spread_values(Player.Character) end
    if Player.Backpack then find_spread_values(Player.Backpack) end
    if workspace:FindFirstChild("Weapons") then find_spread_values(workspace.Weapons) end
end

local function IsVisible(part)
    if not _G.AimbotWallCheck then return true end
    local char = Player.Character
    if not char then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, part.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), params)
    return res == nil
end

task.spawn(function()
    while task.wait(0.2) do
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Player and v.Character then
                if IsArsenal and _G.HitboxEnabled then
                    for _, pN in pairs({"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart"}) do
                        local p = v.Character:FindFirstChild(pN)
                        if p then p.CanCollide, p.Transparency, p.Size = false, _G.HitboxTransparency, Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize) end
                    end
                elseif not IsArsenal and _G.HitboxExtendEnabled then
                    local h = v.Character:FindFirstChild("Head")
                    if h then h.CanCollide, h.Transparency, h.Size = false, _G.HitboxExtendTransparency, Vector3.new(_G.HitboxExtendSize, _G.HitboxExtendSize, _G.HitboxExtendSize) end
                end
            end
        end
    end
end)

local function ApplyCharms(v)
    local function add(char)
        if not char then return end
        local hi = char:FindFirstChild("ValCharms") or Instance.new("Highlight")
        hi.Name, hi.Parent, hi.DepthMode, hi.FillColor = "ValCharms", char, 0, _G.AccentColor
    end
    v.CharacterAdded:Connect(add)
    if v.Character then add(v.Character) end
end
for _, v in pairs(Players:GetPlayers()) do ApplyCharms(v) end
Players.PlayerAdded:Connect(ApplyCharms)

function GetClosestPlayer()
    local t, d = nil, _G.AimbotFov
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= Player and v.Character then
            local p = v.Character:FindFirstChild("HeadHB") or v.Character:FindFirstChild("Head")
            local h = v.Character:FindFirstChildOfClass("Humanoid")
            if p and h and h.Health > 0 then
                local pos, onS = Camera:WorldToViewportPoint(p.Position)
                if onS and IsVisible(p) then
                    local m = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if m < d then t = p; d = m end
                end
            end
        end
    end
    return t
end
-- valware.cc | 
local ScreenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or Player:FindFirstChild("PlayerGui")))
local VelLabel = Instance.new("TextLabel", ScreenGui)
VelLabel.Size, VelLabel.Position, VelLabel.BackgroundTransparency, VelLabel.Font, VelLabel.TextSize, VelLabel.TextColor3 = UDim2.new(0, 100, 0, 20), UDim2.new(0.5, -50, 0.5, 50), 1, 3, 15, _G.AccentColor

local Watermark = Instance.new("Frame", ScreenGui)
Watermark.Size, Watermark.Position, Watermark.BackgroundColor3, Watermark.BorderColor3 = UDim2.new(0, 210, 0, 22), UDim2.new(0, 10, 0, 10), Color3.fromRGB(15, 15, 15), Color3.fromRGB(45, 45, 45)
local WText = Instance.new("TextLabel", Watermark)
WText.Size, WText.BackgroundTransparency, WText.Font, WText.TextColor3, WText.TextSize = UDim2.new(1, 0, 1, 0), 1, 3, Color3.new(1,1,1), 11

local Main = Instance.new("Frame", ScreenGui)
Main.Size, Main.Position, Main.BackgroundColor3, Main.BorderColor3, Main.Visible = UDim2.new(0, 210, 0, 200), UDim2.new(0.5, -105, 0.5, -100), Color3.fromRGB(12, 12, 12), Color3.fromRGB(40, 40, 40), false
local RGBLine = Instance.new("Frame", Main); RGBLine.Size, RGBLine.BorderSizePixel = UDim2.new(1, 0, 0, 4), 0
local Grad = Instance.new("UIGradient", RGBLine); Grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.5, _G.AccentColor), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))})
local TabBar = Instance.new("Frame", Main); TabBar.Size, TabBar.Position, TabBar.BackgroundColor3 = UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 4), Color3.fromRGB(18, 18, 18)
local Container = Instance.new("Frame", Main); Container.Size, Container.Position, Container.BackgroundTransparency = UDim2.new(1, -8, 1, -26), UDim2.new(0, 4, 0, 24), 1

local function createTab(name, pos)
    local btn = Instance.new("TextButton", TabBar); btn.Size, btn.Position, btn.BackgroundTransparency, btn.Text, btn.Font, btn.TextColor3, btn.TextSize = UDim2.new(0.25, 0, 1, 0), UDim2.new(0.25 * pos, 0, 0, 0), 1, name, 3, (pos == 0 and Color3.new(1,1,1) or Color3.fromRGB(100, 100, 100)), 9
    local page = Instance.new("ScrollingFrame", Container); page.Size, page.BackgroundTransparency, page.Visible, page.CanvasSize, page.ScrollBarThickness = UDim2.new(1, 0, 1, 0), 1, (pos == 0), UDim2.new(0, 0, 0, 380), 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 2)
    btn.MouseButton1Click:Connect(function() for _, v in pairs(Container:GetChildren()) do v.Visible = false end for _, v in pairs(TabBar:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(100, 100, 100) end end page.Visible, btn.TextColor3 = true, Color3.new(1,1,1) end)
    return page
end

local mP, rP, vP, miP = createTab("MOVE", 0), createTab("RAGE", 1), createTab("VIS", 2), createTab("MISC", 3)
local function addToggle(n, v, p, k, cb)
    local f = Instance.new("Frame", p); f.Size, f.BackgroundTransparency = UDim2.new(1, 0, 0, 15), 1
    local b = Instance.new("TextButton", f); b.Size, b.Position, b.BackgroundColor3, b.BorderSizePixel, b.Text = UDim2.new(0, 6, 0, 6), UDim2.new(0, 5, 0.5, -3), _G[v] and _G.AccentColor or Color3.fromRGB(35, 35, 35), 0, ""
    local l = Instance.new("TextLabel", f); l.Text, l.Position, l.Size, l.BackgroundTransparency, l.TextColor3, l.Font, l.TextSize, l.TextXAlignment = n:upper(), UDim2.new(0, 18, 0, 0), UDim2.new(1, -18, 1, 0), 1, _G[v] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150), 3, 8, 0
    b.MouseButton1Click:Connect(function() _G[v] = not _G[v]; b.BackgroundColor3 = _G[v] and _G.AccentColor or Color3.fromRGB(35, 35, 35); l.TextColor3 = _G[v] and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); if cb then cb(_G[v]) end end)
end

-- Setup Tabs
addToggle("Pixel Surf", "PixelSurfEnabled", mP)
addToggle("Edge Bug", "EdgeBugEnabled", mP)
addToggle("Jump Bug", "JumpBugEnabled", mP)
addToggle("Bhop", "BhopEnabled", mP)
addToggle("Walk Speed", "WalkSpeedEnabled", mP)
addToggle("Aimbot", "AimbotEnabled", rP)
addToggle("ESP Charms", "EspCharmsEnabled", vP)
if IsCounterBlox then addToggle("No-Spread", "NoSpreadEnabled", miP, nil, function(V) if V then scan_for_weapons() apply_no_spread_all() else restore_spread_all() end end) end

RunService.Heartbeat:Connect(function(dt)
    local c = Player.Character; local r = c and c:FindFirstChild("HumanoidRootPart"); local h = c and c:FindFirstChild("Humanoid")
    if not r or not h then return end
    VelLabel.Visible, VelLabel.Text = _G.ShowVelocity, math.floor(Vector2.new(r.Velocity.X, r.Velocity.Z).Magnitude)
    h.WalkSpeed = _G.WalkSpeedEnabled and _G.WalkSpeedValue or 16
    Lighting.ClockTime = _G.NightModeEnabled and 1 or 14
    if _G.AntiAimEnabled then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(_G.AntiAimSpeed * dt * 10), 0) end
    if _G.BhopEnabled and UserInputService:IsKeyDown(_G.BhopKey) and h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
    
    if _G.JumpBugEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local ray = workspace:Raycast(r.Position, Vector3.new(0, -h.HipHeight - 2.5, 0))
        if ray and r.Velocity.Y < -5 then h:ChangeState(3); r.Velocity = Vector3.new(r.Velocity.X, h.JumpPower + 5, r.Velocity.Z) end
    end
    if _G.EdgeBugEnabled and UserInputService:IsKeyDown(_G.EdgeBugKey) then
        local ray = workspace:Raycast(r.Position, Vector3.new(0, -5, 0))
        if not ray and h.FloorMaterial == Enum.Material.Air and r.Velocity.Y < -5 then r.Velocity = Vector3.new(r.Velocity.X, -0.001, r.Velocity.Z) end
    end
end)

RunService.RenderStepped:Connect(function()
    for _, v in pairs(Players:GetPlayers()) do if v ~= Player and v.Character then local h = v.Character:FindFirstChild("ValCharms") if h then h.Enabled = _G.EspCharmsEnabled end end end
    if _G.NoRecoilEnabled then Camera.CFrame = Camera.CFrame * CFrame.Angles(math.random(-_G.RecoilStrength, _G.RecoilStrength)/100, math.random(-_G.RecoilStrength, _G.RecoilStrength)/100, 0) end
    Grad.Offset = Vector2.new(math.sin(tick() * 1.5) * 0.5, 0)
    Watermark.Visible = _G.WatermarkEnabled
    WText.Text = string.format(" valware.cc | %d fps | %d ms ", math.floor(1/RunService.RenderStepped:Wait()), math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
    if _G.AimbotEnabled and IsTargeting then local t = GetClosestPlayer() if t then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), _G.AimbotSmoothness) end end
end)

UserInputService.InputBegan:Connect(function(i, g) if not g then if i.KeyCode == _G.MenuKey then Main.Visible = not Main.Visible end if i.KeyCode == _G.AimbotKey then IsTargeting = true end end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == _G.AimbotKey then IsTargeting = false end end)
