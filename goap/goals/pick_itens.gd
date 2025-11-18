extends GoapGoal

class_name PickItensGoal

func get_clazz(): return "PickItensGoal"


func is_valid(actor) -> bool:
	var all_elements = WorldState.get_elements("food") + WorldState.get_elements("drink") + WorldState.get_elements("product")
	#print("all elements: ", all_elements)
	var can_buy_more = false
	for i in all_elements:
		#print(i.client_holding)
		if not i.client_holding:
			if WorldState.get_state(str(actor)+i.limit_ref) == false:
				if actor.money - actor.bill > i.cost:
					can_buy_more = true
	#print(WorldState.get_state(str(actor)+"hunger_limit"), WorldState.get_state(str(actor)+"thirst_limit"))
	return can_buy_more and not (WorldState.get_state(str(actor)+"hunger_limit") 
							and WorldState.get_state(str(actor)+"thirst_limit") 
							and WorldState.get_state(str(actor)+"hygiene_limit")
							)

# generic has lower priority compared to other goals
func priority(actor) -> int:
	return 6

func get_desired_state(actor) -> Dictionary:
	return {
		str(actor)+"hunger_limit": true,
		str(actor)+"thirst_limit": true,
		str(actor)+"hygiene_limit": true,
		str(actor)+"hunger": actor.food_limit,
		str(actor)+"thirst": actor.drink_limit,
		str(actor)+"hygiene": actor.product_limit
	}
