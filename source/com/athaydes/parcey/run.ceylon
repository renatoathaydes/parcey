import com.athaydes.parcey.combinator {
    ...
}

"Run the module `com.athaydes.parcey`."
shared void run() {
    value sentence = seq {
        sepBy(char(' '), many(word(), 1)),
        skip(oneOf { '.', '!', '?' })
    };
    assert(is ParseResult<{String*}> result =
        sentence.parse("This is a sentence!"));
    assert(result.result.sequence() == ["This", "is", "a", "sentence"]);
    print(result);
}