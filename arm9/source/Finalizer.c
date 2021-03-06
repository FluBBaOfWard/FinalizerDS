#include <nds.h>

#include "Finalizer.h"
#include "Gfx.h"
//#include "SN76496/SN76496.h"
#include "K005849/K005849.h"
#include "ARM6809/ARM6809.h"


int packState(void *statePtr) {
	int size = 0;
//	size += sn76496SaveState(statePtr+size, &sn76496_0);
	size += k005849SaveState(statePtr+size, &k005885_0);
	size += m6809SaveState(statePtr+size, &m6809OpTable);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
//	size += sn76496LoadState(&sn76496_0, statePtr+size);
	size += k005849LoadState(&k005885_0, statePtr+size);
	m6809LoadState(&m6809OpTable, statePtr+size);
}

int getStateSize() {
	int size = 0;
//	size += sn76496GetStateSize();
	size += k005849GetStateSize();
	size += m6809GetStateSize();
	return size;
}

static const ArcadeRom finalizrRoms[14] = {
	// ROM_REGION( 0x10000, "maincpu", 0 )
	{"523k01.9c",   0x4000, 0x716633cb},
	{"523k02.12c",  0x4000, 0x1bccc696},
	{"523k03.13c",  0x4000, 0xc48927c6},
	// ROM_REGION( 0x1000, "audiocpu", 0 ) /* 8039 */
	{"d8749hd.bin", 0x0800, 0x978dfc33},
	// ROM_REGION( 0x20000, "gfx1", 0 )
	{"523h04.5e",   0x4000, 0xc056d710},
	{"523h05.6e",   0x4000, 0xae0d0f76},
	{"523h06.7e",   0x4000, 0xd2db9689},
	{"523h07.5f",   0x4000, 0x50e512ba},
	{"523h08.6f",   0x4000, 0x79f44e17},
	{"523h09.7f",   0x4000, 0x8896dc85},
	/* 18000-1ffff empty */
	// ROM_REGION( 0x0240, "proms", 0 ) /* PROMs at 2F & 3F are MMI 63S081N (or compatibles), PROMs at 10F & 11F are MMI 6301-1N (or compatibles) */
	{"523h10.2f",   0x0020, 0xec15dd15},
	{"523h11.3f",   0x0020, 0x54be2e83},
	{"523h13.11f",  0x0100, 0x4e0647a0},
	{"523h12.10f",  0x0100, 0x53166a2a},
};

static const ArcadeRom finalizraRoms[14] = {
	// ROM_REGION( 0x10000, "maincpu", 0 )
	{"1.9c",        0x4000, 0x7d464e5c},
	{"2.12c",       0x4000, 0x383dc94e},
	{"3.13c",       0x4000, 0xce177f6e},
	// ROM_REGION( 0x1000, "audiocpu", 0 ) /* 8039 */
	{"d8749hd.bin", 0x0800, 0x978dfc33},
	// ROM_REGION( 0x20000, "gfx1", 0 )
	{"523h04.5e",   0x4000, 0xc056d710},
	{"523h05.6e",   0x4000, 0xae0d0f76},
	{"523h06.7e",   0x4000, 0xd2db9689},
	{"523h07.5f",   0x4000, 0x50e512ba},
	{"523h08.6f",   0x4000, 0x79f44e17},
	{"523h09.7f",   0x4000, 0x8896dc85},
	/* 18000-1ffff empty */
	// ROM_REGION( 0x0240, "proms", 0 ) /* PROMs at 2F & 3F are MMI 63S081N (or compatibles), PROMs at 10F & 11F are MMI 6301-1N (or compatibles) */
	{"523h10.2f",   0x0020, 0xec15dd15},
	{"523h11.3f",   0x0020, 0x54be2e83},
	{"523h13.11f",  0x0100, 0x4e0647a0},
	{"523h12.10f",  0x0100, 0x53166a2a},
};

static const ArcadeRom finalizrbRoms[13] = {
	// ROM_REGION( 0x10000, "maincpu", 0 )
	{"finalizr.5",  0x8000, 0xa55e3f14},
	{"finalizr.6",  0x4000, 0xce177f6e},
	// ROM_REGION( 0x1000, "audiocpu", 0 ) /* 8039 */
	{"d8749hd.bin", 0x0800, 0x978dfc33},
	// ROM_REGION( 0x20000, "gfx1", 0 )
	{"523h04.5e",   0x4000, 0xc056d710},
	{"523h05.6e",   0x4000, 0xae0d0f76},
	{"523h06.7e",   0x4000, 0xd2db9689},
	{"523h07.5f",   0x4000, 0x50e512ba},
	{"523h08.6f",   0x4000, 0x79f44e17},
	{"523h09.7f",   0x4000, 0x8896dc85},
	/* 18000-1ffff empty */
	// ROM_REGION( 0x0240, "proms", 0 ) /* PROMs at 2F & 3F are MMI 63S081N (or compatibles), PROMs at 10F & 11F are MMI 6301-1N (or compatibles) */
	{"523h10.2f",   0x0020, 0xec15dd15},
	{"523h11.3f",   0x0020, 0x54be2e83},
	{"523h13.11f",  0x0100, 0x4e0647a0},
	{"523h12.10f",  0x0100, 0x53166a2a},
};


const ArcadeGame games[GAME_COUNT] = {
	{"finalizr", "Finalizer - Super Transformation (set 1)", 14, finalizrRoms},
	{"finalizra", "Finalizer - Super Transformation (set 2)", 14, finalizraRoms},
	{"finalizrb", "Finalizer - Super Transformation (bootleg)", 13, finalizrbRoms},
};
