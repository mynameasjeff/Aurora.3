/*
Overview:
	Used to create objects that need a per step proc call.  Default definition of 'New()'
	stores a reference to src machine in global 'machines list'.  Default definition
	of 'Del' removes reference to src machine in global 'machines list'.

Class Variables:
	use_power (num)
		current state of auto power use.
		Possible Values:
			0 -- no auto power use
			1 -- machine is using power at its idle power level
			2 -- machine is using power at its active power level

	active_power_usage (num)
		Value for the amount of power to use when in active power mode

	idle_power_usage (num)
		Value for the amount of power to use when in idle power mode

	power_channel (num)
		What channel to draw from when drawing power for power mode
		Possible Values:
			AREA_USAGE_EQUIP:0 -- Equipment Channel
			AREA_USAGE_LIGHT:2 -- Lighting Channel
			AREA_USAGE_ENVIRON:3 -- Environment Channel

	component_parts (list)
		A list of component parts of machine used by frame based machines.

	panel_open (num)
		Whether the panel is open

	uid (num)
		Unique id of machine across all machines.

	gl_uid (global num)
		Next uid value in sequence

	stat (bitflag)
		Machine status bit flags.
		Possible bit flags:
			BROKEN:1 -- Machine is broken
			NOPOWER:2 -- No power is being supplied to machine.
			POWEROFF:4 -- tbd
			MAINT:8 -- machine is currently under going maintenance.
			EMPED:16 -- temporary broken by EMP pulse

Class Procs:
	New()                     'game/machinery/machine.dm'

	Destroy()                     'game/machinery/machine.dm'

	powered(chan = AREA_USAGE_EQUIP)         'modules/power/power_usage.dm'
		Checks to see if area that contains the object has power available for power
		channel given in 'chan'.

	use_power_oneoff(amount, chan=AREA_USAGE_EQUIP, autocalled)   'modules/power/power_usage.dm'
		Deducts 'amount' from the power channel 'chan' of the area that contains the object.
		This is not a continuous draw, but rather will be cleared after one APC update.

	power_change()               'modules/power/power_usage.dm'
		Called by the area that contains the object when ever that area under goes a
		power state change (area runs out of power, or area channel is turned off).

	RefreshParts()               'game/machinery/machine.dm'
		Called to refresh the variables in the machine that are contributed to by parts
		contained in the component_parts list. (example: glass and material amounts for
		the autolathe)

		Default definition handles power usage only (all parts contribute based on energy_rating).

	assign_uid()               'game/machinery/machine.dm'
		Called by machine to assign a value to the uid variable.

	process()                  'game/machinery/machine.dm'
		Called by the 'master_controller' once per game tick for each machine that is listed in the 'machines' list.


	Compiled by Aygar
*/

/obj/machinery
	name = "machinery"
	icon = 'icons/obj/stationobjs.dmi'
	w_class = WEIGHT_CLASS_GIGANTIC
	layer = STRUCTURE_LAYER
	init_flags = INIT_MACHINERY_PROCESS_SELF
	pass_flags_self = PASSMACHINE | LETPASSCLICKS

	/// Controlled by a bitflag, differentiates between a few different possible states including the machine being broken or unpowered.
	/// See code/__defines/machinery.dm for the possible states.
	var/stat = 0
	/// Is this machine emagged?
	var/emagged = 0

	/// In what power state is this machine? Possible states include being off, idle, or active - see code/__defines/machinery.dm.
	/// You should not be modifying this directly! Use the procs in power_usage.dm.
	var/use_power = POWER_USE_IDLE
	var/internal = FALSE
	/// How much power should this be drawing in the idle power state?
	var/idle_power_usage = 0
	/// How much power should this be drawing in the active power state?
	var/active_power_usage = 0
	var/power_init_complete = FALSE
	/// What power channel does this fall under in APCs? Possible channels include: AREA_USAGE_EQUIP, AREA_USAGE_ENVIRON or AREA_USAGE_LIGHT
	var/power_channel = AREA_USAGE_EQUIP

	/* List of types that should be spawned as component_parts for this machine.
		Structure:
			type -> num_objects

		num_objects is optional, and will be treated as 1 if omitted.

		example:
		component_types = list(
			/obj/foo/bar,
			/obj/baz = 2
		)
	*/
	var/list/component_types
	/// List of all the parts used to build it, if made from certain kinds of frames.
	var/list/component_parts = null
	/// Use the generic power rating mechanics for parts, or bespoke.
	var/parts_power_mgmt = TRUE
	/// The total power rating of all parts serves as a power usage multiplier.
	var/parts_power_usage = 0

	var/uid
	var/panel_open = 0
	var/global/gl_uid = 1
	var/interact_offline = 0 // Can the machine be interacted with while de-powered.
	var/printing = 0 // Is this machine currently printing anything?
	var/list/processing_parts // Component parts queued for processing by the machine. Expected type: `/obj/item/stock_parts` Unused currently

	/// Bitflag. What is being processed. One of `MACHINERY_PROCESS_*`.
	var/processing_flags

	var/clicksound //played sound on usage
	var/clickvol = 40 //volume
	var/obj/item/device/assembly/signaler/signaler // signaller attached to the machine
	var/obj/effect/overmap/visitable/linked // overmap sector the machine is linked to

	/// Manufacturer of this machine. Used for TGUI themes, when you have a base type and subtypes with different themes (like the coffee machine).
	/// Pass the manufacturer in ui_data and then use it in the UI.
	var/manufacturer = null

/obj/machinery/feedback_hints(mob/user, distance, is_adjacent)
	. = list()
	if(signaler && is_adjacent)
		. += SPAN_WARNING("\The [src] has a hidden signaler attached to it. You might or might not notice this.")
	// Still needs some work- must be able to be distinguish between thinobjectsgs that are anchored that can be casually
	// unanchored (i.e. vending machines) vs. objects that are anchored but require other steps to unanchor (i.e. airlocks).
	/*
	if(anchored)
		. += SPAN_NOTICE("\The [src] is anchored to the floor by a couple of <b>bolts</b>.")
	*/

/obj/machinery/Initialize(mapload, d = 0, populate_components = TRUE, is_internal = FALSE)
	//Stupid macro used in power usage
	CAN_BE_REDEFINED(TRUE)

	. = ..()
	if(d)
		set_dir(d)

	if(init_flags & INIT_MACHINERY_PROCESS_ALL)
		START_PROCESSING_MACHINE(src, init_flags & INIT_MACHINERY_PROCESS_ALL)
	SSmachinery.machinery += src // All machines should be in machinery.

	if (populate_components && component_types)
		component_parts = list()
		for (var/type in component_types)
			var/count = component_types[type]
			if(ispath(type, /obj/item/stack))
				if(isnull(count))
					count = 1
				component_parts += new type(src, count)
			else
				if(count > 1)
					for (var/i in 1 to count)
						component_parts += new type(src)
				else
					component_parts += new type(src)

		if(component_parts.len)
			RefreshParts()

/obj/machinery/Destroy()
	//Stupid macro used in power usage
	CAN_BE_REDEFINED(TRUE)

	STOP_PROCESSING_MACHINE(src, MACHINERY_PROCESS_ALL)
	SSmachinery.machinery -= src

	//Clear the component parts
	//If the components are inside the machine, delete them, otherwise we assume they were dropped to the ground during deconstruction,
	//and were not removed from the component_parts list by deconstruction code
	if(component_parts)
		for(var/atom/A in component_parts)
			if(A.loc == src)
				qdel(A)
	component_parts = null

	return ..()

// /obj/machinery/proc/process_all()
// 	/* Uncomment this if/when you need component processing
// 	if(processing_flags & MACHINERY_PROCESS_COMPONENTS)
// 		for(var/thing in processing_parts)
// 			var/obj/item/stock_parts/part = thing
// 			if(part.machine_process(src) == PROCESS_KILL)
// 				part.stop_processing() */

// 	if((processing_flags & MACHINERY_PROCESS_SELF))
// 		. = process()
// 		if(. == PROCESS_KILL)
// 			STOP_PROCESSING_MACHINE(src, MACHINERY_PROCESS_SELF)

/obj/machinery/process(seconds_per_tick)
	return PROCESS_KILL

/obj/machinery/emp_act(severity)
	. = ..()
	if(use_power && stat == 0)
		use_power_oneoff(7500/severity)

		var/obj/effect/overlay/pulse2 = new(src.loc)
		pulse2.icon = 'icons/effects/effects.dmi'
		pulse2.icon_state = "empdisable"
		pulse2.name = "emp sparks"
		pulse2.anchored = 1
		pulse2.set_dir(pick(GLOB.cardinals))

		QDEL_IN(pulse2, 10)

/obj/machinery/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(25))
				qdel(src)
				return
	return

/**
 * Check to see if the machine is operable
 *
 * * `additional_flags` - Additional flags to check for, that could have been added to the `stat` variable
 *
 * Returns `TRUE` if the machine is operable, `FALSE` otherwise
 */
/obj/machinery/proc/operable(additional_flags = 0)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_BE_PURE(TRUE)

	if(stat & (NOPOWER|BROKEN|additional_flags))
		return FALSE
	else
		return TRUE

/obj/machinery/proc/toggle_power(power_set = -1, additional_flags = 0)
	if(power_set >= 0)
		update_use_power(power_set)
	else if (use_power || !operable(additional_flags))
		update_use_power(POWER_USE_OFF)
	else
		update_use_power(initial(use_power))

	update_icon()

/obj/machinery/CanUseTopic(var/mob/user)
	if(stat & BROKEN)
		return STATUS_CLOSE

	if(!interact_offline && (stat & NOPOWER))
		return STATUS_CLOSE

	return ..()

/obj/machinery/CouldUseTopic(var/mob/user)
	..()
	if(clicksound && iscarbon(user))
		playsound(src, clicksound, clickvol)
	user.set_machine(src)

/obj/machinery/CouldNotUseTopic(var/mob/user)
	user.unset_machine()

////////////////////////////////////////////////////////////////////////////////////////////

/obj/machinery/attack_ai(mob/user as mob)
	if(!ai_can_interact(user))
		return
	if(isrobot(user))
		// For some reason attack_robot doesn't work
		// This is to stop robots from using cameras to remotely control machines.
		if(user.client && user.client.eye == user)
			return src.attack_hand(user)
	else
		return src.attack_hand(user)

/obj/machinery/attack_hand(mob/user as mob)
	if(!operable(MAINT))
		return 1
	if(user.lying || user.stat)
		return 1
	if ( ! (istype(usr, /mob/living/carbon/human) || \
			istype(usr, /mob/living/silicon)))
		to_chat(usr, SPAN_WARNING("You don't have the dexterity to do this!"))
		return 1
/*
	//distance checks are made by atom/proc/DblClick
	if ((get_dist(src, user) > 1 || !istype(src.loc, /turf)) && !istype(user, /mob/living/silicon))
		return 1
*/
	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.getBrainLoss() >= 60)
			visible_message(SPAN_WARNING("[H] stares cluelessly at [src] and drools."))
			return 1
		else if(prob(H.getBrainLoss()))
			to_chat(user, SPAN_WARNING("You momentarily forget how to use [src]."))
			return 1

	src.add_fingerprint(user)

	return ..()

/obj/machinery/attackby(obj/item/attacking_item, mob/user)
	if(obj_flags & OBJ_FLAG_SIGNALER)
		if(issignaler(attacking_item))
			if(signaler)
				to_chat(user, SPAN_WARNING("\The [src] already has a signaler attached."))
				return TRUE
			var/obj/item/device/assembly/signaler/S = attacking_item
			user.drop_from_inventory(attacking_item, src)
			signaler = S
			S.machine = src
			user.visible_message("<b>[user]</b> attaches \the [S] to \the [src].", SPAN_NOTICE("You attach \the [S] to \the [src]."), range = 3)
			log_and_message_admins("has attached a signaler to \the [src].", user, get_turf(src))
			return TRUE
		else if(attacking_item.iswirecutter() && signaler)
			user.visible_message("<b>[user]</b> removes \the [signaler] from \the [src].", SPAN_NOTICE("You remove \the [signaler] from \the [src]."), range = 3)
			user.put_in_hands(detach_signaler())
			return TRUE

	return ..()

/obj/machinery/proc/detach_signaler(var/turf/detach_turf)
	if(!signaler)
		return

	if(!detach_turf)
		detach_turf = get_turf(src)
	if(!detach_turf)
		LOG_DEBUG("[src] tried to drop a signaler, but it had no turf ([src.x]-[src.y]-[src.z])")
		return

	var/obj/item/device/assembly/signaler/S = signaler

	signaler.forceMove(detach_turf)
	signaler.machine = null
	signaler = null

	return S

/obj/machinery/proc/RefreshParts()
	/*
	if(parts_power_mgmt)
		var/new_idle_power
		var/new_active_power

		if(!component_parts || !component_parts.len)
			return
		var/parts_energy_rating = 0

		for(var/obj/item/stock_parts/part in component_parts)
			parts_energy_rating += part.energy_rating()

		new_idle_power = initial(idle_power_usage) * (1 + parts_energy_rating)
		new_active_power = initial(active_power_usage) * (1 + parts_energy_rating)

		change_power_consumption(new_idle_power)
		change_power_consumption(new_active_power, POWER_USE_ACTIVE)
	*/

/obj/machinery/proc/assign_uid()
	uid = gl_uid
	gl_uid++

/obj/machinery/proc/state(var/msg)
	for(var/mob/O in hearers(src, null))
		O.show_message("[icon2html(src, O)] <span class = 'notice'>[msg]</span>", 2)

/obj/machinery/proc/ping(text=null)
	if (!text)
		text = "\The [src] pings."

	state(text, "blue")
	playsound(src.loc, 'sound/machines/ping.ogg', 50, 0)

/obj/machinery/proc/pingx3(text=null)
	if (!text)
		text = "\The [src] pings."

	state(text, "blue")
	playsound(src.loc, 'sound/machines/pingx3.ogg', 50, 0)

/obj/machinery/proc/buzz(text=null)
	if (!text)
		text = "\The [src] buzzes."

	state(text, "blue")
	playsound(src.loc, 'sound/machines/buzz-sigh.ogg', 50, 0) //TODO: Check if that one is the correct sound

/obj/machinery/proc/shock(mob/user, prb)
	if(!operable())
		return 0
	if(!prob(prb))
		return 0
	spark(src, 5, GLOB.alldirs)
	if (electrocute_mob(user, get_area(src), src, 0.7))
		var/area/temp_area = get_area(src)
		if(temp_area)
			var/obj/machinery/power/apc/temp_apc = temp_area.get_apc()

			if(temp_apc && temp_apc.terminal && temp_apc.terminal.powernet)
				temp_apc.terminal.powernet.trigger_warning()
		if(user.stunned)
			return 1
	return 0

/obj/machinery/proc/default_deconstruction_crowbar(var/mob/user, var/obj/item/C)
	if(!istype(C) || !C.iscrowbar())
		return 0
	if(!panel_open)
		return 0
	. = dismantle()

/obj/machinery/proc/default_deconstruction_screwdriver(var/mob/user, var/obj/item/S)
	if(!istype(S) || !S.isscrewdriver())
		return FALSE
	S.play_tool_sound(get_turf(src), 50)
	panel_open = !panel_open
	to_chat(user, SPAN_NOTICE("You [panel_open ? "open" : "close"] the maintenance hatch of [src]."))
	update_icon()
	return TRUE

/obj/machinery/proc/default_part_replacement(var/mob/user, var/obj/item/storage/part_replacer/R)
	if(!LAZYLEN(component_parts))
		return FALSE
	else if(istype(R))
		var/parts_replaced = FALSE
		if(panel_open)
			var/obj/item/circuitboard/CB = locate(/obj/item/circuitboard) in component_parts
			var/P
			for(var/obj/item/reagent_containers/glass/G in component_parts)
				for(var/D in CB.req_components)
					var/T = text2path(D)
					if(ispath(G.type, T))
						P = T
						break
				for(var/obj/item/reagent_containers/glass/B in R.contents)
					if(B.reagents && B.reagents.total_volume > 0) continue
					if(istype(B, P) && istype(G, P))
						if(B.volume > G.volume)
							R.remove_from_storage(B, src)
							R.handle_item_insertion(G, 1)
							component_parts -= G
							component_parts += B
							B.forceMove(src)
							to_chat(user, SPAN_NOTICE("[G.name] replaced with [B.name]."))
							break
			for(var/obj/item/stock_parts/A in component_parts)
				for(var/D in CB.req_components)
					var/T = text2path(D)
					if(ispath(A.type, T))
						P = T
						break
				for(var/obj/item/stock_parts/B in R.contents)
					if(istype(B, P) && istype(A, P))
						if(B.rating > A.rating)
							R.remove_from_storage(B, src)
							R.handle_item_insertion(A, 1)
							component_parts -= A
							component_parts += B
							B.forceMove(src)
							to_chat(user, SPAN_NOTICE("[A.name] replaced with [B.name]."))
							parts_replaced = TRUE
							break
			RefreshParts()
			update_icon()
			if(parts_replaced) //only play sound when RPED actually replaces parts
				playsound(src, 'sound/items/rped.ogg', 40, TRUE)
			return TRUE
		else
			to_chat(user, SPAN_NOTICE("The following parts have been detected in \the [src]:"))
			to_chat(user, counting_english_list(component_parts))
	else return FALSE

/obj/machinery/proc/dismantle()
	playsound(loc, /singleton/sound_category/crowbar_sound, 50, 1)
	var/obj/machinery/constructable_frame/machine_frame/M = new /obj/machinery/constructable_frame/machine_frame(loc)
	M.set_dir(src.dir)
	M.state = 3
	M.icon_state = "blueprint_1"

	for(var/obj/I in component_parts)
		I.forceMove(loc)
		component_parts -= I

	qdel(src)

	return TRUE

/obj/machinery/proc/print(var/obj/paper, var/play_sound = 1, var/print_sfx = /singleton/sound_category/print_sound, var/print_delay = 10, var/message, var/mob/user)
	if( printing )
		return FALSE

	printing = TRUE

	if (play_sound)
		playsound(src.loc, print_sfx, 50, 1)

	if(!message)
		message = "\The [src] rattles to life and spits out a paper titled [paper]."
	visible_message(SPAN_NOTICE(message))

	addtimer(CALLBACK(src, PROC_REF(print_move_paper), paper, user), print_delay)

	return TRUE

/obj/machinery/proc/print_move_paper(obj/paper, mob/user)
	if(user && ishuman(user) && user.Adjacent(src))
		user.put_in_hands(paper)
	else
		paper.forceMove(loc)
	printing = FALSE

/obj/machinery/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit)
	. = ..()
	if(. != BULLET_ACT_HIT)
		return .

	if(hitting_projectile.get_structure_damage() > 5)
		bullet_ping(hitting_projectile)

/obj/machinery/proc/do_hair_pull(mob/living/carbon/human/H)
	if(stat & (NOPOWER|BROKEN))
		return

	if(!istype(H))
		return

	//for whatever reason, skrell's tentacles have a really long length
	//horns would not get caught in the machine
	//vaurca have fine control of their antennae
	if(isskrell(H) || isunathi(H) || isvaurca(H))
		return

	var/datum/sprite_accessory/hair/hair_style = GLOB.hair_styles_list[H.h_style]
	for(var/obj/item/protection in list(H.head))
		if(protection && (protection.flags_inv & BLOCKHAIR|BLOCKHEADHAIR))
			return

	if(hair_style.length >= 4 && prob(25))
		H.apply_damage(30, DAMAGE_BRUTE, BP_HEAD)
		H.visible_message(SPAN_DANGER("\The [H]'s hair catches in \the [src]!"),
					SPAN_DANGER("Your hair gets caught in \the [src]!"))
		if(H.can_feel_pain())
			H.emote("scream")
			H.apply_damage(45, DAMAGE_PAIN)

// A late init operation called in SSshuttle for ship computers and holopads, used to attach the thing to the right ship.
/obj/machinery/proc/attempt_hook_up(var/obj/effect/overmap/visitable/sector)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(sector))
		return FALSE
	if(sector.check_ownership(src))
		linked = sector
		return TRUE
	return FALSE

/obj/machinery/proc/sync_linked()
	var/obj/effect/overmap/visitable/sector = GLOB.map_sectors["[z]"]
	if(!sector)
		return
	return attempt_hook_up_recursive(sector)

/obj/machinery/proc/attempt_hook_up_recursive(var/obj/effect/overmap/visitable/sector)
	if(attempt_hook_up(sector))
		return sector
	for(var/obj/effect/overmap/visitable/candidate in sector)
		if((. = .(candidate)))
			return

/obj/proc/on_user_login(mob/M)
	return

/obj/machinery/proc/set_emergency_state(var/new_security_level)
	return

/obj/machinery/hitby(atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hitting_atom))
		var/mob/living/M = hitting_atom
		M.turf_collision(src, throwingdatum.speed)
		return
	else
		visible_message(SPAN_DANGER("\The [src] was hit by \the [hitting_atom]."))

/obj/machinery/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(. < UI_INTERACTIVE)
		if(user.machine)
			user.unset_machine()
