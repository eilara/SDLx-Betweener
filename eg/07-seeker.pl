#!/usr/bin/perl

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use SDL;
use SDL::GFX::Primitives;
use SDL::Events;
use SDLx::App;
use SDLx::Text;
use SDLx::Betweener;

my $w          = 640;
my $h          = 480;

my $app = SDLx::App->new(title=>'Easing Functions', width=>$w, height=>$h);
my $tweener = SDLx::Betweener->new(app => $app);

my $player = [320, 200];
my $creep  = [[0, 0]];

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xFFFFFFFF);
    my ($x, $y) = @{$creep->[0]};
    SDL::GFX::Primitives::pixel_color($app, $x, $y, 0x000000FF);
    $app->draw_circle([$x,$y], 32, 0xFF0000FF, 1);
    $app->draw_circle_filled($player, 16, 0xFFFFFFFF);
    $app->draw_circle($player, 16, 0x000000FF, 1);
    $app->update;
});

$app->add_event_handler(sub {
    my ($e, $app) = @_;
    if($e->type == SDL_QUIT) {
        $app->stop;
    } elsif ($e->type == SDL_MOUSEMOTION) {
        $player->[0] = $e->motion_x;
        $player->[1] = $e->motion_y;
    }
    return 0;
});

my $seeker = $tweener->tween_seek(
    on => $creep->[0],
    speed => 200 / 1_000,
    to => $player,
    done => sub {
    },
);

$seeker->start;

$app->run;

__END__


$_->start(0) for @tweens;



}

# ------------------------------------------------------------------------------


    push @tweens, $tweener->tween_path(
        t       => 6_000,
        to      => [$w - $radius, $y],
        on      => {position => $circle},
        bounce  => 1,
        forever => 1,
        ease    => $ease,
    );
