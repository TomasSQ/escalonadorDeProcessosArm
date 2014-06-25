arm-as=arm-eabi-as
arm-ld=arm-eabi-ld
arm-cc=arm-eabi-gcc
asflags=-g
ldflags=-g -Ttext=0x77802000

all: ra137748

ra137748: boot.o
	$(arm-ld) boot.o -o ra137748 $(ldflags) 

boot.o: boot.s
	$(arm-as) $(asflags) boot.s -o boot.o

clean:
	rm -f *.o ra137748
