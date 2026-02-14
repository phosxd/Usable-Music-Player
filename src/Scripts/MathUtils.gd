class_name MathUtils extends Node


static func transfer_range_of_value(origin:Vector2, target:Vector2, value:float) -> float:
	return (target.x + (((value-origin.x) / (origin.y-origin.x)) * (target.y-target.x)))
