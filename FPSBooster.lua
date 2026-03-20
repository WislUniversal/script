local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Utility = {}
local State = {
    renderOn = false,
    renderPct = 0.5,
    maxDist = 1500,
    particlesOff = false,
    noAnimation = false,
    fullbright = false,
    hideTexture = false,
    shadowsOff = false,
    postEffectsOff = false,
    atmosphereOff = false,
    worldLightsOff = false,
    hidePlayer = false,
}
local renderParts = {}
local renderPartsMap = {}
local renderPartsIndex = 1
local renderPartsStale = 0
local renderParticles = {}
local renderParticlesMap = {}
local renderParticlesIndex = 1
local renderParticlesStale = 0
local renderConn = nil
local fpsConn = nil
local renderDescAddConn = nil
local renderDescRemoveConn = nil
local hidePlayerConn = nil
local MAX_PARTS_PER_FRAME = 200
local MAX_PARTICLES_PER_FRAME = 100
local CLEANUP_INTERVAL = 20
local C = {
    bg = Color3.fromRGB(30, 30, 30),
    title = Color3.fromRGB(40, 40, 40),
    section = Color3.fromRGB(35, 35, 35),
    text = Color3.fromRGB(220, 220, 220),
    dim = Color3.fromRGB(150, 150, 150),
    on = Color3.fromRGB(80, 180, 80),
    off = Color3.fromRGB(180, 60, 60),
    slider = Color3.fromRGB(50, 50, 50),
    fill = Color3.fromRGB(80, 140, 255),
    white = Color3.fromRGB(255, 255, 255),
    border = Color3.fromRGB(55, 55, 55),
}
local shadowStore = {}
local function setShadows(off)
    State.shadowsOff = off
    pcall(function()
        if off then
            if not shadowStore.GlobalShadows then
                shadowStore.GlobalShadows = Lighting.GlobalShadows
                shadowStore.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
                shadowStore.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
            end
            Lighting.GlobalShadows = false
            Lighting.EnvironmentSpecularScale = 0
            Lighting.EnvironmentDiffuseScale = 0
        else
            if shadowStore.GlobalShadows ~= nil then
                Lighting.GlobalShadows = shadowStore.GlobalShadows
                Lighting.EnvironmentSpecularScale = shadowStore.EnvironmentSpecularScale
                Lighting.EnvironmentDiffuseScale = shadowStore.EnvironmentDiffuseScale
                shadowStore = {}
            end
        end
    end)
end
local atmosphereStore = setmetatable({}, {__mode = "k"})
local postEffectsStore = setmetatable({}, {__mode = "k"})
local function setAtmosphere(off)
    State.atmosphereOff = off
    if off then
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Atmosphere") then
                if not atmosphereStore[obj] then
                    atmosphereStore[obj] = {
                        Density = obj.Density,
                        Glare = obj.Glare,
                        Haze = obj.Haze,
                        Visible = obj.Visible,
                    }
                end
                obj.Density = 0
                obj.Glare = 0
                obj.Haze = 0
                obj.Visible = false
            end
        end
    else
        for obj, vals in pairs(atmosphereStore) do
            pcall(function()
                if obj and obj.Parent then
                    obj.Density = vals.Density
                    obj.Glare = vals.Glare
                    obj.Haze = vals.Haze
                    obj.Visible = vals.Visible
                end
            end)
        end
        atmosphereStore = setmetatable({}, {__mode = "k"})
    end
end
local function setPostEffects(off)
    State.postEffectsOff = off
    if off then
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("PostEffect") then
                if not postEffectsStore[obj] then
                    postEffectsStore[obj] = obj.Enabled
                end
                obj.Enabled = false
            end
        end
    else
        for obj, enabled in pairs(postEffectsStore) do
            pcall(function()
                if obj and obj.Parent then
                    obj.Enabled = enabled
                end
            end)
        end
        postEffectsStore = setmetatable({}, {__mode = "k"})
    end
end
local particlesStore = setmetatable({}, {__mode = "k"})
local function setParticles(off)
    State.particlesOff = off
    if off then
        local descendants = workspace:GetDescendants()
        for _, d in ipairs(descendants) do
            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
                if not particlesStore[d] then
                    particlesStore[d] = d.Enabled
                end
                d.Enabled = false
            end
        end
    else
        for d, enabled in pairs(particlesStore) do
            pcall(function()
                if d and d.Parent then
                    d.Enabled = enabled
                end
            end)
        end
        particlesStore = setmetatable({}, {__mode = "k"})
    end
end
local function setQuality(low)
    pcall(function()
        settings().Rendering.QualityLevel = low and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    end)
end
local worldLightsStore = setmetatable({}, {__mode = "k"})
local function setWorldLights(off)
    State.worldLightsOff = off
    if off then
        local descendants = workspace:GetDescendants()
        for _, d in ipairs(descendants) do
            if d:IsA("SpotLight") or d:IsA("PointLight") or d:IsA("SurfaceLight") then
                if not worldLightsStore[d] then
                    worldLightsStore[d] = d.Enabled
                end
                d.Enabled = false
            end
        end
    else
        for d, enabled in pairs(worldLightsStore) do
            pcall(function()
                if d and d.Parent then
                    d.Enabled = enabled
                end
            end)
        end
        worldLightsStore = setmetatable({}, {__mode = "k"})
    end
end
local function resetRender()
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = 0
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            d.Enabled = true
        end
    end
end
local texStore = {
    decals = setmetatable({}, {__mode="k"}),
    surfApp = setmetatable({}, {__mode="k"}),
    materials = setmetatable({}, {__mode="k"}),
    meshTex = setmetatable({}, {__mode="k"}),
    fileMesh = setmetatable({}, {__mode="k"}),
    beams = setmetatable({}, {__mode="k"}),
    skies = setmetatable({}, {__mode="k"}),
    shirts = setmetatable({}, {__mode="k"}),
    pants = setmetatable({}, {__mode="k"}),
    terrainDeco = nil,
}
local function hideObjTexture(d)
    local success = pcall(function()
        if d:IsA("Decal") or d:IsA("Texture") then
            if not texStore.decals[d] then
                texStore.decals[d] = d.Transparency
            end
            d.Transparency = 1
        elseif d:IsA("SurfaceAppearance") then
            if not texStore.surfApp[d] then
                texStore.surfApp[d] = d.Parent
            end
            d.Parent = nil
        elseif d:IsA("BasePart") and not d:IsA("Terrain") then
            if not texStore.materials[d] then
                texStore.materials[d] = d.Material
            end
            d.Material = Enum.Material.SmoothPlastic
            if d:IsA("MeshPart") and d.TextureID ~= "" then
                if not texStore.meshTex[d] then
                    texStore.meshTex[d] = d.TextureID
                end
                d.TextureID = ""
            end
        elseif d:IsA("FileMesh") then
            if d.TextureId ~= "" then
                if not texStore.fileMesh[d] then
                    texStore.fileMesh[d] = d.TextureId
                end
                d.TextureId = ""
            end
        elseif d:IsA("Beam") then
            if d.Texture ~= "" then
                if not texStore.beams[d] then
                    texStore.beams[d] = d.Texture
                end
                d.Texture = ""
            end
        elseif d:IsA("Sky") then
            if not texStore.skies[d] then
                texStore.skies[d] = {
                    d.SkyboxBk, d.SkyboxDn, d.SkyboxFt,
                    d.SkyboxLf, d.SkyboxRt, d.SkyboxUp,
                }
            end
            d.SkyboxBk = ""
            d.SkyboxDn = ""
            d.SkyboxFt = ""
            d.SkyboxLf = ""
            d.SkyboxRt = ""
            d.SkyboxUp = ""
        elseif d:IsA("Shirt") then
            if not texStore.shirts[d] then
                texStore.shirts[d] = d.ShirtTemplate
            end
            d.ShirtTemplate = ""
        elseif d:IsA("Pants") then
            if not texStore.pants[d] then
                texStore.pants[d] = d.PantsTemplate
            end
            d.PantsTemplate = ""
        end
    end)
    return success
end
local function cleanupTextureProcessing()
    if State.hideTexture then
        setHideTexture(false)
    end
end
local function setHideTexture(on)
    State.hideTexture = on
    if on then
        local wsDescendants = workspace:GetDescendants()
        local lightingDescendants = Lighting:GetDescendants()

        for _, d in ipairs(wsDescendants) do
            hideObjTexture(d)
        end
        for _, d in ipairs(lightingDescendants) do
            hideObjTexture(d)
        end
        for _, d in ipairs(Lighting:GetChildren()) do
            hideObjTexture(d)
        end
        pcall(function()
            if workspace.Terrain then
                texStore.terrainDeco = workspace.Terrain.Decoration
                workspace.Terrain.Decoration = false
            end
        end)
    else
        for d, v in pairs(texStore.decals) do
            pcall(function()
                if d and d.Parent then d.Transparency = v end
            end)
        end
        texStore.decals = {}

        for d, p in pairs(texStore.surfApp) do
            pcall(function()
                if d and d.Parent == nil and p and p.Parent then d.Parent = p end
            end)
        end
        texStore.surfApp = {}

        for d, m in pairs(texStore.materials) do
            pcall(function()
                if d and d.Parent then d.Material = m end
            end)
        end
        texStore.materials = {}

        for d, t in pairs(texStore.meshTex) do
            pcall(function()
                if d and d.Parent then d.TextureID = t end
            end)
        end
        texStore.meshTex = {}

        for d, t in pairs(texStore.fileMesh) do
            pcall(function()
                if d and d.Parent then d.TextureId = t end
            end)
        end
        texStore.fileMesh = {}

        for d, t in pairs(texStore.beams) do
            pcall(function()
                if d and d.Parent then d.Texture = t end
            end)
        end
        texStore.beams = {}

        for d, s in pairs(texStore.skies) do
            pcall(function()
                if d and d.Parent then
                    d.SkyboxBk = s[1]
                    d.SkyboxDn = s[2]
                    d.SkyboxFt = s[3]
                    d.SkyboxLf = s[4]
                    d.SkyboxRt = s[5]
                    d.SkyboxUp = s[6]
                end
            end)
        end
        texStore.skies = {}

        for d, t in pairs(texStore.shirts) do
            pcall(function()
                if d and d.Parent then d.ShirtTemplate = t end
            end)
        end
        texStore.shirts = {}

        for d, t in pairs(texStore.pants) do
            pcall(function()
                if d and d.Parent then d.PantsTemplate = t end
            end)
        end
        texStore.pants = {}

        if texStore.terrainDeco ~= nil then
            pcall(function()
                if workspace.Terrain then
                    workspace.Terrain.Decoration = texStore.terrainDeco
                end
            end)
            texStore.terrainDeco = nil
        end
    end
end
local animConns = {}
local disabledScripts = {}
local hookedObjs = {}
local function killTrack(track)
    pcall(function()
        track:Stop(0)
        track:AdjustSpeed(0)
        track:AdjustWeight(0, 0)
    end)
end
local function hookAnimObj(obj)
    if hookedObjs[obj] then return end
    hookedObjs[obj] = true
    pcall(function()
        for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
            killTrack(track)
        end
    end)
    local ok, conn = pcall(function()
        return obj.AnimationPlayed:Connect(function(track)
            killTrack(track)
        end)
    end)
    if ok and conn then
        table.insert(animConns, conn)
    end
end
local function scanAnimations()
    local descendants = workspace:GetDescendants()
    for _, d in ipairs(descendants) do
        if d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("Humanoid") then
            hookAnimObj(d)
            if d:IsA("Humanoid") then
                local animator = d:FindFirstChildOfClass("Animator")
                if animator then
                    hookAnimObj(animator)
                end
            end
        end
        if d:IsA("BaseScript") and string.lower(d.Name) == "animate" then
            pcall(function()
                if not d.Disabled then
                    d.Disabled = true
                    table.insert(disabledScripts, d)
                end
            end)
        end
    end
end
local function handleCharacter(char)
    if not State.noAnimation then return end
    for _, d in pairs(char:GetDescendants()) do
        if d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("Humanoid") then
            hookAnimObj(d)
        end
        if d:IsA("BaseScript") and string.lower(d.Name) == "animate" then
            pcall(function()
                d.Disabled = true
                table.insert(disabledScripts, d)
            end)
        end
    end
    local descConn
    descConn = char.DescendantAdded:Connect(function(d)
        if not State.noAnimation then
            if descConn then descConn:Disconnect() end
            return
        end
        if d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("Humanoid") then
            if State.noAnimation then hookAnimObj(d) end
        end
        if d:IsA("BaseScript") and string.lower(d.Name) == "animate" then
            pcall(function()
                d.Disabled = true
                table.insert(disabledScripts, d)
            end)
        end
    end)
    table.insert(animConns, descConn)
end
local function cleanupAnimationProcessing()
    for _, conn in ipairs(animConns) do
        pcall(function() conn:Disconnect() end)
    end
    animConns = {}
    for _, s in ipairs(disabledScripts) do
        pcall(function()
            if s and s.Parent then
                s.Disabled = false
            end
        end)
    end
    disabledScripts = {}
    hookedObjs = {}
    State.noAnimation = false
end
local function setNoAnimation(on)
    State.noAnimation = on
    if on then
        for _, conn in ipairs(animConns) do
            pcall(function() conn:Disconnect() end)
        end
        animConns = {}
        disabledScripts = {}
        hookedObjs = {}
        scanAnimations()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                handleCharacter(p.Character)
            end
            local conn = p.CharacterAdded:Connect(function(char)
                handleCharacter(char)
            end)
            table.insert(animConns, conn)
        end
        local pConn = Players.PlayerAdded:Connect(function(p)
            if not State.noAnimation then return end
            local conn = p.CharacterAdded:Connect(function(char)
                handleCharacter(char)
            end)
            table.insert(animConns, conn)
        end)
        table.insert(animConns, pConn)
    else
        cleanupAnimationProcessing()
    end
end
local playerHideStore = {}
local otherPlayerHideConn = nil
local function setHidePlayer(on)
    State.hidePlayer = on
    if on then
        if hidePlayerConn then
            hidePlayerConn:Disconnect()
        end
        if otherPlayerHideConn then
            otherPlayerHideConn:Disconnect()
        end
        local function hideCharacter(char)
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not playerHideStore[part] then
                        playerHideStore[part] = {
                            Transparency = part.Transparency,
                            CanCollide = part.CanCollide,
                        }
                    end
                    part.Transparency = 1
                    part.CanCollide = false
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    if not playerHideStore[part] then
                        playerHideStore[part] = {
                            Transparency = part.Transparency,
                        }
                    end
                    part.Transparency = 1
                end
            end
        end
        local function hideAllPlayers()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    hideCharacter(p.Character)
                end
            end
        end
        hideAllPlayers()
        if player.Character then
            hideCharacter(player.Character)
        end
        otherPlayerHideConn = Players.PlayerAdded:Connect(function(p)
            if State.hidePlayer and p ~= player and p.Character then
                hideCharacter(p.Character)
            end
        end)
        hidePlayerConn = player.CharacterAdded:Connect(function(char)
            if State.hidePlayer then
                hideCharacter(char)
            end
        end)
    else
        if hidePlayerConn then
            hidePlayerConn:Disconnect()
            hidePlayerConn = nil
        end
        if otherPlayerHideConn then
            otherPlayerHideConn:Disconnect()
            otherPlayerHideConn = nil
        end
        for part, data in pairs(playerHideStore) do
            pcall(function()
                if part and part.Parent then
                    if data.Transparency ~= nil then
                        part.Transparency = data.Transparency
                    end
                    if data.CanCollide ~= nil then
                        part.CanCollide = data.CanCollide
                    end
                end
            end)
        end
        playerHideStore = {}
    end
end
local function addRenderPart(part)
    if renderPartsMap[part] then return end
    renderPartsMap[part] = true
    table.insert(renderParts, part)
end
local function removeRenderPart(part)
    if not renderPartsMap[part] then return end
    renderPartsMap[part] = nil
    renderPartsStale += 1
end
local function addRenderParticle(p)
    if renderParticlesMap[p] then return end
    renderParticlesMap[p] = true
    table.insert(renderParticles, p)
end
local function removeRenderParticle(p)
    if not renderParticlesMap[p] then return end
    renderParticlesMap[p] = nil
    renderParticlesStale += 1
end
local function rebuildRenderParts()
    local newList = {}
    for part in pairs(renderPartsMap) do
        table.insert(newList, part)
    end
    renderParts = newList
    renderPartsIndex = 1
    renderPartsStale = 0
end
local function rebuildRenderParticles()
    local newList = {}
    for p in pairs(renderParticlesMap) do
        table.insert(newList, p)
    end
    renderParticles = newList
    renderParticlesIndex = 1
    renderParticlesStale = 0
end
local function initRenderLists()
    renderParts = {}
    renderParticles = {}
    renderPartsMap = {}
    renderParticlesMap = {}
    renderPartsIndex = 1
    renderParticlesIndex = 1
    renderPartsStale = 0
    renderParticlesStale = 0
    for _, d in pairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and not d:IsA("Terrain") then
            addRenderPart(d)
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            addRenderParticle(d)
        end
    end
end
local function stepRender()
    if not State.renderOn then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local pct = State.renderPct
    local maxDist = pct <= 0.01 and 0 or math.max(80, pct * State.maxDist)
    local fadeStart = maxDist * 0.7
    local fadeRange = maxDist - fadeStart
    local char = player.Character
    local camLook = cam.CFrame.LookVector
    local maxDistSq = maxDist * maxDist
    local fadeStartSq = fadeStart * fadeStart
    local fadeStartHalfSq = (fadeStart * 0.5) ^ 2
    local timeStart = os.clock()
    local partsBudget = 0.0018
    local particlesBudget = 0.0012
    local partCount = #renderParts
    if renderPartsStale > (partCount * 2) then
        rebuildRenderParts()
        partCount = #renderParts
    end
    local partsProcessed = 0
    for i = 1, MAX_PARTS_PER_FRAME do
        if os.clock() - timeStart > partsBudget then
            break
        end
        if renderPartsIndex > partCount then
            renderPartsIndex = 1
        end
        local part = renderParts[renderPartsIndex]
        renderPartsIndex += 1
        if not part or not part.Parent then
            renderPartsMap[part] = nil
            renderPartsStale += 1
            partsProcessed += 1
            continue
        end
        if part and renderPartsMap[part] then
            if part:IsA("BasePart") then
                if not (char and part:IsDescendantOf(char)) and part.Transparency < 0.95 then
                    if maxDist <= 0 then
                        if part.LocalTransparencyModifier < 0.99 then
                            part.LocalTransparencyModifier = 1
                        end
                    else
                        local offset = part.Position - camPos
                        local distSq = offset.X^2 + offset.Y^2 + offset.Z^2
                        if distSq > maxDistSq then
                            if part.LocalTransparencyModifier < 0.99 then
                                part.LocalTransparencyModifier = 1
                            end
                        elseif distSq > fadeStartSq then
                            local offsetUnit = offset.Magnitude > 0 and offset.Unit or Vector3.new(0, 1, 0)
                            local dot = camLook:Dot(offsetUnit)
                            if dot < -0.3 and distSq > fadeStartHalfSq then
                                if part.LocalTransparencyModifier < 0.99 then
                                    part.LocalTransparencyModifier = 1
                                end
                            else
                                local dist = math.sqrt(distSq)
                                local newTransparency = (dist - fadeStart) / fadeRange
                                if math.abs(part.LocalTransparencyModifier - newTransparency) > 0.01 then
                                    part.LocalTransparencyModifier = newTransparency
                                end
                            end
                        else
                            if part.LocalTransparencyModifier > 0.01 then
                                part.LocalTransparencyModifier = 0
                            end
                        end
                    end
                end
            end
        else
            renderPartsStale += 1
        end
        partsProcessed += 1
    end
    timeStart = os.clock()
    local particleCount = #renderParticles
    if renderParticlesStale > (particleCount * 2) then
        rebuildRenderParticles()
        particleCount = #renderParticles
    end
    local particlesProcessed = 0
    for i = 1, MAX_PARTICLES_PER_FRAME do
        if os.clock() - timeStart > particlesBudget then
            break
        end
        if renderParticlesIndex > particleCount then
            renderParticlesIndex = 1
        end
        local p = renderParticles[renderParticlesIndex]
        renderParticlesIndex += 1
        if not p or not p.Parent then
            renderParticlesMap[p] = nil
            renderParticlesStale += 1
            particlesProcessed += 1
            continue
        end
        if p and renderParticlesMap[p] then
            if not State.particlesOff then
                local parent = p.Parent
                if parent and parent:IsA("BasePart") then
                    local enabled
                    if maxDist <= 0 then
                        enabled = false
                    else
                        local offset = parent.Position - camPos
                        local distSq = offset.X^2 + offset.Y^2 + offset.Z^2
                        enabled = distSq <= maxDistSq
                    end
                    if p.Enabled ~= enabled then
                        p.Enabled = enabled
                    end
                end
            end
        else
            renderParticlesStale += 1
        end
        particlesProcessed += 1
    end
end
renderDescAddConn = workspace.DescendantAdded:Connect(function(d)
    if State.particlesOff then
        if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
            d.Enabled = false
        end
    end
    if State.renderOn and State.renderPct <= 0 then
        if d:IsA("BasePart") and not d:IsA("Terrain") then
            d.LocalTransparencyModifier = 1
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            d.Enabled = false
        end
    end
    if State.worldLightsOff then
        if d:IsA("SpotLight") or d:IsA("PointLight") or d:IsA("SurfaceLight") then
            d.Enabled = false
        end
    end
    if d:IsA("BasePart") and not d:IsA("Terrain") then
        addRenderPart(d)
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
        addRenderParticle(d)
    end
    if State.hideTexture then
        hideObjTexture(d)
    end
    if State.noAnimation then
        if d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("Humanoid") then
            if State.noAnimation then
                hookAnimObj(d)
                if d:IsA("Humanoid") then
                    local animator = d:FindFirstChildOfClass("Animator")
                    if animator then hookAnimObj(animator) end
                end
            end
        end
        if d:IsA("BaseScript") and string.lower(d.Name) == "animate" then
            pcall(function()
                d.Disabled = true
                table.insert(disabledScripts, d)
            end)
        end
    end
end)
renderDescRemoveConn = workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("BasePart") and not d:IsA("Terrain") then
        removeRenderPart(d)
    elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
        removeRenderParticle(d)
    end
end)
Lighting.DescendantAdded:Connect(function(d)
    if State.hideTexture then
        hideObjTexture(d)
    end
    if State.postEffectsOff and d:IsA("PostEffect") then
        if not postEffectsStore[d] then
            postEffectsStore[d] = d.Enabled
        end
        d.Enabled = false
    end
    if State.atmosphereOff and d:IsA("Atmosphere") then
        if not atmosphereStore[d] then
            atmosphereStore[d] = {
                Density = d.Density,
                Glare = d.Glare,
                Haze = d.Haze,
                Visible = d.Visible,
            }
        end
        d.Density = 0
        d.Glare = 0
        d.Haze = 0
        d.Visible = false
    end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "FPSBoosterBasic"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 380)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 1
main.BorderColor3 = C.border
main.ClipsDescendants = true
main.Parent = gui
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = C.title
titleBar.BorderSizePixel = 0
titleBar.Parent = main
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.Position = UDim2.new(0, 8, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "FPS Booster"
titleText.TextColor3 = C.white
titleText.TextSize = 14
titleText.Font = Enum.Font.SourceSansBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 50, 1, 0)
fpsLabel.Position = UDim2.new(1, -55, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "-- FPS"
fpsLabel.TextColor3 = C.on
fpsLabel.TextSize = 11
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = titleBar
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, 0, 1, -28)
content.Position = UDim2.new(0, 0, 0, 28)
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
local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.PaddingLeft = UDim.new(0, 8)
contentPad.PaddingRight = UDim.new(0, 8)
contentPad.PaddingBottom = UDim.new(0, 8)
contentPad.Parent = content
local orderCount = 0
local function nextOrder()
    orderCount += 1
    return orderCount
end
local function addHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundColor3 = C.section
    lbl.BorderSizePixel = 0
    lbl.Text = "  " .. text
    lbl.TextColor3 = C.fill
    lbl.TextSize = 11
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
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = content
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.Font = Enum.Font.SourceSans
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    btn.BackgroundColor3 = default and C.on or C.off
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = C.white
    btn.TextSize = 10
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
    box.Size = UDim2.new(1, 0, 0, 36)
    box.BackgroundTransparency = 1
    box.LayoutOrder = nextOrder()
    box.Parent = content
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 0, 14)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.Font = Enum.Font.SourceSans
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = box
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.35, 0, 0, 14)
    valLbl.Position = UDim2.new(0.65, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = math.floor(default * 100) .. "%"
    valLbl.TextColor3 = C.fill
    valLbl.TextSize = 12
    valLbl.Font = Enum.Font.SourceSansBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = box
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -8, 0, 6)
    track.Position = UDim2.new(0, 4, 0, 18)
    track.BackgroundColor3 = C.slider
    track.BorderSizePixel = 0
    track.Parent = box
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(default, 0, 1, 0)
    fill.BackgroundColor3 = C.fill
    fill.BorderSizePixel = 0
    fill.Parent = track
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 10, 0, 14)
    handle.Position = UDim2.new(default, -5, 0.5, -7)
    handle.BackgroundColor3 = C.white
    handle.BorderSizePixel = 1
    handle.BorderColor3 = C.border
    handle.ZIndex = 3
    handle.Parent = track
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 10, 0, 20)
    hit.Position = UDim2.new(0, -5, 0, 14)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 5
    hit.Parent = box
    local sliding = false
    local function update(x)
        if not track.Parent or not fill.Parent or not handle.Parent or not valLbl.Parent then return end
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
addToggle("Hide Texture", false, function(on)
    setHideTexture(on)
end)
addToggle("Hide Player", false, function(on)
    setHidePlayer(on)
end)
addSep()
addHeader("VISUAL")
addToggle("No Atmosphere", false, function(on)
    setAtmosphere(on)
end)
addToggle("No World Lights", false, function(on)
    setWorldLights(on)
end)
addToggle("No Animation", false, function(on)
    setNoAnimation(on)
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
addSep()
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
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0, 10, 1, -55)
toggleBtn.BackgroundColor3 = C.title
toggleBtn.BorderSizePixel = 1
toggleBtn.BorderColor3 = C.border
toggleBtn.Text = "FPS"
toggleBtn.TextColor3 = C.white
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = gui
local toggleDragOn, toggleDragStart, toggleStartPos = false, nil, nil
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragOn = true
        toggleDragStart = input.Position
        toggleStartPos = toggleBtn.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if toggleDragOn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - toggleDragStart
        toggleBtn.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + d.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragOn = false
    end
end)
toggleBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
    if main.Visible then
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end)
initRenderLists()
renderConn = RunService.RenderStepped:Connect(function()
    stepRender()
end)
task.spawn(function()
    while true do
        task.wait(CLEANUP_INTERVAL)
        if not State.renderOn then continue end
        rebuildRenderParts()
        rebuildRenderParticles()
        collectgarbage("collect")
    end
end)
do
    local frames = 0
    local lastT = os.clock()
    fpsConn = RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - lastT >= 1 then
            local fps = math.floor(frames / (now - lastT))
            fpsLabel.Text = fps .. " FPS"
            if fps >= 50 then
                fpsLabel.TextColor3 = C.on
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(230, 190, 50)
            else
                fpsLabel.TextColor3 = C.off
            end
            frames = 0
            lastT = now
        end
    end)
end
local function cleanupAll()
    State.renderOn = false
    setHideTexture(false)
    cleanupTextureProcessing()
    setNoAnimation(false)
    cleanupAnimationProcessing()
    setHidePlayer(false)
    resetRender()
    setParticles(false)
    setPostEffects(false)
    setShadows(false)
    setAtmosphere(false)
    setWorldLights(false)
    if State.fullbright then
        State.fullbright = false
        if Utility.FullbrightConn then
            Utility.FullbrightConn:Disconnect()
            Utility.FullbrightConn = nil
        end
        pcall(function()
            if Utility.OriginalLighting then
                Lighting.Brightness = Utility.OriginalLighting.Brightness
                Lighting.ClockTime = Utility.OriginalLighting.ClockTime
                Lighting.FogEnd = Utility.OriginalLighting.FogEnd
                Lighting.GlobalShadows = Utility.OriginalLighting.GlobalShadows
                Lighting.OutdoorAmbient = Utility.OriginalLighting.OutdoorAmbient
                Utility.OriginalLighting = nil
            end
        end)
    end
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    if fpsConn then
        fpsConn:Disconnect()
        fpsConn = nil
    end
    if renderDescAddConn then
        renderDescAddConn:Disconnect()
        renderDescAddConn = nil
    end
    if renderDescRemoveConn then
        renderDescRemoveConn:Disconnect()
        renderDescRemoveConn = nil
    end
end
game:BindToClose(cleanupAll)
