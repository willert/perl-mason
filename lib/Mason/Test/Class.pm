package Mason::Test::Class;
use Carp;
use File::Basename;
use File::Path;
use File::Slurp;
use File::Temp qw(tempdir);
use Mason::Interp;
use Test::Exception;
use Test::More;
use strict;
use warnings;
use base qw(Test::Class);

__PACKAGE__->SKIP_CLASS("abstract base class");

my $gen_path_count = 0;

sub _startup : Test(startup) {
    my $self = shift;
    $self->{temp_dir}  = tempdir( 'mason-test-XXXX', TMPDIR => 1, CLEANUP => 0 );
    $self->{comp_root} = $self->{temp_dir} . "/comps";
    $self->{data_dir}  = $self->{temp_dir} . "/data";
    mkpath( [ $self->{comp_root}, $self->{data_dir} ], 0, 0775 );

    $self->{interp} = Mason::Interp->new(
        comp_root => $self->{comp_root},
        data_dir  => $self->{data_dir},
    );
}

sub add_comp {
    my ( $self, %params ) = @_;

    my $path   = $params{path}      || die "must pass path";
    my $source = $params{component} || die "must pass component";
    my $source_file = join( "/", $self->{comp_root}, $path );
    mkpath_and_write_file( $source_file, $source );
}

sub remove_comp {
    my ( $self, %params ) = @_;

    my $path = $params{path} || die "must pass path";
    my $source_file = join( "/", $self->{comp_root}, $path );
    unlink($source_file);
}

sub test_comp {
    my ( $self, %params ) = @_;

    my $caller = ( caller(1) )[3];
    my ($caller_base) = ( $caller =~ /([^:]+)$/ );
    my $path         = $params{path} || ( "/$caller_base" . ( ++$gen_path_count ) );
    my $desc         = $params{desc};
    my $source       = $params{component} || croak "must pass component";
    my $expect       = $params{expect};
    my $expect_error = $params{expect_error};
    croak "must pass either expect or expect_error" unless $expect || $expect_error;

    $self->add_comp( path => $path, component => $source );
    if ($expect_error) {
        $desc ||= $expect_error;
        throws_ok( sub { $self->{interp}->srun($path) }, $expect_error, $desc );
    }
    else {
        $desc ||= $caller;
        is( $self->{interp}->srun($path), $expect, $desc );
    }
}

sub mkpath_and_write_file {
    my ( $source_file, $source ) = @_;

    mkpath( dirname($source_file), 0, 0775 );
    write_file( $source_file, $source );
}

1;
