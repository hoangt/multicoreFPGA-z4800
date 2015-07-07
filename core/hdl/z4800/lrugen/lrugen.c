/*
Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License,
version 2, as published by the Free Software Foundation.
Other versions of the license may NOT be used without
the written consent of the copyright holder(s).

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/


/* This is one of the biggest hacks I've ever written in my life. */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <strings.h>
#include <string.h>

#define false 0
#define true 1

int fact(int x){
   int ret = 1;
   for(int i = x;i > 1;i--) ret *= i;
   return ret;
}

int log2c(int x){
   int ret = 0;
   int i = 1;
   while(i < x){
      i <<= 1;
      ret++;
   }
   return ret;
}

int dump_p(int *p, int n){
   for(int i = 0;i < n;i++) printf("%d ", p[i]);
   printf("\n");
}

int binprint(int x, int nbits){
   assert(nbits <= 32);
   char s[33], o[33];
   char *p = s;
   char *q = o;
   for(int i = 0;i < nbits;i++){
      *p++ = (x & 1) ? '1' : '0';
      x >>= 1;
   }
   for(int i = 0;i < nbits;i++){
      *q++ = *--p;
   }
   *q++ = '\0';
   printf("%s", o);
}

int is_unique(int *p, int n){
   int *s = malloc(sizeof(int) * n);
   for(int i = 0;i < n;i++) s[i] = 0;
   for(int i = 0;i < n;i++){
      if(s[p[i]] == 0) s[p[i]]++;
      else{
         free(s);
         return false;
      }
   }
   free(s);
   return true;
}

int bump(int *p, int n, int t){
   int ret = 1;
   if(n > 1) ret = bump(p + 1, n - 1, t);
   if(ret){
      (*p)++;
      if(*p == t){
         *p = 0;
         return true;
      }
      else return false;
   }
   return false;
}

void twiddle(int *cur, int **perms, int n, int nperms, int repl, int *p){
   p[0] = repl;
   int j = 1;
   for(int i = 0;i < n;i++){
      if(cur[i] != repl) p[j++] = cur[i];
   }
}

int lookup(int **perms, int *p, int n, int nperms){
   for(int i = 0;i < nperms;i++){
      if(!bcmp(perms[i], p, sizeof(int) * n)) return i;
   }
   printf("lookup failed\n");
   return -1;
}

int main(int argc, char *argv[]){
   int nways = atoi(argv[1]);
   //printf("%d-way cache\n", nways);
   int nwaybits = log2c(nways);
   int nperms = fact(nways);
   int nlrubits = log2c(nperms);
   //printf("%d permutations, requiring %d bits\n", nperms, nlrubits);

   int *p = malloc(sizeof(int) * nways);
   for(int i = 0;i < nways;i++) p[i] = i;
   int **perms = malloc(sizeof(int *) * nperms);
   for(int i = 0;i < nperms;i++) perms[i] = malloc(sizeof(int) * nways);
   memcpy(perms[0], p, sizeof(int) * nways);
   for(int n = 1;n < nperms;n++){
      memcpy(perms[n], perms[n - 1], sizeof(int) * nways);
      bump(perms[n], nways, nways);
      while(!is_unique(perms[n], nways)) bump(perms[n], nways, nways);
   }

   int *pn = malloc(sizeof(int) * nways);

   printf("WIDTH=%d;\n", nlrubits + nwaybits);
   printf("DEPTH=%d;\n", 1 << log2c(nperms * nways));
   printf("ADDRESS_RADIX=BINARY;\n");
   printf("DATA_RADIX=BINARY;\n");
   printf("CONTENT BEGIN\n");

   // output format: curstate & most_recent -> nextstate & least_recent

   for(int i = 0;i < nperms;i++){
      for(int j = 0;j < nways;j++){
         twiddle(perms[i], perms, nways, nperms, j, pn);
         int next_state = lookup(perms, pn, nways, nperms);
         binprint(i, nlrubits);
         binprint(j, nwaybits);
         printf(" : ");
         binprint(next_state, nlrubits);
         binprint(perms[i][nways - 1], nwaybits);
         printf(";\n");
      }
   }
   printf("END;\n");
   return 0;
}
