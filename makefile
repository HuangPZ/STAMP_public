############################## Makefile parameters ######################################
# RUN_TYPE {localhost, LAN or WAN} 
RUN_TYPE := localhost
# NETWORK {SecureML, Sarda, MiniONN, LeNet, AlexNet, and VGG16}
NETWORK := ALL
# Dataset {MNIST, CIFAR10, and ImageNet}
DATASET	:= ALL
# Security {Semi-honest or Malicious} 
SECURITY:= Semi-honest
# CUDA
USE_CUDA := 1
ifeq ($(USE_CUDA), 1)
INC_CUDA=-I '/usr/local/cuda/include' -lcudart -L/usr/local/cuda/lib64 #-I '/usr/include/thrust/system/cuda' -lcudart -L/usr/lib/cuda
NVCC=//usr/local/cuda/bin/nvcc #/usr/local/cuda/bin/nvcc #or any other path of nvcc
NVCC_OPT=-std=c++11 -arch sm_60
endif
#########################################################################################




#########################################################################################
CXX=g++
SRC_CPP_FILES     := $(wildcard src/*.cpp)
SRC_CU_FILES      := $(wildcard src/*.cu)
OBJ_CPP_FILES     := $(wildcard util/*.cpp)
OBJ_FILES    	  := $(patsubst src/%.cpp, src/%.o,$(SRC_CPP_FILES))
ifeq ($(USE_CUDA), 1)
OBJ_FILES    	  += $(patsubst src/%.cu, src/%.o_cu,$(SRC_CU_FILES))
endif
OBJ_FILES    	  += $(patsubst util/%.cpp, util/%.o,$(OBJ_CPP_FILES))
HEADER_FILES       = $(wildcard src/*.h)

# FLAGS := -static -g -O0 -w -std=c++11 -pthread -msse4.1 -maes -msse2 -mpclmul -fpermissive -fpic
FLAGS := -O3 -w -std=c++11 -pthread -msse4.1 -maes -msse2 -mpclmul -fpic
LIBS := -lcrypto -lssl -lzmq
OBJ_INCLUDES := -I 'lib_eigen/' -I 'util/Miracl/' -I 'util/' -I '$(OPEN_SSL_LOC)/include/' 
ifeq ($(USE_CUDA), 1)
OBJ_INCLUDES += $(INC_CUDA) 
endif
BMR_INCLUDES := -L./ -L$(OPEN_SSL_LOC)/lib/ $(OBJ_INCLUDES) 


help: ## Run make or make help to see list of options
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: STAMP.out ## Just compile the code

STAMP.out: $(OBJ_FILES)
	g++ $(FLAGS) -o $@ $(OBJ_FILES) $(BMR_INCLUDES) $(LIBS)
	
%.o: %.cpp $(HEADER_FILES)
	$(CXX) $(FLAGS) -c $< -o $@ $(OBJ_INCLUDES)
ifeq ($(USE_CUDA), 1)
%.o_cu: %.cu $(HEADER_FILES)
	$(NVCC) $(NVCC_OPT)  -c $< -o $@ $(BMR_INCLUDES)
endif
clean: ## Run this to clean all files
	rm -rf STAMP.out
	rm -rf src/*.o src/*.o_cu util/*.o

################################# Remote runs ##########################################
terminal: STAMP.out ## Run this to print the output of (only) Party 0 to terminal
	./STAMP.out 2 files/IP_$(RUN_TYPE) files/keyC files/keyAC files/keyBC >/dev/null &
	./STAMP.out 1 files/IP_$(RUN_TYPE) files/keyB files/keyBC files/keyAB >/dev/null &
	./STAMP.out 0 files/IP_$(RUN_TYPE) files/keyA files/keyAB files/keyAC 
	@echo "Execution completed"

file: STAMP.out ## Run this to append the output of (only) Party 0 to file output/3PC.txt
	mkdir -p output
	./STAMP.out 2 files/IP_$(RUN_TYPE) files/keyC files/keyAC files/keyBC >/dev/null &
	./STAMP.out 1 files/IP_$(RUN_TYPE) files/keyB files/keyBC files/keyAB >/dev/null &
	./STAMP.out 0 files/IP_$(RUN_TYPE) files/keyA files/keyAB files/keyAC >>output/3PC.txt
	@echo "Execution completed"

valg: STAMP.out ## Run this to execute (only) Party 0 using valgrind. Change FLAGS to -O0.
	./STAMP.out 2 files/IP_$(RUN_TYPE) files/keyC files/keyAC files/keyBC >/dev/null &
	./STAMP.out 1 files/IP_$(RUN_TYPE) files/keyB files/keyBC files/keyAB >/dev/null &
	valgrind --tool=memcheck --leak-check=full --track-origins=yes --dsymutil=yes ./STAMP.out 0 files/IP_$(RUN_TYPE) files/keyA files/keyAB files/keyAC

command: STAMP.out ## Run this to use the run parameters specified in the makefile. 
	./STAMP.out 2 files/IP_$(RUN_TYPE) files/keyC files/keyAC files/keyBC $(NETWORK) $(DATASET) $(SECURITY) >/dev/null &
	./STAMP.out 1 files/IP_$(RUN_TYPE) files/keyB files/keyBC files/keyAB $(NETWORK) $(DATASET) $(SECURITY) >/dev/null &
	./STAMP.out 0 files/IP_$(RUN_TYPE) files/keyA files/keyAB files/keyAC $(NETWORK) $(DATASET) $(SECURITY) 
	@echo "Execution completed"


################################## tmux runs ############################################
zero: STAMP.out ## Run this to only execute Party 0 (useful for multiple terminal runs)
	./STAMP.out 0 files/IP_$(RUN_TYPE) files/keyA files/keyAB files/keyAC 

one: STAMP.out ## Run this to only execute Party 1 (useful for multiple terminal runs)
	./STAMP.out 1 files/IP_$(RUN_TYPE) files/keyB files/keyBC files/keyAB

two: STAMP.out ## Run this to only execute Party 2 (useful for multiple terminal runs)
	./STAMP.out 2 files/IP_$(RUN_TYPE) files/keyC files/keyAC files/keyBC
#########################################################################################

.PHONY: help

