-- GuildForge - Core.lua
-- Namespace, initialization, event management

GuildForge = GuildForge or {}  -- garde compat pendant transition
Agora = GuildForge              -- alias principal
-- NOTE: GuildForge alias must remain until all Locale files are updated from
-- "local L = GuildForge.L" to "local L = Agora.L". Do not remove.
local GC = Agora

-- Slash commands first, before any code that could crash
SLASH_AGORA1 = "/agora"
SLASH_AGORA2 = "/ag"
SlashCmdList["AGORA"] = function(msg)
    if GC.ToggleUI then
        local ok, err = pcall(function()
            if msg == "scan" then
                GC:ScanProfessionLevels()
                GC:SendMyData()
                print("|cff00ff00Agora:|r " .. (GC.L and GC.L["CORE_ScanDone"] or "Scan done."))
            elseif msg == "debug" then
                GC:ToggleDebug()
            else
                GC:ToggleUI()
            end
        end)
        if not ok then print("|cffff0000Agora:|r " .. tostring(err)) end
    end
end

GC.PREFIX         = "AGORA"
GC.VERSION        = 2
GC.VERSION_STRING = "1.0.0"
GC.devMode        = false

-- Locale string table. Populated by Locales/ files loaded after Core.lua.
-- Falls back to the key itself if a translation is missing.
GC.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

-- Timer without dependency on C_Timer (compatible TBC/Wrath/Cata)
function GC:After(delay, callback)
    local elapsed = 0
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end

-- Register addon prefix
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(GC.PREFIX)
elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(GC.PREFIX)
end

-- Main event frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
eventFrame:RegisterEvent("CRAFT_SHOW")
eventFrame:RegisterEvent("CRAFT_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or (event == "PLAYER_ENTERING_WORLD" and not GC._loginDone) then
        GC._loginDone = true
        GC:Log("[EVENT] " .. event .. " -> OnLogin")
        GC:OnLogin()

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        GC:OnAddonMessage(prefix, message, channel, sender)

    elseif event == "GUILD_ROSTER_UPDATE" then
        GC:OnRosterUpdate()

    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
        if event == "TRADE_SKILL_SHOW" then
            GC._currentTradeSkill = nil
        end

        local function TryResolveName()
            local nameNow = GetTradeSkillLine()
            if (not nameNow or nameNow == "UNKNOWN") and TradeSkillFrame then
                for _, region in pairs({ TradeSkillFrame:GetRegions() }) do
                    if region.GetText then
                        local t = region:GetText()
                        if t and t ~= "" then
                            if not nameNow or nameNow == "UNKNOWN" then
                                nameNow = t
                            end
                        end
                    end
                end
            end
            if nameNow and nameNow ~= "UNKNOWN" then
                local cleaned = nameNow:match("^([^%(]+)") or nameNow
                cleaned = cleaned:match("^%s*(.-)%s*$")
                GC._currentTradeSkill = cleaned
                GC:Log("[EVENT] currentTradeSkill = " .. cleaned)
            end
            return nameNow
        end

        local nameNow = TryResolveName()
        GC:Log("[EVENT] " .. event .. " - GetTradeSkillLine = " .. tostring(nameNow))

        GC:After(1.5, function()
            if not GC._currentTradeSkill then
                TryResolveName()
            end
            GC:ScanTradeSkillRecipes()
            if GetCraftLine then
                local cn = GetCraftLine()
                if cn and cn ~= "UNKNOWN" then
                    GC:ScanCraftRecipes()
                end
            end
        end)

    elseif event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
        GC:After(1.5, function()
            GC:ScanCraftRecipes()
        end)


    elseif event == "TRADE_SKILL_CLOSE" then
        if GC._initComplete and IsInGuild() then
            GC:After(0.3, function()
                GC:SendMyData()
            end)
        end

    elseif event == "PLAYER_LOGOUT" then
        GC:SendRemove()

    elseif event == "PLAYER_GUILD_UPDATE" then
        if IsInGuild() then
            if not GC._inGuild then
                GC._inGuild = true
                GC:Log("[EVENT] PLAYER_GUILD_UPDATE -> rejoint une guilde")
                GC:After(3, function()
                    GC:ScanProfessionLevels()
                    GC:SendHello()
                end)
                GC:After(5, function()
                    GC:SendMyData()
                    GC._initComplete = true
                end)
            end
        else
            GC._inGuild = false
            GC._initComplete = false
            GC:Log("[EVENT] PLAYER_GUILD_UPDATE -> quitte la guilde")
        end
    end
end)

-- Fallback init : OnUpdate guaranteed if PLAYER_LOGIN/PLAYER_ENTERING_WORLD do not fire
local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnUpdate", function(self)
    if not GC._loginDone and IsLoggedIn and IsLoggedIn() then
        GC._loginDone = true
        GC:Log("[INIT] OnUpdate fallback -> OnLogin")
        GC:OnLogin()
    end
    -- Disable as soon as init is done
    if GC._loginDone then
        self:SetScript("OnUpdate", nil)
    end
end)

-- Unique key for the current player: "Name-Realm"
function GC:GetMyKey()
    if not GC._myKey then
        local name  = UnitName("player") or "Unknown"
        local realm = GetRealmName and GetRealmName() or ""
        if realm == "" or realm == nil then realm = "Local" end
        GC._myKey = name .. "-" .. realm
    end
    return GC._myKey
end

function GC:OnLogin()
    GC:InitDB()

    -- Join the Agora server-wide channel (passive listening; opt-in required to broadcast)
    -- Two-step: join, then hide from all chat frames to avoid the "You have joined..." message
    GC:After(5, function()
        JoinChannelByName(GC.SERVER_CHANNEL)
        GC:After(0.5, function()
            local chanNum = GetChannelName(GC.SERVER_CHANNEL)
            if chanNum and chanNum > 0 then
                for i = 1, NUM_CHAT_WINDOWS or 7 do
                    local frame = _G["ChatFrame" .. i]
                    if frame then
                        pcall(function()
                            if frame.RemoveChannel then
                                frame:RemoveChannel(chanNum)
                            elseif ChatFrame_RemoveChannel then
                                ChatFrame_RemoveChannel(frame, chanNum)
                            end
                        end)
                    end
                end
            end
        end)
    end)

    -- Scan always runs, in guild or not
    GC:After(3, function()
        GC:ScanProfessionLevels()
        GC._initComplete = true

        -- Check if any recipes are already in the DB
        local myKey = GC:GetMyKey()
        local hasRecipes = false
        local member = AgoraDB and AgoraDB.members and AgoraDB.members[myKey]
        if member then
            for _, prof in ipairs(member.professions or {}) do
                if prof.recipes and #prof.recipes > 0 then hasRecipes = true; break end
            end
        end

        if IsInGuild() then
            GC._inGuild = true
            GC:SendHello()
            GC:SendVersion()
            if not hasRecipes then
                print("|cff00ccffAgora:|r " .. (GC.L and GC.L["CORE_OpenWindows"] or "Open your profession windows to share your recipes."))
            end
        end
    end)

    if IsInGuild() then
        GC._inGuild = true
        GC:After(5, function()
            GC:SendMyData()
            print("|cff00ccffAgora:|r " .. (GC.L and GC.L["CORE_RecipesUpdated"] or "Recipes synced with the guild."))
        end)
    end

    -- Heartbeat toutes les 5 minutes (300 secondes)
    local HEARTBEAT_INTERVAL = 300

    local ScheduleHeartbeat
    ScheduleHeartbeat = function()
        GC:After(HEARTBEAT_INTERVAL, function()
            if GC._initComplete then
                GC:SendHeartbeat()
                GC:PurgeStaleHeartbeats()
            end
            ScheduleHeartbeat()  -- re-schedule regardless
        end)
    end

    if not GC._heartbeatScheduled then
        GC._heartbeatScheduled = true
        ScheduleHeartbeat()
    end
end

-- Single entry point for addon messages (real or simulated)
function GC:OnAddonMessage(prefix, message, channel, sender)
    if prefix == GC.PREFIX then
        GC:OnMessage(sender, message, channel)
    end
end

function GC:OnRosterUpdate()
    if not AgoraDB then return end
    GC:CleanupDepartedMembers()
end
