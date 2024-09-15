#! /bin/bash
link_flags="-L. -lraylib -lm"

run() {
    hare run $link_flags main.ha
}

build() {
    hare run $link_flags main.ha
}

run
