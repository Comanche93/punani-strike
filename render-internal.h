/* This file is part of punani-strike
 * Copyright (c) 2011 Gianni Tedesco
 * Released under the terms of GPLv3
*/
#ifndef _RENDERER_INTERNAL_H
#define _RENDERER_INTERNAL_H

struct render_ops {
	void (*blit)(void *priv, texture_t tex, SDL_Rect *src, SDL_Rect *dst);
	void (*size)(void *priv, unsigned int *x, unsigned int *y);
	void (*exit)(void *priv, int code);
};

struct _renderer {
	const struct render_ops *ops;
	void *priv;
};

#endif /* _RENDERER_INTERNAL_H */