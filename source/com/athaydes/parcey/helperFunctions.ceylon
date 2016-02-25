import com.athaydes.parcey.combinator {
    sequenceOf,
    nonEmptySequenceOf
}
import com.athaydes.parcey.internal {
    chooseName
}

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To*.
 
 If [[converter]] throws a [[Throwable]], it is caught and converted into a [[ParseError]], which is then
 returned as the result of parsing the input.
 
 For use with chain parsers (eg. [[Parser<{From*}>]]), prefer [[mapParser]]."
see (`function mapParser`)
shared Parser<To> mapValueParser<out From, out To>(
    Parser<From> parser, To(From) converter)
        => object satisfies Parser<To> {
    name => parser.name;
    
    shared actual ParseResult<To> doParse(
        CharacterConsumer consumer) {
        switch(result = parser.doParse(consumer))
        case (is String) {
            return result;
        }
        else {
            try {
                return ParseSuccess(converter(result.result));
            }
            catch(Throwable e) {
                return consumer.abort();
            }
        }
    }
    
};

"Given a parser *(p)* and a function [[To(From)]] *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type [[{From*}]] to [[{To*}]].
 
 If [[converter]] throws a [[Throwable]], it is caught and converted into a [[ParseError]], which is then
 returned as the result of parsing the input.
 
 This function is convenient when using chain parsers. For single-value parsers,
 prefer to use [[mapValueParser]]."
see (`function mapValueParser`, `function nonEmptySequenceOf`)
shared Parser<{To*}> mapParser<out From,out To>(Parser<{From*}> parser, To(From) converter)
        => mapValueParser(parser, ({From*} from) => from.collect(converter));

"Given several parsers *(ps)* and a function `To({From*})` *(f)*, return a new parser which delegates the parsing
 to a [[sequenceOf]] of *ps*, using *f* to convert the results from type [[{From*}]] to [[{To*}]].
 
 If [[converter]] throws a [[Throwable]], it is caught and converted into a [[ParseError]], which is then
 returned as the result of parsing the input.
 
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
shared Parser<{To*}> mapParsers<in From,out To>(
    {Parser<{From*}>+} parsers,
    To({From*}) converter,
    String name_ = "")
        => object satisfies Parser<{To*}> {
    value parser = chainParser(mapValueParser(sequenceOf(parsers), converter));
    name = chooseName(name_, () => parser.name);
    doParse = parser.doParse;
};

"Converts a [[{Item*}]] parser to an Item parser by returning only the first
 Item of the Iterable in the result, if possible.
 
 If the result of parsing with the given [[parser|parser]] is an empty Iterable
 or parsing fails, the resulting parser returns a [[ParseError]]."
shared Parser<Item> first<out Item>(Parser<{Item*}> parser)
        => mapValueParser(nonEmptySequenceOf { parser }, ({Item+} items) => items.first);

"Converts an [[Item]] parser to a [[{Item+}]] parser which can be
 chained to other multi-value parsers.
 
 The result of parsing some input, if successful, contains an Iterable
 with the single value returned by the given parser."
see (`function sequenceOf`, `function nonEmptySequenceOf`)
shared Parser<{Item+}> chainParser<out Item>(Parser<Item> parser)
        => mapValueParser(parser, (Item result) => { result });

"Converts a Parser of Characters to a [[{String+}]] Parser.
 
 If succesful, the result contains an Iterable with a single String."
see (`function mapValueParser`)
shared Parser<{String+}> strParser(Parser<{Character*}> parser)
        => chainParser(mapValueParser(parser, String));

"Converts a Parser which may generate null values to one which will not."
see(`function nonEmptySequenceOf`)
shared Parser<{Value*}> coalescedParser<out Value>(
    Parser<{Value?*}> parser,
    String name_ = "")
        given Value satisfies Object
        => mapValueParser<{Value?*},{Value*}>(parser, Iterable.coalesced);
