class_name V3EconomyRules
extends RefCounted
## Integer-only currency and Daily Deal helpers. UnifiedRules remains the
## compatibility façade for transition receipts and catalog-specific offers.

static func daily_price(snapshot: Dictionary, shop: String, item_id: String, price: int) -> int:
	var deal: Dictionary = snapshot.get("daily_deal", {})
	if str(deal.get("shop", "")) == shop and str(deal.get("id", "")) == item_id:
		return price * (10000 - int(deal.get("discount_bps", 2000))) / 10000
	return price

static func can_spend(profile: Dictionary, currency: String, amount: int) -> bool:
	return amount >= 0 and int(profile.get(currency, 0)) >= amount

static func spend(profile: Dictionary, currency: String, amount: int) -> bool:
	if not can_spend(profile, currency, amount): return false
	profile[currency] = int(profile.get(currency, 0)) - amount
	return true

static func credit(profile: Dictionary, currency: String, amount: int) -> void:
	profile[currency] = int(profile.get(currency, 0)) + maxi(0, amount)
