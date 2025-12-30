#include <stdio.h>
#include <inttypes.h>
#include <string.h>
#include <libgen.h>

char buf[65536+7];
struct ccsds {
  uint16_t apid __attribute__((packed));
  uint16_t seq __attribute__((packed));
  uint16_t length __attribute__((packed));
};

struct fast {
  struct ccsds head;
  uint32_t TC __attribute__((packed));
  int16_t max __attribute__((packed));
  int16_t may __attribute__((packed));
  int16_t maz __attribute__((packed));
  int16_t mgx __attribute__((packed));
  int16_t mgy __attribute__((packed));
  int16_t mgz __attribute__((packed));
  int16_t mt  __attribute__((packed));
  int16_t hx __attribute__((packed));
  int16_t hy __attribute__((packed));
  int16_t hz __attribute__((packed));
  int16_t hw __attribute__((packed));
  uint32_t TC1 __attribute__((packed));
};

struct pps {
  struct ccsds head;
  uint32_t TC0 __attribute__((packed));
  uint32_t TC1 __attribute__((packed));
  uint8_t last __attribute__((packed));
  uint8_t this __attribute__((packed));
};

struct ccsds* ccsds=(struct ccsds*)buf;
struct fast* fast=(struct fast*)buf;
struct pps* pps=(struct pps*)buf;
char* KwanSync="KwanSync";
uint32_t lastPPSTC;

int16_t ntohs(int16_t in) {
  return ((in&0xFF00)>>8) | ((in&0x00FF)<<8);
}

int32_t ntohl(int32_t in) {
  return ((in&0xFF000000)>>24) |
         ((in&0x00FF0000)>> 8) |
         ((in&0x0000FF00)<< 8) |
         ((in&0x000000FF)<<24);
}

unsigned int hour_packets=1200000*6;
unsigned int hour=0;
unsigned int fast_packets=0;

int main(int argc, char** argv) {
  char oufn[1024],base[1024];
  strcpy(base,basename(argv[1]));
  base[8]=0;
  FILE* inf=fopen(argv[1],"rb");
  FILE* ouf[2048];
  for(int i=0;i<2048;i++) ouf[i]=NULL;
  fread(buf,1,8,inf);
  int seq=0;
  int qes=ntohl(seq);
  while(!feof(inf)) {
    fread(buf,1,6,inf);
    ccsds->apid=ntohs(ccsds->apid) & 0x07FF;
    ccsds->seq=ntohs(ccsds->seq);
    ccsds->length=ntohs(ccsds->length);
    fread(buf+6,1,ccsds->length+1,inf);
//    fprintf(stdout,"apid 0x%03x, length %5d\n",ccsds->apid,ccsds->length);
    if(ouf[ccsds->apid]==NULL) {
      sprintf(oufn,"%s_%03x_%02d.sds",base,ccsds->apid,hour);
      ouf[ccsds->apid]=fopen(oufn,"wb");
    }
    if(ccsds->apid==0x10) {
      if(ccsds->length!=29) {
        fprintf(stderr,"Wrong length for fast packet, file offset %10d (0x%08x), expected 29, saw %d\n",(int)ftell(inf),(int)ftell(inf),ccsds->length);
        return 1;
      }
      fwrite(&qes,sizeof(qes),1,ouf[ccsds->apid]);
      fwrite(buf+6,1,ccsds->length+1,ouf[ccsds->apid]);
      fast_packets++;
      if(fast_packets % 100000 == 0) printf("%d\n",fast_packets);
      if(fast_packets>=hour_packets) {
        printf("Hour boundary: Closing and reopening files\n");
        for(int i=0;i<2048;i++) if(ouf[i]!=NULL) {
          fclose(ouf[i]);
          ouf[i]=NULL;
        }
        fast_packets=0;
        hour+=3;
      }
    } else if(ccsds->apid==0x03) {
      fwrite(buf+8,1,ccsds->length-1,ouf[ccsds->apid]);
    } else if(ccsds->apid==0x16) {
      fwrite(&qes,sizeof(qes),1,ouf[ccsds->apid]);
      fwrite(buf+6,1,ccsds->length+1,ouf[ccsds->apid]);
      pps->TC1=ntohl(pps->TC1);
//      printf("PPS packet: TC1=0x%08x (%f s), diff=%d (%f us)\n",pps->TC1,((double)(pps->TC1))/60000000.0,pps->TC1-lastPPSTC,((double)(pps->TC1-lastPPSTC))/60.0);
      lastPPSTC=pps->TC1;
    } else {
      fwrite(&qes,sizeof(qes),1,ouf[ccsds->apid]);
      fwrite(buf+6,1,ccsds->length+1,ouf[ccsds->apid]);
    }
    seq++;
    qes=ntohl(seq);
  }
  return 0;
}
