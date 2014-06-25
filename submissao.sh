#!/bin/sh

if [ $# -lt 1 ]
then
	echo "modo de uso: ./submissao.sh ra<seu_ra>"
else
	mkdir $1
	cp Makefile_submissao $1/Makefile
	cp boot.s $1/

	echo "ra135494" >> $1/grupo.txt
	echo "ra137748" >> $1/grupo.txt
	
	tar -zcvf $1.tar.gz $1

	rm -rf $1
fi
