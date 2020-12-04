
# ----------------------------------------------------------------------
# adjust the following to the location of your Lua include file

INCFLAGS= -I../lua/include

# ----------------------------------------------------------------------

CC= gcc
AR= ar

CFLAGS= -Os -fPIC $(INCFLAGS) 
LDFLAGS= -fPIC

OBJS= vl5.o

vl5.so:  vl5.c
	$(CC) -c $(CFLAGS) vl5.c
	$(CC) -shared $(LDFLAGS) -o vl5.so $(OBJS)
	strip vl5.so

clean:
	rm -f *.o *.a *.so

.PHONY: clean


