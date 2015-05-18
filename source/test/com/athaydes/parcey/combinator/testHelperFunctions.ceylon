import ceylon.test {
    fail,
    assertEquals
}

import com.athaydes.parcey {
    space,
    integer,
    ParsedLocation,
    ParseError,
    Parser,
    ParseResult,
    char,
    str,
    mapValueParser
}
import com.athaydes.parcey.combinator {
    many,
    skip,
    seq
}
import ceylon.language.meta.model {
    Type
}

shared ParsedLocation extractLocation(String errorMessage) {
    object messageParser {
        function asLocation({Integer*} indexes) {
            assert (exists row = indexes.first);
            assert (exists col = indexes.rest.first);
            return [row, col];
        }
        value spaces = skip(many(space()));
        shared Parser<ParsedLocation> locationParser = mapValueParser(seq {
            integer(), skip(char(',')), spaces, skip(str("column")), spaces, integer()
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
            assertEquals(actualResult.consumed.sequence(), expectedResult.consumed.sequence(), errorMessage);
            assertEquals(expectedResult.overConsumed, expectedResult.overConsumed, errorMessage);
        } else {
            fail("``errorMessage`` - Results have different types: ``actualResult``, ``expectedResult``");
        }
    }
    case (is ParseError) {
        if (is ParseError expectedResult) {
            assertEquals(actualResult.consumed.sequence(), expectedResult.consumed.sequence(), errorMessage);
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
                result1.consumed.chain(result2.consumed),
                result1.overConsumed.chain(result2.overConsumed));
        }
        case (is ParseError) {
            return ParseError(
                result2.message,
                result1.consumed.chain(result2.consumed));
        }
    }
    case (is ParseError) {
        return result1;
    }
}

shared void expect<Expected>(
    Anything actual,
    Type<Expected>|Anything(Expected) \ithen) {
    if (is Expected actual) {
        if (is Anything(Expected) \ithen) {
            \ithen(actual);
        }
    } else {
        fail("Unexpected type: ``actual else "<null>"``");
    }
}
