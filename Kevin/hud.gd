extends Control


func _on_start_buton_pressed() -> void:
	EventBus.WAVE.new_round.emit()
