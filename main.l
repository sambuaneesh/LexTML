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

int search(char *str, char *suggestions[], int *count) {
    Node *curr = attr_root;
    *count = 0;
    char prefix[MAX_WORD_LEN] = "";
    int pos = 0;
    
    while (*str) {
        if (curr->children[*str] == NULL) {
            collect(curr, prefix, suggestions, count);
            return 0;
        }
        curr = curr->children[*str];
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
    NULL  // sentinel to mark eo array
};

char *html_attributes[] = {
    "src","srcset", "alt", "width", "height", "class", 
    "id", "style", "href", "type", "value",
    "name", "placeholder", "title", "align", "target",
    NULL
};

void init() {
    root = newNode();
    for (int i = 0; html_tags[i] != NULL; i++) {
        insert(html_tags[i]);
    }
    
    attr_root = newNode();
    for (int i = 0; html_attributes[i] != NULL; i++) {
        Node *curr = attr_root;
        char *str = html_attributes[i];
        while (*str) {
            if (curr->children[*str] == NULL)
                curr->children[*str] = newNode();
            curr = curr->children[*str];
            str++;
        }
        curr->end = 1;
    }
}

void helper(char* token) {
    char *suggestions[MAX_SUGGESTIONS];
    int count = 0;
    
    char *tag = strtok(token, " ");
    if (search(tag, suggestions, &count)) {
        printf("Line %d: Valid tag: %s\n", line, tag);
    } else {
        printf("Line %d: Invalid tag: %s\n", line, tag);
        if (count > 0) {
            printf("Suggestions:\n");
            for (int i = 0; i < count; i++) {
                printf("- %s\n", suggestions[i]);
                free(suggestions[i]);
            }
        }
    }
    
    char *attr;
    while ((attr = strtok(NULL, " "))) {
        char attr_name[100];
        int i = 0;
        while (attr[i] && attr[i] != '=') {
            attr_name[i] = attr[i];
            i++;
        }
        attr_name[i] = '\0';
        
        count = 0;
        if (search(attr_name, suggestions, &count)) {
            printf("Line %d: Valid attribute: %s\n", line, attr_name);
        } else {
            printf("Line %d: Invalid attribute: %s\n", line, attr_name);
            if (count > 0) {
                printf("Suggestions:\n");
                for (int i = 0; i < count; i++) {
                    printf("- %s\n", suggestions[i]);
                    free(suggestions[i]);
                }
            }
        }
    }
}

%}

%%
\n { line++; }
"<!"[^\n>]*">" { /* ignoring comments and something like <!DOCTYPE ...> */ }
"<"[^\n>]*">" {
    char token[100];
    strncpy(token, yytext + 1, strlen(yytext) - 2);
    token[strlen(yytext) - 2] = '\0';
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