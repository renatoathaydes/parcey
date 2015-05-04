import com.athaydes.parcey.combinator {
    ...
}

"Run the module `com.athaydes.parcey`."
shared void run() {
    value csv = parserChain(anyChar, either(oneOf('.'), oneOf(',')), anyChar);
    print(csv.parse("a,b"));
    print(csv.parse("a.b"));
    print(csv.parse("a,b,c"));
    print(csv.parse(""));
    print(csv.parse(",a,b"));
    
}