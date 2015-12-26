# Parcey

> A parser-combinator library for the Ceylon language.
Inspired by Haskell's [Parsec](http://hackage.haskell.org/package/parsec) library.

## Importing Parcey

Add this line to your `module.ceylon` file:

```ceylon
import com.athaydes.parcey "0.3.0";
```

## Using Parcey

### Basics

Parcey is pretty simple to use. There are parsers (or recognizers) and parser-combinators.

Both are usually created using function calls (this allows recursive and mutually referring definitions!).

For example, to get a parser of integers:

```ceylon
value parser = integer();
```

You can use the parser like this:

```ceylon
assert(is ParseSuccess<{Integer*}> contents =
        parser.parse("123"));
assert(contents.result.sequence() == [123]);
```

> Notice that most parsers return a sequence of values, rather than a single value... that's because, most of the time, parsers are used to parse several values, not just one... additionally, this allows us to combine the parsers much more easily, as we'll see later.

If something goes wrong, you'll get a good error message:

```ceylon
assert(is ParseError error = parser.parse("hello"));
print(error.message);
```

Prints:

```
(line 1, column 1)
Unexpected 'hello'
Expecting (integer)
```

An example of a parser combinator is `sequenceOf`, which takes a sequence of parsers
and applies each one in turn.

So, to parse 3 integers separated by spaces, we could do:

```ceylon
value parser2 = sequenceOf {
    integer(), spaces(), integer(), spaces(), integer()
};

value contents2 = parser2.parse("10  20 30 40  50");
assert(is ParseSuccess<{Integer*}> contents2);
assert(contents2.result.sequence() == [10, 20, 30]);
```

> spaces() parses white-spaces, including new lines and tabs, discarding the results.


Notice that only the 3 first Integers are parsed, because once all the parsers are satisfied, they have no reason to continue parsing the input!

> If you want to consume the whole input, just add an `endOfInput` parser at the end of the Iterable given to `sequenceOf` so that the parser will fail if there's anything left in the input after parsing the first 3 Integers.

The spaces are not included in the result because the `spaces` parser
discards its results.

> Note: the type of `parser2` is `Parser<{Integer*}>`, not `Parser<{Integer|Character*}>` because Ceylon can infer that all parameters of `sequenceOf` are either parsers of `{Integer*}` or `[]` (the
`spaces` parsers), and the union of `[]` with any other `Iterable` type is just the other type!

If what we really wanted in the example above was to parse as many integers as
possible, not just the first 3, we could use a powerful combinator called `separatedBy`, which does just that kind of thing...

```ceylon
value parser3 = separatedBy(spaces(), integer());

value contents3 = parser3.parse("10  20 30 40  50");
assert(is ParseSuccess<{Integer*}> contents3);
assert(contents3.result.sequence() == [10, 20, 30, 40, 50]);
```

Great, isn't it?

Notice that the last argument of every parser function is the parser name.
A nice default is provided for all parsers, but you can use that to improve error messages.

For example, using `parser2` defined above (which expects 3 integers separated by spaces):

```ceylon
value error2 = parser2.parse("0 x y");
assert(is ParseError error2);
print(error2.message);
```

Prints:

```
line 1, column 3
Unexpected 'x y'
Expecting (integer)
```

If we created the integer parsers using names:

```ceylon
value parser2a = sequenceOf {
    integer("latitude"), spaces(),
    integer("longitude"), spaces(),
    integer("elevation")
};
```

The error message would have been:

```
line 1, column 3
Unexpected 'x y'
Expecting (longitude)
```

### List of parsers

Here's a full list of the available **parsers**:

* `character`: parses the single specified character.
* `characters`: parses a non-empty stream of characters.
* `anyCharacter`: parses any character.
* `letter`: parses a single latin letter (`'a'..'z'` and `'A'..'Z'`).
* `word`: parses any word (defined as a sequence of latin letters).
* `text`: parses the single specified String.
* `anyString`: parses any String (defined as a sequence of any characters, except spaces).
* `space`: parses a space (whitespace, new-line, etc).
* `spaces`: parses as many spaces as possible, discarding the results.
* `digit`: parses a single digit (`0..9`).
* `integer`: parses an `Integer`.
* `oneOf`: parses one of the given characters.
* `noneOf`: parses anything but the given characters.
* `endOfInput`: parses the empty String, ie. end of input.
* `satisfy`: parses a Character that satisfies the given predicate.

### Parser combinators

And these are the parser **combinators**:

* `sequenceOf`: applies one or more parsers in sequence, one after the other.
* `nonEmptySequenceOf`: like `sequenceOf`, but ensures at least one item in the result stream.
* `either`: applies one of the given parsers, trying each until one succeeds.
* `separatedBy`: parses a parser separated by a separator parser.
* `separatedWith`: like `separatedBy`, but does not discard the separators.
* `many`: applies a parser as many times as possible.
* `option`: applies a parser if successful, backtracking if not.
* `skip`: applies a parser but skips its result.
* `around`: parses a parser around another parser.

> For a detailed description of each function, check the CeylonDocs!

The `nonEmptySequenceOf` combinator is particularly useful when you know the result of another combinator must have at least one item. For example, consider this parser:

```ceylon
value parser = separatedBy(spaces(), word(), 1);
```

Here, the parser will take up the type `Parser<{String*}>`, even though, because we specified that the `separatedBy` parser must only succeed if at least one `word()` is found, we know that the type should be `Parser<{String+}>`. To fix this, we just need to wrap the parser with `nonEmptySequenceOf`:

```ceylon
Parser<{String+}> parser = nonEmptySequenceOf { separatedBy(spaces(), word(), 1) };
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

assert(is ParseSuccess<Person> contents3 =
    personParser.parse("Mikael"));
Person mikael = contents3.result;
assert(mikael.name == "Mikael");
```

*A sequence of words separated by spaces, where each word is a `Person`*.

```ceylon
// let's re-use the personParser from the previous example
Parser<{Person*}> peopleParser =
    separatedBy(spaces(), chainParser(personParser));

assert(is ParseSuccess<{Person*}> contents4 =
    peopleParser.parse("Mary John"));
value people = contents4.result.sequence();
assert((people[0]?.name else "") == "Mary");
assert((people[1]?.name else "") == "John");
```

More concisely, we could define `peopleParser` as:

```ceylon
Parser<{Person*}> peopleParser2 =
    mapParser(separatedBy(spaces(), word()), Person);
```

That's because `mapParser`, unlike `mapValueParser`, creates a `Parser`
which is ready to be chained to other parsers (ie. it has type `Parser<{A*}>`, not just `Parser<A>`), which can be very helpful!

To map to types that take more than one argument to construct, use `mapParsers`:

```ceylon
Parser<{<String->Integer>*}> namedInteger = mapParsers({
    word(),
    skip(character(':')),
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
value sentence = sequenceOf {
    separatedBy(character(' '), many(word(), 1)),
    skip(oneOf { '.', '!', '?' })
};

assert(is ParseSuccess<{String*}> result =
    sentence.parse("This is a sentence!"));

assert(result.result.sequence() == ["This", "is", "a", "sentence"]);
```

*A calculation is 2 or more integers separated with some operator around spaces*.

```ceylon
value operator = oneOf { '+', '-', '*', '/', '^', '%' };
value calculation = many(separatedWith(around(spaces(), operator), integer(), 2));

assert(is ParseSuccess<{Integer|Character*}> contents6 =
    calculation.parse("2 + 4*60 / 2"));
assert(contents6.result.sequence() == [2, '+', 4, '*', 60, '/', 2]);
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
value quote = skip(character('"'));
function jsonStr()
        => mapParser(strParser(sequenceOf({
    quote, many(noneOf { '"' }), quote
}, "jsonString")), JsonString);
function jsonInt()
        => mapParser(integer("jsonInt"), JsonNumber);
function jsonValue()
        => either { jsonStr(), jsonInt() };

// a recursive definition needs explicit type
Parser<{JsonArray*}> jsonArray() => sequenceOf({
    skip(around(spaces(), character('['))),
    chainParser(
        mapValueParser(
            separatedBy(around(spaces(), character(',')), either {
                jsonValue(),
                jsonArray()
            }), JsonArray)
    ),
    spaces(),
    skip(character(']'))
}, "jsonArray");

// Mutually referring parsers must be wrapped in a class or object
object json {

    shared Parser<{JsonElement*}> jsonElement()
            => either({ jsonValue(), jsonObject(), jsonArray() }, "jsonElement");

    shared Parser<{JsonEntry*}> jsonEntry() => mapParsers({
        jsonStr(),
        skip(around(spaces(), character(':'))),
        jsonElement()
    }, ({JsonElement*} elements) {
            assert(is JsonString key = elements.first);
            assert(is JsonElement element = elements.last);
            return JsonEntry(key, element);
    }, "jsonEntry");
    
    shared Parser<{JsonObject*}> jsonObject() => mapParsers({
        skip(around(spaces(), character('{'))),
        separatedBy(around(spaces(), character(',')), jsonEntry()),
        spaces(),
        skip(character('}'))
    }, JsonObject, "jsonObject");
    
}

value jsonParser = either {
    jsonValue(),
    json.jsonObject()
};

// parsing a simple json value
value contents7 = jsonParser.parse("10");
assert(is ParseSuccess<Anything> contents7);
assert(exists n = contents7.result.first,
    n == JsonNumber(10));

// parsing a json Object
value jsonObj = jsonParser.parse("{\"int\": 1, \"array\": [\"item1\", 2] }");
print(jsonObj);
assert(is ParseSuccess<Anything> jsonObj); 
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

*CSV Parser - comparison with Haskell's Parsec*

[Click here](source/test/com/athaydes/parcey/csvParserTest.ceylon)
