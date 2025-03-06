%{
#include "util.h"
#include "stack.h"
%}

%{
/***** INDENTATION *****/
#define MAX_INDENT_LEVEL 42
#define TAB_WIDTH 4

size_t indent_stack_pool[MAX_INDENT_LEVEL];
stack_t indent_stack = {0};

size_t get_indent_length (size_t n, const char str[static n])
{
	size_t res = 0;
	while (n--) res += str[n] == ' ' ? 1 : TAB_WIDTH;
	return res;
}
%}

%{
/***** MULTILINE COMMENTS *****/
size_t comment_depth = 0;
%}
%x COMMENT

%{
/***** TOKENS *****/
typedef enum {
	TOK_EOF = 0,
	TOK_ERROR = 256,
	TOK_KEYWORD,
	TOK_ID,
	TOK_CONST_CHAR,
	TOK_CONST_BYTE, TOK_CONST_INT,
	TOK_CONST_STRING,
	TOK_OP_NE,
	TOK_OP_LE,
	TOK_OP_GE,
	TOK_OP_ASSIGN,
	TOK_IND_START,
	TOK_IND_END,
} token_t;

#define TOK_DELIM(x) ((x) == '(' || (x) == ')' || (x) == '[' || (x) == ']' \
		|| (x) == ',' || (x) == ':')
#define TOK_OP(x) (((x) < 256 && !TOK_DELIM(x)) \
		|| (TOK_OP_NE <= (x) && (x) <= TOK_OP_ASSIGN))

const char *tok_type (token_t token)
{
	if (1 <= token && token <= 256)
		return TOK_DELIM(token) ?  "delimiter" : "operator\t";
	switch (token) {
	case TOK_EOF:		return "end-of-file";
	case TOK_KEYWORD:	return "keyword\t";
	case TOK_ID:		return "identifier";
	case TOK_CONST_CHAR:	return "character";
	case TOK_CONST_BYTE:	return "byte\t";
	case TOK_CONST_INT:	return "integer\t";
	case TOK_CONST_STRING:	return "string\t";
	case TOK_OP_NE:
	case TOK_OP_LE:
	case TOK_OP_GE:
	case TOK_OP_ASSIGN:	return "operator";
	case TOK_IND_START:	return "indent start";
	case TOK_IND_END:	return "indent end";
	case TOK_ERROR:		return "error\t";
	default:		die("Invalid token: %d\n", token);
	}
}

#define REGISTER(tok, lex) \
	printf("Token: %s\tLexeme: %s\n", tok_type(tok), lex)

%}

CHAR	[a-zA-Z0-9\!\#\$\%\&\(\)\*\+\,\-\.\/\:\;\<\=\>\?\@\[\]\^\_\`\{\|\}\~]|" "|"\\"[ntr0\\\'\"]|"\\x"[0-9a-f]{2}
KEYWORD	"and"|"as"|"begin"|"break"|"byte"|"continue"|"decl"|"def"|"elif"|"else"|"end"|"exit"|"false"|"if"|"is"|"int"|"loop"|"not"|"or"|"ref"|"return"|"skip"|"true"|"var"	

%%

{KEYWORD}			{ return TOK_KEYWORD; }

[[:alpha:]][[:alnum:]_]*	{ return TOK_ID; }
[[:digit:]]+			{ return TOK_CONST_INT; }
\'{CHAR}\'			{ return TOK_CONST_CHAR; }
\"{CHAR}*\"			{ return TOK_CONST_STRING; }

[\+\-\*\/%\!\&\|\=\<\>]		{ return (token_t)yytext[0]; }
[\(\)\[\]\,\:]			{ return (token_t)yytext[0]; }

^[ \t]+	{
	size_t cur_len = get_indent_length(yyleng, yytext),
	       top = stack_empty(indent_stack) ?
		       0 : stack_peek(indent_stack, size_t);

	if (cur_len > top) {
		stack_push(indent_stack, cur_len);
		yytext[0] = '\0';
		return TOK_IND_START;
	}
	if (cur_len < top) {
		UNUSED(stack_pop(indent_stack, size_t));
		yyleng -= cur_len - top;
		return TOK_IND_END;
	}
}
[ \t]+	/* */
\n	/* */

\#.*$		/* single-line */
\(\*		{ comment_depth = 1; BEGIN(COMMENT); }
<COMMENT>{
	\(\*	{ comment_depth++; }
	\*\)	{ if (--comment_depth == 0) BEGIN(INITIAL); }
	.|\n     /* eat up any unmatched character */
}

.		{
	eprintf("Illegal character: '%c'(%d)\n", yytext[0], (int)yytext[0]);
}

%%

int
main (int argc, char **argv)
{
	token_t token;

	argc--, argv++;
	yyin = argc ? fopen(argv[0], "r") : stdin;
	indent_stack = stack_init(indent_stack_pool, LEN(indent_stack_pool));

	token = yylex();
	for (; token != TOK_EOF; token = yylex()) REGISTER(token, yytext);

	for (; !stack_empty(indent_stack);
			UNUSED(stack_pop(indent_stack, size_t)))
		REGISTER(TOK_IND_END, "");

	UNUSED(input);
	UNUSED(yyunput);
}
