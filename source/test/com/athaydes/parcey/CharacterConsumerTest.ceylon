import ceylon.test {
    test,
    assertEquals
}
import com.athaydes.parcey {
    CharacterConsumer
}


shared class CharacterConsumerTest() {
   
   test shared void knowsHowToStartParser() {
       value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
       assertEquals(consumer.next(), 'a');
       assertEquals(consumer.latestConsumed().sequence(), ['a']);
       consumer.startParser();
       assertEquals(consumer.next(), 'b');
       assertEquals(consumer.next(), 'c');
       assertEquals(consumer.latestConsumed().sequence(), ['b', 'c']);
   }
   
   test shared void knowsHowToRestartParserAfterAbort() {
       value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
       assertEquals(consumer.next(), 'a');
       assertEquals(consumer.latestConsumed().sequence(), ['a']);
       consumer.startParser();
       assertEquals(consumer.next(), 'b');
       assertEquals(consumer.next(), 'c');
       consumer.abort("Test error");
       consumer.startParser();
       assertEquals(consumer.next(), 'b');
       assertEquals(consumer.next(), 'c');
       assertEquals(consumer.next(), 'd');
       assertEquals(consumer.latestConsumed().sequence(), ['b', 'c', 'd']);
       assertEquals(consumer.consumedByLatestParser, 3);
   }
   
   test shared void knowsHowToTakeBackInput() {
       value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
       function next10() => (1..10).collect((_) => consumer.next());
       assertEquals(next10().sequence(), ('a'..'z').take(10).sequence());
       consumer.takeBack(5);
       assertEquals(consumer.consumedByLatestParser, 10);
       consumer.startParser();
       assertEquals(next10().sequence(), ('a'..'z').skip(5).take(10).sequence());
   }
   
   test shared void knowLocation() {
       value consumer = CharacterConsumer("a \nbc\n\nd\t  e\nf".iterator());
       assertEquals(consumer.next(), 'a');
       assertEquals(consumer.next(), ' ');
       assertEquals(consumer.location(), [1, 1]);
       consumer.startParser();
       assertEquals(consumer.location(), [1, 3]);
       assertEquals(consumer.next(), '\n');
       assertEquals(consumer.next(), 'b');
       assertEquals(consumer.location(), [1, 3]);
       consumer.startParser();
       assertEquals(consumer.location(), [2, 2]);
       assertEquals(consumer.next(), 'c');
       consumer.startParser();
       assertEquals(consumer.location(), [2, 3]);
       assertEquals(consumer.next(), '\n');
       consumer.startParser();
       assertEquals(consumer.location(), [3, 1]);
       assertEquals(consumer.next(), '\n');
       assertEquals(consumer.next(), 'd');
       assertEquals(consumer.next(), '\t');
       assertEquals(consumer.next(), ' ');
       assertEquals(consumer.next(), ' ');
       assertEquals(consumer.next(), 'e');
       consumer.startParser();
       assertEquals(consumer.location(), [4, 6]);
       assertEquals(consumer.next(), '\n');
       consumer.startParser();
       assertEquals(consumer.location(), [5, 1]);
       assertEquals(consumer.next(), 'f');
       consumer.startParser();
       assertEquals(consumer.location(), [5, 2]);
   }

   test shared void knowLocationAfterAborting() {
       value consumer = CharacterConsumer("a\nbc\nde".iterator());
       assertEquals(consumer.next(), 'a');
       assertEquals(consumer.next(), '\n');
       assertEquals(consumer.next(), 'b');
       consumer.abort("");
       assertEquals(consumer.location(), [1, 1]);
       consumer.startParser();
       assertEquals(consumer.location(), [1, 1]);
       assertEquals(consumer.next(), 'a');
       (1..5).collect((_) => consumer.next());
       consumer.startParser();
       assertEquals(consumer.location(), [3, 2]);
       assertEquals(consumer.next(), 'e');
       consumer.abort("");
       consumer.startParser();
       assertEquals(consumer.location(), [3, 2]);
    }
    
}