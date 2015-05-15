import com.athaydes.parcey.combinator {
    ...
}

"Run the module `com.athaydes.parcey`."
shared void run() {
    // Basics
    value parser = integer();
    assert(is ParseResult<{Integer+}> contents =
        parser.parse("123"));
    assert(contents.result.sequence() == [123]);

    assert(is ParseError error = parser.parse("hello"));
    print(error.message);
    
    value parser2 = seq {
        integer("latitude"), spaces(), integer(), spaces(), integer()
    };
    
    value contents2 = parser2.parse("10  20 30 40  50");
    assert(is ParseResult<{Integer*}> contents2);
    assert(contents2.result.sequence() == [10, 20, 30]);
    
    value parser3 = sepBy(spaces(), integer());
    
    value contents3 = parser3.parse("10  20 30 40  50");
    assert(is ParseResult<{Integer*}> contents3);
    assert(contents3.result.sequence() == [10, 20, 30, 40, 50]);
    
    value error2 = parser2.parse("x y");
    assert(is ParseError error2);
    print(error2.message);

    // helper functions example
    class Person(shared String name) {}
    
    Parser<Person> personParser =
            mapValueParser(first(word()), Person);
    
    assert(is ParseResult<Person> contents4 =
        personParser.parse("Mikael"));
    Person mikael = contents4.result;
    assert(mikael.name == "Mikael");
    
    Parser<{Person*}> peopleParser =
            sepBy(spaces(), chainParser(personParser));
    //Parser<{Person*}> peopleParser2 =
    //        mapParser(sepBy(spaces(), word()), Person);
    
    assert(is ParseResult<{Person*}> contents5 =
        peopleParser.parse("Mary John"));
    value people = contents5.result.sequence();
    assert((people[0]?.name else "") == "Mary");
    assert((people[1]?.name else "") == "John");

    // sentence example
    value sentence = seq {
        sepBy(char(' '), many(word(), 1)),
        skip(oneOf { '.', '!', '?' })
    };
    
    assert(is ParseResult<{String*}> contents1 =
        sentence.parse("This is a sentence!"));
    assert(contents1.result.sequence() == ["This", "is", "a", "sentence"]);
    print(contents1);
    
    // arithmetics example
    value operator = oneOf { '+', '-', '*', '/', '^', '%' };
    value calculation = many(sepWith(around(spaces(), operator), integer()), 2);
    
    assert(is ParseResult<{Integer|Character*}> contents6 =
        calculation.parse("2 + 4*60 / 2"));
    print(contents6);
    assert(contents6.result.sequence() == [2, '+', 4, '*', 60, '/', 2]);
    
}