-- Gemeinsame Shop-Konfiguration (Server + Client).
-- Liegt in ReplicatedStorage, damit die Shop-UI (Punkt 3) dieselben Preise anzeigt.
-- Der Server prüft Käufe ausschließlich gegen diese Tabelle, nie gegen Client-Angaben.

export type ItemInfo = {
	displayName: string,
	price: number,
}

local ShopConfig = {}

ShopConfig.START_COINS = 100
ShopConfig.BUY_ITEM_EVENT = "BuyItem"

-- Schlüssel = Item-ID (wird so auch im DataStore und im Inventar-Ordner verwendet).
ShopConfig.ITEMS = {
	Wasser = { displayName = "Wasserflasche", price = 10 },
	Kaffee = { displayName = "Kaffee", price = 15 },
	Snack = { displayName = "Schokoriegel", price = 25 },
	Kanister = { displayName = "Benzinkanister", price = 50 },
} :: { [string]: ItemInfo }

function ShopConfig.getItem(itemId: string): ItemInfo?
	return ShopConfig.ITEMS[itemId]
end

return ShopConfig
