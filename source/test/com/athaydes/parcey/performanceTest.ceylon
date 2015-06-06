import ceylon.test {
    test,
    assertEquals,
    ignore
}

import com.athaydes.parcey {
    integer,
    spaces,
    ParseSuccess
}
import com.athaydes.parcey.combinator {
    sepBy
}

//ignore
shared test void performanceTest() {
    value parser = sepBy(spaces(), integer());
    value builder = StringBuilder();
    //print("Enter to continue");
    //process.readLine();
    //print("Starting...");
    //variable Integer count = 0;
    for (int in 0..300) {
        builder.clear();
        for (i in 0..int) {
     //       count++;
            builder.append(i.string).appendCharacter(' ');
        }
        //value result = builder.string.split().collect(parseInteger).coalesced;
        value result = parser.parse(builder.string);
        //print(result);
        assert(is ParseSuccess<Anything> result);
        assertEquals(int + 1, result.result.size);
    }
    //print("Done! Enter to exit");
    //process.readLine();
    //print("Bye");

    //print("Parsed ``count`` integers");
}
