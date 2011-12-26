#ifndef _PUNANI_CHOPPER_H
#define _PUNANI_CHOPPER_H

typedef struct _chopper *chopper_t;

#define CHOPPER_THROTTLE	0
#define CHOPPER_BRAKE		1
#define CHOPPER_LEFT		2
#define CHOPPER_RIGHT		3

chopper_t chopper_apache(void);
chopper_t chopper_comanche(void);
void chopper_think(chopper_t chopper);
void chopper_render(chopper_t chopper, game_t g);
void chopper_control(chopper_t chopper, unsigned int ctrl, int down);
void chopper_free(chopper_t chopper);

#endif /* _PUNANI_CHOPPER_H */
