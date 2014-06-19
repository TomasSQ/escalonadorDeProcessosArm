source /home/specg12-2/mc404/simulador/set_path.sh

make clean
make

arm-eabi-as -g ra137748.s -o ra137748.o
arm-eabi-ld ra137748.o -o ra137748 -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0
mksd.sh --so ra137748 --user faz_nada
arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img -g

