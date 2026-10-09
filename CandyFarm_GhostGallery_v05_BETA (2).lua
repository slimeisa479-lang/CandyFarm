-- CandyFarm | Ghost Gallery | v0.5 BETA
-- For local inspection/testing in Roblox. No HttpGet, loadstring, remotes or telemetry.
-- Adopt Me target/object/input internals are not known: successful hits/rewards not guaranteed.

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local VirtualUser = game:GetService('VirtualUser')
local CollectionService = game:GetService('CollectionService')
local player = Players.LocalPlayer
if not player then return end

local env = (type(getgenv)=='function' and getgenv()) or _G
local old = env.CandyFarm2026
local savedEvent = old and old.EventMark
local savedLearn = old and old.LearnedName
if old and type(old.Stop)=='function' then pcall(old.Stop) end

local state = {
    Alive=true, Farm=false, TP=true, Aim=true, Hold=true,
    EventAuto=false, JoinAuto=false, AFK=false,
    Target=nil, TargetModel=nil, Type='', Shots=0, Clears=0,
    TargetStarted=0, LostAt=nil, LastScan=0, LastTP=0,
    LastFire=0, LastTool=0, LastEvent=0, LastJoin=0,
    EventMark=savedEvent, LearnedName=savedLearn,
    Message='Ready', FireMethod='none', TPStatus='not tried',
    LastToolName='none', InputDown=false, InputMode='',
    Connections={}, UIRefresh={}, TargetScore=0,
    ManualTarget=nil, Warning='', NoTargetsSince=nil,
}
env.CandyFarm2026=state

local function rootPart()
    local c=player.Character
    return c and c:FindFirstChild('HumanoidRootPart')
end
local function isAlive()
    local c=player.Character
    local h=c and c:FindFirstChildOfClass('Humanoid')
    return h and h.Health>0 and rootPart()
end
local function lower(v) return tostring(v or ''):lower() end
local function has(str, token) return string.find(lower(str),token,1,true)~=nil end
local function matched(str, words)
    local s=lower(str)
    for _,w in ipairs(words) do
        if string.find(s,w,1,true) then return true end
    end
    return false
end
local function bestPart(obj)
    if not obj then return nil end
    if obj:IsA('BasePart') then return obj end
    if obj:IsA('Model') then
        return obj.PrimaryPart or obj:FindFirstChild('HumanoidRootPart',true)
            or obj:FindFirstChildWhichIsA('BasePart',true)
    end
    return obj:FindFirstChildWhichIsA('BasePart',true)
end
local function characterObject(obj)
    local c=player.Character
    if c and obj:IsDescendantOf(c) then return true end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return true end
    end
    return false
end
local function modelOf(p)
    if not p then return nil end
    if p:IsA('Model') then return p end
    return p:FindFirstAncestorOfClass('Model')
end
local function scoreObject(obj, fromHighlight)
    local p=bestPart(obj)
    if not p or not p:IsDescendantOf(Workspace) or characterObject(p) then return nil end
    local r=rootPart()
    if not r then return nil end
    local dist=(p.Position-r.Position).Magnitude
    if dist>320 then return nil end
    local m=modelOf(p)
    local n=lower(p.Name)
    local mn=lower(m and m.Name)
    local on=lower(obj.Name)
    local joined=n..' '..mn..' '..on
    local score=0
    local kind='unknown'
    if matched(joined,{'ghostboss','ghost_boss','bossghost','boss_ghost','boss ghost'}) then
        score=score+130; kind='BOSS'
    elseif matched(joined,{'ghost','specter','spectre','phantom','spirit','jumpscare'}) then
        score=score+80; kind='GHOST'
    elseif matched(joined,{'possess','haunted','haunt'}) then
        score=score+68; kind='FURNITURE'
    end
    -- Pets' found furniture can be highlighted even if its name says only "Chair".
    if fromHighlight then
        score=score+73
        if kind=='unknown' then kind='HIGHLIGHTED FURNITURE' end
    end
    if state.LearnedName and (n==state.LearnedName or mn==state.LearnedName) then
        score=score+115
        if kind=='unknown' then kind='LEARNED' end
    end
    for _,target in ipairs({m,p}) do
        if target then
            for _,an in ipairs({'IsGhost','Ghost','Possessed','Haunted','IsBoss','Targetable'}) do
                if target:GetAttribute(an)==true then
                    score=score+70
                    if kind=='unknown' then kind='ATTRIBUTE' end
                    break
                end
            end
            local hu=target:FindFirstChildWhichIsA('Humanoid')
            if hu and hu.Health>0 and kind~='unknown' then score=score+8 end
            local val=target:FindFirstChild('Health') or target:FindFirstChild('HP')
            if val and (val:IsA('IntValue') or val:IsA('NumberValue')) and val.Value>0 then
                score=score+20
            end
        end
    end
    -- Never pick map decoration merely because it is named like the event.
    if matched(joined,{'ghost gallery','ghostgallery','ghost_gallery','ghostblaster','ghost_blaster',
                        'manorentrance','manor_entrance','ghost sign','ghost portal','ghost_shop'}) then
        score=score-150
    end
    if score<55 then return nil end
    -- Prefer conspicuous exposed ghosts, boss, and nearby highlighted objects.
    score=score-math.min(dist/15,20)
    if score<48 then return nil end
    return {Part=p,Model=m,Score=score,Kind=kind,Distance=dist}
end

local function scanTarget()
    local options={}
    local seen={}
    local function consider(obj, highlighted)
        local p=bestPart(obj)
        if not p or seen[p] then return end
        seen[p]=true
        local c=scoreObject(obj,highlighted)
        if c then table.insert(options,c) end
    end
    -- Scan replicated target parts, not network remotes or game-internal scripts.
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA('Highlight') then
            if obj.Enabled then
                local target=obj.Adornee or obj.Parent
                if target and (target:IsA('BasePart') or target:IsA('Model')) then
                    consider(target,true)
                end
            end
        elseif obj:IsA('Model') then
            local nm=lower(obj.Name)
            if matched(nm,{'ghost','specter','spectre','phantom','possess','haunt','spirit','boss'}) then
                consider(obj,false)
            end
        elseif obj:IsA('BasePart') then
            local nm=lower(obj.Name)
            if matched(nm,{'ghost','specter','spectre','phantom','possess','haunt','spirit','boss'}) then
                consider(obj,false)
            end
        end
    end
    -- Optional public CollectionService tags, if Adopt Me uses any of these names.
    for _,tag in ipairs({'Ghost','ghost','Possessed','Haunted','GhostTarget','HauntedFurniture'}) do
        local ok,tagged=pcall(function() return CollectionService:GetTagged(tag) end)
        if ok and tagged then
            for _,obj in ipairs(tagged) do
                if obj:IsDescendantOf(Workspace) then consider(obj,true) end
            end
        end
    end
    table.sort(options,function(a,b) return a.Score>b.Score end)
    return options[1],#options
end

local VIM
pcall(function() VIM=game:GetService('VirtualInputManager') end)
local function sendButton(down,x,y)
    if not VIM then return false end
    local ok=pcall(function() VIM:SendMouseButtonEvent(x,y,0,down,game,0) end)
    return ok
end
local function centerXY()
    local cam=Workspace.CurrentCamera
    if not cam then return 0,0 end
    return math.floor(cam.ViewportSize.X/2),math.floor(cam.ViewportSize.Y/2)
end
local function releaseFire()
    if state.InputDown then
        if state.InputMode=='mouse' and type(mouse1release)=='function' then
            pcall(mouse1release)
        elseif state.InputMode=='vim' then
            local x,y=centerXY()
            sendButton(false,x,y)
        end
    end
    state.InputDown=false
    state.InputMode=''
end
local function clearTarget(reason)
    releaseFire()
    state.Target=nil
    state.TargetModel=nil
    state.ManualTarget=nil
    state.TargetStarted=0
    state.LostAt=nil
    state.Type=''
    state.TargetScore=0
    state.Shots=0
    state.Message=reason or 'Target unlocked'
end
local function acquire(c)
    clearTarget()
    state.Target=c.Part
    state.TargetModel=c.Model
    state.Type=c.Kind
    state.TargetScore=c.Score
    state.TargetStarted=os.clock()
    state.NoTargetsSince=nil
    state.Message='LOCK '..state.Type..': '..state.Target.Name
end
local function refreshPart()
    local p=state.Target
    if p and p:IsDescendantOf(Workspace) then return p end
    local m=state.TargetModel
    if m and m:IsDescendantOf(Workspace) then
        local repl=bestPart(m)
        if repl and repl:IsDescendantOf(Workspace) then
            state.Target=repl
            return repl
        end
    end
    return nil
end
local function defeated(obj)
    if not obj then return false end
    local h=obj:FindFirstChildWhichIsA('Humanoid',true)
    if h and h.Health<=0 then return true end
    for _,attribute in ipairs({'Dead','IsDead','Defeated','Killed','Cleared','Captured'}) do
        if obj:GetAttribute(attribute)==true then return true end
    end
    for _,name in ipairs({'Health','HP','health','hp'}) do
        local v=obj:FindFirstChild(name,true)
        if v and (v:IsA('IntValue') or v:IsA('NumberValue')) and v.Value<=0 then return true end
    end
    return false
end
local function shouldAdvance(now)
    if not state.Target then return false end
    if defeated(state.TargetModel) or defeated(state.Target) then return true end
    if refreshPart() then state.LostAt=nil; return false end
    if not state.LostAt then state.LostAt=now end
    -- Object disappearance after a shot is the only fallback success heuristic.
    return state.Shots>0 and (now-state.LostAt)>1.7
end

local function currentBlaster()
    local c=player.Character
    if not c then return nil end
    local active=c:FindFirstChildWhichIsA('Tool')
    local function related(t)
        return t and t:IsA('Tool') and matched(t.Name,{'ghost','blast','laser','specter','spirit'})
    end
    if related(active) then return active end
    for _,child in ipairs(c:GetChildren()) do if related(child) then return child end end
    local bag=player:FindFirstChildOfClass('Backpack')
    if bag then
        for _,t in ipairs(bag:GetChildren()) do
            if related(t) then
                local hum=c:FindFirstChildOfClass('Humanoid')
                if hum then pcall(function() hum:EquipTool(t) end) end
                return c:FindFirstChild(t.Name)
            end
        end
    end
    return active -- fallback: a nonstandard Tool might be the blaster
end

local function tpNear(p,now)
    if not state.TP or now-state.LastTP<0.65 then return end
    local r=rootPart()
    local c=player.Character
    if not r or not c or not isAlive() then return end
    local delta=r.Position-p.Position
    local horizontal=Vector3.new(delta.X,0,delta.Z)
    local dir=horizontal.Magnitude>0.05 and horizontal.Unit or Vector3.new(0,0,1)
    local offset=(state.Type=='BOSS') and 16 or 10
    local destination=p.Position+dir*offset+Vector3.new(0,2,0)
    state.LastTP=now
    if (r.Position-destination).Magnitude<5 then return end
    local look=CFrame.lookAt(destination,Vector3.new(p.Position.X,destination.Y,p.Position.Z))
    local ok=pcall(function()
        c:PivotTo(look)
        r.AssemblyLinearVelocity=Vector3.zero
        r.AssemblyAngularVelocity=Vector3.zero
    end)
    state.TPStatus=ok and 'TP attempted (server may revert)' or 'TP error'
end

-- Aim after the game's normal camera script; rotate camera + move aim cursor to center.
-- Some blasters use their OWN GUI/controller and cannot be controlled this way.
local function aimAt(p)
    local cam=Workspace.CurrentCamera
    if not cam or not p then return end
    local at=p.Position
    if state.Type=='BOSS' then at=at+Vector3.new(0,1.5,0) end
    local from=cam.CFrame.Position
    if (from-at).Magnitude<0.1 then return end
    cam.CFrame=CFrame.lookAt(from,at)
    local x,y=centerXY()
    if type(mousemoveabs)=='function' then
        pcall(mousemoveabs,x,y)
    elseif type(mousemoverel)=='function' and UIS.MouseEnabled then
        local loc=UIS:GetMouseLocation()
        pcall(mousemoverel,math.floor(x-loc.X),math.floor(y-loc.Y))
    elseif VIM then
        pcall(function() VIM:SendMouseMoveEvent(x,y,game) end)
    end
end

local function fireAt(p,now)
    if now-state.LastFire<0.12 then return end
    state.LastFire=now
    local tool=currentBlaster()
    state.LastToolName=tool and tool.Name or 'no Tool (UI blaster?)'
    -- Hold the actual simulated mouse down when possible, rather than just rotating camera.
    local x,y=centerXY()
    if state.Hold then
        if not state.InputDown then
            if type(mouse1press)=='function' and type(mouse1release)=='function' then
                if pcall(mouse1press) then
                    state.InputDown=true; state.InputMode='mouse'; state.FireMethod='mouse hold'
                    state.Shots=state.Shots+1
                end
            elseif sendButton(true,x,y) then
                state.InputDown=true; state.InputMode='vim'; state.FireMethod='VIM hold'
                state.Shots=state.Shots+1
            end
        end
    else
        releaseFire()
        if type(mouse1click)=='function' then
            if pcall(mouse1click) then state.FireMethod='mouse click';state.Shots=state.Shots+1 end
        elseif sendButton(true,x,y) then
            sendButton(false,x,y)
            state.FireMethod='VIM click'
            state.Shots=state.Shots+1
        end
    end
    -- Roblox Tool API fallback; many game-specific Ghost Blasters are not Tools.
    if tool and now-state.LastTool>0.8 then
        state.LastTool=now
        local ok=pcall(function() tool:Activate() end)
        if ok then
            state.Shots=state.Shots+1
            if state.FireMethod=='none' then state.FireMethod='Tool:Activate' end
        end
    end
end

local function entranceAnchor()
    if typeof(state.EventMark)=='CFrame' then return state.EventMark.Position,'saved circle' end
    local nearest,score,label=nil,0,''
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local nm=lower(obj.Name)
        local s=0
        local p=nil
        if obj:IsA('ProximityPrompt') then
            nm=nm..' '..lower(obj.ActionText)..' '..lower(obj.ObjectText)
            if has(nm,'ghost gallery') then s=140
            elseif has(nm,'manor') and has(nm,'join') then s=110 end
            p=bestPart(obj.Parent)
        elseif obj:IsA('BasePart') then
            if matched(nm,{'ghostgalleryqueue','ghost_gallery_queue','manorentrance','manor_entrance'}) then s=115
            elseif has(nm,'manor') and matched(nm,{'door','enter','queue','portal'}) then s=70 end
            p=obj
        end
        if p and s>score then nearest=p.Position;score=s;label=obj.Name end
    end
    return nearest,label
end
local function tpEvent()
    local r=rootPart()
    local c=player.Character
    if not r or not c or not isAlive() then state.Message='Character not ready'; return false end
    local pos,how=entranceAnchor()
    if not pos then
        state.Message='EVENT: no entrance detected. Go to circle, press MARK'
        return false
    end
    if (r.Position-pos).Magnitude<10 then
        state.Message='EVENT: already near '..how
        return true
    end
    local ok=pcall(function() c:PivotTo(CFrame.new(pos+Vector3.new(0,3,0))) end)
    state.Message=ok and ('EVENT TP attempted: '..how) or 'EVENT TP failed'
    state.TPStatus=state.Message
    return ok
end

local function visible(guiObj)
    local node=guiObj
    while node do
        if node:IsA('GuiObject') and not node.Visible then return false end
        node=node.Parent
    end
    return true
end
local function joinPopup()
    local pg=player:FindFirstChildOfClass('PlayerGui')
    if not pg then return false end
    local buttons={}
    for _,o in ipairs(pg:GetDescendants()) do
        if (o:IsA('TextButton') or o:IsA('ImageButton')) and visible(o) then
            local txt=lower(o:IsA('TextButton') and o.Text or o.Name)
            local par=o.Parent
            local nearby=txt
            for _=1,3 do
                if not par or par==pg then break end
                nearby=nearby..' '..lower(par.Name)
                for _,child in ipairs(par:GetChildren()) do
                    if child:IsA('TextLabel') and child.Visible and #child.Text<140 then
                        nearby=nearby..' '..lower(child.Text)
                    end
                end
                par=par.Parent
            end
            if has(nearby,'ghost gallery') and matched(txt,{'join','teleport','play','go','enter','yes'}) then
                table.insert(buttons,o)
            end
        end
    end
    local target=buttons[1]
    if not target then return false end
    local p=target.AbsolutePosition+target.AbsoluteSize/2
    local x,y=math.floor(p.X),math.floor(p.Y)
    if not sendButton(true,x,y) then return false end
    sendButton(false,x,y)
    state.Message='JOIN POPUP clicked (unverified)'
    return true
end

local function activePrompt()
    local r=rootPart()
    if not r then return nil end
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:IsA('ProximityPrompt') and o.Enabled then
            local words=lower(o.Name..' '..o.ActionText..' '..o.ObjectText)
            if has(words,'ghost gallery') or (has(words,'manor') and has(words,'join')) then
                local p=bestPart(o.Parent)
                if p and (r.Position-p.Position).Magnitude<o.MaxActivationDistance then return o end
            end
        end
    end
end

-- Halloween UI: minimal dark-purple window, draggable on mouse and touch.
local gui=Instance.new('ScreenGui')
gui.Name='CandyFarm_v05_GhostGallery'
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=160
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild('PlayerGui')
local function round(ui,r)
    local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r or 11);c.Parent=ui
end
local function makeLabel(parent,t,size,color,bold)
    local l=Instance.new('TextLabel')
    l.BackgroundTransparency=1;l.Text=t;l.TextColor3=color or Color3.fromRGB(250,244,255)
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=size or 12;l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextWrapped=true;l.Parent=parent
    return l
end
local function makeButton(parent,t)
    local b=Instance.new('TextButton')
    b.BackgroundColor3=Color3.fromRGB(69,43,109);b.TextColor3=Color3.new(1,1,1)
    b.Text=t;b.TextSize=12;b.Font=Enum.Font.GothamBold
    b.Parent=parent;round(b,9)
    return b
end
local main=Instance.new('Frame')
main.Size=UDim2.fromOffset(350,460)
main.Position=UDim2.new(0.5,-175,0.5,-230)
main.BackgroundColor3=Color3.fromRGB(21,14,36)
main.Active=true;main.Parent=gui;round(main,17)
local stroke=Instance.new('UIStroke')
stroke.Color=Color3.fromRGB(174,101,255);stroke.Thickness=1.8;stroke.Parent=main
local sc=Instance.new('UIScale')
sc.Scale=math.clamp((Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.X or 600)/375,0.72,1)
sc.Parent=main
local hd=Instance.new('Frame')
hd.Size=UDim2.new(1,0,0,76);hd.BackgroundColor3=Color3.fromRGB(57,32,91)
hd.Parent=main;round(hd,16)
local grad=Instance.new('UIGradient')
grad.Color=ColorSequence.new(Color3.fromRGB(96,47,154),Color3.fromRGB(39,22,65));grad.Rotation=12;grad.Parent=hd
local title=makeLabel(hd,'👻 CANDYFARM',20,nil,true)
title.Position=UDim2.fromOffset(15,9);title.Size=UDim2.fromOffset(260,30)
local subt=makeLabel(hd,'GHOST GALLERY • v0.5 BETA',11,Color3.fromRGB(225,196,255),true)
subt.Position=UDim2.fromOffset(16,41);subt.Size=UDim2.fromOffset(245,18)
local exit=makeButton(hd,'X')
exit.Position=UDim2.fromOffset(309,12);exit.Size=UDim2.fromOffset(28,28)
local min=makeButton(hd,'−')
min.Position=UDim2.fromOffset(275,12);min.Size=UDim2.fromOffset(28,28)

local tabHolder=Instance.new('Frame')
tabHolder.BackgroundTransparency=1;tabHolder.Position=UDim2.fromOffset(10,84)
tabHolder.Size=UDim2.new(1,-20,0,35);tabHolder.Parent=main
local tabNames={'FARM','EVENT','DEBUG'}
local pages={}
local tabs={}
for i,name in ipairs(tabNames) do
    local b=makeButton(tabHolder,name)
    b.Position=UDim2.new((i-1)/3,4,0,0)
    b.Size=UDim2.new(1/3,-8,1,0)
    tabs[i]=b
    local p=Instance.new('Frame')
    p.BackgroundTransparency=1;p.Size=UDim2.new(1,-20,0,270)
    p.Position=UDim2.fromOffset(10,126);p.Visible=i==1;p.Parent=main
    pages[i]=p
end
local function showTab(n)
    for i,b in ipairs(tabs) do
        b.BackgroundColor3=i==n and Color3.fromRGB(166,91,244) or Color3.fromRGB(58,37,91)
        pages[i].Visible=i==n
    end
end
for i,b in ipairs(tabs) do b.MouseButton1Click:Connect(function() showTab(i) end) end
showTab(1)
local function toggle(page,rowIndex,name,desc,key)
    local bg=Instance.new('Frame')
    bg.Position=UDim2.fromOffset(0,(rowIndex-1)*54)
    bg.Size=UDim2.new(1,0,0,49)
    bg.BackgroundColor3=Color3.fromRGB(36,26,57);bg.Parent=page;round(bg,9)
    local l=makeLabel(bg,name,13,nil,true)
    l.Position=UDim2.fromOffset(9,5);l.Size=UDim2.new(1,-90,0,20)
    local s=makeLabel(bg,desc,10,Color3.fromRGB(180,158,211))
    s.Position=UDim2.fromOffset(9,26);s.Size=UDim2.new(1,-89,0,15)
    local btn=makeButton(bg,'OFF')
    btn.Position=UDim2.new(1,-68,0,10);btn.Size=UDim2.fromOffset(57,29)
    local function refresh()
        btn.Text=state[key] and 'ON' or 'OFF'
        btn.BackgroundColor3=state[key] and Color3.fromRGB(145,68,232) or Color3.fromRGB(61,46,87)
    end
    state.UIRefresh[key]=refresh
    btn.MouseButton1Click:Connect(function()
        state[key]=not state[key]
        if (key=='Farm' or key=='Hold') and (not state.Farm or not state.Hold) then releaseFire() end
        if key=='Farm' and not state.Farm then clearTarget('Paused') end
        refresh()
    end)
    refresh()
end

toggle(pages[1],1,'AUTO FARM','Find furniture, ghosts and boss','Farm')
toggle(pages[1],2,'TP TO GHOST','Teleport near locked target','TP')
toggle(pages[1],3,'AIM + BLASTER','Camera + cursor aim at target','Aim')
toggle(pages[1],4,'HOLD FIRE','Hold mouse; Tool fallback','Hold')
local pick=makeButton(pages[1],'AIM PICK')
pick.Position=UDim2.fromOffset(0,220);pick.Size=UDim2.fromOffset(158,39)
local skip=makeButton(pages[1],'SKIP TARGET')
skip.Position=UDim2.fromOffset(171,220);skip.Size=UDim2.fromOffset(158,39)

toggle(pages[2],1,'AUTO RETURN','TP to saved entrance when not hunting','EventAuto')
toggle(pages[2],2,'JOIN POPUP','Try Ghost Gallery teleport pop-up','JoinAuto')
toggle(pages[2],3,'ANTI AFK','Prevent idle timer when possible','AFK')
local mark=makeButton(pages[2],'MARK CIRCLE')
mark.Position=UDim2.fromOffset(0,170);mark.Size=UDim2.fromOffset(158,39)
local tp=makeButton(pages[2],'TP TO EVENT')
tp.Position=UDim2.fromOffset(171,170);tp.Size=UDim2.fromOffset(158,39)
local eventInfo=makeLabel(pages[2],'MARK CIRCLE while standing at the queue entrance, then TP.',11,Color3.fromRGB(246,184,111))
eventInfo.Position=UDim2.fromOffset(2,216);eventInfo.Size=UDim2.new(1,-4,0,51)

local debugtxt=makeLabel(pages[3],'Debug: no target selected',12,nil)
debugtxt.Position=UDim2.fromOffset(3,4);debugtxt.Size=UDim2.new(1,-6,0,170)
debugtxt.TextYAlignment=Enum.TextYAlignment.Top
local copy=makeButton(pages[3],'COPY DEBUG')
copy.Position=UDim2.fromOffset(0,180);copy.Size=UDim2.fromOffset(158,39)
local reset=makeButton(pages[3],'RESET LOCK')
reset.Position=UDim2.fromOffset(171,180);reset.Size=UDim2.fromOffset(158,39)
local msg=makeLabel(pages[3],'No webhooks, remote events or outside loaders.',11,Color3.fromRGB(190,169,218))
msg.Position=UDim2.fromOffset(0,226);msg.Size=UDim2.new(1,0,0,32)

local statusBar=Instance.new('Frame')
statusBar.Position=UDim2.fromOffset(10,406)
statusBar.Size=UDim2.new(1,-20,0,42)
statusBar.BackgroundColor3=Color3.fromRGB(38,28,57)
statusBar.Parent=main;round(statusBar,9)
local status=makeLabel(statusBar,'Ready',11,Color3.fromRGB(244,228,255))
status.Position=UDim2.fromOffset(10,3);status.Size=UDim2.new(1,-20,1,-6)

-- Touch / mouse dragging on the header
local isDrag=false
local dragStart,frameStart
hd.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        isDrag=true;dragStart=inp.Position;frameStart=main.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then isDrag=false end
        end)
    end
end)
table.insert(state.Connections,UIS.InputChanged:Connect(function(inp)
    if isDrag and dragStart and frameStart and (inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=inp.Position-dragStart
        main.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y)
    end
end))
local collapsed=false
min.MouseButton1Click:Connect(function()
    collapsed=not collapsed
    for _,p in ipairs(pages) do p.Visible=not collapsed and p==pages[1] end
    tabHolder.Visible=not collapsed
    statusBar.Visible=not collapsed
    main.Size=collapsed and UDim2.fromOffset(350,76) or UDim2.fromOffset(350,460)
    min.Text=collapsed and '+' or '−'
    if not collapsed then showTab(1) end
end)

local renderName='CandyFarm_Aim_v05'
local function stop()
    if not state.Alive then return end
    state.Alive=false
    releaseFire()
    pcall(function() RunService:UnbindFromRenderStep(renderName) end)
    for _,con in ipairs(state.Connections) do pcall(function() con:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    if env.CandyFarm2026==state then env.CandyFarm2026=nil end
end
state.Stop=stop
exit.MouseButton1Click:Connect(stop)

pick.MouseButton1Click:Connect(function()
    local cam=Workspace.CurrentCamera
    local p=nil
    if cam then
        local x,y=centerXY()
        local ray=cam:ViewportPointToRay(x,y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=player.Character and {player.Character} or {}
        local hit=Workspace:Raycast(ray.Origin,ray.Direction*250,params)
        p=hit and hit.Instance
    end
    if not p then p=player:GetMouse().Target end
    if not p or characterObject(p) then state.Message='AIM PICK: no valid part under crosshair';return end
    local m=modelOf(p)
    state.LearnedName=lower((m and m.Name) or p.Name)
    acquire({Part=p,Model=m,Kind='MANUAL / '..state.LearnedName,Score=999})
    state.Message='LEARNED '..state.LearnedName
end)
skip.MouseButton1Click:Connect(function() clearTarget('Skipped manually') end)
reset.MouseButton1Click:Connect(function() clearTarget('Manual reset') end)
mark.MouseButton1Click:Connect(function()
    local r=rootPart()
    if r then
        state.EventMark=r.CFrame
        state.Message='Event queue position saved for this session'
    else state.Message='Character not spawned' end
end)
tp.MouseButton1Click:Connect(tpEvent)
copy.MouseButton1Click:Connect(function()
    local report=table.concat({
        'CandyFarm v0.5 debug',
        'PlaceId='..tostring(game.PlaceId),
        'Farm='..tostring(state.Farm),
        'Target='..tostring(state.Target and state.Target:GetFullName() or 'none'),
        'Type='..state.Type,
        'Score='..tostring(state.TargetScore),
        'LearnedName='..tostring(state.LearnedName),
        'Equipped='..tostring(state.LastToolName),
        'Input='..state.FireMethod,
        'Shots attempted='..tostring(state.Shots),
        'TP='..state.TPStatus,
        'EventMark='..tostring(state.EventMark and state.EventMark.Position),
        'Message='..state.Message,
    },'\n')
    if type(setclipboard)=='function' then
        local ok=pcall(setclipboard,report)
        msg.Text=ok and 'Debug copied. Paste to ChatGPT.' or 'Clipboard denied; see F9 console.'
    else msg.Text='No clipboard. See Roblox F9 console.' end
    print(report)
end)

-- Run aim after Roblox's camera controller, but don't take over its CameraType.
RunService:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value+1,function()
    if not state.Alive or not state.Farm or not state.Aim then return end
    local p=refreshPart()
    if p then aimAt(p) end
end)

table.insert(state.Connections,player.Idled:Connect(function()
    if not state.Alive or not state.AFK then return end
    pcall(function() VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.zero) end)
end))

-- Action loop. No unknown internal RemoteEvent calls. All activity best-effort.
task.spawn(function()
    while state.Alive do
        local now=os.clock()
        if state.Farm and isAlive() then
            if not state.Target and now-state.LastScan>1.2 then
                state.LastScan=now
                local candidate,count=scanTarget()
                if candidate then acquire(candidate) else
                    state.NoTargetsSince=state.NoTargetsSince or now
                    state.Message='No ghost candidate; AIM PICK in round ('..count..')'
                end
            end
            if state.Target then
                if shouldAdvance(now) then
                    state.Clears=state.Clears+1
                    clearTarget('Target gone/dead (not confirmed reward)')
                else
                    local p=refreshPart()
                    if p then
                        tpNear(p,now)
                        if state.Aim then fireAt(p,now)
                        else releaseFire();state.Message='Locked, AIM is OFF' end
                    else
                        releaseFire();state.Message='Target missing, waiting before changing'
                    end
                    if state.Target and now-state.TargetStarted>25 then
                        state.Warning='Target still present; use SKIP if stuck'
                    else state.Warning='' end
                end
            end
        else
            releaseFire()
            if not state.Farm then state.Message='Ready: turn AUTO FARM on in round' end
        end

        if state.JoinAuto and now-state.LastJoin>3 then
            state.LastJoin=now
            local joined=joinPopup()
            local prompt=activePrompt()
            if not joined and prompt and type(fireproximityprompt)=='function' then
                pcall(fireproximityprompt,prompt)
            end
        end
        -- Event TP is a saved location; cannot create a server queue when round is closed.
        -- Do not teleport away from an active hunt just because ghosts are briefly hidden.
        local noTargetsLongEnough=state.NoTargetsSince and now-state.NoTargetsSince>60
        local equippedTool=player.Character and player.Character:FindFirstChildWhichIsA('Tool')
        local blasterEquipped=equippedTool and matched(equippedTool.Name,{'ghost','blast','laser','spirit'})
        if state.EventAuto and not state.Target and not blasterEquipped
            and (not state.Farm or noTargetsLongEnough) and now-state.LastEvent>12 then
            state.LastEvent=now
            tpEvent()
        end
        local tname=state.Target and state.Target.Name or 'none'
        status.Text=(state.Farm and '● AUTO' or '○ OFF')..' | '..state.Type..' '..tname..'\n'..state.Message
        debugtxt.Text='Target: '..tname..'\nKind: '..state.Type..'\nLearned: '..tostring(state.LearnedName)..
            '\nWeapon: '..state.LastToolName..'\nInput: '..state.FireMethod..'\nAttempts: '..state.Shots..
            ' | Removed: '..state.Clears..'\nTP: '..state.TPStatus..'\n'..state.Warning
        eventInfo.Text=(state.EventMark and 'Circle saved. ' or 'Circle NOT saved. ')..
            'Auto join uses visible pop-up or nearby prompt. Event TP uses saved point.'
        task.wait(0.14)
    end
end)
print('[CandyFarm v0.5] loaded; mechanics speculative until real Ghost Gallery data are inspected')
