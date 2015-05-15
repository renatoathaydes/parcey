import com.athaydes.parcey.combinator {
    seq,
    seq1
}

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To*."
shared Parser<To> mapValueParser<From,To>(Parser<From> parser, To(From) converter)
        => object satisfies Parser<To> {
    name = parser.name;
    shared actual ParseResult<To>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        switch (result)
        case (is ParseResult<From>) {
            return ParseResult(converter(result.result),
                    result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return result;
        }
    }
};

"Given a parser *(p)* and a function [[To(From)]] *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type [[{From*}]] to [[{To*}]]."
shared Parser<{To*}> mapParser<From,To>(Parser<{From*}> parser, To(From) converter)
        => object satisfies Parser<{To*}> {
    name = parser.name;
    shared actual ParseResult<{To*}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        switch (result)
        case (is ParseResult<{From*}>) {
            return ParseResult(result.result.map(converter),
                result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return result;
        }
    }
};

"Converts an [[Item]] parser to a [[{Item+}]] parser which can be
 chained to other multi-value parsers.
 
 The result of parsing some input, if successful, is an Iterable
 containing the single value returned by the given parser."
see(`function seq`, `function seq1`)
shared Parser<{Item+}> asChainParser<Item>(Parser<Item> parser)
        => object satisfies Parser<{Item+}> {
            name = parser.name;
            shared actual ParseResult<{Item+}>|ParseError doParse(
                Iterator<Character> input,
                ParsedLocation parsedLocation,
                String? delegateName) {
                value result = parser.doParse(input, parsedLocation);
                if (is ParseError result) {
                    return result;
                } else {
                    return ParseResult({result.result},
                        result.parseLocation, result.consumed, result.overConsumed);
                }
            }
    };

"Converts a Parser of Characters to a String Parser.
 
 If succesful, the returned value is an [[{String+}]] containing a single String."
see (`function mapValueParser`)
shared Parser<{String+}> strParser(Parser<{Character*}> parser)
        => asChainParser(mapValueParser(parser, String));

"Converts a Parser which may generate null values to one which will not.
 
 A [[ParseError]] occurs if the parser would generate only null values."
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
see (`function mapValueParser`, `function seq`)
shared Result({Arg*}) takeArgs<out Result,in Arg>(Result(Arg) fun) {
    return function({Arg*} args) {
        "This function can only be called with non-empty iterables!"
        assert (exists first = args.first);
        return fun(first);
    };
}
