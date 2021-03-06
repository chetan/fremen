use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              NAME         => 'Gearman::Server',
              VERSION_FROM => 'lib/Gearman/Server.pm',
              ABSTRACT_FROM => 'lib/Gearman/Server.pm',
              EXE_FILES    => ['gearmand'],
              PREREQ_PM    => {
                  'Gearman::Util' => 0,
                  'Danga::Socket' => 1.52,
              },
              AUTHOR       => 'Brad Fitzpatrick (brad@danga.com), Brad Whitaker (whitaker@danga.com)',
              );
