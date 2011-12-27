/* This file is part of punani-strike
 * Copyright (c) 2011 Gianni Tedesco
 * Released under the terms of GPLv3
*/
#include <punani/punani.h>
#include <punani/renderer.h>
#include <punani/tex.h>
#include <punani/map.h>
#include <punani/blob.h>

#include "mapfile.h"

struct _map {
	texture_t tiles;
	unsigned int tiles_per_row;
	struct mapfile_hdr *hdr;
	const uint16_t *rmap;
	size_t sz;
};

/* map screen size/coords to tile coords in map space */
static void screen2map(map_t map, SDL_Rect *scr, SDL_Rect *m) 
{
	m->x = (scr->x / map->hdr->tile_width);
	m->y = (scr->y / map->hdr->tile_height);
	m->w = (scr->w / map->hdr->tile_width) + 1;
	m->h = (scr->h / map->hdr->tile_height) + 1;
}

/* map a tile in to the screen space */
static void tile2screen(map_t map, unsigned int x, unsigned int y,
			SDL_Rect *scr, SDL_Rect *dst)
{
	unsigned int xc, yc;

	/* figure out top left pixel of this tile */
	xc = x * map->hdr->tile_width;
	yc = y * map->hdr->tile_height;

	/* subtract map render origin */
	dst->x = xc - scr->x;
	dst->y = yc - scr->y;

}

/* get a source tile by its ID */
static void src_tile(map_t map, uint16_t id, SDL_Rect *src)
{
	unsigned int tx, ty;

	tx = id % map->tiles_per_row;
	ty = id / map->tiles_per_row;

	src->x = tx * map->hdr->tile_width;
	src->y = ty * map->hdr->tile_height;
}

void map_render(map_t map, renderer_t r, SDL_Rect *scr)
{
	unsigned int x, y;
	SDL_Rect src, dst, m;

	screen2map(map, scr, &m);

	/* invariants */
	src.w = map->hdr->tile_width;
	src.h = map->hdr->tile_height;
	dst.w = map->hdr->tile_width;
	dst.h = map->hdr->tile_height;

	for(y = m.y; y < (unsigned)(m.y + m.h); y++) {
		for(x = m.x; x < (unsigned)(m.x + m.w); x++) {
			uint16_t id;

			id = map->rmap[x * map->hdr->ytiles + y];
			
			src_tile(map, id, &src);

			tile2screen(map, x, y, scr, &dst);

			renderer_blit(r, map->tiles, &src, &dst);
		}
	}
}

void map_get_size(map_t map, unsigned int *x, unsigned int *y)
{
	if ( x )
		*x = map->hdr->xtiles * map->hdr->tile_width;
	if ( y )
		*y = map->hdr->ytiles * map->hdr->tile_height;
}

static int sanity_check(struct _map *map)
{
	if ( map->sz < sizeof(*map->hdr) )
		return 0;
	if ( map->hdr->magic != MAPFILE_MAGIC )
		return 0;
	if ( (sizeof(*map->hdr) + (map->hdr->xtiles * 
					map->hdr->ytiles *
					sizeof(uint16_t))) < map->sz )
		return 0;

	return 1;
}

map_t map_load(const char *name)
{
	struct _map *map = NULL;
	char fn[512];
	uint8_t *buf;

	map = calloc(1, sizeof(*map));
	if ( NULL == map )
		goto out;

	buf = blob_from_file(name, &map->sz);
	if ( NULL == buf )
		goto out_free;

	map->hdr = (struct mapfile_hdr *)buf;
	map->rmap = (uint16_t *)(buf + sizeof(*map->hdr));
	if ( !sanity_check(map) )
		goto out_free_blob;

	snprintf(fn, sizeof(fn), "data/tiles/%s", map->hdr->tilemap);
	map->tiles = png_get_by_name(fn, 0);
	if ( NULL == map->tiles )
		goto out_free_blob;

	map->tiles_per_row = texture_width(map->tiles) / map->hdr->tile_width;

	/* success */
	goto out;
out_free_blob:
	blob_free((uint8_t *)map->hdr, map->sz);
out_free:
	free(map);
	map = NULL;
out:
	return map;
}

void map_free(map_t map)
{
	if ( map ) {
		blob_free((uint8_t *)map->hdr, map->sz);
		texture_put(map->tiles);
		free(map);
	}
}