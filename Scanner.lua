-- GuildForge - Scanner.lua
-- Scan professions (levels) and recipes (open craft window)

local GC = Agora

-- Normalize profession names to canonical English.
-- Handles locale differences AND accents (e.g. Ingenierie / Ingénierie -> Engineering).
-- Also acts as a whitelist: if a name is not in this table, it is not a profession.
local PROF_CANONICAL = {
    -- enUS (identite)
    ["Alchemy"]           = "Alchemy",
    ["Blacksmithing"]     = "Blacksmithing",
    ["Enchanting"]        = "Enchanting",
    ["Engineering"]       = "Engineering",
    ["Herbalism"]         = "Herbalism",
    ["Jewelcrafting"]     = "Jewelcrafting",
    ["Leatherworking"]    = "Leatherworking",
    ["Mining"]            = "Mining",
    ["Skinning"]          = "Skinning",
    ["Tailoring"]         = "Tailoring",
    ["Cooking"]           = "Cooking",
    ["First Aid"]         = "First Aid",
    ["Fishing"]           = "Fishing",
    ["Inscription"]       = "Inscription",
    -- frFR
    ["Alchimie"]          = "Alchemy",
    ["Forge"]             = "Blacksmithing",
    ["Enchantement"]      = "Enchanting",
    ["Ingenierie"]        = "Engineering",
    ["Ingénierie"]        = "Engineering",
    ["Herboristerie"]     = "Herbalism",
    ["Joaillerie"]        = "Jewelcrafting",
    ["Travail du cuir"]   = "Leatherworking",
    ["Minage"]            = "Mining",
    ["Depecage"]          = "Skinning",
    ["Dépeçage"]          = "Skinning",
    ["Couture"]           = "Tailoring",
    ["Cuisine"]           = "Cooking",
    ["Secourisme"]        = "First Aid",
    ["Peche"]             = "Fishing",
    ["Pêche"]             = "Fishing",
    ["Calligraphie"]      = "Inscription",
    -- deDE
    ["Alchemie"]              = "Alchemy",
    ["Schmiedekunst"]         = "Blacksmithing",
    ["Verzauberkunst"]        = "Enchanting",
    ["Ingenieurskunst"]       = "Engineering",
    ["Krauterkunde"]          = "Herbalism",
    ["Kräuterkunde"]          = "Herbalism",
    ["Juwelierskunst"]        = "Jewelcrafting",
    ["Lederverarbeitung"]     = "Leatherworking",
    ["Bergbau"]               = "Mining",
    ["Kurschnerei"]           = "Skinning",
    ["Kürschnerei"]           = "Skinning",
    ["Schneiderei"]           = "Tailoring",
    ["Kochkunst"]             = "Cooking",
    ["Erste Hilfe"]           = "First Aid",
    ["Angeln"]                = "Fishing",
    ["Inschriftenkunde"]      = "Inscription",
    -- esES / esMX
    ["Alquimia"]              = "Alchemy",
    ["Herrería"]              = "Blacksmithing",
    ["Herreria"]              = "Blacksmithing",
    ["Encantamiento"]         = "Enchanting",
    ["Ingeniería"]            = "Engineering",
    ["Ingenieria"]            = "Engineering",
    ["Herboristería"]         = "Herbalism",
    ["Herboristeria"]         = "Herbalism",
    ["Joyería"]               = "Jewelcrafting",
    ["Joyeria"]               = "Jewelcrafting",
    ["Peletería"]             = "Leatherworking",
    ["Peleteria"]             = "Leatherworking",
    ["Minería"]               = "Mining",
    ["Mineria"]               = "Mining",
    ["Desuello"]              = "Skinning",
    ["Sastrería"]             = "Tailoring",
    ["Sastreria"]             = "Tailoring",
    ["Cocina"]                = "Cooking",
    ["Primeros auxilios"]     = "First Aid",
    ["Pesca"]                 = "Fishing",
    ["Inscripción"]           = "Inscription",
    ["Inscripcion"]           = "Inscription",
    -- ptBR
    ["Alquimia"]              = "Alchemy",
    ["Ferraria"]              = "Blacksmithing",
    ["Encantamento"]          = "Enchanting",
    ["Engenharia"]            = "Engineering",
    ["Herbalismo"]            = "Herbalism",
    ["Joalheria"]             = "Jewelcrafting",
    ["Curtimento"]            = "Leatherworking",
    ["Mineração"]             = "Mining",
    ["Mineracao"]             = "Mining",
    ["Esfolamento"]           = "Skinning",
    ["Alfaiataria"]           = "Tailoring",
    ["Culinária"]             = "Cooking",
    ["Culinaria"]             = "Cooking",
    ["Primeiros Socorros"]    = "First Aid",
    ["Inscrição"]             = "Inscription",
    ["Inscricao"]             = "Inscription",
    -- ruRU
    ["Алхимия"]               = "Alchemy",
    ["Кузнечное дело"]        = "Blacksmithing",
    ["Наложение чар"]         = "Enchanting",
    ["Инженерное дело"]       = "Engineering",
    ["Травничество"]          = "Herbalism",
    ["Ювелирное дело"]        = "Jewelcrafting",
    ["Кожевничество"]         = "Leatherworking",
    ["Горное дело"]           = "Mining",
    ["Снятие шкур"]           = "Skinning",
    ["Портняжное дело"]       = "Tailoring",
    ["Кулинария"]             = "Cooking",
    ["Первая помощь"]         = "First Aid",
    ["Рыбная ловля"]          = "Fishing",
    ["Начертание"]            = "Inscription",
}

-- TBC specializations: spellID -> parent profession
-- Tailoring excluded: its IDs correspond to recipes. Detected via spellbook.
-- Leatherworking: completed by spellbook scan (prefix "Travail du cuir ").
local SPEC_SPELLS = {
    -- Engineering
    { id = 20219, parent_en = "Engineering",    parent_fr = "Ingenierie"      }, -- Gnome Engineer
    { id = 20222, parent_en = "Engineering",    parent_fr = "Ingenierie"      }, -- Goblin Engineer
    -- Blacksmithing (Armorsmith + Weaponsmith + sub-specs)
    { id =  9788, parent_en = "Blacksmithing",  parent_fr = "Forge"           }, -- Master Armorsmith
    { id =  9787, parent_en = "Blacksmithing",  parent_fr = "Forge"           }, -- Master Weaponsmith
    { id = 17039, parent_en = "Blacksmithing",  parent_fr = "Forge"           }, -- Master Swordsmith
    { id = 17040, parent_en = "Blacksmithing",  parent_fr = "Forge"           }, -- Master Hammersmith
    { id = 17041, parent_en = "Blacksmithing",  parent_fr = "Forge"           }, -- Master Axesmith
    -- Leatherworking
    { id = 10657, parent_en = "Leatherworking", parent_fr = "Travail du cuir" }, -- Elemental (or Tribal)
    { id = 10658, parent_en = "Leatherworking", parent_fr = "Travail du cuir" }, -- Elemental
    { id = 10660, parent_en = "Leatherworking", parent_fr = "Travail du cuir" }, -- Tribal
    -- Alchemy (TBC mastery)
    { id = 28674, parent_en = "Alchemy",        parent_fr = "Alchimie"        }, -- Potion Master
    { id = 28677, parent_en = "Alchemy",        parent_fr = "Alchimie"        }, -- Elixir Master
    { id = 28672, parent_en = "Alchemy",        parent_fr = "Alchimie"        }, -- Transmutation Master
}

-- Exclusive recipes indicating Tailoring specialization (frFR + enUS)
-- These recipes only appear in the window if the player has the specialization
local TAILORING_SPEC_INDICATORS = {
    { recipe_fr = "Tissu de lune primordial",  recipe_en = "Primal Mooncloth", spec = "Tissu de lune primordial"  },
    { recipe_fr = "Tissu d'ombre",             recipe_en = "Shadowcloth",      spec = "Tissu d'ombre"             },
    { recipe_fr = "Etoffe de sort",            recipe_en = "Spellcloth",       spec = "Etoffe de sort"            },
}

-- Scans player profession levels via GetSkillLineInfo
-- Does not require an open craft window
function GC:ScanProfessionLevels()
    if not AgoraDB then return end

    local _pName = (UnitName and UnitName("player")) or "Unknown"
    local _rName = ""
    if GetRealmName then
        local ok, val = pcall(GetRealmName)
        if ok and val and val ~= "" then _rName = val end
    end
    if _rName == "" then _rName = "Local" end
    local myKey  = _pName .. "-" .. _rName
    Agora._myKey = myKey  -- cache for other functions

    local existing = AgoraDB.members[myKey] or {}

    -- Preserve already-scanned recipes per profession
    local savedRecipes = {}
    for _, prof in ipairs(existing.professions or {}) do
        savedRecipes[prof.name] = prof.recipes
    end

    -- Normalize savedRecipes keys to canonical names
    local savedRecipesNorm = {}
    for rawName, recipes in pairs(savedRecipes) do
        local canon = PROF_CANONICAL[rawName] or rawName
        savedRecipesNorm[canon] = recipes
    end

    local professions = {}
    local profByName  = {}
    local numSkills = GetNumSkillLines()
    for i = 1, numSkills do
        local name, isHeader, _, skillRank, _, _, skillMaximum = GetSkillLineInfo(i)
        if not isHeader and name then
            local canon = PROF_CANONICAL[name]
            GC:Log("[SCAN] skill[" .. i .. "] '" .. name .. "' -> " .. (canon or "INCONNU"))
            if canon then
                local p = {
                    name      = canon,
                    level     = skillRank    or 0,
                    maxLevel  = skillMaximum or 0,
                    recipes   = savedRecipesNorm[canon] or {},
                }
                table.insert(professions, p)
                profByName[canon] = p
            end
        end
    end

    -- Detect specializations via IsSpellKnown (Engineering, Blacksmithing, LW, Alchemy)
    if IsSpellKnown and GetSpellInfo then
        for _, spec in ipairs(SPEC_SPELLS) do
            if IsSpellKnown(spec.id) then
                local spellName = GetSpellInfo(spec.id)
                if spellName then
                    local parentProf = profByName[spec.parent_en]
                    if parentProf then
                        parentProf.specialization = spellName
                        GC:Log("[SCAN] Spec detected: " .. spellName .. " (spell " .. spec.id .. ")")
                    end
                end
            end
        end
    end

    -- Scan the spellbook for specs whose name starts with the profession name
    -- E.g. "Couture d'etoffe lunaire", "Travail du cuir elementaire", etc.
    -- More reliable than hardcoded spellIDs for these professions.
    if GetNumSpellTabs and BOOKTYPE_SPELL then
        -- Table: exact prefix (with trailing space) -> keys to look up in profByName
        local GRIMOIRE_PREFIXES = {
            { prefix_fr = "Couture ",         prefix_en = "Tailoring ",
              keys      = { "Couture", "Tailoring" } },
            { prefix_fr = "Travail du cuir ", prefix_en = "Leatherworking ",
              keys      = { "Travail du cuir", "Leatherworking" } },
        }

        local numTabs = GetNumSpellTabs()
        for tab = 1, numTabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            for i = offset + 1, offset + numSpells do
                local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
                if spellName then
                    for _, entry in ipairs(GRIMOIRE_PREFIXES) do
                        local matchFR = spellName:find("^" .. entry.prefix_fr)
                        local matchEN = spellName:find("^" .. entry.prefix_en)
                        if matchFR or matchEN then
                            -- Find the parent profession in profByName
                            local prof
                            for _, key in ipairs(entry.keys) do
                                prof = profByName[key]
                                if prof then break end
                            end
                            if prof and not prof.specialization then
                                prof.specialization = spellName
                                GC:Log("[SCAN] Spec spellbook: " .. spellName)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    AgoraDB.members[myKey] = {
        name        = UnitName("player"),
        realm       = GetRealmName(),
        class       = select(2, UnitClass("player")),
        professions = professions,
        timestamp   = time(),
    }
end

-- Scans all recipes from the currently open craft window
-- Called on TRADE_SKILL_SHOW / TRADE_SKILL_UPDATE
function GC:ScanTradeSkillRecipes()
    if not AgoraDB then
        -- Defensive initialization if OnLogin has not yet run
        AgoraDB = { members = {}, version = Agora.VERSION }
        GC:Log("[SCAN] AgoraDB initialise en urgence")
    end

    -- Build myKey first (used by the fallbacks below)
    local _pName  = (UnitName and UnitName("player")) or "Unknown"
    local _rName  = ""
    if GetRealmName then
        local ok, val = pcall(GetRealmName)
        if ok and val and val ~= "" then _rName = val end
    end
    if _rName == "" then _rName = "Local" end
    local myKey = _pName .. "-" .. _rName

    local skillName, _, _, skillRank, _, skillMaximum = GetTradeSkillLine()
    GC:Log("[SCAN] GetTradeSkillLine = " .. tostring(skillName)
           .. "  rank=" .. tostring(skillRank)
           .. "  max=" .. tostring(skillMaximum))
    -- Normalize immediately to the canonical English name
    if skillName and skillName ~= "UNKNOWN" then
        skillName = PROF_CANONICAL[skillName] or skillName
    end
    if not skillName or skillName == "UNKNOWN" then
        -- Fallback 1: name cached by TRADE_SKILL_SHOW event
        skillName = GC._currentTradeSkill
        if skillName then skillName = PROF_CANONICAL[skillName] or skillName end
    end

    if not skillName or skillName == "UNKNOWN" then
        -- Fallback 2: identify profession via recipe names in RecipeDB
        local numR = GetNumTradeSkills and GetNumTradeSkills() or 0
        if numR > 0 and GC.RecipeDB then
            local scores = {}
            for i = 1, math.min(numR, 15) do
                local rName, rType = GetTradeSkillInfo(i)
                if rType ~= "header" and rName then
                    for _, entry in ipairs(GC.RecipeDB) do
                        if entry.name == rName then
                            scores[entry.prof] = (scores[entry.prof] or 0) + 1
                        end
                    end
                end
            end
            local bestProf, bestScore = nil, 0
            for prof, score in pairs(scores) do
                if score > bestScore then bestProf, bestScore = prof, score end
            end
            if bestProf then
                skillName = bestProf
                GC:Log("[SCAN] Profession identified via RecipeDB: " .. skillName .. " (" .. bestScore .. " recipes)")
            end
        end
    end


    if not skillName or skillName == "UNKNOWN" then
        -- Fallback 3: UNKNOWN + available recipes = enchanting on this server
        -- (GetTradeSkillLine returns UNKNOWN for enchanting on some private servers)
        local numR = GetNumTradeSkills and GetNumTradeSkills() or 0
        if numR > 0 then
            -- Make sure the member is in the DB before searching their professions
            if not AgoraDB.members[myKey] then
                pcall(function() GC:ScanProfessionLevels() end)
            end
            local member0 = AgoraDB.members[myKey]
            if member0 then
                for _, p in ipairs(member0.professions or {}) do
                    if p.name:find("nchant") then
                        skillName = p.name
                        GC:Log("[SCAN] Fallback 3 : UNKNOWN + " .. numR .. " recettes -> " .. skillName)
                        break
                    end
                end
            end
        end
    end

    if not skillName or skillName == "UNKNOWN" then
        GC:Log("[SCAN] Invalid profession, window not open?")
        return
    end

    GC:Log("[SCAN] myKey = " .. myKey)

    -- Make sure the member exists in the DB
    if not AgoraDB.members[myKey] then
        GC:Log("[SCAN] step 2: ScanProfessionLevels")
        local ok2, err2 = pcall(function() GC:ScanProfessionLevels() end)
        if not ok2 then
            GC:Log("[SCAN] CRASH ScanProfessionLevels: " .. tostring(err2))
        end
    end

    local member = AgoraDB.members[myKey]
    if not member then
        GC:Log("[SCAN] member nil after ScanProfessionLevels, manual creation")
        local _realm2 = ""
        if GetRealmName then
            local ok3, v3 = pcall(GetRealmName)
            if ok3 and v3 and v3 ~= "" then _realm2 = v3 end
        end
        if _realm2 == "" then _realm2 = "Local" end
        member = { name = _pName, realm = _realm2,
                   class = select(2, UnitClass("player")) or "WARRIOR",
                   professions = {}, timestamp = time() }
        AgoraDB.members[myKey] = member
    end

    GC:Log("[SCAN] step 3: looking up profession " .. skillName)
    -- Find or create the profession entry
    local prof = nil
    for _, p in ipairs(member.professions) do
        if p.name == skillName then
            prof = p
            break
        end
    end
    if not prof then
        prof = { name = skillName, level = 0, maxLevel = 0, recipes = {} }
        table.insert(member.professions, prof)
    end

    prof.level    = skillRank    or prof.level
    prof.maxLevel = skillMaximum or prof.maxLevel
    prof.recipes  = {}

    do
        -- Reset filters to scan ALL known recipes
        -- (otherwise GetNumTradeSkills only returns those matching the active filter)
        if SetTradeSkillSubClassFilter then
            pcall(function()
                -- 0 = "All types", true = show, true = include sub-categories
                SetTradeSkillSubClassFilter(0, 1, 1)
            end)
        end
        if SetTradeSkillItemLevelFilter then
            pcall(function() SetTradeSkillItemLevelFilter(0, 0) end)
        end

        local numRecipes = GetNumTradeSkills()
        GC:Log("[SCAN] " .. skillName .. " : " .. tostring(numRecipes) .. " entries in window")
        for i = 1, numRecipes do
            local recipeName, recipeType = GetTradeSkillInfo(i)
            if recipeType ~= "header" and recipeName then
                local numReagents = GetTradeSkillNumReagents(i)
                local reagents = {}
                for j = 1, numReagents do
                    local rName, rTex, rCount = GetTradeSkillReagentInfo(i, j)
                    if rName then
                        table.insert(reagents, { name = rName, count = rCount or 1, icon = rTex })
                    end
                end
                table.insert(prof.recipes, {
                    name     = recipeName,
                    reagents = reagents,
                    icon     = GetTradeSkillIcon(i),
                    itemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i) or nil,
                })
            end
        end
        GC:Log("[SCAN] " .. skillName .. " : " .. #prof.recipes .. " recipes saved")

        -- Detect Tailoring specialization via exclusive recipes
        if skillName == "Couture" or skillName == "Tailoring" then
            prof.specialization = nil
            local recipeIndex = {}
            for _, r in ipairs(prof.recipes) do
                if r.name then recipeIndex[r.name] = true end
            end
            for _, ind in ipairs(TAILORING_SPEC_INDICATORS) do
                if recipeIndex[ind.recipe_fr] or recipeIndex[ind.recipe_en] then
                    local foundName = recipeIndex[ind.recipe_fr] and ind.recipe_fr or ind.recipe_en
                    prof.specialization = foundName
                    GC:Log("[SCAN] Tailoring spec detected: " .. foundName)
                    break
                end
            end
        end
    end

    member.timestamp = time()

    -- Update UI if it is open
    if GC.mainFrame and GC.mainFrame:IsShown() then
        GC:RefreshUI()
    end
end

-- Scan via Craft API (used by Enchanting on Classic/TBC)
function GC:ScanCraftRecipes()
    if not AgoraDB then return end

    local skillName = GetCraftLine and GetCraftLine()
    if skillName and skillName ~= "UNKNOWN" then
        skillName = PROF_CANONICAL[skillName] or skillName
    end
    if not skillName or skillName == "UNKNOWN" then
        -- Fallback: GetCraftLine returns UNKNOWN on TBC Anniversary
        -- If crafts are available, look for an "Enchanting" profession in the DB
        local numC = GetNumCrafts and GetNumCrafts() or 0
        if numC > 0 then
            local _pName = (UnitName and UnitName("player")) or "Unknown"
            local _rName = ""
            if GetRealmName then
                local ok, val = pcall(GetRealmName)
                if ok and val and val ~= "" then _rName = val end
            end
            if _rName == "" then _rName = "Local" end
            local _myKey = _pName .. "-" .. _rName
            local _member = AgoraDB.members[_myKey]
            if _member then
                for _, p in ipairs(_member.professions or {}) do
                    if p.name:find("nchant") then
                        skillName = p.name
                        GC:Log("[CRAFT] Fallback GetCraftLine -> " .. skillName)
                        break
                    end
                end
            end
        end
        if not skillName or skillName == "UNKNOWN" then
            GC:Log("[CRAFT] GetCraftLine unknown, aborting")
            return
        end
    end
    GC:Log("[CRAFT] GetCraftLine = " .. skillName)

    local _pName = (UnitName and UnitName("player")) or "Unknown"
    local _rName = ""
    if GetRealmName then
        local ok, val = pcall(GetRealmName)
        if ok and val and val ~= "" then _rName = val end
    end
    if _rName == "" then _rName = "Local" end
    local myKey = _pName .. "-" .. _rName

    if not AgoraDB.members[myKey] then
        GC:ScanProfessionLevels()
    end
    local member = AgoraDB.members[myKey]
    if not member then return end

    local prof = nil
    for _, p in ipairs(member.professions) do
        if p.name == skillName then prof = p; break end
    end
    if not prof then
        prof = { name = skillName, level = 0, maxLevel = 0, recipes = {} }
        table.insert(member.professions, prof)
    end

    prof.recipes = {}
    local numCrafts = GetNumCrafts and GetNumCrafts() or 0
    for i = 1, numCrafts do
        local name, _, craftType = GetCraftInfo(i)
        if craftType ~= "header" and name then
            local numReagents = GetCraftNumReagents and GetCraftNumReagents(i) or 0
            local reagents = {}
            for j = 1, numReagents do
                local rName, rTex, rCount = GetCraftReagentInfo(i, j)
                if rName then
                    table.insert(reagents, { name = rName, count = rCount or 1, icon = rTex })
                end
            end
            table.insert(prof.recipes, {
                name     = name,
                reagents = reagents,
                itemLink = GetCraftItemLink and GetCraftItemLink(i) or nil,
            })
        end
    end
    GC:Log("[CRAFT] " .. skillName .. " : " .. #prof.recipes .. " recipes saved")
    member.timestamp = time()
    if GC.mainFrame and GC.mainFrame:IsShown() then GC:RefreshUI() end
end
