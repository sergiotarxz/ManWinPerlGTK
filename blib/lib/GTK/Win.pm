package GTK::Win;

use v5.38.0;
use strict;
use warnings;


our $VERSION = "0.001";

require XSLoader;

XSLoader::load('GTKWin', $VERSION);
require GTK::Win::Parents;
1;
