CC := mpicc
SRCDIR := src
BUILDDIR := build
TARGET := bin/mpi-knn

SRCEXT := c
SOURCES := $(shell find $(SRCDIR) -type f -name *.$(SRCEXT))
OBJECTS := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.o))
CFLAGS := -O3 -g -Wall# -static# -Wall -Wextra -v -da -Q
LIB := -lm#-lpthread -fopenmp -lcilkrts# -fbuiltin
INC := -I include -lm#-fopenmp -fcilkplus -I include

$(TARGET): $(OBJECTS)
	  @echo " Linking..."
	  @echo " $(CC) $^ -o $(TARGET) $(LIB)"; $(CC) $^ -o $(TARGET) $(LIB)

$(BUILDDIR)/%.o: $(SRCDIR)/%.$(SRCEXT)
	  @mkdir -p $(BUILDDIR)
	  @echo " $(CC) $(CFLAGS) $(INC) -c -o $@ $<"; $(CC) $(CFLAGS) $(INC) -c -o $@ $<

clean:
	  @echo " Cleaning...";
	  @echo " $(RM) -r $(BUILDDIR)/*.o $(TARGET)"; $(RM) -r $(BUILDDIR)/*.o $(TARGET)
