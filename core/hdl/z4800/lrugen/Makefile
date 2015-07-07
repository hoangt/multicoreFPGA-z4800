#Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License,
#version 2, as published by the Free Software Foundation.
#Other versions of the license may NOT be used without
#the written consent of the copyright holder(s).
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

CFLAGS := -std=gnu99 -g

all: lrugen lru.2way.mif lru.3way.mif lru.4way.mif lru.5way.mif

clean:
	rm -f lrugen lru.?way.mif

lrugen: lrugen.c
	$(CC) $(CFLAGS) -o $@ $<

lru.2way.mif: lrugen
	./lrugen 2 > $@

lru.3way.mif: lrugen
	./lrugen 3 > $@

lru.4way.mif: lrugen
	./lrugen 4 > $@

lru.5way.mif: lrugen
	./lrugen 5 > $@
