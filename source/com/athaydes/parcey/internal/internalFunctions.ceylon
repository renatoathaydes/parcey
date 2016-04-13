import com.athaydes.parcey {
    ParsedLocation,
    CharacterConsumer,
    ParseError,
    Parser
}

shared {Character*} asIterable(CharacterConsumer consumer)
        => object satisfies {Character*} {
    iterator() => object satisfies Iterator<Character> {
        next = consumer.next;
    };
};

String inBrackets(String text)
        => if (text.startsWith("(") &&
    text.endsWith(")")) then text else "(``text``)";

shared String chooseName(String name, String() default)
        => inBrackets(name.empty then default() else name);

Integer numberOfCharactersToDisplayInErrorMessage = 11;

String unexpected(CharacterConsumer consumer) {
    value next = consumer.peek(consumer.consumedAtDeepestError(),
        numberOfCharactersToDisplayInErrorMessage);

    return next.size == numberOfCharactersToDisplayInErrorMessage
    then quote(String(next.exceptLast.chain("...")))
    else quote(String(next));
}

shared ParseError parseError(CharacterConsumer consumer, String errorName) {
    value location = consumer.deepestErrorLocation();
    value message = "(``readableLocation(location)``)
                     Unexpected ``unexpected(consumer)``
                     Expecting ``consumer.deepestError else errorName``";
    return ParseError(message, location);
}

shared String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

shared Boolean negate(Boolean b)
        => !b;

"Returns a String showing the location with 1-based indexes."
shared String readableLocation(ParsedLocation parsedLocation)
        => "line ``parsedLocation[0]``, column ``parsedLocation[1]``";

shared String simplePlural(String word, Integer count)
        => word + (count != 1 then "s" else "");

shared String computeParserName({Parser<Anything>*} parsers, String separator)() {
    return parsers.map(Parser.name)
            .interpose(separator)
            .fold("")(plus);
}
