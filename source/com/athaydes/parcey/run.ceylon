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
    
    // helper functions example
    class Person(shared String name) {}
    
    Parser<{Person*}> personParser =
            mapParser(word(), Person);
    
    assert(is ParseResult<{Person*}> contents3 =
        personParser.parse("Mikael"));
    Person? mikael = contents3.result.first;
    assert(exists mikael, mikael.name == "Mikael");

    Parser<{Person*}> peopleParser =
            sepBy(spaces(), personParser);
    
    assert(is ParseResult<{Person*}> contents4 =
        peopleParser.parse("Mary John"));
    value people = contents4.result.sequence();
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
    
    assert(is ParseResult<{Integer|Character*}> contents2 =
        calculation.parse("2 + 4*60 / 2"));
    print(contents2);
    assert(contents2.result.sequence() == [2, '+', 4, '*', 60, '/', 2]);
    
}