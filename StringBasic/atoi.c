/****************

int atoi_(const char* str);

Convert string to integer
Parses the C-string str interpreting its content as an integral number, which 
is returned as a value of type int.

The function first discards as many whitespace characters (as in isspace) as 
necessary until the first non-whitespace character is found. Then, starting 
from this character, takes an optional initial plus or minus sign followed by
 as many base-10 digits as possible, and interprets them as a numerical value.

The string can contain additional characters after those that form the integral 
number, which are ignored and have no effect on the behavior of this function.

If the first sequence of non-whitespace characters in str is not a valid 
integral number, or if no such sequence exists because either str is empty or 
it contains only whitespace characters, no conversion is performed and zero is 
returned.

****************/

int atoi_(const char* str);

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

int atoi_(const char* s)
{
	int num = 0;
	bool is_neg = false;
	if (!s) {
		return 0;
	}

	// NB. isspace('\0') == false
	while (isspace(*s)) {
		++s;
	}

	if (*s == '+') {
		++s;
	} else if (*s == '-') {
		is_neg = true;
		++s;
	}

	while (*s >= '0' && *s <= '9') {
		num = num * 10 + *s++ - '0';
	}

	if (is_neg) {
		return -num;
	} else {
		return num;
	}

}

int main(int argc, char const *argv[])
{
	char a[250];

	#define ASSERT_EQ(s) assert(atoi_(s) == atoi(s))

	ASSERT_EQ("42");
	ASSERT_EQ("-12345");
	ASSERT_EQ("+10086");
	ASSERT_EQ("0");
	ASSERT_EQ("+0");
	ASSERT_EQ("-0");
	ASSERT_EQ("");
	ASSERT_EQ("-");
	ASSERT_EQ("+");
	ASSERT_EQ("+-");
	ASSERT_EQ("2147483647");
	ASSERT_EQ("2147483648");
	ASSERT_EQ("-2147483648");
	ASSERT_EQ("-2147483649");
	ASSERT_EQ("0000000000000001");
	ASSERT_EQ("some_interviewers_are_assholes");
	ASSERT_EQ("+plus");
	ASSERT_EQ("-minus");
	ASSERT_EQ("    9527");
	ASSERT_EQ("GFW404");
	ASSERT_EQ("    CALL911");
	ASSERT_EQ("  1024WTF");

	fgets(a, sizeof(a), stdin);
	a[strlen(a) - 1] = 0;
	printf("%i\n", atoi_(a));
	return 0;
}