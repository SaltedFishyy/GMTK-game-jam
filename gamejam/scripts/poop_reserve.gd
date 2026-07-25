class_name PoopReserve
extends RefCounted

const CM_PER_STORAGE_POINT: float = 10.0

var max_reserve_cm: float = 0.0
var remaining_reserve_cm: float = 0.0


# 根据本轮开始时的储存量重新计算并装满Poop储备。
func reset(storage_capacity: int) -> void:
	max_reserve_cm = float(maxi(storage_capacity, 0)) * CM_PER_STORAGE_POINT
	remaining_reserve_cm = max_reserve_cm


# 消耗请求的厘米数，并返回本次实际允许推出的厘米数。
func consume(requested_cm: float) -> float:
	var safe_request: float = maxf(requested_cm, 0.0)
	var consumed_cm: float = minf(safe_request, remaining_reserve_cm)
	remaining_reserve_cm = maxf(remaining_reserve_cm - consumed_cm, 0.0)
	return consumed_cm


# 返回本轮最大储备厘米数。
func get_max_reserve_cm() -> float:
	return max_reserve_cm


# 返回本轮当前剩余储备厘米数。
func get_remaining_reserve_cm() -> float:
	return remaining_reserve_cm
