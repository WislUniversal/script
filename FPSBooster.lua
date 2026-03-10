local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local RunService   = game:GetService("RunService")
local Utility = {}
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local State = {
    renderOn     = false,
    renderPct    = 0.5,
    maxDist      = 1500,
    folded       = false,
    particlesOff = false,
    noAnimation  = false,
    fullbright   = false,
}
local C = {
    bg       = Color3.fromRGB(30, 30, 30),
    title    = Color3.fromRGB(40, 40, 40),
    section  = Color3.fromRGB(35, 35, 35),
    text     = Color3.fromRGB(220, 220, 220),
    dim      = Color3.fromRGB(150, 150, 150),
    on       = Color3.fromRGB(80, 180, 80),
    off      = Color3.fromRGB(180, 60, 60),
    slider   = Color3.fromRGB(50, 50, 50),
    fill     = Color3.fromRGB(80, 140, 255),
    white    = Color3.fromRGB(255, 255, 255),
    border   = Color3.fromRGB(55, 55, 55),
}
local function setShadows(off)
    pcall(function()
        Lighting.GlobalShadows = not off
        Lighting.EnvironmentSpecularScale = off and 0 or 1
        Lighting.EnvironmentDiffuseScale = off and 0 or 1
    end)
end
local function setPostEffects(off)
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") then
            obj.Enabled = not off
        end
    end
end
local function setParticles(off)
    State.particlesOff = off
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
            d.Enabled = not off
        end
    end
end
local function setQuality(low)
    pcall(function()
        settings().Rendering.QualityLevel = low and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    end)
end
local function setAtmosphere(off)
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            obj.Density = off and 0 or 0.395
            obj.Glare = off and 0 or 0
            obj.Haze = off and 0 or 0
        end
    end
end
local function setWorldLights(off)
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("SpotLight") or d:IsA("PointLight") or d:IsA("SurfaceLight") then
            d.Enabled = not off
        end
    end
end
local function resetRender()
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = 0
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            if not State.particlesOff then d.Enabled = true end
        end
    end
end
workspace.DescendantAdded:Connect(function(d)
    if State.particlesOff then
        if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
            d.Enabled = false
        end
    end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "FPSBoosterBasic"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 410)
main.AnchorPoint = Vector2.new(1, 1)
main.Position = UDim2.new(1, -20, 1, -20)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 1
main.BorderColor3 = C.border
main.ClipsDescendants = true
main.Parent = gui
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = C.title
titleBar.BorderSizePixel = 0
titleBar.Parent = main
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "FPS Booster"
titleText.TextColor3 = C.white
titleText.TextSize = 15
titleText.Font = Enum.Font.SourceSansBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 55, 1, 0)
fpsLabel.Position = UDim2.new(1, -100, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "-- FPS"
fpsLabel.TextColor3 = C.on
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = titleBar
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 32, 0, 24)
minimizeBtn.Position = UDim2.new(1, -38, 0, 4)
minimizeBtn.BackgroundColor3 = C.slider
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "_"
minimizeBtn.TextColor3 = C.white
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.Parent = titleBar
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, 0, 1, -32)
content.Position = UDim2.new(0, 0, 0, 32)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = C.fill
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = content
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = content
local orderCount = 0
local function nextOrder()
    orderCount += 1
    return orderCount
end
local function addHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundColor3 = C.section
    lbl.BorderSizePixel = 0
    lbl.Text = "  " .. text
    lbl.TextColor3 = C.fill
    lbl.TextSize = 12
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = nextOrder()
    lbl.Parent = content
end
local function addSep()
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.border
    s.BorderSizePixel = 0
    s.LayoutOrder = nextOrder()
    s.Parent = content
end
local function addToggle(text, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = content
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.SourceSans
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BackgroundColor3 = default and C.on or C.off
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = C.white
    btn.TextSize = 11
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = row
    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.BackgroundColor3 = on and C.on or C.off
        btn.Text = on and "ON" or "OFF"
        callback(on)
    end)
    return btn
end
local function addSlider(text, default, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 42)
    box.BackgroundTransparency = 1
    box.LayoutOrder = nextOrder()
    box.Parent = content
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 0, 16)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.SourceSans
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = box
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.3, 0, 0, 16)
    valLbl.Position = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = math.floor(default * 100) .. "%"
    valLbl.TextColor3 = C.fill
    valLbl.TextSize = 13
    valLbl.Font = Enum.Font.SourceSansBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = box
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -8, 0, 8)
    track.Position = UDim2.new(0, 4, 0, 24)
    track.BackgroundColor3 = C.slider
    track.BorderSizePixel = 0
    track.Parent = box
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(default, 0, 1, 0)
    fill.BackgroundColor3 = C.fill
    fill.BorderSizePixel = 0
    fill.Parent = track
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 12, 0, 16)
    handle.Position = UDim2.new(default, -6, 0.5, -8)
    handle.BackgroundColor3 = C.white
    handle.BorderSizePixel = 1
    handle.BorderColor3 = C.border
    handle.ZIndex = 3
    handle.Parent = track
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 10, 0, 24)
    hit.Position = UDim2.new(0, -5, 0, 16)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 5
    hit.Parent = box
    local sliding = false
    local function update(x)
        local rel = x - track.AbsolutePosition.X
        local pct = math.clamp(rel / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        handle.Position = UDim2.new(pct, -6, 0.5, -8)
        valLbl.Text = math.floor(pct * 100) .. "%"
        callback(pct)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    return box
end
addHeader("RENDER DISTANCE")
addToggle("Enable Culling", false, function(on)
    State.renderOn = on
    if not on then resetRender() end
end)
addSlider("Distance", 0.5, function(v)
    State.renderPct = v
end)
addSep()
addHeader("FPS BOOST")
addToggle("Remove Shadows", false, function(on)
    setShadows(on)
end)
addToggle("No Post Effects", false, function(on)
    setPostEffects(on)
end)
addToggle("No Particles", false, function(on)
    setParticles(on)
end)
addToggle("Low Quality", false, function(on)
    setQuality(on)
end)
addSep()
addHeader("VISUAL")
addToggle("No Atmosphere", false, function(on)
    setAtmosphere(on)
end)
addToggle("No World Lights", false, function(on)
    setWorldLights(on)
end)
local animationConnections = {}
local activeTweens = {}
local particleEmitters = {}
local function collectAllAnimations()
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") or descendant:IsA("AnimationController") then
            if descendant:IsA("Humanoid") then
                local animator = descendant:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:Stop(0)
                    end
                end
            elseif descendant:IsA("AnimationController") then
                for _, track in ipairs(descendant:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
        elseif descendant:IsA("ParticleEmitter") then
            table.insert(particleEmitters, descendant)
        end
    end
    local TweenService = game:GetService("TweenService")
end
local function stopCharacterAnimations()
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") then
            local animator = descendant:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
                local conn = animator.AnimationPlayed:Connect(function(track)
                    track:Stop(0)
                end)
                table.insert(animationConnections, conn)
            end
        elseif descendant:IsA("AnimationController") then
            for _, track in ipairs(descendant:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
            local conn = descendant.AnimationPlayed:Connect(function(track)
                track:Stop(0)
            end)
            table.insert(animationConnections, conn)
        end
    end
end
local function disableParticleAnimations(disable)
    for _, emitter in ipairs(particleEmitters) do
        if disable then
            emitter.Enabled = false
        else
            emitter.Enabled = true
        end
    end
    if disable then
        local conn = workspace.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("ParticleEmitter") then
                descendant.Enabled = false
                table.insert(particleEmitters, descendant)
            end
        end)
        table.insert(animationConnections, conn)
    end
end
local function disableUIAnimations(disable)
    local TweenService = game:GetService("TweenService")
    if disable then
        local oldCreate = TweenService.Create
        TweenService.Create = function(self, instance, tweenInfo, properties)
            local tween = oldCreate(self, instance, tweenInfo, properties)
            table.insert(activeTweens, tween)
            tween:Cancel()
            return tween
        end
    else
    end
end
addToggle("No Animation", false, function(on)
    State.noAnimation = on
    if on then
        for _, conn in ipairs(animationConnections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        animationConnections = {}
        particleEmitters = {}
        activeTweens = {}
        collectAllAnimations()
        stopCharacterAnimations()
        disableParticleAnimations(true)
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("Rotate") or descendant:IsA("BodyAngularVelocity") or descendant:IsA("BodyGyro") then
                descendant.Enabled = false
            end
            if descendant:IsA("BodyPosition") or descendant:IsA("BodyVelocity") or descendant:IsA("BodyForce") then
                descendant.Enabled = false
            end
            if descendant:IsA("AlignOrientation") or descendant:IsA("AlignPosition") or descendant:IsA("Twist") or descendant:IsA("Weld") then
                if descendant:IsA("AlignOrientation") then
                    descendant.Enabled = false
                elseif descendant:IsA("AlignPosition") then
                    descendant.Enabled = false
                end
            end
        end
    else
        for _, conn in ipairs(animationConnections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        animationConnections = {}
        for _, emitter in ipairs(particleEmitters) do
            emitter.Enabled = true
        end
        particleEmitters = {}
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("Rotate") or descendant:IsA("BodyAngularVelocity") or descendant:IsA("BodyGyro") or
               descendant:IsA("BodyPosition") or descendant:IsA("BodyVelocity") or descendant:IsA("BodyForce") then
                descendant.Enabled = true
            end
        end
    end
end)
addToggle("Fullbright", false, function(state)
    State.fullbright = state
    if state then
        if not Utility.OriginalLighting then
            Utility.OriginalLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        if Utility.FullbrightConn then Utility.FullbrightConn:Disconnect() end
        Utility.FullbrightConn = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end)
    else
        if Utility.FullbrightConn then
            Utility.FullbrightConn:Disconnect()
            Utility.FullbrightConn = nil
        end
        if Utility.OriginalLighting then
            Lighting.Brightness = Utility.OriginalLighting.Brightness
            Lighting.ClockTime = Utility.OriginalLighting.ClockTime
            Lighting.FogEnd = Utility.OriginalLighting.FogEnd
            Lighting.GlobalShadows = Utility.OriginalLighting.GlobalShadows
            Lighting.OutdoorAmbient = Utility.OriginalLighting.OutdoorAmbient
            Utility.OriginalLighting = nil
        end
    end
end)
local dragOn, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragOn = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragOn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragOn = false
    end
end)
minimizeBtn.MouseButton1Click:Connect(function()
    State.folded = not State.folded
    if State.folded then
        content.Visible = false
        main.Size = UDim2.new(0, 260, 0, 32)
        minimizeBtn.Text = "+"
    else
        content.Visible = true
        main.Size = UDim2.new(0, 260, 0, 410)
        minimizeBtn.Text = "_"
    end
end)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(1, -70, 1, -70)
toggleBtn.BackgroundColor3 = C.title
toggleBtn.BorderSizePixel = 1
toggleBtn.BorderColor3 = C.border
toggleBtn.Text = "FPS"
toggleBtn.TextColor3 = C.white
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = gui
toggleBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    if main.Visible then
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end)
task.spawn(function()
    while true do
        if State.renderOn then
            local camPos    = camera.CFrame.Position
            local maxDist   = math.max(80, State.renderPct * State.maxDist)
            local fadeStart = maxDist * 0.75
            local fadeRange = maxDist - fadeStart
            local char      = player.Character
            local desc      = workspace:GetDescendants()
            local BATCH     = 500
            for i = 1, #desc, BATCH do
                if not State.renderOn then break end
                local last = math.min(i + BATCH - 1, #desc)
                for j = i, last do
                    local d = desc[j]
                    if char and d:IsDescendantOf(char) then continue end
                    if d:IsA("BasePart") then
                        local dist = (d.Position - camPos).Magnitude
                        if dist > maxDist then
                            d.LocalTransparencyModifier = 1
                        elseif dist > fadeStart then
                            d.LocalTransparencyModifier = (dist - fadeStart) / fadeRange
                        else
                            d.LocalTransparencyModifier = 0
                        end
                    elseif not State.particlesOff and (d:IsA("ParticleEmitter") or d:IsA("Trail")) then
                        local p = d.Parent
                        if p and p:IsA("BasePart") then
                            d.Enabled = (p.Position - camPos).Magnitude <= maxDist
                        end
                    end
                end
                if last < #desc then
                    RunService.Heartbeat:Wait()
                end
            end
        end
        task.wait(0.15)
    end
end)
task.spawn(function()
    local frames = 0
    local lastT  = tick()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = tick()
        if now - lastT >= 1 then
            local fps = math.floor(frames / (now - lastT))
            fpsLabel.Text = fps .. "FPS"
            if fps >= 50 then
                fpsLabel.TextColor3 = C.on
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(230, 190, 50)
            else
                fpsLabel.TextColor3 = C.off
            end
            frames = 0
            lastT  = now
        end
    end)
end)
