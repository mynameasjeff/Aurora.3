/datum/exoplanet_theme/grass
	name = "Grasslands" // Not gm_flatgrass, but pretty close
	surface_turfs = list(
		/turf/simulated/floor/exoplanet/grass,
		/turf/simulated/mineral/planet
	)
	mountain_threshold = 0.9
	possible_biomes = list(
		BIOME_COOL = list(
			BIOME_ARID = /singleton/biome/grass/chaparral,
			BIOME_SEMIARID = /singleton/biome/grass/forest,
			BIOME_SUBHUMID = /singleton/biome/grass/forest
		),
		BIOME_WARM = list(
			BIOME_ARID = /singleton/biome/grass/chaparral,
			BIOME_SEMIARID = /singleton/biome/grass,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside
		),
		BIOME_EQUATOR = list(
			BIOME_ARID = /singleton/biome/grass,
			BIOME_SEMIARID = /singleton/biome/grass/riverside,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside
		)
	)

	heat_levels = list(
		BIOME_COOL = 0.4,
		BIOME_WARM = 0.8,
		BIOME_EQUATOR = 1.0
	)

	humidity_levels = list(
		BIOME_ARID = 0.2,
		BIOME_SEMIARID = 0.5,
		BIOME_SUBHUMID = 1.0
	)

/datum/exoplanet_theme/grass/before_map_generation(obj/effect/overmap/visitable/sector/exoplanet/E)
	. = ..()
	surface_color = E.grass_color

/datum/exoplanet_theme/grass/marsh
	name = "Fungal Marsh"
	surface_turfs = list(
		/turf/simulated/mineral/planet
	)
	possible_biomes = list(
		BIOME_WARM = list(
			BIOME_SUBHUMID = /singleton/biome/marsh,
			BIOME_HUMID = /singleton/biome/marsh/forest
		),
		BIOME_EQUATOR = list(
			BIOME_SUBHUMID = /singleton/biome/marsh,
			BIOME_HUMID = /singleton/biome/marsh/forest
		)

	)
	heat_levels = list(
		BIOME_WARM = 0.5,
		BIOME_EQUATOR = 1.0
	)
	humidity_levels = list(
		BIOME_SUBHUMID = 0.4,
		BIOME_HUMID = 1.0
	)

//biesel

/datum/exoplanet_theme/grass/biesel
	possible_biomes = list(
		BIOME_COOL = list(
			BIOME_ARID = /singleton/biome/grass/biesel,
			BIOME_SEMIARID = /singleton/biome/grass/forest/biesel,
			BIOME_SUBHUMID = /singleton/biome/grass/forest/biesel
		),
		BIOME_WARM = list(
			BIOME_ARID = /singleton/biome/grass/biesel,
			BIOME_SEMIARID = /singleton/biome/grass/biesel,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/biesel
		),
		BIOME_EQUATOR = list(
			BIOME_ARID = /singleton/biome/grass/biesel,
			BIOME_SEMIARID = /singleton/biome/grass/riverside/biesel,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/biesel
		)
	)

/datum/exoplanet_theme/grass/moghes //un-nuked Moghes theme
	name = "Untouched Lands"
	mountain_threshold = 0.9
	possible_biomes = list(
		BIOME_COOL = list(
			BIOME_ARID = /singleton/biome/grass/chaparral/moghes,
			BIOME_SEMIARID = /singleton/biome/grass/forest/moghes,
			BIOME_SUBHUMID = /singleton/biome/grass/forest/moghes
		),
		BIOME_WARM = list(
			BIOME_ARID = /singleton/biome/grass/chaparral/moghes,
			BIOME_SEMIARID = /singleton/biome/grass/moghes,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/moghes
		),
		BIOME_EQUATOR = list(
			BIOME_ARID = /singleton/biome/grass/moghes,
			BIOME_SEMIARID = /singleton/biome/grass/riverside/moghes,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/moghes
		)
	)

	heat_levels = list(
		BIOME_COOL = 0.4,
		BIOME_WARM = 0.8,
		BIOME_EQUATOR = 1.0
	)

	humidity_levels = list(
		BIOME_ARID = 0.2,
		BIOME_SEMIARID = 0.5,
		BIOME_SUBHUMID = 1.0
	)

/datum/exoplanet_theme/grass/moghes/after_map_generation(obj/effect/overmap/visitable/sector/exoplanet/E)
	var/area/A = E.planetary_area
	LAZYDISTINCTADD(A.ambience, AMBIENCE_JUNGLE)
	A.area_blurb = "The air is hot and humid, clinging to your skin. An occasional cool breeze offers some small respite. Beneath your feet lies lush grass, and the sounds of strange animals fill the air."

/datum/exoplanet_theme/grass/ouerea //Ouerea theme.
	name = "Ouerea"
	surface_turfs = list(
		/turf/simulated/mineral
	)
	mountain_threshold = 0.9
	possible_biomes = list(
		BIOME_COOL = list(
			BIOME_ARID = /singleton/biome/grass/chaparral/ouerea,
			BIOME_SEMIARID = /singleton/biome/grass/forest/ouerea,
			BIOME_SUBHUMID = /singleton/biome/grass/forest/ouerea
		),
		BIOME_WARM = list(
			BIOME_ARID = /singleton/biome/grass/chaparral/ouerea,
			BIOME_SEMIARID = /singleton/biome/grass/ouerea,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/ouerea
		),
		BIOME_EQUATOR = list(
			BIOME_ARID = /singleton/biome/grass/ouerea,
			BIOME_SEMIARID = /singleton/biome/grass/riverside/ouerea,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/ouerea
		)
	)

	heat_levels = list(
		BIOME_COOL = 0.4,
		BIOME_WARM = 0.8,
		BIOME_EQUATOR = 1.0
	)

	humidity_levels = list(
		BIOME_ARID = 0.2,
		BIOME_SEMIARID = 0.5,
		BIOME_SUBHUMID = 1.0
	)

/datum/exoplanet_theme/grass/xanu_nayakhyber
	name = "Naya Khyber"
	surface_turfs = list(
		/turf/simulated/floor/exoplanet/grass/stalk,
		/turf/simulated/mineral/planet
	)

	possible_biomes = list(
		BIOME_COOL = list(
			BIOME_ARID = /singleton/biome/grass/xanu,
			BIOME_SEMIARID = /singleton/biome/grass/chaparral/xanu,
			BIOME_SUBHUMID = /singleton/biome/grass/forest/xanu
		),
		BIOME_WARM = list(
			BIOME_ARID = /singleton/biome/grass/chaparral/xanu,
			BIOME_SEMIARID = /singleton/biome/grass/chaparral/xanu,
			BIOME_SUBHUMID = /singleton/biome/grass/riverside/xanu
		),
		BIOME_EQUATOR = list(
			BIOME_ARID = /singleton/biome/grass/forest/xanu,
			BIOME_SEMIARID = /singleton/biome/grass/forest/xanu,
			BIOME_SUBHUMID = /singleton/biome/grass/chaparral/xanu
		)
	)
