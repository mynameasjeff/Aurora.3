/obj/structure/bigDelivery
	desc = "A big wrapped package."
	name = "large parcel"
	icon = 'icons/obj/storage/misc.dmi'
	icon_state = "deliverycloset"
	var/obj/wrapped = null
	density = 1
	var/sortTag = null
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	var/examtext = null
	var/nameset = 0
	var/label_y
	var/label_x
	var/tag_x

/obj/structure/bigDelivery/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(distance <= 4)
		if(sortTag)
			. += SPAN_NOTICE("It is labeled \"[sortTag]\".")
		if(examtext)
			. += SPAN_NOTICE("It has a note attached which reads, \"[examtext]\".")

/obj/structure/bigDelivery/attack_hand(mob/user as mob)
	unwrap()

/obj/structure/bigDelivery/attack_ai(mob/user)
	if(isrobot(user) && Adjacent(user)) // Robots can open packages.
		attack_hand(user)

/obj/structure/bigDelivery/proc/unwrap()
	playsound(loc, 'sound/items/package_unwrap.ogg', 50, 1)
	if(wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove(get_turf(src.loc))
		if(istype(wrapped, /obj/structure/closet))
			var/obj/structure/closet/O = wrapped
			O.welded = 0
	qdel(src)

/obj/structure/bigDelivery/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = attacking_item
		if(O.currTag)
			if(src.sortTag != O.currTag)
				to_chat(user, SPAN_NOTICE("You have labeled the destination as [O.currTag]."))
				if(!src.sortTag)
					src.sortTag = O.currTag
					update_icon()
				else
					src.sortTag = O.currTag
				playsound(src.loc, 'sound/machines/twobeep.ogg', 50, 1)
			else
				to_chat(user, SPAN_WARNING("The package is already labeled for [O.currTag]."))
		else
			to_chat(user, SPAN_WARNING("You need to set a destination first!"))

	else if(attacking_item.ispen())
		switch(alert("What would you like to alter?",,"Title","Description", "Cancel"))
			if("Title")
				var/str = sanitizeSafe(input(usr,"Label text?","Set label",""), MAX_NAME_LEN)
				if(!str || !length(str))
					to_chat(usr, SPAN_WARNING("Invalid text."))
					return
				user.visible_message("\The [user] titles \the [src] with \a [attacking_item], marking down: \"[str]\"",\
				SPAN_NOTICE("You title \the [src]: \"[str]\""),\
				"You hear someone scribbling a note.")
				playsound(src, pick('sound/bureaucracy/pen1.ogg','sound/bureaucracy/pen2.ogg'), 20)
				name = "[name] ([str])"
				if(!examtext && !nameset)
					nameset = 1
					update_icon()
				else
					nameset = 1
			if("Description")
				var/str = sanitize(input(usr,"Label text?","Set label",""))
				if(!str || !length(str))
					to_chat(usr, SPAN_WARNING("Invalid text."))
					return
				if(!examtext && !nameset)
					examtext = str
					update_icon()
				else
					examtext = str
				user.visible_message("\The [user] labels \the [src] with \a [attacking_item], scribbling down: \"[examtext]\"",\
				SPAN_NOTICE("You label \the [src]: \"[examtext]\""),\
				"You hear someone scribbling a note.")
				playsound(src, pick('sound/bureaucracy/pen1.ogg','sound/bureaucracy/pen2.ogg'), 20)
	return

/obj/structure/bigDelivery/update_icon()
	ClearOverlays()
	if(nameset || examtext)
		var/image/I = new/image('icons/obj/storage/misc.dmi',"delivery_label")
		if(icon_state == "deliverycloset")
			I.pixel_x = 2
			if(label_y == null)
				label_y = rand(-6, 11)
			I.pixel_y = label_y
		else if(icon_state == "deliverycrate")
			if(label_x == null)
				label_x = rand(-8, 6)
			I.pixel_x = label_x
			I.pixel_y = -3
		AddOverlays(I)
	if(src.sortTag)
		var/image/I = new/image('icons/obj/storage/misc.dmi',"delivery_tag")
		if(icon_state == "deliverycloset")
			if(tag_x == null)
				tag_x = rand(-2, 3)
			I.pixel_x = tag_x
			I.pixel_y = 9
		else if(icon_state == "deliverycrate")
			if(tag_x == null)
				tag_x = rand(-8, 6)
			I.pixel_x = tag_x
			I.pixel_y = -3
		AddOverlays(I)

/obj/item/smallDelivery
	desc = "A small wrapped package."
	name = "small parcel"
	icon = 'icons/obj/storage/misc.dmi'
	icon_state = "deliverycrate3"
	drop_sound = 'sound/items/drop/cardboardbox.ogg'
	pickup_sound = 'sound/items/pickup/cardboardbox.ogg'
	var/obj/item/wrapped = null
	var/sortTag = null
	var/examtext = null
	var/nameset = 0
	var/tag_x

/obj/item/smallDelivery/attack_self(mob/user as mob)
	if (src.wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove(user.loc)
		to_chat(user, SPAN_NOTICE("You tear open the parcel, revealing \a [wrapped]!"))
		if(ishuman(user))
			user.put_in_hands(wrapped)
		else if(isrobot(user))
			var/obj/item/gripper/G = user.get_active_hand()
			if(istype(G))
				G.drop(src, user, FALSE)
				if(is_type_in_list(wrapped, G.can_hold))
					G.grip_item(wrapped, user, FALSE)
				else
					to_chat(user, SPAN_WARNING("\The [wrapped] tumbles from \the [G] as you unwrap it!"))
					wrapped.forceMove(get_turf(src))
			else
				wrapped.forceMove(get_turf(src))
		else
			wrapped.forceMove(get_turf(src))

	qdel(src)
	return

/obj/item/smallDelivery/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/device/destTagger))
		var/obj/item/device/destTagger/O = attacking_item
		if(O.currTag)
			if(src.sortTag != O.currTag)
				to_chat(user, SPAN_NOTICE("You have labeled the destination as [O.currTag]."))
				if(!src.sortTag)
					src.sortTag = O.currTag
					update_icon()
				else
					src.sortTag = O.currTag
				playsound(src.loc, 'sound/machines/twobeep.ogg', 50, 1)
			else
				to_chat(user, SPAN_WARNING("The package is already labeled for [O.currTag]."))
		else
			to_chat(user, SPAN_WARNING("You need to set a destination first!"))

	else if(attacking_item.ispen())
		switch(tgui_input_list(user, "What would you like to alter?", null, list("Title", "Description"), "Cancel"))
			if("Title")
				var/str = sanitizeSafe( tgui_input_text(usr, "Label text?", "Set label", "", MAX_NAME_LEN), MAX_NAME_LEN )
				if(!str || !length(str))
					to_chat(usr, SPAN_WARNING("Invalid text."))
					return
				user.visible_message("\The [user] titles \the [src] with \a [attacking_item], marking down: \"[str]\"",\
				SPAN_NOTICE("You title \the [src]: \"[str]\""),\
				"You hear someone scribbling a note.")
				playsound(src, pick('sound/bureaucracy/pen1.ogg','sound/bureaucracy/pen2.ogg'), 20)
				name = "[name] ([str])"
				if(!examtext && !nameset)
					nameset = 1
					update_icon()
				else
					nameset = 1

			if("Description")
				var/str = sanitize(tgui_input_text(usr, "Label text?", "Set label", ""))
				if(!str || !length(str))
					to_chat(usr, SPAN_WARNING("Invalid text."))
					return
				if(!examtext && !nameset)
					examtext = str
					update_icon()
				else
					examtext = str
				user.visible_message("\The [user] labels \the [src] with \a [attacking_item], scribbling down: \"[examtext]\"",\
				SPAN_NOTICE("You label \the [src]: \"[examtext]\""),\
				"You hear someone scribbling a note.")
				playsound(src, pick('sound/bureaucracy/pen1.ogg','sound/bureaucracy/pen2.ogg'), 20)
	return

/obj/item/smallDelivery/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(distance <= 4)
		if(sortTag)
			. += SPAN_NOTICE("It is labeled \"[sortTag]\".")
		if(examtext)
			. += SPAN_NOTICE("It has a note attached which reads, \"[examtext]\".")

/obj/item/smallDelivery/update_icon()
	ClearOverlays()
	if((nameset || examtext) && icon_state != "deliverycrate1")
		var/image/I = new/image('icons/obj/storage/misc.dmi',"delivery_label")
		if(icon_state == "deliverycrate5")
			I.pixel_y = -1
		AddOverlays(I)
	if(src.sortTag)
		var/image/I = new/image('icons/obj/storage/misc.dmi',"delivery_tag")
		switch(icon_state)
			if("deliverycrate1")
				I.pixel_y = -5
			if("deliverycrate2")
				I.pixel_y = -2
			if("deliverycrate3")
				I.pixel_y = 0
			if("deliverycrate4")
				if(tag_x == null)
					tag_x = rand(0,5)
				I.pixel_x = tag_x
				I.pixel_y = 3
			if("deliverycrate5")
				I.pixel_y = -3
		AddOverlays(I)

/obj/structure/bigDelivery/Destroy()
	if(wrapped) //sometimes items can disappear. For example, bombs. --rastaf0
		wrapped.forceMove((get_turf(loc)))
		if(istype(wrapped, /obj/structure/closet))
			var/obj/structure/closet/O = wrapped
			O.welded = 0
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in contents)
		AM.forceMove(T)
	return ..()

/obj/item/device/destTagger
	name = "destination tagger"
	desc = "Used to set the destination of properly wrapped packages."
	icon = 'icons/obj/item/device/dest_tagger.dmi'
	icon_state = "dest_tagger"
	var/currTag = 0
	matter = list(DEFAULT_WALL_MATERIAL = 250, MATERIAL_GLASS = 140)
	w_class = WEIGHT_CLASS_SMALL
	obj_flags = OBJ_FLAG_CONDUCTABLE
	slot_flags = SLOT_BELT

/obj/item/device/destTagger/proc/openwindow(mob/user)
	var/dat = "<tt><center><h1><b>TagMaster 2.3</b></h1></center>"

	dat += "<table style='width:100%; padding:4px;'><tr>"
	for(var/i = 1, i <= SSdisposals.tagger_locations.len, i++)
		dat += "<td><a href='byond://?src=[REF(src)];nextTag=[html_encode(SSdisposals.tagger_locations[i])]'>[SSdisposals.tagger_locations[i]]</a></td>"

		if (i % 4==0)
			dat += "</tr><tr>"

	dat += "</tr></table><br>Current Selection: [currTag ? currTag : "None"]</tt>"
	dat += "<br><a href='byond://?src=[REF(src)];nextTag=CUSTOM'>Enter custom location.</a>"
	user << browse(HTML_SKELETON(dat), "window=destTagScreen;size=450x375")
	onclose(user, "destTagScreen")

/obj/item/device/destTagger/attack_self(mob/user)
	openwindow(user)
	return

/obj/item/device/destTagger/Topic(href, href_list)
	src.add_fingerprint(usr)

	if(href_list["nextTag"] && (html_decode(href_list["nextTag"]) in SSdisposals.tagger_locations))
		src.currTag = html_decode(href_list["nextTag"])

	if(href_list["nextTag"] == "CUSTOM")
		var/dest = input("Please enter custom location.", "Location", src.currTag ? src.currTag : "None")
		if(dest != "None")
			src.currTag = dest
		else
			src.currTag = 0

	openwindow(usr)

/obj/machinery/disposal/deliveryChute
	name = "delivery chute"
	desc = "A chute for big and small packages alike!"
	density = 1
	icon_state = "intake"

	var/c_mode = 0

/obj/machinery/disposal/deliveryChute/Initialize()
	. = ..()
	trunk = locate() in src.loc
	if(trunk)
		trunk.linked = src	// link the pipe trunk to self

/obj/machinery/disposal/deliveryChute/interact()
	return

/obj/machinery/disposal/deliveryChute/update()
	return

/obj/machinery/disposal/deliveryChute/CollidedWith(atom/bumped_atom) //Go straight into the chute
	. = ..()

	if(istype(bumped_atom, /obj/projectile) || istype(bumped_atom, /obj/effect))
		return

	switch(dir)
		if(NORTH)
			if(bumped_atom.loc.y != src.loc.y+1) return
		if(EAST)
			if(bumped_atom.loc.x != src.loc.x+1) return
		if(SOUTH)
			if(bumped_atom.loc.y != src.loc.y-1) return
		if(WEST)
			if(bumped_atom.loc.x != src.loc.x-1) return

	if(istype(bumped_atom, /obj))
		var/obj/O = bumped_atom
		O.forceMove(src)
	else if(istype(bumped_atom, /mob))
		var/mob/M = bumped_atom
		M.forceMove(src)
	INVOKE_ASYNC(src, PROC_REF(flush))

/obj/machinery/disposal/deliveryChute/flush()
	flushing = TRUE
	flick("intake-closing", src)
	var/obj/disposalholder/H = new()	// virtual holder object which actually
												// travels through the pipes.
	air_contents = new()		// new empty gas resv.

	sleep(10)
	playsound(src, 'sound/machines/disposalflush.ogg', 50, 0, 0)
	sleep(5) // wait for animation to finish

	H.init(src)	// copy the contents of disposer to holder

	H.start(src) // start the holder processing movement
	flushing = FALSE
	// now reset disposal state
	flush = 0
	if(mode == 2)	// if was ready,
		mode = 1	// switch to charging
	update()
	return

/obj/machinery/disposal/deliveryChute/attackby(obj/item/attacking_item, mob/user)
	if(!attacking_item || !user)
		return

	if(istype(attacking_item, /obj/item/holder))
		user.drop_item(attacking_item)
		CollidedWith(attacking_item)

	if(attacking_item.isscrewdriver())
		if(c_mode==0)
			c_mode=1
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, "You remove the screws around the power connection.")
			return
		else if(c_mode==1)
			c_mode=0
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, "You attach the screws around the power connection.")
			return
	else if(attacking_item.iswelder() && c_mode==1)
		var/obj/item/weldingtool/W = attacking_item
		if(W.use(1,user))
			to_chat(user, "You start slicing the floorweld off the delivery chute.")
			if(W.use_tool(src, user, 20, volume = 50))
				if(!src || !W.isOn()) return
				to_chat(user, "You sliced the floorweld off the delivery chute.")
				var/obj/structure/disposalconstruct/C = new (src.loc)
				C.ptype = 8 // 8 =  Delivery chute
				C.update()
				C.anchored = 1
				C.density = 1
				qdel(src)
			return
		else
			to_chat(user, "You need more welding fuel to complete this task.")
			return

/obj/machinery/disposal/deliveryChute/Destroy()
	if(trunk)
		trunk.linked = null
	return ..()
