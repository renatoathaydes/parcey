import ceylon.language.meta {
	type
}
import ceylon.language.meta.model {
	Type
}
import ceylon.test {
	assertEquals
}

shared class TypeAssertion<out Expected>(
	Anything instance, 
	Type<Expected> expectedType,
	Boolean exactMatch = false) {
	
	// gives a good  error message
	if (exactMatch) {
		assertEquals(type(instance), `Expected`,
			"Result does not have the expected type");
	} else {
		if (!type(instance).subtypeOf(`Expected`)) {
			throw AssertionError("Result is not a subtype of `` `Expected` ``: \
			                      ``type(instance)``");
		}
	}
	// narrow the type
	assert (is Expected instance);
	
	shared void with(void assertions(Expected expected)) {
		assertions(instance);
	}
}

shared class AssertionMaker(Anything instance) {
	
	shared TypeAssertion<Expected> ofType<Expected>(Type<Expected> expectedType)
		=> TypeAssertion(instance, expectedType, true);
	
	shared TypeAssertion<Expected> assignableTo<Expected>(Type<Expected> expectedType)
		=> TypeAssertion(instance, expectedType, false);
	
}

shared AssertionMaker expect(Anything actual) => AssertionMaker(actual);
