import ceylon.test {
    test,
    assertEquals
}

import com.athaydes.parcey {
    digit,
    strParser,
    mapParser,
    coallescedParser,
    ParseResult,
    spaces
}
import com.athaydes.parcey.combinator {
    many,
    sepBy
}

import test.com.athaydes.parcey.combinator {
    expect
}

test shared void coallescedParserTest() {
    value maybeIntParser = mapParser<String, Integer?>(
        sepBy(spaces(), strParser(many(digit(), 1))), parseInteger);
    
    value intParser = coallescedParser(maybeIntParser);
    
    expect(intParser.parse(""), void(ParseResult<{Integer*}> result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("x"), void(ParseResult<{Integer*}> result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("1"), void(ParseResult<{Integer*}> result) {
        assertEquals(result.result.sequence(), [1]);
    });
    expect(intParser.parse("1 2 10 w z"), void(ParseResult<{Integer*}> result) {
        assertEquals(result.result.sequence(), [1, 2, 10]);
    });
}
