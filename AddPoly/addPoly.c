/* Add two polynomials using linked list */

#include <stdio.h>
#include <stdlib.h>

typedef struct Term
{
	int coeff;
	int expo;
	struct Term* next;
} Term;

typedef struct Poly
{
	Term* head;
	int nTerms;
} Poly;

Poly* Poly_new();
void Poly_free(Poly* poly);
void Poly_insert(Poly* poly, Term* newTerm);
void Poly_reverse(Poly* poly);
void Poly_input(Poly* poly);
void Poly_add(Poly* poly1, Poly* poly2, Poly* polySum);
void Poly_bubbleSort(Poly* poly);
void Poly_print(Poly* poly);

/********************************/

Term* _Poly_newTerm()
{
	Term* term = (Term*)malloc(sizeof(*term));
	term->next = NULL;
	return term;
}

Term* _Poly_copyTerm(Term* src)
{
	Term* dst = _Poly_newTerm();
	dst->coeff = src->coeff;
	dst->expo = src->expo;
	return dst;
}

Poly* Poly_new()
{
	Poly* poly = (Poly*)malloc(sizeof(*poly));
	poly->head = NULL;
	poly->nTerms = 0;
	return poly;
}

void Poly_free(Poly* poly)
{
	Term* t;
	for (t = poly->head; t; ) {
		Term* curr = t;
		t = t->next;
		free(curr);
	}
	free(poly);
}

void Poly_insert(Poly* poly, Term* newTerm)
{
	newTerm->next = poly->head;
	poly->head = newTerm;
	poly->nTerms++;
}

void Poly_reverse(Poly* poly)
{
	Term *t, *prev = NULL;
	for (t=poly->head; t; ) {
		Term* nextTerm = t->next;
		t->next = prev;
		prev = t;
		t = nextTerm;
	}
	poly->head = prev;
}

void Poly_input(Poly* poly)
{
	int nTerms, i;
	puts("The number of terms: ");
	scanf("%d", &nTerms);
	for (i=0; i<nTerms; ) {
		Term* newTerm = _Poly_newTerm();
		int coeff, expo;
		printf("  coefficient & exponent of term #%d: ", ++i);
		scanf("%d%d", &coeff, &expo);
		newTerm->coeff = coeff;
		newTerm->expo = expo;
		Poly_insert(poly, newTerm);
	}
}

void Poly_add(Poly* poly1, Poly* poly2, Poly* polySum)
{
	Term *t1, *t2;
	// sort before adding
	Poly_bubbleSort(poly1);
	Poly_bubbleSort(poly2);

	for (t1 = poly1->head, t2 = poly2->head;
		t1 && t2; ) {
		if (t1->expo > t2->expo) {
			Poly_insert(polySum, _Poly_copyTerm(t1));
			t1 = t1->next;
		} else if (t1->expo < t2->expo) {
			Poly_insert(polySum, _Poly_copyTerm(t2));
			t2 = t2->next;
		} else {
			Term* sum = _Poly_copyTerm(t1);
			sum->coeff += t2->coeff;
			Poly_insert(polySum, sum);
			t1 = t1->next;
			t2 = t2->next;
		}
	}

	t1 = t1 ? t1 : t2;
	while (t1) {
		Poly_insert(polySum, _Poly_copyTerm(t1));
		t1 = t1->next;
	}
	Poly_reverse(polySum);
}

void Poly_bubbleSort(Poly* poly)
{
	Term* end = NULL;
	Term** pp = &(poly->head);
	Term** _pp = pp;
	
	while (pp = _pp, (*pp) != end) {
		for (;;) {
			Term* p = *pp;
			Term* q = p->next;
			if (q == end) {
				end = p;
				break;
			}

			if (p->expo < q->expo) {
				p->next = q->next;
				q->next = p;
				*pp = q;
			}

			pp = &((*pp)->next);			
		}
	}
}

void Poly_print(Poly* poly)
{
	Term* t = poly->head;
	for (;;) {
		printf("%dx^%d", t->coeff, t->expo);
		t = t->next;
		if (t) {
			printf(" + ");
		} else {
			puts("");
			break;
		}
	}
}

/********************************/

int main(int argc, char const *argv[])
{
	Poly *poly1, *poly2, *polySum;

	puts("Input the 1st polynomial: ");
	poly1 = Poly_new();
	Poly_input(poly1);
	printf("You input is: ");
	Poly_print(poly1);

	puts("Input the 2nd polynomial: ");
	poly2 = Poly_new();
	Poly_input(poly2);
	printf("You input is: ");
	Poly_print(poly2);

	polySum = Poly_new();
	Poly_add(poly1, poly2, polySum);
	printf("Sum = ");
	Poly_print(polySum);

	Poly_free(poly1);
	Poly_free(poly2);
	Poly_free(polySum);
	return 0;
}
