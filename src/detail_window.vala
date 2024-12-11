
[GtkTemplate (ui = "/org/gnome/filechecker/detail_window.ui")]
public class Filechecker.DetailWindow : Adw.ApplicationWindow {
     [GtkChild]
    private unowned Gtk.Label file_label; // name of the file
    [GtkChild]
    private unowned Gtk.Label bytes_label; // bytes numbers of the difference
    [GtkChild]
    private unowned Gtk.Label orig_label; // original value of the differing bytes
    [GtkChild]
    private unowned Gtk.Label corr_label; // corrupted value of the differing bytes
    [GtkChild]
    private unowned Gtk.Label context_left_orig_label; // Context on the left side of the original file
    [GtkChild]
    private unowned Gtk.Label context_bytes_orig_label; // original value of the differing bytes in the original file
    [GtkChild]
    private unowned Gtk.Label context_right_orig_label; // Context on the right side of the original file
    [GtkChild]
    private unowned Gtk.Label context_left_corr_label; // Context on the left side of the corrupted file
    [GtkChild]
    private unowned Gtk.Label context_bytes_corr_label; // corrupted value of the differing bytes in the corrupted file
    [GtkChild]
    private unowned Gtk.Label context_right_corr_label; // Context on the right side of the corrupted file
    [GtkChild]
    private unowned Gtk.Label context_text_orig; // textu context from the original file
    [GtkChild]
    private unowned Gtk.Label context_text_corr; // text context from the corrupted file

    public DetailWindow (Gtk.Application app, string result,
                         string original_folder, string corrupted_folder, int context_size) {
        Object (application: app);
        load_css();

        // Extracts information about the file and differences from the result string
        var filename = result.split("File: ")[1].split(" byte")[0];
        var number_byte = result.split("byte: ")[1].split(" orig")[0];
        var orig_byte = result.split("orig=")[1].split(" corr")[0];
        var corr_byte = result.split("corr=")[1].split(" left")[0];
        var context_left = "";
        var context_right = "";

        if(context_size>0){
        context_left = result.split("left: ")[1].split(" right")[0];
        context_right = result.split("right: ")[1];
        }

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

        // text context from both files
        string text_orig = get_text(original_folder,filename,number_byte, context_size);
        string text_corr = get_text(corrupted_folder,filename,number_byte, context_size);

        if(text_orig != text_corr){
            context_text_orig.set_text(text_orig);
            context_text_corr.set_text(text_corr);
            }

    }

//get text context from file
private string get_text(string original_folder, string filename, string number_byte,
    int context_size){

    if(context_size == 0){
        return "";
    }

    string file_path = original_folder + "/" + filename;
    int start_byte, end_byte;

    try {
        // Parses start and end byte ranges if there are few diffs in file
        if(number_byte.contains(", ")){
            start_byte = int.parse(number_byte.split(", ")[0]) - context_size;
            var count_parts = number_byte.split(", ");
            end_byte = int.parse(count_parts[count_parts.length-1]) + context_size;
            }else{ //if only one corrupted byte in file
                start_byte = int.parse(number_byte) - context_size;
                end_byte = int.parse(number_byte) + context_size;
                }

    } catch (Error e) {
        stderr.printf("Error: The start and end bytes must be integers\n");
        return "";
    }
    //try to get text context
    try {
        File file = File.new_for_path(file_path);
        FileInputStream input_stream = file.read(null);

        if (start_byte < 0) {
           start_byte = 0;
        }

        FileInfo file_info = file.query_info("standard::size", FileQueryInfoFlags.NONE, null);
        var file_size = file_info.get_size();
        if (end_byte >= file_size) { //check that end context byte is exist in file size range
        end_byte = (int)(file_size - 1);
        }

        // Skips bytes to the start position
        input_stream.skip((size_t) start_byte, null);

        // quantity of bytes
        size_t length = (size_t) (end_byte - start_byte + 1);
        uint8[] buffer = new uint8[length];

        ssize_t bytes_read = input_stream.read(buffer, null);

        string text = "";

        // Converts the bytes to readable characters
        if (bytes_read > 0) {
                for (int i = 0; i < bytes_read; i++) {
                    char c = (char) buffer[i];
                    // replace unreadable characters with "."
                    text += (c >= 32 && c <= 126) ? c.to_string() : ".";
                }
            }
        input_stream.close(null);
        return text;
    } catch (Error e) {
        stderr.printf("Error while working with the file: %s", e.message);
        return "";
    }

  }

//css for green and red text in context labels
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
        //if app runs in GNOME Builder then get_current_dir returns home dir
        if(!css_file.contains("FileChecker")){
            css_file+="/Projects/FileChecker";
        }
        //if app runs in terminal then get_current_dir returns correct build dir
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
          stderr.printf("Error while loading CSS: %s", css_file);
        }
    }
}

