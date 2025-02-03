%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define SIZE 128 // 128 -> ascii range

typedef struct Node {
    struct Node *children[SIZE];
    int end; // bool to check if end of token
} Node;

Node *newNode() {
    Node *node = (Node *)malloc(sizeof(Node));
    for (int i = 0; i < SIZE; i++)
        node->children[i] = NULL;
    node->end = 0;
    return node;
}

Node *root;
int line = 1;

void insert(char *str) {
    Node *curr = root;
    while (*str) {
        if (curr->children[*str] == NULL)
            curr->children[*str] = newNode();
        curr = curr->children[*str];
        str++;
    }
    curr->end = 1;
}

int search(char *str) {
    Node *curr = root;
    while (*str) {
        if (curr->children[*str] == NULL)
            return 0;
        curr = curr->children[*str];
        str++;
    }
    return curr->end;
}

void init() {
    root = newNode();
    insert("head");
}

void helper(char* token) {
    if (search(token))
        printf("Line %d: Complete token: \"%s\"\n", line, token);
    else
        printf("Line %d: Incomplete token: \"%s\"\n", line, token);
}

%}

%%
\n { line++; }
"<!"[^\n>]*">" { /* ignoring comments and something like <!DOCTYPE ...> */ }
"<"[^\n>]*">" {
    char token[100];
    strncpy(token, yytext + 1, strlen(yytext) - 2);
    token[strlen(yytext) - 2] = '\0'; // null terminating str
    helper(token);
}
. { /* ignoring rest */ }
%%

int main() {
    init();
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}