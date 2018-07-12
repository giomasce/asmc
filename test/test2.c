
int test, test2;
unsigned char x, y, z;
char *ptr, arr[8];
short arr2[3];
char *arr3[10];
char *(arr4[10]);
char (*arr5)[10];

void (*main_ptr)(int argc, char *argv[], char*);

// Test from http://www.unixwiz.net/techtips/reading-cdecl.html
char *(*(**foo [0][8])())[];

int main(int other_name, char **);

int main(int argc, char **argv) {
  char c;
  int x1;
  unsigned int x2;
  int arr[10];

  /*2+2;
  2-2;
  2*2;
  2/2;
  2%2;*/

  //2 < (2+2/2);

  2+x1+x;

  /*x1;
  c;
  c+x1+x2;
  //"hello";
  main_ptr;*/

  0+0;
  return;
}

int main(int, char**);
