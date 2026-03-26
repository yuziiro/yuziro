-- ╔══════════════════════════════════════════════════════╗
-- ║            yuziro  //  FPS Booster  v2               ║
-- ║        Industrial geometric redesign                  ║
-- ╚══════════════════════════════════════════════════════╝

local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local StarterGui   = game:GetService("StarterGui")
local RunService   = game:GetService("RunService")

local player        = Players.LocalPlayer
local SETTINGS_FILE = "Yuziro_FPSBooster_Settings.json"

-- ─── Defaults ────────────────────────────────────────────
local REMOVE_EFFECTS        = true
local SIMPLIFY_MESH_EFFECTS = true
local AFK_GRIND             = true
local AUTO_EXECUTE          = true
local HAS_APPLIED           = false  -- permanent one-time flag

-- ─── Palette ─────────────────────────────────────────────
local C = {
    S0  = Color3.fromRGB(10,  10,  12),
    S1  = Color3.fromRGB(16,  16,  20),
    S2  = Color3.fromRGB(22,  22,  28),
    S3  = Color3.fromRGB(30,  30,  38),
    A   = Color3.fromRGB(190, 220, 255),
    A2  = Color3.fromRGB(100, 160, 240),
    SP  = Color3.fromRGB(160, 100, 255),
    OK  = Color3.fromRGB(60,  210, 140),
    ERR = Color3.fromRGB(230, 70,  70),
    T1  = Color3.fromRGB(240, 240, 248),
    T2  = Color3.fromRGB(140, 140, 160),
    T3  = Color3.fromRGB(55,  55,  70),
    OFF = Color3.fromRGB(28,  28,  36),
    W   = Color3.fromRGB(255, 255, 255),
    CLR = Color3.fromRGB(160, 35,  35),
}

-- ─── Settings I/O ────────────────────────────────────────
local function loadSettings()
    if not (readfile and isfile and isfile(SETTINGS_FILE)) then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)
    if ok and data then
        REMOVE_EFFECTS        = data.REMOVE_EFFECTS        ~= nil and data.REMOVE_EFFECTS        or true
        SIMPLIFY_MESH_EFFECTS = data.SIMPLIFY_MESH_EFFECTS ~= nil and data.SIMPLIFY_MESH_EFFECTS or true
        AFK_GRIND             = data.AFK_GRIND             ~= nil and data.AFK_GRIND             or true
        AUTO_EXECUTE          = data.AUTO_EXECUTE          ~= nil and data.AUTO_EXECUTE          or true
        HAS_APPLIED           = data.HAS_APPLIED           == true  -- only true if explicitly saved
        return true
    end
    return false
end

local function saveSettings()
    if not writefile then return end
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode({
            REMOVE_EFFECTS        = REMOVE_EFFECTS,
            SIMPLIFY_MESH_EFFECTS = SIMPLIFY_MESH_EFFECTS,
            AFK_GRIND             = AFK_GRIND,
            AUTO_EXECUTE          = AUTO_EXECUTE,
            HAS_APPLIED           = HAS_APPLIED,
        }))
    end)
end

loadSettings()

-- ─── Core Booster ────────────────────────────────────────
local function runBooster()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    task.wait(0.5)
    local L  = game:GetService("Lighting")
    local RS = game:GetService("ReplicatedStorage")
    local SKIP = { SelectionBox=true, SelectionSphere=true,
        SelectionPartLasso=true, SelectionPointLasso=true,
        Handles=true, ArcHandles=true }
    local SKY = { "SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId" }
    L.Ambient=Color3.fromRGB(170,170,170); L.OutdoorAmbient=Color3.new()
    L.ColorShift_Bottom=Color3.new(); L.ColorShift_Top=Color3.new()
    L.Brightness=0; L.ShadowSoftness=0; L.GlobalShadows=false
    L.Technology=Enum.Technology.Compatibility
    L.EnvironmentDiffuseScale=0; L.EnvironmentSpecularScale=0
    L.LightingStyle=Enum.LightingStyle.Soft
    local terrain=workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.CastShadow=false; terrain.WaterWaveSize=0
        terrain.WaterWaveSpeed=0; terrain.WaterReflectance=0
        if sethiddenproperty then sethiddenproperty(terrain,"Decoration",false) end
    end
    local function processObject(o)
        if SKIP[o.ClassName] then o.Adornee=nil
        elseif o:IsA("BasePart") then
            o.Material=Enum.Material.SmoothPlastic; o.Reflectance=0; o.CastShadow=false
            if o:IsA("MeshPart") or o:IsA("PartOperation") then
                o.CollisionFidelity=Enum.CollisionFidelity.Box end
        elseif o:IsA("Sky") then
            for _,p in ipairs(SKY) do o[p]="" end; o.StarCount=0
        elseif o:IsA("Atmosphere") then
            o.Density=0; o.Offset=0; o.Glare=0; o.Haze=0
        elseif o:IsA("SurfaceAppearance") then
            o.ColorMap=""; o.NormalMap=""; o.RoughnessMap=""; o.MetalnessMap=""
        elseif o:IsA("Texture") or o:IsA("Decal") then o.Texture=""
        elseif o:IsA("PostEffect") or o:IsA("PointLight")
            or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Enabled=false
        end
    end
    for _,o in ipairs(game:GetDescendants()) do processObject(o) end
    local function disableEffect(o)
        if not o then return end
        if o:IsA("Beam") or o:IsA("Trail") then o.Enabled=false
        elseif o:IsA("ParticleEmitter") then o.Lifetime=NumberRange.new(0) end
    end
    if REMOVE_EFFECTS or AFK_GRIND then
        for _,o in ipairs(RS:GetDescendants()) do disableEffect(o) end
        workspace.DescendantAdded:Connect(disableEffect)
    end
    local function simplify(list)
        for _,o in ipairs(list) do
            if o:IsA("MeshPart") or o:IsA("SpecialMesh") then o.MeshId="" end
        end
    end
    if AFK_GRIND then simplify(game:GetDescendants())
    elseif SIMPLIFY_MESH_EFFECTS then simplify(RS:GetDescendants()) end
    if AFK_GRIND or SIMPLIFY_MESH_EFFECTS then
        game.DescendantAdded:Connect(function(o)
            if o:IsA("MeshPart") or o:IsA("SpecialMesh") then
                if AFK_GRIND or (SIMPLIFY_MESH_EFFECTS and o:IsDescendantOf(RS)) then
                    o.MeshId="" end end end)
    end
end

-- ─── Helpers ─────────────────────────────────────────────
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification",
            { Title="yuziro fps booster", Text=text, Duration=4 })
    end)
end

local function guiParent()
    if syn        then return CoreGui
    elseif gethui then return gethui()
    else               return player:WaitForChild("PlayerGui") end
end

local function protect(gui)
    if syn then syn.protect_gui(gui) end
end

local function tw(obj, t, props, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out), props):Play()
end

local function hRule(parent, yPos, color, alpha)
    local r = Instance.new("Frame", parent)
    r.Size                 = UDim2.new(1, 0, 0, 1)
    r.Position             = UDim2.new(0, 0, 0, yPos)
    r.BackgroundColor3     = color or C.T3
    r.BackgroundTransparency = alpha or 0.5
    r.BorderSizePixel      = 0
    return r
end

local function dot(parent, size, color, cornerR)
    local d = Instance.new("Frame", parent)
    d.Size             = UDim2.new(0, size, 0, size)
    d.BackgroundColor3 = color
    d.BorderSizePixel  = 0
    Instance.new("UICorner", d).CornerRadius = UDim.new(0, cornerR or 0)
    return d
end

-- ─── Live FPS tracker ────────────────────────────────────
local currentFPS   = 0
local fpsListeners = {}

RunService.Heartbeat:Connect(function(dt)
    currentFPS = math.round(1 / dt)
    for _, lbl in ipairs(fpsListeners) do
        if lbl and lbl.Parent then
            lbl.Text       = currentFPS .. " FPS"
            lbl.TextColor3 = currentFPS >= 55 and C.OK
                          or currentFPS >= 30 and C.A
                          or C.ERR
        end
    end
end)

-- ─── Profile picture ─────────────────────────────────────
local function makeAvatar(parent, sz, pos)
    local wrap = Instance.new("Frame", parent)
    wrap.Size             = UDim2.new(0, sz, 0, sz)
    wrap.Position         = pos
    wrap.BackgroundColor3 = C.S2
    wrap.BorderSizePixel  = 0
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 4)

    local sk = Instance.new("UIStroke", wrap)
    sk.Color = C.A2; sk.Thickness = 1; sk.Transparency = 0.55

    local img = Instance.new("ImageLabel", wrap)
    img.Size                  = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.ScaleType             = Enum.ScaleType.Crop
    img.Visible               = false
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 3)

    local mono = Instance.new("TextLabel", wrap)
    mono.Size                 = UDim2.new(1,0,1,0)
    mono.BackgroundTransparency = 1
    mono.Text                 = string.upper(string.sub(player.DisplayName,1,1))
    mono.TextColor3           = C.A
    mono.TextSize             = math.floor(sz * 0.44)
    mono.Font                 = Enum.Font.GothamBold
    mono.Visible              = true

    local url = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=48&h=48"
    img.Image = url
    task.spawn(function()
        local ok = pcall(function()
            game:GetService("ContentProvider"):PreloadAsync({url})
        end)
        if ok then img.Visible=true; mono.Visible=false end
    end)
    return wrap
end

-- ─── Mini / minimize pill ────────────────────────────────
local miniGui = nil

local function showMiniGui()
    if not miniGui then return end
    miniGui.Enabled = true
    local bar = miniGui:FindFirstChild("MiniBar", true)
    if not bar then return end
    -- Slide in from left
    bar.Position = UDim2.new(0, -260, 0, 16)
    tw(bar, 0.48, { Position = UDim2.new(0, 16, 0, 16) }, Enum.EasingStyle.Back)
end

local function createMiniGui()
    if miniGui then miniGui:Destroy() end

    miniGui = Instance.new("ScreenGui")
    miniGui.Name           = "YuziroFPSMini"
    miniGui.ResetOnSpawn   = false
    miniGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    miniGui.Enabled        = false
    protect(miniGui)
    miniGui.Parent = guiParent()

    -- Bar: 240 wide to give more room for content
    local BAR_W, BAR_H = 240, 40
    local bar = Instance.new("Frame")
    bar.Name             = "MiniBar"
    bar.Size             = UDim2.new(0, BAR_W, 0, BAR_H)
    bar.Position         = UDim2.new(0, 16, 0, 16)
    bar.BackgroundColor3 = C.S1
    bar.BorderSizePixel  = 0
    bar.Active           = true
    bar.Draggable        = true
    bar.Parent           = miniGui
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)

    local barSk = Instance.new("UIStroke", bar)
    barSk.Color = C.A2; barSk.Thickness = 1; barSk.Transparency = 0.55

    -- Left accent strip
    local strip = Instance.new("Frame", bar)
    strip.Size             = UDim2.new(0, 2, 1, -8)
    strip.Position         = UDim2.new(0, 0, 0, 4)
    strip.BackgroundColor3 = C.A
    strip.BorderSizePixel  = 0
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 2)

    -- Avatar (28px)
    makeAvatar(bar, 28, UDim2.new(0, 8, 0.5, -14))

    -- Divider after avatar
    local div1 = Instance.new("Frame", bar)
    div1.Size             = UDim2.new(0, 1, 0, 20)
    div1.Position         = UDim2.new(0, 44, 0.5, -10)
    div1.BackgroundColor3 = C.T3
    div1.BackgroundTransparency = 0.3
    div1.BorderSizePixel  = 0

    -- ── FIX: "BOOST" label stacked ABOVE the FPS number ──
    -- "BOOST" is a tiny 9px label at top of the content area
    local tagLbl = Instance.new("TextLabel", bar)
    tagLbl.Size               = UDim2.new(0, 80, 0, 13)
    tagLbl.Position           = UDim2.new(0, 52, 0, 5)   -- top portion of bar
    tagLbl.BackgroundTransparency = 1
    tagLbl.Text               = "BOOST"
    tagLbl.TextColor3         = C.T3
    tagLbl.TextSize           = 9
    tagLbl.Font               = Enum.Font.GothamBold
    tagLbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- FPS number sits BELOW the "BOOST" label
    local fpsLbl = Instance.new("TextLabel", bar)
    fpsLbl.Size               = UDim2.new(0, 90, 0, 18)
    fpsLbl.Position           = UDim2.new(0, 52, 0, 18)  -- below tagLbl
    fpsLbl.BackgroundTransparency = 1
    fpsLbl.Text               = currentFPS .. " FPS"
    fpsLbl.TextColor3         = C.A
    fpsLbl.TextSize           = 13
    fpsLbl.Font               = Enum.Font.GothamBold
    fpsLbl.TextYAlignment     = Enum.TextYAlignment.Center
    table.insert(fpsListeners, fpsLbl)

    -- Divider before expand btn
    local div2 = Instance.new("Frame", bar)
    div2.Size             = UDim2.new(0, 1, 0, 20)
    div2.Position         = UDim2.new(1, -36, 0.5, -10)
    div2.BackgroundColor3 = C.T3
    div2.BackgroundTransparency = 0.3
    div2.BorderSizePixel  = 0

    -- Expand "+" button
    local expandBtn = Instance.new("TextButton", bar)
    expandBtn.Size               = UDim2.new(0, 34, 1, 0)
    expandBtn.Position           = UDim2.new(1, -35, 0, 0)
    expandBtn.BackgroundTransparency = 1
    expandBtn.Text               = "+"
    expandBtn.TextColor3         = C.T2
    expandBtn.TextSize           = 17
    expandBtn.Font               = Enum.Font.GothamBold
    expandBtn.ZIndex             = 3

    expandBtn.MouseEnter:Connect(function()
        tw(expandBtn, 0.1, { TextColor3 = C.A })
    end)
    expandBtn.MouseLeave:Connect(function()
        tw(expandBtn, 0.1, { TextColor3 = C.T2 })
    end)

    local openHit = Instance.new("TextButton", bar)
    openHit.Size               = UDim2.new(1, -36, 1, 0)
    openHit.BackgroundTransparency = 1
    openHit.Text               = ""
    openHit.ZIndex             = 2
    openHit.MouseEnter:Connect(function()
        tw(bar, 0.1, { BackgroundColor3 = C.S3 })
    end)
    openHit.MouseLeave:Connect(function()
        tw(bar, 0.1, { BackgroundColor3 = C.S1 })
    end)

    local function openMain()
        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsLbl then table.remove(fpsListeners, i); break end
        end
        miniGui:Destroy(); miniGui = nil
        createMainGui()
    end

    openHit.MouseButton1Click:Connect(openMain)
    expandBtn.MouseButton1Click:Connect(openMain)

    expandBtn.MouseButton2Click:Connect(function()
        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsLbl then table.remove(fpsListeners, i); break end
        end
        miniGui:Destroy(); miniGui = nil
    end)
end

-- ─── Main GUI ────────────────────────────────────────────
local mainGui = nil

function createMainGui()
    if mainGui then mainGui:Destroy() end

    local cur = {
        remove   = REMOVE_EFFECTS,
        simplify = SIMPLIFY_MESH_EFFECTS,
        afk      = AFK_GRIND,
        auto     = AUTO_EXECUTE,
    }

    mainGui = Instance.new("ScreenGui")
    mainGui.Name           = "YuziroFPSBoosterGUI"
    mainGui.ResetOnSpawn   = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protect(mainGui)
    mainGui.Parent = guiParent()

    -- Backdrop — fully transparent, just keeps clicks from passing through
    local backdrop = Instance.new("Frame", mainGui)
    backdrop.Size                 = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel      = 0

    local FW, FH = 500, 620
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(0, FW, 0, FH)
    frame.Position         = UDim2.new(0.5, -FW/2, 0.5, -FH/2)
    frame.BackgroundColor3 = C.S0
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    frame.ZIndex           = 2
    frame.Parent           = mainGui
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local fsk = Instance.new("UIStroke", frame)
    fsk.Color = C.A2; fsk.Thickness = 1; fsk.Transparency = 0.6

    local leftStripe = Instance.new("Frame", frame)
    leftStripe.Size             = UDim2.new(0, 3, 1, -16)
    leftStripe.Position         = UDim2.new(0, 0, 0, 8)
    leftStripe.BackgroundColor3 = C.A2
    leftStripe.BorderSizePixel  = 0
    Instance.new("UICorner", leftStripe).CornerRadius = UDim.new(0, 3)
    leftStripe.BackgroundTransparency = 0.3

    local HDR_H   = 96
    local HDR_PAD = 24

    local av = makeAvatar(frame, 56, UDim2.new(0, HDR_PAD, 0, 20))

    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.Size               = UDim2.new(0, 220, 0, 28)
    nameLbl.Position           = UDim2.new(0, HDR_PAD + 68, 0, 22)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text               = "FPS BOOSTER"
    nameLbl.TextColor3         = C.T1
    nameLbl.TextSize           = 20
    nameLbl.Font               = Enum.Font.GothamBlack
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local subLbl = Instance.new("TextLabel", frame)
    subLbl.Size               = UDim2.new(0, 220, 0, 18)
    subLbl.Position           = UDim2.new(0, HDR_PAD + 68, 0, 54)
    subLbl.BackgroundTransparency = 1
    subLbl.Text               = "yuziro  //  v2"
    subLbl.TextColor3         = C.T3
    subLbl.TextSize           = 12
    subLbl.Font               = Enum.Font.Gotham
    subLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size             = UDim2.new(0, 36, 0, 36)
    closeBtn.Position         = UDim2.new(1, -48, 0, 28)
    closeBtn.BackgroundColor3 = C.S2
    closeBtn.Text             = "X"
    closeBtn.TextColor3       = C.T3
    closeBtn.TextSize         = 13
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.BorderSizePixel  = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, 0.1, { BackgroundColor3 = C.CLR, TextColor3 = C.W })
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, 0.1, { BackgroundColor3 = C.S2, TextColor3 = C.T3 })
    end)

    local minBtn = Instance.new("TextButton", frame)
    minBtn.Size             = UDim2.new(0, 36, 0, 36)
    minBtn.Position         = UDim2.new(1, -90, 0, 28)
    minBtn.BackgroundColor3 = C.S2
    minBtn.Text             = "_"
    minBtn.TextColor3       = C.T3
    minBtn.TextSize         = 16
    minBtn.Font             = Enum.Font.GothamBold
    minBtn.BorderSizePixel  = 0
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)
    minBtn.MouseEnter:Connect(function()
        tw(minBtn, 0.1, { BackgroundColor3 = C.S3, TextColor3 = C.A })
    end)
    minBtn.MouseLeave:Connect(function()
        tw(minBtn, 0.1, { BackgroundColor3 = C.S2, TextColor3 = C.T3 })
    end)

    local fpsDot = dot(frame, 8, C.OK, 4)
    fpsDot.Position = UDim2.new(1, -174, 0, 36)

    local fpsBadgeLbl = Instance.new("TextLabel", frame)
    fpsBadgeLbl.Size               = UDim2.new(0, 80, 0, 24)
    fpsBadgeLbl.Position           = UDim2.new(1, -164, 0, 28)
    fpsBadgeLbl.BackgroundTransparency = 1
    fpsBadgeLbl.Text               = currentFPS .. " FPS"
    fpsBadgeLbl.TextColor3         = C.A
    fpsBadgeLbl.TextSize           = 15
    fpsBadgeLbl.Font               = Enum.Font.GothamBold
    fpsBadgeLbl.TextXAlignment     = Enum.TextXAlignment.Left
    table.insert(fpsListeners, fpsBadgeLbl)

    local liveLbl = Instance.new("TextLabel", frame)
    liveLbl.Size               = UDim2.new(0, 80, 0, 14)
    liveLbl.Position           = UDim2.new(1, -164, 0, 54)
    liveLbl.BackgroundTransparency = 1
    liveLbl.Text               = "LIVE"
    liveLbl.TextColor3         = C.T3
    liveLbl.TextSize           = 10
    liveLbl.Font               = Enum.Font.GothamBold
    liveLbl.TextXAlignment     = Enum.TextXAlignment.Left

    hRule(frame, HDR_H, C.T3, 0.6)

    local STAT_Y = HDR_H + 16
    local STAT_H = 50
    local STAT_W = math.floor((FW - 48) / 3)

    local function makeStat(label, value, idx)
        local xOff = 24 + idx * STAT_W
        local vl = Instance.new("TextLabel", frame)
        vl.Size               = UDim2.new(0, STAT_W, 0, 24)
        vl.Position           = UDim2.new(0, xOff, 0, STAT_Y)
        vl.BackgroundTransparency = 1
        vl.Text               = value
        vl.TextColor3         = C.T1
        vl.TextSize           = 16
        vl.Font               = Enum.Font.GothamBold
        vl.TextXAlignment     = Enum.TextXAlignment.Left

        local ll = Instance.new("TextLabel", frame)
        ll.Size               = UDim2.new(0, STAT_W, 0, 16)
        ll.Position           = UDim2.new(0, xOff, 0, STAT_Y + 26)
        ll.BackgroundTransparency = 1
        ll.Text               = label
        ll.TextColor3         = C.T3
        ll.TextSize           = 11
        ll.Font               = Enum.Font.Gotham
        ll.TextXAlignment     = Enum.TextXAlignment.Left

        if idx > 0 then
            local vd = Instance.new("Frame", frame)
            vd.Size             = UDim2.new(0, 1, 0, STAT_H - 8)
            vd.Position         = UDim2.new(0, xOff - 6, 0, STAT_Y + 4)
            vd.BackgroundColor3 = C.T3
            vd.BackgroundTransparency = 0.5
            vd.BorderSizePixel  = 0
        end
    end

    makeStat("QUALITY",   "Level 1",   0)
    makeStat("SHADOWS",   "Disabled",  1)
    makeStat("RENDERER",  "Compat",    2)

    hRule(frame, HDR_H + STAT_H + 20, C.T3, 0.6)

    local SEC_Y = HDR_H + STAT_H + 32
    local secLabel = Instance.new("TextLabel", frame)
    secLabel.Size               = UDim2.new(1, -48, 0, 16)
    secLabel.Position           = UDim2.new(0, 24, 0, SEC_Y)
    secLabel.BackgroundTransparency = 1
    secLabel.Text               = "SETTINGS"
    secLabel.TextColor3         = C.T3
    secLabel.TextSize           = 11
    secLabel.Font               = Enum.Font.GothamBold
    secLabel.TextXAlignment     = Enum.TextXAlignment.Left

    local TROW_H   = 64
    local TROW_Y   = SEC_Y + 20
    local TROW_PAD = 24

    local function makeToggle(label, desc, default, rowIdx, onChange, isSpecial)
        local onCol = isSpecial and C.SP or C.A
        local yPos  = TROW_Y + rowIdx * TROW_H

        local rowHit = Instance.new("Frame", frame)
        rowHit.Size             = UDim2.new(1, -6, 0, TROW_H)
        rowHit.Position         = UDim2.new(0, 3, 0, yPos)
        rowHit.BackgroundColor3 = C.S0
        rowHit.BorderSizePixel  = 0
        Instance.new("UICorner", rowHit).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel", rowHit)
        lbl.Size               = UDim2.new(1, -110, 0, 26)
        lbl.Position           = UDim2.new(0, TROW_PAD - 3, 0, 10)
        lbl.BackgroundTransparency = 1
        lbl.Text               = label
        lbl.TextColor3         = C.T1
        lbl.TextSize           = 15
        lbl.Font               = Enum.Font.GothamSemibold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left

        local descL = Instance.new("TextLabel", rowHit)
        descL.Size               = UDim2.new(1, -110, 0, 16)
        descL.Position           = UDim2.new(0, TROW_PAD - 3, 0, 38)
        descL.BackgroundTransparency = 1
        descL.Text               = desc
        descL.TextColor3         = C.T3
        descL.TextSize           = 11
        descL.Font               = Enum.Font.Gotham
        descL.TextXAlignment     = Enum.TextXAlignment.Left

        local TW, TH = 52, 28
        local track = Instance.new("Frame", rowHit)
        track.Size             = UDim2.new(0, TW, 0, TH)
        track.Position         = UDim2.new(1, -(TW + 18), 0.5, -TH/2)
        track.BackgroundColor3 = default and onCol or C.OFF
        track.BorderSizePixel  = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

        local KS = TH - 6
        local knob = Instance.new("Frame", track)
        knob.Size             = UDim2.new(0, KS, 0, KS)
        knob.Position         = default
            and UDim2.new(1, -(KS+3), 0.5, -KS/2)
            or  UDim2.new(0,       3, 0.5, -KS/2)
        knob.BackgroundColor3 = C.W
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 2)

        if rowIdx < 2 then
            hRule(frame, yPos + TROW_H, C.T3, 0.72)
        end

        local clickBtn = Instance.new("TextButton", rowHit)
        clickBtn.Size               = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text               = ""
        clickBtn.MouseEnter:Connect(function()
            tw(rowHit, 0.1, { BackgroundColor3 = C.S2 })
        end)
        clickBtn.MouseLeave:Connect(function()
            tw(rowHit, 0.1, { BackgroundColor3 = C.S0 })
        end)
        local val = default
        clickBtn.MouseButton1Click:Connect(function()
            val = not val
            tw(track, 0.14, { BackgroundColor3 = val and onCol or C.OFF })
            tw(knob,  0.14, {
                Position = val
                    and UDim2.new(1, -(KS+3), 0.5, -KS/2)
                    or  UDim2.new(0,       3, 0.5, -KS/2)
            })
            if onChange then onChange(val) end
        end)
    end

    makeToggle("Remove Effects",  "Disable beams, trails and particles",  cur.remove,   0, function(v) cur.remove   = v end)
    makeToggle("Simplify Meshes", "Clear mesh IDs in ReplicatedStorage",  cur.simplify, 1, function(v) cur.simplify = v end)
    makeToggle("AFK Grind Mode",  "Max optimization, clears all meshes",  cur.afk,      2, function(v) cur.afk      = v end)

    -- ── Info row ───────────────────────────────────────────
    local infoY = TROW_Y + TROW_H * 3
    local infoRow = Instance.new("Frame", frame)
    infoRow.Size             = UDim2.new(1, -6, 0, TROW_H)
    infoRow.Position         = UDim2.new(0, 3, 0, infoY)
    infoRow.BackgroundColor3 = C.S0
    infoRow.BorderSizePixel  = 0
    Instance.new("UICorner", infoRow).CornerRadius = UDim.new(0, 4)

    local infoDot = dot(infoRow, 7, C.SP, 3)
    infoDot.Position = UDim2.new(0, TROW_PAD - 3, 0, 16)

    local infoTitle = Instance.new("TextLabel", infoRow)
    infoTitle.Size               = UDim2.new(1, -20, 0, 26)
    infoTitle.Position           = UDim2.new(0, TROW_PAD + 12, 0, 10)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text               = "Auto Execute"
    infoTitle.TextColor3         = C.T2
    infoTitle.TextSize           = 15
    infoTitle.Font               = Enum.Font.GothamSemibold
    infoTitle.TextXAlignment     = Enum.TextXAlignment.Left

    local infoDesc = Instance.new("TextLabel", infoRow)
    infoDesc.Size               = UDim2.new(1, -20, 0, 16)
    infoDesc.Position           = UDim2.new(0, TROW_PAD + 12, 0, 38)
    infoDesc.BackgroundTransparency = 1
    infoDesc.Text               = "Add this script to your executor's autoexec folder"
    infoDesc.TextColor3         = C.T3
    infoDesc.TextSize           = 11
    infoDesc.Font               = Enum.Font.Gotham
    infoDesc.TextXAlignment     = Enum.TextXAlignment.Left

    local BTN_AREA_Y = TROW_Y + TROW_H * 4 + 14
    hRule(frame, BTN_AREA_Y, C.T3, 0.6)

    local BTN_Y = BTN_AREA_Y + 16
    local BTN_H = 54

    local BTN_ACTIVE_BG = Color3.fromRGB(22, 80, 52)
    local BTN_LOCKED_BG = Color3.fromRGB(18, 18, 24)
    local isLocked = HAS_APPLIED

    local boostBtn = Instance.new("TextButton", frame)
    boostBtn.Size             = UDim2.new(1, -48, 0, BTN_H)
    boostBtn.Position         = UDim2.new(0, 24, 0, BTN_Y)
    boostBtn.BackgroundColor3 = isLocked and BTN_LOCKED_BG or C.A2
    boostBtn.Text             = ""
    boostBtn.AutoButtonColor  = false
    boostBtn.BorderSizePixel  = 0
    Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 6)

    local lockStroke = Instance.new("UIStroke", boostBtn)
    lockStroke.Color       = isLocked and C.T3 or C.A2
    lockStroke.Thickness   = 1
    lockStroke.Transparency = isLocked and 0.3 or 1

    local btnDot = dot(boostBtn, 8, isLocked and C.T3 or C.OK, 4)
    btnDot.Position = UDim2.new(0, 18, 0.5, -4)
    btnDot.ZIndex   = 3

    local btnLbl = Instance.new("TextLabel", boostBtn)
    btnLbl.Size                = UDim2.new(1, 0, 1, 0)
    btnLbl.BackgroundTransparency = 1
    btnLbl.Text                = isLocked and "BOOST ACTIVE" or "BOOST NOW"
    btnLbl.TextColor3          = isLocked and C.T2 or C.S0
    btnLbl.TextSize            = 16
    btnLbl.Font                = Enum.Font.GothamBlack

    boostBtn.MouseEnter:Connect(function()
        if isLocked then
            btnLbl.Text = "ALREADY APPLIED"
            tw(btnLbl, 0.1, { TextColor3 = C.T3 })
        else
            tw(boostBtn, 0.1, { BackgroundColor3 = C.A })
        end
    end)
    boostBtn.MouseLeave:Connect(function()
        if isLocked then
            btnLbl.Text = "BOOST ACTIVE"
            tw(btnLbl, 0.1, { TextColor3 = C.T2 })
        else
            tw(boostBtn, 0.1, { BackgroundColor3 = C.A2 })
        end
    end)

    local BOT_Y = BTN_Y + BTN_H + 12
    local statusLbl = Instance.new("TextLabel", frame)
    statusLbl.Size               = UDim2.new(1, -48, 0, 16)
    statusLbl.Position           = UDim2.new(0, 24, 0, BOT_Y)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text               = isLocked
        and "Boost was applied — changes are permanent"
        or  "Ready"
    statusLbl.TextColor3         = C.T3
    statusLbl.TextSize           = 11
    statusLbl.Font               = Enum.Font.Gotham
    statusLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local function setStatus(text, color)
        statusLbl.Text       = text
        statusLbl.TextColor3 = color or C.T3
    end

    if isLocked then
        secLabel.Text       = "SETTINGS  —  READ ONLY"
        secLabel.TextColor3 = C.T3
    end

    -- ── Smooth close/minimize animation ────────────────────
    local ANIM_DURATION = 0.28

    local function closeMain(andShowMini)
        frame.Active = false
        tw(frame, ANIM_DURATION, {
            Size     = UDim2.new(0, FW, 0, 0),
            Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2 - 40),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        task.wait(ANIM_DURATION + 0.04)

        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsBadgeLbl then table.remove(fpsListeners, i); break end
        end
        if mainGui then mainGui:Destroy(); mainGui = nil end

        if andShowMini then
            createMiniGui()
            showMiniGui()
        end
    end

    closeBtn.MouseButton1Click:Connect(function() closeMain(false) end)
    minBtn.MouseButton1Click:Connect(function() closeMain(true) end)

    boostBtn.MouseButton1Click:Connect(function()
        -- If already applied, do nothing — button is permanently locked
        if isLocked then return end

        REMOVE_EFFECTS        = cur.remove
        SIMPLIFY_MESH_EFFECTS = cur.simplify
        AFK_GRIND             = cur.afk
        AUTO_EXECUTE          = cur.auto

        tw(boostBtn, 0.06, { BackgroundColor3 = C.S3 })
        task.wait(0.07)

        setStatus("Applying...", C.A)
        btnLbl.Text       = "APPLYING..."
        btnLbl.TextColor3 = C.T2
        tw(boostBtn, 0.1, { BackgroundColor3 = C.S2 })

        task.spawn(function()
            local ok = pcall(runBooster)
            if ok then
                notify("Boost applied.")

                -- Lock permanently
                isLocked  = true
                HAS_APPLIED = true
                saveSettings()  -- persist the lock

                -- Transition button to locked state
                tw(boostBtn, 0.3, { BackgroundColor3 = BTN_LOCKED_BG })
                tw(btnLbl,   0.3, { TextColor3 = C.T2 })
                tw(btnDot,   0.3, { BackgroundColor3 = C.T3 })
                lockStroke.Transparency = 0.3
                btnLbl.Text = "BOOST ACTIVE"

                setStatus("Boost was applied — changes are permanent", C.T3)
                secLabel.Text       = "SETTINGS  —  READ ONLY"
                secLabel.TextColor3 = C.T3

                task.wait(1.2)
                closeMain(cur.auto)
            else
                setStatus("Failed — see console", C.ERR)
                btnLbl.Text       = "BOOST NOW"
                btnLbl.TextColor3 = C.S0
                tw(boostBtn, 0.2, { BackgroundColor3 = C.A2 })
            end
        end)
    end)

    -- ── Open animation (slides DOWN into place from above) ─
    frame.Size     = UDim2.new(0, FW, 0, 0)
    frame.Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2 - 30)
    tw(frame, 0.36, {
        Size     = UDim2.new(0, FW, 0, FH),
        Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2),
    }, Enum.EasingStyle.Back)
end

-- ─── Entry Point ─────────────────────────────────────────
createMiniGui()

if AUTO_EXECUTE then
    print("yuziro fps booster v2: auto-executing...")
    task.spawn(function()
        local ok = pcall(runBooster)
        if ok then
            print("yuziro fps booster v2: complete!")
            notify("Boost activated.")
            HAS_APPLIED = true
            saveSettings()
        else
            warn("yuziro fps booster v2: runBooster failed!")
        end
    end)
    task.delay(0.5, showMiniGui)
else
    createMainGui()
end

-- ─── Teleport Re-queue (Universal) ──────────────────────
-- Save the script to disk so any executor can re-read it.
local SCRIPT_FILE = "Yuziro_FPSBooster_Main.lua"

-- Step 1: always save current script to disk if possible
if writefile then
    pcall(function()
        -- getscriptbytecode / getscriptsource work on most executors
        -- as a fallback we save a self-loader stub
        local src = nil
        if getscriptsource then
            pcall(function() src = getscriptsource() end)
        end
        if not src and get_script_bytecode then
            -- not useful raw, skip
            src = nil
        end
        -- If we can't get source, write a stub that HttpGet's from a url
        -- (user can replace URL with their own raw paste link)
        if not src then
            src = [[-- yuziro fps booster v2 stub
-- Replace this URL with your raw script URL if needed
loadstring(game:HttpGet("https://raw.githubusercontent.com/yuziro/fps-booster/main/main.lua"))()
]]
        end
        writefile(SCRIPT_FILE, src)
    end)
end

-- Step 2: queue the re-execution using whichever method the executor supports
local rerunCode = ([[
    local ok, err = pcall(function()
        if readfile and isfile and isfile("%s") then
            loadstring(readfile("%s"))()
        end
    end)
    if not ok then warn("yuziro fps booster re-queue failed: " .. tostring(err)) end
]]):format(SCRIPT_FILE, SCRIPT_FILE)

-- Method 1: queue_on_teleport (Synapse X, KRNL, Velocity, etc.)
if queue_on_teleport then
    pcall(function() queue_on_teleport(rerunCode) end)

-- Method 2: syn.queue_on_teleport (older Synapse X builds)
elseif syn and syn.queue_on_teleport then
    pcall(function() syn.queue_on_teleport(rerunCode) end)

-- Method 3: hookfunction on teleport service (Fluxus fallback)
elseif hookfunction then
    pcall(function()
        local TPS = game:GetService("TeleportService")
        local orig = TPS.Teleport
        hookfunction(orig, function(...)
            pcall(function() loadstring(rerunCode)() end)
            return orig(...)
        end)
    end)
end

-- Method 4: executor auto-exec folder (most modern executors)
-- If the executor has an autoexec folder, saving the file there
-- means it runs automatically every game join — most reliable.
if writefile then
    pcall(function()
        -- Common autoexec paths across executors
        local autoexecPaths = {
            "autoexec/" .. SCRIPT_FILE,   -- Synapse X, Velocity
            "auto-exec/" .. SCRIPT_FILE,  -- KRNL
            "AutoExec/" .. SCRIPT_FILE,   -- Fluxus
        }
        -- Only write to autoexec if we already have the file saved
        if readfile and isfile and isfile(SCRIPT_FILE) then
            local src = readfile(SCRIPT_FILE)
            for _, path in ipairs(autoexecPaths) do
                pcall(function() writefile(path, src) end)
            end
        end
    end)
end

print("yuziro fps booster v2 loaded — auto-execute: " .. tostring(AUTO_EXECUTE))
