/datum/map_template/ruin/away_site/militia_ship
	name = "Freelancer Mercenary Ship"
	description = "Perhaps one of Hephaestus Industries's most successful designs, The Axiom-Class Utility Cutter is a common sight in nearly every major power in the Orion Spur thanks to it's ease of prodution and cost effectiveness. While the design frequently sees use as a tug, utility vehicle, or for short range-transportation. Independent Spacers also frequently purchase used Axioms on the cheap and modify it to varying degrees for their own needs. This specimen in particular has faced extensive modifications for ship-to-ship combat and scouting."

	prefix = "ships/wildlands_milita"
	suffix = "milita_ship.dmm"

	sectors = list(SECTOR_BADLANDS, SECTOR_VALLEY_HALE)
	spawn_weight = 1
	ship_cost = 1
	id = "milita_ship"
	shuttles_to_initialise = list(/datum/shuttle/autodock/overmap/ssrm_shuttle)

	unit_test_groups = list(3)

/singleton/submap_archetype/militia_ship
	map = "Freelancer Mercenary Ship"
	descriptor = "Perhaps one of Hephaestus Industries's most successful designs, The Axiom-Class Utility Cutter is a common sight in nearly every major power in the Orion Spur thanks to it's ease of prodution and cost effectiveness. While the design frequently sees use as a tug, utility vehicle, or for short range-transportation. Independent Spacers also frequently purchase used Axioms on the cheap and modify it to varying degrees for their own needs. This specimen in particular has faced extensive modifications for ship-to-ship combat and scouting."
// Ship stuff

/obj/effect/overmap/visitable/ship/militia_ship
	name = "Freelancer Mercenary Vessel"
	class = "ICV"
	desc = "Perhaps one of Hephaestus Industries's most successful designs, The Axiom-Class Utility Cutter is a common sight in nearly every major power in the Orion Spur thanks to it's ease of prodution and cost effectiveness. While the design frequently sees use as a tug, utility vehicle, or for short range-transportation. Independent Spacers also frequently purchase used Axioms on the cheap and modify it to varying degrees for their own needs. This specimen in particular has faced extensive modifications for ship-to-ship combat and scouting."
	icon_state = "tramp"
	moving_state = "tramp_moving"
	scanimage = "no_data.png"
	designer = "MANUFACTURER UNKNOWN, SUBJECT MODEL MODIFIED BEYOND RECONGITION"
	volume = "49 meters length, 30 meters beam/width, 14 meters vertical height"
	drive = "Low-Speed Warp Acceleration FTL Drive"
	weapons = "Dual extrouding improvised weapons bay(s), port external docking arm"
	sizeclass = "Axiom-Class Utility Cutter (modified)"
	shiptype = "Modified Paramilitary Vessel"
	max_speed = 1/(2 SECONDS)
	burn_delay = 1 SECONDS
	vessel_mass = 6500
	fore_dir = SOUTH
	vessel_size = SHIP_SIZE_SMALL
	initial_restricted_waypoints = list(
		"SSRM Shuttle" = list("nav_ssrm_dock")
	)

	initial_generic_waypoints = list(
		"nav_ssrm_corvette_1",
		"nav_ssrm_corvette_2"
	)

	invisible_until_ghostrole_spawn = TRUE

/obj/effect/overmap/visitable/ship/milia_ship/New()
	designation = "[pick("Earner of the Year", "Problems go away here", "Into the greens", "Credit printer", "Odd evener", "We fight 4 Cash", "Landsknetch", "Golden Horde", "Vikinger", "Rounds in, money out", "Fortuna", "Breaking Even", "We fight dirty", "Discounts 4 Collies", "Discounts 4 Imps", "Fuck you Joseph Dorn", "Job wanted, can shoot", "Poverty ender 9000", "Rensberg's bastard children", "Too good for Zavod", "Too good for the Marines")]"
	..()

/obj/effect/overmap/visitable/ship/ranger_corvette/get_skybox_representation()
	var/image/skybox_image = image('icons/skybox/subcapital_ships.dmi', "ranger")
	skybox_image.pixel_x = rand(0,64)
	skybox_image.pixel_y = rand(128,256)
	return skybox_image
