#!/bin/bash

# Default output format
OUTPUT_FORMAT="gtest"

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == "--output="* ]]; then
    OUTPUT_FORMAT="${arg#*=}"
    # Remove this argument from the list
    set -- "${@/$arg/}"
  fi
done

# Run tests with Busted, loading the init.lua file first
busted --output=$OUTPUT_FORMAT --lpath="./lua/?.lua;./lua/?/init.lua" --helper="./test/init.lua" "$@" ./test
