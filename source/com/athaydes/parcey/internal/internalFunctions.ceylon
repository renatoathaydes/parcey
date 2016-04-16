import com.athaydes.parcey {
    ParsedLocation,
    CharacterConsumer,
    ParseError
}

shared {Character*} asIterable(CharacterConsumer consumer)
        => object satisfies {Character*} {
    iterator() => object satisfies Iterator<Character> {
        next = consumer.next;
    };
};

String inSinleQuotes(String text)
        => if (text.startsWith("'") &&
               text.endsWith("'")) then text else "'``text``'";

shared String chooseName(String name, String() default)
        => inSinleQuotes(name.empty then default() else name);

Integer numberOfCharactersToDisplayInErrorMessage = 11;

String unexpected(CharacterConsumer consumer) {
    value next = consumer.peek(consumer.consumedAtDeepestError,
        numberOfCharactersToDisplayInErrorMessage);

    return next.size == numberOfCharactersToDisplayInErrorMessage
    then quote(String(next.exceptLast.chain("...")))
    else quote(String(next));
}

String expecting(CharacterConsumer consumer, String errorName) {
    String expecting;
    if (consumer.deepestErrors.empty) {
        expecting = errorName;
    } else {
        expecting = consumer.deepestErrors
                .map(inSinleQuotes)
                .interpose(" or ")
                .fold("")(plus);
    }
    return expecting;
}

shared ParseError parseError(CharacterConsumer consumer, String errorName) {
    value location = consumer.deepestErrorLocation;

    value message = "(``readableLocation(location)``)
                     Unexpected ``unexpected(consumer)``
                     Expecting ``expecting(consumer, errorName)``";
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
