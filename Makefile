
# ----------------------------------------------------------------------
# adjust the following to the location of your Lua include file

INCFLAGS= -I../lua/include

# ----------------------------------------------------------------------

CC= gcc
AR= ar

CFLAGS= -Os -fPIC $(INCFLAGS) 
LDFLAGS= -fPIC

OBJS= vl5core.o

vl5.so:  vl5core.c
	$(CC) -c $(CFLAGS) vl5core.c
	$(CC) -shared $(LDFLAGS) -o vl5core.so $(OBJS)
	strip vl5core.so

test: vl5core.so
	lua test.lua

clean:
	rm -f *.o *.a *.so

.PHONY: clean


