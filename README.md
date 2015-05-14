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

> Notice that most parsers return a sequence of values, rather than a single value... that's because, most of the time, parsers are used in to parse several values, of course, but also because this allows us to combine the parsers much more easily, as we'll see later.

If something goes wrong, you'll get a good error message:

```ceylon
assert(is ParseError error = parser.parse("hello"));
print(error.message);

// prints: Expected integer but found 'h' at row 1, column 1
```

### List of parsers

Here's a full list of the available **parsers**:

* `char`: parses the single specified character.
* `anyChar`: parses any character.
* `letter`: parses a single latin letter (`'a'..'z'` and `'A'..'Z'`).
* `word`: parses any word (defined as a sequence of latin letters).
* `str`: parses the single specified String.
* `anyStr`: parses any String (defined as a sequence of any characters, except spaces).
* `space`: parses a space (whitespace, new-line, etc).
* `spaces`: parses as many spaces as possible.
* `digit`: parses a single digit (`0..9`).
* `integer`: parses an `Integer`.
* `oneOf`: parses one of the given characters.
* `noneOf`: parses anything but the given characters.
* `eof`: parses the empty String, ie. end of input.

And these are the parser **combinators**:

* `seq`: applies one or more parsers in sequence, one after the other.
* `either`: applies one of the given parsers, trying each until one succeeds.
* `sepBy`: parses a parser separated by a separator parser.
* `sepWith`: like `sepBy`, but does not discard the separators.
* `many`: applies a parser as many times as possible.
* `option`: applies a parser if successful, backtracking if not.
* `skip`: applies a parser but skips its result.
* `around`: parses a parser around another parser.

For a detailed description, check the CeylonDocs!

### Helper functions

* `valueParser`: converts a parser of type A to a parser of type B.
* `multiValueParser`: converts a parser of type A to a parser of type {B+}.
* `stringParser`: converts a parser of type {Character*} to a parser of type {String*}.
* `coallescedParser`: turns a parser of type A? into a parser of type A.
* `takeArgs`: converts a function which takes an argument of type A to one that takes an argument of type {A*}.

These helper functions work together to let you create Parsers which can generate values of the types you're interested, not just Strings and Characters.

Quick examples:

```ceylon
class Person(shared String name) {}

Parser<Person> personParser =
        valueParser(word(), takeArgs(Person));

assert(is ParseResult<Person> contents3 = personParser.parse("Mikael"));
Person mikael = contents3.result;
assert(mikael.name == "Mikael");
```

```ceylon
Parser<{Person+}> peopleParser =
        multiValueParser(sepBy(spaces(),word()), takeArgs(Person));

assert(is ParseResult<{Person+}> contents4 =
    peopleParser.parse("Mary John"));
value people = contents4.result.sequence();
assert((people[0]?.name else "") == "Mary");
assert((people[1]?.name else "") == "John");
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
