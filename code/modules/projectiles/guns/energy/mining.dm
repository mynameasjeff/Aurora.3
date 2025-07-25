/*******************PLASMA CUTTER*******************/

/obj/item/gun/energy/plasmacutter
	name = "plasma cutter"
	desc = "A mining tool capable of expelling concentrated plasma bursts. You could use it to cut limbs off of xenos! Or, you know, mine stuff."
	charge_meter = FALSE
	icon = 'icons/obj/guns/plasma_cutter.dmi'
	icon_state = "plasma"
	item_state = "plasma"
	usesound = 'sound/weapons/plasma_cutter.ogg'
	fire_sound = 'sound/weapons/plasma_cutter.ogg'
	slot_flags = SLOT_BELT|SLOT_BACK
	accuracy = 1
	force = 22
	sharp = TRUE
	edge = TRUE
	origin_tech = list(TECH_MATERIAL = 4, TECH_PHORON = 3, TECH_ENGINEERING = 3)
	matter = list(DEFAULT_WALL_MATERIAL = 4000, MATERIAL_GLASS = 2000)
	projectile_type = /obj/projectile/beam/plasmacutter
	cell_type = /obj/item/cell/high
	charge_cost = 666.66 // 15 shots on a high cap cell
	needspin = FALSE

/obj/item/gun/energy/plasmacutter/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(is_adjacent)
		if(power_supply)
			. += FONT_SMALL(SPAN_NOTICE("It has a <b>[capitalize_first_letters(power_supply.name)]</b> installed as its power supply."))
		else
			. += FONT_SMALL(SPAN_WARNING("It has no power supply installed."))

/obj/item/gun/energy/plasmacutter/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.isscrewdriver())
		if(power_supply)
			to_chat(user, SPAN_NOTICE("You uninstall \the [power_supply]."))
			power_supply.forceMove(get_turf(src))
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				H.put_in_hands(power_supply)
			power_supply = null
		else
			to_chat(user, SPAN_WARNING("\The [src] doesn't have a power supply!"))
	else if(istype(attacking_item, /obj/item/cell))
		if(power_supply)
			to_chat(user, SPAN_WARNING("\The [src] already has a power supply installed!"))
		else
			to_chat(user, SPAN_NOTICE("You install \the [attacking_item] into \the [src]."))
			user.drop_from_inventory(attacking_item, src)
			power_supply = attacking_item
	else
		..()

/obj/item/gun/energy/plasmacutter/proc/check_power_and_message(var/mob/user, var/use_amount = 1)
	if(!power_supply)
		to_chat(user, SPAN_WARNING("\The [src] doesn't have a power supply installed!"))
		return TRUE
	if(!power_supply.check_charge(charge_cost * use_amount))
		to_chat(user, SPAN_WARNING("\The [src] doesn't have enough power to do this!"))
		return TRUE
	return FALSE

/obj/item/gun/energy/plasmacutter/mounted
	name = "mounted plasma cutter"
	self_recharge = TRUE
	use_external_power = TRUE
	cell_type = null
	max_shots = 15

/obj/projectile/beam/plasmacutter
	name = "plasma arc"
	icon_state = "omnilaser"
	damage = 20
	damage_type = DAMAGE_BURN
	check_armor = LASER
	range = 5
	pass_flags = PASSTABLE|PASSRAILING

	var/mineral_passes = 2 // amount of mineral turfs it passes through before ending

	muzzle_type = /obj/effect/projectile/muzzle/plasma_cutter
	tracer_type = /obj/effect/projectile/tracer/plasma_cutter
	impact_type = /obj/effect/projectile/impact/plasma_cutter
	maim_rate = 1

/obj/projectile/beam/plasmacutter/proc/pass_check(var/turf/simulated/mineral/mine_turf)
	if(mineral_passes <= 0)
		return list(null, FALSE) // the projectile stops
	mineral_passes--
	var/mineral_destroyed = on_hit(mine_turf)
	return list(BULLET_ACT_HIT, mineral_destroyed) // the projectile tunnels deeper

/obj/projectile/beam/plasmacutter/on_hit(atom/target, blocked, def_zone)
	if(istype(target, /turf/simulated/mineral))
		var/turf/simulated/mineral/M = target
		if(prob(33))
			M.GetDrilled(1)
			return TRUE
		else if(prob(88))
			M.emitter_blasts_taken += 2
		M.emitter_blasts_taken += 1
	return ..()

/obj/item/gun/energy/plasmacutter/use_resource(mob/user, var/use_amount)
	if(use_external_power)
		var/obj/item/cell/external = get_external_power_supply()
		if(external)
			external.use(use_amount * charge_cost)
		return
	if(power_supply)
		power_supply.use(use_amount * charge_cost)
