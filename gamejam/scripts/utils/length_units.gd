class_name LengthUnits
extends RefCounted

const PIXELS_PER_CM: float = 1.0
const CENTIMETERS_PER_FOOT: float = 30.48


static func pixels_to_cm(pixels: float) -> float:
	return pixels / PIXELS_PER_CM


static func cm_to_pixels(centimeters: float) -> float:
	return centimeters * PIXELS_PER_CM


static func cm_to_feet(centimeters: float) -> float:
	return centimeters / CENTIMETERS_PER_FOOT


static func feet_to_cm(feet: float) -> float:
	return feet * CENTIMETERS_PER_FOOT


static func feet_to_pixels(feet: float) -> float:
	return cm_to_pixels(feet_to_cm(feet))
