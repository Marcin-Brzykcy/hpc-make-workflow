TARGET ?= hello
OUTPUT_FILE = output.txt
ifeq ($(origin CC),default)
CC = gcc
endif
CFLAGS ?= -O2 -Wall -Wextra

.PHONY: all clean
all: $(TARGET)

$(TARGET): hello.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

clean:
	rm -f $(TARGET)
