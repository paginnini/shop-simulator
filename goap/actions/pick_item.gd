extends GoapAction

class_name PickItemAction


func get_clazz(): return "PickItemAction"

var _item
var default_item_position: Vector3


func is_valid(actor) -> bool:
	if _item and not WorldState.get(str(_item)+"is_picked_up") and (actor.current_money - actor.current_bill >= _item.cost) and not _item.client_holding:
		return true
	return false

func _init(item):
	_item = item
	default_item_position = _item.position


func get_cost(_blackboard  = null) -> float:
	return default_item_position.distance_to(_blackboard["position"]) * (1 - _blackboard["actor"].preference[_item.type])


func get_preconditions() -> Dictionary:
	return {
		"position": default_item_position
	}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects() -> Dictionary:
	return {
		"is_satisfied" : true,
		"done_shopping": true,
	}


func perform(actor, _delta) -> bool:
	#if _item: _item.highlight()
	
	if not is_valid(actor):
		print(str(actor) + " Não é valida")
		actor._current_goal = null
		#_item.unhighlight()
		return false
	elif actor.current_money - actor.current_bill < _item.cost:
		print(str(actor) + " TENTOU PEGAR E NAO TINHA DINHEIRO")
		actor._current_goal = null
		#actor._action_planner._actions.erase(self)
		#_item.unhighlight()
		return false
	
	print(str(actor) + " PEGA ITEM")
	print(str(actor) + " _item.cost: ", _item.cost)
	print(str(actor) + " _item.satisfaction: ", _item.satisfaction)
	
	_item.picked_up(actor)
	WorldState._state.set(str(_item)+"is_picked_up", true)
	_item.scale *= 0.5
	
	print(str(actor) + " bill antes: ", actor.current_bill)
	print(str(actor) + " satisfaction antes: ", actor.current_satisfaction)
	
	actor.current_satisfaction += _item.satisfaction
	actor.current_bill += _item.cost
	actor.current_bladder += _item.hydration
	actor.itens_list.push_back(_item)
	
	print(str(actor) + " bill depois: ", actor.current_bill)
	print(str(actor) + " satisfaction depois: ", actor.current_satisfaction)
	
	actor.going_already = false
	#_item.unhighlight()
	return true
