FBC=fbc #compiler
PRIMARY=PPool #primary file (main program)

all:
	$(FBC) -x $(PRIMARY) -s gui PPool.bas
	
clean:
	rm *.o $(PRIMARY) $(SECONDARY)
