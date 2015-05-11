import com.athaydes.parcey.combinator {
    ...
}

"Run the module `com.athaydes.parcey`."
shared void run() {
    value csv = parserChain({anyChar(), either({char('.'), char(',')}), anyChar()});
    print(csv.parse("a,b"));
    print(csv.parse("a.b"));
    print(csv.parse("a,b,c"));
    print(csv.parse(""));
    print(csv.parse(",a,b"));
    
}