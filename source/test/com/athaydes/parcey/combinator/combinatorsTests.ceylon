import ceylon.test {
    test,
    assertEquals,
    fail,
    assertFalse
}

import com.athaydes.parcey {
    ParseResult,
    anyChar,
    ParseError,
    char,
    oneString,
    space,
    noneOf,
    spaceChars,
    ParsedLocation,
    asSingleValueParser,
    integer,
    Parser,
    stringParser,
    spaces
}
import com.athaydes.parcey.combinator {
    either,
    seq,
    many,
    option,
    skip,
    sepBy,
    around
}

test
shared void canParseNonStableStream() {
    value parser = seq {
        anyChar(), char(' '), anyChar()
    };
    
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
    value parser = either {
        char('a'), oneString("hi"), space()
    };
    
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
    value parser = either {
        char('a'), char('b')
    };
    
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
    value parser = either {
        char('a'), char('b'), char('c')
    };
    
    value result = parser.parse("c");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
        assertEquals(result.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackThrice() {
    value parser = either {
        oneString("abcd"), oneString("abcef"), oneString("abceg")
    };
    
    value result = parser.parse("abcegh");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'b', 'c', 'e', 'g']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorDoesNotConsumeNextToken() {
    value parser = either { oneString("ab"), oneString("ac") };
    
    value result = parser.parse("ade");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['a', 'd']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorSimpleTest() {
    value result = many(char('a')).parse("aaa");
    
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
    value result = many(char('a')).parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
        assertEquals(result.parseLocation, [0, 2]);
        assertEquals(result.consumed, ['a', 'a']);
        assertEquals(result.overConsumed, ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    value result = many(oneString("abc")).parse("abcabcabcdef");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c']);
        assertEquals(result.parseLocation, [0, 9]);
        assertEquals(result.consumed, ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c']);
        assertEquals(result.overConsumed, ['d']);
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
    value result = seq { many(char('a'), 1), char('b') }
            .parse("aab");
    
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
    value result = seq({
        many(char('a'), 3), char('b')
    }).parse("aaaab");
    
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
shared void manySeqCombinationTest() {
    value manySeq = many(seq { char('x'), skip(char(',')) });
    
    value result1 = manySeq.parse("x,x,x!");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x']);
        assertEquals(result1.parseLocation, [0, 4]);
        assertEquals(result1.consumed, ['x', ',', 'x', ',']);
        assertEquals(result1.overConsumed, ['x', '!']);
    } else {
        fail("Result was ``result1``");
    }
}

test
shared void manySeqManyCombinationTest() {
    value parser = many(seq { skip(char('.')), many(char('x')) });
    
    value result1 = parser.parse(".x.xxx..x!x");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x', 'x', 'x', 'x']);
        assertEquals(result1.parseLocation, [0, 9]);
        assertEquals(result1.consumed, ['.', 'x', '.', 'x', 'x', 'x', '.', '.', 'x']);
        assertEquals(result1.overConsumed, ['!']);
    } else {
        fail("Result was ``result1``");
    }
}
test
shared void skipManyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    value result = skip(many(oneString("abc"))).parse("abcabcabcdef");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 9]);
        assertEquals(result.consumed, ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c']);
        assertEquals(result.overConsumed, ['d']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorSimpleTest() {
    value result = skip(many(char('a'))).parse("aaa");
    
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
    value result = skip(many(char('a'))).parse("b");
    
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
    value result1 = skip(many(char('a'))).parse("axy");
    if (is ParseResult<[]> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parseLocation, [0, 1]);
        assertEquals(result1.consumed, ['a']);
        assertEquals(result1.overConsumed, ['x']);
    } else {
        fail("Result was ``result1``");
    }
    
    value result = seq({skip(many(char('a'))), char('b')})
            .parse("aab");
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
    value result = skip(many(char('a'), 1)).parse("aaa");
    
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
    value result = skip(many(char('a'), 1)).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 1)), char('b')
    }.parse("aab");
    
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
    value result = skip(many(char('a'), 3)).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumed, ['a', 'a', 'b']);
        assertFalse(result.message.empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany3CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 3)), char('b')
    }.parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.consumed, ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void testOptionSimple() {
    value parser = option(char('a'));
    
    value result1 = parser.parse("");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result, []);
        assertEquals(result1.parseLocation, [0, 0]);
        assertEquals(result1.consumed, []);
        assertEquals(result1.overConsumed, []);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("a");
    if (is ParseResult<{Character*}> result2) {
        assertEquals(result2.result, ['a']);
        assertEquals(result2.parseLocation, [0, 1]);
        assertEquals(result2.consumed, ['a']);
        assertEquals(result2.overConsumed, []);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("b");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result, []);
        assertEquals(result3.parseLocation, [0, 0]);
        assertEquals(result3.consumed, []);
        assertEquals(result3.overConsumed, ['b']);
    } else {
        fail("Result was ```result3``");
    }
}

test shared void testOptionMultivalue() {
    value parser = option(seq { oneString("hej"), oneString("bye") });
    
    value result1 = parser.parse("hejdå");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parseLocation, [0, 0]);
        assertEquals(result1.consumed, []);
        assertEquals(result1.overConsumed, ['h', 'e', 'j', 'd']);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("hejbye");
    if (is ParseResult<{Character*}> result2) {
        assertEquals(result2.result.sequence(), ['h', 'e', 'j', 'b', 'y', 'e']);
        assertEquals(result2.parseLocation, [0, 6]);
        assertEquals(result2.consumed, ['h', 'e', 'j', 'b', 'y', 'e']);
        assertEquals(result2.overConsumed, []);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("hell");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result.sequence(), []);
        assertEquals(result3.parseLocation, [0, 0]);
        assertEquals(result3.consumed, []);
        assertEquals(result3.overConsumed, ['h', 'e', 'l']);
    } else {
        fail("Result was ```result3``");
    }
}

test
shared void parserChainSimpleTest() {
    for (index->singleParser in [char('a'), many(noneOf(spaceChars)), space()].indexed) {
        for (input in ["", "0", "\n", " ", "a", "abc", "123", " xxx yyy"]) {
            value result1 = singleParser.parse(input);
            value result2 = seq({singleParser}).parse(input);
            value errorMessage = "Parser index: ``index``, Input: ``input``";
            assertResultsEqual(result1, result2, errorMessage);
            assertParseLocationsEqual(result1, result2, errorMessage);
        }
    }
}

test
shared void parserChain2ParsersTest() {
    for (index->parserPair in [[char('a'), char(' ')], [many(noneOf(spaceChars)), char(' ')], [space(), oneString("xxmn")]].indexed) {
        for (input in ["", "0", "\n", " ", "a", "a b c", "123", " abc", " xxx yyy"]) {
            value result1 = parserPair[0].parse(input);
            value nonParsed = input.sublistFrom(result1.consumed.size);
            value x = String(nonParsed);
            value result2 = parserPair[1].parse(x);
            value totalResult = seq(parserPair).parse(input);
            value expectedResult = findExpectedResult(result1, result2);
            value errorMessage = "Parser index: ``index``, Input: '``input``'";
            assertResultsEqual(totalResult, expectedResult, errorMessage);
        }
    }
}

test
shared void parserChainParsedLocationTest() {
    value parser = seq {
        char('a'), char('b'), either { char('c'), char('d') }, oneString("xyz")
    };
    
    for ([input, expected] in [["a", [0, 1]], ["abx", [0, 2]], ["abcd", [0, 3]], ["abcxym", [0, 3]]]) {
        value result = parser.parse(input);
        if (is ParseError result) {
            assertEquals(extractLocation(result.message), expected, result.message);
        } else {
            fail("Result for input ``input`` was ``result``");
        }    
    }
}

test
shared void testSepBy() {
    value commaSeparated = sepBy(char(','), integer());
    
    value result1 = commaSeparated.parse("");
    if (is ParseResult<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = commaSeparated.parse("1,2,");
    if (is ParseResult<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2]);
        assertEquals(result2.consumed, ['1', ',', '2']);
        assertEquals(result2.overConsumed, [',']);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = commaSeparated.parse("1");
    if (is ParseResult<{Integer*}> result3) {
        assertEquals(result3.result.sequence(), [1]);
    } else {
        fail("Result was ``result3``");
    }
    
    value result4 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseResult<{Integer*}> result4) {
        assertEquals(result4.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result4``");
    }
}

test
shared void testSepByMin3() {
    value commaSeparated = sepBy(char(','), integer(), 3);
    
    value result1 = commaSeparated.parse("100,200,53");
    if (is ParseResult<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), [100, 200, 53]);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseResult<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result2``");
    }
    value result3 = commaSeparated.parse("1");
    if (is ParseError result3) {
        assertFalse(result3.message.empty);
    } else {
        fail("Result was ``result3``");
    }
    value result4 = commaSeparated.parse("1,2");
    if (is ParseError result4) {
        assertFalse(result4.message.empty);
    } else {
        fail("Result was ``result4``");
    }
}

test
shared void testSepByWithComplexCombination() {
    value args = seq {
        skip(char('(')),
        sepBy(around(spaces(), char(',')),
            stringParser(either { oneString("shared"), oneString("actual") })),
        skip(char(')'))
    };
    
    value result1 = args.parse("()");
    if (is ParseResult<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = args.parse("(shared)");
    if (is ParseResult<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["shared"]);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = args.parse("(shared, actual)");
    if (is ParseResult<{String*}> result3) {
        assertEquals(result3.result.sequence(), ["shared", "actual"]);
    } else {
        fail("Result was ``result3``");
    }
    
    value result4 = args.parse("(shared   ,    actual,shared)");
    if (is ParseResult<{String*}> result4) {
        assertEquals(result4.result.sequence(), ["shared", "actual", "shared"]);
    } else {
        fail("Result was ``result4``");
    }
}

ParsedLocation extractLocation(String errorMessage) {
    object messageParser {
        function asLocation({Integer*} indexes) {
            assert (exists row = indexes.first);
            assert (exists col = indexes.rest.first);
            return [row, col];
        }
        value spaces = skip(many(space()));
        shared Parser<ParsedLocation> locationParser = asSingleValueParser(seq {
            integer(), skip(char(',')), spaces, skip(oneString("column")), spaces, integer()
        }, asLocation);
    }
    // messages always end with 'row <i>, column <j>'
    value rowIndex = errorMessage.lastInclusion("row");
    if (exists rowIndex) {
        value locationMessage = errorMessage.sublistFrom(rowIndex + "row ".size);
        value result = messageParser.locationParser.parse(locationMessage);
        if (is ParseResult<ParsedLocation> result) {
            return result.result;
        } else {
            fail("Could not parse location in '``errorMessage``' ----> ``result.message``");
        }
    } else {
        fail("Error message does not contain 'row': ``errorMessage``");
    }
    throw;
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

ParseResult<{Character*}>|ParseError findExpectedResult(ParseResult<{Character*}|String>|ParseError result1, ParseResult<{Character*}|String>|ParseError result2) {
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
