extends Node

var money_per_cm: float = 0.5
var total_money: int = 0


# 根据原始长度计算本轮价值，但不修改总金钱。
func calculate_poop_value(length_cm: float) -> int:
	var safe_length_cm: float = maxf(length_cm, 0.0)
	var safe_money_per_cm: float = maxf(money_per_cm, 0.0)
	return maxi(floori(safe_length_cm * safe_money_per_cm), 0)


# 计算本轮价值、加入总金钱，并返回实际获得的金钱。
func add_poop_value(length_cm: float) -> int:
	var money_earned: int = calculate_poop_value(length_cm)
	total_money += money_earned
	return money_earned
