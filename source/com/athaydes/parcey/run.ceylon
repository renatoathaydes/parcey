import com.athaydes.parcey.combinator {
    ...
}

"Run the module `com.athaydes.parcey`."
shared void run() {
    value csv = parserChain(char, either(oneOf('.'), oneOf(',')), char);
    print(csv.parse("a,b"));
    print(csv.parse("a.b"));
    print(csv.parse("a,b,c"));
    print(csv.parse(""));
    print(csv.parse(",a,b"));
    for (item in 'A'..'z') {
        process.write(item.string);
    }
}