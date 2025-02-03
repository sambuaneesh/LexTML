all: lexer
	./lexer < input

lexer: lex
	gcc lex.yy.c -o lexer -lfl

lex: main.l
	flex main.l

clean:
	rm -f lexer lex.yy.c