CFLAGS=-Wall -g
LDFLAGS=-lfl
LEX=flex

.PHONY: clean

lexer: lexer.c

clean:
	rm lexer.c lexer 2&>/dev/null | true
