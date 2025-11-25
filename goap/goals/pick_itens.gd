extends GoapGoal

class_name PickItensGoal

func get_clazz(): return "PickItensGoal"


func is_valid(actor) -> bool:
	var all_elements = WorldState.get_elements("item")
	#print("all elements: ", all_elements)
	if actor._state["satisfaction"] >= actor._state["satisfaction_limit"]:
		return false
	
	var can_buy_more = false
	for i in all_elements:
		#print(i.client_holding)
		if not i.client_holding:
			#print("TESTE", actor._state["money"])
			if actor._state["money"] - actor._state["bill"] >= i.cost:
				return true
	#print(WorldState.get_state(str(actor)+"hunger_limit"), WorldState.get_state(str(actor)+"thirst_limit"))
	return can_buy_more

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 6

func get_desired_state(actor) -> Dictionary:
	return {
		"satisfaction": actor.satisfaction_limit, 
	}
