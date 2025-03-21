#!/bin/bash

# Run tests with Busted, loading the init.lua file first
busted --lpath="./lua/?.lua;./lua/?/init.lua" --helper="./test/init.lua" "$@" ./test
