extends Control
@onready var health_label :Label= $Margin/Main/TopBar/LeftStack/Health/HealthLabel
@onready var biscuit_label :Label= $Margin/Main/TopBar/LeftStack/Biscuits/BiscuitLabel
@onready var round_label :Label = $Margin/Main/TopBar/RoundCenter/RoundLabel

func _ready() -> void:
	EventBus.PLAYER.took_damage.connect(on_player_damage)
	EventBus.PLAYER.update_biscuit_count.connect(on_biscuit_updated)
	EventBus.WAVE.new_round.connect(on_round_update)


func _on_start_buton_pressed() -> void:
	EventBus.UI.request_new_round.emit()

func on_player_damage(current:int,change):
	health_label.text = str(current)

func on_biscuit_updated(biscuits):
	biscuit_label.text = str(biscuits[BiscuitEconomy.Flavor.Plain])

func on_round_update(num):
	round_label.text = "Round " + str(num) + " / 20"
