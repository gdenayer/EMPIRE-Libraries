# Generic Makefile for C++ C and Fortran projects
#Features:
#- Generic: No adoption necessary for changing source files
#- Configurable location of src and object files
#- Automatic intelligent dependency generation (only C and C++)
#- Separation of build configuration and makefile
#- Support different tool chains
#- Support for multiple build configurations
#- Multiple builds in the same directory
#- Automatic folder management in source code folder up to one layer
#Problems:
# There are certain scenarios with renaming files which can cause errors.
# Still a fix is not trivial and I wanted to keep things simple. After
# renaming of files a make clean && make  fixes the problem.
#
# Stefan Sicklinger stefan.sicklinger@tum.de




#This can be changed as a command line argument e.g. make TAG=GCC (DEFAULT is ICC)
TAG ?= ICC

##CONFIGURE BUILD SYSTEM
STATICLIB     = libempire_thirdparty.a
DYNAMICLIB    = libempire_thirdparty.so
BUILD_DIR  = ./$(TAG)
EXE_DIR    = ./bin$(TAG)
SRC_DIR_MAIN   = ./src
MAKE_DIR   = ./
HEADER_DIR = include
TMP        = 0
#Set Q only if it is not already set by the command line
Q         ?= @

#Create folder structure for mkdir
SRC_DIR   := $(SRC_DIR_MAIN)
SUB_DIR   := $(patsubst $(SRC_DIR)%,%,${shell find ${SRC_DIR} -type d -print})
SUB_DIR   := $(patsubst /%,%,$(SUB_DIR))
SUB_DIR   := $(patsubst $(HEADER_DIR),,$(SUB_DIR))
##DO NOT EDIT BELOW
#Include tool chain specific file 
include $(MAKE_DIR)/include_$(TAG).mk
#Include all header files in here in order to be able to use #include < >
INCLUDES  += -I $(SRC_DIR)/$(HEADER_DIR)

#Construct search path for all prerequisites (VPATH)
VPATH     = $(SRC_DIR)
#Generate ASM file names from source code
#Hint you can use also the GNU binutils (objdump, readelf) to deassemble
ASM  = $(patsubst $(SRC_DIR_MAIN)/%.c, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR_MAIN)/*.c))
ASM += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.c, $(BUILD_DIR)/$(var)/%.s,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.c)))
ASM += $(patsubst $(SRC_DIR_MAIN)/%.cc, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR_MAIN)/*.cc))
ASM += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.cc, $(BUILD_DIR)/$(var)/%.s,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.cc)))
ASM += $(patsubst $(SRC_DIR_MAIN)/%.cpp, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR_MAIN)/*.cpp))
ASM += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.cpp, $(BUILD_DIR)/$(var)/%.s,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.cpp)))
ASM += $(patsubst $(SRC_DIR_MAIN)/%.f90, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR_MAIN)/*.f90))
ASM += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.f90, $(BUILD_DIR)/$(var)/%.s,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.f90)))
#Generate object file names from source code
OBJ  = $(patsubst $(SRC_DIR_MAIN)/%.c, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR_MAIN)/*.c))
OBJ += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.c, $(BUILD_DIR)/$(var)/%.o,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.c)))
OBJ += $(patsubst $(SRC_DIR_MAIN)/%.cc, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR_MAIN)/*.cc))
OBJ += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.cc, $(BUILD_DIR)/$(var)/%.o,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.cc)))
OBJ += $(patsubst $(SRC_DIR_MAIN)/%.cpp, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR_MAIN)/*.cpp))
OBJ += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.cpp, $(BUILD_DIR)/$(var)/%.o,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.cpp)))
OBJ += $(patsubst $(SRC_DIR_MAIN)/%.f90, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR_MAIN)/*.f90))
OBJ += $(foreach var,$(SUB_DIR), $(patsubst $(SRC_DIR_MAIN)/$(var)/%.f90, $(BUILD_DIR)/$(var)/%.o,$(wildcard $(SRC_DIR_MAIN)/$(var)/*.f90)))



CPPFLAGS := $(CPPFLAGS) $(DEFINES) $(INCLUDES) 


staticlib: $(BUILD_DIR) $(OBJ) flann
	@echo "===>  CREATE STATIC LIBRARY  $(STATICLIB)"
	$(Q)ar rcs $(STATICLIB) $(OBJ)
	@mv $(STATICLIB) $(EXE_DIR)/$(STATICLIB)
	
dynamiclib: $(BUILD_DIR) $(OBJ)
	@echo "===>  CREATE DYNAMIC LIBRARY  $(DYNAMICLIB)"
	$(Q)${LINKER} ${LFLAGS} -shared -o $(DYNAMICLIB) $(OBJ)
	@mv $(DYNAMICLIB) $(EXE_DIR)/$(DYNAMICLIB)	
	
print:
	@echo "Print OBJ list: $(OBJ)"
	@echo "Print ASM list: $(ASM)"
	@echo "Print SUB_DIR list: $(SUB_DIR)"
	@echo "Print mkdir:"
	@$(foreach var,$(SUB_DIR), echo $(var);)

asm:  $(BUILD_DIR) $(ASM)

$(BUILD_DIR)/%.o:  %.c
	@echo "===>  COMPILE c  $@"
	$(Q)$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(Q)$(CC) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d

$(BUILD_DIR)/%.s:  %.c
	@echo "===>  GENERATE ASM c $@"
	$(Q)$(CC) -S $(CPPFLAGS) $(CFLAGS) $< -o $@


$(BUILD_DIR)/%.o:  %.cc
	@echo "===>  COMPILE cc $@"
	$(Q)$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(Q)$(CXX) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d
	
$(BUILD_DIR)/%.s:  %.cc
	@echo "===>  GENERATE ASM cc  $@"
	$(Q)$(CXX) -S $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	

$(BUILD_DIR)/%.o:  %.cpp
	@echo "===>  COMPILE cpp  $@"
	$(Q)$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(Q)$(CXX) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d
	
$(BUILD_DIR)/%.s:  %.cpp
	@echo "===>  GENERATE ASM cpp  $@"
	$(Q)$(CXX) -S $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	

$(BUILD_DIR)/%.o:  %.f90
	@echo "===>  COMPILE f90 $@"
	$(Q)$(FC) -c  $(FCFLAGS) $< -o $@
	
$(BUILD_DIR)/%.s:  %.f90
	@echo "===>  GENERATE ASM f90  $@"
	$(Q)$(FC) -S $(FCFLAGS) $< -o $@


tags:
	@echo "===>  GENERATE  TAGS"
	$(Q)ctags -R


$(BUILD_DIR):
	$(Q) mkdir $(BUILD_DIR)
	$(Q) mkdir $(EXE_DIR)
	$(Q) mkdir $(BUILD_DIR)/$(HEADER_DIR)
	@$(foreach var,$(SUB_DIR), mkdir $(BUILD_DIR)/$(var);)
	


ifeq ($(findstring $(MAKECMDGOALS),clean),)
-include $(OBJ:.o=.d)
endif

.PHONY: clean 


clean:
	@echo "===> CLEAN"
	@rm -rf $(EXE_DIR)
	@rm -rf $(BUILD_DIR)
	@rm -f tags
	
flann:
	@echo "===> MAKING FLANN"
	@$(MAKE) TAG=$(TAG) -s -C flann-1.7.1-src

nlopt:
	@echo "===> MAKING NLOPT"
	@$(MAKE) TAG=$(TAG) -s -C nlopt-2.4.1

clipper:
	@echo "===> MAKING CLIPPER"
	@$(MAKE) TAG=$(TAG) -s -C clipper_ver6.1.3a
	
## Some hints
#$@ The name of the target, which caused the rule to be processed.
#$< The name of the first prerequisite.
#$ˆ The names of all prerequisites separated by spaces.
#$? The names of all prerequisites, which are newer than the target, separated by spaces.
#More information on the science :-) of automatic dependency file generation can be found  here:
#http://www.cs.berkeley.edu/~smcpeak/autodepend/autodepend.html
#http://make.paulandlesley.org/autodep.html