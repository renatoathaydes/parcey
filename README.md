# Parcey

> A parser-combinator library for the Ceylon language.
Inspired by Haskell's [Parsec](http://hackage.haskell.org/package/parsec) library.

## Importing Parcey

Add this line to your `module.ceylon` file:

> Note: Project not yet on Herd! Will upload once it is a little bit more battle tested.

```ceylon
import com.athaydes.parcey "0.0.1";
```

## Using Parcey

### Basics

Parcey is pretty simple to use. There are parsers and parser-combinators.
Both are usually created using function calls.

For example, to get a parser of integers:

```ceylon
value parser = integer();
```

You can use the parser like this:

```ceylon
assert(is ParseResult<{Integer*}> contents =
        parser.parse("123"));
assert(contents.result.sequence() == [123]);
```

> Notice that most parsers return a sequence of values, rather than a single value... that's because, most of the time, parsers are used to parse several values, not just one... but also because this allows us to combine the parsers much more easily, as we'll see later.

If something goes wrong, you'll get a good error message:

```ceylon
assert(is ParseError error = parser.parse("hello"));
print(error.message);

// prints: Expected integer but found 'h' at row 1, column 1
```

An example of a parser combinator is `seq`, which takes a sequence of parsers
and applies each one in turn.

So, to parse 3 integers separated by spaces, we could do:

```ceylon
value parser2 = seq {
    integer(), spaces(), integer(), spaces(), integer()
};

value contents2 = parser2.parse("10  20 30 40  50");
assert(is ParseResult<{Integer*}> contents2);
assert(contents2.result.sequence() == [10, 20, 30]);
```

Notice that only the 3 first Integers are parsed, because once all the parsers are satisfied, they have no reason to continue parsing the input!

> If you want to consume the whole input, just add an `eof` parser at the end of the Iterable given to `seq` so that the parser will fail if there's anything left in the input after parsing the first 3 Integers.

The spaces are not included in the result because the `spaces` parser
discards its results.

> Note: the type of `parser2` is `Parser<{Integer*}>`, not `Parser<{Integer|Character*}>` because Ceylon can infer that all parameters of `seq` are either parsers of `{Integer*}` or `[]` (the
`spaces` parsers), and the union of `[]` with any other `Iterable` type is just the other type!

If what we really wanted in the example above was to parse as many integers as
possible, not just the first 3, we could use a powerful combinator called `sepBy`, which does just that kind of thing...

```ceylon
value parser3 = sepBy(spaces(), integer());

value contents3 = parser3.parse("10  20 30 40  50");
assert(is ParseResult<{Integer*}> contents3);
assert(contents3.result.sequence() == [10, 20, 30, 40, 50]);
```

Great, isn't it?

Notice that the last argument of every parser function is the parser name.
A nice default is provided for all parsers, but you can use that to improve error messages.

For example, using `parser2` defined above (which expects 3 integers separated by spaces):

```ceylon
value error2 = parser2.parse("x y");
assert(is ParseError error2);
print(error2.message);
```

Prints:

```
Expected integer but found 'x' at row 1, column 1
```

If we created the integer parsers using names:

```ceylon
value parser2 = seq {
    integer("latitude"), spaces(),
    integer("longitude"), spaces(),
    integer("elevation")
};
```

The error message would have been:

```
Expected latitude but found 'x' at row 1, column 1
```

### List of parsers

Here's a full list of the available **parsers**:

* `char`: parses the single specified character.
* `chars`: parses a non-empty stream of characters.
* `anyChar`: parses any character.
* `letter`: parses a single latin letter (`'a'..'z'` and `'A'..'Z'`).
* `word`: parses any word (defined as a sequence of latin letters).
* `str`: parses the single specified String.
* `anyStr`: parses any String (defined as a sequence of any characters, except spaces).
* `space`: parses a space (whitespace, new-line, etc).
* `spaces`: parses as many spaces as possible, discarding the results.
* `digit`: parses a single digit (`0..9`).
* `integer`: parses an `Integer`.
* `oneOf`: parses one of the given characters.
* `noneOf`: parses anything but the given characters.
* `eof`: parses the empty String, ie. end of input.

### Parser combinators

And these are the parser **combinators**:

* `seq`: applies one or more parsers in sequence, one after the other.
* `seq1`: like `seq`, but ensures at least one item in the result stream.
* `either`: applies one of the given parsers, trying each until one succeeds.
* `sepBy`: parses a parser separated by a separator parser.
* `sepWith`: like `sepBy`, but does not discard the separators.
* `many`: applies a parser as many times as possible.
* `option`: applies a parser if successful, backtracking if not.
* `skip`: applies a parser but skips its result.
* `around`: parses a parser around another parser.

> For a detailed description of each function, check the CeylonDocs!

The `seq1` combinator is particularly useful when you know the result of another combinator must have at least one item. For example, consider this parser:

```ceylon
value parser = sepBy(spaces(), word(), 1);
```

Here, the parser will take up the type `Parser<{String*}>`, even though, because we specified that the `sepBy` parser must only succeed if at least one `word()` is found, we know that the type should be `Parser<{String+}>`. To fix this, we just need to wrap the parser with `seq1`:

```ceylon
Parser<{String+}> parser = seq1 { sepBy(spaces(), word(), 1) };
```

### Helper functions

Helper functions are used to transform parsers in some way.

* `mapValueParser`: converts a parser of type `A` to a parser of type `B`.
* `mapParser`: converts a parser of type `{A*}` to a parser of type `{B*}`.
* `mapParsers`: converts a sequence of parsers of type `{A*}` to a parser of type `{B*}`.
* `chainParser`: converts a parser of type `A` to a parser of type `{A+}`.
* `strParser`: converts a parser of type `{Character*}` to a parser of type `{String+}`.
* `coalescedParser`: converts a parser of type `{A?*}` to a parser of type `{A*}`.
* `first`: converts a parser of type `{A*}` to a parser of type `A`.

These helper functions work together to let you create Parsers which can generate values of the types you're interested in, not just Strings and Characters.

Quick examples:

*A Person has a single name which is a valid word*.

```ceylon
class Person(shared String name) {}

Parser<Person> personParser =
    mapValueParser(first(word()), Person);

assert(is ParseResult<Person> contents3 =
    personParser.parse("Mikael"));
Person mikael = contents3.result;
assert(mikael.name == "Mikael");
```

*A sequence of words separated by spaces, where each word is a `Person`*.

```ceylon
// let's re-use the personParser from the previous example
Parser<{Person*}> peopleParser =
    sepBy(spaces(), chainParser(personParser));

assert(is ParseResult<{Person*}> contents4 =
    peopleParser.parse("Mary John"));
value people = contents4.result.sequence();
assert((people[0]?.name else "") == "Mary");
assert((people[1]?.name else "") == "John");
```

More concisely, we could define `peopleParser` as:

```ceylon
Parser<{Person*}> peopleParser2 =
    mapParser(sepBy(spaces(), word()), Person);
```

That's because `mapParser`, unlike `mapValueParser`, creates a `Parser`
which is ready to be chained to other parsers (ie. it has type `Parser<{A*}>`, not just `Parser<A>`), which can be very helpful!

To map to types that take more than one argument to construct, use `mapParsers`:

```ceylon
Parser<{<String->Integer>*}> namedInteger = mapParsers({
    word(),
    skip(char(':')),
    integer()
}, ({String|Integer*} elements) {
    assert(is String key = elements.first);
    assert(is Integer element = elements.last);
    return key->element;
}, "namedInteger");
```

### More examples

*A sentence is a sequence of one or more words, separated by spaces
and ended with one of ['.', '!', '?']*.

```ceylon
value sentence = seq {
    sepBy(char(' '), many(word(), 1)),
    skip(oneOf { '.', '!', '?' })
};

assert(is ParseResult<{String*}> result =
    sentence.parse("This is a sentence!"));

assert(result.result.sequence() == ["This", "is", "a", "sentence"]);
```

*A calculation is 2 or more integers separated with some operator around spaces*.

```ceylon
value operator = oneOf { '+', '-', '*', '/', '^', '%' };
value calculation = many(sepWith(around(spaces(), operator), integer()), 2);
    
assert(is ParseResult<{Integer|Character*}> contents2 =
    calculation.parse("2 + 4*60 / 2"));
assert(contents2.result.sequence() == [2, '+', 4, '*', 60, '/', 2]);
```

*A more complicated example: a simplified Json Parser*

```ceylon
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
Parser<{JsonArray*}> jsonArray() => seq {
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
};

// Mutually referring parsers must be wrapped in a class or object
object json {

    shared Parser<{JsonElement*}> jsonElement()
            => either { jsonValue(), jsonObject(), jsonArray() };

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
```

Now we can test the jsonParser with some Json input:

```ceylon
// parsing a simple json value
assert(is ParseResult<{JsonNumber*}> contents7
    = jsonParser.parse("10"));
assert(exists n = contents7.result.first,
    n == JsonNumber(10));

// parsing a json Object
value jsonObj = jsonParser.parse("{\"int\": 1, \"array\": [\"item1\", 2] }");
print(jsonObj);
assert(is ParseResult<{JsonElement*}> jsonObj); 
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
```
