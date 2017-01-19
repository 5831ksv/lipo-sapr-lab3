%{
/*
This file is part of Reverse Notation Calc.

    Reverse Notation Calc is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

*/

#include "mystack.h"
int int_value;

typedef enum {
    LexNumber=1001,
    LexPlus,
    LexMinus,
    LexDiv,
    LexMult,
	MultipConcatenate,
	MultipIntersection,
	ElementMultip,
	MultLeftBracket,
	MultRightBracket,
	Delimiter,
    LexEnd,
    LexUnknown,
} LexType;

/* enum for state stack */
typedef enum {
	opened=1,		
	writing=2,		
	closed=3,		
} stack_state;

my_stack calc_stack;

my_stack mult_stack;

my_stack mults_count_stack;

stack_state mult_stack_state;

int numbers_in_mult_count;

int is_number_received;

int end_file;

%}

%s SKIPERROR

digit     [0-9]
number    {digit}+

%%

{number}	{
		  int_value=atoi(yytext);
		  fprintf(stderr, "%d", int_value);
		  return LexNumber; }
\+		{
		  fprintf(stderr, " + ");
		  return LexPlus; }
\+m	{
		  fprintf(stderr, " +_mult ");
		  return MultipConcatenate;
		}
\-		{
		  fprintf(stderr, " - ");
		  return LexMinus; }
\/		{
		  fprintf(stderr, " / ");
		  return LexDiv; }
\*		{
		  fprintf(stderr, " * ");
		  return LexMult; }
\*m		{
		  fprintf(stderr, " *_mult ");
		  return MultipIntersection;
		}
\[		{
		  fprintf(stderr, " [ ");
		  return MultLeftBracket;
		}
\]		{
		  fprintf(stderr, " ] ");
		  return MultRightBracket;
		}
,		{
		  fprintf(stderr, " , ");
		  return Delimiter;
		}
\?		{
		  fprintf(stderr, " <<_elementMult| ");
		  return ElementMultip;
		}
^[ \t]*\n	{
		  fprintf(stderr, "empty line\n");
		}
\n		{
		  fprintf(stderr, "CR\n");
		  return LexEnd; }
[ \t]		{ }
.		{ return LexUnknown; }

<SKIPERROR>[^\n]* {}
%%

int process_command(int token)
{
    /* fprintf(stderr, "token: %d\n", token); */

    switch (token) {

	case LexNumber:	{
		if (mult_stack_state == writing)
		{
			int state = my_stack_deep_search(&mult_stack, int_value, numbers_in_mult_count, 0);
			if ((state == 0) || ((state == -1) && (mult_stack.count == 0)))
			{
				if (push_in_stack(&mult_stack, int_value))
				{
					numbers_in_mult_count++;
				}
				else 
				{
					return -2;
				}
			}
			else if (state == 1)
			{
				return -1;
			}
			else if ((state == -1) && (mult_stack.count != 0))
			{
				return -2;
			}
			is_number_received = 1;
		}
		else
		{
			if (!push_in_stack(&calc_stack, int_value))
			{
				return -2;
			}
		}
		break;}
	
	case LexPlus:	{
		if (mult_stack_state == writing)
		{
			return -1;
		}
		int state = stack_top_values_summ(&calc_stack);
		if (!state)
		{
			return state;
		}
		break;}

	case MultipConcatenate:	{
		if (mult_stack_state == writing)
		{
			return -1;
		}
		int state = stack_top_values_summ(&mults_count_stack);
		if (!state)
		{
			return state;
		}
		break;}

	case LexMinus: {
		if (mult_stack_state == writing)
		{
			return -1;
		}
		
		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int a=my_stack_pull(&calc_stack);

		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int b=my_stack_pull(&calc_stack);

		my_stack_push(&calc_stack, b-a);
		if (my_stack_is_full(&calc_stack)) {
			return -2;
		}
		break;}
	
	case LexDiv: {
		if (mult_stack_state == writing)
		{
			return -1;
		}
		
		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int a=my_stack_pull(&calc_stack);

		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int b=my_stack_pull(&calc_stack);

		my_stack_push(&calc_stack, b/a);
		if (my_stack_is_full(&calc_stack)) {
			return -2;
		}
		break;}
		
	case LexMult: {
		if (mult_stack_state == writing)
		{
			return -1;
		}
		
		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int a=my_stack_pull(&calc_stack);

		if (my_stack_is_empty(&calc_stack)) {
			return -1;
		}
		int b=my_stack_pull(&calc_stack);

		my_stack_push(&calc_stack, b*a);
		if (my_stack_is_full(&calc_stack)) {
			return -2;
		}
		break;}
		
	case MultipIntersection: {
		if (mult_stack_state == writing)
		{
			return -1;
		}
		int state = intersector_two_set();
		if (state < 0)
		{
			return state;
		}
		break;}			
	
	case MultLeftBracket:	{
		if (mult_stack_state == writing)
		{
			return -1;
		}

		if (mult_stack_state == closed)
		{
			mult_stack_state = writing;
			numbers_in_mult_count = 0;
		}
		break;}	

	case MultRightBracket:	{
		if (mult_stack_state == writing)
		{
			mult_stack_state = closed;
			if (push_in_stack(&mults_count_stack, numbers_in_mult_count))
			{
				numbers_in_mult_count = 0;
			}
			else
			{
				return -2;
			}
			is_number_received = 0;
		}
		else
		{
			return -1;
		}
		break;}
		
		case Delimiter:	{
		if (((mult_stack_state == writing)  && !(is_number_received))
			|| (!(mult_stack_state == writing)))
		{
			return -1;
		}
		is_number_received = 0;
		break;}
		case ElementMultip:	{
		if (mult_stack_state == writing) 
		{
			return -1;
		}
		else
		{
			int number = my_stack_pull(&calc_stack);
			int mult_count = my_stack_pull(&mults_count_stack);
			
			int state = my_stack_deep_search(&mult_stack, number, mult_count, 0);
			
			my_stack_push(&mults_count_stack, mult_count);
			
			if (state < 0)
			{
				return state;
			}
			else if (state >= 0)
			{
				my_stack_push(&calc_stack, state);
			}
		}
		break;}	
		
		case LexEnd:
		case 0:
			return 0;
			
		case LexUnknown:
			return -1;
	}
	return 1;
}

/* intersects two sets */ 
int intersector_two_set()
{
	my_stack temp_stack_1;
	my_stack temp_stack_2;
	my_stack_init(&temp_stack_1, 100);
	my_stack_init(&temp_stack_2, 100);
	
	int first = my_stack_pull(&mults_count_stack);
	int second;

	int mult_stack_count = mult_stack.count;
	
	for (int i = 0; i < first; i++)
	{
		my_stack_push(&temp_stack_1, my_stack_pull(&mult_stack));
	};
	
	second = my_stack_pull(&mults_count_stack);
	for (int i = 0; i < second; i++)
	{
		my_stack_push(&temp_stack_2, my_stack_pull(&mult_stack));
	};
	
	/* temporary stacks to reduce the search item in the set */
	my_stack short_set;
	my_stack long_set;
	
	if (first >= second)
	{
		short_set = temp_stack_1;
		long_set = temp_stack_2;
	}
	else if (second > first)
	{
		short_set = temp_stack_2;
		long_set = temp_stack_1;
	}
	
	int amount_of_elements = 0;
		
	while (!my_stack_is_empty(&short_set))
	{
		int number = my_stack_pull(&short_set);
		int state = my_stack_deep_search(&long_set, number, long_set.count, 0);
		if (state == 1)
		{
			my_stack_push(&mult_stack, number);
			amount_of_elements++;
		}
		else if (state == -1)
		{
			return state;
		}
	}
	
	my_stack_push(&mults_count_stack, amount_of_elements);
	
	my_stack_done(&temp_stack_2);
	
	my_stack_done(&temp_stack_1);
	
	return 1;
}

/* summ of two value in top of stack */
int stack_top_values_summ(my_stack *stack)
{
	int a=my_stack_pull(stack);

	if (my_stack_is_empty(stack)) {
		return -1;
	}
	int b=my_stack_pull(stack);

	my_stack_push(stack, a+b);
	if (my_stack_is_full(stack)) {
		return -2;
	}
	return 1;
}

/* Just pushing a value to stack */
int push_in_stack(my_stack *stack, int value)
{
	my_stack_push(stack, value);

	if (my_stack_is_full(stack)) {
		return 0;
	}

	return 1;
}

/* resets all flags, stack states and cleans all stacks */
void reset_flags_and_states()
{
	mult_stack_state = closed;
	
	numbers_in_mult_count = 0;

	is_number_received = 0;
}

/* only cleans all stacks  */
void clean_all_stacks()
{
	clean_stack(&calc_stack);
	clean_stack(&mult_stack);
	clean_stack(&mults_count_stack);
}

/* cleans a stack with recording values in temp */
void clean_stack(my_stack *stack)
{
	int temp;
	while (!my_stack_is_empty(stack))
	{
		temp = my_stack_pull(stack);
	}
}
int calc_line()
{
	int token = yylex();
	if (token == 0) {
		return 1;
	}

	while (1) {
		int cmd_res = process_command(token);
		/* reset flags and stack state at shutdown */
		if (cmd_res < 0) {
			reset_flags_and_states();
		}
		
		if (cmd_res == 0) {
			break;
		}
		else if (cmd_res == -1) {
			fprintf(stderr, "\nSyntax error\n");
			clean_all_stacks();
			return 0;
		}
		else if (cmd_res == -2) {
			fprintf(stderr, "\nError: Stack is full\n");
			clean_all_stacks();
			return 0;
		}
		token = yylex();
	}
	
	/* output in the console result of operations with multiplicity */
	
	if (!my_stack_is_empty(&mult_stack))
	{
		fprintf(yyout, "%s", "\nResults of multiplicity operations:\n");
		fprintf(yyout, "%s", " set(");
		while(!my_stack_is_empty(&mult_stack))
		{
			fprintf(yyout, "%d", my_stack_pull(&mult_stack));
			if (!my_stack_is_empty(&mult_stack))
			{
				fprintf(yyout, "%s", ",");
			}
		}
		fprintf(yyout, "%s", ")\n");
	}
	
	
	/* output in the console the result of default settlement operations */
	
	if (!my_stack_is_empty(&calc_stack))
	{
		fprintf(yyout, "%s", "\nResults default operations:\n");
		int result = my_stack_pull(&calc_stack);
		fprintf(yyout, " %d ", result);

		if (!my_stack_is_empty(&calc_stack)) {
			fprintf(stderr, "Calculation stack not empty after calculation\n");
			return 0;
		}
	}
	
	reset_flags_and_states();
	clean_all_stacks();
	
	return 1;
}

void calc()
{
    while (!end_file) {
        fprintf(stderr, "parse line\n");
        if (calc_line() == 0) {
            printf("FAIL\n");
            BEGIN(SKIPERROR);
            yylex();
            BEGIN(INITIAL);
        }
        else {
            printf("OK\n");
        }
        fprintf(stderr, "line parsed\n");
    }
}

int main(void)
{
	my_stack_init(&calc_stack, 100);
	
	my_stack_init(&mult_stack, 100);
	
	my_stack_init(&mults_count_stack, 100);
	
	reset_flags_and_states();
	
	end_file = 0;
	
	calc();

	my_stack_done(&mults_count_stack);
	
	my_stack_done(&mult_stack);
	
	my_stack_done(&calc_stack);
	
	return 0;
}

int yywrap(void)
{
    end_file = 1;
    return 1;
}
