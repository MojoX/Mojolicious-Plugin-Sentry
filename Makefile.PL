use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::Sentry',
    VERSION_FROM => 'lib/Mojolicious/Plugin/Sentry.pm',
    ABSTRACT     => 'Error Tracking Plugin for Mojolicious',
    AUTHOR       => 'Kostya Ten <kostya@cpan.org>',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.010001'}}},
        resources      => {
            bugtracker => {web => 'https://github.com/MojoX/Mojolicious-Plugin-Sentry/issues'},
            license    => ['https://opensource.org/licenses/Apache-2.0'],
            repository => {
                type => 'git',
                url  => 'https://github.com/MojoX/Mojolicious-Plugin-Sentry.git',
                web  => 'https://github.com/MojoX/Mojolicious-Plugin-Sentry',
            },
        },
    },
    PREREQ_PM => {
        'Mojolicious' => '7.59',
        'UUID::Tiny' => '1.04',
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);
