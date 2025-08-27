class_name Projectile extends Area2D
enum Layer{
	NONE = 0,
	TOWER = 1 << 0,
	ENEMY = 1 << 1,
}

@export var speed :float = 1
@export var direction:Vector2 = position
@export var damage:int = 0
@export var target_layer:= Layer.NONE
var hit := false

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func set_target_layer(layer:int):
	collision_layer = layer

func _on_body_entered(body: Node2D) -> void:
	if hit: return
	hit = true
	if "take_damage" in body:
		body.take_damage(damage)
	elif body.has_meta("IsEnemy"):
		var enemy = body.get_parent()
		enemy.take_damage(damage)
	queue_free()


func _on_despawn_timeout() -> void:
	queue_free()
