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
    spaces,
    anyCharacter
}
import com.athaydes.parcey.combinator {
    many,
    separatedBy
}

import test.com.athaydes.parcey.combinator {
    expect
}

test shared void coalescedParserTest() {
    value maybeIntParser = mapParser(
        separatedBy(spaces(), strParser(many(digit(), 1))), parseInteger);
    
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

test shared void testMapParserWithThrowingConverter() {
    function filteringConverter(Character c) {
        assert (c in '1'..'9');
        return c.predecessor;
    }
    value parser = mapParser(many(anyCharacter()), filteringConverter);
    expect(parser.parse("456")).ofType(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), "345".sequence());
    });
    expect(parser.parse("a2")).assignableTo(error);
}
