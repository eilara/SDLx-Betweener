package SDLx::Betweener;

use 5.010001;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use SDL;
use SDLx::Betweener::Timeline;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('SDLx::Betweener', $VERSION);

# tween types

use constant { TWEEN_INT  => 0, TWEEN_FLOAT => 1, TWEEN_PATH => 2,
               TWEEN_RGBA => 3, };
my @Tween_Lookup = qw(_tween_int _tween_float _tween_path _tween_rgba);

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
    my $move_handler   = sub { $timeline->tick };
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
    $self->{timeline}->tick($now? $now: ());
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

sub tween_spawn {
    my ($self, %args) = @_;
    my $on    = $args{on}                || die 'No "on" given';
    my $proxy = $Proxy_Lookup{ref $on}   || die "unknown proxy type: $on";
    my $ease  = $Ease_Lookup{$args{ease} || 'linear'};
    my $waves = delete($args{waves})     || die 'No "waves" given to spawn tween';

    die 'tween_spawn only supports linear ease, mail me if you need non-linear'
        if $ease;

    my $inner = $proxy == CALLBACK_PROXY? $on:
                $proxy == METHOD_PROXY  ? do {
                    my $method = [keys   %$on]->[0];
                    my $obj    = [values %$on]->[0];
                    weaken($obj);
                    sub { $obj->$method(@_) };
                }: die 'Cannot use direct proxy on spawn tween';
    
    my $copy = 'Tween not set yet';

    # TODO wave skipping
    $args{on} = sub {
        my $top_wave      = shift;
        my $cycle_start_t = $copy->get_cycle_start_time;
        my $total_pause_t = $copy->get_total_pause_time;
        my $inter_wave_t  = $copy->get_duration / ($waves - 1);
        my $start_t       = $cycle_start_t + $total_pause_t + $top_wave * $inter_wave_t;
        $inner->($top_wave, $start_t);
    };

    $args{from} = 0;
    $args{to}   = $waves - 1;

    my $tween = $self->tween_int(%args);

    $copy = $tween;
    weaken($copy);

    return $tween;
}

sub tween_fade {
    my ($self, %args) = @_;
    my $on    = $args{on}              || die 'No "on" given';
    my $proxy = $Proxy_Lookup{ref $on} || die "unknown proxy type: $on";

    my ($from, $to) = extract_range($proxy, $on, %args);;

    # 'to' is given as byte of final opacity, we turn it into final
    # rgba value using 'from'
    $to = ($from & 0xFFFFFF00) | $to;

    $args{from} = $from;
    $args{to}   = $to;

    return $self->tween_rgba(%args);
}

sub tween_seek {
    my ($self, %args) = @_;
    my $on     = $args{on}              || die 'No "on" given';
    my $speed  = $args{speed}           || die 'No "speed" given';
    my $proxy  = $Proxy_Lookup{ref $on} || die "unknown proxy type: $on";

    my ($from, $to) = extract_range($proxy, $on, %args);;

    $on = [%$on] if $proxy == METHOD_PROXY;

    return $self->{timeline}->_tween_seek(
        $proxy,
        $on,
        $speed,
        $from,
        $to,
        extract_completer(\%args),
    );
}

sub tween_rgba {
    my ($self, %args) = @_;
    my $builder = $Tween_Lookup[TWEEN_RGBA];
    my $on      = $args{on}                || die 'No "on" given';
    my $t       = $args{t}                 || die 'No "t" for duration given';
    my $proxy   = $Proxy_Lookup{ref $on}   || die "unknown proxy type: $on";
    my $ease    = $Ease_Lookup{$args{ease} || 'linear'};

    my ($from, $to) = extract_range($proxy, $on, %args);;

    $on = [%$on] if $proxy == METHOD_PROXY;

    return $self->{timeline}->$builder(
        $proxy,
        $on,
        $t,
        $from, $to,
        $ease,
        $args{forever} || 0,
        $args{repeat}  || 1,
        $args{bounce}  || 0,
        $args{reverse} || 0,
        extract_completer(\%args),
    );
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
        extract_completer(\%args),
    );
}

sub extract_completer {
    my ($args) = @_;
    my $done = $args->{done} || sub {};
    $done = [%$done] if ref($done) eq 'HASH';
    return $done;
}

# extracts "from" key from args
sub extract_range {
    my ($proxy, $on, %args) = @_;
    my ($from, $to);

    # try to get 'from/to' from range
    ($args{from}, $args{to}) = @{ $args{range} } if $args{range};
    # must have "to" by now
    $to = $args{to};
    die 'No "to" defined' unless defined $to;

    $from = $args{from};
    unless (defined $from) {
        # if we have no 'from' lets try to get it from the proxy
        if ($proxy == DIRECT_PROXY) {
            $from = ref($on) eq 'SCALAR'? $$on: $on;
        } elsif ($proxy == METHOD_PROXY) {
            my $method = [keys %$on]->[0];
            $from = [values %$on]->[0]->$method;
        } elsif ($proxy == CALLBACK_PROXY)
            { die 'No "from" given for callback proxy' }
    }
    return ($from, $to);
}


1;

