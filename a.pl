use v5.38.0;
use strict;
use warnings;

use blib;

use GTK::Win;

my $app = Gtk::Application->new("me.sergiotarxz.hola", 0);
$app->connect('activate' => sub {
    my $win = Gtk::ApplicationWindow->new($app);
    $win->present;
});
$app->run(@ARGV);
