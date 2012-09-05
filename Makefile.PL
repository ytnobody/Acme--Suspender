use inc::Module::Install;
name 'Acme-Suspender';
all_from 'lib/Acme/Suspender.pm';

requires 'Class::Accessor::Fast';

requires 'Carp';
requires 'Furl';
requires 'JSON';
requires 'Try::Tiny';
requires 'URI';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
