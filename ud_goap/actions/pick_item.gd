extends UDGoapAction

class_name UDPickItemAction

var _item
var default_item_position: Vector3

func get_clazz(): return "UDPickItemAction"

func is_valid(state: Dictionary, actor) -> bool:
	if _item:
		if not WorldState.get(str(_item)+"is_picked_up"):
			if (actor._udgoap_state["current_money"] - actor._udgoap_state["current_bill"] >= _item.cost):
				if not _item.client_holding and not state.get(str(_item)+"is_picked_up"):
					return true
	return false

func _init(item):
	_item = item
	default_item_position = _item.position

func get_cost(_blackboard = null) -> float:
	return (_item.cost/_item.satisfaction) * (1 - _blackboard["actor"].preference[_item.type])

func get_preconditions() -> Dictionary:
	return {
		"position": default_item_position
	}

func get_effects(state: Dictionary) -> Dictionary:
	return {
		"current_satisfaction": _item.satisfaction,
		"current_bill": _item.cost,
		"current_bladder": _item.hydration,
		str(_item)+"is_picked_up": true
	}

func perform(actor, _delta, state = null) -> bool:
	#print(str(actor) + "pick:")
	#print(str(actor) + "item position: ", default_item_position)
	if not is_valid(state, actor):
		#print(str(actor) + " Não é valida")
		actor._current_motivation = null
		return false
	elif actor._udgoap_state["current_money"] - actor._udgoap_state["current_bill"] < _item.cost:
		#print(str(actor) + " TENTOU PEGAR E NAO TINHA DINHEIRO")
		actor._current_motivation = null
		return false
	
	#print(str(actor) + " PEGA ITEM")
	#print(str(actor) + " _item.cost: ", _item.cost)
	#print(str(actor) + " _item.satisfaction: ", _item.satisfaction)
	
	_item.picked_up(actor)
	WorldState._state.set(str(_item)+"is_picked_up", true)
	_item.scale *= 0.5
	
	#print(str(actor) + " bill antes: ", actor._udgoap_state["current_bill"])
	#print(str(actor) + " satisfaction antes: ", actor._udgoap_state["current_satisfaction"])
	
	actor._udgoap_state["current_satisfaction"] += _item.satisfaction
	actor._udgoap_state["current_bill"] += _item.cost
	actor._udgoap_state["current_bladder"] += _item.hydration
	actor.itens_list.push_back(_item)
	
	#print(str(actor) + " bill depois: ", actor._udgoap_state["current_bill"])
	#print(str(actor) + " satisfaction depois: ", actor._udgoap_state["current_satisfaction"])
	
	actor.going_already = false
	return true
