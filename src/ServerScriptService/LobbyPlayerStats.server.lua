local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local statsStore = DataStoreService:GetDataStore("BidShowPlayerStatsV1")
local modules = ReplicatedStorage:WaitForChild("Modules")
local signSkinConfig = require(modules:WaitForChild("SignSkinConfig"))
local trailConfig = require(modules:WaitForChild("TrailConfig"))

local function buildCatalog(config)
	local catalog = {}
	for _, item in config do
		catalog[item.ModelName] = item
	end
	return catalog
end

local categories = {
	SignSkin = {
		catalog = buildCatalog(signSkinConfig),
		ownedFolderName = "OwnedSignSkins",
		equippedValueName = "EquippedSignSkin",
	},
	Trail = {
		catalog = buildCatalog(trailConfig),
		ownedFolderName = "OwnedTrails",
		equippedValueName = "EquippedTrail",
	},
}

local purchaseFunction = ReplicatedStorage:FindFirstChild("ShopPurchaseFunction")
if not purchaseFunction then
	purchaseFunction = Instance.new("RemoteFunction")
	purchaseFunction.Name = "ShopPurchaseFunction"
	purchaseFunction.Parent = ReplicatedStorage
end

local purchaseAlert = ReplicatedStorage:FindFirstChild("ShopPurchaseAlert")
if not purchaseAlert then
	purchaseAlert = Instance.new("RemoteEvent")
	purchaseAlert.Name = "ShopPurchaseAlert"
	purchaseAlert.Parent = ReplicatedStorage
end

local developerProductAmounts = {
	[3611489162] = 2000,
	[3611489310] = 7000,
	[3611489343] = 20000,
}

local loadedPlayers = {}
local loadingPlayers = {}
local purchaseLocks = {}
local saveLocks = {}
local saveResults = {}
local requestHistory = {}
local sessionStartedAt = {}
local processedReceipts = {}
local SHOP_REQUEST_LIMIT = 12
local SHOP_REQUEST_WINDOW = 60

local function getOrCreateValue(parent, className, name)
	local value = parent:FindFirstChild(name)
	if value then
		return value
	end

	value = Instance.new(className)
	value.Name = name
	value.Parent = parent
	return value
end

local function createOwnedValue(folder, modelName)
	local owned = folder:FindFirstChild(modelName)
	if owned then
		return owned
	end

	owned = Instance.new("BoolValue")
	owned.Name = modelName
	owned.Value = true
	owned.Parent = folder
	return owned
end

local function serializeOwned(folder)
	local owned = {}
	for _, value in folder:GetChildren() do
		if value:IsA("BoolValue") and value.Value then
			owned[value.Name] = true
		end
	end
	return owned
end

local function loadOwned(folder, savedOwned, catalog)
	if typeof(savedOwned) ~= "table" then
		return
	end

	for key, value in savedOwned do
		local modelName = if typeof(key) == "number" then value else key
		local isOwned = if typeof(key) == "number" then true else value == true
		if isOwned and typeof(modelName) == "string" and catalog[modelName] then
			createOwnedValue(folder, modelName)
		end
	end
end

local function loadProcessedReceipts(savedReceipts)
	local state = {
		list = {},
		set = {},
	}
	if typeof(savedReceipts) ~= "table" then
		return state
	end

	local startIndex = math.max(1, #savedReceipts - 99)
	for index = startIndex, #savedReceipts do
		local purchaseId = tostring(savedReceipts[index])
		if purchaseId ~= "" and not state.set[purchaseId] then
			state.set[purchaseId] = true
			table.insert(state.list, purchaseId)
		end
	end
	return state
end

local function recordProcessedReceipt(state, purchaseId)
	state.set[purchaseId] = true
	table.insert(state.list, purchaseId)
	if #state.list > 100 then
		local expiredId = table.remove(state.list, 1)
		state.set[expiredId] = nil
		return expiredId
	end
	return nil
end

local function getPlayerDataValues(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	return {
		wins = leaderstats:FindFirstChild("Win"),
		money = leaderstats:FindFirstChild("Money"),
		ownedSignSkins = player:FindFirstChild("OwnedSignSkins"),
		ownedTrails = player:FindFirstChild("OwnedTrails"),
		equippedSignSkin = player:FindFirstChild("EquippedSignSkin"),
		equippedTrail = player:FindFirstChild("EquippedTrail"),
	}
end

local function savePlayer(player)
	if not loadedPlayers[player] then
		return false
	end

	if saveLocks[player] then
		local activeLock = saveLocks[player]
		while saveLocks[player] == activeLock do
			task.wait()
		end
		return saveResults[player] == true
	end

	saveLocks[player] = {}
	local values = getPlayerDataValues(player)
	if not values or not values.money or not values.ownedSignSkins or not values.ownedTrails then
		saveResults[player] = false
		saveLocks[player] = nil
		return false
	end

	local snapshot = {
		Wins = if values.wins then values.wins.Value else 0,
		Money = values.money.Value,
		Points = values.money.Value,
		OwnedSignSkins = serializeOwned(values.ownedSignSkins),
		OwnedTrails = serializeOwned(values.ownedTrails),
		EquippedSignSkin = if values.equippedSignSkin then values.equippedSignSkin.Value else "",
		EquippedTrail = if values.equippedTrail then values.equippedTrail.Value else "",
		ProcessedReceipts = table.clone(processedReceipts[player].list),
		SessionStartedAt = sessionStartedAt[player],
	}

	local success, saveError
	for attempt = 1, 3 do
		local staleSession = false
		success, saveError = pcall(function()
			statsStore:UpdateAsync(`player_{player.UserId}`, function(currentData)
				currentData = if typeof(currentData) == "table" then currentData else {}
				local storedSessionStart = tonumber(currentData.SessionStartedAt) or 0
				if storedSessionStart > snapshot.SessionStartedAt then
					staleSession = true
					return nil
				end
				for key, value in snapshot do
					currentData[key] = value
				end
				return currentData
			end)
		end)
		if staleSession then
			saveResults[player] = false
			saveLocks[player] = nil
			warn("[LobbyStats] Rejected stale session save", player.Name)
			return false
		elseif success then
			saveResults[player] = true
			saveLocks[player] = nil
			return true
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end

	warn("[LobbyStats] Failed to save", player.Name, saveError)
	saveResults[player] = false
	saveLocks[player] = nil
	return false
end

local function setupPlayer(player)
	if loadedPlayers[player] or loadingPlayers[player] then
		return
	end

	loadingPlayers[player] = true
	sessionStartedAt[player] = DateTime.now().UnixTimestampMillis
	player:SetAttribute("ShopDataLoaded", false)
	player:SetAttribute("ShopDataLoadFailed", false)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local wins = getOrCreateValue(leaderstats, "IntValue", "Win")
	local money = leaderstats:FindFirstChild("Money")
	if not money then
		local legacyPoints = leaderstats:FindFirstChild("Points")
		if legacyPoints and legacyPoints:IsA("IntValue") then
			legacyPoints.Name = "Money"
			money = legacyPoints
		else
			money = Instance.new("IntValue")
			money.Name = "Money"
			money.Parent = leaderstats
		end
	end

	local ownedSignSkins = getOrCreateValue(player, "Folder", "OwnedSignSkins")
	local ownedTrails = getOrCreateValue(player, "Folder", "OwnedTrails")
	local equippedSignSkin = getOrCreateValue(player, "StringValue", "EquippedSignSkin")
	local equippedTrail = getOrCreateValue(player, "StringValue", "EquippedTrail")

	local success, data
	for attempt = 1, 3 do
		success, data = pcall(function()
			return statsStore:GetAsync(`player_{player.UserId}`)
		end)
		if success or not player.Parent then
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end

	if success and data ~= nil and typeof(data) ~= "table" then
		warn("[LobbyStats] Invalid saved data", player.Name, typeof(data))
		player:SetAttribute("ShopDataLoadFailed", true)
		loadingPlayers[player] = nil
		return
	elseif success and typeof(data) == "table" and player.Parent then
		wins.Value = math.max(0, tonumber(data.Wins) or 0)
		money.Value = math.max(0, tonumber(data.Money) or tonumber(data.Points) or 0)
		loadOwned(ownedSignSkins, data.OwnedSignSkins, categories.SignSkin.catalog)
		loadOwned(ownedTrails, data.OwnedTrails, categories.Trail.catalog)

		local savedSignSkin = tostring(data.EquippedSignSkin or "")
		local savedTrail = tostring(data.EquippedTrail or "")
		equippedSignSkin.Value = if ownedSignSkins:FindFirstChild(savedSignSkin) then savedSignSkin else ""
		equippedTrail.Value = if ownedTrails:FindFirstChild(savedTrail) then savedTrail else ""
		processedReceipts[player] = loadProcessedReceipts(data.ProcessedReceipts)
	elseif not success then
		warn("[LobbyStats] Failed to load", player.Name, data)
		player:SetAttribute("ShopDataLoadFailed", true)
		loadingPlayers[player] = nil
		return
	end

	if player.Parent then
		processedReceipts[player] = processedReceipts[player] or loadProcessedReceipts(nil)
		loadedPlayers[player] = true
		player:SetAttribute("ShopDataLoaded", true)
	end
	loadingPlayers[player] = nil
end

local function isShopRequestAllowed(player)
	local now = os.clock()
	local history = requestHistory[player]
	if not history then
		history = {}
		requestHistory[player] = history
	end

	while history[1] and now - history[1] >= SHOP_REQUEST_WINDOW do
		table.remove(history, 1)
	end

	if #history >= SHOP_REQUEST_LIMIT then
		return false
	end
	table.insert(history, now)
	return true
end

local function makeResult(success, status, message, values, modelName)
	local equippedValue = values.equipped
	return {
		Success = success,
		Status = status,
		Message = message,
		ModelName = modelName,
		Owned = values.owned:FindFirstChild(modelName) ~= nil,
		Equipped = equippedValue.Value == modelName,
		Money = values.money.Value,
	}
end

local function processPurchase(player, categoryName, modelName)
	if player:GetAttribute("ShopDataLoadFailed") then
		return {
			Success = false,
			Message = "Shop data could not be loaded. Rejoin and try again.",
		}
	end

	if not loadedPlayers[player] then
		return {
			Success = false,
			Message = "Shop data is still loading.",
		}
	end

	local category = categories[categoryName]
	local item = category and category.catalog[modelName]
	if not category or not item then
		return {
			Success = false,
			Message = "That item is not available.",
		}
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local values = {
		money = leaderstats and leaderstats:FindFirstChild("Money"),
		owned = player:FindFirstChild(category.ownedFolderName),
		equipped = player:FindFirstChild(category.equippedValueName),
	}
	if not values.money or not values.owned or not values.equipped then
		return {
			Success = false,
			Message = "Shop data is unavailable.",
		}
	end

	local ownedValue = values.owned:FindFirstChild(modelName)
	if not ownedValue then
		if values.money.Value < item.Price then
			return makeResult(false, "InsufficientFunds", "Not enough Money.", values, modelName)
		end

		values.money.Value -= item.Price
		ownedValue = createOwnedValue(values.owned, modelName)
		if not savePlayer(player) then
			values.money.Value += item.Price
			ownedValue:Destroy()
			return makeResult(false, "SaveFailed", "Could not save purchase. Try again.", values, modelName)
		end

		return makeResult(true, "Purchased", "Purchased! Click again to Equip", values, modelName)
	end

	local previousEquipped = values.equipped.Value
	if previousEquipped == modelName then
		values.equipped.Value = ""
	else
		values.equipped.Value = modelName
	end

	if not savePlayer(player) then
		values.equipped.Value = previousEquipped
		return makeResult(false, "SaveFailed", "Could not save equipment. Try again.", values, modelName)
	end

	if values.equipped.Value == modelName then
		return makeResult(true, "Equipped", "Equipped!", values, modelName)
	end
	return makeResult(true, "Unequipped", "Unequipped!", values, modelName)
end

purchaseFunction.OnServerInvoke = function(player, categoryName, modelName)
	if not isShopRequestAllowed(player) then
		return {
			Success = false,
			Message = "Please wait before trying again.",
		}
	end

	if purchaseLocks[player] then
		return {
			Success = false,
			Message = "Purchase already in progress.",
		}
	end

	purchaseLocks[player] = true
	local success, result = pcall(processPurchase, player, categoryName, modelName)
	purchaseLocks[player] = nil

	if not success then
		warn("[LobbyShop] Purchase failed", player.Name, result)
		return {
			Success = false,
			Message = "Something went wrong. Try again.",
		}
	end
	return result
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local amount = developerProductAmounts[receiptInfo.ProductId]
	if not amount then
		warn("[LobbyShop] Unknown developer product", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player or not loadedPlayers[player] or purchaseLocks[player] then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptState = processedReceipts[player]
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if receiptState.set[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local values = getPlayerDataValues(player)
	if not values or not values.money then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	purchaseLocks[player] = true
	values.money.Value += amount
	local expiredReceiptId = recordProcessedReceipt(receiptState, purchaseId)
	local saved = savePlayer(player)
	if not saved then
		values.money.Value -= amount
		receiptState.set[purchaseId] = nil
		if receiptState.list[#receiptState.list] == purchaseId then
			table.remove(receiptState.list)
		end
		if expiredReceiptId then
			table.insert(receiptState.list, 1, expiredReceiptId)
			receiptState.set[expiredReceiptId] = true
		end
		purchaseLocks[player] = nil
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	purchaseLocks[player] = nil

	purchaseAlert:FireClient(player, `Purchased {amount}P!`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	while purchaseLocks[player] do
		task.wait()
	end
	savePlayer(player)
	loadedPlayers[player] = nil
	loadingPlayers[player] = nil
	purchaseLocks[player] = nil
	saveLocks[player] = nil
	saveResults[player] = nil
	requestHistory[player] = nil
	sessionStartedAt[player] = nil
	processedReceipts[player] = nil
end)

game:BindToClose(function()
	local remaining = 0
	for _, player in Players:GetPlayers() do
		remaining += 1
		task.spawn(function()
			while purchaseLocks[player] do
				task.wait()
			end
			savePlayer(player)
			remaining -= 1
		end)
	end

	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do
		task.wait()
	end
end)
