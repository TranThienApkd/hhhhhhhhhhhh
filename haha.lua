-- ZapHubCatalogIDs.lua
-- This script extracts the full list of item IDs that exist in the game (catalog),
-- not just the items currently owned in the player's inventory.
-- It walks the Directory tables under ReplicatedStorage.Library.Directory
-- and prints each item with its category and internal ID (uid).

local HttpService = game:GetService("HttpService")
local Directory = require(game:GetService("ReplicatedStorage").Library.Directory)

-- Helper to safely iterate over a directory table and collect items
local function collectFromCategory(catName, catTable)
    local list = {}
    for _, data in pairs(catTable) do
        if typeof(data) == "table" and data.id then
            table.insert(list, {
                category = catName,
                id = data.id,
                -- some entries also contain a "uid" field used by the server;
                -- we keep it if present, otherwise we store nil.
                uid = data.uid,
            })
        end
    end
    return list
end

-- Main collection routine
local function collectAllCatalogIDs()
    local all = {}
    -- The Directory table contains sub‑tables like Pets, Eggs, Charms, Enchant, etc.
    for catName, catTable in pairs(Directory) do
        if typeof(catTable) == "table" then
            local items = collectFromCategory(catName, catTable)
            for _, it in ipairs(items) do
                table.insert(all, it)
            end
        end
    end
    return all
end

local catalog = collectAllCatalogIDs()

print("--- Game Catalog ID List ---")
for _, it in ipairs(catalog) do
    local uidPart = it.uid and (" | UID:"..tostring(it.uid)) or ""
    print(string.format("[%-12s] ID:%s%s", it.category, it.id, uidPart))
end

-- Optional: send the list to a Discord webhook for remote viewing.
local webhook = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU" -- replace with your webhook or leave empty
if webhook ~= "" then
    local lines = {}
    for _, it in ipairs(catalog) do
        local uidStr = it.uid and (" | UID:"..tostring(it.uid)) or ""
        table.insert(lines, string.format("%s | ID:%s%s", it.category, it.id, uidStr))
    end
    local payload = {
        embeds = {{
            title = "Game Catalog ID List",
            description = table.concat(lines, "\n"),
            color = 0x00ff00,
        }}
    }
    local body = HttpService:JSONEncode(payload)
    pcall(function()
        request({
            Url = webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body,
        })
    end)
end

print("Done.")
