-- GuildForge - UI.lua
-- Main interface: Recipes view (split panel)
-- Window 820x580, left panel = list, right panel = detail

local GC = Agora
local L  = Agora.L

-- General dimensions
local UI_W      = 820
local UI_H      = 580
local ROW_H     = 22
local LEFT_W    = 305
local TITLE_H   = 36
local VIEW_H    = 28
local TABS_H    = 40

-- WoW item quality colors
local QUALITY_COLOR = {
    [1] = "|cff9d9d9d",
    [2] = "|cff1eff00",
    [3] = "|cff0070dd",
    [4] = "|cffa335ee",
    [5] = "|cffff8000",
}

-- General UI colors
local C_GOLD    = "|cffffd700"
local C_GRAY    = "|cff888888"
local C_GREEN   = "|cff55dd55"
local C_ORANGE  = "|cffff9900"
local C_RESET   = "|r"
local C_EXPTAG  = "|cff6677aa"

-- WoW class colors
local CLASS_COLOR = {
    WARRIOR      = "|cffc79c6e",
    PALADIN      = "|cfff58cba",
    HUNTER       = "|cffabd473",
    ROGUE        = "|cfffff569",
    PRIEST       = "|cffffffff",
    DEATHKNIGHT  = "|cffc41f3b",
    SHAMAN       = "|cff0070de",
    MAGE         = "|cff69ccf0",
    WARLOCK      = "|cff9482c9",
    DRUID        = "|cffff7d0a",
}

-- Dimmed class colors (60% brightness) - members with no data
local CLASS_COLOR_DIM = {
    WARRIOR      = "|cff4a3828",
    PALADIN      = "|cff583343",
    HUNTER       = "|cff3d4c28",
    ROGUE        = "|cff5c5924",
    PRIEST       = "|cff666666",
    DEATHKNIGHT  = "|cff450b14",
    SHAMAN       = "|cff002a52",
    MAGE         = "|cff254858",
    WARLOCK      = "|cff352e48",
    DRUID        = "|cff5c2d03",
}

-- Profession display names per locale (canonical EN -> localized name)
local _loc = GetLocale and GetLocale() or "enUS"
local PROF_DISPLAY = {}
if _loc == "frFR" then
    PROF_DISPLAY = {
        Alchemy        = "Alchimie",
        Blacksmithing  = "Forge",
        Enchanting     = "Enchantement",
        Engineering    = "Ingénierie",
        Herbalism      = "Herboristerie",
        Jewelcrafting  = "Joaillerie",
        Leatherworking = "Travail du cuir",
        Mining         = "Minage",
        Skinning       = "Dépeçage",
        Tailoring      = "Couture",
        Cooking        = "Cuisine",
        ["First Aid"]  = "Secourisme",
        Fishing        = "Pêche",
        Inscription    = "Calligraphie",
    }
elseif _loc == "deDE" then
    PROF_DISPLAY = {
        Alchemy        = "Alchemie",
        Blacksmithing  = "Schmiedekunst",
        Enchanting     = "Verzauberkunst",
        Engineering    = "Ingenieurskunst",
        Herbalism      = "Kräuterkunde",
        Jewelcrafting  = "Juwelierskunst",
        Leatherworking = "Lederverarbeitung",
        Mining         = "Bergbau",
        Skinning       = "Kürschnerei",
        Tailoring      = "Schneiderei",
        Cooking        = "Kochkunst",
        ["First Aid"]  = "Erste Hilfe",
        Fishing        = "Angeln",
        Inscription    = "Inschriftenkunde",
    }
elseif _loc == "esES" or _loc == "esMX" then
    PROF_DISPLAY = {
        Alchemy        = "Alquimia",
        Blacksmithing  = "Herrería",
        Enchanting     = "Encantamiento",
        Engineering    = "Ingeniería",
        Herbalism      = "Herboristería",
        Jewelcrafting  = "Joyería",
        Leatherworking = "Peletería",
        Mining         = "Minería",
        Skinning       = "Desuello",
        Tailoring      = "Sastrería",
        Cooking        = "Cocina",
        ["First Aid"]  = "Primeros auxilios",
        Fishing        = "Pesca",
        Inscription    = "Inscripción",
    }
elseif _loc == "ptBR" then
    PROF_DISPLAY = {
        Alchemy        = "Alquimia",
        Blacksmithing  = "Ferraria",
        Enchanting     = "Encantamento",
        Engineering    = "Engenharia",
        Herbalism      = "Herbalismo",
        Jewelcrafting  = "Joalheria",
        Leatherworking = "Curtimento",
        Mining         = "Mineração",
        Skinning       = "Esfolamento",
        Tailoring      = "Alfaiataria",
        Cooking        = "Culinária",
        ["First Aid"]  = "Primeiros Socorros",
        Fishing        = "Pesca",
        Inscription    = "Inscrição",
    }
elseif _loc == "ruRU" then
    PROF_DISPLAY = {
        Alchemy        = "Алхимия",
        Blacksmithing  = "Кузнечное дело",
        Enchanting     = "Наложение чар",
        Engineering    = "Инженерное дело",
        Herbalism      = "Травничество",
        Jewelcrafting  = "Ювелирное дело",
        Leatherworking = "Кожевничество",
        Mining         = "Горное дело",
        Skinning       = "Снятие шкур",
        Tailoring      = "Портняжное дело",
        Cooking        = "Кулинария",
        ["First Aid"]  = "Первая помощь",
        Fishing        = "Рыбная ловля",
        Inscription    = "Начертание",
    }
end

-- Profession icons (native WoW textures)
local PROF_ICONS = {
    -- frFR
    ["Enchantement"]    = "Interface\\Icons\\Trade_Engraving",
    ["Forge"]           = "Interface\\Icons\\Trade_BlackSmithing",
    ["Alchimie"]        = "Interface\\Icons\\Trade_Alchemy",
    ["Travail du cuir"] = "Interface\\Icons\\Trade_LeatherWorking",
    ["Couture"]         = "Interface\\Icons\\Trade_Tailoring",
    ["Joaillerie"]      = "Interface\\Icons\\INV_Misc_Gem_01",
    ["Ingenierie"]      = "Interface\\Icons\\Trade_Engineering",
    ["Minage"]          = "Interface\\Icons\\Trade_Mining",
    ["Herboristerie"]   = "Interface\\Icons\\Trade_Herbalism",
    ["Depecage"]        = "Interface\\Icons\\Ability_SteelMelee",
    ["Cuisine"]         = "Interface\\Icons\\INV_Misc_Food_15",
    ["Secourisme"]      = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Peche"]           = "Interface\\Icons\\Trade_Fishing",
    -- enUS
    ["Enchanting"]      = "Interface\\Icons\\Trade_Engraving",
    ["Blacksmithing"]   = "Interface\\Icons\\Trade_BlackSmithing",
    ["Alchemy"]         = "Interface\\Icons\\Trade_Alchemy",
    ["Leatherworking"]  = "Interface\\Icons\\Trade_LeatherWorking",
    ["Tailoring"]       = "Interface\\Icons\\Trade_Tailoring",
    ["Jewelcrafting"]   = "Interface\\Icons\\INV_Misc_Gem_01",
    ["Engineering"]     = "Interface\\Icons\\Trade_Engineering",
    ["Mining"]          = "Interface\\Icons\\Trade_Mining",
    ["Herbalism"]       = "Interface\\Icons\\Trade_Herbalism",
    ["Skinning"]        = "Interface\\Icons\\Ability_SteelMelee",
    ["Cooking"]         = "Interface\\Icons\\INV_Misc_Food_15",
    ["First Aid"]       = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Fishing"]         = "Interface\\Icons\\Trade_Fishing",
}

-- Category filters per profession (keys in both frFR and enUS for robustness)
local PROF_FILTERS = {
    Enchanting        = {"Armes","Torse","Gants","Bottes","Poignets","Cape","Bouclier","Anneaux"},
    Enchantement      = {"Armes","Torse","Gants","Bottes","Poignets","Cape","Bouclier","Anneaux"},
    Alchemy           = {"Flasques","Potions","Elixirs","Transmutations","Huiles","Materiaux"},
    Alchimie          = {"Flasques","Potions","Elixirs","Transmutations","Huiles","Materiaux"},
    Blacksmithing     = {"Armes","Armes 2M","Armures","Bouclier","Materiaux"},
    Forge             = {"Armes","Armes 2M","Armures","Bouclier","Materiaux"},
    ["Leatherworking"]  = {"Casques","Torse","Gants","Bottes","Cape","Poignets","Armures","Sacs","Materiaux"},
    ["Travail du cuir"] = {"Casques","Torse","Gants","Bottes","Cape","Poignets","Armures","Sacs","Materiaux"},
    Tailoring           = {"Casques","Torse","Gants","Bottes","Cape","Poignets","Sacs","Textiles","Materiaux"},
    Couture             = {"Casques","Torse","Gants","Bottes","Cape","Poignets","Sacs","Textiles","Materiaux"},
    Jewelcrafting       = {"Gemmes","Bijoux","Figurines","Baguettes"},
    Joaillerie          = {"Gemmes","Bijoux","Figurines","Baguettes"},
    Engineering         = {"Casques","Explosifs","Gadgets","Armures","Materiaux"},
    Ingenierie          = {"Casques","Explosifs","Gadgets","Armures","Materiaux"},
    Cooking             = {"Cuisine"},
    Cuisine             = {"Cuisine"},
}

-- Wowhead URLs by expansion and locale
local WOWHEAD_EXP = {
    [1]="classic", [2]="tbc", [3]="wotlk", [4]="cata",
}
local WOWHEAD_LANG = {
    frFR="fr", deDE="de", esES="es", esMX="es",
    ptBR="pt", ruRU="ru", koKR="ko",
}


-- UI state
GC.viewMode       = "patrons"
GC.selectedProf   = nil
GC.selectedRecipe = nil
GC.filterCategory  = nil
GC.showGuildOnly   = false
GC.filterImportant = false
GC.currentSearch   = ""

-- ============================================================================
-- Helpers
-- ============================================================================

-- Builds the Wowhead base URL: https://www.wowhead.com/{exp}/{lang}/
local function WowheadBase(expansion)
    local exp    = WOWHEAD_EXP[expansion or GC.currentExpansion] or "tbc"
    local locale = GetLocale and GetLocale() or "enUS"
    local lang   = WOWHEAD_LANG[locale]
    if lang then
        return "https://www.wowhead.com/" .. exp .. "/" .. lang .. "/"
    else
        return "https://www.wowhead.com/" .. exp .. "/"
    end
end

local function GetSpellURL(entry)
    if not entry.spellID then return nil end
    local base = WowheadBase(entry.expansion)
    return base .. "spell=" .. entry.spellID
end

local function GetItemURL(entry)
    local base = WowheadBase(entry.expansion)
    -- Priority 1: static itemID from RecipeDB
    if entry.itemID then
        return base .. "item=" .. entry.itemID
    end
    -- Priority 2: WoW item link from scan (contains the ID)
    if entry.itemLink then
        local id = entry.itemLink:match("item:(%d+)")
        if id then return base .. "item=" .. id end
    end
    return nil
end

local function GetAHPrice(itemName)
    if not itemName then return nil end
    if AuctionatorPrices then
        local realmName = GetRealmName and GetRealmName() or ""
        local key = realmName .. " - " .. itemName
        local price = AuctionatorPrices[key]
        if price and price > 0 then return price end
        if AuctionatorPrices[itemName] then return AuctionatorPrices[itemName] end
    end
    return nil
end

local function HasAHAddon()
    -- On TBC Anniversary, the API may be in C_AddOns or global
    local function isLoaded(name)
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            if C_AddOns.IsAddOnLoaded(name) then return true end
        end
        if IsAddOnLoaded and IsAddOnLoaded(name) then return true end
        return false
    end

    if isLoaded("Auctionator")   then return true end
    if isLoaded("Auctioneer")    then return true end
    if isLoaded("Auc-Advanced")  then return true end
    if isLoaded("AucAdvanced")   then return true end
    if isLoaded("Auc_Advanced")  then return true end

    -- Fallback: check for global data tables
    if AuctionatorPrices then return true end
    if AucAdvanced       then return true end
    if Auctioneer        then return true end
    if AucCore           then return true end
    return false
end

local function GetItemQualityColor(quality)
    if not quality then return "" end
    -- ITEM_QUALITY_COLOR_CODES is a WoW global: "|cffXXXXXX" per quality level
    if ITEM_QUALITY_COLOR_CODES and ITEM_QUALITY_COLOR_CODES[quality] then
        return ITEM_QUALITY_COLOR_CODES[quality]
    end
    local t = {
        [0]="|cff9d9d9d", [1]="|cffffffff", [2]="|cff1eff00",
        [3]="|cff0070dd", [4]="|cffa335ee", [5]="|cffff8000",
    }
    return t[quality] or ""
end

local function FormatCopper(copper)
    if not copper or copper <= 0 then return nil end
    -- GetCoinTextureString is a Blizzard API that returns properly formatted
    -- money string with official coin icon textures embedded
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    -- Fallback: embed native coin icon textures manually
    local GOLD   = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t"
    local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t"
    local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t"
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then table.insert(parts, "|cffffd700" .. g .. "|r" .. GOLD) end
    if s > 0 then table.insert(parts, "|cffc0c0c0" .. s .. "|r" .. SILVER) end
    if c > 0 then table.insert(parts, "|cffb87333" .. c .. "|r" .. COPPER) end
    return #parts > 0 and table.concat(parts, " ") or nil
end

local function BuildOnlineCache()
    local cache = {}
    if not GetNumGuildMembers then return cache end
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, isOnline, _, classFile = GetGuildRosterInfo(i)
        if name then
            local short = name:match("^([^%-]+)") or name
            cache[short] = {
                online = isOnline == 1 or isOnline == true,
                class  = classFile or "WARRIOR",
            }
        end
    end
    return cache
end

-- Returns a human-readable relative duration string (e.g. "2d")
local function RelativeTime(timestamp)
    if not timestamp or timestamp == 0 then return nil end
    local diff = time() - timestamp
    if diff < 60 then
        return "< 1 min"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. " min"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h"
    else
        return math.floor(diff / 86400) .. " j"
    end
end

local STALE_THRESHOLD = 7 * 24 * 3600

-- Resolves the icon for an entry: guild scan > itemID > spellID > itemLink > name
local function ResolveIcon(entry)
    local icon = entry and entry.icon
    if not icon and entry.itemID and GetItemInfo then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(entry.itemID)
        icon = tex
    end
    if not icon and entry.spellID and GetSpellTexture then
        icon = GetSpellTexture(entry.spellID)
    end
    if not icon and entry.itemLink then
        local lid = entry.itemLink:match("item:(%d+)")
        if lid then
            local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(tonumber(lid))
            icon = tex
        end
    end
    if not icon and entry.name and GetItemInfo then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(entry.name)
        icon = tex
    end
    return icon
end

-- Hides GameTooltip and comparison tooltips
local function HideTooltip()
    GameTooltip:Hide()
    if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
    if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
end

-- Shows the tooltip for an entry (recipe spell first, item as fallback) anchored to a frame
local function ShowEntryTooltip(anchor, entry)
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    if entry.spellID then
        local sl = "|cff71d5ff|Hspell:" .. entry.spellID
                .. "|h[" .. (entry.name or "") .. "]|h|r"
        GameTooltip:SetHyperlink(sl)
        GameTooltip:Show()
    elseif entry.itemLink then
        GameTooltip:SetHyperlink(entry.itemLink)
        GameTooltip:Show()
        if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem() end
    elseif entry.itemID then
        GameTooltip:SetHyperlink("item:" .. entry.itemID)
        GameTooltip:Show()
        if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem() end
    elseif entry.name then
        GameTooltip:SetText(entry.name)
        GameTooltip:Show()
    end
end

local function GetMemberFreshness(member)
    -- "fresh" = in DB with timestamp < 7 days
    -- "stale" = in DB but > 7 days old
    -- "none"  = not in DB
    if not member then return "none" end
    local ts = member.timestamp or 0
    if ts == 0 then return "stale" end
    if (time() - ts) > STALE_THRESHOLD then return "stale" end
    return "fresh"
end

-- ============================================================================
-- Row pool (left panel)
-- ============================================================================

local rowPool    = {}
local activeRows = 0

-- Reagent row pool (below each recipe in the left panel)
local reagRowPool    = {}
local activeReagRows = 0
local MAX_REAG_ICONS = 8

local function ClearRows()
    for _, row in ipairs(rowPool)    do row:Hide() end
    for _, row in ipairs(reagRowPool) do row:Hide() end
    activeRows     = 0
    activeReagRows = 0
end

local function GetReagentRow(parent, y)
    activeReagRows = activeReagRows + 1
    if not reagRowPool[activeReagRows] then
        local f = CreateFrame("Frame", nil, parent)
        f:SetHeight(18)
        f.icons = {}
        for _ = 1, MAX_REAG_ICONS do
            local ic = CreateFrame("Frame", nil, f)
            ic:SetSize(14, 14)
            ic:EnableMouse(true)
            local tex = ic:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            ic.tex = tex
            local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", ic, "RIGHT", 1, 0)
            lbl:SetTextColor(0.8, 0.8, 0.8)
            ic.lbl = lbl
            ic:Hide()
            table.insert(f.icons, ic)
        end
        reagRowPool[activeReagRows] = f
    end
    local row = reagRowPool[activeReagRows]
    row:SetParent(parent)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, y)
    row:SetPoint("RIGHT",   parent, "RIGHT",   0, 0)
    for _, ic in ipairs(row.icons) do
        ic:SetScript("OnEnter", nil)
        ic:SetScript("OnLeave", nil)
        ic:Hide()
    end
    row:Show()
    return row
end

local function GetRow(parent, y, indent, w)
    activeRows = activeRows + 1
    if not rowPool[activeRows] then
        local btn = CreateFrame("Button", nil, parent)
        btn:SetHeight(ROW_H)
        btn:EnableMouse(true)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
        local hl = btn:GetHighlightTexture()
        if hl then hl:SetVertexColor(0.7, 0.6, 0.15) end

        local lfs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lfs:SetJustifyH("LEFT")
        if lfs.SetWordWrap    then lfs:SetWordWrap(false)    end
        if lfs.SetNonSpaceWrap then lfs:SetNonSpaceWrap(false) end
        btn.lfs = lfs

        local rfs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rfs:SetJustifyH("RIGHT")
        rfs:SetWidth(56)
        btn.rfs = rfs

        -- Background texture (for header rows; hidden by default)
        local bgTex = btn:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        bgTex:Hide()
        btn.bgTex = bgTex

        -- Icon texture (shown for header rows with prof icon, or known recipes)
        local ic = btn:CreateTexture(nil, "ARTWORK")
        ic:SetSize(16, 16)
        ic:SetPoint("LEFT", btn, "LEFT", 2, 0)
        ic:Hide()
        btn.ic = ic

        rowPool[activeRows] = btn
    end

    local row = rowPool[activeRows]
    row:SetParent(parent)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", indent or 0, y)
    row:SetPoint("RIGHT",   parent, "RIGHT",   0, 0)
    row.lfs:ClearAllPoints()
    row.lfs:SetPoint("LEFT",  row, "LEFT", 4, 0)
    row.lfs:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    row.rfs:ClearAllPoints()
    row.rfs:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.lfs:SetText("")
    row.rfs:SetText("")
    row.bgTex:Hide()
    row.ic:Hide()
    row._onClick = nil
    row:SetScript("OnClick",  nil)
    row:SetScript("OnEnter",  nil)
    row:SetScript("OnLeave",  nil)
    row:Show()
    return row
end

-- ============================================================================
-- BuildPatronMap
-- ============================================================================

local function BuildPatronMap(profFilter, catFilter, search, guildOnly)
    local curExp  = GC.currentExpansion or 2
    local prevExp = curExp - 1

    -- Index of recipes known by the guild
    -- Key is profession name lowercased to handle accent differences (e.g. Ingenierie vs Ingénierie)
    local guildKnown = {}
    -- Mapping table: profName:lower() -> original profName (for fallback display)
    local profNameByLower = {}
    for _, member in pairs(GC:GetAllMembers()) do
        for _, prof in ipairs(member.professions or {}) do
            local lprof = prof.name:lower()
            if not guildKnown[lprof] then guildKnown[lprof] = {} end
            profNameByLower[lprof] = prof.name
            for _, recipe in ipairs(prof.recipes or {}) do
                local lname = recipe.name:lower()
                if not guildKnown[lprof][lname] then
                    guildKnown[lprof][lname] = {
                        crafters = {},
                        reagents = recipe.reagents,
                        icon     = recipe.icon,
                        itemLink = recipe.itemLink,
                        minSkill = recipe.minSkill,
                    }
                end
                table.insert(guildKnown[lprof][lname].crafters, member.name)
            end
        end
    end

    local map     = {}
    local order   = {}
    local dbShown = {}
    -- All recipes present in RecipeDB (across all expansions).
    -- Used to block the fallback "guild known but not in DB" path for recipes
    -- that exist in the DB but are filtered out by expansion.
    local inDB    = {}

    local function ensureProf(pName)
        if not map[pName] then
            map[pName]    = {}
            dbShown[pName] = {}
            table.insert(order, pName)
        end
    end

    -- From RecipeDB
    for _, entry in ipairs(GC.RecipeDB or {}) do
        -- Resolve name: static > GetSpellInfo(spellID) > GetItemInfo(itemID)
        local entryName = entry.name
        if not entryName and entry.spellID and GetSpellInfo then
            entryName = GetSpellInfo(entry.spellID)
        end
        if not entryName and entry.itemID and GetItemInfo then
            entryName = (GetItemInfo(entry.itemID))
        end
        if not entryName then entryName = "???" end

        -- Mark in inDB (lowercase key)
        if not inDB[entry.prof] then inDB[entry.prof] = {} end
        inDB[entry.prof][entryName:lower()] = true

        local expOk    = (entry.expansion == curExp)
                      or (GC.showPrevExp and entry.expansion == prevExp)
        local profOk   = (not profFilter) or (entry.prof == profFilter)
        local catOk    = (not catFilter)  or (entry.category == catFilter)
        local searchOk = (search == "")   or entryName:lower():find(search, 1, true)
        local gk          = guildKnown[entry.prof:lower()] and guildKnown[entry.prof:lower()][entryName:lower()]
        local knownOk     = (not guildOnly) or (gk ~= nil)
        local importantOk = (not GC.filterImportant) or (entry.important == true)

        if expOk and profOk and catOk and searchOk and knownOk and importantOk then
            ensureProf(entry.prof)

            local entryIcon = ResolveIcon({ icon=gk and gk.icon, itemID=entry.itemID, spellID=entry.spellID })

            -- Quality and ilvl from itemID if available
            local entryQuality = entry.quality or 2
            local entryIlvl    = 0
            if entry.itemID and GetItemInfo then
                local _, _, q, ilvl = GetItemInfo(entry.itemID)
                if q    and q    > 0 then entryQuality = q    end
                if ilvl and ilvl > 0 then entryIlvl    = ilvl end
            end

            table.insert(map[entry.prof], {
                name      = entryName,
                prof      = entry.prof,
                expansion = entry.expansion,
                quality   = entryQuality,
                ilvl      = entryIlvl,
                category  = entry.category,
                spellID   = entry.spellID,
                itemID    = entry.itemID,
                reagents  = (gk and gk.reagents and #gk.reagents > 0) and gk.reagents or entry.reagents,
                crafters  = gk and gk.crafters,
                known     = gk ~= nil,
                icon      = entryIcon,
                itemLink  = gk and gk.itemLink,
                minSkill  = (gk and gk.minSkill) or entry.minSkill,
                important = entry.important,
            })
            dbShown[entry.prof][entryName:lower()] = true
        end
    end

    -- Guild recipes not in DB (not filtered by category/quality)
    -- Excludes recipes present in RecipeDB regardless of expansion
    -- (otherwise a filtered Vanilla recipe would surface here without an expansion tag)
    if not catFilter then
        for lprof, recipes in pairs(guildKnown) do
            -- profName: original name (with possible accents), lprof: lowercase version
            local profName = profNameByLower[lprof] or lprof
            local profOk = (not profFilter) or (lprof == profFilter:lower())
            if profOk then
                for recipeName, data in pairs(recipes) do
                    local lname = recipeName:lower()
                    -- Check in inDB using the lowercase profession key from RecipeDB
                    local alreadyInDB = false
                    for dbProf, dbRecipes in pairs(inDB) do
                        if dbProf:lower() == lprof and dbRecipes[lname] then
                            alreadyInDB = true; break
                        end
                    end
                    -- Check in dbShown the same way
                    local alreadyShown = false
                    for dbProf, dbRecipes in pairs(dbShown) do
                        if dbProf:lower() == lprof and dbRecipes[lname] then
                            alreadyShown = true; break
                        end
                    end
                    if not alreadyInDB and not alreadyShown then
                        local searchOk = (search == "")
                                      or recipeName:lower():find(search, 1, true)
                        if searchOk then
                            ensureProf(profName)
                            table.insert(map[profName], {
                                name      = recipeName,
                                prof      = profName,
                                expansion = nil,
                                quality   = 2,
                                category  = nil,
                                spellID   = nil,
                                reagents  = data.reagents,
                                crafters  = data.crafters,
                                known     = true,
                                icon      = data.icon,
                                itemLink  = data.itemLink,
                                minSkill  = data.minSkill,
                            })
                        end
                    end
                end
            end
        end
    end

    -- Sort: important first, then minSkill descending, then alphabetical
    for _, pName in ipairs(order) do
        table.sort(map[pName], function(a, b)
            if (a.important == true) ~= (b.important == true) then
                return a.important == true
            end
            local sa = a.minSkill or 0
            local sb = b.minSkill or 0
            if sa ~= sb then return sa > sb end
            return (a.name or "") < (b.name or "")
        end)
    end

    table.sort(order)
    return map, order
end

-- ============================================================================
-- Detail panel (right) - pre-created widgets
-- ============================================================================

local MAX_REAGENTS = 8
local MAX_CRAFTERS = 8

local function MakeUrlBox(parent)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetFontObject(ChatFontNormal)
    box:SetHeight(20)
    box:SetAutoFocus(false)
    box:SetMaxLetters(300)
    box:EnableMouse(true)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.45)
    local border = box:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     box, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT",  1, -1)
    border:SetColorTexture(0.4, 0.32, 0.08, 0.5)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnMouseDown",       function(self) self:SetFocus() self:HighlightText() end)
    box:SetScript("OnEnterPressed",    function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed",   function(self) self:ClearFocus() end)
    return box
end

local function CreateDetailPanel(parent, x, y, w, h)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    panel:SetSize(w, h)

    -- Background panel droit
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.015, 0.005, 0.6)

    -- Empty state icon (shown alongside hint)
    local emptyIcon = panel:CreateTexture(nil, "ARTWORK")
    emptyIcon:SetSize(52, 52)
    emptyIcon:SetTexture("Interface\\AddOns\\GuildForge\\GuildForge_icon")
    emptyIcon:SetPoint("CENTER", panel, "CENTER", 0, 30)
    emptyIcon:SetAlpha(0.25)
    emptyIcon:Hide()
    panel.emptyIcon = emptyIcon

    -- Hint shown when nothing is selected
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("CENTER", panel, "CENTER", 0, -36)
    hint:SetJustifyH("CENTER")
    hint:SetWidth(220)
    hint:SetTextColor(0.45, 0.4, 0.3)
    panel.hint = hint

    -- TOP SECTION: icon + name + URLs
    local TOP_H = 122  -- height reserved for the top section

    -- Top section background
    local topBg = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
    topBg:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, 0)
    topBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    topBg:SetHeight(TOP_H)
    topBg:SetColorTexture(0.06, 0.035, 0.01, 0.6)
    panel.topBg = topBg

    -- Icon (52x52)
    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(52, 52)
    icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    panel.detailIcon = icon

    panel.detailIconBorder = nil  -- no glow

    -- Invisible frame over the icon to capture hover events (Texture has no OnEnter)
    local iconHit = CreateFrame("Frame", nil, panel)
    iconHit:SetAllPoints(icon)
    iconHit:EnableMouse(true)
    panel.detailIconHit = iconHit

    -- Nom (GameFontNormalLarge)
    local nameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetPoint("TOPLEFT",  panel, "TOPLEFT", 70, -12)
    nameLabel:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -12)
    panel.detailName = nameLabel

    -- Tag expansion
    local expTag = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expTag:SetJustifyH("LEFT")
    expTag:SetPoint("TOPLEFT", panel, "TOPLEFT", 70, -32)
    panel.detailExpTag = expTag

    -- Required skill level (e.g. "Recipe 375"), on its own line
    local skillTag = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    skillTag:SetJustifyH("LEFT")
    skillTag:SetPoint("TOPLEFT", panel, "TOPLEFT", 70, -42)
    skillTag:SetTextColor(0.6, 0.6, 0.6)
    panel.detailSkillTag = skillTag

    -- Spell description (right column, below title and expansion tag)
    local descLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetJustifyH("LEFT")
    descLabel:SetPoint("TOPLEFT",  panel, "TOPLEFT",  70, -48)
    descLabel:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -48)
    descLabel:SetWordWrap(true)
    descLabel:SetMaxLines(3)
    descLabel:SetTextColor(0.75, 0.7, 0.55)
    panel.detailDesc = descLabel

    -- Wowhead URL fields: label + clickable FontString
    -- Click opens a popup EditBox to select/copy the URL
    local function MakeUrlField(panelParent, labelText)
        local row = CreateFrame("Button", nil, panelParent)
        row:SetHeight(20)
        row:EnableMouse(true)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetText(C_GRAY .. labelText .. C_RESET)
        lbl:SetJustifyH("LEFT")
        lbl:SetWidth(80)
        lbl:SetPoint("LEFT", row, "LEFT", 0, 0)

        local urlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        urlText:SetJustifyH("LEFT")
        urlText:SetPoint("LEFT",  row, "LEFT",  84, 0)
        urlText:SetPoint("RIGHT", row, "RIGHT",  0, 0)
        urlText:SetTextColor(0.4, 0.65, 1, 1)

        -- Popup EditBox (created once per panel)
        if not panel._urlPopup then
            local pop = CreateFrame("Frame", nil, panel, BackdropTemplateMixin and "BackdropTemplate" or nil)
            pop:SetSize(460, 36)
            pop:SetFrameStrata("TOOLTIP")
            if pop.SetBackdrop then
                pop:SetBackdrop({
                    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    tile=true, tileSize=16, edgeSize=16,
                    insets={left=4,right=4,top=4,bottom=4},
                })
                pop:SetBackdropColor(0, 0, 0, 0.95)
            end
            local peb = CreateFrame("EditBox", nil, pop)
            peb:SetPoint("TOPLEFT",     pop, "TOPLEFT",      8, -8)
            peb:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -8,  8)
            peb:SetFontObject(ChatFontNormal)
            peb:SetAutoFocus(true)
            peb:SetMaxLetters(512)
            peb:SetScript("OnEscapePressed",   function(s) s:ClearFocus(); pop:Hide() end)
            peb:SetScript("OnEnterPressed",    function(s) s:ClearFocus(); pop:Hide() end)
            peb:SetScript("OnEditFocusGained", function(s) s:HighlightText() end)
            pop.eb = peb
            pop:Hide()
            panel._urlPopup = pop

            -- Close the popup when clicking elsewhere on the panel
            panel:EnableMouse(true)
            panel:SetScript("OnMouseDown", function()
                if pop:IsShown() then
                    pop.eb:ClearFocus()
                    pop:Hide()
                end
            end)
        end

        row._urlText = urlText
        row._url     = nil
        row:SetScript("OnClick", function()
            if not row._url then return end
            local pop = panel._urlPopup
            pop.eb:SetText(row._url)
            pop:ClearAllPoints()
            pop:SetPoint("BOTTOM", row, "TOP", 0, 4)
            pop:Show()
            pop.eb:SetFocus()
            pop.eb:HighlightText()
        end)

        -- Interface compatible with calling code (SetText / SetTextColor)
        row.editBox      = row
        row.SetText      = function(_, url)
            row._url = url
            urlText:SetText(url or "")
        end
        row.SetTextColor = function() end

        row:Hide()
        return row
    end

    -- Global container (Y positioned dynamically in ShowRecipeDetail)
    local urlRow = CreateFrame("Frame", nil, panel)
    panel.detailUrlRow = urlRow

    local urlField1 = MakeUrlField(urlRow, "Recette :")
    urlField1:SetPoint("TOPLEFT",  urlRow, "TOPLEFT",  0, 0)
    urlField1:SetPoint("TOPRIGHT", urlRow, "TOPRIGHT", 0, 0)
    panel.detailUrlField1 = urlField1
    panel.detailUrlBtn1   = urlField1.editBox
    panel.detailUrlLabel1 = urlField1.editBox
    panel.detailUrlBox1   = urlField1.editBox

    local urlField2 = MakeUrlField(urlRow, "Objet :")
    panel.detailUrlField2 = urlField2
    panel.detailUrlBtn2   = urlField2.editBox
    panel.detailUrlLabel2 = urlField2.editBox
    panel.detailUrlBox2   = urlField2.editBox

    -- Horizontal separator below the top section
    local sep1 = panel:CreateTexture(nil, "BORDER")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, -TOP_H)
    sep1:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -TOP_H)
    sep1:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    sep1:SetVertexColor(0.55, 0.42, 0.1, 0.7)
    panel.detailSep1 = sep1

    -- BOTTOM SECTION : Composants | Artisans

    -- == Reagents (full width, dynamic height) ==
    local reagSection = CreateFrame("Frame", nil, panel)
    reagSection:SetPoint("TOPLEFT",  panel, "TOPLEFT",  4, -(TOP_H + 5))
    reagSection:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -(TOP_H + 5))
    panel.reagSection = reagSection

    local reagBg = reagSection:CreateTexture(nil, "BACKGROUND", nil, 1)
    reagBg:SetAllPoints()
    reagBg:SetColorTexture(0.06, 0.035, 0.01, 0.55)

    local reagLabel = reagSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reagLabel:SetJustifyH("LEFT")
    reagLabel:SetPoint("TOPLEFT", reagSection, "TOPLEFT", 10, -8)
    panel.detailReagentsLabel = reagLabel

    panel.detailReagents = {}
    for i = 1, MAX_REAGENTS do
        local row = CreateFrame("Frame", nil, reagSection)
        row:SetHeight(20)
        row:EnableMouse(true)
        row:SetPoint("TOPLEFT",  reagSection, "TOPLEFT",   8, -(8 + 18 + (i-1)*20))
        row:SetPoint("TOPRIGHT", reagSection, "TOPRIGHT", -8, -(8 + 18 + (i-1)*20))

        -- Icon (vertically centered in the row)
        local ic = row:CreateTexture(nil, "ARTWORK")
        ic:SetSize(16, 16)
        ic:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon = ic

        -- Quantity: fixed right-aligned column (e.g. "  1x", "  6x", "10x")
        local qty = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        qty:SetJustifyH("RIGHT")
        qty:SetWidth(28)
        qty:SetPoint("LEFT", ic, "RIGHT", 2, 0)
        qty:SetTextColor(0.9, 0.9, 0.9)
        row.qty = qty

        -- Item name (starts after the quantity column)
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetJustifyH("LEFT")
        lbl:SetPoint("LEFT",  qty, "RIGHT", 4, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.label = lbl

        -- AH price (hidden if no AH addon is loaded)
        local price = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        price:SetJustifyH("RIGHT")
        price:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        price:SetTextColor(0.7, 0.7, 0.7)
        row.price = price

        panel.detailReagents[i] = row
    end

    panel.detailAHHint = nil  -- hint AH supprime

    -- == Crafters (full width, below reagents) ==
    local craftersSection = CreateFrame("Frame", nil, panel)
    panel.craftersSection = craftersSection

    local craftersBg = craftersSection:CreateTexture(nil, "BACKGROUND", nil, 1)
    craftersBg:SetAllPoints()
    craftersBg:SetColorTexture(0.04, 0.02, 0.06, 0.55)

    -- Main label (number of crafters or "Nobody knows this recipe")
    local craftersLabel = craftersSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    craftersLabel:SetJustifyH("LEFT")
    craftersLabel:SetPoint("TOPLEFT", craftersSection, "TOPLEFT", 10, -8)
    panel.detailCraftersLabel = craftersLabel

    -- Online column (right side)
    local onlineLbl = craftersSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    onlineLbl:SetPoint("TOPRIGHT", craftersSection, "TOPRIGHT", -10, -8)
    onlineLbl:SetText("|cffaaaaaa" .. "Online" .. "|r")
    panel.detailOnlineLbl = onlineLbl

    -- "Can learn it" label (shown when nobody knows the recipe)
    local candidatesLabel = craftersSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    candidatesLabel:SetJustifyH("LEFT")
    candidatesLabel:Hide()
    panel.detailCandidatesLabel = candidatesLabel

    panel.detailCrafters = {}
    for i = 1, MAX_CRAFTERS do
        local row = CreateFrame("Frame", nil, craftersSection)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT",  craftersSection, "TOPLEFT",  10, -(8 + 16 + (i-1)*24))
        row:SetPoint("TOPRIGHT", craftersSection, "TOPRIGHT", -10, -(8 + 16 + (i-1)*24))

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetJustifyH("LEFT")
        name:SetPoint("LEFT",  row, "LEFT",  0,  0)
        name:SetPoint("RIGHT", row, "RIGHT", -18, 0)
        row.name = name

        local dot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dot:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        dot:SetWidth(14)
        dot:SetJustifyH("RIGHT")
        row.dot = dot

        local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        btn:SetSize(66, 16)
        btn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        btn:SetText(L["UI_Whisper"] or "Whisper")
        btn:Hide()
        row.whisperBtn = btn

        panel.detailCrafters[i] = row
    end

    panel:Hide()
    return panel
end

-- Updates the recipe detail panel
local function ShowRecipeDetail(panel, entry, onlineCache)
    panel:Show()
    panel.hint:Hide()
    if panel.emptyIcon then panel.emptyIcon:Hide() end
    panel.topBg:Show()
    panel.detailIcon:Show()
    if panel.detailIconHit then panel.detailIconHit:Show() end
    panel.detailName:Show()
    panel.detailExpTag:Show()
    panel.detailDesc:Show()
    panel.detailSep1:Show()
    panel.detailReagentsLabel:Show()
    panel.detailCraftersLabel:Show()
    panel.detailOnlineLbl:Show()
    panel.reagSection:Show()
    panel.craftersSection:Show()

    panel.detailIcon:SetTexture(ResolveIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")

    if panel.detailIconHit then
        local capturedForIcon = entry
        panel.detailIconHit:SetScript("OnEnter", function(self)
            ShowEntryTooltip(self, capturedForIcon)
        end)
        panel.detailIconHit:SetScript("OnLeave", HideTooltip)
        panel.detailIconHit:SetScript("OnMouseDown", function()
            if IsShiftKeyDown() then
                local link = capturedForIcon.itemLink
                if not link and capturedForIcon.spellID then
                    link = "|cff71d5ff|Hspell:"..capturedForIcon.spellID.."|h["..(capturedForIcon.name or "").."]|h|r"
                end
                if link and ChatEdit_InsertLink then
                    if not ChatEdit_InsertLink(link) then
                        ChatFrame_OpenChat(link, DEFAULT_CHAT_FRAME)
                    end
                end
            end
        end)
    end

    -- Name: entry.name (resolved in BuildPatronMap from GetSpellInfo/GetItemInfo)
    -- Quality: from itemID if available
    local displayQuality = entry.quality or 2
    if entry.itemID and GetItemInfo then
        local _, _, q = GetItemInfo(entry.itemID)
        if q and q > 0 then displayQuality = q end
    end
    local qc = QUALITY_COLOR[displayQuality] or QUALITY_COLOR[2]
    panel.detailName:SetText(qc .. (entry.name or "") .. C_RESET)

    -- Tag expansion
    local curExp = GC.currentExpansion or 2
    if entry.expansion and entry.expansion < curExp then
        local short = GC.EXP_SHORT and GC.EXP_SHORT[entry.expansion] or "?"
        panel.detailExpTag:SetText(C_EXPTAG .. "[" .. short .. "]" .. C_RESET)
    else
        panel.detailExpTag:SetText("")
    end

    if panel.detailSkillTag then
        if entry.minSkill and entry.minSkill > 0 then
            local label = L["UI_SkillReq"] or "Recipe"
            panel.detailSkillTag:SetText(label .. " " .. entry.minSkill)
            panel.detailSkillTag:Show()
        else
            panel.detailSkillTag:Hide()
        end
    end

    -- Wowhead URL fields: always below title/expTag
    local spellURL = GetSpellURL(entry)
    local itemURL  = GetItemURL(entry)

    -- URL fields: show/hide the whole container (label + editbox together)
    local urlH = 0
    local function setUrl(eb, url)
        eb:SetText(url)
    end
    if spellURL then
        setUrl(panel.detailUrlBtn1, spellURL)
        panel.detailUrlField1:Show()
        urlH = urlH + 22
    else
        panel.detailUrlBtn1:SetText("")
        panel.detailUrlField1:Hide()
    end

    if itemURL then
        setUrl(panel.detailUrlBtn2, itemURL)
        -- urlField2 positions itself just below urlField1 if it is visible
        panel.detailUrlField2:ClearAllPoints()
        if spellURL then
            panel.detailUrlField2:SetPoint("TOPLEFT",  panel.detailUrlField1, "BOTTOMLEFT",  0, -2)
            panel.detailUrlField2:SetPoint("TOPRIGHT", panel.detailUrlField1, "BOTTOMRIGHT", 0, -2)
        else
            panel.detailUrlField2:SetPoint("TOPLEFT",  panel.detailUrlRow, "TOPLEFT",  0, 0)
            panel.detailUrlField2:SetPoint("TOPRIGHT", panel.detailUrlRow, "TOPRIGHT", 0, 0)
        end
        panel.detailUrlField2:Show()
        urlH = urlH + 22
    else
        panel.detailUrlBtn2:SetText("")
        panel.detailUrlField2:Hide()
    end

    -- urlRow container: anchored below the skillTag
    local urlY = -62
    if panel.detailUrlRow then
        panel.detailUrlRow:SetHeight(math.max(urlH, 1))
        panel.detailUrlRow:ClearAllPoints()
        panel.detailUrlRow:SetPoint("TOPLEFT",  panel, "TOPLEFT",  70, urlY)
        panel.detailUrlRow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, urlY)
        if urlH > 0 then panel.detailUrlRow:Show() else panel.detailUrlRow:Hide() end
    end

    -- Description: below the URLs
    local desc = ""
    if entry.spellID and GetSpellDescription then
        desc = GetSpellDescription(entry.spellID) or ""
    end

    local descY = urlY - urlH - 4
    panel.detailDesc:ClearAllPoints()
    panel.detailDesc:SetPoint("TOPLEFT",  panel, "TOPLEFT",  70, descY)
    panel.detailDesc:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, descY)

    local descH = 0
    if desc ~= "" then
        panel.detailDesc:SetText(desc)
        panel.detailDesc:Show()
        -- GetStringHeight after SetText is reliable when width is known
        descH = math.ceil(panel.detailDesc:GetStringHeight() or 0)
        if descH < 1 then descH = 36 end  -- fallback 3 lines if layout not yet done
    else
        panel.detailDesc:Hide()
    end

    -- Reposition the separator and sections based on actual content height
    local dynTopH = math.max(122, math.abs(descY) + descH + 8)
    panel.topBg:SetHeight(dynTopH)
    panel.detailSep1:ClearAllPoints()
    panel.detailSep1:SetPoint("TOPLEFT",  panel, "TOPLEFT",  0, -dynTopH)
    panel.detailSep1:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -dynTopH)
    panel.reagSection:ClearAllPoints()
    panel.reagSection:SetPoint("TOPLEFT",  panel, "TOPLEFT",  4, -(dynTopH + 5))
    panel.reagSection:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -(dynTopH + 5))

    -- Reagents
    panel.detailReagentsLabel:SetText(L["UI_Reagents"] or "Materials:")
    local reagents  = entry.reagents or {}
    local reagCount = math.min(#reagents, MAX_REAGENTS)

    -- Pre-request item cache for unloaded IDs (GetItemInfo triggers a server request)
    local anyCacheMiss = false
    for _, r in ipairs(reagents) do
        if r.id then
            if not GetItemInfo(r.id) then anyCacheMiss = true end
        end
    end

    for i = 1, MAX_REAGENTS do
        local row = panel.detailReagents[i]
        if i <= reagCount then
            local r = reagents[i]
            row:Show()
            -- Lookup by ID (new-gen RecipeDB) or by name (live scan)
            local lookupKey = r.id or r.name
            local qty       = r.qty or r.count or 1

            -- Icone + nom + qualite via GetItemInfo
            local itemName, itemIcon, itemQuality, itemLink2
            if GetItemInfo and lookupKey then
                local n, lnk, q, _, _, _, _, _, _, tex = GetItemInfo(lookupKey)
                itemName    = n
                itemLink2   = lnk
                itemIcon    = tex
                itemQuality = q
            end
            -- Icon fallback: texture stored during scan (GetTradeSkillReagentInfo)
            if not itemIcon then itemIcon = r.icon end
            -- Nom affiche : priorite GetItemInfo > name stocke
            local displayName = itemName or r.name or tostring(lookupKey or "?")

            row.icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:Show()

            -- Quantity in its own right-aligned fixed-width column
            if row.qty then row.qty:SetText(qty .. "x") end

            local qc2 = GetItemQualityColor and GetItemQualityColor(itemQuality) or ""
            row.label:SetText(qc2 .. displayName .. C_RESET)

            local p    = GetAHPrice(displayName)
            local pStr = p and FormatCopper(p * qty) or ""
            if pStr ~= "" then
                row.price:SetText(pStr)
                row.price:Show()
                -- Shorten the label to avoid overlapping the price
                row.label:SetPoint("RIGHT", row.price, "LEFT", -4, 0)
            else
                row.price:Hide()
                row.label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            end

            -- Native WoW tooltip on hover (with Shift comparison)
            local capturedLink = itemLink2
            local capturedName = displayName
            row:SetScript("OnEnter", function(self)
                ShowEntryTooltip(self, { itemLink=capturedLink, name=capturedName })
            end)
            row:SetScript("OnLeave", HideTooltip)
            row:SetScript("OnMouseDown", function()
                if IsShiftKeyDown() then
                    local link = capturedLink
                    if link and ChatEdit_InsertLink then
                        if not ChatEdit_InsertLink(link) then
                            ChatFrame_OpenChat(link, DEFAULT_CHAT_FRAME)
                        end
                    end
                end
            end)
        else
            row:Hide()
            if row.qty then row.qty:SetText("") end
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)
        end
    end

    -- Retry once if some items were not in cache (WoW loads them asynchronously)
    if anyCacheMiss and not entry._cacheRetried then
        entry._cacheRetried = true
        GC:After(0.6, function()
            if panel:IsShown() then
                ShowRecipeDetail(panel, entry, onlineCache)
            end
        end)
    end

    -- reagSection height (without AH hint)
    local reagH = 8 + 18 + reagCount * 20 + 10
    panel.reagSection:SetHeight(reagH)
    panel.craftersSection:ClearAllPoints()
    panel.craftersSection:SetPoint("TOPLEFT",  panel.reagSection, "BOTTOMLEFT",  0, -6)
    panel.craftersSection:SetPoint("TOPRIGHT", panel.reagSection, "BOTTOMRIGHT", 0, -6)

    -- ── Artisans ─────────────────────────────────────────────────────────────
    local crafters = entry.crafters or {}
    local n        = #crafters

    -- Build the display list and its label
    local displayList = {}

    if n == 0 then
        panel.detailOnlineLbl:Hide()
        if panel.detailCandidatesLabel then panel.detailCandidatesLabel:Hide() end
        panel.detailCraftersLabel:SetText(C_ORANGE .. (L["UI_NoCrafters"] or "Nobody has this recipe.") .. C_RESET)
    else
        panel.detailOnlineLbl:Show()
        if panel.detailCandidatesLabel then panel.detailCandidatesLabel:Hide() end
        if n == 1 then
            panel.detailCraftersLabel:SetText("1 artisan :")
        else
            panel.detailCraftersLabel:SetText(n .. " artisans :")
        end
        for _, c in ipairs(crafters) do table.insert(displayList, { name = c }) end
    end

    local rowY0 = -26

    local displayCount = math.min(#displayList, MAX_CRAFTERS)
    for i = 1, MAX_CRAFTERS do
        local row = panel.detailCrafters[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  panel.craftersSection, "TOPLEFT",  10, rowY0 - (i-1)*24)
        row:SetPoint("TOPRIGHT", panel.craftersSection, "TOPRIGHT", -10, rowY0 - (i-1)*24)

        if i <= displayCount then
            local item = displayList[i]
            row:Show()
            local info = onlineCache and onlineCache[item.name]
            local isOnline = info and info.online

            row.dot:SetText("")
            local cc = isOnline
                and ((info and info.class and CLASS_COLOR[info.class]) or C_GREEN)
                or  C_GRAY
            row.name:SetText(cc .. item.name .. C_RESET)

            row.whisperBtn:SetText(L["UI_Whisper"] or "Whisper")
            local capName = item.name
            row.whisperBtn:SetScript("OnClick", function()
                if ChatFrame_OpenChat then
                    ChatFrame_OpenChat("/w " .. capName .. " ", DEFAULT_CHAT_FRAME)
                end
            end)
            row.whisperBtn:Show()
        else
            row:Hide()
        end
    end

    -- craftersSection height based on actual content
    local crafterH = (n == 0) and 42 or (8 + 18 + n * 24 + 10)
    panel.craftersSection:SetHeight(crafterH)
end

-- (ShowMemberDetail removed: members view no longer exists)

-- ============================================================================
-- Main UI creation
-- ============================================================================

function GC:CreateUI()
    if GC.mainFrame then return end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", "AgoraMainFrame", UIParent, template)
    frame:SetFrameStrata("HIGH")
    frame:SetSize(UI_W, UI_H)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()
    tinsert(UISpecialFrames, "AgoraMainFrame")

    -- Dark backdrop
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        frame:SetBackdropColor(0.06, 0.04, 0.01, 1.0)
        frame:SetBackdropBorderColor(0.6, 0.48, 0.18, 0.85)
    end

    -- Extra solid background to ensure opacity (UI-DialogBox-Background is semi-transparent)
    local solidBg = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
    solidBg:SetPoint("TOPLEFT",     frame, "TOPLEFT",  13, -10)
    solidBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 10)
    solidBg:SetColorTexture(0.04, 0.02, 0.01, 1.0)

    -- Title bar
    local titleBand = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    titleBand:SetHeight(TITLE_H)
    titleBand:SetPoint("TOPLEFT",  frame, "TOPLEFT",  12, -8)
    titleBand:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -8)
    titleBand:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    titleBand:SetVertexColor(0.08, 0.05, 0.01, 0.9)

    -- Separator below the title
    local titleSep = frame:CreateTexture(nil, "BORDER")
    titleSep:SetHeight(2)
    titleSep:SetPoint("TOPLEFT",  frame, "TOPLEFT",  12, -(8 + TITLE_H))
    titleSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -(8 + TITLE_H))
    titleSep:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    titleSep:SetVertexColor(0.6, 0.45, 0.1, 0.8)

    -- Title icon + text
    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetSize(20, 20)
    titleIcon:SetTexture("Interface\\AddOns\\GuildForge\\GuildForge_icon")
    titleIcon:SetPoint("TOP", frame, "TOP", -50, -(8 + TITLE_H / 2 - 10))

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 8, -(8 + TITLE_H / 2 - 6))
    title:SetText(C_GOLD .. "Agora" .. C_RESET)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- ── Action bar (WeakAuras style: inline text links, no box buttons) ──
    local topY = 8 + TITLE_H + 2 + 6  -- below title bar + separator + margin

    local actionBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    actionBg:SetHeight(VIEW_H)
    actionBg:SetPoint("TOPLEFT",  frame, "TOPLEFT",  12, -topY)
    actionBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -topY)
    actionBg:SetColorTexture(0.035, 0.02, 0.005, 0.85)

    local actionSepBot = frame:CreateTexture(nil, "BORDER")
    actionSepBot:SetHeight(1)
    actionSepBot:SetPoint("TOPLEFT",  frame, "TOPLEFT",  12, -(topY + VIEW_H))
    actionSepBot:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -(topY + VIEW_H))
    actionSepBot:SetColorTexture(0.5, 0.38, 0.08, 0.45)

    local btnPatrons = CreateFrame("Button", nil, frame)
    btnPatrons:SetSize(120, VIEW_H)
    btnPatrons:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -topY)
    btnPatrons:SetNormalFontObject("GameFontNormal")
    btnPatrons:SetHighlightFontObject("GameFontNormal")
    btnPatrons:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
    local bpHL = btnPatrons:GetHighlightTexture()
    if bpHL then bpHL:SetVertexColor(0.6, 0.5, 0.1) end
    btnPatrons:SetText(L["UI_TabByRecipe"])
    frame.btnPatrons = btnPatrons

    btnPatrons:SetScript("OnClick", function()
        GC.filterCategory = nil
        GC:RefreshUI()
    end)

    -- WoW-style SearchBox with magnifier icon + clear button
    local sbW, sbH = 210, 24

    local sbContainer = CreateFrame("Frame", nil, frame)
    sbContainer:SetSize(sbW, sbH)
    sbContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -topY)

    -- Fond
    local sbBg = sbContainer:CreateTexture(nil, "BACKGROUND")
    sbBg:SetAllPoints()
    sbBg:SetColorTexture(0.05, 0.03, 0.01, 0.92)

    -- Gold border (4 lines of 1px)
    local function MakeBorder(parent, point, rpoint, ox, oy, w, h)
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.65, 0.52, 0.18, 1)
        t:SetPoint(point,  parent, point,  ox,  oy)
        t:SetPoint(rpoint, parent, rpoint, -ox, -oy)
        if w  then t:SetWidth(w)  end
        if h  then t:SetHeight(h) end
        return t
    end
    MakeBorder(sbContainer, "TOPLEFT",    "TOPRIGHT",    0,  0, nil, 1)
    MakeBorder(sbContainer, "BOTTOMLEFT", "BOTTOMRIGHT", 0,  0, nil, 1)
    MakeBorder(sbContainer, "TOPLEFT",    "BOTTOMLEFT",  0,  0, 1, nil)
    MakeBorder(sbContainer, "TOPRIGHT",   "BOTTOMRIGHT", 0,  0, 1, nil)

    -- Slightly brighter inner background on focus (texture swap)
    sbContainer._bgNormal = {0.05, 0.03, 0.01, 0.92}
    sbContainer._bgFocus  = {0.10, 0.07, 0.02, 0.95}
    sbContainer._sbBg     = sbBg

    -- Magnifier icon (left)
    local sbIcon = sbContainer:CreateTexture(nil, "ARTWORK")
    sbIcon:SetSize(14, 14)
    sbIcon:SetPoint("LEFT", sbContainer, "LEFT", 4, 0)
    sbIcon:SetTexture("Interface\\Common\\UI-SearchBox-Icon")
    sbIcon:SetVertexColor(0.8, 0.75, 0.5, 0.9)

    -- EditBox
    local searchBox = CreateFrame("EditBox", "AgoraSearchBox", sbContainer)
    searchBox:SetFontObject("GameFontNormalSmall")
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(60)
    searchBox:EnableMouse(true)
    searchBox:SetPoint("TOPLEFT",     sbContainer, "TOPLEFT",     20, -4)
    searchBox:SetPoint("BOTTOMRIGHT", sbContainer, "BOTTOMRIGHT", -22, 4)

    -- Placeholder text
    local sbHint = sbContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sbHint:SetPoint("LEFT", searchBox, "LEFT", 0, 0)
    sbHint:SetText(C_GRAY .. (L["UI_SearchHint"] or "Rechercher...") .. C_RESET)
    frame.sbHint = sbHint

    -- Clear button (X) — visible only when text is present
    local clearBtn = CreateFrame("Button", nil, sbContainer)
    clearBtn:SetSize(18, 18)
    clearBtn:SetPoint("RIGHT", sbContainer, "RIGHT", -2, 0)
    clearBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    clearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    clearBtn:Hide()
    frame.searchClearBtn = clearBtn

    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)

    -- Visual focus: brighter background when active
    searchBox:SetScript("OnEditFocusGained", function()
        sbContainer._sbBg:SetColorTexture(0.10, 0.07, 0.02, 0.95)
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        sbContainer._sbBg:SetColorTexture(0.05, 0.03, 0.01, 0.92)
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        GC.currentSearch = self:GetText():lower()
        local empty = GC.currentSearch == ""
        sbHint:SetShown(empty)
        clearBtn:SetShown(not empty)
        GC:RefreshUI()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- "Guild only" checkbox - anchored to the left of the search box
    local guildOnlyChk = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    guildOnlyChk:SetSize(22, 22)
    local guildOnlyLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guildOnlyLbl:SetText(C_GRAY .. (L["UI_GuildOnly"] or "Guild only") .. C_RESET)
    guildOnlyLbl:SetPoint("RIGHT", sbContainer, "LEFT", -36, 0)
    guildOnlyChk:SetPoint("LEFT",  guildOnlyLbl, "RIGHT", 2, 1)
    guildOnlyChk:SetChecked(GC.showGuildOnly)
    guildOnlyChk:SetScript("OnClick", function(self)
        GC.showGuildOnly = self:GetChecked()
        GC:RefreshUI()
    end)
    frame.guildOnlyChk = guildOnlyChk
    frame.guildOnlyLbl = guildOnlyLbl

    -- ── Profession tabs (icons, 40px, visible in Recipes view only) ──
    local tabsY = topY + VIEW_H + 4

    local tabArea = CreateFrame("Frame", nil, frame)
    tabArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  14, -(tabsY))
    tabArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -(tabsY))
    tabArea:SetHeight(TABS_H)
    frame.tabArea = tabArea

    -- Separator below the tabs
    local tabSep = frame:CreateTexture(nil, "BORDER")
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT",  frame, "TOPLEFT",  12, -(tabsY + TABS_H + 2))
    tabSep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -(tabsY + TABS_H + 2))
    tabSep:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    tabSep:SetVertexColor(0.4, 0.3, 0.08, 0.6)
    frame.tabSep = tabSep

    -- "Include Vanilla" checkbox (visible only when expansion > Classic)
    local prevExpChk = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    prevExpChk:SetSize(22, 22)
    local prevExpLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevExpLbl:SetText(C_GRAY .. (L["UI_IncludeVanilla"] or "Include Vanilla") .. C_RESET)
    prevExpLbl:SetPoint("RIGHT", guildOnlyLbl, "LEFT", -36, 0)
    prevExpChk:SetPoint("LEFT", prevExpLbl, "RIGHT", 2, 1)
    prevExpChk:SetChecked(GC.showPrevExp)
    prevExpChk:SetScript("OnClick", function(self)
        GC.showPrevExp = self:GetChecked()
        GC:BuildTabs()
        GC:RefreshUI()
    end)
    frame.prevExpChk = prevExpChk
    frame.prevExpLbl = prevExpLbl

    -- Legacy button (disabled, replaced by checkbox)
    frame.prevExpBtn = nil

    -- ── Content area: Y start below the tabs ──
    local contentY = tabsY + TABS_H + 6

    -- Category filters (just below the tabs, in the left panel)
    local catArea = CreateFrame("Frame", nil, frame)
    catArea:SetPoint("TOPLEFT",  frame, "TOPLEFT",  14, -(contentY))
    catArea:SetSize(LEFT_W - 14, 22)
    frame.catArea = catArea

    -- Global counter shown in catArea when no profession is selected
    local catCounter = catArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catCounter:SetPoint("LEFT",  catArea, "LEFT",  0, 0)
    catCounter:SetJustifyH("LEFT")
    catCounter:Hide()
    frame.catCounter = catCounter

    -- Importants toggle (always visible, right-anchored in catArea)
    local impBtn = CreateFrame("Button", nil, frame)
    impBtn:SetHeight(22)
    local impLbl = impBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    impLbl:SetText("|cffffd700★ |r" .. (L["UI_ImportantOnly"] or "Important"))
    impBtn:SetWidth(impLbl:GetStringWidth() + 20)
    impLbl:SetPoint("CENTER", impBtn, "CENTER", 0, 0)
    impBtn:SetPoint("RIGHT", catArea, "RIGHT", 0, 0)
    impBtn:SetPoint("TOP",   catArea, "TOP",   0, 0)

    local impBg = impBtn:CreateTexture(nil, "BACKGROUND")
    impBg:SetAllPoints()
    impBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    impBtn.bg = impBg

    local function updateImpBg()
        if GC.filterImportant then
            impBg:SetVertexColor(0.3, 0.18, 0.04, 0.95)
        else
            impBg:SetVertexColor(0.1, 0.07, 0.02, 0.7)
        end
    end
    updateImpBg()

    impBtn:SetScript("OnClick", function()
        GC.filterImportant = not GC.filterImportant
        updateImpBg()
        GC:RefreshUI()
    end)
    impBtn:SetScript("OnEnter", function()
        impBg:SetVertexColor(0.4, 0.25, 0.06, 1)
    end)
    impBtn:SetScript("OnLeave", updateImpBg)
    frame.impBtn = impBtn
    -- Constrain catCounter so it doesn't overlap impBtn (anchored right of catArea)
    catCounter:SetPoint("RIGHT", catArea, "RIGHT", -(impBtn:GetWidth() + 4), 0)

    -- Vertical divider between left and right panels
    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT",    frame, "TOPLEFT",  14 + LEFT_W, -(contentY + 26))
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14 + LEFT_W, 42)
    divider:SetColorTexture(0.5, 0.38, 0.1, 0.3)

    -- ── Left panel: scroll frame list ──
    local listY = contentY + 26  -- room for catArea (22px) + gap (4px)
    local scrollLeft = CreateFrame("ScrollFrame", "AgoraScrollLeft", frame,
                                    "UIPanelScrollFrameTemplate")
    scrollLeft:SetPoint("TOPLEFT",    frame, "TOPLEFT",  14, -listY)
    scrollLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 42)
    scrollLeft:SetWidth(LEFT_W - 20)
    frame.scrollLeft = scrollLeft

    local contentLeft = CreateFrame("Frame", "AgoraContentLeft", scrollLeft)
    contentLeft:SetWidth(LEFT_W - 38)
    contentLeft:SetHeight(1)
    scrollLeft:SetScrollChild(contentLeft)
    frame.contentLeft = contentLeft

    -- ── Right panel: detail ──
    local detailX = 14 + LEFT_W + 8
    local detailW = UI_W - detailX - 14

    local detailPanel = CreateDetailPanel(frame, detailX, listY, detailW,
                                           UI_H - listY - 42)
    detailPanel:Show()
    frame.detailPanel = detailPanel

    -- ── Footer bar (WeakAuras style) ──
    local footerSep = frame:CreateTexture(nil, "BORDER")
    footerSep:SetHeight(1)
    footerSep:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  12, 40)
    footerSep:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 40)
    footerSep:SetColorTexture(0.5, 0.38, 0.08, 0.5)

    local footerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    footerBg:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  12, 9)
    footerBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 40)
    footerBg:SetColorTexture(0.035, 0.02, 0.005, 0.9)

    -- Copyable link popup (shared by all footer links)
    local linkPopup = CreateFrame("Frame", "AgoraLinkPopup", UIParent,
                                  BackdropTemplateMixin and "BackdropTemplate" or nil)
    linkPopup:SetSize(360, 108)
    linkPopup:SetPoint("CENTER")
    linkPopup:SetFrameStrata("DIALOG")
    linkPopup:SetMovable(true)
    linkPopup:EnableMouse(true)
    linkPopup:RegisterForDrag("LeftButton")
    linkPopup:SetScript("OnDragStart", linkPopup.StartMoving)
    linkPopup:SetScript("OnDragStop",  linkPopup.StopMovingOrSizing)
    -- Escape handling: close popup first, then main frame on second press.
    -- We do this by removing the main frame from UISpecialFrames while the
    -- popup is open, so CloseSpecialWindows() doesn't close both at once.
    local function removeMainFromSpecial()
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "AgoraMainFrame" then
                table.remove(UISpecialFrames, i)
                break
            end
        end
    end
    local function addMainToSpecial()
        for _, v in ipairs(UISpecialFrames) do
            if v == "AgoraMainFrame" then return end
        end
        tinsert(UISpecialFrames, "AgoraMainFrame")
    end

    linkPopup:SetScript("OnShow", function()
        removeMainFromSpecial()
        -- Register popup so Escape closes it (not the GameMenu)
        local found = false
        for _, v in ipairs(UISpecialFrames) do
            if v == "AgoraLinkPopup" then found = true; break end
        end
        if not found then tinsert(UISpecialFrames, "AgoraLinkPopup") end
    end)
    linkPopup:SetScript("OnHide", function()
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "AgoraLinkPopup" then
                table.remove(UISpecialFrames, i); break
            end
        end
        addMainToSpecial()
    end)
    if linkPopup.SetBackdrop then
        linkPopup:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        linkPopup:SetBackdropColor(0.06, 0.04, 0.01, 0.98)
        linkPopup:SetBackdropBorderColor(0.85, 0.68, 0.22, 1)
    end
    linkPopup:Hide()

    local popupMsg = linkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupMsg:SetPoint("TOP", linkPopup, "TOP", 0, -16)
    popupMsg:SetText("")
    linkPopup.msg = popupMsg

    local popupDesc = linkPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popupDesc:SetPoint("TOP", popupMsg, "BOTTOM", 0, -4)
    popupDesc:SetTextColor(0.6, 0.6, 0.6)
    popupDesc:SetText("")
    linkPopup.desc = popupDesc

    local popupBox = CreateFrame("EditBox", "AgoraLinkBox", linkPopup)
    popupBox:SetFontObject("GameFontNormalSmall")
    popupBox:SetPoint("TOPLEFT",     popupDesc, "BOTTOMLEFT",  0, -8)
    popupBox:SetPoint("BOTTOMRIGHT", linkPopup, "BOTTOMRIGHT", -40, 16)
    popupBox:SetAutoFocus(false)
    popupBox:SetMaxLetters(256)
    popupBox:SetScript("OnEscapePressed", function() linkPopup:Hide() end)
    popupBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local popupClose = CreateFrame("Button", nil, linkPopup, "UIPanelCloseButton")
    popupClose:SetPoint("TOPRIGHT", linkPopup, "TOPRIGHT", -2, -2)
    popupClose:SetScript("OnClick", function() linkPopup:Hide() end)

    linkPopup.Open = function(_, title, desc, url)
        popupMsg:SetText(C_GOLD .. title .. "|r")
        popupDesc:SetText(desc)
        if url and url ~= "" then
            popupBox:SetText(url)
            popupBox:Show()
            linkPopup:SetHeight(130)
            popupBox:SetFocus()
            popupBox:HighlightText()
        else
            popupBox:Hide()
            linkPopup:SetHeight(95)
        end
        linkPopup:Show()
    end

    -- Left: footer link buttons
    local function MakeFooterLink(parent, text, title, desc, url)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetHeight(28)
        btn:SetWidth(80)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints()
        fs:SetJustifyH("CENTER")
        fs:SetText("|cff5a6e68" .. text .. "|r")
        btn:SetScript("OnEnter", function()
            fs:SetText("|cffaac4bc" .. text .. "|r")
        end)
        btn:SetScript("OnLeave", function()
            fs:SetText("|cff5a6e68" .. text .. "|r")
        end)
        btn:SetScript("OnClick", function()
            linkPopup:Open(title, desc, url)
        end)
        return btn
    end

    local footerGH = MakeFooterLink(frame, "GitHub",
        L["LINK_GitHub_Title"], L["LINK_GitHub_Desc"], "github.com/pampasaga")
    footerGH:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 9)

    local footerCF = MakeFooterLink(frame, "CurseForge",
        L["LINK_CurseForge_Title"], L["LINK_CurseForge_Desc"], "curseforge.com/wow/addons/guildforge")
    footerCF:SetPoint("LEFT", footerGH, "RIGHT", 8, 0)

    -- Ko-fi: uncomment when the page is ready to be promoted
    -- local footerKF = MakeFooterLink(frame, "Ko-fi",
    --     L["LINK_Kofi_Title"], L["LINK_Kofi_Desc"], "ko-fi.com/pampasaga")
    -- footerKF:SetPoint("LEFT", footerCF, "RIGHT", 8, 0)

    -- Right: Pampasaga branding (clickable credits)
    local footerBrand = CreateFrame("Button", nil, frame)
    footerBrand:SetSize(160, 28)
    footerBrand:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 9)
    local fbFS = footerBrand:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fbFS:SetAllPoints()
    fbFS:SetJustifyH("RIGHT")
    fbFS:SetText("|cff2d3d38Pampasaga-Spineshatter|r")
    footerBrand:SetScript("OnEnter", function()
        fbFS:SetText("|cff5a7a70Pampasaga-Spineshatter|r")
    end)
    footerBrand:SetScript("OnLeave", function()
        fbFS:SetText("|cff2d3d38Pampasaga-Spineshatter|r")
    end)
    footerBrand:SetScript("OnClick", function()
        linkPopup:Open(L["LINK_Credits_Title"], L["LINK_Credits_Msg"], "")
    end)

    -- Version label: top-left corner
    local footerVer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerVer:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    footerVer:SetText("|cff2a3d34v" .. GC.VERSION_STRING .. "|r")
    GC.footerVersionLabel = footerVer

    function GC:UpdateFooterVersion()
        if not GC.footerVersionLabel then return end
        if GC._newerVersionSeen then
            GC.footerVersionLabel:SetText(
                "|cff2a3d34v" .. GC.VERSION_STRING .. "|r  " ..
                "|cffff9900" .. (L["CORE_UpdateAvailable"] or "Update available!") .. "|r")
        else
            GC.footerVersionLabel:SetText("|cff2a3d34v" .. GC.VERSION_STRING .. "|r")
        end
    end

    frame:HookScript("OnShow", function() GC:UpdateFooterVersion() end)

    GC.mainFrame = frame
    GC:BuildTabs()
    GC:RefreshUI()
end

-- ============================================================================
-- Profession tabs
-- ============================================================================

function GC:BuildTabs()
    local frame   = GC.mainFrame
    local tabArea = frame.tabArea
    if frame.tabs then for _, t in ipairs(frame.tabs) do t:Hide() end end
    frame.tabs = {}

    -- Merge guild professions + RecipeDB
    -- Gathering professions: no craftable recipes, must not appear as tabs
    local GATHERING = {
        ["Minage"]=true,        ["Mining"]=true,
        ["Herboristerie"]=true, ["Herbalism"]=true,
        ["Cueillette"]=true,
        ["Depecage"]=true,      ["Skinning"]=true,
        ["Peche"]=true,         ["Fishing"]=true,
    }

    local profSet  = {}
    local profList = {}

    for _, name in ipairs(GC:GetAllProfessions()) do
        if not profSet[name] and not GATHERING[name] then
            profSet[name] = true
            table.insert(profList, name)
        end
    end

    local curExp  = GC.currentExpansion or 2
    local prevExp = curExp - 1
    for _, entry in ipairs(GC.RecipeDB or {}) do
        local expOk = (entry.expansion == curExp)
                   or (GC.showPrevExp and entry.expansion == prevExp)
        if expOk and not profSet[entry.prof] then
            profSet[entry.prof] = true
            table.insert(profList, entry.prof)
        end
    end

    table.sort(profList)

    -- "All" button at the start
    local list = {}
    table.insert(list, { name = L["UI_AllProfs"] or "All", key = nil })
    for _, name in ipairs(profList) do
        table.insert(list, { name = name, key = name })
    end

    -- "Include Vanilla" checkbox (managed via frame.prevExpChk, no legacy button)
    frame.prevExpBtn = nil
    frame.UpdateExpBtn = nil
    -- Checkbox visibility managed in RefreshUI

    local x = 0
    for _, item in ipairs(list) do
        local profName = item.name
        local profKey  = item.key

        local btn = CreateFrame("Button", nil, tabArea)
        btn:SetHeight(TABS_H - 4)
        btn:SetPoint("LEFT", tabArea, "LEFT", x, 0)

        local icon = profKey and PROF_ICONS[profKey]
        local ic = nil

        if icon then
            -- Square button sized to icon
            btn:SetSize(TABS_H - 4, TABS_H - 4)
            ic = btn:CreateTexture(nil, "ARTWORK")
            ic:SetSize(30, 30)
            ic:SetPoint("CENTER", btn, "CENTER", 0, 0)
            ic:SetTexture(icon)
            ic:SetVertexColor(0.6, 0.6, 0.6)
        else
            -- "All" text button
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
            lbl:SetText(profName)
            btn:SetWidth(lbl:GetStringWidth() + 14)
        end
        btn.ic = ic

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        btn.bg = bg

        -- Gold selection bar at the bottom
        local activeLine = btn:CreateTexture(nil, "OVERLAY")
        activeLine:SetHeight(3)
        activeLine:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  2, 0)
        activeLine:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        activeLine:SetColorTexture(0.9, 0.72, 0.2, 1)
        activeLine:Hide()
        btn.activeLine = activeLine

        local function updateBg()
            local active = (profKey == nil and GC.selectedProf == nil)
                        or (profKey ~= nil and profKey == GC.selectedProf)
            if active then
                bg:SetColorTexture(0.22, 0.14, 0.03, 1.0)
                activeLine:Show()
                if btn.ic then btn.ic:SetVertexColor(1, 1, 1) end
            else
                bg:SetColorTexture(0.10, 0.06, 0.01, 0.8)
                activeLine:Hide()
                if btn.ic then btn.ic:SetVertexColor(0.6, 0.6, 0.6) end
            end
        end
        updateBg()
        btn.updateBg = updateBg

        btn:SetScript("OnClick", function()
            GC.selectedProf    = profKey
            GC.filterCategory  = nil
            GC.selectedRecipe  = nil
            for _, t in ipairs(frame.tabs) do
                if t.updateBg then t.updateBg() end
            end
            GC:BuildCatFilters()
            GC:RefreshUI()
        end)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.35, 0.22, 0.05, 1)
            if btn.ic then btn.ic:SetVertexColor(1, 0.92, 0.6) end
            if profKey then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(PROF_DISPLAY[profName] or profName, 1, 1, 0)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if profKey then GameTooltip:Hide() end
            updateBg()
        end)
        btn._profName = profName
        btn._profKey  = profKey

        x = x + btn:GetWidth() + 2
        table.insert(frame.tabs, btn)
    end
end

-- ============================================================================
-- Category filters (left panel, below the tabs)
-- ============================================================================

function GC:BuildCatFilters()
    local frame   = GC.mainFrame
    local catArea = frame.catArea

    -- Recycle old buttons
    if frame.catBtns then
        for _, b in ipairs(frame.catBtns) do b:Hide() end
    end
    frame.catBtns = {}

    local prof = GC.selectedProf
    if not prof then return end

    -- ── Recipes mode: filters by category ───────────────────────────────────

    -- Build the list of available categories from RecipeDB
    local catSet   = {}
    local filters  = {}
    for _, entry in ipairs(GC.RecipeDB or {}) do
        if entry.prof == prof and entry.category and not catSet[entry.category] then
            catSet[entry.category] = true
            table.insert(filters, entry.category)
        end
    end
    table.sort(filters)
    if #filters == 0 then return end

    local x = 0

    -- "All" button (resets the filter)
    do
        local allBtn = CreateFrame("Button", nil, catArea)
        allBtn:SetHeight(18)
        local lbl = allBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetText(L["UI_AllProfs"] or "All")
        local bw = lbl:GetStringWidth() + 10
        allBtn:SetWidth(bw)
        lbl:SetPoint("CENTER", allBtn, "CENTER", 0, 0)
        allBtn:SetPoint("LEFT", catArea, "LEFT", x, 0)
        allBtn.lbl = lbl
        local bg = allBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        allBtn.bg = bg
        local function updateBgAll()
            if GC.filterCategory == nil then
                bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                bg:SetVertexColor(0.3, 0.18, 0.04, 0.95)
            else
                bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                bg:SetVertexColor(0.1, 0.07, 0.02, 0.7)
            end
        end
        updateBgAll()
        allBtn.updateBg = updateBgAll
        allBtn:SetScript("OnClick", function()
            GC.filterCategory = nil
            for _, b in ipairs(frame.catBtns) do
                if b.updateBg then b.updateBg() end
            end
            GC.selectedRecipe = nil
            GC:RefreshUI()
        end)
        allBtn:SetScript("OnEnter", function(self)
            self.bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            self.bg:SetVertexColor(0.4, 0.25, 0.06, 1)
        end)
        allBtn:SetScript("OnLeave", updateBgAll)
        x = x + bw + 4
        table.insert(frame.catBtns, allBtn)
    end

    for _, cat in ipairs(filters) do
        local btn = CreateFrame("Button", nil, catArea)
        btn:SetHeight(18)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        local catLabel = cat
        lbl:SetText(catLabel)
        local bw = lbl:GetStringWidth() + 10
        btn:SetWidth(bw)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn:SetPoint("LEFT", catArea, "LEFT", x, 0)
        btn.lbl = lbl

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        btn.bg = bg

        local function updateBg()
            if GC.filterCategory == cat then
                bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                bg:SetVertexColor(0.3, 0.18, 0.04, 0.95)
            else
                bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                bg:SetVertexColor(0.1, 0.07, 0.02, 0.7)
            end
        end
        updateBg()
        btn.updateBg = updateBg

        btn:SetScript("OnClick", function()
            if GC.filterCategory == cat then
                GC.filterCategory = nil
            else
                GC.filterCategory = cat
            end
            for _, b in ipairs(frame.catBtns) do
                if b.updateBg then b.updateBg() end
            end
            GC.selectedRecipe = nil
            GC:RefreshUI()
        end)
        btn:SetScript("OnEnter", function(self)
            self.bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            self.bg:SetVertexColor(0.4, 0.25, 0.06, 1)
        end)
        btn:SetScript("OnLeave", updateBg)

        x = x + bw + 4
        table.insert(frame.catBtns, btn)
    end
end

-- ============================================================================
-- Recipes view: left panel
-- ============================================================================

local function RefreshPatronsLeft(content, onlineCache)
    local frame   = GC.mainFrame
    local map, order = BuildPatronMap(
        GC.selectedProf,
        GC.filterCategory,
        GC.currentSearch,
        GC.showGuildOnly
    )
    local y          = 0
    local total      = 0
    local grandTotal = 0
    local grandKnown = 0
    local curExp     = GC.currentExpansion or 2

    -- Pre-compute global totals (used by catArea in RefreshUI)
    for _, profName in ipairs(order) do
        for _, e in ipairs(map[profName]) do
            grandTotal = grandTotal + 1
            if e.known then grandKnown = grandKnown + 1 end
        end
    end

    for _, profName in ipairs(order) do
        local entries    = map[profName]
        local knownCount = 0
        for _, e in ipairs(entries) do if e.known then knownCount = knownCount + 1 end end

        -- Profession header
        local hdr = GetRow(content, y, 0)
        hdr.bgTex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        hdr.bgTex:SetVertexColor(0.18, 0.10, 0.02, 0.95)
        hdr.bgTex:Show()

        local iconPath = PROF_ICONS[profName]
        if iconPath then
            hdr.ic:SetTexture(iconPath)
            hdr.ic:Show()
            hdr.lfs:ClearAllPoints()
            hdr.lfs:SetPoint("LEFT",  hdr, "LEFT",  22, 0)
            hdr.lfs:SetPoint("RIGHT", hdr, "RIGHT", -60, 0)
        end
        hdr.lfs:SetText(C_GOLD .. (PROF_DISPLAY[profName] or profName) .. C_RESET)
        hdr.rfs:SetText(C_GREEN .. knownCount .. C_RESET
                     .. C_GRAY .. "/" .. #entries .. C_RESET)
        y = y - ROW_H

        for _, entry in ipairs(entries) do
            local expTag = ""
            if entry.expansion and entry.expansion < curExp and GC.showPrevExp then
                local short = GC.EXP_SHORT and GC.EXP_SHORT[entry.expansion] or "?"
                expTag = " " .. C_EXPTAG .. "[" .. short .. "]" .. C_RESET
            end

            local row = GetRow(content, y, 6)

            -- Quality color or grey if unknown
            -- For known recipes: minimum quality 2 (white) to avoid displaying in grey
            local displayQ = entry.known and math.max(entry.quality or 2, 2) or 0
            local qc = displayQ > 0 and (QUALITY_COLOR[displayQ] or QUALITY_COLOR[2])
                                     or C_GRAY

            local rowIcon = ResolveIcon(entry)

            local leftOff  = 4
            if rowIcon then
                row.ic:SetTexture(rowIcon)
                row.ic:Show()
                leftOff = 22
            end

            local crafterCount = entry.crafters and #entry.crafters or 0
            local crafterStr   = crafterCount > 0
                and (C_GREEN .. crafterCount .. C_RESET)
                or  (C_GRAY  .. "0"          .. C_RESET)

            row.lfs:ClearAllPoints()
            row.lfs:SetPoint("LEFT",  row, "LEFT",  leftOff, 0)
            row.lfs:SetPoint("RIGHT", row, "RIGHT", -24, 0)

            local displayName = entry.name or ""
            if entry.important then
                displayName = "|cffffd700★ |r" .. displayName
            end
            local skillTag = entry.minSkill and (C_GRAY .. " [" .. entry.minSkill .. "]" .. C_RESET) or ""
            row.lfs:SetText(qc .. displayName .. C_RESET .. skillTag .. expTag)
            row.rfs:SetText(crafterStr)

            -- Store the entry for the right panel
            local capturedEntry = entry

            row:SetScript("OnEnter", function(self) ShowEntryTooltip(self, capturedEntry) end)
            row:SetScript("OnLeave", function() HideTooltip() end)

            row:SetScript("OnClick", function()
                -- Shift+click: inserts the link into the active chat box (native WoW behaviour)
                if IsShiftKeyDown() then
                    local link = capturedEntry.itemLink
                    if not link and capturedEntry.spellID then
                        link = "|cff71d5ff|Hspell:"..capturedEntry.spellID.."|h["
                               ..(capturedEntry.name or "").."]|h|r"
                    end
                    if link and ChatEdit_InsertLink then
                        if not ChatEdit_InsertLink(link) then
                            -- No chat box open: open the /g channel
                            ChatFrame_OpenChat(link, DEFAULT_CHAT_FRAME)
                        end
                    end
                    return
                end
                GC.selectedRecipe = capturedEntry
                local onCache = BuildOnlineCache()
                ShowRecipeDetail(GC.mainFrame.detailPanel, capturedEntry, onCache)
            end)

            y = y - ROW_H
            total = total + 1
        end
        y = y - 4
    end

    return total, y, grandKnown, grandTotal
end

-- ============================================================================
-- (Members view removed: Agora focuses on recipes only)
-- ============================================================================

-- ============================================================================
-- RefreshUI
-- ============================================================================

function GC:RefreshUI()
    if not GC.mainFrame then return end
    local frame   = GC.mainFrame
    local content = frame.contentLeft

    -- Element visibility (always recipes view now)
    GC.viewMode = "patrons"
    frame.tabArea:SetShown(true)
    if frame.tabSep then frame.tabSep:SetShown(true) end
    frame.catArea:SetShown(true)
    local showPrevExpCtrl = (GC.currentExpansion or 2) > (GC.EXP_CLASSIC or 1)
    if frame.prevExpChk then frame.prevExpChk:SetShown(showPrevExpCtrl) end
    if frame.prevExpLbl then frame.prevExpLbl:SetShown(showPrevExpCtrl) end
    if frame.guildOnlyChk then
        frame.guildOnlyChk:SetShown(true)
        if frame.guildOnlyLbl then frame.guildOnlyLbl:SetShown(true) end
    end

    -- Highlight the active button
    frame.btnPatrons:LockHighlight()
    frame.btnPatrons:SetText(C_GOLD .. L["UI_TabByRecipe"] .. C_RESET)

    -- Rebuild category / specialization filters
    GC:BuildCatFilters()

    -- Hide profession tabs with no results during a search
    if GC.currentSearch ~= "" then
        local searchMap = BuildPatronMap(nil, nil, GC.currentSearch, false)
        for _, tab in ipairs(frame.tabs or {}) do
            if tab._profKey == nil then
                tab:Show()  -- "All" always visible
            else
                tab:SetShown(searchMap[tab._profKey] ~= nil and #(searchMap[tab._profKey] or {}) > 0)
            end
        end
    else
        for _, tab in ipairs(frame.tabs or {}) do tab:Show() end
    end

    ClearRows()

    local onlineCache = BuildOnlineCache()
    local total, y

    local grandKnown, grandTotal
    total, y, grandKnown, grandTotal = RefreshPatronsLeft(content, onlineCache)

    -- Global counter in catArea ("All" tab)
    if frame.catCounter then
        if not GC.selectedProf then
            frame.catCounter:SetText(
                C_GRAY  .. "Total : " .. C_RESET
                .. C_GREEN .. (grandKnown or 0) .. C_RESET
                .. C_GRAY  .. " / " .. (grandTotal or 0) .. " patrons connus" .. C_RESET
            )
            frame.catCounter:Show()
        else
            frame.catCounter:Hide()
        end
    end

    if total == 0 then
        local row = GetRow(content, 0, 0)
        if GC.currentSearch ~= "" then
            row.lfs:SetText(C_GRAY
                .. string.format(L["UI_NoResults"] or "No results for \"%s\".",
                                 GC.currentSearch)
                .. C_RESET)
        elseif not IsInGuild() then
            row.lfs:SetText(C_GRAY
                .. (L["UI_NoGuild"] or "Join a guild to share\nyour recipes with your guildmates.")
                .. C_RESET)
        else
            row.lfs:SetText(C_GRAY .. (L["UI_NoData"] or "No data.") .. C_RESET)
        end
        y = -ROW_H
    end

    content:SetHeight(math.max(math.abs(y) + 20, 1))

    -- Right panel: hint when nothing is selected
    local dp = frame.detailPanel
    local function HideDetailWidgets(dp)
        if dp.topBg then dp.topBg:Hide() end
        if dp.detailIconHit then dp.detailIconHit:Hide() end
        if dp.detailIcon then dp.detailIcon:Hide() end
        if dp.detailName then dp.detailName:Hide() end
        if dp.detailExpTag then dp.detailExpTag:Hide() end
        if dp.detailSkillTag then dp.detailSkillTag:Hide() end
        if dp.detailUrlRow then dp.detailUrlRow:Hide() end
        if dp.detailUrlLabel1 then dp.detailUrlLabel1:Hide() end
        if dp.detailUrlBox1 then dp.detailUrlBox1:Hide() end
        if dp.detailUrlLabel2 then dp.detailUrlLabel2:Hide() end
        if dp.detailUrlBox2 then dp.detailUrlBox2:Hide() end
        if dp.detailSep1 then dp.detailSep1:Hide() end
        if dp.detailDesc then dp.detailDesc:Hide() end
        if dp.detailReagentsLabel then dp.detailReagentsLabel:Hide() end
        for i = 1, MAX_REAGENTS do
            if dp.detailReagents and dp.detailReagents[i] then
                dp.detailReagents[i]:Hide()
            end
        end
        if dp.detailCandidatesLabel then dp.detailCandidatesLabel:Hide() end
        if dp.detailCraftersLabel then dp.detailCraftersLabel:Hide() end
        for i = 1, MAX_CRAFTERS do
            if dp.detailCrafters and dp.detailCrafters[i] then
                dp.detailCrafters[i]:Hide()
            end
        end
        if dp.detailOnlineLbl then dp.detailOnlineLbl:Hide() end
        if dp.reagSection then dp.reagSection:Hide() end
        if dp.craftersSection then dp.craftersSection:Hide() end
        if dp.colDiv then dp.colDiv:Hide() end
    end

    -- Build the onboarding message if nobody in the guild has any recipe data yet
    local function GetOnboardingHint()
        if not IsInGuild() then return nil end
        -- If any guild member has recipes, the list has content: just show "Select a recipe"
        if AgoraDB and AgoraDB.members then
            for _, member in pairs(AgoraDB.members) do
                for _, prof in ipairs(member.professions or {}) do
                    if prof.recipes and #prof.recipes > 0 then return nil end
                end
            end
        end
        return "|cffff4444" ..
               (L["UI_OnboardingMain"] or "Open each profession window\nto sync your recipes\nwith your guildmates.")
    end

    if not GC.selectedRecipe then
        -- Hide all detail widgets and show the hint
        HideDetailWidgets(dp)
        local onboard = GetOnboardingHint()
        if onboard then
            dp.hint:SetText(onboard)
        else
            dp.hint:SetText(C_GRAY .. (L["UI_SelectRecipe"] or "Select a recipe") .. C_RESET)
        end
        dp.hint:Show()
        if dp.emptyIcon then dp.emptyIcon:Show() end
        dp:Show()
    else
        ShowRecipeDetail(dp, GC.selectedRecipe, onlineCache)
    end

    -- Sync prevExp checkbox state
    if frame.prevExpChk then
        frame.prevExpChk:SetChecked(GC.showPrevExp)
    end
end

-- ============================================================================
-- Toggle
-- ============================================================================

function GC:ToggleUI()
    local ok, err = pcall(function()
        if not GC.mainFrame then
            GC:CreateUI()
            GC:BuildTabs()
            GC:RefreshUI()
            GC.mainFrame:Show()
        elseif GC.mainFrame:IsShown() then
            GC.mainFrame:Hide()
        else
            GC:BuildTabs()
            GC:RefreshUI()
            GC.mainFrame:Show()
        end
    end)
    if not ok then
        print("|cffff0000" .. (L["CORE_ErrorPrefix"] or "Agora error: ") .. "|r"
              .. tostring(err))
    end
end
