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

char *html_tags[] = {
    "head", "body", "html", "div", "img",
    "p", "a", "title", "meta", "link",
    "script", "style", "form", "input", "button",
    "table", "tr", "td", "th", "ul",
    "li", "span", "br", "hr", "h1",
    "h2", "h3", "h4", "h5", "h6",
    NULL  // sentinel to mark eo array
};

char *html_attributes[] = {
    "src", "alt", "width", "height", "class", 
    "id", "style", "href", "type", "value",
    "name", "placeholder", "title", "align", "target",
    NULL
};

void init() {
    // tag trie
    root = newNode();
    for (int i = 0; html_tags[i] != NULL; i++) {
        insert(html_tags[i]);
    }
    
    // attrib trie
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

int search_attr(char *str) {
    Node *curr = attr_root;
    while (*str && *str != '=') {  // searching only till "="
        if (curr->children[*str] == NULL)
            return 0;
        curr = curr->children[*str];
        str++;
    }
    return curr->end;
}

void helper(char* token) {
    char *tag = strtok(token, " ");
    if (search(tag))
        printf("Line %d: Valid tag: %s\n", line, tag);
    else
        printf("Line %d: Invalid tag: %s\n", line, tag);
    
    char *attr;
    while ((attr = strtok(NULL, " "))) {
        char attr_name[100];
        int i = 0;
        while (attr[i] && attr[i] != '=') {
            attr_name[i] = attr[i];
            i++;
        }
        attr_name[i] = '\0';
        
        if (search_attr(attr_name))
            printf("Line %d: Valid attribute: %s\n", line, attr_name);
        else
            printf("Line %d: Invalid attribute: %s\n", line, attr_name);
    }
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