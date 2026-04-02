-- GuildForge - Broadcast.lua
-- Serialization, chunking, sending and receiving guild data

local GC = Agora

-- TBC Anniversary compatibility: SendAddonMessage is in C_ChatInfo
local SendAddonMsg = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage

local SEP        = "\001"   -- internal separator (ASCII 1, never in WoW names)
local CHUNK_SIZE = 200      -- max characters per addon message
local CHUNK_SEP  = "\002"   -- chunk header separator (ASCII 2)

GC.SERVER_CHANNEL = "Agora"

-- Incoming chunks being reassembled: { [senderKey] = { total, count, chunks={} } }
GC.incoming = {}

-- ─── Utility: split a string by a separator ───────────────────────

local function split(str, sep)
    local result = {}
    local pos = 1
    while pos <= #str do
        local found = str:find(sep, pos, true)
        if found then
            table.insert(result, str:sub(pos, found - 1))
            pos = found + #sep
        else
            table.insert(result, str:sub(pos))
            break
        end
    end
    return result
end

-- ─── Serialization ───────────────────────────────────────────────────────────

-- Converts a member's data into a transportable string
-- Format V2: V2|name|realm|class|timestamp|zone|price|provides_mats|PROF|...|REC|name|cd|reagents|...
function GC:Serialize(data)
    -- V2 : ajoute zone, price, provides_mats
    local p = {
        "V2",
        data.name,
        data.realm,
        data.class       or "",
        tostring(data.timestamp or 0),
        data.zone        or "",
        data.price       or "",      -- "" | "tips" | copper string
        data.provides_mats and "1" or "0",
    }

    for _, prof in ipairs(data.professions or {}) do
        table.insert(p, "PROF")
        table.insert(p, prof.name)
        table.insert(p, tostring(prof.level   or 0))
        table.insert(p, tostring(prof.maxLevel or 0))
        table.insert(p, prof.specialization or "")

        for _, recipe in ipairs(prof.recipes or {}) do
            table.insert(p, "REC")
            table.insert(p, recipe.name)
            table.insert(p, recipe.cd_available and "1" or "0")
            for _, reagent in ipairs(recipe.reagents or {}) do
                local rName = reagent.name:gsub("=", " ")
                table.insert(p, rName .. "=" .. tostring(reagent.count or 1))
            end
        end
    end

    return table.concat(p, SEP)
end

-- Reconstructs a member's data from a serialized string. Supports V1 and V2.
function GC:Deserialize(str)
    local parts = split(str, SEP)
    local version = parts[1]
    if version ~= "V1" and version ~= "V2" then return nil end

    local data = {
        name          = parts[2] or "",
        realm         = parts[3] or "",
        class         = parts[4] or "",
        timestamp     = tonumber(parts[5]) or 0,
        professions   = {},
    }

    local i
    if version == "V2" then
        data.zone          = parts[6] or ""
        data.price         = parts[7] or ""
        data.provides_mats = parts[8] == "1"
        i = 9
    else
        -- V1 compat
        data.zone          = ""
        data.price         = ""
        data.provides_mats = false
        i = 6
    end

    local currentProf   = nil
    local currentRecipe = nil

    while i <= #parts do
        local p = parts[i]

        if p == "PROF" then
            local spec = parts[i + 4]
            currentProf = {
                name           = parts[i + 1] or "",
                level          = tonumber(parts[i + 2]) or 0,
                maxLevel       = tonumber(parts[i + 3]) or 0,
                specialization = (spec and spec ~= "") and spec or nil,
                recipes        = {},
            }
            table.insert(data.professions, currentProf)
            currentRecipe = nil
            i = i + 5

        elseif p == "REC" then
            if currentProf then
                local recipeName = parts[i + 1] or ""
                local cdField    = (version == "V2") and parts[i + 2] or nil
                currentRecipe = {
                    name         = recipeName,
                    cd_available = cdField == "1",
                    reagents     = {},
                }
                table.insert(currentProf.recipes, currentRecipe)
            end
            i = i + (version == "V2" and 3 or 2)

        elseif p ~= "" then
            -- Reagent format: "name=quantity"
            if currentRecipe then
                local rName, rCount = p:match("^(.+)=(%d+)$")
                if rName and rCount then
                    table.insert(currentRecipe.reagents, { name = rName, count = tonumber(rCount) })
                end
            end
            i = i + 1

        else
            i = i + 1
        end
    end

    return data
end

-- ─── Sending ───────────────────────────────────────────────────────────────────

-- Splits a long payload into multiple addon messages of CHUNK_SIZE characters
-- Chunk format: "DATA<CHUNK_SEP>senderKey<CHUNK_SEP>idx<CHUNK_SEP>total<CHUNK_SEP>data"
-- channel : "GUILD" ou "CHANNEL" (canal serveur)
function GC:SendChunked(senderKey, payload, channel)
    channel = channel or "GUILD"
    local chunks = {}
    for i = 1, #payload, CHUNK_SIZE do
        table.insert(chunks, payload:sub(i, i + CHUNK_SIZE - 1))
    end

    local total = #chunks
    for idx, chunk in ipairs(chunks) do
        local msg = "DATA" .. CHUNK_SEP .. senderKey .. CHUNK_SEP
                 .. idx .. CHUNK_SEP .. total .. CHUNK_SEP .. chunk
        -- 0.05s delay between each chunk to avoid flooding
        GC:After((idx - 1) * 0.05, function()
            if channel == "CHANNEL" then
                SendAddonMsg(GC.PREFIX, msg, "CHANNEL", GC.SERVER_CHANNEL)
            else
                SendAddonMsg(GC.PREFIX, msg, "GUILD")
            end
        end)
    end
end

-- Broadcast own data to the guild and/or the server channel
function GC:SendMyData()
    if not AgoraDB then return end
    local myKey = GC:GetMyKey()
    local data  = AgoraDB.members[myKey]
    if not data then return end
    -- Do not broadcast if no profession scanned (avoids overwriting others' data)
    if not data.professions or #data.professions == 0 then return end

    -- Enrichir avec zone et settings du joueur
    data.zone          = GetRealZoneText and GetRealZoneText() or ""
    data.price         = GC:GetPriceDefault()
    data.provides_mats = false  -- per-recipe flag handled separately; global default is false

    -- Envoyer a la guilde
    if IsInGuild() then
        GC:SendChunked(myKey, GC:Serialize(data), "GUILD")
    end

    -- Envoyer au serveur si opt-in
    if GC:GetServerOptIn() then
        GC:SendChunked(myKey, GC:Serialize(data), "CHANNEL")
    end
end

-- Send a HELLO: "I am new, please send me everything you have"
function GC:SendHello()
    local myKey = GC:GetMyKey()
    local msg   = "HELLO" .. CHUNK_SEP .. myKey
    if IsInGuild() then
        SendAddonMsg(GC.PREFIX, msg, "GUILD")
    end
    if GC:GetServerOptIn() then
        SendAddonMsg(GC.PREFIX, msg, "CHANNEL", GC.SERVER_CHANNEL)
    end
end

-- Heartbeat : signal "je suis la", envoye toutes les 5 minutes par Core.lua
function GC:SendHeartbeat()
    local myKey = GC:GetMyKey()
    local msg   = "HEARTBEAT" .. CHUNK_SEP .. myKey
    if IsInGuild() then
        SendAddonMsg(GC.PREFIX, msg, "GUILD")
    end
    if GC:GetServerOptIn() then
        SendAddonMsg(GC.PREFIX, msg, "CHANNEL", GC.SERVER_CHANNEL)
    end
end

-- Remove : signale que le joueur part (logout, desactivation)
function GC:SendRemove()
    local myKey = GC:GetMyKey()
    local msg   = "REMOVE" .. CHUNK_SEP .. myKey
    if IsInGuild() then
        SendAddonMsg(GC.PREFIX, msg, "GUILD")
    end
    if GC:GetServerOptIn() then
        SendAddonMsg(GC.PREFIX, msg, "CHANNEL", GC.SERVER_CHANNEL)
    end
end

-- Broadcast own version string so guildmates can detect updates
function GC:SendVersion()
    if not IsInGuild() then return end
    SendAddonMsg(GC.PREFIX, "VERSION" .. CHUNK_SEP .. GC.VERSION_STRING, "GUILD")
end

-- Compare two semver strings ("1.2.3"). Returns 1 if a > b, -1 if a < b, 0 if equal.
local function compareVersions(a, b)
    local function parts(v)
        local t = {}
        for n in v:gmatch("%d+") do t[#t + 1] = tonumber(n) end
        return t
    end
    local pa, pb = parts(a), parts(b)
    for i = 1, math.max(#pa, #pb) do
        local va = pa[i] or 0
        local vb = pb[i] or 0
        if va > vb then return  1 end
        if va < vb then return -1 end
    end
    return 0
end

-- Send all stored data (response to a HELLO)
-- Random delay to prevent everyone from responding at the same time
function GC:SendFullGuildData()
    if not AgoraDB then return end
    local delay = math.random() * 3  -- 0-3s random
    local extra = 0
    for key, memberData in pairs(AgoraDB.members) do
        local k, d = key, memberData
        GC:After(delay + extra, function()
            GC:SendChunked(k, GC:Serialize(d))
        end)
        extra = extra + 0.5  -- 0.5s between each member
    end
end

-- ─── Reception / Receiving ───────────────────────────────────────────────────────────────

function GC:OnMessage(sender, message, channel)
    local parts = split(message, CHUNK_SEP)
    if #parts < 1 then return end

    local msgType = parts[1]

    -- A new member is requesting all guild data
    if msgType == "HELLO" then
        local requester = parts[2]
        -- Do not respond to self, and only respond on GUILD channel
        if requester ~= GC:GetMyKey() and channel == "GUILD" then
            GC:SendFullGuildData()
        end

    -- Receiving a member data chunk
    elseif msgType == "DATA" then
        local senderKey = parts[2]
        local idx       = tonumber(parts[3])
        local total     = tonumber(parts[4])
        local data      = parts[5]

        if not senderKey or not idx or not total or not data then return end

        -- Do not process own data
        if senderKey == GC:GetMyKey() then return end

        -- Accumulate chunks; record the origin channel on first chunk
        if not GC.incoming[senderKey] then
            GC.incoming[senderKey] = { total = total, count = 0, chunks = {}, channel = channel }
            -- Timeout: drop incomplete transfers after 60s to avoid memory leak
            GC:After(60, function()
                if GC.incoming[senderKey] then
                    GC.incoming[senderKey] = nil
                end
            end)
        end

        local inc = GC.incoming[senderKey]
        if not inc.chunks[idx] then
            inc.chunks[idx] = data
            inc.count = inc.count + 1
        end

        -- All chunks received: reassemble and save
        if inc.count >= inc.total then
            local full = ""
            for i = 1, inc.total do
                full = full .. (inc.chunks[i] or "")
            end
            local originChannel = inc.channel
            GC.incoming[senderKey] = nil

            local memberData = GC:Deserialize(full)
            if memberData and memberData.name ~= "" then
                if originChannel == "CHANNEL" then
                    -- Data from the server-wide channel: save as peer
                    GC:SavePeer(senderKey, memberData)
                    if GC.mainFrame and GC.mainFrame:IsShown() then
                        GC:RefreshUI()
                    end
                else
                    -- Data from the guild channel: save as guild member
                    local key = memberData.name .. "-" .. memberData.realm
                    local existing = AgoraDB.members[key]
                    if not existing or memberData.timestamp >= existing.timestamp then
                        AgoraDB.members[key] = memberData
                        print("|cff00ccffAgora:|r " .. string.format(GC.L["BROADCAST_DataReceived"], memberData.name))
                        if GC.mainFrame and GC.mainFrame:IsShown() then
                            GC:RefreshUI()
                        end
                    end
                end
            end
        end

    -- A member is broadcasting their addon version
    elseif msgType == "VERSION" then
        local theirVersion = parts[2]
        if theirVersion and not GC._newerVersionKnown then
            if compareVersions(theirVersion, GC.VERSION_STRING) > 0 then
                GC._newerVersionKnown = true
                GC._newerVersionSeen  = theirVersion
                print("|cff00ccffAgora:|r " .. string.format(
                    GC.L["CORE_NewVersion"], theirVersion))
                if GC.UpdateFooterVersion then GC:UpdateFooterVersion() end
            end
        end

    -- Heartbeat: update last_heartbeat for known peers
    elseif msgType == "HEARTBEAT" then
        local peerKey = parts[2]
        if peerKey and peerKey ~= GC:GetMyKey() then
            local peers = GC:GetPeers()
            local peer  = peers[peerKey]
            if peer then
                peer.last_heartbeat = time()
            end
        end

    -- A member is leaving; remove from peers (server) or members (guild)
    elseif msgType == "REMOVE" then
        local peerKey = parts[2]
        if peerKey then
            GC:RemovePeer(peerKey)
            if GC.mainFrame and GC.mainFrame:IsShown() then
                GC:RefreshUI()
            end
        end
    end
end
