# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'DBI::Easy::SQLite',
    'VERSION_FROM' => 'SQLite.pm',
    'PREREQ_PM'    => { DBI => 0, 'DBD::SQLite' => 0 },
);
