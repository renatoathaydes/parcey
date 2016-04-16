import com.athaydes.parcey.combinator {
    sequenceOf,
    nonEmptySequenceOf
}

"Given a parser *(p)* and a function To(From) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *From* to *To*.

 If [[converter]] throws a [[Throwable]], it is caught and converted into a [[ParseError]], which is then
 returned as the result of parsing the input.

 For use with chain parsers (eg. [[Parser<{From*}>]]), prefer [[mapParser]]."
see (`function mapParser`)
shared Parser<To> mapValueParser<out From, out To>(
    "The parser whose result value should be converted from [[From]] to [[To]]"
    Parser<From> parser,
    "A function converting [[parser]]'s value from [[From]] to [[To]]"
    To(From) converter,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        => object satisfies Parser<To> {

    shared actual ParseResult<To> doParse(
        CharacterConsumer consumer) {
        value startPosition = consumer.currentlyParsed();
        switch (result = parser.doParse(consumer))
        case (is ErrorMessage) {
            return name else result;
        }
        else {
            try {
                return ParseSuccess(converter(result.result));
            }
            catch (Throwable e) {
                value error = if (exists name)
                    then "``name``[``e.message``]"
                    else e.message;
                consumer.setError(startPosition, error);
                return error;
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
shared Parser<{To*}> mapParser<out From,out To>(
    "The parser whose results should be converted from [[From]] to [[To]]"
    Parser<{From*}> parser,
    "A function converting [[parser]]'s results from [[From]] to [[To]]"
    To(From) converter,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        => mapValueParser(parser, ({From*} from) => from.collect(converter), name);

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
    "The parsers whose results should be mapped from [[From]] to [[To]]"
    {Parser<{From*}>+} parsers,
    "A function converting [[parsers]]' results from [[From]] to [[To]]"
    To({From*}) converter,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parsers]]."
    String? name = null)
        => object satisfies Parser<{To*}> {
    value parser = chainParser(mapValueParser(sequenceOf(parsers), converter, name));
    doParse = parser.doParse;
};

"Converts a [[{Item*}]] parser to an Item parser by returning only the first
 Item of the Iterable in the result, if possible.

 If the result of parsing with the given [[parser|parser]] is an empty Iterable
 or parsing fails, the resulting parser returns a [[ParseError]]."
shared Parser<Item> first<out Item>(
    "The parser whose results should be ignored except for the first result, if any."
    Parser<{Item*}> parser,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        => mapValueParser(nonEmptySequenceOf { parser },
                ({Item+} items) => items.first,
                name);

"Converts an [[Item]] parser to a [[{Item+}]] parser which can be
 chained to other multi-value parsers.

 The result of parsing some input, if successful, contains an Iterable
 with the single value returned by the given parser."
see (`function sequenceOf`, `function nonEmptySequenceOf`)
shared Parser<{Item+}> chainParser<out Item>(
    "The parser whose result should be converted into an Iterable of which the result is the single item."
    Parser<Item> parser,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        => mapValueParser(parser, (Item result) => { result }, name);

"Converts a Parser of Characters to a [[{String+}]] Parser.

 If succesful, the result contains an Iterable with a single String."
see (`function mapValueParser`)
shared Parser<{String+}> strParser(
    "Parsers of [[{Character*}]]"
    Parser<{Character*}> parser,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        => chainParser(mapValueParser(parser, String, name));

"Converts a Parser which may generate null values to one which will not.

 This works by simply removing the null values from the results of the given [[parser]]."
see(`function nonEmptySequenceOf`)
shared Parser<{Value*}> coalescedParser<out Value>(
    "Parser of optional [[Value]]s."
    Parser<{Value?*}> parser,
    "The name of this parser.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null)
        given Value satisfies Object
        => mapValueParser<{Value?*},{Value*}>(parser, Iterable.coalesced, name);
