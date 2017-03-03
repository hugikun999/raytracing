#ifndef __RAYTRACING_H
#define __RAYTRACING_H

#include "objects.h"
#include "primitives.h"
#include <stdint.h>

void raytracing(void *data);

typedef struct Pthread_Data {
    uint8_t *pixels;
    color background_color;
    rectangular_node rectangulars;
    sphere_node spheres;
    light_node lights;
    const viewpoint *view;
    int width;
    int height;
    int thread_num;
    int partition;
} pthread_data;

pthread_data *data_init(uint8_t *pixels, color background_color,
                        rectangular_node rectangulars, sphere_node spheres,
                        light_node lights, const viewpoint *view, int rows, int cols, int thread_num, int partition);

#endif
