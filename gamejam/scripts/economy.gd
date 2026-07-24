extends Node

var money_per_cm: float = 0.5
var break_value_multiplier: float = 0.8
var total_money: int = 0


# 根据原始长度和夹断次数计算本轮价值，但不修改总金钱。
func calculate_poop_value(length_cm: float, break_count: int = 0) -> int:
	var safe_length_cm: float = maxf(length_cm, 0.0)
	var safe_money_per_cm: float = maxf(money_per_cm, 0.0)
	var safe_break_count: int = maxi(break_count, 0)
	var safe_break_multiplier: float = clampf(
		break_value_multiplier,
		0.0,
		1.0
	)
	var final_value: float = (
		safe_length_cm
		* safe_money_per_cm
		* pow(safe_break_multiplier, safe_break_count)
	)
	return maxi(floori(final_value), 0)


# 计算折价后的本轮价值、加入总金钱，并返回实际获得的金钱。
func add_poop_value(length_cm: float, break_count: int = 0) -> int:
	var money_earned: int = calculate_poop_value(length_cm, break_count)
	total_money += money_earned
	return money_earned
