
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
        load_css();

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
        private void load_css(){
        var css_provider = new Gtk.CssProvider();
        var display = Gdk.Display.get_default();

        if (display != null)
        {
            Gtk.StyleContext.add_provider_for_display(
                display,
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
        string css_file = GLib.Environment.get_current_dir();
        if(!css_file.contains("FileChecker")){
            css_file+="/Projects/FileChecker";
        }
        if(css_file.contains("builddir")){
            css_file+="/../..";
            }

                css_file += "/src/css/style.css";


        try
        {
            css_provider.load_from_path(css_file);
        }
        catch (GLib.Error e)
        {
          //  GLib.Debug.print("Ошибка при загрузке CSS: " + e.message);
        }
    }
}

