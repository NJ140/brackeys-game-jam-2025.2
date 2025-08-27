extends Node

var ENEMY = Enemy.new()
var WAVE = Wave.new()
var UI = Ui.new()
var TOWER = _Tower.new()

class Enemy:
	signal reached_end(strength:int)
	signal defeted(enemy_data)

class Wave:
	signal new_round(round_number)
	signal round_ended(round_number)
	signal spawned(enemy,prefered_path)

class Ui:
	signal new_focus(element)

class _Tower:
	signal request_new_tower(tower_data,position)
