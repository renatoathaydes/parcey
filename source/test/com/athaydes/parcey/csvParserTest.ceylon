import com.athaydes.parcey {
    noneOf,
    character,
    strParser,
    endOfInput,
    ParseError,
    text,
    mapValueParser
}
import com.athaydes.parcey.combinator {
    either,
    many,
    sequenceOf,
    separatedBy,
    skip
}

shared void csvParserTest() {
    
    /* # EXAMPLE Haskell CSV Parser from http://book.realworldhaskell.org/read/using-parsec.html
     import Text.ParserCombinators.Parsec
     
     csvFile = endBy line eol
     line = sepBy cell (char ',')
     cell = quotedCell <|> many (noneOf ",\n\r")
     
     quotedCell = 
     do char '"'
       content <- many quotedChar
       char '"' <?> "quote at end of cell"
       return content
     
     quotedChar =
        noneOf "\""
     <|> try (string "\"\"" >> return '"')
     
     eol =   try (string "\n\r")
     <|> try (string "\r\n")
     <|> string "\n"
     <|> string "\r"
     <?> "end of line"
     
     parseCSV :: String -> Either ParseError [[String]]
     parseCSV input = parse csvFile "(unknown)" input
     
     main =
     do c <- getContents
       case parse csvFile "(stdin)" c of
            Left e -> do putStrLn "Error parsing input:"
                         print e
            Right r -> mapM_ print r
     
     */
    object csvParser {
        
        value quotedChar => either {
            noneOf { '"' }, sequenceOf { character('\\'), character('"') }
        };
        
        value quotedCell => sequenceOf {
            character('"'), many(quotedChar), character('"')
        };
        
        value eol => skip(either {
            text("\n\r"), text("\r\n"), character('\n')
        });
        
        value cell => strParser(either {
            quotedCell, many(noneOf { ',', '\n', '\r' })
        });
        
        value line => mapValueParser(separatedBy(character(','), cell),
                ({String*} cells) => [cells]);
        
        value csvFile = sequenceOf { separatedBy(eol, line), endOfInput() };
        
        shared void parse(String input) {
            value outcome = csvFile.parse(input);
            switch(outcome)
            case (is ParseError) { print("Error parsing input ``outcome.message``"); }
            else { print(outcome.result); }
        }
        
    }
    
    // test our parser
    csvParser.parse("ai,bej,cee\nnn,dey,ey,f,renato\n\"one big \ncell\"");
}