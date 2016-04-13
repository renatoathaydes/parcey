"# Parcey

 > A parser-combinator library for the Ceylon language.
 Inspired by Haskell's [Parsec](http://hackage.haskell.org/package/parsec) library.

 ## Importing Parcey

 Add this line to your `module.ceylon` file:


     import com.athaydes.parcey \"0.4.0\";

 ## Using Parcey

 Parcey is pretty simple to use. There are parsers (or recognizers) and parser-combinators.

 Both are usually created using function calls (this allows recursive and mutually referring definitions!).

 For example, to get a parser of integers:

     value parser = integer();

 You can use the parser like this:

     assert(is ParseSuccess<{Integer*}> contents =
            parser.parse(\"123\"));
     assert(contents.result.sequence() == [123]);

 For more information, see the [Github page](https://github.com/renatoathaydes/parcey)."
module com.athaydes.parcey "0.4.0" {
    import ceylon.collection "1.2.2";
}
