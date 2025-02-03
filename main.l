%{
#include <stdio.h>
#include <string.h>
int line = 1;

void helper(char* token) {
    printf("Line %d: Token found: \"%s\"\n", line, token);
}
%}

%%
\n { line++; }
"<"[^\n>]*">" {
    char token[100];
    strncpy(token, yytext + 1, strlen(yytext) - 2);
    token[strlen(yytext) - 2] = '\0'; // null terminating str
    helper(token);
}
. { /* ignoring rest */ }
%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}