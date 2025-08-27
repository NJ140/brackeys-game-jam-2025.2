extends CharacterBody2D

signal on_damage(i:int)

func take_damage(i:int):
	on_damage.emit(i)
