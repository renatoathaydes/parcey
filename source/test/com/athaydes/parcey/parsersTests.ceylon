import ceylon.test {
    test,
    assertEquals,
    assertFalse,
    fail
}

import com.athaydes.parcey {
    anyChar,
    ParseResult,
    letter,
    ParseError,
    oneOf,
    noneOf,
    eof,
    space,
    spaceChars,
    string
}
import com.athaydes.parcey.combinator {
    ...
}

test shared void testEof() {
    assert(is ParseResult<{String*}> result1 = eof.parse(""));
    assertEquals(result1.result.sequence(), []);
    assertEquals(result1.parsedIndex, 0);
    assertEquals(result1.consumedOk, []);
    assertEquals(result1.consumedFailed, []);
    
    assert(is ParseError result2 = eof.parse("a"));
    assertFalse(result2.message.empty);
    assertEquals(result2.consumedOk, []);
    assertEquals(result2.consumedFailed, []);
}

test shared void testAnyChar() {
    assert(is ParseResult<{String*}> result1 = anyChar.parse("a"));
    assertEquals(result1.result.sequence(), ["a"]);
    assertEquals(result1.parsedIndex, 1);
    assertEquals(result1.consumedOk, ['a']);
    assertEquals(result1.consumedFailed, []);
    
    assert(is ParseResult<{String*}> result2 = anyChar.parse("xyz"));
    assertEquals(result2.result.sequence(), ["x"]);
    assertEquals(result2.parsedIndex, 1);
    assertEquals(result2.consumedOk, ['x']);
    assertEquals(result2.consumedFailed, []);
    
    assert(is ParseError result3 = anyChar.parse(""));
    assertFalse(result3.message.empty);
    assertEquals(result3.consumedOk, []);
    assertEquals(result3.consumedFailed, []);
}

test shared void testLetter() {
    for (item in ('a'..'z').append('A'..'Z')) {
        assert(is ParseResult<{String*}> result = letter.parse({item}));
        assertEquals(result.result.sequence(), [item.string]);
        assertEquals(result.parsedIndex, 1);
        assertEquals(result.consumedOk, [item]);
        assertEquals(result.consumedFailed, []);
    }
    for (item in ['\t', ' ', '?', '!', '%', '^', '&', '*']) {
        assert(is ParseError result = letter.parse({item}));
        assertFalse(result.message.empty);
        assertEquals(result.consumedFailed, [item]);
        assertEquals(result.consumedOk, []);
    }
}

test shared void testSpace() {
    assert(is ParseError result1 = space.parse(""));
    assertFalse(result1.message.empty);
    assertEquals(result1.consumedOk, []);
    assertEquals(result1.consumedFailed, []);

    for (item in spaceChars) {
        value result = space.parse({item});
        if (is ParseResult<{String*}> result) {
            assertEquals(result.result.sequence(), [item.string]);
            assertEquals(result.parsedIndex, 1);
            assertEquals(result.consumedOk, [item]);
            assertEquals(result.consumedFailed, []);    
        } else {
            fail("Result was ```result``");
        }
    }
    
    assert(is ParseError result2 = space.parse("xy"));
    assertFalse(result2.message.empty);
    assertEquals(result2.consumedOk, []);
    assertEquals(result2.consumedFailed, ['x']);
}

test shared void testString() {
    assert(is ParseResult<String> result1 = string.parse(""));
    assertEquals(result1.result, "");
    assertEquals(result1.parsedIndex, 0);
    assertEquals(result1.consumedOk, []);
    assertEquals(result1.consumedFailed, []);
    
    assert(is ParseResult<String> result2 = string.parse("a"));
    assertEquals(result2.result, "a");
    assertEquals(result2.parsedIndex, 1);
    assertEquals(result2.consumedOk, ['a']);
    assertEquals(result2.consumedFailed, []);
    
    assert(is ParseResult<String> result3 = string.parse("xyz abc"));
    assertEquals(result3.result, "xyz");
    assertEquals(result3.parsedIndex, 3);
    assertEquals(result3.consumedOk, ['x', 'y', 'z']);
    assertEquals(result3.consumedFailed, [' ']);
}

test shared void testOneOf() {
    value parser = oneOf('x', 'a');
    
    value result1 = parser.parse("");
    if (is ParseError result1) {
        assertFalse(result1.message.empty);
        assertEquals(result1.consumedFailed, []);
        assertEquals(result1.consumedOk, []);
    } else {
        fail("Result was ``result1``");
    }
    
    for (item in ['x', 'a']) {
        value result = parser.parse({item});
        if (is ParseResult<{String*}> result) {
            assertEquals(result.result.sequence(), [item.string]);
            assertEquals(result.parsedIndex, 1);
            assertEquals(result.consumedOk, [item]);
            assertEquals(result.consumedFailed, []);    
        } else {
            fail("Result was ``result``");
        }
        
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        value result = parser.parse({item});
        if (is ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumedFailed, [item]);
            assertEquals(result.consumedOk, []);
        } else {
            fail("Result was ``result``");
        }
    }
}

test shared void testNoneOf() {
    value parser = noneOf('x', 'a');
    
    value result1 = parser.parse("");
    if (is ParseResult<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parsedIndex, 0);
        assertEquals(result1.consumedOk, []);
        assertEquals(result1.consumedFailed, []);    
    } else {
        fail("Result was ``result1``");
    }
    
    for (item in ['x', 'a']) {
        value result = parser.parse({item});
        if (is ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumedFailed, [item]);
            assertEquals(result.consumedOk, []);
        } else {
            fail("Result was ``result``");
        }
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        value result = parser.parse({item});
        if (is ParseResult<{String*}> result) {
            assertEquals(result.result.sequence(), [item.string]);
            assertEquals(result.parsedIndex, 1);
            assertEquals(result.consumedOk, [item]);
            assertEquals(result.consumedFailed, []);    
        } else {
            fail("Result was ``result``");
        }
    }
}
