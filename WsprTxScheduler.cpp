#include "WsprTxScheduler.h"

int tx_band_sum(char bsum[10])
{
    int i,j;
    
    for (j=0; j<10; j++) {
        bsum[j]=0;
        for (i=0; i<6; i++) {
            bsum[j]=bsum[j]+tx[i][j];
        }
    }
    return 1;
}

int tx_add_to_band(int band)
{
    // add tx cycle to a band without regard to ntxlim
    int i,islot;
    for ( i=0; i<10; i++) {
        islot=rand()%6;
        if( tx[islot][band] != 1 ) {
            tx[islot][band]=1;
            return 1;
        }
    }
    return 0;
}

int tx_sum()
{
    int i,j,sum=0;
    for (i=0; i<6; i++) {
        for (j=0; j<10; j++) {
            sum=sum+tx[i][j];
        }
    }
    return sum;
}

int tx_add_one(char* tx)
{
    int i;
    for (i=1; i<59; i++) {
        if( tx[i-1]==0 && tx[i]==0 && tx[i+1]==0 ) {
            tx[i]=1;
            return 1;
        }
    }
    return 0;
}

int tx_trim(char* tx, int ntxlim)
{
    // trim array to that ntxlim is not exceeded
    int i,nrun,sum;
    nrun=0;
    for (i=0; i<60; i++) {
        if( tx[i]==1 ) {
            nrun++;
            if( nrun > ntxlim ) {
                tx[i]=0;
                nrun=0;
            }
        } else {
            nrun=0;
        }
    }
    sum=0;
    for (i=0; i<60; i++) {
        sum=sum+tx[i];
    }
    return sum;
}

void tx_print()
{
    int i,j;
    for (i=0; i<6; i++) {
        for (j=0; j<10; j++) {
            if( (i*10+j)%10 == 0 && i>=0 ) printf("\n");
            printf("%d ",tx[i][j]);
        }
    }
    printf("\n");
}

int create_tx_schedule(int pctx)
{
    char bsum[10];
    int i, j, k, sum, ntxlim, ntxbandmin, needed;
    int iflag;
    
    needed=60*(pctx/100.0)+0.5;
    
    srand(time(NULL));
    memset(tx,0,sizeof(char)*60);
    
    if( pctx < 17 ) {
        needed=pctx*60/100;
        for (i=0; i<needed; i++) {
            tx[rand()%6][rand()%10]=1;
        }
        return 1;
    } else if( pctx >= 17 && pctx < 33 ) {
        ntxlim=1;
        ntxbandmin=1;
    } else if( pctx >= 33 && pctx < 50 ) {
        ntxlim=1;
        ntxbandmin=2;
    } else if( pctx >= 50 && pctx < 60 ) {
        ntxlim=2;
        ntxbandmin=3;
    } else {
        ntxlim=3;
        ntxbandmin=4;
    }
    
    // start by filling each band slot with ntxbandmin tx's
    for (i=0; i<ntxbandmin; i++) {
        for (j=0; j<10; j++) {
            tx_add_to_band(j);
        }
    }
    // trim so that no more than ntxlim successive transmissions
    sum=tx_trim(*tx,ntxlim);
    j=0;
    iflag=0;
    while (j<100 && iflag==0) {
        // now backfill columns that got trimmed
        tx_band_sum(bsum);
        
        iflag=1;
        for (i=0; i<10; i++) {
            if( bsum[i] < ntxbandmin ) {
                iflag=0;
                for (k=0; k<ntxbandmin-bsum[i]; k++) {
                    tx_add_to_band(i);
                }
            }
        }
        sum=tx_trim(*tx,ntxlim);
        j++;
    }
    
    for(j=0; j < (needed-sum); j++ ) {
        tx_add_one(*tx);
    }
    return 0;
}

int next_tx_state(int pctx)
{
  time_t now=time(0)+30;
  tm *ltm = localtime(&now);
  int hour  = ltm->tm_hour;
  int minute = ltm->tm_min;

  int tx_2hr_slot = hour/2; 
  int tx_20min_slot = (hour-tx_2hr_slot*2)*3 + minute/20;
  int tx_2min_slot = (minute%20)/2;

  if( (tx_2hr_slot != tx_table_2hr_slot) || (tx_table_pctx != pctx) ) {
    create_tx_schedule(pctx);
    tx_table_2hr_slot = tx_2hr_slot;
    tx_table_pctx = pctx;
  }
  
  cout << "Hour " << hour << " Minute " << minute << endl;
  cout << "tx_2hr_slot " << tx_2hr_slot << endl;
  cout << "tx_20min_slot " << tx_20min_slot << endl;
  cout << "tx_2min_slot " << tx_2min_slot << endl;
  cout << "tx_table_2hr_slot " << tx_table_2hr_slot << endl;
  cout << "Requested % " << pctx << " Actual % " << 100*tx_sum()/60 << endl;
  tx_print();
  return tx[tx_20min_slot][tx_2min_slot];
}
/*
int main(int argc, char *argv[])
{
    
    if( argc == 2 ) {
        pctx = atoi(argv[1]);
    } else {
        pctx = 25;
    }
    tx_table_2hr_slot = 0;
    cout << "Next TX state: " << next_tx_state(m_pctx) << endl;
    cout << "Requested % " << pctx << " Actual % " << 100*tx_sum()/60 << endl;
    tx_print();
}
*/
