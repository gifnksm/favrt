BUILD := debug

SRC_ROOT=src
OBJ_ROOT=obj
BIN_ROOT=bin

SRCDIR=$(SRC_ROOT)
OBJDIR=$(OBJ_ROOT)/$(BUILD)
BINDIR=$(BIN_ROOT)/$(BUILD)

TARGET_NAME=favrt
SRC=$(addprefix $(SRCDIR)/,main.d config.d path.d)
OBJ=${patsubst $(SRCDIR)/%.d,$(OBJDIR)/%.o,$(SRC)}
TARGET=$(BINDIR)/$(TARGET_NAME)

DFLAGS=-property -w -wi -I$(SRCDIR)
DFLAGS.debug=-debug -g
DFLAGS.release=-release -inline -O
DFLAGS.unittest=$(DFLAGS.debug) -unittest -cov
DFLAGS+=$(DFLAGS.$(BUILD))

LDFLAGS=-L-lxml2

.PHONY: debug
debug:
	make BUILD=debug all-build

.PHONY: release
release:
	make BUILD=release all-build

.PHONY: unittest
unittest:
	make BUILD=unittest all-build
	$(BIN_ROOT)/unittest/$(TARGET_NAME)

all: debug release unittest
all-build: $(TARGET)

compile-build: $(OBJ)

$(BINDIR)/$(TARGET_NAME): $(OBJ)
	dmd $(OBJ) $(DFLAGS) $(LDFLAGS) -of$@

$(OBJDIR)/%.o: $(SRCDIR)/%.d
	dmd $< $(DFLAGS) -c -od$(OBJDIR)

.PHONY: clean
clean:
	make BUILD=debug clean-build
	make BUILD=release clean-build
	make BUILD=unittest clean-build

.PHONY: clean-build
clean-build:
	$(RM) $(OBJ)

