#!/usr/bin/perl
use lib qw(../..);

my @array = qw(
47 49 46 38 39 61 01 00 01 00 F7 00 00 00 00 00 00 00 55 00 00 AA 00 00 FF
00 24 00 00 24 55 00 24 AA 00 24 FF 00 49 00 00 49 55 00 49 AA 00 49 FF 00
6D 00 00 6D 55 00 6D AA 00 6D FF 00 92 00 00 92 55 00 92 AA 00 92 FF 00 B6
00 00 B6 55 00 B6 AA 00 B6 FF 00 DB 00 00 DB 55 00 DB AA 00 DB FF 00 FF 00
00 FF 55 00 FF AA 00 FF FF 24 00 00 24 00 55 24 00 AA 24 00 FF 24 24 00 24
24 55 24 24 AA 24 24 FF 24 49 00 24 49 55 24 49 AA 24 49 FF 24 6D 00 24 6D
55 24 6D AA 24 6D FF 24 92 00 24 92 55 24 92 AA 24 92 FF 24 B6 00 24 B6 55
24 B6 AA 24 B6 FF 24 DB 00 24 DB 55 24 DB AA 24 DB FF 24 FF 00 24 FF 55 24
FF AA 24 FF FF 49 00 00 49 00 55 49 00 AA 49 00 FF 49 24 00 49 24 55 49 24
AA 49 24 FF 49 49 00 49 49 55 49 49 AA 49 49 FF 49 6D 00 49 6D 55 49 6D AA
49 6D FF 49 92 00 49 92 55 49 92 AA 49 92 FF 49 B6 00 49 B6 55 49 B6 AA 49
B6 FF 49 DB 00 49 DB 55 49 DB AA 49 DB FF 49 FF 00 49 FF 55 49 FF AA 49 FF
FF 6D 00 00 6D 00 55 6D 00 AA 6D 00 FF 6D 24 00 6D 24 55 6D 24 AA 6D 24 FF
6D 49 00 6D 49 55 6D 49 AA 6D 49 FF 6D 6D 00 6D 6D 55 6D 6D AA 6D 6D FF 6D
92 00 6D 92 55 6D 92 AA 6D 92 FF 6D B6 00 6D B6 55 6D B6 AA 6D B6 FF 6D DB
00 6D DB 55 6D DB AA 6D DB FF 6D FF 00 6D FF 55 6D FF AA 6D FF FF 92 00 00
92 00 55 92 00 AA 92 00 FF 92 24 00 92 24 55 92 24 AA 92 24 FF 92 49 00 92
49 55 92 49 AA 92 49 FF 92 6D 00 92 6D 55 92 6D AA 92 6D FF 92 92 00 92 92
55 92 92 AA 92 92 FF 92 B6 00 92 B6 55 92 B6 AA 92 B6 FF 92 DB 00 92 DB 55
92 DB AA 92 DB FF 92 FF 00 92 FF 55 92 FF AA 92 FF FF B6 00 00 B6 00 55 B6
00 AA B6 00 FF B6 24 00 B6 24 55 B6 24 AA B6 24 FF B6 49 00 B6 49 55 B6 49
AA B6 49 FF B6 6D 00 B6 6D 55 B6 6D AA B6 6D FF B6 92 00 B6 92 55 B6 92 AA
B6 92 FF B6 B6 00 B6 B6 55 B6 B6 AA B6 B6 FF B6 DB 00 B6 DB 55 B6 DB AA B6
DB FF B6 FF 00 B6 FF 55 B6 FF AA B6 FF FF DB 00 00 DB 00 55 DB 00 AA DB 00
FF DB 24 00 DB 24 55 DB 24 AA DB 24 FF DB 49 00 DB 49 55 DB 49 AA DB 49 FF
DB 6D 00 DB 6D 55 DB 6D AA DB 6D FF DB 92 00 DB 92 55 DB 92 AA DB 92 FF DB
B6 00 DB B6 55 DB B6 AA DB B6 FF DB DB 00 DB DB 55 DB DB AA DB DB FF DB FF
00 DB FF 55 DB FF AA DB FF FF FF 00 00 FF 00 55 FF 00 AA FF 00 FF FF 24 00
FF 24 55 FF 24 AA FF 24 FF FF 49 00 FF 49 55 FF 49 AA FF 49 FF FF 6D 00 FF
6D 55 FF 6D AA FF 6D FF FF 92 00 FF 92 55 FF 92 AA FF 92 FF FF B6 00 FF B6
55 FF B6 AA FF B6 FF FF DB 00 FF DB 55 FF DB AA FF DB FF FF FF 00 FF FF 55
FF FF AA FF FF FF 21 F9 04 01 00 00 FF 00 2C 00 00 00 00 01 00 01 00 40 08
04 00 FF 05 04 00 3B);

print "Content-type: image/gif\n\n";
binmode STDOUT;
my $buffer = pack("C*", map { hex($_); } @array);
print $buffer;

