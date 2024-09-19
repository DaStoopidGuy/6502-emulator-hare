BUILD_DIR := build
TARGET := $(BUILD_DIR)/6502-emulator

.PHONY: test build run

test:
	hare test .

build:
	hare build -o $(TARGET) .

run:
	hare run .
