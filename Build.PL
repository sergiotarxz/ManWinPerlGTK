use v5.38.0;
use Module::Build;

my @types = (
    [ 'Gtk::Application', 'GtkApplication', 'GTK_APPLICATION' ],
    [ 'Gio::Application', 'GApplication', 'G_APPLICATION' ],
    [ 'Gtk::Window', 'GtkWindow', 'GTK_WINDOW' ],
    [ 'Gtk::ApplicationWindow', 'GtkApplicationWindow', 'GTK_APPLICATION_WINDOW' ],
    [ 'G::Object',          'GObject',        'G_OBJECT' ],
);

my %parentships = (
    'Gtk::ApplicationWindow' => [
        'Gtk::Window',
    ],
    'Gtk::Window' => [
        'G::Object',
    ],
    'Gtk::Application' => [
        'Gio::Application',
    ],
    'Gio::Application' => [
        'G::Object',
    ]
);

generate_typemap();
generate_typedefs();
generate_parentships();

sub generate_parentships {
    open my $fh, '>', 'lib/GTK/Win/Parents.pm'
        or die "Cannot create parentships: $!";
    for my $child (keys %parentships) {
        say $fh "package $child;";
        say $fh "use v5.38.0;";
        say $fh "use vars qw/\@ISA/;";
        say $fh "our \@ISA = qw/@{[join ' ', @{$parentships{$child}}]}/;";
    }
}

my $build = Module::Build->new(
    module_name => 'GTK::Win',
    license     => 'perl',
    requires    => {
        'perl'               => '5.38.2',
        'ExtUtils::CBuilder' => 0,
    },
    xs_files           => { './GTKWin.xs' => './GTKWin.xs', },
    extra_compiler_flags => scalar `pkg-config --cflags gtk4` . " -I$ENV{PWD}",
    extra_linker_flags => scalar `pkg-config --libs gtk4`,
);

$build->create_build_script;

sub generate_typemap {
    open my $fh, '>', 'typemap'
      or die "Cannot create typemap: $!";

    say $fh "TYPEMAP";
    for my $row (@types) {
        my $perl_class = $row->[0];
        my $c_constant = $row->[1];
        my $c_class    = $row->[2];
        say $fh "
$perl_class T_PTROBJ_GOBJECT_$c_class

$c_constant * T_PTROBJ_GOBJECT_$c_class
";
    }
    say $fh "INPUT";
    for my $row (@types) {
        my $perl_class         = $row->[0];
        my $c_constant         = $row->[1];
        my $c_class            = $row->[2];
        my $c_class_lower_case = lc($c_class);
        say $fh "
T_PTROBJ_GOBJECT_$c_class
    if (sv_isobject(\$arg)) {
        IV integer_pointer = SvIV(SvRV(\$arg));
        void *void_object = INT2PTR(void *, integer_pointer);
        if (G_IS_OBJECT(void_object)) {
            GObject *gobject = G_OBJECT (void_object);
            if (G_TYPE_CHECK_INSTANCE_TYPE(gobject, ${c_class_lower_case}_get_type())) {
                \$var = $c_class (gobject);
            } else {
                croak(\"Not implementing $c_class\");
            }
        } else {
            croak(\"Expected gobject\");
        }
    } else {
        croak(\"Expected $perl_class object\");
    }
";
    }

    say $fh "OUTPUT";

    for my $row (@types) {
        my $perl_class = $row->[0];
        my $c_class    = $row->[2];

        say $fh "
T_PTROBJ_GOBJECT_$c_class
    sv_setref_pv(\$arg, \"$perl_class\", (void *)\$var);
";
    }
}

sub generate_typedefs {
    open my $fh, '>', 'typedefs.h'
        or die "Cannot create typedefs.h: $!";
    for my $row (@types) {
        my $perl_class         = $row->[0];
        my $c_constant         = $row->[1];
        my $c_class            = $row->[2];
        my $c_class_lower_case = lc($c_class);
        say $fh "typedef $c_constant *" . ($perl_class =~ s/::/__/gr).';';
    }
}
