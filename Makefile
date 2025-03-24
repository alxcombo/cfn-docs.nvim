.PHONY: test test-verbose test-pretty test-color

test:
	./test/run_tests.sh --output=plainTerminal

test-verbose:
	./test/run_tests.sh --output=gtest -v

test-pretty:
	./test/run_tests.sh --output=utfTerminal -v

test-color:
	./test/run_tests.sh --output=TAP -v | grep -v "^ok" | grep -v "^not ok" | grep -v "^# " | grep -v "^1\.\." | GREP_COLORS="mt=01;32" grep --color=always "^" | less -R
