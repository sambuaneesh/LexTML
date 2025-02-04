%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define SIZE 128 // 128 -> ascii range
#define MAX_SUGGESTIONS 10
#define MAX_WORD_LEN 100

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

Node *root; // tags trie
Node *attr_root;  // sep trie for attribs
int line = 1;

void insert(char *str, Node *trie) {
    while (*str) {
        if (trie->children[(int)*str] == NULL)
            trie->children[(int)*str] = newNode();
        trie = trie->children[(int)*str];
        str++;
    }
    trie->end = 1;
}

void collect(Node *curr, char *prefix, char *suggestions[], int *count) {
    if (*count >= MAX_SUGGESTIONS) return;
    
    if (curr->end) {
        suggestions[*count] = strdup(prefix);
        (*count)++;
    }
    
    for (int i = 0; i < SIZE; i++) {
        if (curr->children[i]) {
            char newPrefix[MAX_WORD_LEN];
            sprintf(newPrefix, "%s%c", prefix, i);
            collect(curr->children[i], newPrefix, suggestions, count);
        }
    }
}

int search(Node *trie, char *str, char *suggestions[], int *count) {
    Node *curr = trie;
    *count = 0;
    char prefix[MAX_WORD_LEN] = "";
    int pos = 0;
    
    while (*str) {
        if (curr->children[(int)*str] == NULL) {
            collect(curr, prefix, suggestions, count);
            return 0;
        }
        curr = curr->children[(int)*str];
        prefix[pos++] = *str;
        str++;
    }
    prefix[pos] = '\0';
    
    if (!curr->end) {
        collect(curr, prefix, suggestions, count);
        return 0;
    }
    return curr->end;
}

char *html_tags[] = {
    "head", "header", "body", "html", "div", "img",
    "p", "a", "title", "meta", "link",
    "script", "style", "form", "input", "button",
    "table", "tr", "td", "th", "ul",
    "li", "span", "br", "hr", "h1",
    "h2", "h3", "h4", "h5", "h6",
    NULL  // sentinel
};

char *html_attributes[] = {
    "src", "srcset", "alt", "width", "height", "class", 
    "id", "style", "href", "type", "value",
    "name", "placeholder", "title", "align", "target",
    NULL
};

void init() {
    root = newNode();
    for (int i = 0; html_tags[i] != NULL; i++)
        insert(html_tags[i], root);
    
    attr_root = newNode();
    for (int i = 0; html_attributes[i] != NULL; i++)
        insert(html_attributes[i], attr_root);
}

void helper(char* token, int type) { // type 0 -> tag, 1 -> attr
    char *suggestions[MAX_SUGGESTIONS];
    int count = 0;
    
    Node *trie = (type == 0) ? root : attr_root;
    
    char *word = strtok(token, " ");
    if (search(trie, word, suggestions, &count)) {
        if (type == 0)
            printf("Line %d: Valid tag: %s\n", line, word);
        else
            printf("Line %d: Valid attribute: %s\n", line, word);
    } else {
        if (type == 0)
            printf("Line %d: Invalid tag: %s\n", line, word);
        else
            printf("Line %d: Invalid attribute: %s\n", line, word);
        if (count > 0) {
            printf("Suggestions:\n");
            for (int i = 0; i < count; i++) {
                printf("- %s\n", suggestions[i]);
                free(suggestions[i]);
            }
        }
    }
}

%}
LETTER    [a-zA-Z]

%%
\n                     { line++; }
"<!"[^\n>]*">"       { /* ignoring comments and <!DOCTYPE ...> */ }
"<"{LETTER}+         {
                          char token[100];
                          strncpy(token, yytext + 1, strlen(yytext) - 2);
                          token[strlen(yytext) - 2] = '\0';
                          helper(token,0);
                      }
"<"{LETTER}+">"       {
                          char token[100];
                          strncpy(token, yytext + 1, strlen(yytext) - 2);
                          token[strlen(yytext) - 2] = '\0';
                          helper(token,0);
                      }
{LETTER}+"<"          {
                          char token[100];
                          strncpy(token, yytext + 1, strlen(yytext) - 2);
                          token[strlen(yytext) - 2] = '\0';
                          helper(token,0);
                      }
" "{LETTER}+"="       {
                          char token[100];
                          strncpy(token, yytext + 1, strlen(yytext) - 2);
                          token[strlen(yytext) - 2] = '\0';
                          helper(token,1);
                      }
.                     { /* ignoring rest */ }
%%

int main() {
    init();
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}