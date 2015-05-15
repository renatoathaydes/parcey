import com.athaydes.parcey.combinator {
    seq
}

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To* and turning the result into a single-value
 Iterable<To>."
see (`function takeArgs`, `function valueParser`)
shared Parser<{To+}> multiValueParser<From,To>(Parser<From> parser, To(From) converter)
        => object satisfies Parser<{To+}> {
    name = parser.name;
    shared actual ParseResult<{To+}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        switch (result)
        case (is ParseResult<From>) {
            return ParseResult({ converter(result.result) },
                result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return result;
        }
    }
};

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To*.
 
 This is useful because it is common that
 parsers should produce a single value which needs to be converted to a different type, but because
 parsers always return multiple values (so that they can be *chained* together), this function
 is required in those cases.
 
 Use [[multiValueParser]] if the required parser needs to be chained to other parsers."
see (`function multiValueParser`)
shared Parser<To> valueParser<From,To>(Parser<From> parser, To(From) converter)
        => object satisfies Parser<To> {
    name = parser.name;
    shared actual ParseResult<To>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        switch (result)
        case (is ParseResult<From>) {
            return ParseResult(converter(result.result), result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return result;
        }
    }
};

"Converts a Parser of Characters to a String Parser."
see (`function multiValueParser`)
shared Parser<{String+}> stringParser(Parser<{Character*}> parser)
        => multiValueParser(parser, String);

"Converts a Parser which may generate null values to one which will not.
 
 A [[ParseError]] occurs if the parser would generate a null value."
shared Parser<{Value+}> coallescedParser<Value>(Parser<{Value?+}> parser)
        given Value satisfies Object
        => object satisfies Parser<{Value+}> {
    
    name => parser.name;
    
    shared actual ParseResult<{Value+}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        if (is ParseResult<{Value?+}> result) {
            value results = result.result.sequence();
            if (results.any((element) => element is Null)) {
                return ParseError("ParseResult contains a null value: ``results``", result.consumed);
            } else {
                assert(is {Value+} values = results.coalesced.sequence());
                return ParseResult(values,
                    result.parseLocation, result.consumed, result.overConsumed);
            }
        } else {
            return result;
        }
    }
};

"Converts a function that takes one argument of type *Arg* to one which takes an
 argument of type *`{Arg*}`* (eg. many args).
 
 For example, to parse a String and then produce a single Foo, where Foo's constructor takes a single String:
 
     Parser<{Foo*}> fooParser = multiValueParser(str(\"foo\"), takeArgs(Foo));
 "
see (`function multiValueParser`, `function seq`)
shared Result({Arg*}) takeArgs<out Result,in Arg>(Result(Arg) fun) {
    return function({Arg*} args) {
        "This function can only be called with non-empty iterables!"
        assert (exists first = args.first);
        return fun(first);
    };
}
