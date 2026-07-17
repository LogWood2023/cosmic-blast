extends Node


func _ready() -> void:
	var standard := GameManager.estimate_frenzy_uptime(10.0)
	var hell_eye := GameManager.estimate_frenzy_uptime(21.0)
	if standard < 0.25 or standard > 0.40:
		_fail("Standard frenzy uptime must remain in the 25%-40% range.")
		return
	if hell_eye < 0.50 or hell_eye > 0.70:
		_fail("Hell-eye frenzy uptime must remain in the 50%-70% range.")
		return
	if not is_equal_approx(GameManager.FRENZY_FIRE_RATE_MULT, 0.625) or not is_equal_approx(GameManager.FRENZY_DAMAGE_TAKEN_MULT, 0.6):
		_fail("Frenzy base multipliers no longer match balance targets.")
		return
	print("Frenzy uptime check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
