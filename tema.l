/* Chirac Andrei 335CC */

%{
#include <stdio.h>
FILE *yyin;

int nr_of_lines = 0;
int nr_of_func = 0;
int nr_of_variables = 0;
int nr_of_param = 0;
int nr_of_values = 0;
int prev_nr_of_variables = 0;
int diff_nr_of_param = 0;
int prev = 0;
int diff;
int ok;

char **var_names;
char **func_name;
char **param_name;

char **var_types;
char **func_type;
char **param_type;

%}
litera [A-Za-z]
cifra [0-9]
semn [+-]?
Natural {cifra}+
Intreg {semn}{Natural}
Real {semn}{Natural}\.{Natural}?

%x SIMPLE_COMMENT
%x COMPLEX_COMMENT
%x FUNC_DECLARATION
%x VAR_DECLARATION
%x VAR_DECLARATION_INITIALIZATION
%x VAR_DECLARATION_VALUE_AFTER_INITIALIZATION
%x VAR_DECLARATION_VALUE
%x PARAM_TYPE
%x CHECK
%x CHECK_FUNC
%x RETURN

%%

"//" { BEGIN(SIMPLE_COMMENT);}

<SIMPLE_COMMENT>. { }

<SIMPLE_COMMENT>"\n" {
    nr_of_lines++;
    BEGIN(INITIAL);
}

"/*" { BEGIN(COMPLEX_COMMENT); }

<COMPLEX_COMMENT>"*/" { BEGIN(INITIAL); }

<COMPLEX_COMMENT>\n { nr_of_lines++; }

<COMPLEX_COMMENT>. { }

"var" { 
    prev_nr_of_variables = nr_of_variables;
    BEGIN(VAR_DECLARATION);
}

"func" {
    BEGIN(FUNC_DECLARATION);
}

"return" {
    BEGIN(RETURN);
}

<RETURN>{litera}+ {
    
    if (strcmp(func_type[nr_of_func - 1], "none") == 0 ) {
        printf("line %d: Too many arguments to return\n", nr_of_lines + 1);
        fflush(stdout);
    } else {
        for(int i = 0; i < nr_of_param; i++) {
            if (strcmp(param_name[i], yytext) == 0) {
                if (strcmp(param_type[i], func_type[nr_of_func - 1]) != 0) {
                    printf("line %d: Invalid return type for function ’%s’\n", nr_of_lines + 1, func_name[nr_of_func - 1]);
                    fflush(stdout);
                }
            }
        }

        for(int i = 0; i < nr_of_variables; i++) {
            if (strcmp(var_names[i], yytext) == 0) {
                if (strcmp(var_types[i], func_type[nr_of_func - 1]) != 0) {
                    printf("line %d: Invalid return type for function ’%s’\n", nr_of_lines + 1, func_name[nr_of_func - 1]);
                    fflush(stdout);
                }
            }
        }
    }
}

<RETURN>"\n" {
    nr_of_lines++;
    BEGIN(INITIAL);
}
<RETURN>. {}

{litera}+ {
            prev_nr_of_variables = nr_of_variables;
            ok = -1;
            for(int i = 0; i < nr_of_variables; i++ ) {
                if(strcmp(var_names[i], yytext) == 0) {
                    ok = i;
                    BEGIN(CHECK);
                }
            }

            if (ok == -1) {
                prev++;
                nr_of_variables++;
                diff = nr_of_variables - prev;

                if (nr_of_variables == 1) {
                
                    var_names = malloc(nr_of_variables * sizeof(char *));
                    var_names[0] = malloc(50 * sizeof(char));
                    strcpy(var_names[nr_of_variables - 1], yytext);

                    var_types = malloc(nr_of_variables * sizeof(char *));
                    var_types[0] = malloc(50 * sizeof(char));
                    strcpy(var_types[0], "none");
                    

                } else {
                    var_names = realloc(var_names, nr_of_variables * sizeof(char *));
                    var_names[nr_of_variables - 1] = malloc(50 * sizeof(char));
                    strcpy(var_names[nr_of_variables - 1], yytext);

                    var_types = realloc(var_types, nr_of_variables * sizeof(char *));
                    var_types[nr_of_variables - 1] = malloc(50 * sizeof(char));
                    strcpy(var_types[nr_of_variables - 1], "none");
                }
            }
          }

":=" {
    BEGIN(VAR_DECLARATION_VALUE); 
}
"}" {
    nr_of_param = 0;
    nr_of_variables = 0;
}
\n   {nr_of_lines++; }
. { }


<CHECK>":=" {

    printf("line %d: No new variables on the left side of :=\n",  nr_of_lines + 1);
    fflush(stdout);
    BEGIN(INITIAL);
}

<CHECK>"=" {BEGIN(VAR_DECLARATION_VALUE_AFTER_INITIALIZATION);}
<CHECK>. {}

<FUNC_DECLARATION>"int"|"float32"|"string"|"bool" { 
    strcpy(func_type[nr_of_func - 1], yytext); 
}

<FUNC_DECLARATION>{litera}+ {
    for(int i = 0; i < nr_of_func; i++) {
        if(strcmp(func_name[i], yytext) == 0) {
            printf("line %d: ’%s’ redeclared in this file\n", nr_of_lines + 1, func_name[i]);
            fflush(stdout);
        }
    }

    nr_of_func++;
    if (nr_of_func == 1) {
                
        func_name= malloc(nr_of_func * sizeof(char *));
        func_name[0] = malloc(50 * sizeof(char));
        strcpy(func_name[nr_of_func - 1], yytext);

        func_type = malloc(nr_of_func * sizeof(char *));
        func_type[0] = malloc(50 * sizeof(char));
        strcpy(func_type[0], "none");

    } else {
        func_name = realloc(func_name, nr_of_func * sizeof(char *));
        func_name[nr_of_func - 1] = malloc(50 * sizeof(char));
        strcpy(func_name[nr_of_func - 1], yytext);

        func_type = realloc(func_type, nr_of_func * sizeof(char *));
        func_type[nr_of_func - 1] = malloc(50 * sizeof(char));
        strcpy(func_type[nr_of_func - 1], "none");
    }
}

<FUNC_DECLARATION>"(" { BEGIN(PARAM_TYPE); }

<FUNC_DECLARATION>"{" { BEGIN(INITIAL); }

<FUNC_DECLARATION>. {};

<FUNC_DECLARATION>"\n" { nr_of_lines++; }

<PARAM_TYPE>"int"|"float32"|"string"|"bool" { 
    for(int i = nr_of_param - diff_nr_of_param; i < nr_of_param; i++) {
        strcpy(param_type[i], yytext); 
    }

    diff_nr_of_param = 0;
}

<PARAM_TYPE>{litera}+ {

    nr_of_param++;
    diff_nr_of_param++;
    if (nr_of_param == 1) {
                
        param_name= malloc(nr_of_param * sizeof(char *));
        param_name[0] = malloc(50 * sizeof(char));
        strcpy(param_name[nr_of_param - 1], yytext);

        param_type = malloc(nr_of_param * sizeof(char *));
        param_type[0] = malloc(50 * sizeof(char));
        strcpy(param_type[0], "none");

    } else {
        param_name = realloc(param_name, nr_of_param * sizeof(char *));
        param_name[nr_of_param - 1] = malloc(50 * sizeof(char));
        strcpy(param_name[nr_of_param - 1], yytext);

        param_type = realloc(param_type, nr_of_param * sizeof(char *));
        param_type[nr_of_param - 1] = malloc(50 * sizeof(char));
        strcpy(param_type[nr_of_param - 1], "none");
    }
}

<PARAM_TYPE>")" {
    BEGIN(FUNC_DECLARATION);
}

<PARAM_TYPE>. {}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>{Real} {
    if(strcmp(var_types[ok], "none") == 0) {
        strcpy(var_types[ok], "float32");
    } else {

        if(strcmp(var_types[ok], "float32") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "float32", var_types[ok]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>{Natural} {
    if(strcmp(var_types[ok], "none") == 0) {
        strcpy(var_types[ok], "int");
    } else {

        if(strcmp(var_types[ok], "int") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "int", var_types[ok]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>{Intreg} {
    if(strcmp(var_types[ok], "none") == 0) {
        strcpy(var_types[ok], "int");
    } else {

        if(strcmp(var_types[ok], "int") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "int", var_types[ok]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>\"(\\.|[^"\\])*\" {
    if(strcmp(var_types[ok], "none") == 0) {
        strcpy(var_types[ok], "string");
    } else {
        if(strcmp(var_types[ok], "string") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "string", var_types[ok]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>"true"|"false" {
    if(strcmp(var_types[ok], "none") == 0) {
        strcpy(var_types[ok], "bool");
    } else { 
        if(strcmp(var_types[ok], "bool") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "bool", var_types[ok]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>{litera}+ {
    for(int i = 0; i < nr_of_variables; i++ ) {
        if(strcmp(var_names[i], yytext) == 0) {
            if(strcmp(var_types[ok], "none") == 0) {
                strcpy(var_types[ok], var_types[i]);
            } else { 
                if(strcmp(var_types[ok], var_types[i]) != 0) {
                    printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, var_types[i], var_types[ok]);
                    fflush(stdout);
                }
            }
        }
    }
}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>. {}

<VAR_DECLARATION_VALUE_AFTER_INITIALIZATION>\n {
    nr_of_lines++;
    BEGIN(INITIAL);
}

<VAR_DECLARATION>"int"|"float32"|"string"|"bool" { 
    for(int i = prev_nr_of_variables; i < nr_of_variables; i++) {
        strcpy(var_types[i], yytext);
    }
}

<VAR_DECLARATION>{litera}+ { 
    ok = -1;
    for(int i = 0; i < nr_of_variables; i++ ) {
        if(strcmp(var_names[i], yytext) == 0) {
            ok = 1;
            printf("line %d: ’%s’ redeclared in this block\n", nr_of_lines + 1, var_names[i]);
            fflush(stdout);
        }
    }
    
    if (ok == -1) {
        nr_of_variables++;
        
        if (nr_of_variables == 1) {
        
            var_names = malloc(nr_of_variables * sizeof(char *));
            var_names[0] = malloc(50 * sizeof(char));
            strcpy(var_names[nr_of_variables - 1], yytext);

            var_types = malloc(nr_of_variables * sizeof(char *));
            var_types[0] = malloc(50 * sizeof(char));
            strcpy(var_types[0], "none");
            
        } else {
        
            var_names = realloc(var_names, nr_of_variables * sizeof(char *));
            var_names[nr_of_variables - 1] = malloc(50 * sizeof(char));
            strcpy(var_names[nr_of_variables - 1], yytext);

            var_types = realloc(var_types, nr_of_variables * sizeof(char *));
            var_types[nr_of_variables - 1] = malloc(50 * sizeof(char));
            strcpy(var_types[nr_of_variables - 1], "none");
        }
    }
}

<VAR_DECLARATION>"=" { BEGIN(VAR_DECLARATION_VALUE); }

<VAR_DECLARATION>":=" { BEGIN(VAR_DECLARATION_VALUE); }

<VAR_DECLARATION>. {}

<VAR_DECLARATION>\n {
    nr_of_lines++;
    BEGIN(INITIAL);
}

<VAR_DECLARATION_VALUE>{Real} {
    diff++;
    if(strcmp(var_types[diff - 1], "none") == 0) {
        strcpy(var_types[diff - 1], "float32");
    } else {
        if(strcmp(var_types[diff - 1], "float32") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "float32", var_types[diff - 1]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE>{Natural} {
    diff++;
    if(strcmp(var_types[diff - 1], "none") == 0) {
        strcpy(var_types[diff - 1], "int");
    } else {

        if(strcmp(var_types[diff - 1], "int") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "int", var_types[diff - 1]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE>{Intreg} {
    diff++;
    if(strcmp(var_types[diff - 1], "none") == 0) {
        strcpy(var_types[diff - 1], "int");
    } else {

        if(strcmp(var_types[diff - 1], "int") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "int", var_types[diff - 1]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE>\"(\\.|[^"\\])*\" {
    diff++;
    if(strcmp(var_types[diff - 1], "none") == 0) {
        strcpy(var_types[diff - 1], "string");
    } else {
        if(strcmp(var_types[diff - 1], "string") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "string", var_types[diff - 1]);
                fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE>"true"|"false" {
    diff++;
    if(strcmp(var_types[diff - 1], "none") == 0) {
        strcpy(var_types[diff - 1], "bool");
    } else { 
        if(strcmp(var_types[diff - 1], "bool") != 0) {
            printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, "bool", var_types[diff - 1]);
            fflush(stdout);
        }
    }
}

<VAR_DECLARATION_VALUE>{litera}+ {
    for(int i = 0; i < nr_of_variables; i++ ) {
        if(strcmp(var_names[i], yytext) == 0) {
            diff++;
            if(strcmp(var_types[diff - 1], "none") == 0) {
                strcpy(var_types[diff - 1], var_types[i]);
            } else { 
                if(strcmp(var_types[diff - 1], var_types[i]) != 0) {
                    printf("line %d: (%s) cannot be represented by the (%s)\n", nr_of_lines + 1, var_types[i], var_types[diff - 1]);
                    fflush(stdout);
                }
            }
        }
    }
}

<VAR_DECLARATION_VALUE>. {}

<VAR_DECLARATION_VALUE>\n {
    prev = 0;
    nr_of_lines++;
    BEGIN(INITIAL);
}

%%

int main( int argc, char **argv ) {

    yyin = fopen(argv[1], "r");
	yylex();
    fclose(yyin);
}