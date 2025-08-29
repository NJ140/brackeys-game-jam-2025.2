extends PanelContainer


func _on_button_pressed() -> void:
	EventBus.WAVE.new_round.emit()
