show_debug_message("\n");
show_debug_message("Inheritance Tests");
show_debug_message("====================================");
show_debug_message("\n------------------------------------");
show_debug_message("pEnemy");
show_debug_message("------------------------------------");

var parent = instance_create_layer(x, y, layer, pEnemy);
parent.attack();				 // Prints 'pEnemy::attack - Regular Attack'

show_debug_message("\n------------------------------------");
show_debug_message("oStrongEnemy (Override Example)");
show_debug_message("------------------------------------");

var strong = instance_create_layer(x, y, layer, oStrongEnemy);
strong.attack();				 // Prints 'oStrongEnemy::attack - Double Attack'

show_debug_message("\n------------------------------------");
show_debug_message("oSpecialEnemy (Extention Example)");
show_debug_message("------------------------------------");

var special = instance_create_layer(x, y, layer, oSpecialEnemy);
special.attack();				// Prints 'pEnemy::attack - Regular Attack'
special.specialAttack();        // Prints 'oSpecialEnemy::specialAttack - Special Attack'

show_debug_message("\n");
