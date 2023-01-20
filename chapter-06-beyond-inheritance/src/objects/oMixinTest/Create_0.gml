show_debug_message("\n");
show_debug_message("Mixin Tests");
show_debug_message("====================================");
show_debug_message("\n------------------------------------");
show_debug_message("Before Mixin Applied:");
show_debug_message("------------------------------------");

var original = new OriginalClass();
original.valueOverrideExample();        // Prints '1'
original.methodToOverride();            // Prints 'original'

// Apply mixin
Mixin.apply(original, MixinTest);

show_debug_message("\n------------------------------------");
show_debug_message("After Mixin Applied:");
show_debug_message("------------------------------------");

original.valueOverrideExample();        // Prints '7'
original.methodToOverride();            // Prints 'overridden'
original.extendingMethod();             // Prints 'new behaviour'
show_debug_message("\n");
