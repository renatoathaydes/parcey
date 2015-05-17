import com.athaydes.parcey.combinator {
    seq,
    seq1
}
import com.athaydes.parcey.internal {
    parseError,
    chooseName
}

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To*.
 
 For use with chain parsers (eg. [[Parser<{From*}>]]), prefer [[mapParser]]."
see(`function mapParser`)
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
 to *p*, using *f* to convert the result from type [[{From*}]] to [[{To*}]].
 
 This function is convenient when using chain parsers. For single-value parsers,
 prefer to use [[mapValueParser]]."
see(`function mapValueParser`)
shared Parser<{To*}> mapParser<From,To>(Parser<{From*}> parser, To(From) converter)
        => mapValueParser(parser, ({From*} from) => from.map(converter));

"Given several parsers *(ps)* and a function [[To({From*})]] *(f)*, return a new parser which delegates the parsing
 to a [[seq]] of *ps*, using *f* to convert the results from type [[{From*}]] to [[{To*}]].
 
 This function allows mapping to types which take more than one argument in the constructor.
 
 For example:
 
     Parser<{<String->Integer>*}> namedInteger = mapParsers({
         word(),
         skip(char(':')),
         integer()
     }, ({String|Integer*} elements) {
         assert(is String key = elements.first);
         assert(is Integer element = elements.last);
         return key->element;
     }, \"namedInteger\");"
shared Parser<{To*}> mapParsers<From, To>(
    {Parser<{From*}>+} parsers,
    To({From*}) converter,
    String name_ = "")
        => object satisfies Parser<{To*}> {
        name => name_;
        shared actual ParseResult<{To*}>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            value parser = mapValueParser(seq(parsers), converter);
            return chainParser(parser).doParse(input, parsedLocation);
        }
    };

"Converts a [[{Item+}]] parser to an [[Item]] parser.
 
 Notice that the given parser may consume many [[Item]]s even if wrapped around this function."
shared Parser<Item> first<Item>(Parser<{Item+}> parser)
        => mapValueParser(parser, ({Item+} items) => items.first);

"Converts an [[Item]] parser to a [[{Item+}]] parser which can be
 chained to other multi-value parsers.
 
 The result of parsing some input, if successful, is an Iterable
 containing the single value returned by the given parser."
see(`function seq`, `function seq1`)
shared Parser<{Item+}> chainParser<Item>(Parser<Item> parser)
        => mapValueParser(parser, (Item result) => { result });

"Converts a Parser of Characters to a [[{String+}]] Parser.
 
 If succesful, the returned Iterable contains a single String."
see (`function mapValueParser`)
shared Parser<{String+}> strParser(Parser<{Character*}> parser)
        => chainParser(mapValueParser(parser, String));

"Converts a Parser which may generate null values to one which will not.
 
 A [[ParseError]] occurs if the parser would generate only null values."
shared Parser<{Value+}> coallescedParser<Value>(
    Parser<{Value?+}> parser,
    String name_ = "")
        given Value satisfies Object
        => object satisfies Parser<{Value+}> {
    
    name => chooseName(name_, "result contains only null values");
    
    shared actual ParseResult<{Value+}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation, delegateName);
        if (is ParseResult<{Value?+}> result) {
            value results = result.result.sequence();
            if (results.every((element) => element is Null)) {
                return parseError(name, result.consumed, parsedLocation);
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
