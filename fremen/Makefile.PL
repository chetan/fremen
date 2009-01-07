use inc::Module::Install;

name     'Fremen';
all_from 'lib/Fremen.pm';
author   'Chetan Sarva <chetan@pixelcop.net>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

