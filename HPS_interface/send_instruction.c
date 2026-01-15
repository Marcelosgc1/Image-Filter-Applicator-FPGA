#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "lib/stb_image.h"
#include "lib/stb_image_write.h"
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include "lib/hps.h"
#include <pthread.h>

#define LW_BRIDGE_BASE    0xFF200000
#define LW_BRIDGE_SPAN    0x00005000

#define PIO_CMD_OFFSET    0x00  /* HPS → FPGA (pio_out) */
#define PIO_STAT_OFFSET   0x10  /* FPGA → HPS (pio_in) */

#define N_BYTES           25    /* 200 bits / 8 */
#define N_BITS            (N_BYTES * 8)

int open_dev(void)
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open(/dev/mem)");
        exit(1);
    }
    return fd;
}

void *map_hps(int fd)
{
    void *base = mmap(NULL,
                      LW_BRIDGE_SPAN,
                      PROT_READ | PROT_WRITE,
                      MAP_SHARED,
                      fd,
                      LW_BRIDGE_BASE);
    if (base == MAP_FAILED) {
        perror("mmap");
        close(fd);
        exit(1);
    }
    return base;
}

void unmap_hps(void *base)
{
    if (munmap(base, LW_BRIDGE_SPAN) != 0) {
        perror("munmap");
        exit(1);
    }
}



void bayer_grbg_to_rgb(uint8_t *bayer, uint8_t *rgb, uint8_t *greyscale, int width, int height) {
    int x, y;

    #define PIX(x, y) bayer[(y) * width + (x)]
    #define CLAMP(v) ((v) < 0 ? 0 : ((v) > 255 ? 255 : (v)))

    for (y = 1; y < height - 1; y++) {
        for (x = 1; x < width - 1; x++) {
            int r = 0, g = 0, b = 0;

            int idx = y * width + x;
            int out_idx = idx * 3;

            if (y % 2 == 0) {
                if (x % 2 == 0) {
                    // G pixel (even row, even col)
                    g = PIX(x, y);
                    r = (PIX(x-1, y) + PIX(x+1, y)) / 2;
                    b = (PIX(x, y-1) + PIX(x, y+1)) / 2;
                } else {
                    // R pixel
                    r = PIX(x, y);
                    g = (PIX(x-1, y) + PIX(x+1, y) + PIX(x, y-1) + PIX(x, y+1)) / 4;
                    b = (PIX(x-1, y-1) + PIX(x+1, y-1) + PIX(x-1, y+1) + PIX(x+1, y+1)) / 4;
                }
            } else {
                if (x % 2 == 0) {
                    // B pixel
                    b = PIX(x, y);
                    g = (PIX(x-1, y) + PIX(x+1, y) + PIX(x, y-1) + PIX(x, y+1)) / 4;
                    r = (PIX(x-1, y-1) + PIX(x+1, y-1) + PIX(x-1, y+1) + PIX(x+1, y+1)) / 4;
                } else {
                    // G pixel (odd row, odd col)
                    g = PIX(x, y);
                    r = (PIX(x, y-1) + PIX(x, y+1)) / 2;
                    b = (PIX(x-1, y) + PIX(x+1, y)) / 2;
                }
            }
	    
            rgb[out_idx + 0] = CLAMP(b);
            rgb[out_idx + 1] = CLAMP(g);
            rgb[out_idx + 2] = CLAMP(r);
            
	        //https://www.w3.org/Graphics/Color/sRGB
            greyscale[idx] = (0.2126 * CLAMP(r)) + (0.7152 * CLAMP(g)) + (0.0722 * CLAMP(b));
        }
    }
}


void imageFromFPGA(volatile int *pio_cmd, uint8_t *image){
    volatile int *pio_instruction = pio_cmd;
    volatile int *pio_pixel_color = pio_cmd + 4;
    int count = 0;
    int temp = 0, t2 = 0;
    int beyer;

    while(count < 65536){
	    temp = (count<<4) + 15;
        *pio_instruction = temp;
        beyer = *pio_pixel_color;
        
	    t2 = count<<2;
        image[t2] = beyer & 255;
        image[t2+1] = (beyer >> 8) & 255;
        image[t2+2] = (beyer >> 16) & 255;
        image[t2+3] = (beyer >> 24) & 255;
        //printf("%x %d %d\n", beyer, count, *pio_instruction>>4); //debug
        count = count + 1;
    }

    *pio_instruction = 0;
    return;
}

void imageToFPGA(volatile int *pio_cmd, uint8_t *image){
    volatile int *pio_instruction = pio_cmd;
    volatile int *pio_pixel_color = pio_cmd + 8;
    int count = 0;
    int temp = 0, t2 = 0;

    while(count < 65536){
	    temp = (count<<4) + 13;
        t2 = count<<2;
        *pio_pixel_color = image[t2] | image[t2+1] << 8 | image[t2+2] << 16| image[t2+3] << 24;
        *pio_instruction = temp;
        
	    
        //printf("%x %d %d\n", beyer, count, *pio_instruction>>4); //debug
        count = count + 1;
        *pio_instruction = 0;
    }

    *pio_instruction = 0;
    return;
}

void generateImage(volatile int *pio_cmd){
    uint8_t *image = malloc(512*512);
    imageFromFPGA(pio_cmd, image);
    uint8_t *rgb_img = malloc(512 * 512 * 3);
    uint8_t *gs = malloc(512 * 512);
    bayer_grbg_to_rgb(image, rgb_img, gs, 512, 512);
    stbi_write_png("data/outputRGB.png", 512, 512, 3, rgb_img, 512*3);
    stbi_write_png("data/outputGS.png", 512, 512, 1, gs, 512);
    stbi_write_png("data/raw.png", 512, 512, 1, image, 512);

}

void sendImage(volatile int *pio_cmd){
    //uint8_t *image = malloc(512*512);
    uint8_t *input_img = "data/raw.png";
    int alt, larg, chan; 
    uint8_t *image_p = stbi_load(input_img, &alt, &larg, &chan, 1);

    imageToFPGA(pio_cmd, image_p);
    
}

int getInstruction(int num){
    int fpgaInstruction = 14;
    num = num << 4;
    return fpgaInstruction | num;
}

int main(void){
    volatile int *pio_cmd;
    void *hps_base;
    int fd;

    fd       = open_dev();
    hps_base = map_hps(fd);
    pio_cmd  = (volatile int *)((char*)hps_base + PIO_LED_BASE);
    //////////////////////////////
    int input;
    int program = 1;
    while (program){
        printf("===What wanna do?===\n");
        printf("0 -\tIdentity\n");
        printf("1 -\tED Roberts\n");
        printf("2 -\tED Sobel\n");
        printf("3 -\tED Prewitt\n");
        printf("4 -\tED Exp. Sobel\n");
        printf("5 -\tED Laplace\n");
        printf("6 -\tSharpen\n");
        printf("7 -\tConvert to Grayscale\n");
        printf("8 -\tRead Image\n");
        printf("9 -\tWrite Image\n");
        printf("===Any other integer to close program===\n");
        scanf("%d", &input);
        switch (input){
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 6:
	        case 7:
                *pio_cmd = getInstruction(input);
                printf("\ninst: %x\n\n",*pio_cmd);
                break;
            case 8:
                generateImage(pio_cmd);
                break;
            case 9: 
                sendImage(pio_cmd);
                break;
            default:
                program = 0;
                break;
        }
        *pio_cmd = 0;
    }
    
    unmap_hps(hps_base);
    close(fd);
    return 0;
}
