%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define SIZE 128 // 128 -> ascii range
#define MAX_SUGGESTIONS 5
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

Node *root, *attr_root, *entity_root, *num_entity_root, *directive_root;
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
        if (curr->children[(int)*str] == NULL)
            return -1;  // if no match found
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

// numeric entities start with &# but in the document "#" is not given, but i am considering it. src link is below:
// https://lh4.googleusercontent.com/proxy/kYEgXFwgZSTbf4bwhkuHajBgD1z9_FMMiyA-DlRshPoL1OXHpzvqtUWK4MADcRscCMhIYKDgten3dMRVJjoE9i70JIF89tiXePcR
char *numeric_entities[] = {"32", "33", "34", "35", "36", "37", "38", "39", 
    "60", "62", "160", "169", "174", "8364", "163", "165", "167", "176", 
    "x20", "x21", "x22", "x23", "x24", "x25", "x26", "x27", 
    "x3C", "x3E", "xA0", "xA9", "xAE", "x20AC", "xA3", "xA5", "xA7", 
    "xB0", "xB5", "xB7", NULL
};

char *html_directives[] = {
    "include", "for", "if", "else", "while",
    "define", "macro", "endif", "foreach", "switch", "case", "default",
    NULL
};


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

    directive_root = newNode();
    for (int i = 0; html_directives[i] != NULL; i++)
        insert(html_directives[i], directive_root);
}

void helper(char* token, int type) { // type 0 -> tag, 1 -> attr, 2 -> entity, 3 -> num_entity, 4 -> directive
    char *suggestions[MAX_SUGGESTIONS];
    int count = 0;

    Node *trie;
    switch (type) {
        case 0: trie = root; break;
        case 1: trie = attr_root; break;
        case 2: trie = entity_root; break;
        case 3: trie = num_entity_root; break;
        case 4: trie = directive_root; break;
        default: return;
    }

    char word[MAX_WORD_LEN];
    strncpy(word, token, sizeof(word) - 1);
    word[sizeof(word) - 1] = '\0';

    if (search(trie, word, suggestions, &count) == 0) {
        printf("Line %d: Incomplete token: \"%s\"\n", line, word);
        if (count > 0) {
            printf("Suggestions:\n");
            for (int i = 0; i < count; i++) {
                printf("%s\n", suggestions[i]);
                free(suggestions[i]);
            }
            printf("\n");
        }
    }
}

// macro for the below redundant code for passing tokens to helper
#define HANDLE(TYPE) {                          \
    char token[100];                           \
    size_t len = strlen(yytext);               \
    if (len <= 1) ECHO;                        \
    else {                                     \
        if (TYPE == 0) {                       \
            if (yytext[0] == '<') {            \
                size_t i = 1;                   \
                while (i < len && yytext[i] != '>') \
                    token[i-1] = yytext[i], i++; \
                token[i-1] = '\0';             \
            } else if (yytext[0] == '/') {     \
                size_t i = 1;                   \
                while (i < len && yytext[i] != '>') \
                    token[i-1] = yytext[i], i++; \
                token[i-1] = '\0';             \
            }                                  \
        } else if (TYPE == 1) {                \
            size_t i = 1;                      \
            while (i < len && yytext[i] != '=') \
                token[i-1] = yytext[i], i++;   \
            token[i-1] = '\0';                \
        } else if (TYPE == 2 || TYPE == 3) {   \
            size_t start = (TYPE == 3) ? 2 : 1; \
            size_t i = 0;                      \
            while (start < len && yytext[start] != ';') \
                token[i++] = yytext[start++];  \
            token[i] = '\0';                   \
        } else if (TYPE == 4) {                \
            strncpy(token, yytext + 1, len - 1); \
            token[len - 1] = '\0';             \
        }                                      \
        helper(token, TYPE);                   \
    }                                          \
}

%}
TOK    [a-zA-Z]

%%

\n                     { line++; }
"<!"[^\n>]*">"         { /* ignoring comments and <!DOCTYPE ...> */ }
"<"{TOK}+          { HANDLE(0); /*apparently 'or' operator is not working in flex, so did like this*/}
"<"{TOK}+">"        { HANDLE(0); }
"/"{TOK}+">"           { HANDLE(0); }
" "{TOK}+"="        { HANDLE(1); }
"&"{TOK}+";"          { HANDLE(2); }
"&"{TOK}+          { HANDLE(2); }
"&#"[0-9]+";"        { HANDLE(3); }
"&#"[0-9]+          { HANDLE(3); }
"@"{TOK}+          { HANDLE(4); }
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