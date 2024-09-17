#! /bin/bash
# link_flags="-L. -lraylib -lm"
link_flags=""

run() {
    hare run $link_flags main.ha
}

build() {
    hare build $link_flags main.ha
}

run-valgrind() {
    valgrind ./main
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
    if [ "$1" == "valgrind" ];
    then
        run-valgrind
    fi
else
    run
fi
