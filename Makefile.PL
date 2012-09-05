use inc::Module::Install;
name 'Acme-Suspender';
all_from 'lib/Acme/Suspender.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
