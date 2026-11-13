-- PRD Visibility 3.0
-- Controls the visibility of the Personal Resource Display in WoW: Forever.
--   In combat: full opacity and bar text.
--   Out of combat while health/resource is changing: partial opacity.
--   Out of combat with full bars: hidden.
--
-- Forever hides current health and power values from addons (secret values),
-- so activity is used instead: while regenerating, the game fires health and
-- power events; when the bars are full (or rage reaches 0), they stop. The
-- wait time adapts to the rhythm of the regeneration ticks.

local ADDON_NAME = ...
local FRAME_NAME = "PersonalResourceDisplayFrame"
local BLIZZ_ADDON = "Blizzard_PersonalResourceDisplay"
local PREFIX = "|cff33ff99PRD Visibility:|r "

---------------------------------------------------------------------------
-- Texts
---------------------------------------------------------------------------
local LOCALES = {
    en = {
        loaded = "active. Type /prdv to open the options.",
        waiting = "waiting for %s to load...",
        notFound = "couldn't find %s yet.",
        enabled = "Enabled",
        textCombat = "Bar text only in combat",
        showWhen = "Show out of combat while changing:",
        health = "Health",
        mana = "Mana", rage = "Rage", energy = "Energy", other = "Other resources",
        opacity = "Opacity:",
        inCombat = "  In combat",
        regenerating = "  Regenerating",
        fullBars = "  Full bars",
        maxDelay = "Max wait",
        subtitle = "Personal Resource Display visibility based on combat and regeneration.",
        language = "Language: English",
        langReload = "language changed. Type /reload to apply it.",
        st_disabled = "disabled", st_combat = "combat", st_regen = "regenerating", st_idle = "idle",
        r_disabled = "addon disabled", r_combat = "in combat", r_dead = "dead",
        r_partial = "bars not full", r_full = "bars full",
        r_health = "health changing", r_power = "%s changing", r_none = "no changes",
        status = "state: %s (%d%%) | reason: %s | resource: %s",
        debug = "health: last event %.1fs ago, visible %.1fs more | resource: last event %.1fs ago, visible %.1fs more",
        commands = "commands: /prdv, /prdv options, /prdv help, /prdv status, /prdv debug",
        help = "Help",
        helpTitle = "PRD Visibility - Help",
        helpText = "If PRD Visibility stops loading after a WoW: Forever update:\n\n"
            .. "1. At character select, open the AddOns list.\n\n"
            .. "2. If the addon says |cffffd100Out of date|r, check |cffffd100Load out of date AddOns|r at the top of the list. That's all.\n\n"
            .. "3. If it says |cffffd100Incompatible|r, enter the game and type the command below in chat. It prints a number.\n\n"
            .. "4. Open |cffffd100PRDVisibility.toc|r (in Interface\\AddOns\\PRDVisibility) with Notepad and replace the number in the first line:\n"
            .. "     ## Interface: (the number)\n\n"
            .. "5. Save the file and restart the game.",
        helpCopy = "Click the box and press Ctrl+C to copy the command.",
        helpFooter = "If the addon doesn't load you can't open this window, so these steps are also in README.txt inside the addon folder.",
    },
    es = {
        loaded = "activo. Escribe /prdv para abrir las opciones.",
        waiting = "esperando a que cargue %s...",
        notFound = "no encontré %s todavía.",
        enabled = "Activado",
        textCombat = "Texto de las barras solo en combate",
        showWhen = "Mostrar fuera de combate cuando cambia:",
        health = "Vida",
        mana = "Maná", rage = "Rabia", energy = "Energía", other = "Otros recursos",
        opacity = "Opacidad:",
        inCombat = "  En combate",
        regenerating = "  Regenerando",
        fullBars = "  Barras llenas",
        maxDelay = "Espera máxima",
        subtitle = "Visibilidad del Personal Resource Display según combate y regeneración.",
        language = "Idioma: Español",
        langReload = "idioma cambiado. Escribe /reload para aplicarlo.",
        st_disabled = "desactivado", st_combat = "combate", st_regen = "regenerando", st_idle = "en reposo",
        r_disabled = "addon desactivado", r_combat = "en combate", r_dead = "muerto",
        r_partial = "barras incompletas", r_full = "barras llenas",
        r_health = "vida cambiando", r_power = "%s cambiando", r_none = "sin cambios",
        status = "estado: %s (%d%%) | motivo: %s | recurso: %s",
        debug = "vida: último evento hace %.1fs, visible %.1fs más | recurso: último evento hace %.1fs, visible %.1fs más",
        commands = "comandos: /prdv, /prdv opciones, /prdv ayuda, /prdv estado, /prdv debug",
        help = "Ayuda",
        helpTitle = "PRD Visibility - Ayuda",
        helpText = "Si PRD Visibility deja de cargar después de una actualización de WoW: Forever:\n\n"
            .. "1. En la selección de personaje, abre la lista de AddOns.\n\n"
            .. "2. Si el addon dice |cffffd100Out of date|r, marca |cffffd100Load out of date AddOns|r arriba de la lista. Con eso basta.\n\n"
            .. "3. Si dice |cffffd100Incompatible|r, entra al juego y escribe en el chat el comando de abajo. Te mostrará un número.\n\n"
            .. "4. Abre |cffffd100PRDVisibility.toc|r (en Interface\\AddOns\\PRDVisibility) con el Bloc de notas y reemplaza el número de la primera línea:\n"
            .. "     ## Interface: (el número)\n\n"
            .. "5. Guarda el archivo y reinicia el juego.",
        helpCopy = "Haz clic en el recuadro y presiona Ctrl+C para copiar el comando.",
        helpFooter = "Si el addon no carga no podrás abrir esta ventana, así que estos pasos también están en README.txt dentro de la carpeta del addon.",
    },
}
local L = LOCALES.en

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local DEFAULTS = {
    enabled = true,
    language = "en",
    health = true,
    power = { mana = true, rage = true, energy = true, other = true },
    maxDelay = 6,
    alphaCombat = 100, -- opacity in combat (%)
    alphaRegen = 50,   -- opacity while regenerating out of combat (%)
    alphaIdle = 0,     -- opacity with full bars out of combat (%)
    textCombatOnly = true,
}

-- Game power types -> settings key.
local POWER_KEYS = { [0] = "mana", [1] = "rage", [3] = "energy" }
local DECAY_POWER = { [1] = true, [6] = true } -- resources that drop to 0 at rest
local MANA_PAUSE = 5.5 -- mana stops regenerating for a few seconds after casting

local db
local prd
local applying = false
local lastReason = "-"

local track = {
    health = { last = 0, untilTime = 0 },
    power  = { last = 0, untilTime = 0 },
}

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function PowerKey()
    return POWER_KEYS[UnitPowerType("player")] or "other"
end

local function MarkActivity(t)
    local now = GetTime()
    local interval = now - t.last
    t.last = now
    local timeout
    if interval < db.maxDelay then
        timeout = math.max(1, math.min(db.maxDelay, interval * 1.5 + 0.25))
    else
        timeout = db.maxDelay
    end
    t.untilTime = math.max(t.untilTime, now + timeout)
end

-- true/false if values are readable, nil if they are secret.
local function ExactCheck()
    if db.health then
        local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
        if IsSecret(hp) or IsSecret(hpMax) then return nil end
        if hp < hpMax then return true end
    end
    if db.power[PowerKey()] then
        local pType = UnitPowerType("player")
        local p, pMax = UnitPower("player", pType), UnitPowerMax("player", pType)
        if IsSecret(p) or IsSecret(pMax) then return nil end
        if pMax > 0 then
            if DECAY_POWER[pType] then
                if p > 0 then return true end
            elseif p < pMax then
                return true
            end
        end
    end
    return false
end

-- Returns "disabled", "combat", "regen" or "idle".
local function GetState()
    if not db or not db.enabled then lastReason = L.r_disabled; return "disabled" end
    if InCombatLockdown() or UnitAffectingCombat("player") then
        lastReason = L.r_combat; return "combat"
    end
    if UnitIsDeadOrGhost("player") then lastReason = L.r_dead; return "idle" end

    local exact = ExactCheck()
    if exact ~= nil then
        lastReason = exact and L.r_partial or L.r_full
        return exact and "regen" or "idle"
    end

    local now = GetTime()
    if db.health and now < track.health.untilTime then
        lastReason = L.r_health; return "regen"
    end
    if db.power[PowerKey()] and now < track.power.untilTime then
        lastReason = string.format(L.r_power, L[PowerKey()]); return "regen"
    end
    lastReason = L.r_none
    return "idle"
end

local function TargetAlpha(state)
    if state == "combat" then return db.alphaCombat / 100 end
    if state == "regen" then return db.alphaRegen / 100 end
    if state == "idle" then return db.alphaIdle / 100 end
    return 1
end

-- Bar texts (values and percentages): every text inside the display except
-- the Edit Mode selection box.
local barTexts = {}

local function CollectTexts(frame)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            barTexts[#barTexts + 1] = region
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child ~= prd.Selection then CollectTexts(child) end
    end
end

local function ApplyText(state)
    wipe(barTexts)
    CollectTexts(prd)
    local alpha = 1
    if state ~= "disabled" and state ~= "combat" and db.textCombatOnly then
        alpha = 0
    end
    for _, fs in ipairs(barTexts) do
        if fs:GetAlpha() ~= alpha then fs:SetAlpha(alpha) end
    end
end

local function Apply()
    if not prd then return end
    local state = GetState()
    local alpha = TargetAlpha(state)
    if math.abs(prd:GetAlpha() - alpha) > 0.001 then
        applying = true
        prd:SetAlpha(alpha)
        applying = false
    end
    ApplyText(state)
end

---------------------------------------------------------------------------
-- Options UI (shared by the floating window and the game's Options page)
---------------------------------------------------------------------------
local panel

local function CreateCheck(parent, label, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetSize(26, 26)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        Apply()
    end)
    cb.Refresh = function(self) self:SetChecked(getter()) end
    return cb
end

local function CreateStepper(parent, label, y, getter, setter, minV, maxV, step, suffix)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", 18, y)
    text:SetText(label)

    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPLEFT", 200, y)
    value:SetJustifyH("CENTER")
    value:SetWidth(44)

    local function Refresh() value:SetText(getter() .. suffix) end

    local minus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minus:SetSize(24, 20)
    minus:SetPoint("RIGHT", value, "LEFT", -2, 0)
    minus:SetText("-")
    minus:SetScript("OnClick", function()
        setter(math.max(minV, getter() - step)); Refresh(); Apply()
    end)

    local plus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plus:SetSize(24, 20)
    plus:SetPoint("LEFT", value, "RIGHT", 2, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function()
        setter(math.min(maxV, getter() + step)); Refresh(); Apply()
    end)

    return Refresh
end

-- Help window
local HELP_COMMAND = "/dump select(4, GetBuildInfo())"
local helpFrame

local function ShowHelp()
    if not helpFrame then
        helpFrame = CreateFrame("Frame", "PRDVisibilityHelp", UIParent, "BasicFrameTemplateWithInset")
        helpFrame:SetWidth(400)
        helpFrame:SetPoint("CENTER")
        helpFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        helpFrame:SetMovable(true)
        helpFrame:EnableMouse(true)
        helpFrame:RegisterForDrag("LeftButton")
        helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
        helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
        tinsert(UISpecialFrames, "PRDVisibilityHelp")

        local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -6)
        title:SetText(L.helpTitle)

        local text = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 18, -36)
        text:SetWidth(364)
        text:SetJustifyH("LEFT")
        text:SetText(L.helpText)

        -- Box with the command, so it can be copied with Ctrl+C.
        local box = CreateFrame("EditBox", nil, helpFrame, "InputBoxTemplate")
        box:SetSize(300, 24)
        box:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 6, -14)
        box:SetAutoFocus(false)
        box:SetText(HELP_COMMAND)
        box:SetCursorPosition(0)
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(HELP_COMMAND); self:HighlightText() end
        end)
        box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        local copy = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        copy:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -6)
        copy:SetWidth(364)
        copy:SetJustifyH("LEFT")
        copy:SetText(L.helpCopy)

        local footer = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        footer:SetPoint("TOPLEFT", copy, "BOTTOMLEFT", 0, -16)
        footer:SetWidth(364)
        footer:SetJustifyH("LEFT")
        footer:SetText(L.helpFooter)

        helpFrame:SetHeight(36 + text:GetStringHeight() + 14 + 24 + 6
            + copy:GetStringHeight() + 16 + footer:GetStringHeight() + 24)
    end
    helpFrame:Show()
end

local function BuildControls(parent, y)
    local checks, refreshers = {}, {}

    checks[#checks + 1] = CreateCheck(parent, L.enabled, y,
        function() return db.enabled end, function(v) db.enabled = v end)
    y = y - 28
    checks[#checks + 1] = CreateCheck(parent, L.textCombat, y,
        function() return db.textCombatOnly end, function(v) db.textCombatOnly = v end)
    y = y - 36

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 18, y)
    header:SetText(L.showWhen)
    y = y - 22

    checks[#checks + 1] = CreateCheck(parent, L.health, y,
        function() return db.health end, function(v) db.health = v end)
    y = y - 28

    for _, key in ipairs({ "mana", "rage", "energy", "other" }) do
        checks[#checks + 1] = CreateCheck(parent, L[key], y,
            function() return db.power[key] end, function(v) db.power[key] = v end)
        y = y - 28
    end

    y = y - 10
    local opHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opHeader:SetPoint("TOPLEFT", 18, y)
    opHeader:SetText(L.opacity)
    y = y - 24

    refreshers[#refreshers + 1] = CreateStepper(parent, L.inCombat, y,
        function() return db.alphaCombat end, function(v) db.alphaCombat = v end, 0, 100, 10, "%")
    y = y - 26
    refreshers[#refreshers + 1] = CreateStepper(parent, L.regenerating, y,
        function() return db.alphaRegen end, function(v) db.alphaRegen = v end, 0, 100, 10, "%")
    y = y - 26
    refreshers[#refreshers + 1] = CreateStepper(parent, L.fullBars, y,
        function() return db.alphaIdle end, function(v) db.alphaIdle = v end, 0, 100, 10, "%")
    y = y - 36

    refreshers[#refreshers + 1] = CreateStepper(parent, L.maxDelay, y,
        function() return db.maxDelay end, function(v) db.maxDelay = v end, 2, 15, 1, " s")
    y = y - 40

    -- Language switch: takes effect after /reload.
    local langButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    langButton:SetSize(170, 24)
    langButton:SetPoint("TOPLEFT", 18, y)
    langButton:SetText(L.language)
    langButton:SetScript("OnClick", function()
        db.language = (db.language == "en") and "es" or "en"
        print(PREFIX .. LOCALES[db.language].langReload)
    end)

    local helpButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    helpButton:SetSize(86, 24)
    helpButton:SetPoint("LEFT", langButton, "RIGHT", 8, 0)
    helpButton:SetText(L.help)
    helpButton:SetScript("OnClick", ShowHelp)

    return function()
        for _, cb in ipairs(checks) do cb:Refresh() end
        for _, refresh in ipairs(refreshers) do refresh() end
    end
end

-- Floating window (/prdv)
local function CreatePanel()
    panel = CreateFrame("Frame", "PRDVisibilityPanel", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 520)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()
    tinsert(UISpecialFrames, "PRDVisibilityPanel") -- closes with Esc

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -6)
    title:SetText("PRD Visibility")

    panel:SetScript("OnShow", BuildControls(panel, -34))
end

local function TogglePanel()
    if not panel then CreatePanel() end
    panel:SetShown(not panel:IsShown())
end

-- Page in the game's Options > AddOns
local settingsCategory

local function RegisterOptionsPage()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local page = CreateFrame("Frame")
    page:Hide()

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("PRD Visibility")

    local subtitle = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText(L.subtitle)

    page:SetScript("OnShow", BuildControls(page, -64))

    settingsCategory = Settings.RegisterCanvasLayoutCategory(page, "PRD Visibility")
    Settings.RegisterAddOnCategory(settingsCategory)
end

local function OpenOptions()
    if settingsCategory and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory, settingsCategory:GetID())
        if ok then return end
    end
    TogglePanel()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")

local function InitDB()
    PRDVisibilityDB = PRDVisibilityDB or {}
    db = PRDVisibilityDB
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then
            if type(v) == "table" then
                db[k] = {}
                for k2, v2 in pairs(v) do db[k][k2] = v2 end
            else
                db[k] = v
            end
        end
    end
    for k2, v2 in pairs(DEFAULTS.power) do
        if db.power[k2] == nil then db.power[k2] = v2 end
    end
    L = LOCALES[db.language] or LOCALES.en
end

local function Attach()
    if prd then return true end
    prd = _G[FRAME_NAME]
    if not prd then return false end

    hooksecurefunc(prd, "SetAlpha", function()
        if not applying then Apply() end
    end)
    prd:HookScript("OnShow", Apply)

    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterUnitEvent("UNIT_HEALTH", "player")
    events:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    events:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

    C_Timer.NewTicker(0.25, Apply)

    print(PREFIX .. L.loaded)
    Apply()
    return true
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then InitDB() end
        if arg1 == BLIZZ_ADDON and db then Attach() end
        return
    elseif event == "PLAYER_LOGIN" then
        if not db then InitDB() end
        RegisterOptionsPage()
        if not Attach() then
            print(PREFIX .. string.format(L.waiting, BLIZZ_ADDON))
        end
        return
    end

    local now = GetTime()
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        MarkActivity(track.health)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
        MarkActivity(track.power)
    elseif event == "UNIT_DISPLAYPOWER" then
        -- Shapeshift: reset the resource rhythm.
        track.power.last = 0
        MarkActivity(track.power)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if PowerKey() == "mana" then
            track.power.untilTime = math.max(track.power.untilTime, now + MANA_PAUSE)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Short margin after combat: regeneration events will extend it;
        -- if the bars are already full, it hides soon.
        track.health.untilTime = math.max(track.health.untilTime, now + 2)
        track.power.untilTime = math.max(track.power.untilTime, now + 2)
    end
    Apply()
end)

---------------------------------------------------------------------------
-- Slash commands (English and Spanish)
---------------------------------------------------------------------------
local STATE_KEYS = { disabled = "st_disabled", combat = "st_combat", regen = "st_regen", idle = "st_idle" }

SLASH_PRDVISIBILITY1 = "/prdv"
SlashCmdList.PRDVISIBILITY = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "" then
        TogglePanel()
        return
    elseif msg == "options" or msg == "opciones" then
        OpenOptions()
        return
    elseif msg == "help" or msg == "ayuda" then
        ShowHelp()
        return
    end
    if not prd then
        print(PREFIX .. string.format(L.notFound, FRAME_NAME))
        return
    end
    if msg == "status" or msg == "estado" then
        local state = GetState()
        print(PREFIX .. string.format(L.status, L[STATE_KEYS[state]],
            math.floor(TargetAlpha(state) * 100 + 0.5), lastReason, L[PowerKey()]))
    elseif msg == "debug" then
        local now = GetTime()
        print(PREFIX .. string.format(L.debug,
            now - track.health.last, math.max(0, track.health.untilTime - now),
            now - track.power.last, math.max(0, track.power.untilTime - now)))
    else
        print(PREFIX .. L.commands)
    end
end
