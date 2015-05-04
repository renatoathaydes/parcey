import ceylon.test {
    test,
    assertEquals,
    fail,
    assertFalse
}

import com.athaydes.parcey {
    ParseResult,
    oneOf,
    anyChar,
    ParseError
}
import com.athaydes.parcey.combinator {
    either,
    parserChain,
    many
}

test shared void canParseNonStableStream() {
    value parser = parserChain(anyChar, oneOf(' '), anyChar);
    
    value result = parser.parse(object satisfies Iterable<Character> {
        value data = {'a', ' ', 'b'}.iterator();
        iterator() => data;
    });
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", " ", "b"]);
        assertEquals(result.parsedIndex, 3);
    } else {
        fail("Result was ``result``");
    }
}

test shared void eitherCombinatorCanBacktrackOnce() {
    value parser = either(oneOf('a'), oneOf('b'));
    
    value result = parser.parse("b");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["b"]);
        assertEquals(result.parsedIndex, 1);
    } else {
        fail("Result was ``result``");
    }
}

test shared void eitherCombinatorCanBacktrackTwice() {
    value parser = either(oneOf('a'), oneOf('b'), oneOf('c'));
    
    value result = parser.parse("c");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["c"]);
        assertEquals(result.parsedIndex, 1);
    } else {
        fail("Result was ``result``");
    }
}

test shared void manyCombinatorSimpleTest() {
    value result = many(oneOf('a')).parse("aaa");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", "a", "a"]);
        assertEquals(result.parsedIndex, 3);
        assertEquals(result.consumedOk, ['a', 'a', 'a']);
    } else {
        fail("Result was ``result``");
    }
}

test shared void manyCombinatorEmptyInputTest() {
    value result = many(oneOf('a')).parse("b");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parsedIndex, 0);
        assertEquals(result.consumedFailed, ['b']);
        assertEquals(result.consumedOk, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void manyCombinatorDoesNotConsumeNextToken() {
    value result = parserChain(many(oneOf('a')), oneOf('b')).parse("aab");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", "a", "b"]);
        assertEquals(result.parsedIndex, 3);
        assertEquals(result.consumedOk, ['b']);
        assertEquals(result.consumedFailed, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void many1CombinatorSimpleTest() {
    value result = many(oneOf('a'), 1).parse("aaa");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", "a", "a"]);
        assertEquals(result.parsedIndex, 3);
        assertEquals(result.consumedOk, ['a', 'a', 'a']);
        assertEquals(result.consumedFailed, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void many1CombinatorTooShortInputTest() {
    value result = many(oneOf('a'), 1).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumedFailed, ['b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test shared void many1CombinatorDoesNotConsumeNextToken() {
    value result = parserChain(many(oneOf('a'), 1), oneOf('b')).parse("aab");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", "a", "b"]);
        assertEquals(result.parsedIndex, 3);
        assertEquals(result.consumedOk, ['b']);
        assertEquals(result.consumedFailed, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void many3CombinatorTooShortInputTest() {
    value result = many(oneOf('a'), 3).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumedFailed, ['b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test shared void many3CombinatorDoesNotConsumeNextToken() {
    value result = parserChain(many(oneOf('a'), 3), oneOf('b')).parse("aaaab");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["a", "a", "a", "a", "b"]);
        assertEquals(result.parsedIndex, 5);
        assertEquals(result.consumedOk, ['b']);
        assertEquals(result.consumedFailed, []);
    } else {
        fail("Result was ``result``");
    }
}
