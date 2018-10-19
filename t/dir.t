#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile tempdir/;
use File::Basename;

use Errno qw/ENOENT EBADF/;

use Test::MockFile;    # Everything below this can have its open overridden.

my $temp_dir = tempdir( CLEANUP => 1 );
my ( undef, $filename ) = tempfile( DIR => $temp_dir );

note "-------------- REAL MODE --------------";
is( -d $temp_dir, 1, "Temp is created on disk." );
is( opendir( my $dir_fh, $temp_dir ), 1, "$temp_dir can be read" );
like( scalar readdir $dir_fh, qr/\.\.?/,  "Read . or .. from readdir" );
like( scalar readdir $dir_fh, qr/\.\.?/, "Read . or .. from readdir" );
my $base = basename $filename;
is( scalar readdir $dir_fh, $base, "Read $base from readdir" );
is( scalar readdir $dir_fh, undef, "undef when nothing left from readdir." );
my ( undef, $f2 ) = tempfile( DIR => $temp_dir );
$base = basename $f2;
ok( -e $f2, "File 2 ($f2) exists but...." );
is( scalar readdir $dir_fh, undef, "readdir doesn't see it since it's there after the opendir." );
is( closedir $dir_fh,       1,     "close the fake dir handle" );

like( warning { readdir($dir_fh) }, qr/^readdir\(\) attempted on invalid dirhandle \S+ /, "warn on readdir when file handle is closed." );

is( opendir( my $bad_fh, "/not/a/valid/path/kdshjfkjd" ), undef, "opendir on a bad path returns false" );
is( $! + 0, ENOENT, '$! numeric is right.' );
is( $!, "No such file or directory", '$! text is right.' );

like( dies { readdir("abc"); }, qr/^Bad symbol for dirhandle at/, "Dies if string passed instead of dir fh" );

my ( $real_fh, $f3 ) = tempfile( DIR => $temp_dir );
like( warning { readdir($real_fh) }, qr/^readdir\(\) attempted on invalid dirhandle \$fh/, "We only warn if the file handle or glob is invalid." );

note "-------------- MOCK MODE --------------";
my $bar = Test::MockFile->dir( $temp_dir, [qw/. .. abc def/] );

is( opendir( $dir_fh, $temp_dir ), 1, "Mocked temp dir opens and returns true" );
is( scalar readdir $dir_fh, ".",   "Read .  from fake readdir" );
is( scalar readdir $dir_fh, "..",  "Read .. from fake readdir" );
is( telldir $dir_fh,        2,     "tell dir in the middle of fake readdir is right." );
is( scalar readdir $dir_fh, "abc", "Read abc from fake readdir" );
is( scalar readdir $dir_fh, "def", "Read def from fake readdir" );
is( telldir $dir_fh,        4,     "tell dir at the end of fake readdir is right." );
is( scalar readdir $dir_fh, undef, "Read from fake readdir but no more in the list." );
is( scalar readdir $dir_fh, undef, "Read from fake readdir but no more in the list." );
is( scalar readdir $dir_fh, undef, "Read from fake readdir but no more in the list." );
is( scalar readdir $dir_fh, undef, "Read from fake readdir but no more in the list." );

is( rewinddir($dir_fh), 1, "rewinddir returns true." );
is( telldir $dir_fh,    0, "telldir afer rewinddir is right." );
is( [ readdir $dir_fh ], [qw/. .. abc def/], "Read the whole dir from fake readdir after rewinddir" );
is( telldir $dir_fh, 4, "tell dir at the end of fake readdir is right." );
is( seekdir( $dir_fh, 1 ), 1, "seekdir returns where it sought." );
is( [ readdir $dir_fh ], [qw/.. abc def/], "Read the whole dir from fake readdir after seekdir" );
closedir($dir_fh);

done_testing();
exit;
