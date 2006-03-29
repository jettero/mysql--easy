# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'DBI::Easy',
    'VERSION_FROM' => 'Easy.pm',
    'PREREQ_PM'    => { DBI => 0, 'DBD::SQLite' => 0, 'DBD::mysql' => 0 },
);
