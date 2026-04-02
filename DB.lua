-- GuildForge - DB.lua
-- Read / write member data in AgoraDB (SavedVariables)

local GC = Agora

-- Default structure for AgoraDB
local DB_DEFAULTS = {
    version      = 2,
    members      = {},    -- guild data (existing)
    settings     = {
        server_opt_in = false,   -- player chose to broadcast to server
        price_default = "",      -- "" | "tips" | copper amount as string
    },
    my_prices    = {},    -- [prof_name][recipe_name] = { price="", provides_mats=false }
    server_peers = {},    -- [key "Name-Realm"] = { data=..., last_heartbeat=timestamp }
}

function GC:InitDB()
    if not AgoraDB then AgoraDB = {} end
    -- Merge defaults without overwriting existing values
    if not AgoraDB.version  then AgoraDB.version  = DB_DEFAULTS.version  end
    if not AgoraDB.members  then AgoraDB.members  = {}                   end
    if not AgoraDB.settings then AgoraDB.settings = {}                   end
    if AgoraDB.settings.server_opt_in == nil then
        AgoraDB.settings.server_opt_in = DB_DEFAULTS.settings.server_opt_in
    end
    if AgoraDB.settings.price_default == nil then
        AgoraDB.settings.price_default = DB_DEFAULTS.settings.price_default
    end
    if not AgoraDB.my_prices    then AgoraDB.my_prices    = {} end
    if not AgoraDB.server_peers then AgoraDB.server_peers = {} end
end

function GC:GetServerOptIn()
    return AgoraDB and AgoraDB.settings and AgoraDB.settings.server_opt_in or false
end

function GC:SetServerOptIn(val)
    if not AgoraDB then return end
    AgoraDB.settings.server_opt_in = val == true
end

function GC:GetPriceDefault()
    return AgoraDB and AgoraDB.settings and AgoraDB.settings.price_default or ""
end

function GC:SetPriceDefault(val)
    if not AgoraDB then return end
    AgoraDB.settings.price_default = val or ""
end

-- price : "" | "tips" | montant en copper (string)
-- provides_mats : true | false
function GC:GetMyPrice(profName, recipeName)
    if not AgoraDB or not AgoraDB.my_prices then return { price = "", provides_mats = false } end
    local p = AgoraDB.my_prices[profName]
    if not p then return { price = "", provides_mats = false } end
    return p[recipeName] or { price = "", provides_mats = false }
end

function GC:SetMyPrice(profName, recipeName, price, provides_mats)
    if not AgoraDB then return end
    if not AgoraDB.my_prices[profName] then
        AgoraDB.my_prices[profName] = {}
    end
    AgoraDB.my_prices[profName][recipeName] = {
        price         = price or "",
        provides_mats = provides_mats == true,
    }
end

function GC:SavePeer(key, data)
    if not AgoraDB then return end
    AgoraDB.server_peers[key] = {
        data           = data,
        last_heartbeat = time(),
    }
end

function GC:RemovePeer(key)
    if not AgoraDB then return end
    AgoraDB.server_peers[key] = nil
end

function GC:GetPeers()
    if not AgoraDB then return {} end
    return AgoraDB.server_peers or {}
end

-- Retire les peers dont le heartbeat date de plus de 10 minutes (2 cycles manques)
function GC:PurgeStaleHeartbeats()
    if not AgoraDB or not AgoraDB.server_peers then return end
    local now = time()
    for key, peer in pairs(AgoraDB.server_peers) do
        if now - (peer.last_heartbeat or 0) > 600 then
            AgoraDB.server_peers[key] = nil
        end
    end
end

-- Save or update a member
function GC:SaveMember(data)
    if not data or not data.name or not data.realm then return end
    local key = data.name .. "-" .. data.realm
    AgoraDB.members[key] = data
end

-- Remove a member by key
function GC:RemoveMember(key)
    if AgoraDB and AgoraDB.members then
        AgoraDB.members[key] = nil
    end
end

-- Returns the set of base names currently in the guild (requires IsInGuild)
function GC:GetCurrentGuildSet()
    local set = {}
    if not IsInGuild() then return set end
    local numMembers = GetNumGuildMembers and GetNumGuildMembers() or 0
    for i = 1, numMembers do
        local name = (GetGuildRosterInfo(i))
        if name then
            local base = name:match("^([^%-]+)") or name
            set[base] = true
        end
    end
    return set
end

-- Returns only members of the current guild (filtered by WoW roster)
-- The current player is always included (to see their own recipes while out of guild)
function GC:GetAllMembers()
    if not AgoraDB then return {} end

    local myKey = GC:GetMyKey()

    if not IsInGuild() then
        -- Out of guild: only own data
        local result = {}
        if myKey and AgoraDB.members[myKey] then
            result[myKey] = AgoraDB.members[myKey]
        end
        return result
    end

    local roster = GC:GetCurrentGuildSet()
    -- If the roster is not yet loaded, return everything (avoids empty UI at boot)
    if next(roster) == nil then
        return AgoraDB.members or {}
    end

    local result = {}
    for key, data in pairs(AgoraDB.members or {}) do
        local base = key:match("^([^%-]+)") or key
        if roster[base] then
            result[key] = data
        end
    end
    -- Always include the current player even if the roster is partial
    if myKey and AgoraDB.members[myKey] then
        result[myKey] = AgoraDB.members[myKey]
    end
    return result
end

-- Returns members who have a given profession
function GC:GetMembersWithProfession(profName)
    local result = {}
    for key, member in pairs(GC:GetAllMembers()) do
        for _, prof in ipairs(member.professions or {}) do
            if prof.name == profName then
                table.insert(result, { key = key, member = member, prof = prof })
                break
            end
        end
    end
    -- Sort by profession level descending
    table.sort(result, function(a, b)
        return (a.prof.level or 0) > (b.prof.level or 0)
    end)
    return result
end

-- Returns the list of all professions present in the guild (no duplicates)
function GC:GetAllProfessions()
    local seen = {}
    local list = {}
    for _, member in pairs(GC:GetAllMembers()) do
        for _, prof in ipairs(member.professions or {}) do
            if not seen[prof.name] then
                seen[prof.name] = true
                table.insert(list, prof.name)
            end
        end
    end
    table.sort(list)
    return list
end

-- Purge members who are no longer in the guild
function GC:CleanupDepartedMembers()
    if not IsInGuild() or not AgoraDB then return end

    -- Build a set of current members (by base name)
    local current = {}
    local numMembers = GetNumGuildMembers and GetNumGuildMembers() or 0

    -- If the roster is not yet loaded (0 members), do nothing.
    -- Deleting everything on an empty roster would erase valid data.
    if numMembers == 0 then return end

    for i = 1, numMembers do
        local name = (GetGuildRosterInfo(i))
        if name then
            -- Strip the -Realm suffix if present (Cata+)
            local baseName = name:match("^([^%-]+)") or name
            current[baseName] = true
        end
    end

    -- Always keep the current player's data
    local myKey = GC:GetMyKey()
    if myKey then
        local myBase = myKey:match("^([^%-]+)") or myKey
        current[myBase] = true
    end

    -- Remove those who are no longer in the guild
    for key in pairs(AgoraDB.members) do
        local baseName = key:match("^([^%-]+)") or key
        if not current[baseName] then
            print("|cff00ccffAgora:|r " .. string.format(GC.L["DB_MemberLeft"], baseName))
            AgoraDB.members[key] = nil
        end
    end
end
