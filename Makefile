.PHONY: all build run test install clean

BUILD_DIR   := build
SRC_DIR     := src
INSTALL_DIR := $(HOME)/.local/bin
BINARY      := $(BUILD_DIR)/fireterm
TEST_BINARY := $(BUILD_DIR)/fireterm_tests

all: build

build:
	ponyc -o $(BUILD_DIR) $(SRC_DIR) -b fireterm --linker gcc

run: build
	$(BINARY)

test:
	ponyc -o $(BUILD_DIR) --debug tests -b fireterm_tests --linker gcc
	$(TEST_BINARY)

install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BINARY) $(INSTALL_DIR)/fireterm

clean:
	rm -rf $(BUILD_DIR)