package SDLx::Betweener;

use 5.010001;
use strict;
use warnings;
use SDL;
use SDLx::Betweener::Timeline;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('SDLx::Betweener', $VERSION);

# tween types

use constant { TWEEN_INT => 0, TWEEN_FLOAT => 1, TWEEN_PATH => 2 };
my @Tween_Lookup = qw(_tween_int _tween_float _tween_path);

# proxy types

use constant { DIRECT_PROXY => 1, CALLBACK_PROXY => 2, METHOD_PROXY => 3 };
my %Proxy_Lookup = do { my $i = 1; map { $_ => $i++ } qw(ARRAY CODE HASH)};

# path types

use constant { LINEAR_PATH => 0, CIRCULAR_PATH => 1 };
my %Path_Lookup = do { my $i = 0; map { $_ => $i++ } qw(
    linear circular polyline
)};

# ease types

my @Ease_Names = qw(
    linear
    p2_in p2_out p2_in_out
    p3_in p3_out p3_in_out
    p4_in p4_out p4_in_out
    p5_in p5_out p5_in_out
    sine_in sine_out sine_in_out
    circular_in circular_out circular_in_out
    exponential_in exponential_out exponential_in_out
    elastic_in elastic_out elastic_in_out
    back_in back_out back_in_out
    bounce_in bounce_out bounce_in_out
);
my %Ease_Lookup = do { my $i = 0; map { $_ => $i++ } @Ease_Names };
sub Ease_Names { @Ease_Names }

sub new {
    my ($class, %args) = @_;
    my $timeline       = SDLx::Betweener::Timeline->new;
    my $move_handler   = sub { $timeline->tick(SDL::get_ticks) };
    $args{app}->add_move_handler($move_handler) if $args{app};
    return bless {
        timeline     => $timeline,
        move_handler => $move_handler,
        %args,
    }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{app}->remove_move_handler($self->{move_handler})
        if $self->{app};
}

sub tick {
    my ($self, $now) = @_;
    $now = SDL::get_ticks unless defined $now;
    $self->{timeline}->tick($now);
}

sub tween_int {
    my ($self, %args) = @_;
    return $self->tween(TWEEN_INT, %args);
}

sub tween_float {
    my ($self, %args) = @_;
    return $self->tween(TWEEN_FLOAT, %args);
}

sub tween_path {
    my ($self, %args) = @_;
    return $self->tween(TWEEN_PATH, %args);
}

sub tween {
    my ($self, $type, %args) = @_;
    my $builder = $Tween_Lookup[$type];
    my $on      = $args{on}                || die 'No "on" given';
    my $on_type = ref($on)                 || die '"on" must be ref';
       $on      = [$on] if $on_type eq 'SCALAR'; # normalize for direct proxy
    my $t       = $args{t}                 || die 'No "t" for duration given';
    my $proxy   = $Proxy_Lookup{ref $on}   || die "unknown proxy type: $on";
    my $ease    = $Ease_Lookup{$args{ease} || 'linear'};

    # these 2 only used for 1d tweens
    my ($from, $to);

    # these 2 only used for TWEEN_PATH type
    my $path = $args{path}? $Path_Lookup{$args{path}->[0] || die 'no path type'}
                          : LINEAR_PATH;
    my $path_args;

    # these tweens need from/to syntax sugar
    if (($type == TWEEN_INT  || $type == TWEEN_FLOAT) ||
        ($type == TWEEN_PATH && $path == LINEAR_PATH)) {

        # try to get 'from/to' from range
        ($args{from}, $args{to}) = @{ $args{range} } if $args{range};
        # must have "to" by now
        $to = $args{to};
        die 'No "to" defined' unless defined $to;
        $from = $args{from};

        if (defined $from) {
            $on = $on->[0] if
                $proxy == DIRECT_PROXY && @$on == 1;
        } else {
            # if we have no 'from' lets try to get it from the proxy
            if ($proxy == DIRECT_PROXY) {
                if (@$on == 1) {
                    $on = $on->[0];
                    $from = $$on;
                } else {
                    $from = $on;
                }
            } elsif ($proxy == METHOD_PROXY) {
                my $method = [keys %$on]->[0];
                $from = [values %$on]->[0]->$method;
            } elsif ($proxy == CALLBACK_PROXY)
                { die 'No "from" given for callback proxy' }
        }

        $path_args = {from=>$from, to=>$to} if $type == TWEEN_PATH;

    } else { # then we are building a non linear path tween
        $path_args = $args{path}->[1];
    }

    $on = [%$on] if $proxy == METHOD_PROXY;

    return $self->{timeline}->$builder(
        $proxy,
        $on,
        $t,
        ($type == TWEEN_PATH? ($path, $path_args): ($from, $to)),
        $ease,
        $args{forever} || 0,
        $args{repeat}  || 1,
        $args{bounce}  || 0,
        $args{reverse} || 0,
    );
}

1;

__END__

path => [
    {linear => {from=>[1,2], to=>[3,4]}}
    {linear => {from=>[1,2], to=>[3,4]}}
],
