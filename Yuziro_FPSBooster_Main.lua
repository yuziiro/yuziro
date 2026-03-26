-- ╔══════════════════════════════════════════╗
-- ║       yuziro FPS Booster                 ║
-- ╚══════════════════════════════════════════╝

local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local StarterGui   = game:GetService("StarterGui")
local RunService   = game:GetService("RunService")

local player        = Players.LocalPlayer
local SETTINGS_FILE = "Yuziro_FPSBooster_Settings.json"

-- ─── Defaults ────────────────────────────────
local REMOVE_EFFECTS        = false
local SIMPLIFY_MESH_EFFECTS = false
local AFK_GRIND             = false
local AUTO_EXECUTE          = true

-- ─── Theme ───────────────────────────────────
local C = {
    BG_DEEP    = Color3.fromRGB(8,   12,  24),
    BG_MID     = Color3.fromRGB(12,  18,  36),
    BG_PANEL   = Color3.fromRGB(16,  24,  48),
    BG_HOVER   = Color3.fromRGB(22,  34,  66),
    ACCENT     = Color3.fromRGB(56,  148, 255),
    ACCENT2    = Color3.fromRGB(0,   200, 255),
    ACCENT_DIM = Color3.fromRGB(20,  60,  140),
    ON         = Color3.fromRGB(56,  148, 255),
    OFF        = Color3.fromRGB(30,  40,  65),
    TEXT1      = Color3.fromRGB(220, 235, 255),
    TEXT2      = Color3.fromRGB(100, 150, 200),
    TEXT_DIM   = Color3.fromRGB(50,  75,  120),
    SUCCESS    = Color3.fromRGB(60,  220, 160),
    ERROR      = Color3.fromRGB(255, 75,  75),
    CLOSE      = Color3.fromRGB(180, 50,  50),
    BORDER     = Color3.fromRGB(28,  55,  120),
    SPECIAL_BG = Color3.fromRGB(10,  18,  42),
}

-- ─── Settings I/O ────────────────────────────
local function loadSettings()
    if not (readfile and isfile and isfile(SETTINGS_FILE)) then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)
    if ok and data then
        REMOVE_EFFECTS        = data.REMOVE_EFFECTS        or false
        SIMPLIFY_MESH_EFFECTS = data.SIMPLIFY_MESH_EFFECTS or false
        AFK_GRIND             = data.AFK_GRIND             or false
        AUTO_EXECUTE          = data.AUTO_EXECUTE ~= nil and data.AUTO_EXECUTE or true
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
        }))
    end)
end

loadSettings()

-- ─── Core Booster ────────────────────────────
local function runBooster()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    task.wait(1)

    local L  = game:GetService("Lighting")
    local RS = game:GetService("ReplicatedStorage")

    local SKIP_CLASSES = {
        SelectionBox=true, SelectionSphere=true,
        SelectionPartLasso=true, SelectionPointLasso=true,
        Handles=true, ArcHandles=true,
    }
    local SKY_PROPS = {
        "SkyboxBk","SkyboxDn","SkyboxFt",
        "SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId"
    }

    L.Ambient                  = Color3.fromRGB(170, 170, 170)
    L.OutdoorAmbient           = Color3.new()
    L.ColorShift_Bottom        = Color3.new()
    L.ColorShift_Top           = Color3.new()
    L.Brightness               = 0
    L.ShadowSoftness           = 0
    L.GlobalShadows            = false
    L.Technology               = Enum.Technology.Compatibility
    L.EnvironmentDiffuseScale  = 0
    L.EnvironmentSpecularScale = 0
    L.LightingStyle            = Enum.LightingStyle.Soft

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.CastShadow       = false
        terrain.WaterWaveSize    = 0
        terrain.WaterWaveSpeed   = 0
        terrain.WaterReflectance = 0
        if sethiddenproperty then sethiddenproperty(terrain, "Decoration", false) end
    end

    local function processObject(o)
        if SKIP_CLASSES[o.ClassName] then
            o.Adornee = nil
        elseif o:IsA("BasePart") then
            o.Material    = Enum.Material.SmoothPlastic
            o.Reflectance = 0
            o.CastShadow  = false
            if o:IsA("MeshPart") or o:IsA("PartOperation") then
                o.CollisionFidelity = Enum.CollisionFidelity.Box
            end
        elseif o:IsA("Sky") then
            for _, p in ipairs(SKY_PROPS) do o[p] = "" end
            o.StarCount = 0
        elseif o:IsA("Atmosphere") then
            o.Density = 0; o.Offset = 0; o.Glare = 0; o.Haze = 0
        elseif o:IsA("SurfaceAppearance") then
            o.ColorMap = ""; o.NormalMap = ""; o.RoughnessMap = ""; o.MetalnessMap = ""
        elseif o:IsA("Texture") or o:IsA("Decal") then
            o.Texture = ""
        elseif o:IsA("PostEffect") or o:IsA("PointLight")
            or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
            o.Enabled = false
        end
    end

    for _, o in ipairs(game:GetDescendants()) do processObject(o) end

    local function disableEffect(o)
        if not o then return end
        if o:IsA("Beam") or o:IsA("Trail") then
            o.Enabled = false
        elseif o:IsA("ParticleEmitter") then
            o.Lifetime = NumberRange.new(0)
        end
    end

    if REMOVE_EFFECTS or AFK_GRIND then
        for _, o in ipairs(RS:GetDescendants()) do disableEffect(o) end
        workspace.DescendantAdded:Connect(disableEffect)
    end

    local function simplify(list)
        for _, o in ipairs(list) do
            if o:IsA("MeshPart") or o:IsA("SpecialMesh") then o.MeshId = "" end
        end
    end

    if AFK_GRIND then
        simplify(game:GetDescendants())
    elseif SIMPLIFY_MESH_EFFECTS then
        simplify(RS:GetDescendants())
    end

    if AFK_GRIND or SIMPLIFY_MESH_EFFECTS then
        game.DescendantAdded:Connect(function(o)
            if o:IsA("MeshPart") or o:IsA("SpecialMesh") then
                if AFK_GRIND or (SIMPLIFY_MESH_EFFECTS and o:IsDescendantOf(RS)) then
                    o.MeshId = ""
                end
            end
        end)
    end
end

-- ─── Helpers ─────────────────────────────────
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "yuziro fps booster", Text = text, Duration = 5,
        })
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

local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t), props):Play()
end

local function roundFix(parent, color)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1, 0, 0, 12)
    f.Position         = UDim2.new(0, 0, 1, -12)
    f.BackgroundColor3 = color
    f.BorderSizePixel  = 0
    return f
end

-- ─── Live FPS tracker ────────────────────────
local currentFPS   = 0
local fpsListeners = {}

RunService.Heartbeat:Connect(function(dt)
    currentFPS = math.round(1 / dt)
    for _, lbl in ipairs(fpsListeners) do
        if lbl and lbl.Parent then
            lbl.Text       = currentFPS .. " FPS"
            lbl.TextColor3 = currentFPS >= 55 and C.SUCCESS
                          or currentFPS >= 30 and C.ACCENT
                          or C.ERROR
        end
    end
end)

-- ─── Mini GUI ────────────────────────────────
local miniGui = nil

local function showMiniGui()
    if not miniGui then return end
    miniGui.Enabled = true
    local pill = miniGui:FindFirstChild("MiniButton", true)
    if not pill then return end
    pill.Position = UDim2.new(0, -90, 0, 10)
    tween(pill, 0.5, { Position = UDim2.new(0, 10, 0, 10) })
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

    local pill = Instance.new("Frame")
    pill.Name             = "MiniButton"
    pill.Size             = UDim2.new(0, 88, 0, 34)
    pill.Position         = UDim2.new(0, 10, 0, 10)
    pill.BackgroundColor3 = C.BG_MID
    pill.BorderSizePixel  = 0
    pill.Active           = true
    pill.Draggable        = true
    pill.Parent           = miniGui
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local pillStroke = Instance.new("UIStroke", pill)
    pillStroke.Color       = C.ACCENT
    pillStroke.Thickness   = 1
    pillStroke.Transparency = 0.5

    local statusDot = Instance.new("Frame", pill)
    statusDot.Size             = UDim2.new(0, 7, 0, 7)
    statusDot.Position         = UDim2.new(0, 10, 0.5, -3.5)
    statusDot.BackgroundColor3 = C.SUCCESS
    statusDot.BorderSizePixel  = 0
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

    local fpsLbl = Instance.new("TextLabel", pill)
    fpsLbl.Size                = UDim2.new(1, -24, 1, 0)
    fpsLbl.Position            = UDim2.new(0, 22, 0, 0)
    fpsLbl.BackgroundTransparency = 1
    fpsLbl.Text                = currentFPS .. " FPS"
    fpsLbl.TextColor3          = C.ACCENT2
    fpsLbl.TextSize            = 12
    fpsLbl.Font                = Enum.Font.GothamBold
    fpsLbl.TextXAlignment      = Enum.TextXAlignment.Left
    table.insert(fpsListeners, fpsLbl)

    local dropdown = Instance.new("Frame")
    dropdown.Name             = "Dropdown"
    dropdown.Size             = UDim2.new(0, 188, 0, 88)
    dropdown.Position         = UDim2.new(0, 96, 0, 0)
    dropdown.BackgroundColor3 = C.BG_MID
    dropdown.BorderSizePixel  = 0
    dropdown.Visible          = false
    dropdown.Parent           = pill
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 10)

    local ds = Instance.new("UIStroke", dropdown)
    ds.Color       = C.BORDER
    ds.Thickness   = 1
    ds.Transparency = 0.2

    local function makeDropBtn(text, textColor, yPos)
        local base = Color3.fromRGB(
            math.floor(textColor.R * 255 * 0.18),
            math.floor(textColor.G * 255 * 0.18),
            math.floor(textColor.B * 255 * 0.18)
        )
        local hov = Color3.fromRGB(
            math.min(math.floor(textColor.R * 255 * 0.30), 255),
            math.min(math.floor(textColor.G * 255 * 0.30), 255),
            math.min(math.floor(textColor.B * 255 * 0.30), 255)
        )
        local b = Instance.new("TextButton", dropdown)
        b.Size             = UDim2.new(1, -12, 0, 32)
        b.Position         = UDim2.new(0, 6, 0, yPos)
        b.BackgroundColor3 = base
        b.Text             = text
        b.TextColor3       = textColor
        b.TextSize         = 11
        b.Font             = Enum.Font.GothamSemibold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = hov}) end)
        b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = base}) end)
        return b
    end

    local disableBtn = makeDropBtn("Disable Auto Execute", C.ACCENT, 6)
    local destroyBtn = makeDropBtn("Close Widget",         C.ERROR,  44)

    local open = false
    local clickArea = Instance.new("TextButton", pill)
    clickArea.Size               = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text               = ""
    clickArea.ZIndex             = 2
    clickArea.MouseButton1Click:Connect(function()
        open = not open
        dropdown.Visible = open
    end)

    disableBtn.MouseButton1Click:Connect(function()
        AUTO_EXECUTE = false
        saveSettings()
        dropdown.Visible = false
        open = false
        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsLbl then table.remove(fpsListeners, i) break end
        end
        createMiniGui()
        createMainGui()
    end)

    destroyBtn.MouseButton1Click:Connect(function()
        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsLbl then table.remove(fpsListeners, i) break end
        end
        miniGui:Destroy()
        miniGui = nil
    end)
end

-- ─── Main GUI ────────────────────────────────
mainGui = nil

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

    -- ── Outer frame ──────────────────────────
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(0, 330, 0, 460)
    frame.Position         = UDim2.new(0.5, -165, 0.5, -230)
    frame.BackgroundColor3 = C.BG_DEEP
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    frame.Parent           = mainGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    Instance.new("UIStroke", frame).Color       = C.ACCENT
    frame:FindFirstChildOfClass("UIStroke").Thickness   = 1
    frame:FindFirstChildOfClass("UIStroke").Transparency = 0.65

    -- ── Title bar ────────────────────────────
    local titleBar = Instance.new("Frame", frame)
    titleBar.Size             = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = C.BG_MID
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
    roundFix(titleBar, C.BG_MID)

    -- Animated accent underline
    local accentLine = Instance.new("Frame", titleBar)
    accentLine.Size             = UDim2.new(0, 50, 0, 2)
    accentLine.Position         = UDim2.new(0, 14, 1, -2)
    accentLine.BackgroundColor3 = C.ACCENT
    accentLine.BorderSizePixel  = 0
    task.delay(0.5, function()
        tween(accentLine, 0.7, { Size = UDim2.new(0.45, 0, 0, 2) })
    end)

    -- Icon
    local iconBg = Instance.new("Frame", titleBar)
    iconBg.Size             = UDim2.new(0, 32, 0, 32)
    iconBg.Position         = UDim2.new(0, 14, 0.5, -16)
    iconBg.BackgroundColor3 = C.ACCENT_DIM
    iconBg.BorderSizePixel  = 0
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
    local iconLbl = Instance.new("TextLabel", iconBg)
    iconLbl.Size                = UDim2.new(1, 0, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                = "⚡"
    iconLbl.TextSize            = 15
    iconLbl.Font                = Enum.Font.GothamBold

    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size               = UDim2.new(1, -130, 0, 20)
    titleLbl.Position           = UDim2.new(0, 54, 0, 11)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "FPS BOOSTER"
    titleLbl.TextColor3         = C.TEXT1
    titleLbl.TextSize           = 14
    titleLbl.Font               = Enum.Font.GothamBold
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local byLbl = Instance.new("TextLabel", titleBar)
    byLbl.Size               = UDim2.new(1, -130, 0, 14)
    byLbl.Position           = UDim2.new(0, 54, 0, 33)
    byLbl.BackgroundTransparency = 1
    byLbl.Text               = "by yuziro"
    byLbl.TextColor3         = C.TEXT_DIM
    byLbl.TextSize           = 10
    byLbl.Font               = Enum.Font.Gotham
    byLbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- FPS badge in header
    local fpsBadge = Instance.new("Frame", titleBar)
    fpsBadge.Size             = UDim2.new(0, 74, 0, 28)
    fpsBadge.Position         = UDim2.new(1, -114, 0.5, -14)
    fpsBadge.BackgroundColor3 = C.BG_PANEL
    fpsBadge.BorderSizePixel  = 0
    Instance.new("UICorner", fpsBadge).CornerRadius = UDim.new(0, 7)

    local fpsBadgeLbl = Instance.new("TextLabel", fpsBadge)
    fpsBadgeLbl.Size                = UDim2.new(1, 0, 1, 0)
    fpsBadgeLbl.BackgroundTransparency = 1
    fpsBadgeLbl.Text                = currentFPS .. " FPS"
    fpsBadgeLbl.TextColor3          = C.ACCENT2
    fpsBadgeLbl.TextSize            = 12
    fpsBadgeLbl.Font                = Enum.Font.GothamBold
    table.insert(fpsListeners, fpsBadgeLbl)

    -- Close button
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.Position         = UDim2.new(1, -40, 0.5, -14)
    closeBtn.BackgroundColor3 = C.BG_PANEL
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = C.TEXT2
    closeBtn.TextSize         = 11
    closeBtn.Font             = Enum.Font.GothamBold
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.15, {BackgroundColor3 = C.CLOSE, TextColor3 = C.TEXT1})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.15, {BackgroundColor3 = C.BG_PANEL, TextColor3 = C.TEXT2})
    end)

    -- ── Content ──────────────────────────────
    local content = Instance.new("Frame", frame)
    content.Size                = UDim2.new(1, -20, 1, -74)
    content.Position            = UDim2.new(0, 10, 0, 68)
    content.BackgroundTransparency = 1

    local function sectionLabel(text, yPos)
        local l = Instance.new("TextLabel", content)
        l.Size                = UDim2.new(1, 0, 0, 14)
        l.Position            = UDim2.new(0, 4, 0, yPos)
        l.BackgroundTransparency = 1
        l.Text                = text
        l.TextColor3          = C.TEXT_DIM
        l.TextSize            = 9
        l.Font                = Enum.Font.GothamSemibold
        l.TextXAlignment      = Enum.TextXAlignment.Left
    end

    sectionLabel("OPTIMIZATION SETTINGS", 0)

    -- Toggle builder
    local function makeToggle(label, desc, default, yPos, onChange, isSpecial)
        local rowBg    = isSpecial and C.SPECIAL_BG or C.BG_MID
        local rowHover = C.BG_HOVER
        local onCol    = C.ON

        local row = Instance.new("Frame", content)
        row.Size             = UDim2.new(1, 0, 0, 52)
        row.Position         = UDim2.new(0, 0, 0, yPos)
        row.BackgroundColor3 = rowBg
        row.BorderSizePixel  = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local rs = Instance.new("UIStroke", row)
        rs.Color       = isSpecial and C.ACCENT or C.BORDER
        rs.Thickness   = 1
        rs.Transparency = isSpecial and 0.5 or 0.8

        -- Left accent bar
        local bar = Instance.new("Frame", row)
        bar.Size             = UDim2.new(0, 3, 0, 28)
        bar.Position         = UDim2.new(0, 0, 0.5, -14)
        bar.BackgroundColor3 = default and onCol or C.OFF
        bar.BorderSizePixel  = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size               = UDim2.new(1, -68, 0, 20)
        lbl.Position           = UDim2.new(0, 14, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text               = label
        lbl.TextColor3         = isSpecial and C.ACCENT2 or C.TEXT1
        lbl.TextSize           = 12
        lbl.Font               = Enum.Font.GothamSemibold
        lbl.TextXAlignment     = Enum.TextXAlignment.Left

        local desc2 = Instance.new("TextLabel", row)
        desc2.Size               = UDim2.new(1, -68, 0, 14)
        desc2.Position           = UDim2.new(0, 14, 0, 29)
        desc2.BackgroundTransparency = 1
        desc2.Text               = desc
        desc2.TextColor3         = C.TEXT_DIM
        desc2.TextSize           = 9
        desc2.Font               = Enum.Font.Gotham
        desc2.TextXAlignment     = Enum.TextXAlignment.Left

        local track = Instance.new("Frame", row)
        track.Size             = UDim2.new(0, 42, 0, 23)
        track.Position         = UDim2.new(1, -52, 0.5, -11.5)
        track.BackgroundColor3 = default and onCol or C.OFF
        track.BorderSizePixel  = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.Size             = UDim2.new(0, 18, 0, 18)
        knob.Position         = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local click = Instance.new("TextButton", row)
        click.Size               = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text               = ""

        local val = default
        click.MouseButton1Click:Connect(function()
            val = not val
            local col = val and onCol or C.OFF
            tween(knob,  0.18, { Position = val and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9) })
            tween(track, 0.18, { BackgroundColor3 = col })
            tween(bar,   0.18, { BackgroundColor3 = col })
            if onChange then onChange(val) end
        end)
        click.MouseEnter:Connect(function() tween(row, 0.15, {BackgroundColor3 = rowHover}) end)
        click.MouseLeave:Connect(function() tween(row, 0.15, {BackgroundColor3 = rowBg}) end)
    end

    makeToggle("Remove Effects",        "Disables beams, trails & particles",       cur.remove,   18,  function(v) cur.remove   = v end)
    makeToggle("Simplify Mesh Effects", "Clears mesh IDs in ReplicatedStorage",     cur.simplify, 76,  function(v) cur.simplify = v end)
    makeToggle("AFK Grind Mode",        "Max optimization — removes all meshes",    cur.afk,      134, function(v) cur.afk      = v end)
    makeToggle("Auto Execute on Load",  "Runs boost automatically when you join",   cur.auto,     192, function(v) cur.auto     = v end, true)

    -- Divider
    local divider = Instance.new("Frame", content)
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 0, 256)
    divider.BackgroundColor3 = C.BORDER
    divider.BorderSizePixel  = 0
    divider.BackgroundTransparency = 0.4

    -- Status row
    local statusDot = Instance.new("TextLabel", content)
    statusDot.Size                = UDim2.new(0, 14, 0, 16)
    statusDot.Position            = UDim2.new(0, 2, 0, 266)
    statusDot.BackgroundTransparency = 1
    statusDot.Text                = "●"
    statusDot.TextColor3          = C.TEXT_DIM
    statusDot.TextSize            = 9
    statusDot.Font                = Enum.Font.Gotham

    local statusLbl = Instance.new("TextLabel", content)
    statusLbl.Size                = UDim2.new(1, -20, 0, 16)
    statusLbl.Position            = UDim2.new(0, 18, 0, 266)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text                = "Ready to boost"
    statusLbl.TextColor3          = C.TEXT2
    statusLbl.TextSize            = 10
    statusLbl.Font                = Enum.Font.Gotham
    statusLbl.TextXAlignment      = Enum.TextXAlignment.Left

    local function setStatus(text, color)
        statusLbl.Text        = text
        statusLbl.TextColor3  = color
        statusDot.TextColor3  = color
    end

    -- Boost button
    local boostBtn = Instance.new("TextButton", content)
    boostBtn.Size             = UDim2.new(1, 0, 0, 46)
    boostBtn.Position         = UDim2.new(0, 0, 1, -46)
    boostBtn.BackgroundColor3 = C.ACCENT
    boostBtn.Text             = ""
    boostBtn.AutoButtonColor  = false
    boostBtn.BorderSizePixel  = 0
    Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 10)

    local boostGrad = Instance.new("UIGradient", boostBtn)
    boostGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 95, 210)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 148, 255)),
    })
    boostGrad.Rotation = 135

    local boostLbl = Instance.new("TextLabel", boostBtn)
    boostLbl.Size                = UDim2.new(1, 0, 1, 0)
    boostLbl.BackgroundTransparency = 1
    boostLbl.Text                = "BOOST NOW"
    boostLbl.TextColor3          = Color3.fromRGB(255, 255, 255)
    boostLbl.TextSize            = 14
    boostLbl.Font                = Enum.Font.GothamBold

    boostBtn.MouseEnter:Connect(function()
        tween(boostBtn, 0.15, {BackgroundColor3 = C.ACCENT2})
    end)
    boostBtn.MouseLeave:Connect(function()
        tween(boostBtn, 0.15, {BackgroundColor3 = C.ACCENT})
    end)

    -- Close logic
    local function closeMain()
        tween(frame, 0.28, {
            Size     = UDim2.new(0,0,0,0),
            Position = UDim2.new(0.5,0,0.5,0),
        })
        task.wait(0.3)
        for i, lbl in ipairs(fpsListeners) do
            if lbl == fpsBadgeLbl then table.remove(fpsListeners, i) break end
        end
        if mainGui then mainGui:Destroy(); mainGui = nil end
    end

    closeBtn.MouseButton1Click:Connect(closeMain)

    boostBtn.MouseButton1Click:Connect(function()
        REMOVE_EFFECTS        = cur.remove
        SIMPLIFY_MESH_EFFECTS = cur.simplify
        AFK_GRIND             = cur.afk
        AUTO_EXECUTE          = cur.auto
        saveSettings()

        tween(boostBtn, 0.08, {Size = UDim2.new(0.97,0,0,42)})
        task.wait(0.08)
        tween(boostBtn, 0.08, {Size = UDim2.new(1,0,0,46)})

        setStatus("Applying optimizations...", C.ACCENT)
        boostLbl.Text = "BOOSTING..."

        task.spawn(function()
            local ok = pcall(runBooster)
            if ok then
                notify("Boost activated successfully!")
                setStatus("✓  All optimizations applied", C.SUCCESS)
                boostLbl.Text = "✓  ACTIVE"
                tween(boostBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(18, 70, 45)})
                boostGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 70,  45)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 160, 100)),
                })
                task.wait(cur.auto and 1.2 or 2)
                closeMain()
                if cur.auto then showMiniGui() end
            else
                setStatus("✗  Boost failed — check console", C.ERROR)
                boostLbl.Text = "BOOST NOW"
            end
        end)
    end)

    -- Open animation
    frame.Size     = UDim2.new(0,0,0,0)
    frame.Position = UDim2.new(0.5,0,0.5,0)
    tween(frame, 0.45, {
        Size     = UDim2.new(0, 330, 0, 460),
        Position = UDim2.new(0.5, -165, 0.5, -230),
    })
end

-- ─── Entry Point ─────────────────────────────
createMiniGui()

if AUTO_EXECUTE then
    print("yuziro fps booster: auto-executing...")
    task.spawn(function()
        local ok = pcall(runBooster)
        if ok then
            print("yuziro fps booster: complete!")
            notify("Boost activated successfully!")
        else
            warn("yuziro fps booster: runBooster failed during auto-execute!")
        end
    end)
    task.delay(0.5, showMiniGui)
else
    createMainGui()
end

-- ─── Teleport Re-queue ───────────────────────
if queue_on_teleport and writefile then
    pcall(function()
        queue_on_teleport([[
            local ok, err = pcall(function()
                if readfile and isfile then
                    local f = "Yuziro_FPSBooster_Main.lua"
                    if isfile(f) then loadstring(readfile(f))() end
                end
            end)
            if not ok then
                warn("yuziro fps booster teleport re-queue failed: " .. tostring(err))
            end
        ]])
    end)
end

print("yuziro fps booster loaded — auto-execute: " .. tostring(AUTO_EXECUTE))
