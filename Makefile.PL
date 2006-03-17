# vi:set syntax=perl:

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'SQLlite::Easy',
    'VERSION_FROM'	=> 'Easy.pm',
    'PREREQ_PM'     => { DBI => 0, 'DBD::SQLiute' => 0 },
);
