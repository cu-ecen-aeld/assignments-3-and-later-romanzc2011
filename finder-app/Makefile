CC=$(CROSS_COMPILE)gcc
CFLAGS=-g
OBJ=writer.o

all: writer

writer: $(OBJ)
	$(CC) -o $@ $^

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

.PHONY: clean

clean:
	rm -f $(OBJ) writer
