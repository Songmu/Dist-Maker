package Dist::Maker::Command::config;
use Mouse;
use MouseX::StrictConstructor;

use Dist::Maker;
use Dist::Maker::Util qw(parse_options slurp);

extends 'Dist::Maker::Base';

sub pass_through { 0 }

sub option_spec {
    return(
        "dump|l",
        "import-from-gitconfig",

        # TODOs
        "shift",
        "unshift",
        "push",
        "pop",
        "set",
    );
}

sub run {
    my $self = shift;

    my($options, $field, @values) = $self->parse_options(@_);

    if($options->{dump}) {
        print $self->dump_user_data;
    }
    elsif($options->{'import-from-gitconfig'}) {
        require Config::Tiny;
        my $gitconfig = Config::Tiny->read("$ENV{HOME}/.gitconfig");
        my $config = $self->config;
        if($gitconfig->{user}) {
            $config->merge_data($config->user_data->{user} //= {},
                $gitconfig->{user});
        }
        $config->save_data();
    }
    elsif(!$field) {
        # TODO: usage
    }
    elsif(!@values) {
        print $self->dump_user_data($field);
    }
    else {
        $self->user_field($field, @values);
        $self->config->save_data();
    }
    return 1;
}

sub dump_user_data {
    my($self, $field) = @_;
    my $config = $self->config;

    my $data = defined($field)
        ? $self->user_field($field)
        : $config->user_data;

    return $config->dump_data($data);
}

sub user_field {
    my($self, $field, @values) = @_;
    my $config = $self->config;

    my $data = $config->user_data;
    my @parts = split /\./, $field;
    while(1) {
        my $p = shift @parts;
        if(@parts) {
            $data = $data->{$p} //= {};
        }
        else {
            if(@values) {
                $self->log("Setting $field ",
                    (@values == 1 ? $values[0] : "[@values]"), "\n");
                $data->{$p} = @values == 1 ? $values[0] : \@values;
                return;
            }
            else {
                return $data->{$p};
            }
        }
    }
}


no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Command::meta - Manages config data

=cut