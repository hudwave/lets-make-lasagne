// A struct class
function OriginalClass() constructor {
    valueToOverride = 1;
    
    valueOverrideExample = function () {
         show_debug_message(valueToOverride);
    }

    methodToOverride = function () {
        show_debug_message("original");
    }
}

// A mixin
function MixinTest() constructor {
    valueToOverride = 7;

    methodToOverride = function () {
        show_debug_message("overridden");
    }

    extendingMethod = function () {
        show_debug_message("new behaviour");
    }
}
