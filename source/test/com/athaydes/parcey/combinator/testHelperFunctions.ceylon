import ceylon.language.meta.model {
    Type
}
import ceylon.test {
    fail,
    assertEquals
}

import com.athaydes.parcey {
    ParseError,
    ParseResult
}

void assertResultsEqual(
    ParseResult<{Character*}>|ParseError actualResult,
    ParseResult<{Character*}>|ParseError expectedResult,
    String errorMessage) {
    switch (actualResult)
    case (is ParseResult<{Character*}>) {
        if (is ParseResult<{Character*}> expectedResult) {
            assertEquals(actualResult.result.sequence(),
                expectedResult.result.sequence(), errorMessage + " (result)");
            assertEquals(actualResult.consumed.sequence(),
                expectedResult.consumed.sequence(), errorMessage + " (consumed)");
            assertEquals(actualResult.overConsumed.sequence(),
                expectedResult.overConsumed.sequence(), errorMessage + " (overConsumed)");
        } else {
            fail("``errorMessage`` - Results have different types: ``actualResult``, ``expectedResult``");
        }
    }
    case (is ParseError) {
        if (is ParseError expectedResult) {
            assertEquals(actualResult.consumed.sequence(),
                expectedResult.consumed.sequence(), errorMessage + " (error.consumed)");
        } else {
            fail("``errorMessage`` - Results have different types: ``actualResult``, ``expectedResult``");
        }
    }
}

ParseResult<{Character*}>|ParseError findExpectedResult(
    ParseResult<{Character*}|String>|ParseError result1,
    ParseResult<{Character*}|String>|ParseError result2) {
    switch (result1)
    case (is ParseResult<{Character*}>) {
        {Character*} consumed = result1.consumed.chain(result2.consumed);
        switch (result2)
        case (is ParseResult<{Character*}>) {
            return ParseResult(
                result1.result.sequence().append(result2.result.sequence()),
                consumed,
                result2.overConsumed);
        }
        case (is ParseError) {
            return ParseError(() => result2.message(), consumed, [0, 0]);
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
