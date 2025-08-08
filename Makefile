SHELL=/bin/bash
.SUFFIXES:
default:

.PHONY: create-labs

STUDENT_EDITABLE_FILES= config.make
PRIVATE_FILES=Assignment.key.ipynb admin .git solution bad-solution

COMPILER=$(CXX) 
MICROBENCH_OPTIMIZE= -DHAVE_LINUX_PERF_EVENT_H -I$(PWD) -g $(C_OPTS)
LIBS= -lm -pthread -lboost_program_options -L/usr/lib/ -lboost_system -ldl
BUILD=build/

OPTIMIZE+=-march=x86-64
COMPILER=g++-9
include config.make


.PRECIOUS: $(BUILD)%.cpp
.PRECIOUS: $(BUILD)%.hpp

$(BUILD)perfstats.o: perfstats.c perfstats.h
	mkdir -p $(BUILD) 
	cp  $< $(BUILD)$<
	$(COMPILER) -DHAVE_LINUX_PERF_EVENT_H -O3 -I$(PWD) $(LIBS) -o $(BUILD)perfstats.o -c $(BUILD)perfstats.c


$(BUILD)%.s: $(BUILD)%.cpp
	mkdir -p $(BUILD) 
#	cp  $< $(BUILD)$<
	$(COMPILER) $(MICROBENCH_OPTIMIZE) $(LIBS) -S $(BUILD)$*.cpp

$(BUILD)%.so: $(BUILD)%.cpp
	mkdir -p $(BUILD) 
	cp *.hpp $(BUILD)
	cp *.h   $(BUILD)
	$(COMPILER)  -DHAVE_LINUX_PERF_EVENT_H $(MICROBENCH_OPTIMIZE) $(LIBS) -rdynamic -fPIC -shared -o $(BUILD)$*.so $(BUILD)$*.cpp
#	$(COMPILER) $(MICROBENCH_OPTIMIZE) $(LIBS) -c -fPIC -o $(BUILD)$*.o $(BUILD)$*.cpp

$(BUILD)%.cpp: %.cpp
	cp $< $(BUILD)
	cp *.hpp $(BUILD)

join.exe: $(BUILD)join_main.o  $(BUILD)join.o $(BUILD)perfstats.o
	$(COMPILER) $(join_OPTIMIZE) $(BUILD)join_main.o  $(BUILD)perfstats.o $(BUILD)join.o -o join.exe

$(BUILD)run_tests.o : OPTIMIZE=-O3

$(BUILD)%.o: %.cpp
	mkdir -p $(BUILD) 
	cp  $< $(BUILD)$<
	$(COMPILER)  -DHAVE_LINUX_PERF_EVENT_H $(MICROBENCH_OPTIMIZE) $(LIBS) -o $(BUILD)$*.o -c $(BUILD)$*.cpp

$(BUILD)join.o : OPTIMIZE=$(join_OPTIMIZE)
$(BUILD)join.s : OPTIMIZE=$(join_OPTIMIZE)
$(BUILD)join_main.o : OPTIMIZE=$(join_OPTIMIZE)

fiddle.exe:  $(BUILD)fiddle.o $(FIDDLE_OBJS) $(BUILD)perfstats.o
	$(COMPILER) $(MICROBENCH_OPTIMIZE)  -DHAVE_LINUX_PERF_EVENT_H $(BUILD)fiddle.o $(BUILD)perfstats.o $(FIDDLE_OBJS) $(LIBS) -o fiddle.exe


#-include $(DJR_JOB_ROOT)/$(LAB_SUBMISSION_DIR)/config.make
clean: 
	rm -f *.exe $(BUILD)*
