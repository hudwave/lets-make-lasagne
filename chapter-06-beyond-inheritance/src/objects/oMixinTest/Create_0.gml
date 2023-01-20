var original = new OriginalClass();
original.valueOverrideExample();        // Prints '1'
original.methodToOverride();            // Prints 'original'

// Apply mixin
Mixin.apply(original, MixinTest);

original.valueOverrideExample();        // Prints '7'
original.methodToOverride();            // Prints 'overridden'
original.extendingMethod();             // Prints 'new behaviour'
