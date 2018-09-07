//Stand-in until this is made more lore-friendly.
/datum/species/xenos
	name = SPECIES_XENO
	name_plural = "Xenophages"

	unarmed_types = list(/datum/unarmed_attack/claws/strong, /datum/unarmed_attack/bite/strong)
	hud_type = /datum/hud_data/alien
	rarity_value = 3
	health_hud_intensity = 1

	natural_armour_values = list(melee = 35, bullet = 25, laser = 30, energy = 30, bomb = 30, bio = 100, rad = 100)

	icon_template = 'icons/mob/human_races/species/xenos/template.dmi'

	// temp until someone who isn't me makes some for this icon set
	damage_overlays = null
	damage_mask =     null
	blood_mask =      null
	// end temp

	pixel_offset_x = -16
	has_fine_manipulation = 0
	gluttonous = GLUT_SMALLER
	strength = STR_VHIGH
	stomach_capacity = MOB_MEDIUM

//	brute_mod =     0.75 // Hardened carapace.
//	burn_mod =      0.75 // ~~Weak to fire.~~ scratch that, we :original_character: now
	radiation_mod = 0    // No feasible way of curing radiation.
	flash_mod =     0    // Denied.
	stun_mod =      0.5  // Halved stun times.
	paralysis_mod = 0.25 // Quartered paralysis times.
	weaken_mod =    0    // Cannot be weakened.

	warning_low_pressure = 50
	hazard_low_pressure = -1

	darksight_range = 8
	darksight_tint = DARKTINT_GREAT

	cold_level_1 = 50
	cold_level_2 = -1
	cold_level_3 = -1

	species_flags = SPECIES_FLAG_NO_SCAN | SPECIES_FLAG_NO_PAIN | SPECIES_FLAG_NO_SLIP | SPECIES_FLAG_NO_POISON | SPECIES_FLAG_NO_MINOR_CUT | SPECIES_FLAG_NO_EMBED | SPECIES_FLAG_NO_TANGLE
	appearance_flags = HAS_EYE_COLOR | HAS_SKIN_COLOR

	spawn_flags = SPECIES_IS_RESTRICTED

	reagent_tag = IS_XENOS

	blood_color = "#05ee05"
	flesh_color = "#282846"

	gibbed_anim = "gibbed-a"
	dusted_anim = "dust-a"
	death_message = "lets out a waning guttural screech, green blood bubbling from its maw."
	death_sound = 'sound/voice/hiss6.ogg'

	speech_sounds = list('sound/voice/hiss1.ogg','sound/voice/hiss2.ogg','sound/voice/hiss3.ogg','sound/voice/hiss4.ogg')
	speech_chance = 100

	breath_type = null
	poison_types = null

	vision_flags = SEE_SELF|SEE_MOBS

	has_organ = list(
		BP_EYES =     /obj/item/organ/internal/eyes/xeno,
		BP_HEART =    /obj/item/organ/internal/heart/open,
		BP_BRAIN =    /obj/item/organ/internal/brain/xeno,
		BP_PLASMA =   /obj/item/organ/internal/xeno/plasmavessel,
		BP_HIVE =     /obj/item/organ/internal/xeno/hivenode,
		)

	var/list/started_healing = list()
	var/accelerated_healing_threshold = 10 SECONDS

	has_limbs = list(
		"chest" =  list("path" = /obj/item/organ/external/chest/xeno),
		"groin" =  list("path" = /obj/item/organ/external/groin/xeno),
		"head" =   list("path" = /obj/item/organ/external/head/xeno),
		"l_arm" =  list("path" = /obj/item/organ/external/arm/xeno),
		"r_arm" =  list("path" = /obj/item/organ/external/arm/right/xeno),
		"l_leg" =  list("path" = /obj/item/organ/external/leg/xeno),
		"r_leg" =  list("path" = /obj/item/organ/external/leg/right/xeno),
		"l_hand" = list("path" = /obj/item/organ/external/hand/xeno),
		"r_hand" = list("path" = /obj/item/organ/external/hand/right/xeno),
		"l_foot" = list("path" = /obj/item/organ/external/foot/xeno),
		"r_foot" = list("path" = /obj/item/organ/external/foot/right/xeno)
		)

	bump_flag = ALIEN
	swap_flags = ~HEAVY
	push_flags = (~HEAVY) ^ ROBOT

	var/weeds_heal_rate = 5     // Health regen on weeds.
	var/weeds_plasma_rate = 5   // Plasma regen on weeds.

	genders = list(FEMALE)

	force_cultural_info = list(
		TAG_CULTURE =   CULTURE_XENOPHAGE_D,
		TAG_HOMEWORLD = HOME_SYSTEM_DEEP_SPACE,
		TAG_FACTION =   FACTION_XENOPHAGE,
		TAG_RELIGION =  RELIGION_OTHER
	)

/datum/species/xenos/get_bodytype(var/mob/living/carbon/H)
	return "Xenophage"

/datum/species/xenos/can_understand(var/mob/other)

	if(istype(other,/mob/living/carbon/alien/larva))
		return 1

	return 0

/datum/species/xenos/hug(var/mob/living/carbon/human/H,var/mob/living/target)
	H.visible_message("<span class='notice'>[H] caresses [target] with countless prickling, needle-like legs.</span>", \
					"<span class='notice'>You caress [target] with countless prickling, needle-like legs.</span>")

/datum/species/xenos/handle_post_spawn(var/mob/living/carbon/human/H)

	if(H.mind)
		H.mind.assigned_role = "Alien"
		H.mind.special_role = "Alien"

	var/decl/cultural_info/culture/hidden/xenophage/culture = SSculture.get_culture(force_cultural_info[TAG_CULTURE])
	if(istype(culture))
		culture.caste_number++
		H.real_name = culture.get_random_name(H)
		H.SetName(H.real_name)
	..()

/datum/species/xenos/handle_environment_special(var/mob/living/carbon/human/H)

	var/turf/T = H.loc
	if(!T) return
	var/datum/gas_mixture/environment = T.return_air()
	if(!environment) return

	var/obj/effect/vine/plant = locate() in T
	if((environment.gas["phoron"] > 0 || (plant && plant.seed && plant.seed.name == "xenomorph")))
		if(!regenerate(H))
			var/obj/item/organ/internal/xeno/plasmavessel/P = H.internal_organs_by_name["plasma vessel"]
			P.stored_plasma += weeds_plasma_rate
			P.stored_plasma = min(max(P.stored_plasma,0),P.max_plasma)
	else
		started_healing["\ref[H]"] = null
	..()

/datum/species/xenos/proc/regenerate(var/mob/living/carbon/human/H)

	var/heal_rate = weeds_heal_rate
	var/mend_prob = 10
	if (!H.lying)
		heal_rate = weeds_heal_rate / 4
		mend_prob = 1

	if(!H.resting || !started_healing["\ref[H]"])
		started_healing["\ref[H]"] = world.time
	if(world.time - started_healing["\ref[H]"] > accelerated_healing_threshold)
		heal_rate *= 1.5
		mend_prob *= 5

	//next internal organs and blood
//	H.restore_blood()
	if(H.vessel.total_volume < H.species.blood_volume)
		H.vessel.add_reagent(/datum/reagent/blood, 10)
	for(var/obj/item/organ/I in H.internal_organs)
		if(I.damage > 0)
			I.damage = max(I.damage - heal_rate, 0)
			if (prob(5))
				to_chat(H, "<span class='alium'>You feel a soothing sensation within your [I.parent_organ]...</span>")
			if(I.can_recover())
				I.status &= ~ORGAN_DEAD
				H.update_body(1)
				if(I.organ_tag == BP_HEART)
					H.resuscitate()
			return 1

	//heal damages
	if (H.getBruteLoss() || H.getFireLoss() || H.getOxyLoss() || H.getToxLoss())
		H.adjustBruteLoss(-heal_rate)
		H.adjustFireLoss(-heal_rate)
		H.adjustOxyLoss(-heal_rate)
		H.adjustToxLoss(-heal_rate)
		if (prob(5))
			to_chat(H, "<span class='alium'>You feel a soothing sensation come over you...</span>")
		return 1

	//next mend broken bones, approx 10 ticks each
	for(var/obj/item/organ/external/E in H.bad_external_organs)
		if (E.status & ORGAN_BROKEN)
			if(E.mend_fracture())
				to_chat(H, "<span class='alium'>You feel something mend itself inside your [E.name].</span>")
			return 1

	return 0

/datum/species/xenos/drone
	name = "Xenophage Drone"
	weeds_plasma_rate = 15
	slowdown = 0
//	brute_mod =     0.6
//	burn_mod =      0.6

	rarity_value = 5
	icobase = 'icons/mob/human_races/species/xenos/r_xenos_drone.dmi'
	deform =  'icons/mob/human_races/species/xenos/r_xenos_drone.dmi'

	has_organ = list(
		BP_EYES =     /obj/item/organ/internal/eyes/xeno,
		BP_HEART =    /obj/item/organ/internal/heart/open,
		BP_BRAIN =    /obj/item/organ/internal/brain/xeno,
		BP_PLASMA =   /obj/item/organ/internal/xeno/plasmavessel/queen,
		BP_ACID =     /obj/item/organ/internal/xeno/acidgland,
		BP_HIVE =     /obj/item/organ/internal/xeno/hivenode,
		BP_RESIN =    /obj/item/organ/internal/xeno/resinspinner,
		)

	inherent_verbs = list(
		/mob/living/proc/ventcrawl,
		/mob/living/carbon/human/proc/pry_open,
		/mob/living/carbon/human/proc/regurgitate,
		/mob/living/carbon/human/proc/plant,
		/mob/living/carbon/human/proc/transfer_plasma,
		/mob/living/carbon/human/proc/evolve,
		/mob/living/carbon/human/proc/resin,
		/mob/living/carbon/human/proc/corrosive_acid,
		/mob/living/carbon/human/proc/darksight,
		/mob/living/carbon/human/proc/scan_target
		)

/datum/species/xenos/drone/handle_post_spawn(var/mob/living/carbon/human/H)

	var/mob/living/carbon/human/A = H
	if(!istype(A))
		return ..()
	..()

/datum/species/xenos/hunter
	name = "Xenophage Hunter"
	weeds_plasma_rate = 5
	slowdown = -0.5
	total_health = 300

	icobase = 'icons/mob/human_races/species/xenos/r_xenos_hunter.dmi'
	deform =  'icons/mob/human_races/species/xenos/r_xenos_hunter.dmi'

	has_organ = list(
		BP_EYES =     /obj/item/organ/internal/eyes/xeno,
		BP_HEART =    /obj/item/organ/internal/heart/open,
		BP_BRAIN =    /obj/item/organ/internal/brain/xeno,
		BP_PLASMA =   /obj/item/organ/internal/xeno/plasmavessel/hunter,
		BP_HIVE =     /obj/item/organ/internal/xeno/hivenode,
		)

	inherent_verbs = list(
		/mob/living/proc/ventcrawl,
		/mob/living/carbon/human/proc/pry_open,
		/mob/living/carbon/human/proc/tackle,
		/mob/living/carbon/human/proc/leap,
		/mob/living/carbon/human/proc/psychic_whisper,
		/mob/living/carbon/human/proc/regurgitate,
		/mob/living/carbon/human/proc/darksight,
		/mob/living/carbon/human/proc/scan_target
		)

	force_cultural_info = list(
		TAG_CULTURE =   CULTURE_XENOPHAGE_H,
		TAG_HOMEWORLD = HOME_SYSTEM_DEEP_SPACE,
		TAG_FACTION =   FACTION_XENOPHAGE,
		TAG_RELIGION =  RELIGION_OTHER
	)

/datum/species/xenos/sentinel
	name = "Xenophage Sentinel"
	weeds_plasma_rate = 10
	slowdown = 0
	total_health = 250
	icobase = 'icons/mob/human_races/species/xenos/r_xenos_sentinel.dmi'
	deform =  'icons/mob/human_races/species/xenos/r_xenos_sentinel.dmi'

	has_organ = list(
		BP_EYES =     /obj/item/organ/internal/eyes/xeno,
		BP_HEART =    /obj/item/organ/internal/heart/open,
		BP_BRAIN =    /obj/item/organ/internal/brain/xeno,
		BP_PLASMA =   /obj/item/organ/internal/xeno/plasmavessel/sentinel,
		BP_ACID =     /obj/item/organ/internal/xeno/acidgland,
		BP_HIVE =     /obj/item/organ/internal/xeno/hivenode,
		)

	inherent_verbs = list(
		/mob/living/proc/ventcrawl,
		/mob/living/carbon/human/proc/pry_open,
		/mob/living/carbon/human/proc/tackle,
		/mob/living/carbon/human/proc/regurgitate,
		/mob/living/carbon/human/proc/transfer_plasma,
		/mob/living/carbon/human/proc/corrosive_acid,
		/mob/living/carbon/human/proc/neurotoxin,
		/mob/living/carbon/human/proc/darksight,
		/mob/living/carbon/human/proc/scan_target
		)

	force_cultural_info = list(
		TAG_CULTURE =   CULTURE_XENOPHAGE_S,
		TAG_HOMEWORLD = HOME_SYSTEM_DEEP_SPACE,
		TAG_FACTION =   FACTION_XENOPHAGE,
		TAG_RELIGION =  RELIGION_OTHER
	)

/datum/species/xenos/queen

	name = "Xenophage Queen"
	total_health = 500
	weeds_heal_rate = 8
	weeds_plasma_rate = 20
	slowdown = 1
	rarity_value = 10

	icobase = 'icons/mob/human_races/species/xenos/r_xenos_queen.dmi'
	deform =  'icons/mob/human_races/species/xenos/r_xenos_queen.dmi'

	has_organ = list(
		BP_EYES =     /obj/item/organ/internal/eyes/xeno,
		BP_HEART =    /obj/item/organ/internal/heart/open,
		BP_BRAIN =    /obj/item/organ/internal/brain/xeno,
		BP_EGG =      /obj/item/organ/internal/xeno/eggsac,
		BP_PLASMA =   /obj/item/organ/internal/xeno/plasmavessel/queen,
		BP_ACID =     /obj/item/organ/internal/xeno/acidgland,
		BP_HIVE =     /obj/item/organ/internal/xeno/hivenode,
		BP_RESIN =    /obj/item/organ/internal/xeno/resinspinner,
		)

	inherent_verbs = list(
		/mob/living/proc/ventcrawl,
		/mob/living/carbon/human/proc/pry_open,
		/mob/living/carbon/human/proc/psychic_whisper,
		/mob/living/carbon/human/proc/regurgitate,
		/mob/living/carbon/human/proc/lay_egg,
		/mob/living/carbon/human/proc/plant,
		/mob/living/carbon/human/proc/transfer_plasma,
		/mob/living/carbon/human/proc/corrosive_acid,
		/mob/living/carbon/human/proc/neurotoxin,
		/mob/living/carbon/human/proc/resin,
		/mob/living/carbon/human/proc/xeno_infest,
		/mob/living/carbon/human/proc/darksight,
		/mob/living/carbon/human/proc/scan_target
		)

	genders = list(FEMALE)

	force_cultural_info = list(
		TAG_CULTURE =   CULTURE_XENOPHAGE_Q,
		TAG_HOMEWORLD = HOME_SYSTEM_DEEP_SPACE,
		TAG_FACTION =   FACTION_XENOPHAGE,
		TAG_RELIGION =  RELIGION_OTHER
	)

/datum/hud_data/alien

	icon = 'icons/mob/screen1_alien.dmi'
	has_a_intent =  1
	has_m_intent =  1
	has_warnings =  1
	has_hands =     1
	has_drop =      1
	has_throw =     1
	has_resist =    1
	has_pressure =  0
	has_nutrition = 0
	has_bodytemp =  0
	has_internals = 0

	gear = list(
		"o_clothing" =   list("loc" = ui_belt,      "name" = "Suit",         "slot" = slot_wear_suit, "state" = "equip",  "dir" = SOUTH),
		"head" =         list("loc" = ui_id,        "name" = "Hat",          "slot" = slot_head,      "state" = "hair"),
		"storage1" =     list("loc" = ui_storage1,  "name" = "Left Pocket",  "slot" = slot_l_store,   "state" = "pocket"),
		"storage2" =     list("loc" = ui_storage2,  "name" = "Right Pocket", "slot" = slot_r_store,   "state" = "pocket"),
		)