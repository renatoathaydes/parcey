import ceylon.language.meta.model {
    Type
}
import ceylon.test {
    fail
}

shared void expect<Expected>(
    Anything actual,
    Type<Expected>|Anything(Expected) \ithen) {
    if (is Expected actual) {
        if (is Anything(Expected) \ithen) {
            \ithen(actual);
        }
    } else {
        fail("Unexpected type: ``actual else "<null>"``");
    }
}
