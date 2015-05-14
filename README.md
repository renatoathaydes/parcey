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

Parcey is pretty simple to use. Let's look at some examples:

```ceylon
value sentence = seq {
    sepBy(char(' '), many(word(), 1)),
    skip(oneOf { '.', '!', '?' })
};

assert(is ParseResult<{String*}> result =
    sentence.parse("This is a sentence!"));

assert(result.result.sequence() == ["This", "is", "a", "sentence"]);
```

A few different parsers and combinators are shown in this example...

The following are simple **parsers**:

* `char`: parses a single character.
* `word`: parses a word (defined as a sequence of latin letters)
* `oneOf`: parses one of the given characters.

And the following are **combinators**:

* `seq`: applies a one or more parsers in sequence, one after the other.
* `sepBy`: parses with a parser separated by another parser.
* `many`: applies a parser as many times as possible.
* `skip`: applies a parser but skips its result.

Knowing what each parser and combinator does, it should be easy to understand
how the above example works...

It basically says: *A sentence is a sequence of words, separated by spaces
and ended with one of ['.', '!', '?']*.
