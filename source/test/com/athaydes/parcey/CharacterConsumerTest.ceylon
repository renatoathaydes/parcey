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

        consumer.startParser("");
        assertEquals(consumer.next(), 'a');
        assertEquals(consumer.latestConsumed().sequence(), ['a']);

        consumer.startParser("");
        assertEquals(consumer.latestConsumed().sequence(), []);
        assertEquals(consumer.next(), 'b');
        assertEquals(consumer.next(), 'c');
        assertEquals(consumer.latestConsumed().sequence(), ['b', 'c']);
    }

    test shared void knowsHowToAbortAndRestartParserAfterwards() {
        value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());

        consumer.startParser("A");
        assertEquals(consumer.next(), 'a');

        consumer.startParser("B");
        assertEquals(consumer.next(), 'b');
        assertEquals(consumer.next(), 'c');
        consumer.abort();
        assertEquals(consumer.consumedAtDeepestError(), 1);
        assertEquals(consumer.deepestError, "B");
        assertEquals(consumer.currentlyParsed(), 1);

        consumer.startParser("C");
        assertEquals(consumer.next(), 'b');
        assertEquals(consumer.next(), 'c');
        assertEquals(consumer.next(), 'd');
        assertEquals(consumer.latestConsumed().sequence(), ['b', 'c', 'd']);
        assertEquals(consumer.consumedByLatestParser, 3);
        assertEquals(consumer.consumedAtDeepestError(), 1);
        assertEquals(consumer.deepestError, "B");
        assertEquals(consumer.currentlyParsed(), 4);

        consumer.abort();
        assertEquals(consumer.consumedAtDeepestError(), 1);
        assertEquals(consumer.deepestError, "C");
        assertEquals(consumer.currentlyParsed(), 1);
    }

    test shared void knowsHowToTakeBackInput() {
        value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
        consumer.startParser("");

        function next10() => (1..10).collect((_) => consumer.next());
        assertEquals(next10().sequence(), ('a'..'z').take(10).sequence());
        consumer.takeBack(5);
        assertEquals(consumer.consumedByLatestParser, 10);
        consumer.startParser("");
        assertEquals(next10().sequence(), ('a'..'z').skip(5).take(10).sequence());
    }

    test shared void knowsLocation() {
        value consumer = CharacterConsumer("a \nbc\n\nd\t  e\nf".iterator());
        consumer.startParser("");

        assertEquals(consumer.location(), [1, 1]);
        assertEquals(consumer.next(), 'a');
        assertEquals(consumer.next(), ' ');
        assertEquals(consumer.location(), [1, 3]);
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.next(), 'b');
        assertEquals(consumer.location(), [2, 2]);
        assertEquals(consumer.next(), 'c');
        assertEquals(consumer.location(), [2, 3]);
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.location(), [3, 1]);
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.location(), [4, 1]);
        assertEquals(consumer.next(), 'd');
        assertEquals(consumer.next(), '\t');
        assertEquals(consumer.location(), [4, 3]);
        assertEquals(consumer.next(), ' ');
        assertEquals(consumer.next(), ' ');
        assertEquals(consumer.next(), 'e');
        assertEquals(consumer.location(), [4, 6]);
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.location(), [5, 1]);
        assertEquals(consumer.next(), 'f');
        assertEquals(consumer.location(), [5, 2]);
    }

    test shared void knowsLocationAfterAborting() {
        value consumer = CharacterConsumer("a\nbc\nde".iterator());

        consumer.startParser("A");
        assertEquals(consumer.next(), 'a');
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.next(), 'b');
        consumer.abort();

        assertEquals(consumer.currentlyParsed(), 0);
        assertEquals(consumer.location(), [1, 1]);

        consumer.startParser("B");
        assertEquals(consumer.next(), 'a');
        (1..5).collect((_) => consumer.next());
        assertEquals(consumer.location(), [3, 2]);

        consumer.startParser("C");
        assertEquals(consumer.next(), 'e');
        consumer.abort();
        assertEquals(consumer.location(), [3, 2]);
    }

    test shared void canReportAndForgetErrors() {
        value consumer = CharacterConsumer("a\nbc\nde".iterator());

        consumer.startParser("A");
        assertEquals(consumer.next(), 'a');
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.next(), 'b');

        consumer.startParser("B");
        assertEquals(consumer.next(), 'c');
        assertEquals(consumer.next(), '\n');
        assertEquals(consumer.next(), 'd');

        consumer.abort();
        assertEquals(consumer.deepestError, "B");
        assertEquals(consumer.deepestErrorLocation(), [2, 2]);
        assertEquals(consumer.currentlyParsed(), 3);

        consumer.startParser("C");
        assertEquals(consumer.next(), 'c');

        consumer.startParser("D");
        assertEquals(consumer.next(), '\n');

        consumer.abort();
        assertEquals(consumer.deepestError, "D");
        assertEquals(consumer.deepestErrorLocation(), [2, 3]);
        assertEquals(consumer.currentlyParsed(), 4);

        // previous error occured at 4, so this should NOT clean it
        consumer.cleanErrorsDeeperThan(4);

        assertEquals(consumer.deepestError, "D");
        assertEquals(consumer.deepestErrorLocation(), [2, 3]);
        assertEquals(consumer.currentlyParsed(), 4);

        // previous error occured at 4, cleaning errors deeper than 3 should clean it
        consumer.cleanErrorsDeeperThan(3);

        assertEquals(consumer.deepestError, "B");
        assertEquals(consumer.deepestErrorLocation(), [2, 2]);
        assertEquals(consumer.currentlyParsed(), 4);
    }

    test shared void knowsHowToMoveBack() {
        value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
        consumer.startParser("");
        (1..5).collect((_) => consumer.next());

        consumer.startParser("");
        (1..5).collect((_) => consumer.next());
        assertEquals(consumer.next(), 'k');

        consumer.moveBackTo(3);
        assertEquals((1..10).collect((_) => consumer.next()), "defghijklm".sequence());

        consumer.startParser("");
        assertEquals((1..3).collect((_) => consumer.next()), "nop".sequence());
        consumer.abort();

        // does it work even after aborting?
        consumer.moveBackTo(10);
        consumer.startParser("");
        assertEquals(consumer.next(), 'k');

        // trying to move back to a index not yet consumed should have no effect
        consumer.moveBackTo(50);
        consumer.startParser("");
        assertEquals(consumer.next(), 'l');

        // moving back to negative indexes should be the same as moving back to 0
        consumer.moveBackTo(-2);
        consumer.startParser("");
        assertEquals(consumer.next(), 'a');
    }

    test shared void knowsHowToTakeBack() {
        value consumer = CharacterConsumer("abcdefghijklmnopqrstuvxz".iterator());
        consumer.startParser("");
        (1..5).collect((_) => consumer.next());

        consumer.startParser("");
        (1..5).collect((_) => consumer.next());
        assertEquals(consumer.next(), 'k');

        consumer.takeBack(3);
        assertEquals((1..10).collect((_) => consumer.next()), "ijklmnopqr".sequence());

        consumer.startParser("");
        assertEquals((1..3).collect((_) => consumer.next()), "stu".sequence());
        consumer.abort();

        // does it work even after aborting?
        consumer.takeBack(10);
        consumer.startParser("");
        assertEquals(consumer.next(), 'i');

        // trying to take back 0 or a negative number should have no effect
        consumer.takeBack(-2);
        consumer.startParser("");
        assertEquals(consumer.next(), 'j');

        consumer.takeBack(0);
        assertEquals(consumer.next(), 'k');

        // taking back more than the number of characters consumed should move back to the beginning
        consumer.takeBack(52);
        consumer.startParser("");
        assertEquals(consumer.next(), 'a');
    }

}