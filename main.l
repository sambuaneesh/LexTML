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
Node *entity_root;  // trie for html entities
Node *num_entity_root;  // trie for numeric entities
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

// while i am at it, added few extra tokens as well!
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

char *html_entities[] = {"amp", "lt", "gt", "quot", "apos", "nbsp",
    "copy", "reg", "euro", "pound", "yen", "sect", "deg", NULL};

char *numeric_entities[] = {"32", "33", "34", "35", "36", "37", "38", "39", 
    "60", "62", "160", "169", "174", "8364", "163", "165", "167", "176", NULL};


void init() {
    root = newNode();
    for (int i = 0; html_tags[i] != NULL; i++)
        insert(html_tags[i], root);
    
    attr_root = newNode();
    for (int i = 0; html_attributes[i] != NULL; i++)
        insert(html_attributes[i], attr_root);
    
    entity_root = newNode();
    for (int i = 0; html_entities[i] != NULL; i++)
        insert(html_entities[i], entity_root);

    num_entity_root = newNode();
    for (int i = 0; numeric_entities[i] != NULL; i++)
        insert(numeric_entities[i], num_entity_root);
}

void helper(char* token, int type) { // type 0 -> tag, 1 -> attr, 2 -> entity, 3 -> num_entity
    char *suggestions[MAX_SUGGESTIONS];
    int count = 0;
    
    Node *trie;
    char *typeName;
    switch (type) {
        case 0:
            trie = root;
            typeName = "tag";
            break;
        case 1:
            trie = attr_root;
            typeName = "attribute";
            break;
        case 2:
            trie = entity_root;
            typeName = "entity";
            break;
        case 3:
            trie = num_entity_root;
            typeName = "numeric entity";
            break;
        default:
            return;
    }
    
    char *word = strtok(token, " ");
    if (search(trie, word, suggestions, &count)) {
        printf("Line %d: Valid %s: %s\n", line, typeName, word);
    } else {
        printf("Line %d: Invalid %s: %s\n", line, typeName, word);
        if (count > 0) {
            printf("Suggestions:\n");
            for (int i = 0; i < count; i++) {
                printf("- %s\n", suggestions[i]);
                free(suggestions[i]);
            }
        }
    }
}

// macro for the below redundant code for passing tokens to helper
#define HANDLE(TYPE) do {                \
    char token[100];                           \
    size_t len = strlen(yytext);               \
    strncpy(token, yytext + 1, len - 2);       \
    token[len - 2] = '\0';                     \
    helper(token, TYPE);                       \
} while(0)

%}
TOK    [a-zA-Z]

%%

\n                     { line++; }
"<!"[^\n>]*">"         { /* ignoring comments and <!DOCTYPE ...> */ }
"<"{TOK}+          { HANDLE(0); /*apparently 'or' operator is not working in flex, so did like this*/}
"<"{TOK}+">"        { HANDLE(0); }
"/"{TOK}+">"           { HANDLE(0); }
" "{TOK}+"="        { HANDLE(1); }
"&"{TOK}+          { HANDLE(2); }
"&#"[0-9]+        { HANDLE(3); }
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