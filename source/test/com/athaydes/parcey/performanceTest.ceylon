import ceylon.test {
    test,
    assertEquals
}

import com.athaydes.parcey {
    integer,
    spaces,
    ParseResult
}
import com.athaydes.parcey.combinator {
    sepBy
}

//ignore
shared test void performanceTest() {
    value parser = sepBy(spaces(), integer());
    value builder = StringBuilder();
    for (int in 0..200) {
        builder.clear();
        for (i in 0..int) {
            builder.append(i.string).appendCharacter(' ');
        }
        value result = parser.parse(builder.string);
        //print(result);
        assert(is ParseResult<{Integer*}> result);
        assertEquals(int + 1, result.result.size);
    }
}
