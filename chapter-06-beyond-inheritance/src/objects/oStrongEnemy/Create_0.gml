event_inherited();

// By redefining attack it will override the
// method defined in the parent object.
attack = function () {
    show_debug_message("oStrongEnemy::attack - Double Attack");
}
