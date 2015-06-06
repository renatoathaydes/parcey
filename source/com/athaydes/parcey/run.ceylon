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
        integer(), spaces(), integer(), spaces(), integer()
    };
    
    value contents2 = parser2.parse("10  20 30 40  50");
    
    assert(is ParseResult<{Integer*}> contents2);
    assert(contents2.result.sequence() == [10, 20, 30]);
    
    value parser3 = sepBy(spaces(), integer());
    
    value contents3 = parser3.parse("10  20 30 40  50");
    assert(is ParseResult<{Integer*}> contents3);
    assert(contents3.result.sequence() == [10, 20, 30, 40, 50]);
    
    value error2 = parser2.parse("0 x y");
    assert(is ParseError error2);
    print(error2.message);
    
    value parser2a = seq {
        integer("latitude"), spaces(),
        integer("longitude"), spaces(),
        integer("elevation")
    };
    print(parser2a.parse("0 x y"));

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
    value calculation = many(sepWith(around(spaces(), operator), integer(), 2));
    print(calculation.parse("2+4"));
    assert(is ParseResult<{Integer|Character*}> contents6 =
        calculation.parse("2 + 4*60 / 2"));
    assert(contents6.result.sequence() == [2, '+', 4, '*', 60, '/', 2]);
    
    // json example
    // firt, let's define some objects to represent Json
    class JsonString(shared String val) {
        equals(Object that)
                => if (is JsonString that) then
        this.val == that.val else false;
    }
    class JsonNumber(shared Integer val) {
        equals(Object that)
                => if (is JsonNumber that) then
        this.val == that.val else false;
    }
    class JsonArray(shared {JsonElement*} val)
            satisfies Correspondence<Integer, JsonElement>{
        value array = val.sequence();
        defines = array.defines;
        get = array.get;
    }
    class JsonEntry(shared JsonString key, shared JsonElement element) {}
    class JsonObject(shared {JsonEntry*} entries) {}
    
    alias JsonValue => JsonString|JsonNumber;
    alias JsonElement => JsonValue|JsonArray|JsonObject;
    
    // now we can define the parsers
    value quote = skip(char('"'));
    function jsonStr()
            => mapParser(strParser(seq({
        quote, many(noneOf { '"' }), quote
    }, "jsonString")), JsonString);
    function jsonInt()
            => mapParser(integer("jsonInt"), JsonNumber);
    function jsonValue()
            => either { jsonStr(), jsonInt() };
    
    // a recursive definition needs explicit type
    Parser<{JsonArray*}> jsonArray() => seq({
        skip(around(spaces(), char('['))),
        chainParser(
            mapValueParser(
                sepBy(around(spaces(), char(',')), either {
                    jsonValue(),
                    jsonArray()
                }), JsonArray)
        ),
        spaces(),
        skip(char(']'))
    }, "jsonArray");
    
    // Mutually referring parsers must be wrapped in a class or object
    object json {
    
        shared Parser<{JsonElement*}> jsonElement()
                => either({ jsonValue(), jsonObject(), jsonArray() }, "jsonElement");
    
        shared Parser<{JsonEntry*}> jsonEntry() => mapParsers({
            jsonStr(),
            skip(around(spaces(), char(':'))),
            jsonElement()
        }, ({JsonElement*} elements) {
                assert(is JsonString key = elements.first);
                assert(is JsonElement element = elements.last);
                return JsonEntry(key, element);
        }, "jsonEntry");
        
        shared Parser<{JsonObject*}> jsonObject() => mapParsers({
            skip(around(spaces(), char('{'))),
            sepBy(around(spaces(), char(',')), jsonEntry()),
            spaces(),
            skip(char('}'))
        }, JsonObject, "jsonObject");
        
    }
    
    value jsonParser = either {
        jsonValue(),
        json.jsonObject()
    };
    
    // parsing a simple json value
    value contents7 = jsonParser.parse("10");
    assert(is ParseResult<Anything> contents7);
    assert(exists n = contents7.result.first,
        n == JsonNumber(10));
    
    // parsing a json Object
    value jsonObj = jsonParser.parse("{\"int\": 1, \"array\": [\"item1\", 2] }");
    print(jsonObj);
    assert(is ParseResult<Anything> jsonObj); 
    assert(is JsonObject obj = jsonObj.result.first);
    value fields = obj.entries.sequence();
    assert(exists intField = fields[0]);
    assert(intField.key == JsonString("int"),
        intField.element == JsonNumber(1));
    assert(exists arrayField = fields[1]);
    assert(arrayField.key == JsonString("array"),
        is JsonArray array = arrayField.element);
    assert(exists first = array[0],
        first == JsonString("item1"));
    assert(exists second = array[1],
        second == JsonNumber(2));
    
    value badJson = jsonParser.parse("{\"int\": 1, array: [\"item1\", 2] }");
    print(badJson);
}

shared void runCeylonDocExamples() {
    Parser<{<String->Integer>*}> namedInteger = mapParsers({
        word(),
        skip(char(':')),
        integer()
    }, ({String|Integer*} elements) {
        assert(is String key = elements.first);
        assert(is Integer element = elements.last);
        return key->element;
    }, "namedInteger");
    
    print(namedInteger.parse("hello:10"));
}
