#! /bin/bash
# link_flags="-L. -lraylib -lm"
link_flags=""

run() {
    hare run main.ha
}

build() {
    hare build -o ./emulator-bin main.ha
}

tests() {
    hare test .
}

if [ $# -gt 0 ]; then
    if [ "$1" == "run" ];
    then
        run
    fi
    if [ "$1" == "build" ];
    then
        build
    fi
    if [ "$1" == "test" ];
    then
        tests
    fi
else
    tests
fi
