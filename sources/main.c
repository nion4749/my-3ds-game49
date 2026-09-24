#include <3ds.h>
//Uploaded by ROMSFOREVER.CO
- Free ROMs & ISOs at ROMSFOREVER.CO
- Please do not delete our credit when re-upload
int main(int argc, char* argv[]) {
    // Запуск вашей игры
    gfxInitDefault();
    
    // Основной цикл программы 3DS
    while (aptMainLoop()) {
        hidScanInput();
        u32 kDown = hidKeysDown();
        if (kDown & KEY_START) break; // Выход при нажатии START
        
        gfxFlushBuffers();
        gfxSwapBuffers();
    }
    
    gfxExit();
    return 0;
}
