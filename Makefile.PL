
use strict;
use ExtUtils::MakeMaker;
use Alien::SDL;


my $lib      = 'betweener';
my $test     = 'betweener_unit_tests';
my $cpp_path = 'src/cpp';
my $lib_ar   = "$cpp_path/lib$lib\$(LIB_EXT)";
my $cc       = 'g++';

WriteMakefile(
    NAME              => 'SDLx::Betweener',
    VERSION_FROM      => 'lib/SDLx/Betweener.pm',
    PREREQ_PM         => {
        'Alien::SDL' => '1.430',
        'SDL'        => '2.536',
        'Moose'      => '2.0402',
    },
    CC                => $cc,
    LD                => '$(CC)',
    ($] >= 5.005 ?
      (ABSTRACT  => 'SDL Perl XS Tweening Animation Library',
       AUTHOR         => 'eilara <ran.eilam@gmail.com>') : ()),
    LIBS              => Alien::SDL->config('libs', '-lm'),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => Alien::SDL->config('cflags'). ' -I. -Isrc/cpp -Isrc/cpp_xs',
    OBJECT            => '$(O_FILES)',
    'MYEXTLIB'        => $lib_ar,
#    clean   => {'FILES' => ''},
);


sub MY::postamble {
'
$(MYEXTLIB): src/Makefile
	cd src && $(MAKE) $(PASSTHRU)
';
}
