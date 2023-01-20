show_debug_message("\n");
show_debug_message("Direct Manipulation Tests");
show_debug_message("====================================");

show_debug_message("\n------------------------------------");
show_debug_message("Override Example Before:");
show_debug_message("------------------------------------");

function OverrideExample() constructor {
    methodToOverride = function () {
        show_debug_message("original");
    }
}

// Create instance and test original method
var overrideTest = new OverrideExample();
overrideTest.methodToOverride();		// Prints 'original'

// Create new method to override original behaviour
var overridingMethod = method(overrideTest, function () {
    show_debug_message("overridden");
});

show_debug_message("\n------------------------------------");
show_debug_message("Override Example After:");
show_debug_message("------------------------------------");

// Override method
overrideTest.methodToOverride = overridingMethod;
overrideTest.methodToOverride();		// Prints 'overridden'

show_debug_message("\n------------------------------------");
show_debug_message("Extension Example:");
show_debug_message("------------------------------------");

function ExtensionExample() constructor {
    baseMethod = function () {
        show_debug_message("original");
    }
}

// Create instance
var extentionTest = new ExtensionExample();

// Create new method to extend original behaviour and
// bind it to the context of the instance
var extendingMethod = method(extentionTest, function () {
    show_debug_message("new behaviour");
});

// Extend class and test both methods
extentionTest.extendedMethod = extendingMethod;
extentionTest.baseMethod();				// Prints 'original'
extentionTest.extendedMethod();			// Prints 'new behaviour'

show_debug_message("\n");
