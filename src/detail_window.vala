[GtkTemplate (ui = "/org/gnome/filechecker/detail_window.ui")]
public class Filechecker.DetailWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Label file_label;
    [GtkChild]
    private unowned Gtk.Label bytes_label;
    [GtkChild]
    private unowned Gtk.Label orig_label;
    [GtkChild]
    private unowned Gtk.Label corr_label;
    [GtkChild]
    private unowned Gtk.Label context_left_orig_label;
    [GtkChild]
    private unowned Gtk.Label context_bytes_orig_label;
    [GtkChild]
    private unowned Gtk.Label context_right_orig_label;
    [GtkChild]
    private unowned Gtk.Label context_left_corr_label;
    [GtkChild]
    private unowned Gtk.Label context_bytes_corr_label;
    [GtkChild]
    private unowned Gtk.Label context_right_corr_label;

    public DetailWindow (Gtk.Application app, string result) {
        Object (application: app);

        var filename = result.split("File: ")[1].split(" byte")[0];
        var number_byte = result.split("byte: ")[1].split(" orig")[0];
        var orig_byte = result.split("orig=")[1].split(" corr")[0];
        var corr_byte = result.split("corr=")[1].split(" left")[0];
        var context_left = result.split("left: ")[1].split(" right")[0];
        var context_right = result.split("right: ")[1];

        file_label.set_text(filename);
        bytes_label.set_text(number_byte);
        orig_label.set_text(orig_byte);
        corr_label.set_text(corr_byte);
        context_left_orig_label.set_text(context_left);
        context_bytes_orig_label.set_text(orig_byte);
        context_right_orig_label.set_text(context_right);
        context_left_corr_label.set_text(context_left);
        context_bytes_corr_label.set_text(corr_byte);
        context_right_corr_label.set_text(context_right);


    }
}

