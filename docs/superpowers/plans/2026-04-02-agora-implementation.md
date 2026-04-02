# Agora Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer GuildForge en Agora — addon unique combinant partage de metiers en guilde et marche serveur-wide de services de craft verifies.

**Architecture:** On evolue la base existante de GuildForge (pas de réécriture). Le canal GUILD reste pour la guilde. On ajoute un canal serveur "Agora". Le format de serialisation passe de V1 a V2. L'UI perd la vue "Membres" et gagne une section crafteurs serveur dans le panel droit, plus un flyout "Proposer mes services".

**Tech Stack:** Lua 5.1 (WoW API), SendAddonMessage / C_ChatInfo.SendAddonMessage, GetContainerItemInfo (scan sacs), GetSpellCooldown (verification CD). Deploy via `bash deploy.sh` vers machine Windows (WoW Classic TBC Anniversary, interface ~20505).

---

## Fichiers touches

| Fichier | Action | Responsabilite |
|---------|--------|----------------|
| `GuildForge_BCC.toc` | Modifier | Titre, SavedVariables, icon |
| `GuildForge_Classic.toc` | Modifier | Idem |
| `Core.lua` | Modifier | Namespace, PREFIX, slash commands, heartbeat, REMOVE au logout, join canal serveur |
| `DB.lua` | Modifier | AgoraDB, nouveaux champs (settings, my_prices, server_peers) |
| `Scanner.lua` | Modifier | Ajouter ScanBags() pour validation badge compos |
| `Broadcast.lua` | Modifier | V2 serialize, SendChunked dual-canal, SendHeartbeat, SendRemove, Deserialize V2 |
| `RecipeDB.lua` | Modifier | Ajouter `important = true` aux recettes cles TBC |
| `UI.lua` | Modifier | Supprimer vue Membres, toggle Importants, dual crafters panel, flyout Proposer |
| `Minimap.lua` | Modifier | Refs GuildForge → Agora |

---

## Task 1 : Renommage — foundation

Objectif : tous les fichiers references GuildForge par le nom d'addon, GuildForgeDB, GCRAFT sont mis a jour. L'addon se charge comme "Agora" dans WoW.

**Fichiers :**
- Modifier : `GuildForge_BCC.toc`
- Modifier : `GuildForge_Classic.toc`
- Modifier : `Core.lua` (lignes 4, 8-10, 27, 61-62)
- Modifier : `DB.lua` (toutes les refs GuildForgeDB)
- Modifier : `Broadcast.lua` (ref GuildForgeDB ligne 143-146, 149)
- Modifier : `UI.lua` (refs GuildForge dans strings et frame names)
- Modifier : `Minimap.lua` (refs nom addon)

- [ ] **Etape 1 : Mettre a jour les .toc**

`GuildForge_BCC.toc` et `GuildForge_Classic.toc` — memes changements dans les deux :

```
## Interface: 20505
## Title: Agora
## Notes: Verified craft marketplace for your guild and realm.
## Notes-frFR: Marche de services de craft verifies pour ta guilde et ton serveur.
## Version: 1.0.0
## Author: Pampasaga
## IconTexture: Interface\AddOns\GuildForge\GuildForge_icon
## SavedVariables: AgoraDB
## X-Website: https://github.com/pampasaga/Agora
## X-License: MIT

Core.lua
Locales\enUS.lua
Locales\frFR.lua
Locales\deDE.lua
Locales\esES.lua
Locales\ptBR.lua
Locales\ruRU.lua
DB.lua
Scanner.lua
Broadcast.lua
RecipeDB.lua
UI.lua
Debug.lua
Minimap.lua
```

Note : `IconTexture` garde le chemin GuildForge pour l'instant (l'icone est le meme fichier physique).

- [ ] **Etape 2 : Renommer namespace et PREFIX dans Core.lua**

Remplacer les lignes 4-10 et 27-62 :

```lua
-- Core.lua lignes 4-10 : renommer namespace
GuildForge = GuildForge or {}  -- garde compat pendant transition
Agora = GuildForge              -- alias principal
local GC = Agora

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
```

Remplacer le bloc init DB (lignes 60-63) :

```lua
if not AgoraDB then
    AgoraDB = { members = {}, version = GC.VERSION }
end
```

- [ ] **Etape 3 : Mettre a jour DB.lua**

Remplacer toutes les occurrences `GuildForgeDB` par `AgoraDB` dans DB.lua.
Il y en a environ 15 (les fonctions SaveMember, RemoveMember, GetAllMembers, GetCurrentGuildSet, GetMembersWithProfession, GetAllProfessions, CleanupDepartedMembers et leurs references internes).

Commande pour verifier qu'il n'en reste pas :
```bash
grep -n "GuildForgeDB" DB.lua
```
Resultat attendu : aucune ligne.

- [ ] **Etape 4 : Mettre a jour Broadcast.lua**

Remplacer toutes les occurrences `GuildForgeDB` par `AgoraDB` dans Broadcast.lua.
Verifier :
```bash
grep -n "GuildForgeDB" Broadcast.lua
```
Resultat attendu : aucune ligne.

- [ ] **Etape 5 : Mettre a jour UI.lua**

Remplacer dans UI.lua :
- Le string `"GuildForge"` dans le titre du frame (ligne ~1705) par `"Agora"`
- Le nom du frame `"GuildForgeMainFrame"` par `"AgoraMainFrame"` (lignes ~1650, 1661, 1979-1991)
- Le nom du scrollframe `"GuildForgeScrollLeft"` par `"AgoraScrollLeft"` (ligne ~1931)
- Le nom du content frame `"GuildForgeContentLeft"` par `"AgoraContentLeft"` (ligne ~1938)
- Le nom du link popup `"GuildForgeLinkPopup"` par `"AgoraLinkPopup"` (lignes ~1966, 1999-2010)
- Le nom du link box `"GuildForgeLinkBox"` par `"AgoraLinkBox"` (ligne ~2034)
- Le texte du footer brand `"Pampasaga-Spineshatter"` (lignes ~2104-2110) : garder tel quel, c'est le pseudo realm
- La texture d'icone `"Interface\\AddOns\\GuildForge\\GuildForge_icon"` : garder pour l'instant (meme fichier)

- [ ] **Etape 6 : Mettre a jour Minimap.lua**

Lire Minimap.lua et remplacer toutes les refs au nom de l'addon ("GuildForge", "GUILDFORGE") par "Agora" / "AGORA". Le tooltip du minimap button doit afficher "Agora".

- [ ] **Etape 7 : Verifier qu'il ne reste plus de refs parasites**

```bash
grep -rn "GuildForge\|GCRAFT\|GuildForgeDB" Core.lua DB.lua Broadcast.lua UI.lua Minimap.lua
```
Seules refs acceptables : commentaires historiques dans Broadcast.lua ("V1" format compat).

- [ ] **Etape 8 : Deploy et verification en jeu**

```bash
cd /Users/pampa/www/GuildForge && bash deploy.sh
```

Dans WoW : `/reload`
- L'addon doit apparaitre comme "Agora" dans la liste des addons (ESC > Interface > Addons)
- `/ag` doit ouvrir la fenetre
- La fenetre doit afficher "Agora" dans la barre de titre (plus "GuildForge")
- Les donnees existantes ne sont PAS migrees (AgoraDB est vide, scan auto au login)

- [ ] **Etape 9 : Commit**

```bash
git add -A
git commit -m "feat: rename GuildForge to Agora (namespace, PREFIX, SavedVariables)"
```

---

## Task 2 : DB schema — nouveaux champs

Objectif : AgoraDB supporte les settings serveur, les prix par recette, le badge compos, et le store des peers serveur.

**Fichiers :**
- Modifier : `DB.lua`

- [ ] **Etape 1 : Definir la structure AgoraDB et les defaults**

Au debut de DB.lua, apres `local GC = Agora`, ajouter :

```lua
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
```

- [ ] **Etape 2 : Ajouter les accesseurs settings**

```lua
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
```

- [ ] **Etape 3 : Ajouter les accesseurs my_prices**

```lua
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
        price        = price or "",
        provides_mats = provides_mats == true,
    }
end
```

- [ ] **Etape 4 : Ajouter les accesseurs server_peers**

```lua
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
```

- [ ] **Etape 5 : Appeler InitDB au login**

Dans Core.lua, dans la fonction `GC:OnLogin()`, s'assurer que `GC:InitDB()` est appele en premier. Remplacer ou completer le bloc d'init existant :

```lua
function GC:OnLogin()
    GC:InitDB()
    -- ... reste de OnLogin existant
end
```

- [ ] **Etape 6 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW : `/reload`, puis `/ag`. L'addon s'ouvre sans erreur. Dans la console debug (`/ag debug`) verifier que AgoraDB a bien la structure attendue :
```lua
/dump AgoraDB.settings
-- attendu : { server_opt_in = false, price_default = "" }
/dump AgoraDB.server_peers
-- attendu : {} (table vide)
```

- [ ] **Etape 7 : Commit**

```bash
git add DB.lua Core.lua
git commit -m "feat: AgoraDB schema with settings, my_prices, server_peers"
```

---

## Task 3 : Broadcast V2 — format et canal serveur

Objectif : le format de serialisation passe a V2 (zone, price, provides_mats, cd_available par recette). Un canal serveur "Agora" est rejoint. SendChunked supporte les deux canaux.

**Fichiers :**
- Modifier : `Broadcast.lua`

- [ ] **Etape 1 : Mise a jour de Serialize en V2**

Remplacer la fonction `GC:Serialize` (actuellement ligne 38) :

```lua
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
```

- [ ] **Etape 2 : Mise a jour de Deserialize pour V1 et V2**

Remplacer la fonction `GC:Deserialize` (actuellement ligne 63) :

```lua
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
        -- V1 compat : pas de zone/price/provides_mats
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
```

- [ ] **Etape 3 : SendChunked supporte les deux canaux**

Remplacer `GC:SendChunked` :

```lua
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
        GC:After((idx - 1) * 0.05, function()
            if channel == "CHANNEL" then
                SendAddonMsg(GC.PREFIX, msg, "CHANNEL", GC.SERVER_CHANNEL)
            else
                SendAddonMsg(GC.PREFIX, msg, "GUILD")
            end
        end)
    end
end
```

Ajouter en haut de Broadcast.lua, apres les constantes :

```lua
GC.SERVER_CHANNEL = "Agora"
```

- [ ] **Etape 4 : SendMyData envoie aux deux canaux si opt-in**

Remplacer `GC:SendMyData` :

```lua
function GC:SendMyData()
    if not AgoraDB then return end
    local myKey = GC:GetMyKey()
    local data  = AgoraDB.members[myKey]
    if not data then return end
    if not data.professions or #data.professions == 0 then return end

    -- Enrichir les donnees avec zone et settings
    data.zone = GetRealZoneText and GetRealZoneText() or ""

    -- Envoyer a la guilde
    if IsInGuild() then
        GC:SendChunked(myKey, GC:Serialize(data), "GUILD")
    end

    -- Envoyer au serveur si opt-in
    if GC:GetServerOptIn() then
        GC:SendChunked(myKey, GC:Serialize(data), "CHANNEL")
    end
end
```

- [ ] **Etape 5 : Ajouter SendHeartbeat et SendRemove**

```lua
-- Heartbeat : signal "je suis la", envoye toutes les 5 minutes
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

-- Remove : signale que le joueur part (logout, instance, desactivation)
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
```

- [ ] **Etape 6 : SendHello envoie aux deux canaux**

Remplacer `GC:SendHello` :

```lua
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
```

- [ ] **Etape 7 : Mettre a jour OnAddonMessage pour HEARTBEAT et REMOVE**

Lire la fonction `GC:OnAddonMessage` existante dans Broadcast.lua. Y ajouter le traitement de HEARTBEAT et REMOVE (les ajouter dans le bloc if/elseif) :

```lua
-- Dans GC:OnAddonMessage, apres le bloc elseif "DATA" :

elseif msgType == "HEARTBEAT" then
    -- Mettre a jour le timestamp du peer serveur
    local peerKey = parts[2]
    if peerKey and peerKey ~= GC:GetMyKey() then
        local peer = AgoraDB.server_peers and AgoraDB.server_peers[peerKey]
        if peer then
            peer.last_heartbeat = time()
        end
    end

elseif msgType == "REMOVE" then
    local peerKey = parts[2]
    if peerKey then
        GC:RemovePeer(peerKey)
        if GC.mainFrame and GC.mainFrame:IsShown() then
            GC:RefreshUI()
        end
    end
```

Et dans le bloc DATA (reception d'un message d'un peer serveur via CHANNEL) : si `channel == "CHANNEL"`, appeler `GC:SavePeer(senderKey, data)` au lieu de `GC:SaveMember(data)`.

Trouver le bloc dans `GC:OnAssembled` (ou equivalent — la fonction appelee quand tous les chunks sont recus) et y ajouter :

```lua
function GC:OnAssembled(senderKey, payload, channel)
    local data = GC:Deserialize(payload)
    if not data then return end
    data.key = senderKey

    if channel == "CHANNEL" then
        -- Donnee serveur-wide
        GC:SavePeer(senderKey, data)
    else
        -- Donnee guilde
        GC:SaveMember(data)
    end

    if GC.mainFrame and GC.mainFrame:IsShown() then
        GC:RefreshUI()
    end
end
```

Note : la fonction existante s'appelle peut-etre differemment. Adapter en lisant le code reel de Broadcast.lua pour trouver ou les chunks reassembles sont traites.

- [ ] **Etape 8 : Joindre le canal serveur au login**

Dans Core.lua, dans `GC:OnLogin()`, apres l'init DB, ajouter :

```lua
-- Rejoindre le canal serveur Agora (lecture uniquement si pas opt-in, mais on doit ecouter)
GC:After(5, function()
    JoinChannelByName(GC.SERVER_CHANNEL)
    -- Cacher le canal du chat (on ne veut pas polluer les fenetres de chat)
    local chanNum = GetChannelName(GC.SERVER_CHANNEL)
    if chanNum and chanNum > 0 then
        -- Le canal est rejoint mais pas affiche dans le chat par defaut
        -- L'utilisateur peut le masquer manuellement dans les options de chat
    end
    GC:SendHello()
end)
```

Enregistrer l'evenement CHAT_MSG_ADDON pour le canal (il arrive via CHAT_MSG_ADDON avec channel="CHANNEL") — c'est deja enregistre dans Core.lua, pas de changement necessaire si l'event handler existant passe le `channel` en parametre a `GC:OnAddonMessage`.

- [ ] **Etape 9 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW : `/reload`
- `/dump GetChannelName("Agora")` doit retourner un numero > 0 (canal rejoint)
- Ouvrir la fenetre `/ag`
- Les donnees de guilde existantes doivent s'afficher normalement
- Envoyer `/ag scan` puis attendre quelques secondes — les guildmates avec l'addon doivent repondre (DATA dans le log debug)

- [ ] **Etape 10 : Commit**

```bash
git add Broadcast.lua Core.lua
git commit -m "feat: Broadcast V2 format, server channel Agora, heartbeat/remove"
```

---

## Task 4 : Scanner — validation badge compos

Objectif : `GC:ScanBags(reagents)` verifie si le joueur a les reactifs en sac et retourne le resultat.

**Fichiers :**
- Modifier : `Scanner.lua`

- [ ] **Etape 1 : Ajouter ScanBags**

A la fin de Scanner.lua, ajouter :

```lua
-- Scanne les sacs du joueur et verifie si les reactifs sont presents.
-- reagents : liste de { name=string, count=number }
-- Retourne : { ok=true } ou { ok=false, missing={ {name, need, have}, ... } }
function GC:ScanBags(reagents)
    -- Construire un inventaire des sacs
    local inventory = {}  -- [itemName:lower()] = quantite totale
    local NUM_BAG_SLOTS = 4
    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag)
        if slots then
            for slot = 1, slots do
                local _, count = GetContainerItemInfo(bag, slot)
                if count and count > 0 then
                    local link = GetContainerItemLink(bag, slot)
                    if link then
                        local itemName = GetItemInfo(link)
                        if itemName then
                            local key = itemName:lower()
                            inventory[key] = (inventory[key] or 0) + count
                        end
                    end
                end
            end
        end
    end

    -- Verifier chaque reactif
    local missing = {}
    for _, reagent in ipairs(reagents) do
        local key  = (reagent.name or ""):lower()
        local need = reagent.count or 1
        local have = inventory[key] or 0
        if have < need then
            table.insert(missing, { name = reagent.name, need = need, have = have })
        end
    end

    if #missing == 0 then
        return { ok = true }
    else
        return { ok = false, missing = missing }
    end
end
```

- [ ] **Etape 2 : Ajouter GetRecipeReagents (acces RecipeDB)**

```lua
-- Retourne les reactifs d'une recette depuis RecipeDB, ou nil si non trouvee.
function GC:GetRecipeReagents(profName, recipeName)
    local lrecipe = recipeName:lower()
    for _, entry in ipairs(GC.RecipeDB or {}) do
        if entry.prof == profName and (entry.name or ""):lower() == lrecipe then
            return entry.reagents
        end
    end
    return nil
end
```

- [ ] **Etape 3 : Deploy et test manuel**

```bash
bash deploy.sh
```

Dans WoW, avec la console debug ouverte :
```lua
-- Dans la console WoW (ou via un addon de test comme /run)
/run local r = {{name="Terocone", count=3}}; local res = Agora:ScanBags(r); print(res.ok, res.missing and #res.missing)
```
- Si le joueur a 3+ Terocone en sac : `true nil`
- Sinon : `false 1`

- [ ] **Etape 4 : Commit**

```bash
git add Scanner.lua
git commit -m "feat: ScanBags for compos badge validation"
```

---

## Task 5 : Core — heartbeat et REMOVE au logout

Objectif : le heartbeat est envoye toutes les 5 minutes. Un REMOVE est envoye au logout.

**Fichiers :**
- Modifier : `Core.lua`

- [ ] **Etape 1 : Timer heartbeat**

Dans `GC:OnLogin()`, apres l'init, ajouter un timer recursif :

```lua
-- Heartbeat toutes les 5 minutes
local HEARTBEAT_INTERVAL = 300  -- secondes

local function ScheduleHeartbeat()
    GC:After(HEARTBEAT_INTERVAL, function()
        if GC._initComplete then
            GC:SendHeartbeat()
            GC:PurgeStaleHeartbeats()
        end
        ScheduleHeartbeat()  -- re-planifier
    end)
end

ScheduleHeartbeat()
```

- [ ] **Etape 2 : REMOVE au logout**

Dans l'event frame de Core.lua, enregistrer `PLAYER_LOGOUT` et `PLAYER_ENTERING_WORLD` pour les instances :

```lua
eventFrame:RegisterEvent("PLAYER_LOGOUT")
```

Dans le handler `OnEvent`, ajouter :

```lua
elseif event == "PLAYER_LOGOUT" then
    GC:SendRemove()
```

Note : `PLAYER_LOGOUT` se declenche avant que la session soit fermee, SendAddonMsg a le temps de partir.

- [ ] **Etape 3 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW :
- Attendre 5 minutes (ou changer HEARTBEAT_INTERVAL a 10 pour tester)
- Verifier dans le debug log que "HEARTBEAT" est envoye
- Se deconnecter et se reconnecter : le debug log d'un autre client avec l'addon doit montrer "REMOVE" recu

- [ ] **Etape 4 : Commit**

```bash
git add Core.lua
git commit -m "feat: heartbeat every 5min, REMOVE on logout"
```

---

## Task 6 : RecipeDB — flag important

Objectif : les recettes cles TBC ont `important = true`. Ces recettes apparaissent en premier et peuvent etre filtrees avec le toggle Importants.

**Fichiers :**
- Modifier : `RecipeDB.lua`

- [ ] **Etape 1 : Identifier les recettes importantes**

Les recettes importantes sont celles utilisees systematiquement en raid ou pour le progression. Criteres :
- Flacons de raid (Flask of Supreme Power, Flask of Fortification, Flask of Relentless Assault, Flask of Mighty Restoration, Flask of Blinding Light)
- Transmutations majeures (Primal Might, transmutes primals : eau→air, feu→terre, etc.)
- Enchants BiS (Mongoose, Savagery, Sunfire, Spellsurge, Boar's Speed, Vitality, Major Resilience)
- Gems meta cles (Chaotic Skyfire Diamond, Bracing Earthstorm Diamond)
- Leatherworking : Drums of Battle, Drums of War (raid consumables majeurs)
- Tailoring : Frozen Shadoweave set, Spellstrike set, Battlecast set
- Engineering : Rocket Boots Xtreme, Goblin Rocket Launcher
- Nourriture : Spicy Crawdad, Fisherman's Feast

```bash
# Trouver les entrees correspondantes dans RecipeDB.lua
grep -n "Flask of Supreme Power\|Flask of Fortification\|Flask of Relentless\|Primal Might\|Mongoose\|Drums of Battle\|Drums of War\|Spellstrike\|Frozen Shadoweave\|Chaotic Skyfire" RecipeDB.lua
```

- [ ] **Etape 2 : Ajouter le flag important**

Pour chaque entree identifiee dans RecipeDB.lua, ajouter `important = true` dans la table.

Exemple — avant :
```lua
{ prof = "Alchemy", name = "Flask of Supreme Power", category = "Flasques", expansion = 2, spellID = 17628, ... },
```

Apres :
```lua
{ prof = "Alchemy", name = "Flask of Supreme Power", category = "Flasques", expansion = 2, spellID = 17628, important = true, ... },
```

Faire de meme pour chaque recette de la liste ci-dessus. Viser entre 30 et 60 recettes marquees `important` au total.

- [ ] **Etape 3 : Verification**

```bash
grep -c "important = true" RecipeDB.lua
```
Attendu : entre 30 et 60.

- [ ] **Etape 4 : Deploy et commit**

```bash
bash deploy.sh
git add RecipeDB.lua
git commit -m "feat: mark key TBC recipes as important in RecipeDB"
```

---

## Task 7 : UI — supprimer vue Membres, ajouter toggle Importants

Objectif : la vue "Par membre" est supprimee. Le toggle Importants est separe des filtres de categorie, positionne a droite dans la catArea.

**Fichiers :**
- Modifier : `UI.lua`

- [ ] **Etape 1 : Supprimer la vue Membres**

Dans `GC:CreateUI()` :
1. Supprimer la creation de `btnMembres` et son `SetScript("OnClick")`
2. Supprimer la creation de `frame.guildOnlyChk` et `frame.guildOnlyLbl` seulement si cette checkbox n'est plus utile (la garder si elle sert encore)
3. Dans `GC:RefreshUI()`, supprimer le bloc `if GC.viewMode == "membres"` et forcer `GC.viewMode = "patrons"` en permanence

Supprimer aussi :
- La fonction `GC:RenderMembersView()` si elle existe en tant que fonction separee
- Les variables d'etat liees a la vue membres : `GC.selectedMember`, `GC.filterSpec`

- [ ] **Etape 2 : Ajouter le state filterImportant**

Au debut de UI.lua, dans le bloc "UI state" (ligne ~214) :

```lua
GC.filterImportant = false
```

- [ ] **Etape 3 : Ajouter le toggle Importants dans catArea**

Dans `GC:BuildCatFilters()`, apres avoir construit les boutons de categorie normaux, ajouter le toggle Importants a droite de la catArea :

```lua
-- Toggle Importants (ancre a droite de catArea, independant des filtres categorie)
local impBtn = CreateFrame("Button", nil, catArea)
impBtn:SetHeight(18)
local impLbl = impBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
impLbl:SetText("|cffffd700* |r" .. (L["UI_ImportantOnly"] or "Important"))
impBtn:SetWidth(impLbl:GetStringWidth() + 16)
impLbl:SetPoint("CENTER", impBtn, "CENTER", 0, 0)
impBtn:SetPoint("RIGHT", catArea, "RIGHT", 0, 0)

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
```

- [ ] **Etape 4 : Appliquer le filtre dans BuildRecipeMap**

Dans la fonction `GC:BuildRecipeMap()` (ou equivalent qui construit la liste des recettes), ajouter la condition `important` :

```lua
-- Dans la boucle de filtrage des entrees RecipeDB :
local importantOk = (not GC.filterImportant) or (entry.important == true)

if expOk and profOk and catOk and searchOk and knownOk and importantOk then
    -- ... ajouter l'entree
end
```

Et dans le tri final, mettre les recettes `important` en premier :

```lua
table.sort(map[pName], function(a, b)
    -- Important d'abord
    if (a.important == true) ~= (b.important == true) then
        return a.important == true
    end
    -- Puis minSkill decroissant
    local sa = a.minSkill or 0
    local sb = b.minSkill or 0
    if sa ~= sb then return sa > sb end
    return (a.name or "") < (b.name or "")
end)
```

- [ ] **Etape 5 : Afficher l'etoile dans la liste des recettes**

Dans le rendu d'une ligne de recette dans `GC:RenderRecipeRow()` (ou equivalent), ajouter l'indicateur important :

```lua
-- Nom de la recette avec etoile si important
local displayName
if entry.important then
    displayName = "|cffffd700* |r" .. (entry.name or "")
else
    displayName = entry.name or ""
end
row.label:SetText(displayName)
```

- [ ] **Etape 6 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW : `/ag`
- La fenetre n'a plus de tab "Par membre"
- Selectionner un metier (ex. Alchimie) : les sous-filtres apparaissent a gauche de la catArea, le bouton "* Important" apparait a droite
- Cliquer "Important" : la liste se reduit aux recettes marquees `important = true`
- Cliquer a nouveau : retour a la liste complete
- Les recettes importantes ont une etoile doree dans la liste

- [ ] **Etape 7 : Commit**

```bash
git add UI.lua
git commit -m "feat: remove members view, add separate Importants toggle"
```

---

## Task 8 : UI — panel droit dual crafteurs (guilde + serveur)

Objectif : le panel droit affiche deux sections separees : crafteurs guilde, crafteurs serveur. Chaque fiche crafteur montre : nom + zone + badge compos + prix.

**Fichiers :**
- Modifier : `UI.lua`

- [ ] **Etape 1 : Etendre la liste des crafteurs dans BuildRecipeMap**

Dans `GC:BuildRecipeMap()`, pour chaque recette, enrichir `entry.crafters` avec des donnees structurees :

```lua
-- Au lieu de stocker juste entry.crafters = { "Pampa", "Zarak" },
-- stocker une liste de tables :
entry.crafters = {
    { name="Pampa", zone="Shattrath", price="tips", provides_mats=false, source="guild" },
    { name="Zarak", zone="Ironforge",  price="5g",   provides_mats=true,  source="guild" },
}
```

Pour les crafteurs guilde, iterer sur `GC:GetAllMembers()` et pour chaque membre/profession/recette correspondante recuperer les donnees dans `AgoraDB.members[key]`.

Pour les crafteurs serveur, iterer sur `GC:GetPeers()` et faire de meme.

```lua
-- Dans la construction de entry.crafters :
local crafterList = {}

-- Guilde
for key, member in pairs(GC:GetAllMembers()) do
    for _, prof in ipairs(member.professions or {}) do
        if prof.name == entry.prof then
            for _, rec in ipairs(prof.recipes or {}) do
                if (rec.name or ""):lower() == entryName:lower() then
                    local priceEntry = GC:GetMyPrice(prof.name, rec.name)  -- donnees du membre
                    table.insert(crafterList, {
                        name          = member.name,
                        zone          = member.zone or "",
                        price         = member.price or "",
                        provides_mats = member.provides_mats or false,
                        cd_available  = rec.cd_available,
                        source        = "guild",
                        class         = member.class,
                    })
                end
            end
        end
    end
end

-- Serveur
for key, peer in pairs(GC:GetPeers()) do
    local peerData = peer.data
    if peerData then
        for _, prof in ipairs(peerData.professions or {}) do
            if prof.name == entry.prof then
                for _, rec in ipairs(prof.recipes or {}) do
                    if (rec.name or ""):lower() == entryName:lower() then
                        -- Ne pas dupliquer si deja en guilde
                        local alreadyGuild = false
                        for _, c in ipairs(crafterList) do
                            if c.name == peerData.name and c.source == "guild" then
                                alreadyGuild = true; break
                            end
                        end
                        if not alreadyGuild then
                            table.insert(crafterList, {
                                name          = peerData.name,
                                zone          = peerData.zone or "",
                                price         = peerData.price or "",
                                provides_mats = peerData.provides_mats or false,
                                cd_available  = rec.cd_available,
                                source        = "server",
                            })
                        end
                    end
                end
            end
        end
    end
end

entry.crafters = crafterList
```

- [ ] **Etape 2 : Mettre a jour ShowRecipeDetail**

Dans `ShowRecipeDetail()` (UI.lua, section crafters), remplacer l'affichage actuel (liste simple) par deux sections :

```lua
-- Separer guild et server
local guildCrafters  = {}
local serverCrafters = {}
for _, c in ipairs(crafters) do
    if c.source == "server" then
        table.insert(serverCrafters, c)
    else
        table.insert(guildCrafters, c)
    end
end

-- Section guilde
if #guildCrafters > 0 then
    -- Titre section
    panel.detailCraftersLabel:SetText(
        "|cff5a7a70" .. (#guildCrafters) .. " guilde|r"
    )
    -- ... afficher chaque crafter guilde (voir ci-dessous)
end

-- Separateur + section serveur
if #serverCrafters > 0 then
    -- Label "serveur"
    -- ... afficher chaque crafter serveur
end
```

Pour chaque crafter row, mettre a jour `RenderCrafterRow(row, crafter, onlineCache)` :

```lua
local function RenderCrafterRow(row, crafter, onlineCache)
    row:Show()

    -- Dot : vert plein pour guilde online, cercle pour serveur
    if crafter.source == "guild" then
        local info     = onlineCache and onlineCache[crafter.name]
        local isOnline = info and info.online
        local cc       = isOnline
            and ((info and info.class and CLASS_COLOR[info.class]) or C_GREEN)
            or  C_GRAY
        row.name:SetText(cc .. crafter.name .. C_RESET)
        row.dot:SetText(isOnline and "|cff00ff00●|r" or "|cff666666●|r")
    else
        row.name:SetText(C_GRAY .. crafter.name .. C_RESET)
        row.dot:SetText("|cff666666○|r")
    end

    -- Zone badge
    if row.zone then
        row.zone:SetText(crafter.zone ~= "" and ("|cff6a5a30[" .. crafter.zone .. "]|r") or "")
    end

    -- Badge compos
    if row.mats then
        row.mats:SetText(crafter.provides_mats and ("|cff55dd55[+Compos]|r") or "")
    end

    -- Prix
    local priceStr = ""
    if crafter.price == "tips" then
        priceStr = "|cffaaaaaa" .. (L["UI_Tips"] or "tips") .. "|r"
    elseif crafter.price and crafter.price ~= "" then
        local copper = tonumber(crafter.price)
        priceStr = copper and FormatCopper(copper) or crafter.price
    end
    if row.price then row.price:SetText(priceStr) end
end
```

Note : les frames `row.zone`, `row.mats`, `row.price` doivent etre creees dans `CreateDetailPanel()`. Adapter les fonctions existantes de creation de rows crafteurs pour inclure ces nouveaux elements.

- [ ] **Etape 3 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW : `/ag`
- Selectionner un patron connu (avec crafteurs en guilde)
- Le panel droit doit montrer la section "guilde" avec les crafteurs
- Si un peer serveur est present : section "serveur" apparait en dessous
- Badge [+Compos] visible sur les fiches avec provides_mats=true
- Prix affiche correctement

- [ ] **Etape 4 : Commit**

```bash
git add UI.lua
git commit -m "feat: detail panel shows guild + server crafters with zone/price/badge"
```

---

## Task 9 : UI — flyout "Proposer mes services"

Objectif : le bouton "Proposer mes services" dans le footer ouvre un flyout permettant d'activer le broadcast serveur, de definir son prix par defaut, et de configurer recette par recette (prix + badge compos).

**Fichiers :**
- Modifier : `UI.lua`

- [ ] **Etape 1 : Bouton dans le footer**

Dans `GC:CreateUI()`, dans la section footer (apres `footerSep`, avant `footerBrand`), ajouter :

```lua
local proposeBtn = CreateFrame("Button", nil, frame)
proposeBtn:SetSize(160, 22)
proposeBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 10)
proposeBtn:SetNormalFontObject("GameFontNormal")

local proposeBg = proposeBtn:CreateTexture(nil, "BACKGROUND")
proposeBg:SetAllPoints()
proposeBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
proposeBg:SetVertexColor(0.15, 0.35, 0.15, 0.9)

local proposeLbl = proposeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
proposeLbl:SetAllPoints()
proposeLbl:SetJustifyH("CENTER")
proposeLbl:SetText("|cff55dd55" .. (L["UI_ProposeServices"] or "Propose my services") .. "|r")

proposeBtn:SetScript("OnClick", function()
    GC:ToggleProposePanel()
end)
proposeBtn:SetScript("OnEnter", function()
    proposeBg:SetVertexColor(0.2, 0.45, 0.2, 1)
end)
proposeBtn:SetScript("OnLeave", function()
    proposeBg:SetVertexColor(0.15, 0.35, 0.15, 0.9)
end)
frame.proposeBtn = proposeBtn
```

- [ ] **Etape 2 : Creer le flyout "Proposer"**

Ajouter la fonction `GC:CreateProposePanel()` :

```lua
function GC:CreateProposePanel()
    if GC.proposePanel then return end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local panel = CreateFrame("Frame", "AgoraProposePanel", UIParent, template)
    panel:SetSize(380, 420)
    panel:SetPoint("BOTTOMLEFT", GC.mainFrame, "BOTTOMRIGHT", 6, 0)
    panel:SetFrameStrata("HIGH")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
    panel:Hide()

    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        panel:SetBackdropColor(0.06, 0.04, 0.01, 1.0)
        panel:SetBackdropBorderColor(0.6, 0.48, 0.18, 0.85)
    end

    -- Titre
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -14)
    title:SetText("|cffffd700" .. (L["UI_ProposeTitle"] or "Propose my services") .. "|r")

    -- Close
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- Toggle opt-in serveur
    local optInChk = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    optInChk:SetSize(22, 22)
    optInChk:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -44)
    local optInLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optInLbl:SetText(L["UI_BroadcastServer"] or "Broadcast to server")
    optInLbl:SetPoint("LEFT", optInChk, "RIGHT", 4, 0)
    optInChk:SetChecked(GC:GetServerOptIn())
    optInChk:SetScript("OnClick", function(self)
        local val = self:GetChecked()
        GC:SetServerOptIn(val)
        if val then
            GC:SendMyData()
        else
            GC:SendRemove()
        end
    end)
    panel.optInChk = optInChk

    -- Prix par defaut
    local priceLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceLbl:SetPoint("TOPLEFT", optInChk, "BOTTOMLEFT", 0, -14)
    priceLbl:SetText(L["UI_DefaultPrice"] or "Default price:")

    -- Dropdown prix : Gratuit / Tips / Montant fixe
    -- Pour simplifier en v1, 3 boutons radio
    local priceOptions = { "", "tips", "custom" }
    local priceLabels  = { L["UI_Free"] or "Free", "Tips", L["UI_Fixed"] or "Fixed" }
    local priceRadios  = {}
    local priceEditBox = nil

    local px = 20
    for i, opt in ipairs(priceOptions) do
        local rb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        rb:SetSize(18, 18)
        rb:SetPoint("TOPLEFT", panel, "TOPLEFT", px, -90)
        local rl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rl:SetText(priceLabels[i])
        rl:SetPoint("LEFT", rb, "RIGHT", 2, 0)
        rb:SetScript("OnClick", function()
            GC:SetPriceDefault(opt == "custom" and "" or opt)
            for _, r in ipairs(priceRadios) do r:SetChecked(false) end
            rb:SetChecked(true)
            if priceEditBox then
                priceEditBox:SetShown(opt == "custom")
            end
        end)
        table.insert(priceRadios, rb)
        px = px + rl:GetStringWidth() + 40
    end

    -- EditBox montant fixe
    local editBox = CreateFrame("EditBox", nil, panel)
    editBox:SetSize(80, 20)
    editBox:SetPoint("LEFT", priceRadios[3], "RIGHT", rl:GetStringWidth() + 6, 0)
    editBox:SetFontObject("GameFontNormalSmall")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false)
    editBox:SetMaxLetters(10)
    local editBg = editBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0, 0, 0, 0.5)
    editBox:SetScript("OnEnterPressed", function(self)
        GC:SetPriceDefault(self:GetText())
        self:ClearFocus()
    end)
    editBox:Hide()
    priceEditBox = editBox
    panel.priceEditBox = editBox

    -- Initialiser l'etat des radios
    local current = GC:GetPriceDefault()
    if current == "" then
        priceRadios[1]:SetChecked(true)
    elseif current == "tips" then
        priceRadios[2]:SetChecked(true)
    else
        priceRadios[3]:SetChecked(true)
        editBox:SetText(current)
        editBox:Show()
    end

    -- Note : configuration par recette (prix + compos) est dans un scroll ci-dessous
    -- Pour la v1, on affiche juste les recettes du joueur avec toggle provides_mats
    local scrollY = -140
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     panel, "TOPLEFT",  14, scrollY)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 14)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(340)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)
    panel.proposeScroll      = scroll
    panel.proposeScrollChild = scrollChild

    GC.proposePanel = panel
end

function GC:ToggleProposePanel()
    if not GC.proposePanel then GC:CreateProposePanel() end
    if GC.proposePanel:IsShown() then
        GC.proposePanel:Hide()
    else
        GC:RefreshProposePanel()
        GC.proposePanel:Show()
    end
end
```

- [ ] **Etape 3 : RefreshProposePanel — liste recettes avec toggle compos**

```lua
function GC:RefreshProposePanel()
    if not GC.proposePanel then return end
    local child = GC.proposePanel.proposeScrollChild
    -- Supprimer les anciens widgets
    for _, w in ipairs(child._rows or {}) do w:Hide() end
    child._rows = {}

    local myKey  = GC:GetMyKey()
    local myData = AgoraDB and AgoraDB.members and AgoraDB.members[myKey]
    if not myData then return end

    local y = 0
    for _, prof in ipairs(myData.professions or {}) do
        -- Header metier
        local hdr = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
        hdr:SetText("|cffffd700" .. (prof.name or "") .. "|r")
        table.insert(child._rows, hdr)
        y = y + 20

        for _, recipe in ipairs(prof.recipes or {}) do
            -- Ligne recette
            local row = CreateFrame("Frame", nil, child)
            row:SetSize(340, 22)
            row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            table.insert(child._rows, row)

            local rLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rLbl:SetPoint("LEFT", row, "LEFT", 0, 0)
            rLbl:SetText(recipe.name or "")

            -- Toggle "fournis les compos"
            local matsChk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            matsChk:SetSize(18, 18)
            matsChk:SetPoint("RIGHT", row, "RIGHT", -60, 0)
            local matsLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            matsLbl:SetText(L["UI_ProvidesCompos"] or "+Compos")
            matsLbl:SetPoint("RIGHT", matsChk, "LEFT", -2, 0)

            local myPrice = GC:GetMyPrice(prof.name, recipe.name)
            matsChk:SetChecked(myPrice.provides_mats)

            local capProf   = prof.name
            local capRecipe = recipe.name
            matsChk:SetScript("OnClick", function(self)
                local val = self:GetChecked()
                if val then
                    -- Valider les compos en sac avant d'activer
                    local reagents = GC:GetRecipeReagents(capProf, capRecipe)
                    if reagents then
                        local result = GC:ScanBags(reagents)
                        if not result.ok then
                            self:SetChecked(false)
                            local msg = L["UI_MissingMats"] or "Missing materials:"
                            for _, m in ipairs(result.missing) do
                                msg = msg .. "\n  " .. m.name .. " : " .. m.have .. "/" .. m.need
                            end
                            print("|cffff9900Agora:|r " .. msg)
                            return
                        end
                    end
                end
                local cur = GC:GetMyPrice(capProf, capRecipe)
                GC:SetMyPrice(capProf, capRecipe, cur.price, val)
                GC:SendMyData()
            end)

            y = y + 22
        end
        y = y + 6
    end

    child:SetHeight(math.max(y + 10, 1))
end
```

- [ ] **Etape 4 : Ajouter les strings de locale**

Dans `Locales/enUS.lua`, ajouter :

```lua
L["UI_ProposeServices"]  = "Propose my services"
L["UI_ProposeTitle"]     = "Propose my services"
L["UI_BroadcastServer"]  = "Broadcast to server"
L["UI_DefaultPrice"]     = "Default price:"
L["UI_Free"]             = "Free"
L["UI_Fixed"]            = "Fixed amount"
L["UI_Tips"]             = "tips"
L["UI_ProvidesCompos"]   = "+Compos"
L["UI_MissingMats"]      = "Missing materials:"
```

Dans `Locales/frFR.lua`, ajouter :

```lua
L["UI_ProposeServices"]  = "Proposer mes services"
L["UI_ProposeTitle"]     = "Proposer mes services"
L["UI_BroadcastServer"]  = "Diffuser sur le serveur"
L["UI_DefaultPrice"]     = "Prix par defaut :"
L["UI_Free"]             = "Gratuit"
L["UI_Fixed"]            = "Montant fixe"
L["UI_Tips"]             = "tips"
L["UI_ProvidesCompos"]   = "+Compos"
L["UI_MissingMats"]      = "Materiaux manquants :"
```

- [ ] **Etape 5 : Deploy et verification**

```bash
bash deploy.sh
```

Dans WoW : `/ag`
- Le bouton "Proposer mes services" est visible dans le footer
- Cliquer : le flyout s'ouvre
- Toggle "Broadcast to server" : active/desactive le broadcast (verifiable avec `/dump AgoraDB.settings.server_opt_in`)
- Les recettes du joueur sont listees avec le toggle "+Compos"
- Activer "+Compos" sans avoir les matériaux : message d'erreur avec les manquants
- Activer "+Compos" avec les matériaux en sac : s'active, un broadcast DATA est envoye

- [ ] **Etape 6 : Commit**

```bash
git add UI.lua Locales/enUS.lua Locales/frFR.lua
git commit -m "feat: Proposer mes services flyout with server opt-in and compos badge"
```

---

## Self-Review

**Spec coverage :**
- [x] Scan metiers via API WoW → Scanner.lua existant, pas modifie (deja fonctionnel)
- [x] Partage guilde automatique → Broadcast V2, canal GUILD conserve
- [x] Broadcast serveur opt-in → Task 3 (SendMyData dual-canal) + Task 9 (flyout toggle)
- [x] Verification CDs → Serialize V2 inclut cd_available par recette
- [x] Badge compos → Task 4 (ScanBags) + Task 9 (toggle avec validation)
- [x] RecipeDB flag important → Task 6
- [x] Heartbeat 5 min → Task 5
- [x] REMOVE au logout → Task 5
- [x] UI onglets metiers → heritage GuildForge, pas de changement necessaire
- [x] Sous-filtres categorie → heritage GuildForge BuildCatFilters
- [x] Toggle Importants separe → Task 7
- [x] Panel droit dual sections → Task 8
- [x] Prix crafter affiché → Task 8 (RenderCrafterRow)
- [x] Zone badge crafter → Task 8 (RenderCrafterRow)
- [x] Footer "Proposer" → Task 9

**Point d'attention Task 7 (supprimer vue Membres) :** la vue membres dans GuildForge implique des fonctions `RenderMembersView`, `BuildMembersMap`, etc. La Task 7 dit de supprimer le mode sans donner le code exact de ces fonctions — l'implementeur devra lire UI.lua et identifier le code a supprimer. Les fonctions a supprimer sont celles dans le bloc `if GC.viewMode == "membres"` de `GC:RefreshUI()`.

**Point d'attention Task 8 :** la structure `entry.crafters` dans BuildRecipeMap depend de la structure interne du code existant. L'implementeur doit d'abord lire comment `entry.crafters` est construit actuellement dans GuildForge (circa ligne 629 de UI.lua) avant d'adapter.

**Point d'attention Task 3 :** `GC:OnAssembled` est un nom hypothetique. L'implementeur doit verifier dans Broadcast.lua comment les chunks reassembles sont traites — la fonction s'appelle peut-etre differemment.
