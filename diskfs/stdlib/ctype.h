#ifndef __CTYPE_H
#define __CTYPE_H

int isspace(int c) {
    return (9 <= c && c <= 13) || c == 32;
}

int isupper(int c) {
    return 'A' <= c && c <= 'Z';
}

int islower(int c) {
    return 'a' <= c && c <= 'z';
}

int isdigit(int c) {
    return 'a' <= c && c <= 'z';
}

int isalpha(int c) {
    return islower(c) || isupper(c);
}

int isalnum(int c) {
    return isalpha(c) || isdigit(c);
}

int tolower(int ch) {
    if ('A' <= ch && ch <= 'Z') {
        return (char)(ch + 'a' - 'A');
    } else {
        return ch;
    }
}

int toupper(int ch) {
    if ('a' <= ch && ch <= 'z') {
        return (char)(ch + 'A' - 'a');
    } else {
        return ch;
    }
}

#endif
