-- Ghost Gallery | Safe Inspector v1
-- Inspection only: never sends data, loads code, fires remotes or teleports.
-- Use inside the Ghost Gallery round while aiming at a ghost or possessed furniture.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local guiRoot = player:WaitForChild("PlayerGui")
local existing = guiRoot:FindFirstChild("GhostGallerySafeInspector")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "GhostGallerySafeInspector"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = guiRoot

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(350, 330)
frame.Position = UDim2.new(0.5, -175, 0.5, -165)
frame.BackgroundColor3 = Color3.fromRGB(26, 20, 46)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(154, 92, 242)
stroke.Thickness = 2
stroke.Parent = frame

local function label(text, y, size, color)
    local l = Instance.new("TextLabel")
    l.Position = UDim2.fromOffset(12,y)
    l.Size = UDim2.new(1,-24,0,size)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(247,237,255)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = frame
    return l
end
local title = label("👻 GHOST GALLERY | SAFE INSPECTOR", 9, 24)
title.Font = Enum.Font.GothamBold
local status = label("Enter a round, aim at a ghost, then AIM PICK", 34, 24, Color3.fromRGB(192,174,220))

local function button(text, x, width, callback)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(x,0,0,63)
    b.Size = UDim2.new(width,-7,0,34)
    b.BackgroundColor3 = Color3.fromRGB(95,56,158)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.Parent = frame
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(callback)
end
local output = Instance.new("TextBox")
output.Position = UDim2.fromOffset(12, 106)
output.Size = UDim2.new(1,-24,1,-118)
output.Text = "Press SCAN or AIM PICK to collect local object names.\nNo code is sent anywhere."
output.TextColor3 = Color3.fromRGB(238,228,255)
output.BackgroundColor3 = Color3.fromRGB(17,13,30)
output.BorderSizePixel = 0
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.MultiLine = true
output.ClearTextOnFocus = false
output.TextEditable = false
output.Parent = frame
Instance.new("UICorner",output).CornerRadius = UDim.new(0,8)

local report = ""
local function fullpath(inst)
    if not inst then return "none" end
    local parts = {}
    local node = inst
    while node and #parts < 12 do
        table.insert(parts, 1, node.Name .. "<" .. node.ClassName .. ">")
        node = node.Parent
    end
    return table.concat(parts,"/")
end
local function appendInfo(lines, obj, tag)
    if not obj then return end
    table.insert(lines, tag .. ": " .. fullpath(obj))
    if obj:IsA("BasePart") then
        table.insert(lines, "  size="..tostring(obj.Size).." anchored="..tostring(obj.Anchored))
    end
    if obj.Parent then table.insert(lines,"  parent="..fullpath(obj.Parent)) end
end
local function present(lines, message)
    report = table.concat(lines,"\n")
    output.Text = report
    status.Text = message .. " — COPY to share with ChatGPT"
    print("[GhostGallery Safe Inspector]", report)
end
local function currentTool()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildWhichIsA("Tool")
end
local function toolInfo(lines)
    local tool = currentTool()
    appendInfo(lines,tool,"EQUIPPED TOOL")
    if tool then
        local n = 0
        for _, obj in ipairs(tool:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("Attachment") or obj:IsA("Beam") or obj:IsA("ParticleEmitter") then
                table.insert(lines,"  + "..fullpath(obj))
                n += 1
                if n >= 20 then break end
            end
        end
    end
end
button("AIM PICK", 0.035, 0.31, function()
    local lines = {"GHOST GALLERY AIM PICK", "Place: " .. tostring(game.PlaceId)}
    local target = player:GetMouse().Target
    appendInfo(lines, target, "MOUSE TARGET")
    local camera = Workspace.CurrentCamera
    if camera then
        local view = camera.ViewportSize
        local ray = camera:ViewportPointToRay(view.X/2, view.Y/2)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = player.Character and {player.Character} or {}
        local hit = Workspace:Raycast(ray.Origin, ray.Direction*300, params)
        appendInfo(lines, hit and hit.Instance, "CENTER RETICLE RAYCAST")
    end
    toolInfo(lines)
    present(lines,"AIM PICK complete")
end)
button("SCAN", 0.36, 0.27, function()
    local lines = {"GHOST GALLERY SCAN", "Place: " .. tostring(game.PlaceId)}
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local count = 0
    local terms = "ghost|haunt|possess|gallery|manor|blast|boss|spirit|specter|spectre"
    table.insert(lines,"Filter: "..terms)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("ghost") or name:find("haunt") or name:find("possess") or name:find("gallery") or name:find("manor") or name:find("blast") or name:find("boss") or name:find("spirit") or name:find("specter") or obj:IsA("Highlight") then
            local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and obj.PrimaryPart) or obj:FindFirstAncestorWhichIsA("Model")
            if part and part:IsA("Model") then part = part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart",true) end
            local dist = root and part and part:IsA("BasePart") and (part.Position - root.Position).Magnitude
            if not dist or dist < 350 then
                count += 1
                table.insert(lines, ("%d. %s%s"):format(count,fullpath(obj),dist and (" dist="..math.floor(dist)) or ""))
                if count >= 75 then break end
            end
        end
    end
    if count == 0 then table.insert(lines,"No keyword/highlight candidates visible") end
    toolInfo(lines)
    present(lines,"SCAN: "..count.." candidates")
end)
button("COPY", 0.65, 0.315, function()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard,report)
        status.Text = ok and "Copied! Paste the report into ChatGPT" or "Copy blocked; select text below"
    else
        status.Text = "Clipboard API unavailable. Select text below or use F9 console"
        output.TextEditable = true
    end
end)
local dragging = false
local startInput, startPosition
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y <= frame.AbsolutePosition.Y + 57 then
            dragging = true
            startInput = input.Position
            startPosition = frame.Position
        end
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startInput
        frame.Position = UDim2.new(startPosition.X.Scale,startPosition.X.Offset + delta.X,startPosition.Y.Scale,startPosition.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
