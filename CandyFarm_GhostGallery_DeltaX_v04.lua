-- CandyFarm | Ghost Gallery 2026 | UI v0.3.1 (DeltaX startup fix)
-- Static script: NO HttpGet, NO loadstring, NO webhook, NO network calls.
-- Third-party Adopt Me internals are NOT known. Assistance features are best-effort.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
if not PlayerGui then return end

local sharedEnv = (type(getgenv) == "function" and getgenv()) or _G
if sharedEnv.CandyFarm2026 and sharedEnv.CandyFarm2026.Stop then
    pcall(sharedEnv.CandyFarm2026.Stop)
end

local state = {
    Alive = true, Hunt = false, Teleport = false, Shoot = false,
    Queue = false, AntiAFK = false, PetHints = false,
    Target = nil, TargetModel = nil, LockedAt = 0, LostSince = nil,
    ShotsOnTarget = 0, Cleared = 0, LastScan = 0,
    LastShot = 0, LastTP = 0, LastQueue = 0, LastNeeds = 0,
    NeedInfo = "Not scanned", Message = "Ready",
    Connections = {}
}
sharedEnv.CandyFarm2026 = state

local C = {
    BG = Color3.fromRGB(16, 13, 29),
    Panel = Color3.fromRGB(27, 21, 45),
    Surface = Color3.fromRGB(39, 30, 60),
    Surface2 = Color3.fromRGB(49, 38, 73),
    Purple = Color3.fromRGB(172, 100, 255),
    Orange = Color3.fromRGB(255, 165, 75),
    Text = Color3.fromRGB(250, 244, 255),
    Muted = Color3.fromRGB(170, 154, 193),
    Green = Color3.fromRGB(100, 230, 166),
    Red = Color3.fromRGB(248, 105, 127)
}

local function corner(parent, radius)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, radius or 12)
    u.Parent = parent
    return u
end

local function stroke(parent, color, alpha, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Purple
    s.Transparency = alpha or 0
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function tw(obj, props, speed)
    local anim = TweenService:Create(obj, TweenInfo.new(speed or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    anim:Play()
    return anim
end

local function text(parent, value, size, color, bold)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    t.TextSize = size or 13
    t.TextColor3 = color or C.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = parent
    return t
end

local function button(parent, name, color)
    local b = Instance.new("TextButton")
    b.Text = name
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = C.Text
    b.BackgroundColor3 = color or C.Surface2
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 9)
    return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "CandyFarm_GhostGallery_2026"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 99
gui.Parent = PlayerGui

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(.5,.5)
shadow.Size = UDim2.fromOffset(370, 440)
shadow.Position = UDim2.fromScale(.5,.52)
shadow.BackgroundColor3 = Color3.fromRGB(4,3,8)
shadow.BackgroundTransparency = .42
shadow.Parent = gui
corner(shadow, 20)

local main = Instance.new("Frame")
main.Name = "Panel"
main.Size = UDim2.fromOffset(354, 424)
main.Position = UDim2.fromOffset(8,8)
main.BackgroundColor3 = C.BG
main.Parent = shadow
corner(main, 17)
stroke(main, C.Purple, .52, 1.4)

local maxWidth = math.min(1, (Workspace.CurrentCamera.ViewportSize.X - 24) / 370)
local scale = Instance.new("UIScale")
scale.Scale = math.max(.68, maxWidth)
scale.Parent = shadow

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,88)
header.BackgroundColor3 = C.Panel
header.Parent = main
corner(header, 17)

local hgrad = Instance.new("UIGradient")
hgrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(75,40,111)), ColorSequenceKeypoint.new(1, C.Panel)})
hgrad.Rotation = 15
hgrad.Parent = header

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1,0,0,4)
accent.BackgroundColor3 = C.Purple
accent.BorderSizePixel = 0
accent.Parent = main
corner(accent, 3)

local pumpkin = text(header, "C", 31, C.Orange, true)
pumpkin.Position = UDim2.fromOffset(16,12)
pumpkin.Size = UDim2.fromOffset(35,40)

local title = text(header, "CANDYFARM", 20, C.Text, true)
title.Position = UDim2.fromOffset(55,11)
title.Size = UDim2.fromOffset(196,30)

local subtitle = text(header, "GHOST GALLERY  /  HALLOWEEN 2026", 10, C.Muted, true)
subtitle.Position = UDim2.fromOffset(56,41)
subtitle.Size = UDim2.fromOffset(235,21)

local version = text(header,"v0.3.1",10,C.Orange,true)
version.Position = UDim2.fromOffset(16,60)
version.Size = UDim2.fromOffset(50,20)

local close = button(header,"X", Color3.fromRGB(115,47,74))
close.Position = UDim2.fromOffset(311,14)
close.Size = UDim2.fromOffset(27,27)
close.MouseButton1Click:Connect(function() gui:Destroy() state.Alive = false end)

local minimize = button(header,"-",C.Surface2)
minimize.Position = UDim2.fromOffset(278,14)
minimize.Size = UDim2.fromOffset(27,27)

local tabs = Instance.new("Frame")
tabs.BackgroundTransparency=1
tabs.Position=UDim2.fromOffset(12,99)
tabs.Size=UDim2.new(1,-24,0,36)
tabs.Parent=main

local tabGhost = button(tabs,"GHOST GALLERY",C.Purple)
tabGhost.Size = UDim2.new(.5,-4,1,0)

local tabPet = button(tabs,"PET / STATUS",C.Surface)
tabPet.Size=UDim2.new(.5,-4,1,0)
tabPet.Position=UDim2.new(.5,4,0,0)

local content = Instance.new("Frame")
content.Position=UDim2.fromOffset(12,144)
content.Size=UDim2.new(1,-24,0,219)
content.BackgroundTransparency=1
content.Parent=main

local ghosts = Instance.new("Frame")
ghosts.Size=UDim2.fromScale(1,1)
ghosts.BackgroundTransparency=1
ghosts.Parent=content

local pets = Instance.new("Frame")
pets.Size=UDim2.fromScale(1,1)
pets.BackgroundTransparency=1
pets.Visible=false
pets.Parent=content

local function selectTab(which)
    ghosts.Visible=(which=="ghost")
    pets.Visible=(which=="pet")
    tw(tabGhost,{BackgroundColor3=(which=="ghost") and C.Purple or C.Surface})
    tw(tabPet,{BackgroundColor3=(which=="pet") and C.Purple or C.Surface})
end
tabGhost.MouseButton1Click:Connect(function() selectTab("ghost") end)
tabPet.MouseButton1Click:Connect(function() selectTab("pet") end)

local function setting(parent, index, name, description, key)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,48)
    row.Position=UDim2.fromOffset(0,(index-1)*54)
    row.BackgroundColor3=C.Panel
    row.Parent=parent
    corner(row,10)
    local lab=text(row,name,13,C.Text,true)
    lab.Position=UDim2.fromOffset(12,5)
    lab.Size=UDim2.new(1,-95,0,21)
    local sub=text(row,description,10,C.Muted,false)
    sub.Position=UDim2.fromOffset(12,25)
    sub.Size=UDim2.new(1,-92,0,16)
    local b=button(row,"OFF",C.Surface2)
    b.Position=UDim2.new(1,-70,0,9)
    b.Size=UDim2.fromOffset(60,30)
    local function refresh()
        b.Text=state[key] and "ON" or "OFF"
        tw(b,{BackgroundColor3=state[key] and C.Purple or C.Surface2})
    end
    b.MouseButton1Click:Connect(function()
        state[key]=not state[key]
        refresh()
    end)
    refresh()
end

setting(ghosts,1,"Target lock","Stay on one ghost until defeated","Hunt")
setting(ghosts,2,"Teleport to target","Move close to the LOCKED ghost","Teleport")
setting(ghosts,3,"Aim + blaster","Face and shoot the same ghost","Shoot")
setting(ghosts,4,"Queue prompt","Use nearby JOIN prompts only","Queue")
setting(pets,1,"Anti AFK","Attempt to prevent idle disconnect","AntiAFK")
setting(pets,2,"Pet needs hints","Look for visible pet task labels","PetHints")

local notice = text(pets,"Ghost targeting/defeat is best-effort.\nNo verified Adopt Me internals.",11,C.Orange,false)
notice.Position = UDim2.fromOffset(0, 110)
notice.Size = UDim2.new(1,0,0,40)

-- // ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ЛОГИКИ // --

local function getClosestGhost()
    local character = LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, minDist = nil, math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (string.find(obj.Name, "Ghost") or string.find(obj.Name, "Призрак")) then
            local p = obj:FindFirstChildWhichIsA("BasePart")
            if p then
                local dist = (root.Position - p.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

local function teleportTo(position)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

local function fireBlaster()
    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    state.LastShot = tick()
end

local function fireProximityPrompt(prompt)
    if fireprompttrigger then
        fireprompttrigger(prompt)
    else
        prompt:InputBegan(Enum.UserInputType.Keyboard)
        task.wait(0.1)
        prompt:InputEnded(Enum.UserInputType.Keyboard)
    end
end

-- // ГЛАВНЫЕ ПОТОКИ АВТОМАТИЗАЦИИ // --

task.spawn(function()
    while state.Alive do
        task.wait(0.1)
        
        if state.Hunt then
            if not state.Target or not state.Target:Parent() then
            state.Target = getClosestGhost()
        end

        if state.Target then
            local targetPart = state.Target:FindFirstChildWhichIsA("BasePart")
            if targetPart and state.Teleport then
                teleportTo(targetPart.Position + Vector3.new(0, 0, 4))
            end

            if state.Shoot and tick() - state.LastShot > 0.5 then
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and targetPart then
                    root.CFrame = CFrame.new(root.Position, Vector3.new(targetPart.Position.X, root.Position.Y, targetPart.Position.Z))
                    fireBlaster()
                end
            end
        else
            if state.Teleport and tick() - state.LastTP > 5 then
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (string.find(obj.Name, "Halloween") or string.find(obj.Name, "Event Portal") or string.find(obj.Name, "GhostGalleryEntrance")) then
                        teleportTo(obj.Position)
                        state.LastTP = tick()
                        break
                    end
                end
            end
        end
    end

    if state.Queue and tick() - state.LastQueue > 3 then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and (string.find(obj.ObjectText, "Join") or string.find(obj.ActionText, "Join")) then
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - obj.Parent.Position).Magnitude < 15 then
                    fireProximityPrompt(obj)
                    state.LastQueue = tick()
                end
            end
        end
    end
end
end)

task.spawn(function()
while state.Alive do
    task.wait(10)
    if state.AntiAFK then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(0.2)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
    end
end
end)

state.Stop = function()
state.Alive = false
if gui then gui:Destroy() end
end

local dragging, dragInput, dragStart, startPos
UserInputService.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    local mousePos = UserInputService:GetMouseLocation()
    if mousePos.X >= header.AbsolutePosition.X and mousePos.X <= header.AbsolutePosition.X + header.AbsoluteSize.X and
       mousePos.Y >= header.AbsolutePosition.Y and mousePos.Y <= header.AbsolutePosition.Y + header.AbsoluteSize.Y then
        dragging = true
        dragStart = input.Position
        startPos = shadow.Position
    end
end
end)

UserInputService.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
    dragInput = input
end
end)

RunService.RenderStepped:Connect(function()
if dragging and dragInput then
    local delta = dragInput.Position - dragStart
    shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)

UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    dragging = false
end
end)
