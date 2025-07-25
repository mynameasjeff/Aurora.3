/obj/machinery/atmospherics/unary/vent_scrubber
	name = "air scrubber"
	desc = "Has a valve and pump attached to it."
	icon = 'icons/atmos/vent_scrubber.dmi'
	icon_state = "map_scrubber_off"

	use_power = POWER_USE_OFF
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 30000			//30000 W ~ 40 HP

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_SCRUBBER //connects to regular and scrubber pipes

	level = 1

	var/area/initial_loc
	var/id_tag = null
	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/hibernate = 0 //Do we even process?
	var/scrubbing = 1 //0 = siphoning, 1 = scrubbing
	var/list/scrubbing_gas

	var/panic = 0 //is this scrubber panicked?

	var/area_uid
	var/radio_filter_out
	var/radio_filter_in

	var/welded = 0

	var/broadcast_status_next_process = FALSE

/obj/machinery/atmospherics/unary/vent_scrubber/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "This filters the atmosphere of harmful gas. Filtered gas goes to the pipes connected to it, typically a scrubber pipe."
	. += "It can be controlled from an Air Alarm."
	. += "It can be configured to drain all air rapidly with a 'panic siphon' from an air alarm."

/obj/machinery/atmospherics/unary/vent_scrubber/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(distance <= 1)
		. += "A small gauge in the corner reads [round(last_flow_rate, 0.1)] L/s at [round(last_power_draw)] W."
	else
		. += "You are too far away to read the gauge."
	if(welded)
		. += "It seems welded shut."

/obj/machinery/atmospherics/unary/vent_scrubber/on
	use_power = POWER_USE_IDLE
	icon_state = "map_scrubber_on"

/obj/machinery/atmospherics/unary/vent_scrubber/Initialize(mapload)
	if(mapload)
		var/turf/T = loc
		var/image/I = image(icon, T, icon_state, dir, pixel_x, pixel_y)
		I.plane = EFFECTS_ABOVE_LIGHTING_PLANE
		I.color = color
		I.alpha = 125
		LAZYADD(T.blueprints, I)

	. = ..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_FILTER

	initial_loc = get_area(loc)
	area_uid = initial_loc.uid
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)

	radio_filter_in = frequency==initial(frequency)?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==initial(frequency)?(RADIO_TO_AIRALARM):null
	if (frequency)
		set_frequency(frequency)

	if (!scrubbing_gas)
		reset_scrubbing()

/obj/machinery/atmospherics/unary/vent_scrubber/proc/reset_scrubbing()
	if (initial(scrubbing_gas))
		scrubbing_gas = initial(scrubbing_gas)
	else
		scrubbing_gas = list()
		for (var/g in gas_data.gases)
			if (g != GAS_OXYGEN && g != GAS_NITROGEN)
				add_to_scrubbing(g)

/obj/machinery/atmospherics/unary/vent_scrubber/proc/add_to_scrubbing(new_gas)
	scrubbing_gas |= new_gas

/obj/machinery/atmospherics/unary/vent_scrubber/proc/remove_from_scrubbing(old_gas)
	scrubbing_gas -= old_gas

/obj/machinery/atmospherics/unary/vent_scrubber/atmos_init()
	..()
	broadcast_status()

/obj/machinery/atmospherics/unary/vent_scrubber/Destroy()
	unregister_radio(src, frequency)
	if(initial_loc)
		initial_loc.air_scrub_info -= id_tag
		initial_loc.air_scrub_names -= id_tag

	return ..()

/obj/machinery/atmospherics/unary/vent_scrubber/update_icon(var/safety = 0)
	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if (welded)
		icon_state = "weld"
		return

	if (!powered() || !use_power)
		icon_state = "off"
	else if (scrubbing)
		icon_state = "on"
	else
		icon_state = "in"

/obj/machinery/atmospherics/unary/vent_scrubber/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		if(!T.is_plating() && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
			return
		else
			if(node)
				add_underlay(T, node, dir, node.icon_connect_type)
			else
				add_underlay(T,, dir)
			underlays += "frame"

/obj/machinery/atmospherics/unary/vent_scrubber/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, radio_filter_in)

/obj/machinery/atmospherics/unary/vent_scrubber/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = TRANSMISSION_RADIO
	signal.source = src
	signal.data = list(
		"area" = area_uid,
		"tag" = id_tag,
		"device" = "AScr",
		"timestamp" = world.time,
		"power" = use_power,
		"scrubbing" = scrubbing,
		"panic" = panic,
		"filter_o2" = (GAS_OXYGEN in scrubbing_gas),
		"filter_n2" = (GAS_NITROGEN in scrubbing_gas),
		"filter_co2" = (GAS_CO2 in scrubbing_gas),
		"filter_phoron" = (GAS_PHORON in scrubbing_gas),
		"filter_n2o" = (GAS_N2O in scrubbing_gas),
		"filter_h" = (GAS_HYDROGEN in scrubbing_gas),
		"filter_2h" = (GAS_DEUTERIUM in scrubbing_gas),
		"filter_3h" = (GAS_TRITIUM in scrubbing_gas),
		"filter_he" = (GAS_HELIUM in scrubbing_gas),
		"filter_b" = (GAS_BORON in scrubbing_gas),
		"filter_so2" = (GAS_SULFUR in scrubbing_gas),
		"filter_no2" = (GAS_NO2 in scrubbing_gas),
		"filter_cl" = (GAS_CHLORINE in scrubbing_gas),
		"filter_h2o" = (GAS_STEAM in scrubbing_gas),
		"sigtype" = "status"
	)

	var/area/A = get_area(src)
	if(!A.air_scrub_names[id_tag])
		var/new_name = "[A.name] Air Scrubber #[A.air_scrub_names.len+1]"
		A.air_scrub_names[id_tag] = new_name
		src.name = new_name
	A.air_scrub_info[id_tag] = signal.data
	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1

/obj/machinery/atmospherics/unary/vent_scrubber/process()
	..()

	if (hibernate > world.time)
		return 1

	if (!node)
		update_use_power(POWER_USE_OFF)

	if (broadcast_status_next_process)
		broadcast_status()
		broadcast_status_next_process = FALSE

	if(!use_power || (stat & (NOPOWER|BROKEN)) || !loc)
		return 0
	if(welded)
		return 0

	var/datum/gas_mixture/environment = loc.return_air()

	var/power_draw = -1
	if(scrubbing)
		//limit flow rate from turfs
		var/transfer_moles = min(environment.total_moles, environment.total_moles*MAX_SCRUBBER_FLOWRATE/environment.volume)	//group_multiplier gets divided out here

		power_draw = scrub_gas(src, scrubbing_gas, environment, air_contents, transfer_moles, power_rating)
	else //Just siphon all air
		//limit flow rate from turfs
		var/transfer_moles = min(environment.total_moles, environment.total_moles*MAX_SIPHON_FLOWRATE/environment.volume)	//group_multiplier gets divided out here

		power_draw = pump_gas(src, environment, air_contents, transfer_moles, power_rating)

	if(scrubbing && power_draw <= 0)	//99% of all scrubbers
		//Fucking hibernate because you ain't doing shit.
		hibernate = world.time + (rand(100,200))

	if (power_draw >= 0)
		last_power_draw = power_draw
		use_power_oneoff(power_draw)

	if(network)
		network.update = 1

	return 1

/obj/machinery/atmospherics/unary/vent_scrubber/hide(var/i) //to make the little pipe section invisible, the icon changes.
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/unary/vent_scrubber/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["power"] != null)
		update_use_power(text2num(signal.data["power"]))
	if(signal.data["power_toggle"] != null)
		update_use_power(!use_power)

	if(signal.data["panic_siphon"]) //must be before if("scrubbing") thing
		panic = text2num(signal.data["panic_siphon"])
		if(panic)
			update_use_power(POWER_USE_IDLE)
			scrubbing = 0
		else
			scrubbing = 1
	if(signal.data["toggle_panic_siphon"] != null)
		panic = !panic
		if(panic)
			update_use_power(POWER_USE_IDLE)
			scrubbing = 0
		else
			scrubbing = 1

	if(signal.data["scrubbing"] != null)
		scrubbing = text2num(signal.data["scrubbing"])
		if(scrubbing)
			panic = 0
	if(signal.data["toggle_scrubbing"])
		scrubbing = !scrubbing
		if(scrubbing)
			panic = 0

	var/list/toggle = list()

	if(!isnull(signal.data["o2_scrub"]) && text2num(signal.data["o2_scrub"]) != (GAS_OXYGEN in scrubbing_gas))
		toggle += GAS_OXYGEN
	else if(signal.data["toggle_o2_scrub"])
		toggle += GAS_OXYGEN

	if(!isnull(signal.data["n2_scrub"]) && text2num(signal.data["n2_scrub"]) != (GAS_NITROGEN in scrubbing_gas))
		toggle += GAS_NITROGEN
	else if(signal.data["toggle_n2_scrub"])
		toggle += GAS_NITROGEN

	if(!isnull(signal.data["co2_scrub"]) && text2num(signal.data["co2_scrub"]) != (GAS_CO2 in scrubbing_gas))
		toggle += GAS_CO2
	else if(signal.data["toggle_co2_scrub"])
		toggle += GAS_CO2

	if(!isnull(signal.data["tox_scrub"]) && text2num(signal.data["tox_scrub"]) != (GAS_PHORON in scrubbing_gas))
		toggle += GAS_PHORON
	else if(signal.data["toggle_tox_scrub"])
		toggle += GAS_PHORON

	if(!isnull(signal.data["n2o_scrub"]) && text2num(signal.data["n2o_scrub"]) != (GAS_N2O in scrubbing_gas))
		toggle += GAS_N2O
	else if(signal.data["toggle_n2o_scrub"])
		toggle += GAS_N2O

	if(!isnull(signal.data["h_scrub"]) && text2num(signal.data["h_scrub"]) != (GAS_HYDROGEN in scrubbing_gas))
		toggle += GAS_HYDROGEN
	else if(signal.data["toggle_h_scrub"])
		toggle += GAS_HYDROGEN

	if(!isnull(signal.data["2h_scrub"]) && text2num(signal.data["2h_scrub"]) != (GAS_DEUTERIUM in scrubbing_gas))
		toggle += GAS_DEUTERIUM
	else if(signal.data["toggle_2h_scrub"])
		toggle += GAS_DEUTERIUM

	if(!isnull(signal.data["3h_scrub"]) && text2num(signal.data["3h_scrub"]) != (GAS_TRITIUM in scrubbing_gas))
		toggle += GAS_TRITIUM
	else if(signal.data["toggle_3h_scrub"])
		toggle += GAS_TRITIUM

	if(!isnull(signal.data["he_scrub"]) && text2num(signal.data["he_scrub"]) != (GAS_HELIUM in scrubbing_gas))
		toggle += GAS_HELIUM
	else if(signal.data["toggle_he_scrub"])
		toggle += GAS_HELIUM

	if(!isnull(signal.data["b_scrub"]) && text2num(signal.data["b_scrub"]) != (GAS_BORON in scrubbing_gas))
		toggle += GAS_BORON
	else if(signal.data["toggle_b_scrub"])
		toggle += GAS_BORON

	if(!isnull(signal.data["so2_scrub"]) && text2num(signal.data["so2_scrub"]) != (GAS_SULFUR in scrubbing_gas))
		toggle += GAS_SULFUR
	else if(signal.data["toggle_so2_scrub"])
		toggle += GAS_SULFUR

	if(!isnull(signal.data["no2_scrub"]) && text2num(signal.data["no2_scrub"]) != (GAS_NO2 in scrubbing_gas))
		toggle += GAS_NO2
	else if(signal.data["toggle_no2_scrub"])
		toggle += GAS_NO2

	if(!isnull(signal.data["cl_scrub"]) && text2num(signal.data["cl_scrub"]) != (GAS_CHLORINE in scrubbing_gas))
		toggle += GAS_CHLORINE
	else if(signal.data["toggle_cl_scrub"])
		toggle += GAS_CHLORINE

	if(!isnull(signal.data["h2o_scrub"]) && text2num(signal.data["h2o_scrub"]) != (GAS_STEAM in scrubbing_gas))
		toggle += GAS_STEAM
	else if(signal.data["toggle_h2o_scrub"])
		toggle += GAS_STEAM

	scrubbing_gas ^= toggle

	if(signal.data["init"] != null)
		name = signal.data["init"]
		return

	if(signal.data["status"] != null)
		broadcast_status_next_process = TRUE
		return //do not update_icon

	broadcast_status_next_process = TRUE
	update_icon()
	return

/obj/machinery/atmospherics/unary/vent_scrubber/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/unary/vent_scrubber/attackby(obj/item/attacking_item, mob/user)
	if (attacking_item.iswrench())
		if (!(stat & NOPOWER) && use_power)
			to_chat(user, SPAN_WARNING("You cannot unwrench \the [src], turn it off first."))
			return TRUE
		var/turf/T = src.loc
		if (node && node.level==1 && isturf(T) && !T.is_plating())
			to_chat(user, SPAN_WARNING("You must remove the plating first."))
			return TRUE
		var/datum/gas_mixture/int_air = return_air()
		if(!loc) return FALSE
		var/datum/gas_mixture/env_air = loc.return_air()
		if ((int_air.return_pressure()-env_air.return_pressure()) > PRESSURE_EXERTED)
			to_chat(user, SPAN_WARNING("You cannot unwrench \the [src], it is too exerted due to internal pressure."))
			add_fingerprint(user)
			return TRUE
		to_chat(user, SPAN_NOTICE("You begin to unfasten \the [src]..."))
		if(attacking_item.use_tool(src, user, 40, volume = 50))
			user.visible_message( \
				SPAN_NOTICE("\The [user] unfastens \the [src]."), \
				SPAN_NOTICE("You have unfastened \the [src]."), \
				"You hear a ratchet.")
			new /obj/item/pipe(loc, make_from=src)
			qdel(src)
		return TRUE

	if(attacking_item.iswelder())
		var/obj/item/weldingtool/WT = attacking_item

		if(!WT.isOn())
			to_chat(user, SPAN_NOTICE("\The [WT] needs to be on to start this task."))
			return

		if(!WT.use(0, user))
			to_chat(user, SPAN_WARNING("You need more welding fuel to complete this task."))
			return

		to_chat(user, SPAN_NOTICE("Now welding \the [src]..."))

		if(!WT.use_tool(src, user, 20, volume = 50))
			to_chat(user, SPAN_NOTICE("You must remain close to finish this task."))
			return

		welded = !welded
		update_icon()
		user.visible_message(SPAN_NOTICE("\The [user] [welded ? "welds \the [src] shut" : "unwelds \the [src]"]."), \
								SPAN_NOTICE("You [welded ? "weld \the [src] shut" : "unweld \the [src]"]."), \
								"You hear welding.")
		return TRUE

	if(istype(attacking_item, /obj/item/melee/arm_blade))
		if(!welded)
			to_chat(user, SPAN_WARNING("\The [attacking_item] can only be used to tear open welded scrubbers!"))
			return TRUE
		user.visible_message(SPAN_WARNING("\The [user] starts using \the [attacking_item] to hack open \the [src]!"), SPAN_NOTICE("You start hacking open \the [src] with \the [attacking_item]..."))
		user.do_attack_animation(src, attacking_item)
		playsound(loc, 'sound/weapons/smash.ogg', 60, TRUE)
		var/cut_amount = 3
		for(var/i = 0; i <= cut_amount; i++)
			if(!attacking_item || !do_after(user, 30, src))
				return TRUE
			user.do_attack_animation(src, attacking_item)
			user.visible_message(SPAN_WARNING("\The [user] smashes \the [attacking_item] into \the [src]!"), SPAN_NOTICE("You smash \the [attacking_item] into \the [src]."))
			playsound(loc, 'sound/weapons/smash.ogg', 60, TRUE)
			if(i == cut_amount)
				welded = FALSE
				spark(get_turf(src), 3, GLOB.alldirs)
				playsound(loc, 'sound/items/welder_pry.ogg', 50, TRUE)
				update_icon()
		return TRUE

	return ..()
