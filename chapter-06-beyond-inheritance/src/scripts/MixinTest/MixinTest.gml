// A struct class
function OriginalClass() constructor {
    valueToOverride = 1;
    
    valueOverrideExample = function () {
         show_debug_message("Value Override: {0}", valueToOverride);
    }

    methodToOverride = function () {
        show_debug_message("Method Override: {0}", "original");
    }
}

// A mixin
function MixinTest() constructor {
    valueToOverride = 7;

    methodToOverride = function () {
        show_debug_message("Method Override: {0}", "overridden");
    }

    extendingMethod = function () {
        show_debug_message("Method Extension: {0}", "new behaviour");
    }
}
