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
    ParseError,
    char,
    string,
    space,
    anyString
}
import com.athaydes.parcey.combinator {
    either,
    parserChain,
    many,
    skipMany,
    option
}

test
shared void canParseNonStableStream() {
    value parser = parserChain(anyChar, oneOf(' '), anyChar);
    
    value result = parser.parse(object satisfies Iterable<Character> {
            value data = { 'a', ' ', 'b' }.iterator();
            iterator() => data;
        });
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', ' ', 'b']);
        assertEquals(result.parseLocation, [0, 3]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanParseAllAlternatives() {
    value parser = either(char('a'), string("hi"), space);
    
    value result1 = parser.parse("a");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result, ['a']);
        assertEquals(result1.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = parser.parse("hi");
    if (is ParseResult<String> result2) {
        assertEquals(result2.result, "hi");
        assertEquals(result2.parseLocation, [0, 2]);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = parser.parse(" ");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result, [' ']);
        assertEquals(result3.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result3``");
    }
}

test
shared void eitherCombinatorCanBacktrackOnce() {
    value parser = either(oneOf('a'), oneOf('b'));
    
    value result = parser.parse("b");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackTwice() {
    value parser = either(oneOf('a'), oneOf('b'), oneOf('c'));
    
    value result = parser.parse("c");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
        assertEquals(result.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackSeveralCharacters() {
    value parser = either(string("hello world"), string("hello john"));
    
    value result = parser.parse("hello john");
    
    if (is ParseResult<String> result) {
        assertEquals(result.result, "hello john");
        assertEquals(result.parseLocation, [0, 10]);
        assertEquals(result.consumed, "hello john".sequence());
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorSimpleTest() {
    value result = many(oneOf('a')).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'a']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorEmptyInputTest() {
    value result = many(char('a')).parse("b");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed, []);
        assertEquals(result.overConsumed, ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorDoesNotConsumeNextToken() {
    value result = parserChain(many(char('a')), char('b')).parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorSimpleTest() {
    value result = many(char('a'), 1).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'a']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorTooShortInputTest() {
    value result = many(char('a'), 1).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorDoesNotConsumeNextToken() {
    value result = parserChain(many(char('a'), 1), char('b')).parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many3CombinatorTooShortInputTest() {
    value result = many(char('a'), 3).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many3CombinatorDoesNotConsumeNextToken() {
    value result = parserChain<Character>(many(oneOf('a'), 3), oneOf('b')).parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.consumed, ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorSimpleTest() {
    value result = skipMany(char('a')).parse("aaa");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'a']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorEmptyInputTest() {
    value result = skipMany(char('a')).parse("b");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed, []);
        assertEquals(result.overConsumed, ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorDoesNotConsumeNextToken() {
    value result1 = skipMany(char('a')).parse("axy");
    if (is ParseResult<[]> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parseLocation, [0, 1]);
        assertEquals(result1.consumed, ['a']);
        assertEquals(result1.overConsumed, ['x']);
    } else {
        fail("Result was ``result1``");
    }
    
    value result = parserChain(skipMany(char('a')), char('b')).parse("aab");
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result, ['b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorSimpleTest() {
    value result = skipMany(char('a'), 1).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'a']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipmany1CombinatorTooShortInputTest() {
    value result = skipMany(char('a'), 1).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorDoesNotConsumeNextToken() {
    value result = parserChain(skipMany(char('a'), 1), char('b')).parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany3CombinatorTooShortInputTest() {
    value result = skipMany(char('a'), 3).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany3CombinatorDoesNotConsumeNextToken() {
    value result = parserChain(skipMany(char('a'), 3), char('b')).parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.consumed, ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void testOption() {
    value parser = option(char('a'));
    if (is ParseResult<Character[]> result = parser.parse("")) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed, []);
        assertEquals(result.overConsumed, []);
    }
    
    if (is ParseResult<Character[]> result = parser.parse("a")) {
        assertEquals(result.result, ['a']);
        assertEquals(result.parseLocation, [0, 1]);
        assertEquals(result.consumed, ['a']);
        assertEquals(result.overConsumed, []);
    }
    
    if (is ParseResult<Character[]> result = parser.parse("b")) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed, []);
        assertEquals(result.overConsumed, ['b']);
    }
}

test
shared void parserChainSimpleTest() {
    for (singleParser in [char('a'), anyString, space]) {
        for (index->input in ["", "0", "\n", " ", "a", "abc", "123", " xxx yyy"].indexed) {
            value result1 = singleParser.parse(input);
            value result2 = parserChain(singleParser).parse(input);
            value errorMessage = "Parser index: ``index``, Input: ``input``";
            assertResultsEqual(result1, result2, errorMessage);
            assertParseLocationsEqual(result1, result2, errorMessage);
        }
    }
}

test
shared void parserChain2ParsersTest() {
    for (index->parserPair in [[char('a'), char(' ')], [anyString, char(' ')], [space, string("xxmn")]].indexed) {
        for (input in ["", "0", "\n", " ", "a", "a b c", "123", " abc", " xxx yyy"]) {
            value result1 = parserPair[0].parse(input);
            value nonParsed = input.sublistFrom(result1.consumed.size);
            value x = String(nonParsed);
            value result2 = parserPair[1].parse(x);
            value totalResult = parserChain(*parserPair).parse(input);
            value expectedResult = findExpectedResult(result1, result2);
            value errorMessage = "Parser index: ``index``, Input: '``input``'";
            assertResultsEqual(totalResult, expectedResult, errorMessage);
        }
    }
}

void assertResultsEqual(
    ParseResult<{Character*}>|ParseError actualResult,
    ParseResult<{Character*}>|ParseError expectedResult,
    String errorMessage) {
    switch (actualResult)
    case (is ParseResult<{Character*}>) {
        if (is ParseResult<{Character*}> expectedResult) {
            assertEquals(actualResult.result.sequence(), expectedResult.result.sequence(), errorMessage);
            assertEquals(actualResult.consumed, expectedResult.consumed, errorMessage);
            assertEquals(expectedResult.overConsumed, expectedResult.overConsumed, errorMessage);
        } else {
            fail("``errorMessage`` - Results have different types: ``actualResult``, ``expectedResult``");
        }
    }
    case (is ParseError) {
        if (is ParseError expectedResult) {
            "The parseLocation of the messages will differ because we don't calculate it in the test code."
            String relevantPartOf(String message)
                    => String(message.sublistTo(2 + (message.inclusions("at row").first else -1)));
            assertEquals(relevantPartOf(actualResult.message), relevantPartOf(expectedResult.message), errorMessage);
            assertEquals(actualResult.consumed, expectedResult.consumed, errorMessage);
        } else {
            fail("``errorMessage`` - Results have different types: ``actualResult``, ``expectedResult``");
        }
    }
}

void assertParseLocationsEqual(
    ParseResult<{Character*}>|ParseError actualResult,
    ParseResult<{Character*}>|ParseError expectedResult,
    String errorMessage) {
    if (is ParseResult<{Character*}>? actualResult,
        is ParseResult<{Character*}> expectedResult) {
        assertEquals(actualResult.parseLocation, expectedResult.parseLocation, errorMessage);
    }
}

ParseResult<{Character*}>|ParseError findExpectedResult(ParseResult<Character[]|String>|ParseError result1, ParseResult<Character[]|String>|ParseError result2) {
    switch (result1)
    case (is ParseResult<{Character*}>) {
        switch (result2)
        case (is ParseResult<{Character*}>) {
            return ParseResult(
                result1.result.sequence().append(result2.result.sequence()),
                result2.parseLocation,
                result1.consumed.append(result2.consumed),
                result1.overConsumed.append(result2.overConsumed));
        }
        case (is ParseError) {
            return ParseError(
                result2.message,
                result1.consumed.append(result2.consumed));
        }
    }
    case (is ParseError) {
        return result1;
    }
}
