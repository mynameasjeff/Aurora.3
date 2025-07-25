GLOBAL_LIST_INIT_TYPED(rod_recipes, /datum/stack_recipe, list(
	new /datum/stack_recipe("grille", /obj/structure/grille, 2, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("floor-mounted catwalk", /obj/structure/lattice/catwalk/indoor, 4, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("grate, dark", /obj/structure/lattice/catwalk/indoor/grate, 1, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("grate, light", /obj/structure/lattice/catwalk/indoor/grate/light, 1, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("table frame", /obj/structure/table, 2, time = 10, one_per_turf = 1, on_floor = 1),
	new /datum/stack_recipe("mine track", /obj/structure/track, 3, time = 10, one_per_turf = TRUE, on_floor = TRUE),
	new /datum/stack_recipe("cane", /obj/item/cane, 1, time = 6),
	new /datum/stack_recipe("crowbar", /obj/item/crowbar, 1, time = 6),
	new /datum/stack_recipe("screwdriver", /obj/item/screwdriver, 1, time = 12),
	new /datum/stack_recipe("wrench", /obj/item/wrench, 1, time = 6),
	new /datum/stack_recipe("spade", /obj/item/shovel/spade, 2, time = 12),
	new /datum/stack_recipe("bolt", /obj/item/arrow, 1, time = 6),
	new /datum/stack_recipe("small animal trap", /obj/item/trap/animal, 6, time = 10),
	new /datum/stack_recipe("medium animal trap", /obj/item/trap/animal/medium, 12, time = 20)
))

/obj/item/stack/rods
	name = "metal rod"
	desc = "Some rods. Can be used for building, or something."
	singular_name = "metal rod"
	icon_state = "rods"
	obj_flags = OBJ_FLAG_CONDUCTABLE
	w_class = WEIGHT_CLASS_NORMAL
	force = 20
	throwforce = 15.0
	throw_speed = 5
	throw_range = 20
	drop_sound = 'sound/items/drop/metalweapon.ogg'
	pickup_sound = 'sound/items/pickup/metalweapon.ogg'
	matter = list(DEFAULT_WALL_MATERIAL = 937.5)
	recyclable = TRUE
	max_amount = 60
	attack_verb = list("hit", "bludgeoned", "whacked")
	lock_picking_level = 3
	stacktype = /obj/item/stack/rods
	icon_has_variants = TRUE

/obj/item/stack/rods/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Left-click this item in-hand to view its crafting menu."
	. += "Left-clicking with this item on a floor without any tiles will reinforce the floor."
	. += "Combining this item with glass sheets will create reinforced glass."

/obj/item/stack/rods/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Combining this item with glass sheets will create reinforced glass."
	. += "Using a welder on two metal rods will recombine them back into a steel sheet."

/obj/item/stack/rods/Destroy()
	. = ..()
	GC_TEMPORARY_HARDDEL

/obj/item/stack/rods/full/Initialize()
	. = ..()
	amount = max_amount
	update_icon()

/obj/item/stack/rods/cyborg
	name = "metal rod synthesizer"
	desc = "A device that makes metal rods."
	gender = NEUTER
	matter = null
	uses_charge = 1
	charge_costs = list(500)
	stacktype = /obj/item/stack/rods

/obj/item/stack/rods/New(var/loc, var/amount=null)
	..()
	recipes = GLOB.rod_recipes

/obj/item/stack/rods/attackby(obj/item/attacking_item, mob/user)
	..()
	if (attacking_item.iswelder())
		var/obj/item/weldingtool/WT = attacking_item

		if(get_amount() < 2)
			to_chat(user, SPAN_WARNING("You need at least two rods to do this."))
			return

		if(WT.use(0,user))
			var/obj/item/stack/material/steel/new_item = new(usr.loc)
			new_item.add_to_stacks(usr)
			for (var/mob/M in viewers(src))
				M.show_message(SPAN_NOTICE("[src] is shaped into metal by [user.name] with the weldingtool."), 3,
								SPAN_NOTICE("You hear welding."), 2)

			var/obj/item/stack/rods/R = src
			src = null
			var/replace = (user.get_inactive_hand()==R)
			R.use(2)
			if (!R && replace)
				user.put_in_hands(new_item)
		return

	if (istype(attacking_item, /obj/item/tape_roll))
		var/obj/item/stack/medical/splint/makeshift/new_splint = new(user.loc)
		new_splint.add_fingerprint(user)

		user.visible_message(SPAN_NOTICE("\The [user] constructs \a [new_splint] out of a [singular_name]."), \
				SPAN_NOTICE("You use make \a [new_splint] out of a [singular_name]."))
		use(1)
		return

	..()

/obj/item/stack/barbed_wire
	name = "barbed wire"
	desc = "A spiky length of wire."
	icon = 'icons/obj/barricades.dmi'
	icon_state = "barbed_wire"
	singular_name = "length"
	max_amount = 50
	w_class = WEIGHT_CLASS_SMALL
	matter = list(DEFAULT_WALL_MATERIAL = 937.5)
	attack_verb = list("hit", "whacked", "sliced")

/obj/item/stack/barbed_wire/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Left-click with this on a barricade to apply barbed wire to it."

/obj/item/stack/barbed_wire/half_full
	amount = 25

/obj/item/stack/barbed_wire/full
	amount = 50

/obj/item/stack/liquidbags
	name = "liquid bags"
	desc = "Bags filled with non-Newtonian liquid for the creation of barricades. These bags feel weird when you touch them: liquid to the gentle touch and the hardest thing you've felt if you smack them."
	singular_name = "liquid bag"
	max_amount = 50
	icon = 'icons/obj/barricades.dmi'
	icon_state = "liquidbags"
	w_class = WEIGHT_CLASS_SMALL
	matter = list(DEFAULT_WALL_MATERIAL = 650, MATERIAL_PHORON = 100, MATERIAL_PLASTEEL = 150)

/obj/item/stack/liquidbags/half_full
	amount = 25

/obj/item/stack/liquidbags/full
	amount = 50

/obj/item/stack/liquidbags/attack_self(mob/living/user)
	..()
	add_fingerprint(user)

	if(!isturf(user.loc))
		return

	if(istype(user.loc, /turf/space))
		to_chat(user, SPAN_WARNING("The liquidbag barricade must be constructed on a proper surface!"))
		return

	user.visible_message(SPAN_NOTICE("[user] starts assembling a liquidbag barricade."),
	SPAN_NOTICE("You start assembling a liquidbag barricade."))

	if(!do_after(user, 3 SECONDS, do_flags = DO_REPAIR_CONSTRUCT))
		return

	for(var/obj/O in user.loc) //Objects, we don't care about mobs. Turfs are checked elsewhere
		if(O.density)
			if(!(O.atom_flags & ATOM_FLAG_CHECKS_BORDER) || O.dir == user.dir)
				return

	var/build_stack = amount
	if(amount >= 5)
		build_stack = 5

	var/obj/structure/barricade/liquid/SB = new(user.loc, user, user.dir, build_stack)
	user.visible_message(SPAN_NOTICE("[user] assembles a liquidbag barricade."),
	SPAN_NOTICE("You assemble a liquidbag barricade."))
	SB.set_dir(user.dir)
	SB.add_fingerprint(user)
	use(build_stack)
