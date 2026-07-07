#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <gtk/gtk.h>
#include "typedefs.h"

static void
perl_signal_callback(GObject *object, gpointer data)
{
    SV *callback = (SV *)data;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSViv(PTR2IV(object))));
    PUTBACK;

    call_sv(callback, G_DISCARD);

    FREETMPS;
    LEAVE;
}

MODULE = GTKWin PACKAGE = Gtk::ApplicationWindow

Gtk::ApplicationWindow
new(SV *class, Gtk::Application app)
    CODE:
        RETVAL = GTK_APPLICATION_WINDOW (gtk_application_window_new(app));
        g_object_ref(G_OBJECT (RETVAL));
    OUTPUT:
        RETVAL

void
DESTROY(Gtk::ApplicationWindow win)
    CODE:
        if (win) {
            g_object_unref(G_OBJECT (win));
        }

MODULE = GTKWin PACKAGE = Gtk::Window

Gtk::Window
new(SV *class)
    CODE:
        RETVAL = GTK_WINDOW (gtk_window_new());
        g_object_ref(G_OBJECT (RETVAL));
    OUTPUT:
        RETVAL

void
present(Gtk::Window win)
    CODE:
        gtk_window_present(win);

void
DESTROY(Gtk::Window win)
    CODE:
        if (win) {
            g_object_unref(G_OBJECT (win));
        }

MODULE = GTKWin PACKAGE = Gtk::Application

Gtk::Application
new(SV *class, char *app_name, size_t flags)
    CODE:
        RETVAL = GTK_APPLICATION (gtk_application_new(app_name, flags));
        g_object_ref(G_OBJECT (RETVAL));
    OUTPUT:
        RETVAL

MODULE = GTKWin PACKAGE = Gio::Application

void
run(Gio::Application app, ...)
    CODE:
        int argc = items - 1;
        char **argv = malloc((argc + 1) * sizeof(*argv));

        argv[0] = "app";

        for (int i = 1; i < argc; i++) {
            argv[i] = SvPV_nolen(ST(i));
        }

        argv[argc] = NULL;

        g_application_run(app, argc, argv);

        free(argv);

void
DESTROY(Gtk::Application app)
    CODE:
        if (app) {
            g_object_unref(G_OBJECT (app));
        }

MODULE = GTKWin PACKAGE = G::Object

void
connect(G::Object obj, SV *signal, SV *callback)
    CODE:
        if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
            croak("callback must be a coderef");
        }

        SvREFCNT_inc(callback);

        g_signal_connect(
            obj,
            SvPV_nolen(signal),
            G_CALLBACK(perl_signal_callback),
            callback
        );
