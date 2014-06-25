source /home/tomas/Unicamp/MC404/simulador/set_path.sh

make clean
make

arm-eabi-as -g boot.s -o boot.o && arm-eabi-ld boot.o -o boot -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0 && mksd.sh --so boot --user dummy_user && arm-sim --rom=/home/tomas/Unicamp/MC404/simulador/dumboot.bin --sd=disk.img -g $1
