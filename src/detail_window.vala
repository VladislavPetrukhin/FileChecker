
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
    [GtkChild]
    private unowned Gtk.Label context_text_orig;
    [GtkChild]
    private unowned Gtk.Label context_text_corr;

    public DetailWindow (Gtk.Application app, string result,
                         string original_folder, string corrupted_folder, int context_size) {
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

        string text_orig = get_text(original_folder,filename,number_byte, context_size);
        string text_corr = get_text(corrupted_folder,filename,number_byte, context_size);

        if(text_orig != text_corr){
            context_text_orig.set_text(text_orig);
            context_text_corr.set_text(text_corr);
            }

    }

    private string get_text(string original_folder, string filename, string number_byte,
    int context_size){
        string file_path = original_folder + "/" + filename;
        int start_byte, end_byte;

    try {
        if(number_byte.contains(", ")){
            start_byte = int.parse(number_byte.split(", ")[0]) - context_size;
        var count_parts = number_byte.split(", ");
        end_byte = int.parse(count_parts[count_parts.length-1]) + context_size;
            }else{
                start_byte = int.parse(number_byte) - context_size;
                end_byte = int.parse(number_byte) + context_size;
                }

    } catch (Error e) {
        stderr.printf("Error: The start and end bytes must be integers\n");
        return "";
    }

    try {
        File file = File.new_for_path(file_path);
        FileInputStream input_stream = file.read(null);

        if (start_byte < 0) {
           start_byte = 0;
        }

        FileInfo file_info = file.query_info("standard::size", FileQueryInfoFlags.NONE, null);
        var file_size = file_info.get_size(); // Получаем размер файла из информации
        if (end_byte >= file_size) {
        end_byte = (int)(file_size - 1);
        }

        // Пропускаем байты до начального
        input_stream.skip((size_t) start_byte, null);

        // Вычисляем количество байтов для чтения
        size_t length = (size_t) (end_byte - start_byte + 1);
        uint8[] buffer = new uint8[length];

        // Читаем данные
        ssize_t bytes_read = input_stream.read(buffer, null);

        string text = "";

        if (bytes_read > 0) {
                for (int i = 0; i < bytes_read; i++) {
                    char c = (char) buffer[i];
                     text += (c >= 32 && c <= 126) ? c.to_string() : ".";
                }
                print("\n");
            }
        input_stream.close(null);
        return text;
    } catch (Error e) {
        print("Error while working with the file: %s\n", e.message);
        return "";
    }

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

