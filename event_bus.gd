extends Node

var ENEMY := Enemy.new()
var WAVE := Wave.new()
var UI := Ui.new()
var TOWER := _Tower.new()
var PLAYER := _Player.new()

## Event intended for or emitted by EnemyUnits
class Enemy:
	signal reached_end(strength:int)
	signal defeted(enemy_data)

## Event intended for or emitted by the WaveManager 
class Wave:
	signal new_round(round_number:int)
	signal round_ended(round_number:int)
	signal spawned(enemy,prefered_path)
	signal all_enemies_cleared
	signal no_more_enemies_to_spawn

## Event intended for or emitted by the UI
class Ui:
	signal request_new_tower(tower_data:Tower.TowerData,position)
	signal request_repair_tower(tower:Tower,amount)
	signal request_power_up_tower(tower:Tower,flavor)
	signal request_level_up_tower(tower:Tower)
	signal tower_selected(tower:Tower)
	signal request_new_round

## Event intended for or emitted by Towers
class _Tower:
	signal built(tower,pos)

## Event intended for or Emitted by the Player
class _Player:
	signal win_game
	signal lose_game
	signal took_damage(current_health,strength)
	signal build_tower_invalid(reason)
	signal earn_biscuits(biscuits:Dictionary)
	signal update_biscuit_count(biscuits:Dictionary)
	signal not_enogh_biscuits()
