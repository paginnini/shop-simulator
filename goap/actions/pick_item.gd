extends GoapAction

class_name PickItemAction


func get_clazz(): return "PickItemAction"

var _item
var default_item_position


func is_valid(blackboard) -> bool:
	if _item or not blackboard.get(str(_item)+"is_picked_up"):
		return true
	return false

func _init(item):
	_item = item
	default_item_position = _item.position


func get_cost(_blackboard  = null) -> float:
	if _blackboard["actor"].ud_goap:
		return 0.0
	else:
		return default_item_position.distance_to(_blackboard["position"]) * (1 - _blackboard["actor"].preference[_item.type])


func get_preconditions(_blackboard = null) -> Dictionary:
	return {}

#TROCAR ESSES EFEITOS POR REAIS
func get_effects(_blackboard = null) -> Dictionary:
	var a = false
	if _item.cost + _blackboard["bill"] > _blackboard["money"]:
		a = true
	return {
		"satisfaction" : _item.satisfaction,
		"is_in_debt": a,
		"bill": _item.cost,
		"position": default_item_position,
	}


func perform(actor, _delta, agent) -> bool:
	if _item: _item.highlight()
	if default_item_position.distance_to(actor.position) <= actor.do_distance:
		if not is_valid(WorldState._state): 
			agent._current_goal = null
			return false
		elif actor._state["money"] - actor._state["bill"] < _item.cost:
			print("TENTOU PEGAR E NAO TINHA DINHEIRO")
			agent._current_goal = null
			agent._action_planner._actions.erase(self)
			return false
		
		print("TESTE")
		
		_item.picked_up(actor)
		WorldState._state.set(str(_item)+"is_picked_up", true)
		_item.scale *= 0.5
		
		actor._state.set("satisfaction", actor._state.get("satisfaction") + _item.satisfaction)
		actor._state["bill"] += _item.cost
		actor._state["bladder"] += _item.hydration
		actor.itens_list.push_back(_item)
		
		actor.going_already = false
		
		return true
	else:
		#print("não ta perto", actor.going_already)
		if not actor.going_already:
			#print("-------------------começa a ir pra: ", _item.position)
			actor.navigation_agent_3d.set_target_position(default_item_position)
			actor.going_already = true
	return false
