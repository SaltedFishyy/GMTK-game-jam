extends Node

var money_per_cm: float = 0.5
var total_money: int = 0


# 根据原始长度与完整度结果计算本轮价值，但不修改总金钱。
func calculate_poop_value(
	length_cm: float,
	integrity: int = 5,
	completed_double_qte: bool = false
) -> int:
	var safe_length_cm: float = maxf(length_cm, 0.0)
	var safe_money_per_cm: float = maxf(money_per_cm, 0.0)
	var value_multiplier: float = _get_integrity_value_multiplier(
		integrity,
		completed_double_qte
	)
	var final_value: float = (
		safe_length_cm
		* safe_money_per_cm
		* value_multiplier
	)
	return maxi(floori(final_value), 0)


# 计算本轮价值、加入总金钱，并返回实际获得的金钱。
func add_poop_value(
	length_cm: float,
	integrity: int = 5,
	completed_double_qte: bool = false
) -> int:
	var money_earned: int = calculate_poop_value(
		length_cm,
		integrity,
		completed_double_qte
	)
	total_money += money_earned
	return money_earned


# 返回当前完整度对应的最终价值倍率。
func _get_integrity_value_multiplier(
	integrity: int,
	completed_double_qte: bool
) -> float:
	var safe_integrity: int = clampi(integrity, 0, 10)
	if safe_integrity <= 4:
		return 0.8
	if safe_integrity >= 8 and completed_double_qte:
		return 1.2

	return 1.0
