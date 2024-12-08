using GLib;
using Gee;

namespace FileCheck {

    public class Analyzer{

        public Analyzer() {}

        public int CONTEXT_SIZE = 4;  // Количество байтов до и после различия

    // Рекурсивная функция для обхода всех файлов в каталоге
    public void compare_directory(File original_dir, File corrupted_dir, ArrayList<string> results) {
        try {
            var original_enumerator = original_dir.enumerate_children(
                "standard::name,standard::type",
                FileQueryInfoFlags.NONE
            );

            FileInfo? original_info;
            while ((original_info = original_enumerator.next_file()) != null) {
                var original_file_name = original_info.get_name();
                var original_file = original_dir.get_child(original_file_name);
                var corrupted_file = corrupted_dir.get_child(original_file_name);

                if (original_info.get_file_type() == FileType.SYMBOLIC_LINK) {
                    stdout.printf("Skipping symbolic link: %s\n", original_file.get_path());
                    continue;
                }

                if (original_info.get_file_type() == FileType.DIRECTORY) {
                    compare_directory(original_file, corrupted_file, results);
                } else {
                    if (!corrupted_file.query_exists()) {
                        //results.add("File missing in corrupted folder: " + original_file_name);
                        continue;
                    }
                    compare_files(original_file, corrupted_file, results);
                }
            }
        } catch (Error e) {
            stderr.printf("Error reading directory: %s\n", e.message);
        }
    }

    private void compare_files(File original_file, File corrupted_file, ArrayList<string> results) {
        try {
            var original_stream = original_file.read();
            var corrupted_stream = corrupted_file.read();

            uint8[] original_buffer = new uint8[262144];
            uint8[] corrupted_buffer = new uint8[262144];

            size_t original_read = 0; // Инициализация
            size_t corrupted_read = 0; // Инициализация
            size_t offset = 0;

            string result = "";
            bool is_last_corrupted = false;
            string last_result = "";

            do {
                original_read = original_stream.read(original_buffer);
                corrupted_read = corrupted_stream.read(corrupted_buffer);

                size_t min_read = (original_read < corrupted_read) ? original_read : corrupted_read;

                for (size_t i = 0; i < min_read; i++) {
                    if (original_buffer[i] != corrupted_buffer[i]) {
                        if(!is_last_corrupted){
                            result = "File: " + original_file.get_basename() +
                            " byte: " + (offset + i).to_string() +
                            " orig=" + original_buffer[i].to_string("0x%02X") +
                            " corr=" + corrupted_buffer[i].to_string("0x%02X") +
                            " left: " + get_left_context(original_buffer, i) +
                            "right: " + get_right_context(original_buffer, i);
                            results.add(result);
                        }else{
                            if (results.size > 0) {
                                last_result = results.get(results.size - 1);


                                if (last_result.contains(" byte:") && last_result.contains("orig=") && last_result.contains("corr=")) {
                                    result = last_result.split(" byte:")[0];
                                    string byte_section = last_result.split("byte: ")[1].split(" orig")[0];
                                    string orig_section = last_result.split("orig=")[1].split(" corr=")[0];
                                    string corr_section = last_result.split(" corr=")[1].split("left:")[0];

                                    result += " byte: " + byte_section + ", ";
                                    result += (offset + i).to_string();
                                    result += " orig=" + orig_section + " " + original_buffer[i].to_string("0x%02X");
                                    result += " corr=" + corr_section + " " + corrupted_buffer[i].to_string("0x%02X");
                                    result += " left: " + last_result.split("left: ")[1].split("right")[0];
                                    result += "right: " + get_right_context(corrupted_buffer, offset + i);
                                    results.set(results.size - 1,result);
                                } else {
                                    stderr.printf("Warning: Unexpected format in last_result.\n");
                                }
                            }

                        }
                        is_last_corrupted = true;
                    }else{
                        is_last_corrupted = false;
                    }
                }
                offset += original_read;
            } while (original_read > 0 && corrupted_read > 0);

            original_stream.close();
            corrupted_stream.close();
        } catch (Error e) {
            stderr.printf("Error comparing files: %s\n", e.message);
        }
    }

    private string get_left_context(uint8[] buffer, size_t diff_index) {
        size_t start = (diff_index > CONTEXT_SIZE) ? diff_index - CONTEXT_SIZE : 0;
        size_t end = diff_index;

        string context = "";
        for (size_t i = start; i < end; i++) {
            context += buffer[i].to_string("0x%02X") + " ";
        }
        return context;
    }

    private string get_right_context(uint8[] buffer, size_t diff_index) {
        size_t start = diff_index + 1;
        size_t end = (diff_index + CONTEXT_SIZE + 1 <= buffer.length) ? diff_index + CONTEXT_SIZE + 1 : buffer.length;

        string context = "";
        for (size_t i = start; i < end; i++) {
            context += buffer[i].to_string("0x%02X") + " ";
        }
        return context;
    }
}
}
