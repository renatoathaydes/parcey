import ceylon.test {
    test,
    assertEquals
}

import com.athaydes.parcey {
    digit,
    strParser,
    mapParser,
    coalescedParser,
    ParseSuccess,
    spaces
}
import com.athaydes.parcey.combinator {
    many,
    sepBy
}

import test.com.athaydes.parcey.combinator {
    expect
}

test shared void coalescedParserTest() {
    value maybeIntParser = mapParser(
        sepBy(spaces(), strParser(many(digit(), 1))), parseInteger);
    
    value intParser = coalescedParser(maybeIntParser);
    
    expect(intParser.parse("")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("x")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("1")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1]);
    });
    expect(intParser.parse("1 2 10 w z")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1, 2, 10]);
    });
}

