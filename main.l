%%
"hello"     { printf("Hello, World!\n"); }
"for"       { printf("C Keyword: for\n"); }
"while"     { printf("C Keyword: while\n"); }
"switch"    { printf("C Keyword: switch\n"); }
[0-9]+      { printf("Number: %s\n", yytext); }
[a-zA-Z][a-zA-Z0-9]*  { printf("Identifier: %s\n", yytext); }
.           { printf("Unknown character: %c\n", yytext[0]); }
%%

int main() {
    yylex();  // Start tokenizing
    return 0;
}

int yywrap() {
    return 1;  // Indicate end of input
}