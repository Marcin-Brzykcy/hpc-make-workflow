TARGET ?= cuda-example
NVCC ?= nvcc
NVCCFLAGS ?= -O2 -std=c++11

.PHONY: all clean
all: $(TARGET)

$(TARGET): main.cu
	$(NVCC) $(NVCCFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

clean:
	rm -f $(TARGET)
