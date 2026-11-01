TARGET ?= openmp
OUTPUT_FILE = output.txt
ifeq ($(origin CC),default)
CC = gcc
endif
CFLAGS ?= -O2 -fopenmp

SRCS := $(wildcard *.c)
.PHONY: all clean
all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

clean:
	rm -f $(TARGET)
