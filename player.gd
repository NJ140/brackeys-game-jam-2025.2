extends Node
# the disembodied player character

@export var health := 20
@export var biscuts := 10
@export var power_buiscuts:Dictionary[BiscutEconomy.Type,int] = {}
