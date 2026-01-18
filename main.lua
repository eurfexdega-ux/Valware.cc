-- [[ VALWARE - MOVEMENT V2.6 PC | FULL MERGED & FIXED ]] --

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ================= GLOBAL SETTINGS =================
_G.EdgeBugEnabled = false
_G.PixelSurfEnabled = false
_G.JumpBugEnabled = false
_G.AirStuckEnabled = false
_G.BhopEnabled = false
_G.WalkSpeedEnabled = false
_G.WalkSpeedValue = 16
_G.HitboxEnabled = false
_G.HitboxSize = 5
_G.HitboxTransparency = 0.5
_G.WatermarkEnabled = true
_G.ShowVelocity = true
_G.ShowNotifs = true
_G.EspBoxEnabled = false
_G.NightModeEnabled = false
_G.FullBrightEnabled = false
_G.AccentColor = Color3.fromRGB(52, 115, 204)
_G.PixelSurfKey = Enum.KeyCode.Unknown
_G.EdgeBugKey = Enum.KeyCode.Unknown
_G.AirStuckKey = Enum.KeyCode.Unknown
_G.BhopKey = Enum.KeyCode.Unknown
_G.JumpBugKey = Enum.KeyCode.Unknown
_G.MenuKey = Enum.KeyCode.End

-- ================= WATERMARK =================
local Watermark = Instance.new("ScreenGui", game.CoreGui)
local WatermarkFrame = Instance.new("Frame", Watermark)
WatermarkFrame.Size = UDim2.new(0, 220, 0, 25); WatermarkFrame.Position = UDim2.new(0, 10, 0, 10)
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); WatermarkFrame.BorderSizePixel = 1; WatermarkFrame.BorderColor3 = _G.AccentColor
local WatermarkText = Instance.new("TextLabel", WatermarkFrame)
WatermarkText.Size = UDim2.new(1, 0, 1, 0); WatermarkText.BackgroundTransparency = 1; WatermarkText.Font = Enum.Font.Code; WatermarkText.TextColor3 = Color3.fromRGB(220, 220, 220); WatermarkText.TextSize = 13

task.spawn(function()
    while task.wait(0.5) do
        WatermarkFrame.Visible = _G.WatermarkEnabled
        local fps = math.floor(1/RunService.RenderStepped:Wait())
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        WatermarkText.Text = string.format("valware.cc | FPS: %d | PING: %d", fps, ping)
    end
end)

-- ================= UI ROOT (PC ONLY) =================
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name = "Main"; MainFrame.Size = UDim2.new(0, 500, 0, 350); MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175); MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MainFrame.BorderSizePixel = 2; MainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40); MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.Visible = false

local InsideBorder = Instance.new("Frame", MainFrame); InsideBorder.Size = UDim2.new(1, -4, 1, -4); InsideBorder.Position = UDim2.new(0, 2, 0, 2); InsideBorder.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
local TabBar = Instance.new("Frame", InsideBorder); TabBar.Size = UDim2.new(1, 0, 0, 30); TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

local function createTabBtn(txt, xPos)
    local b = Instance.new("TextButton", TabBar); b.Size = UDim2.new(0, 90, 1, 0); b.Position = UDim2.new(0, xPos, 0, 0); b.Text = txt; b.Font = Enum.Font.Code; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.BackgroundTransparency = 1; b.TextSize = 11; return b
end

local mTab = createTabBtn("MOVEMENT", 0); mTab.TextColor3 = _G.AccentColor
local rTab = createTabBtn("RAGE", 90); local vTab = createTabBtn("VISUAL", 180); local miTab = createTabBtn("MISC", 270)

local function createPage()
    local p = Instance.new("ScrollingFrame", InsideBorder); p.Size = UDim2.new(1, -20, 1, -40); p.Position = UDim2.new(0, 10, 0, 35); p.BackgroundTransparency = 1; p.CanvasSize = UDim2.new(0,0,0,450); p.ScrollBarThickness = 2; p.Visible = false; Instance.new("UIListLayout", p).Padding = UDim.new(0,6); return p
end

local mPage = createPage(); mPage.Visible = true; local rPage = createPage(); local vPage = createPage(); local miPage = createPage()
local function switch(p, t) mPage.Visible = false; rPage.Visible = false; vPage.Visible = false; miPage.Visible = false; mTab.TextColor3 = Color3.fromRGB(150,150,150); rTab.TextColor3 = Color3.fromRGB(150,150,150); vTab.TextColor3 = Color3.fromRGB(150,150,150); miTab.TextColor3 = Color3.fromRGB(150,150,150); p.Visible = true; t.TextColor3 = _G.AccentColor end
mTab.MouseButton1Click:Connect(function() switch(mPage, mTab) end); rTab.MouseButton1Click:Connect(function() switch(rPage, rTab) end); vTab.MouseButton1Click:Connect(function() switch(vPage, vTab) end); miTab.MouseButton1Click:Connect(function() switch(miPage, miTab) end)

local function createToggle(txt, var, p)
    local btn = Instance.new("TextButton", p); btn.Size = UDim2.new(1,0,0,28); btn.BackgroundTransparency = 1; btn.Text = ""
    local box = Instance.new("Frame", btn); box.Size = UDim2.new(0,14,0,14); box.Position = UDim2.new(0,5,0.5,-7); box.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(40,40,40)
    local lbl = Instance.new("TextLabel", btn); lbl.Text = txt:upper(); lbl.Position = UDim2.new(0,25,0,0); lbl.Size = UDim2.new(1,-30,1,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(200,200,200); lbl.Font = Enum.Font.Code; lbl.TextXAlignment = 0
    btn.MouseButton1Click:Connect(function() _G[var] = not _G[var]; box.BackgroundColor3 = _G[var] and _G.AccentColor or Color3.fromRGB(40,40,40) end)
end

local function createKeybind(txt, var, p)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(1,0,0,28); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Text = txt:upper(); lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,5,0,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(150,150,150); lbl.Font = Enum.Font.Code; lbl.TextXAlignment = 0
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0,80,0,20); b.Position = UDim2.new(1,-85,0.5,-10); b.BackgroundColor3 = Color3.fromRGB(30,30,30); b.Text = _G[var].Name; b.TextColor3 = Color3.fromRGB(200,200,200); b.Font = Enum.Font.Code; b.TextSize = 11
    b.MouseButton1Click:Connect(function() b.Text = "..."; local c; c = UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then _G[var] = i.KeyCode; b.Text = i.KeyCode.Name; c:Disconnect() end end) end)
end

local function createSlider(txt, min, max, def, var, p, isFloat)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(1,0,0,40); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Text = txt:upper()..": "..def; lbl.Size = UDim2.new(1,0,0,15); lbl.Position = UDim2.new(0,5,0,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(180,180,180); lbl.Font = Enum.Font.Code; lbl.TextXAlignment = 0
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(1,-20,0,4); bg.Position = UDim2.new(0,5,0,22); bg.BackgroundColor3 = Color3.fromRGB(40,40,40); bg.BorderSizePixel = 0
    local fill = Instance.new("Frame", bg); fill.Size = UDim2.new((def-min)/(max-min),0,1,0); fill.BackgroundColor3 = _G.AccentColor
    local drag = false
    local function up(i) local x = math.clamp((i.Position.X - bg.AbsolutePosition.X)/bg.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(x,0,1,0); local val = min + (max-min)*x; _G[var] = isFloat and math.floor(val*10)/10 or math.floor(val); lbl.Text = txt:upper()..": ".._G[var] end
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true up(i) end end)
    UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement) then up(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
end

-- POPULATE TABS
createToggle("Pixel Surf", "PixelSurfEnabled", mPage); createKeybind("Surf Bind", "PixelSurfKey", mPage)
createToggle("Edge Bug", "EdgeBugEnabled", mPage); createKeybind("Edge Bug Bind", "EdgeBugKey", mPage)
createToggle("Jump Bug", "JumpBugEnabled", mPage); createKeybind("Jump Bug Bind", "JumpBugKey", mPage)
createToggle("Air Stuck", "AirStuckEnabled", mPage); createKeybind("Stuck Bind", "AirStuckKey", mPage)
createToggle("Bhop", "BhopEnabled", mPage); createKeybind("Bhop Bind", "BhopKey", mPage)
createToggle("Walk Speed", "WalkSpeedEnabled", mPage); createSlider("Value", 16, 200, 16, "WalkSpeedValue", mPage)
createToggle("Hitbox Head", "HitboxEnabled", rPage); createSlider("Size", 1, 20, 5, "HitboxSize", rPage); createSlider("Transparency", 0, 1, 0.5, "HitboxTransparency", rPage, true)
createToggle("ESP Box", "EspBoxEnabled", vPage); createToggle("Night Mode", "NightModeEnabled", vPage); createToggle("Full Bright", "FullBrightEnabled", vPage)
createToggle("Watermark", "WatermarkEnabled", miPage); createToggle("Show Velocity", "ShowVelocity", miPage); createToggle("Show Notifications", "ShowNotifs", miPage); createKeybind("Menu Toggle", "MenuKey", miPage)

-- ================= LOGIC =================
local function notify(txt) if not _G.ShowNotifs then return end local nl = Instance.new("TextLabel", ScreenGui); nl.Size = UDim2.new(0,120,0,20); nl.Position = UDim2.new(0.5,-60,0.585,0); nl.BackgroundTransparency = 1; nl.Font = Enum.Font.Code; nl.TextColor3 = _G.AccentColor; nl.Text = txt; task.spawn(function() task.wait(0.3); TweenService:Create(nl, TweenInfo.new(0.2), {TextTransparency = 1}):Play(); task.wait(0.2); nl:Destroy() end) end
local VelLabel = Instance.new("TextLabel", ScreenGui); VelLabel.Size = UDim2.new(0,90,0,16); VelLabel.Position = UDim2.new(0.5,-45,0.55,0); VelLabel.BackgroundTransparency = 1; VelLabel.Font = Enum.Font.Code; VelLabel.TextColor3 = Color3.fromRGB(220,220,220)

RunService.Stepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            if _G.HitboxEnabled then 
                head.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                head.Transparency = _G.HitboxTransparency
                head.Massless = true; head.CanCollide = true
            else 
                head.Size = Vector3.new(1.15, 1.15, 1.15); head.Transparency = 0 
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local char = Player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    VelLabel.Visible = _G.ShowVelocity; VelLabel.Text = math.floor((root.Velocity * Vector3.new(1,0,1)).Magnitude)
    if _G.WalkSpeedEnabled then hum.WalkSpeed = _G.WalkSpeedValue else hum.WalkSpeed = 16 end
    Lighting.ClockTime = _G.NightModeEnabled and 1 or 14
    if _G.FullBrightEnabled then Lighting.Ambient = Color3.new(1,1,1) end

    -- [[ MOVEMENT LOGIC: HOLD TO ACTIVATE ]]
    if _G.JumpBugEnabled and _G.JumpBugKey ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(_G.JumpBugKey) then
        if root.Velocity.Y < -1 then
            local p = RaycastParams.new(); p.FilterDescendantsInstances = {char}
            if workspace:Raycast(root.Position, Vector3.new(0, -3.2, 0), p) then hum:ChangeState(Enum.HumanoidStateType.Jumping) notify("JB") end
        end
    end

    if _G.AirStuckEnabled and _G.AirStuckKey ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(_G.AirStuckKey) then root.Anchored = true else root.Anchored = false end

    if _G.BhopEnabled and _G.BhopKey ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(_G.BhopKey) then
        if root.Velocity.Magnitude >= 8 and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
    end

    if _G.PixelSurfEnabled and _G.PixelSurfKey ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(_G.PixelSurfKey) and hum.FloorMaterial == Enum.Material.Air then
        local ray = workspace:Raycast(root.Position, Camera.CFrame.LookVector * 4, RaycastParams.new())
        if ray then
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            local flatVel = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
            local surfDir = (flatVel - ray.Normal * flatVel:Dot(ray.Normal)).Unit
            root.Velocity = Vector3.new(surfDir.X * 24, root.Velocity.Y * 0.02, surfDir.Z * 24) - ray.Normal * 25; notify("PS")
        end
    end

    if _G.EdgeBugEnabled and _G.EdgeBugKey ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(_G.EdgeBugKey) and root.Velocity.Y < -5 then
        local p = RaycastParams.new(); p.FilterDescendantsInstances = {char}
        local downRay = workspace:Raycast(root.Position, Vector3.new(0,-6,0), p)
        if downRay then
            local ahead = workspace:Raycast(root.Position + (root.Velocity * Vector3.new(1,0,1)).Unit * 2, Vector3.new(0,-10,0), p)
            if not ahead then root.Velocity = (root.Velocity * Vector3.new(1,0,1)).Unit * 17 + Vector3.new(0,-25,0); notify("EB") end
        end
    end

    -- ESP BOX
    local espFolder = ScreenGui:FindFirstChild("ESP") or Instance.new("Folder", ScreenGui); espFolder.Name = "ESP"
    for _, plr in ipairs(Players:GetPlayers()) do
        local box = espFolder:FindFirstChild(plr.Name)
        if _G.EspBoxEnabled and plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local eRoot = plr.Character.HumanoidRootPart; local pos, onScreen = Camera:WorldToViewportPoint(eRoot.Position)
            if onScreen then
                if not box then box = Instance.new("Frame", espFolder); box.Name = plr.Name; box.BackgroundTransparency = 1; box.BorderColor3 = _G.AccentColor; local s = Instance.new("UIStroke", box); s.Thickness = 1; s.Color = _G.AccentColor end
                local hPos = Camera:WorldToViewportPoint(plr.Character.Head.Position + Vector3.new(0, 0.5, 0)); local lPos = Camera:WorldToViewportPoint(eRoot.Position - Vector3.new(0, 3, 0))
                local h = math.abs(hPos.Y - lPos.Y); local w = h / 1.5; box.Size = UDim2.new(0, w, 0, h); box.Position = UDim2.new(0, pos.X - w/2, 0, pos.Y - h/2); box.Visible = true
            elseif box then box.Visible = false end
        elseif box then box:Destroy() end
    end
end)

UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == _G.MenuKey then MainFrame.Visible = not MainFrame.Visible end end)
