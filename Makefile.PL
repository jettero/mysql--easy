# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'MySQL::Easy',
    'VERSION_FROM' => 'Easy.pm',
    'PREREQ_PM'    => { DBI => 0, 'DBD::mysql' => 0, version=>0 },
);
