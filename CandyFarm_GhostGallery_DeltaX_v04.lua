-- CandyFarm | Ghost Gallery 2026 | UI v0.4 (event TP + hold input beta)
-- Static script: NO HttpGet, NO loadstring, NO webhook, NO network calls.
-- Third-party Adopt Me internals are NOT known. Assistance features are best-effort.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local sharedEnv = (type(getgenv) == "function" and getgenv()) or _G
local previousMark = sharedEnv.CandyFarm2026 and sharedEnv.CandyFarm2026.EventMark
if sharedEnv.CandyFarm2026 and sharedEnv.CandyFarm2026.Stop then
    pcall(sharedEnv.CandyFarm2026.Stop)
end

local state = {
    Alive = true, Hunt = false, Teleport = false, Shoot = false,
    Queue = false, AntiAFK = false, PetHints = false,
    HoldFire = false, FireHeld = false, EventTP = false,
    EventMark = previousMark, EventStatus = "Not searched",
    FireTarget = nil, LastEventTP = 0,
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
local success = pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
if not success then return end

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
local version = text(header,"v0.4 beta",10,C.Orange,true)
version.Position = UDim2.fromOffset(16,60)
version.Size = UDim2.fromOffset(50,20)
local close = button(header,"X", Color3.fromRGB(115,47,74))
close.Position = UDim2.fromOffset(311,14)
close.Size = UDim2.fromOffset(27,27)
local minimize = button(header,"-",C.Surface2)
minimize.Position = UDim2.fromOffset(278,14)
minimize.Size = UDim2.fromOffset(27,27)

local tabs = Instance.new("Frame")
tabs.BackgroundTransparency=1
 tabs.Position=UDim2.fromOffset(12,99)
tabs.Size=UDim2.new(1,-24,0,36)
tabs.Parent=main
local tabGhost = button(tabs,"GHOSTS",C.Purple)
tabGhost.Size = UDim2.new(1/3,-4,1,0)
local tabEvent = button(tabs,"EVENT TP",C.Surface)
tabEvent.Size=UDim2.new(1/3,-4,1,0)
tabEvent.Position=UDim2.new(1/3,2,0,0)
local tabPet = button(tabs,"PET / STATUS",C.Surface)
tabPet.Size=UDim2.new(1/3,-4,1,0)
tabPet.Position=UDim2.new(2/3,4,0,0)

local content = Instance.new("Frame")
content.Position=UDim2.fromOffset(12,144)
content.Size=UDim2.new(1,-24,0,219)
content.BackgroundTransparency=1
content.Parent=main
local ghosts = Instance.new("Frame")
ghosts.Size=UDim2.fromScale(1,1)
ghosts.BackgroundTransparency=1
ghosts.Parent=content
local event = Instance.new("Frame")
event.Size=UDim2.fromScale(1,1)
event.BackgroundTransparency=1
event.Parent=content
event.Visible=false
local pets = Instance.new("Frame")
pets.Size=UDim2.fromScale(1,1)
pets.BackgroundTransparency=1
pets.Parent=content
pets.Visible=false
local function selectTab(which)
    ghosts.Visible=(which=="ghost")
    event.Visible=(which=="event")
    pets.Visible=(which=="pet")
    tw(tabGhost,{BackgroundColor3=(which=="ghost") and C.Purple or C.Surface})
    tw(tabEvent,{BackgroundColor3=(which=="event") and C.Purple or C.Surface})
    tw(tabPet,{BackgroundColor3=(which=="pet") and C.Purple or C.Surface})
end
tabGhost.MouseButton1Click:Connect(function() selectTab("ghost") end)
tabEvent.MouseButton1Click:Connect(function() selectTab("event") end)
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
    state["Refresh_"..key] = refresh
    b.MouseButton1Click:Connect(function()
        state[key]=not state[key]
        refresh()
    end)
    refresh()
end

setting(ghosts,1,"Target lock","Stay on one candidate until it vanishes","Hunt")
setting(ghosts,2,"Teleport to target","Move close to the LOCKED candidate","Teleport")
setting(ghosts,3,"Aim + blaster","Aim camera; attempt to fire Tool","Shoot")
setting(ghosts,4,"Hold fire (BETA)","Hold input if Delta supports mouse1press","HoldFire")
setting(event,1,"Auto TP to Manor","One trip when entrance is detected","EventTP")
setting(event,2,"Queue prompt","Works ONLY for nearby Join prompts","Queue")
setting(pets,1,"Anti AFK","Attempt to prevent idle disconnect","AntiAFK")
setting(pets,2,"Pet needs hints","Look for visible pet task labels","PetHints")

local markEvent = button(event,"MARK HERE",C.Surface2)
markEvent.Position=UDim2.fromOffset(0,115)
markEvent.Size=UDim2.fromOffset(155,38)
local tpEventNow = button(event,"TP TO EVENT",C.Purple)
tpEventNow.Position=UDim2.fromOffset(166,115)
tpEventNow.Size=UDim2.fromOffset(164,38)
local eventInfo = text(event,"Event entrance unknown. Mark it once inside Manor.",11,C.Orange,false)
eventInfo.Position=UDim2.fromOffset(5,159)
eventInfo.Size=UDim2.new(1,-10,0,54)
eventInfo.TextWrapped=true

local notice = text(pets,"Combat status: ready.\nAttack inputs are not confirmed hits.",11,C.Orange,false)
notice.Position=UDim2.fromOffset(8,116)
notice.Size=UDim2.new(1,-16,0,50)
notice.TextWrapped=true
local hints=text(pets,"Detected needs: --",11,C.Muted,false)
hints.Position=UDim2.fromOffset(8,169)
hints.Size=UDim2.new(1,-16,0,37)
hints.TextWrapped=true

local footer = Instance.new("Frame")
footer.Position = UDim2.fromOffset(12,372)
footer.Size = UDim2.new(1,-24,0,40)
footer.BackgroundColor3=C.Panel
footer.Parent=main
corner(footer,10)
local dot = Instance.new("Frame")
dot.Size=UDim2.fromOffset(8,8)
dot.Position=UDim2.fromOffset(10,16)
dot.BackgroundColor3=C.Green
 dot.Parent=footer
corner(dot,8)
local status = text(footer,"READY  |  Experimental assistance",10,C.Muted,false)
status.Position=UDim2.fromOffset(25,6)
status.Size=UDim2.new(1,-100,1,-12)
local unlock=button(footer,"UNLOCK",C.Surface2)
unlock.Size=UDim2.fromOffset(75,28)
unlock.Position=UDim2.new(1,-82,0,6)
unlock.TextSize=10

-- Mobile + mouse dragging via header (rather than deprecated Draggable)
do
    local dragging=false
    local dragStart, startPos
    local dragInput
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=shadow.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            dragInput=input
        end
    end)
    table.insert(state.Connections,UserInputService.InputChanged:Connect(function(input)
        if dragging and input==dragInput and dragStart and startPos then
            local delta=input.Position-dragStart
            shadow.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end))
end
local minimized=false
minimize.MouseButton1Click:Connect(function()
    minimized=not minimized
    tabs.Visible=not minimized
    content.Visible=not minimized
    footer.Visible=not minimized
    shadow.Size=minimized and UDim2.fromOffset(370,105) or UDim2.fromOffset(370,440)
    main.Size=minimized and UDim2.fromOffset(354,89) or UDim2.fromOffset(354,424)
    minimize.Text=minimized and "+" or "-"
end)
-- Release executor mouse input whenever the target/mode changes or script closes.
local function releaseHeldFire()
    if state.FireHeld and type(mouse1release) == "function" then
        pcall(mouse1release)
    end
    state.FireHeld = false
    state.FireTarget = nil
end

function state.Stop()
    if not state.Alive then return end
    state.Alive=false
    releaseHeldFire()
    for _,connection in ipairs(state.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    state.Target=nil
    state.TargetModel=nil
    gui:Destroy()
    if sharedEnv.CandyFarm2026==state then sharedEnv.CandyFarm2026=nil end
end
close.MouseButton1Click:Connect(state.Stop)

local function myRoot()
    local character=LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
-- Experimental candidates: Adopt Me's private ghost/furniture tags are unknown.
-- Pick a BasePart, but lock onto its Model identity when appropriate.
local function ghostCandidate(obj)
    if not obj:IsA("BasePart") then return false end
    if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return false end
    local n=obj.Name:lower()
    local model=obj:FindFirstAncestorOfClass("Model")
    local mn=model and model.Name:lower() or ""
    local matches=n:find("ghost",1,true) or n:find("possessed",1,true)
        or n:find("haunted",1,true) or mn:find("ghost",1,true)
        or mn:find("possessed",1,true)
    local highlight=(model and model:FindFirstChildOfClass("Highlight"))
        or obj:FindFirstChildOfClass("Highlight")
    return matches or (highlight and highlight.Enabled)
end

local function scanTarget()
    local root=myRoot()
    if not root then return nil, nil end
    local best, bestModel, distance=nil,nil,math.huge
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if ghostCandidate(obj) then
            local d=(obj.Position-root.Position).Magnitude
            if d<distance then
                best, bestModel, distance=obj,obj:FindFirstAncestorOfClass("Model"),d
            end
        end
    end
    return best,bestModel
end

local function resetLock(reason)
    releaseHeldFire()
    state.Target=nil
    state.TargetModel=nil
    state.LockedAt=0
    state.LostSince=nil
    state.ShotsOnTarget=0
    state.Message=reason or "Target unlocked"
end

unlock.MouseButton1Click:Connect(function()
    resetLock("Manual unlock")
end)

local function lockTarget(part, model)
    state.Target=part
    state.TargetModel=model
    state.LockedAt=os.clock()
    state.LostSince=nil
    state.ShotsOnTarget=0
    state.Message="LOCKED: "..part.Name
end

local function markedDead(inst)
    if not inst then return false end
    local hum=inst:FindFirstChildWhichIsA("Humanoid",true)
    if hum and hum.Health<=0 then return true end
    for _,attribute in ipairs({"Dead","IsDead","Defeated","Killed","Captured","Cleared"}) do
        if inst:GetAttribute(attribute)==true then return true end
    end
    for _,tag in ipairs({"Health","HP"}) do
        local hp=inst:FindFirstChild(tag,true)
        if hp and (hp:IsA("NumberValue") or hp:IsA("IntValue")) and hp.Value<=0 then
            return true
        end
    end
    return false
end

local function targetDefeated(now)
    local p=state.Target
    if not p then return false end
    local m=state.TargetModel
    if markedDead(m) or markedDead(p) then return true end
    -- Removal after our shots is a heuristic, NOT server-confirmed defeat.
    -- No shots => NEVER advance to another target automatically.
    local present=p:IsDescendantOf(Workspace)
    if present then
        state.LostSince=nil
        return false
    end
    if not state.LostSince then state.LostSince=now end
    return state.ShotsOnTarget>0 and now-state.LostSince>=3
end

local function targetPart()
    local p=state.Target
    if p and p:IsDescendantOf(Workspace) then return p end
    -- Do not pick a different model if a specific ghost vanishes.
    local m=state.TargetModel
    if m and m:IsDescendantOf(Workspace) then
        local replacement=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
        if replacement then
            state.Target=replacement
            return replacement
        end
    end
    return nil
end

local function moveToTarget(part,now)
    if not state.Teleport or now-state.LastTP<1.1 then return end
    local root=myRoot()
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    local offset=root.Position-part.Position
    local flat=Vector3.new(offset.X,0,offset.Z)
    local away=flat.Magnitude>0.05 and flat.Unit or Vector3.new(1,0,0)
    local destination=part.Position+away*5+Vector3.new(0,2.5,0)
    local distance=(root.Position-destination).Magnitude
    if distance>9 then
        local targetCFrame=CFrame.lookAt(destination,part.Position)
        pcall(function() root.CFrame=targetCFrame end)
    end
    state.LastTP=now
end

-- This checks for a standard Tool, but the game's blaster may instead use UI/remotes.
local function getBlaster()
    local character=LocalPlayer.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then return nil end
    local function hasBlasterName(obj)
        if not obj:IsA("Tool") then return false end
        local name=obj.Name:lower()
        return name:find("blaster",1,true) or name:find("ghost",1,true)
    end
    for _,obj in ipairs(character:GetChildren()) do
        if hasBlasterName(obj) then return obj end
    end
    local backpack=LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _,obj in ipairs(backpack:GetChildren()) do
            if hasBlasterName(obj) then
                pcall(function() humanoid:EquipTool(obj) end)
                return character:FindFirstChild(obj.Name)
            end
        end
    end
    return nil
end

local function findQueuePrompt()
    local root=myRoot()
    if not root then return nil end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local phrase=(obj.Name.." "..obj.ActionText.." "..obj.ObjectText):lower()
            if phrase:find("ghost gallery",1,true) or phrase:find("queue",1,true)
                or phrase:find("join",1,true) then
                local part=obj.Parent
                if part and part:IsA("Attachment") then part=part.Parent end
                if part and part:IsA("BasePart") then
                    if (part.Position-root.Position).Magnitude <= obj.MaxActivationDistance then
                        return obj
                    end
                end
            end
        end
    end
end

-- Scan for entrance-labelled parts/prompts; never invent fixed map coordinates.
-- Names are heuristics and may be different in Adopt Me production servers.
local function eventAnchor()
    if typeof(state.EventMark) == "CFrame" then
        return state.EventMark.Position, "Saved MARK HERE position"
    end
    local bestPosition, bestScore, bestName = nil, 0, nil
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local score, position, description = 0, nil, nil
        if obj:IsA("ProximityPrompt") then
            local label = (obj.Name.." "..obj.ActionText.." "..obj.ObjectText):lower()
            if label:find("ghost gallery",1,true) then score=110
            elseif label:find("join",1,true) and label:find("ghost",1,true) then score=100 end
            local owner = obj.Parent
            if owner and owner:IsA("Attachment") then owner=owner.Parent end
            if owner and owner:IsA("BasePart") then
                position = owner.Position
                description = "Prompt: "..obj.Name
            end
        elseif obj:IsA("BasePart") then
            local name = obj.Name:lower():gsub("[_%-]", "")
            if name:find("ghostgallery",1,true) and
                (name:find("door",1,true) or name:find("entrance",1,true)
                 or name:find("queue",1,true) or name:find("join",1,true)) then
                score=100
            elseif name:find("manor",1,true) and
                (name:find("door",1,true) or name:find("entrance",1,true)) then
                score=85
            end
            if score>0 then
                position = obj.Position
                description = obj.Name
            end
        end
        if score>bestScore and position then
            bestPosition, bestScore, bestName = position,score,description
        end
    end
    return bestPosition, bestName
end

local function attemptEventTeleport()
    local root = myRoot()
    local human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not root or not human or human.Health<=0 then return false end
    if state.Target and state.Hunt then
        state.EventStatus="Target locked: event TP paused during combat"
        return false
    end
    local position, source = eventAnchor()
    if not position then
        state.EventStatus = "No Manor entrance found: go there once and MARK HERE"
        return false
    end
    local destination = position + Vector3.new(0,3,0)
    if (root.Position-destination).Magnitude <= 8 then
        state.EventStatus = "Near entrance ("..source..") - join circle manually"
        return true
    end
    local ok = pcall(function()
        root.CFrame = CFrame.new(destination)
    end)
    if ok then
        state.EventStatus = "TP attempted via "..source.." - check your position"
    else
        state.EventStatus = "TP failed - movement may be server-controlled"
    end
    return ok
end

markEvent.MouseButton1Click:Connect(function()
    local root=myRoot()
    if root then
        state.EventMark=root.CFrame
        state.EventStatus="Saved current spot for this session. Press TP TO EVENT."
    else
        state.EventStatus="Character not loaded"
    end
    eventInfo.Text=state.EventStatus
end)

tpEventNow.MouseButton1Click:Connect(function()
    attemptEventTeleport()
    eventInfo.Text=state.EventStatus
end)

local function petNeedHints()
    local pg=LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return "No visible task UI" end
    local needles={"sleepy","hungry","thirsty","dirty","sick","bored","school","camping","сон","голод","жажда"}
    local found={}
    local seen={}
    for _,obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and #obj.Text<120 then
            local s=obj.Text:lower()
            for _,word in ipairs(needles) do
                if s:find(word,1,true) and not seen[word] then
                    table.insert(found,word)
                    seen[word]=true
                end
            end
        end
    end
    return #found>0 and table.concat(found,", ") or "No recognized labels"
end

-- Keep the optional hold tied to exactly the currently locked candidate.
local function attackTarget(part, now)
    local tool = getBlaster()
    if not tool then
        releaseHeldFire()
        state.Message = "No standard Ghost Blaster Tool found"
        return
    end
    if state.HoldFire and type(mouse1press)=="function" and type(mouse1release)=="function" then
        if state.FireHeld and state.FireTarget ~= part then
            releaseHeldFire()
        end
        if not state.FireHeld then
            local ok = pcall(mouse1press)
            if ok then
                state.FireHeld = true
                state.FireTarget = part
                state.ShotsOnTarget=state.ShotsOnTarget+1
                state.Message="HOLD INPUT (unverified): "..part.Name
            else
                state.Message="Hold input failed - Tool activation fallback"
            end
        end
        if state.FireHeld then return end
    end
    releaseHeldFire()
    if now-state.LastShot>.55 then
        local ok = pcall(function() tool:Activate() end)
        if ok then
            state.ShotsOnTarget=state.ShotsOnTarget+1
            state.Message="TOOL ACTIVATE (unverified): "..part.Name
        end
        state.LastShot=now
    end
end

table.insert(state.Connections, LocalPlayer.Idled:Connect(function()
    if not state.Alive or not state.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end))

-- One locked ghost at a time. Scan ONLY when no target is locked.
-- We never switch merely because another ghost is closer.
task.spawn(function()
    while state.Alive do
        local now=os.clock()
        if state.EventTP and now-state.LastEventTP > 7 then
            state.LastEventTP=now
            local done=attemptEventTeleport()
            eventInfo.Text=state.EventStatus
            if done then
                state.EventTP=false
                if state.Refresh_EventTP then state.Refresh_EventTP() end
            end
        end
        if state.Hunt then
            if not state.Target and now-state.LastScan>1 then
                state.LastScan=now
                local p,m=scanTarget()
                if p then lockTarget(p,m) else state.Message="Searching..." end
            end
            if state.Target then
                if targetDefeated(now) then
                    state.Cleared=state.Cleared+1
                    resetLock("Defeated/vanished after attack")
                else
                    local part=targetPart()
                    if part then
                        moveToTarget(part,now)
                        if state.Shoot then
                            local cam=Workspace.CurrentCamera
                            if cam then
                                cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,part.Position),.36)
                            end
                            attackTarget(part,now)
                        else
                            releaseHeldFire()
                            state.Message="LOCKED: "..part.Name
                        end
                    else
                        releaseHeldFire()
                        state.Message="TARGET LOST - locked (UNLOCK to reset)"
                    end
                end
            end
        elseif state.Target then
            releaseHeldFire()
            -- Pausing hunt keeps the lock for resuming later.
            state.Message="PAUSED - target still locked"
        else
            releaseHeldFire()
            state.Message="Ready"
        end
        if state.Queue and now-state.LastQueue>5 then
            state.LastQueue=now
            local prompt=findQueuePrompt()
            if prompt and type(fireproximityprompt)=="function" then
                pcall(fireproximityprompt,prompt)
            end
        end
        if state.PetHints and now-state.LastNeeds>4 then
            state.LastNeeds=now
            state.NeedInfo=petNeedHints()
            hints.Text="Detected needs: "..state.NeedInfo
        end
        notice.Text="Combat: "..state.Message.."\nUnverified hits; no confirmed game API."
        if state.Target then
            local targetName=state.Target.Name
            status.Text="LOCK: "..targetName.." | inputs "..state.ShotsOnTarget
            dot.BackgroundColor3=C.Orange
        elseif state.Hunt then
            status.Text="SEARCHING | attempts "..state.Cleared
            dot.BackgroundColor3=C.Purple
        else
            status.Text="READY | attempts "..state.Cleared
            dot.BackgroundColor3=C.Green
        end
        task.wait(.16)
    end
end)
print("CandyFarm Ghost Gallery v0.4 loaded: Event TP + hold input beta; unverified in Adopt Me")
