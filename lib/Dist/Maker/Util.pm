package Dist::Maker::Util;
use strict;
use parent qw(Exporter);
use Carp ();

our @EXPORT = qw(
    slurp
    parse_options
    p

    mkpath
    rmtree
    usage

    save
);

sub slurp {
    my($file, $layer) = @_;
    open my $in, '<' . ($layer // ''), $file
        or Carp::croak("Cannot open '$file' to slurp: $!");
    local $/;
    return scalar <$in>;
}

sub parse_options {
    my($class, @args) = @_;

    my @spec         = $class->option_spec;
    my $pass_through = $class->pass_through;

    require Getopt::Long;
    my $old = Getopt::Long::Configure(
        "posix_default",
        "permute",        # the argument order doesn't matter
        "no_ignore_case",
        "bundling",
        ($pass_through ? "pass_through" : ()),
    );

    my %opts;
    my $success = Getopt::Long::GetOptionsFromArray(\@args, \%opts, @spec);

    Getopt::Long::Configure($old);

    if(!$pass_through and !$success) {
        usage();
        return;
    }
    return(\%opts, @args);
}

sub p {
    require Text::Xslate::Util;
    goto &Text::Xslate::Util::p;
}

sub mkpath {
    my($logger, @args) = @_;
    $logger->log("mkpath @args\n");
    require File::Path;
    File::Path::mkpath(\@args, $logger->verbose >= 5)
        or Carp::croak("Cannot mkpath(@args): $!");
}

sub rmtree {
    my($logger, @args) = @_;
   $logger->log("mktree @args\n");
    require File::Path;
    File::Path::rmtree(\@args, $logger->verbose >= 5);
}

sub save {
    my($logger, $file, $content) = @_;

    my $tmp = "$file.tmp";
    open my $fh, '>', $tmp
        or return $logger->diag("Cannot open '$tmp' for writing: $!\n");

    print $fh $content;

    close $fh or return $logger->diag("Cannot close '$tmp' in writing: $!\n");

    my $original_exists = -e $file;
    if($original_exists) {
        rename $file => "$file~" or $logger->diag("Cannot rename '$file': $!\n");
    }

    if(not rename $tmp => $file) {
        $logger->diag("Cannot rename '$tmp': $!\n");
        rename "$file~" => $file if $original_exists;
        return $logger->diag("Cannot save file '$file'\n");
    }
    unlink "$file~" if $original_exists;
    return 1;
}

sub usage {
    require Pod::Usage;
    Pod::Usage::pod2usage(@_);
    return 1;
}

1;
__END__

=head1 NAME

Dist::Maker::Util - Common utilities

=cut