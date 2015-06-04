#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <iostream>

using namespace std;

char tx[6][10];
int pctx, tx_table_2hr_slot;

int tx_band_sum(char bsum[10]);
int tx_add_to_band(int band);
int tx_sum();
int tx_add_one(char* tx);
int tx_trim(char* tx, int ntxlim);
void tx_print();
int create_tx_schedule();
int next_tx_state();
