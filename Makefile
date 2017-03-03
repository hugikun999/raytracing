EXEC = raytracing 
EXEC_THREAD = raytracing_thread

GIT_HOOKS := .git/hooks/pre-commit
.PHONY: all
all: $(GIT_HOOKS) $(EXEC) $(EXEC_THREAD)

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

CC ?= gcc
CFLAGS = \
	-std=gnu99 -Wall -O0 -g
LDFLAGS = \
	-lm

ifeq ($(strip $(PROFILE)),1)
PROF_FLAGS = -pg
CFLAGS += $(PROF_FLAGS)
LDFLAGS += $(PROF_FLAGS) 
endif

OBJS := \
	raytracing.o \
	main.o

OBJS_THREAD := raytracing_thread.o main_thread.o

OBJS_COMMON := objects.o

%.o: %.c
	$(CC) $(CFLAGS) -lpthread -c -o $@ $<


$(EXEC): $(OBJS) $(OBJS_COMMON)
	$(CC) -o $@ $^ $(LDFLAGS) -lpthread; \
	rm -rf $(OBJS)

$(EXEC_THREAD): $(OBJS_THREAD) $(OBJS_COMMON)
	$(CC) -o $@ $^ $(LDFLAGS) -lpthread; \
	rm -rf $(OBJS_THREAD)

main.o: use-models.h
main_thread.o: use-models.h
use-models.h: models.inc Makefile
	@echo '#include "models.inc"' > use-models.h
	@egrep "^(light|sphere|rectangular) " models.inc | \
	    sed -e 's/^light /append_light/g' \
	        -e 's/light[0-9]/(\&&, \&lights);/g' \
	        -e 's/^sphere /append_sphere/g' \
	        -e 's/sphere[0-9]/(\&&, \&spheres);/g' \
	        -e 's/^rectangular /append_rectangular/g' \
	        -e 's/rectangular[0-9]/(\&&, \&rectangulars);/g' \
	        -e 's/ = {//g' >> use-models.h

check: $(EXEC)
	@./$(EXEC) && diff -u baseline.ppm out.ppm || (echo Fail; exit)
	@echo "Verified OK"

check_thread: $(EXEC_THREAD)
	@./$(EXEC_THREAD) 4 && diff -u baseline.ppm out.ppm || (echo Fail; exit)
	@echo "Verified OK"

profile: 
	make PROFILE=1

graph: check
	convert out.ppm out.png
	eog out.png

graph_thread: check_thread
	convert out.ppm out.png
	eog out.png

test: $(EXCE_THREAD)
	for i in `seq 1 1 16`; \
	do \
	perf stat --repeat 10 -e cache-misses,instructions,cycles  ./raytracing_thread $$i; \
	done

clean:
	$(RM) $(EXEC) $(OBJS) $(EXEC_THREAD) $(OBJS_THREAD) use-models.h \
		out.ppm gmon.out out.png
