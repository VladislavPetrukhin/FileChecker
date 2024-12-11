using GLib;
using Gee;

namespace FileCheck {

    public class Analyzer {

        public Analyzer() {}

        // The number of bytes before and after a difference for context
        public int CONTEXT_SIZE = 4;

    // Test function to check the left context printing
    private void test_print_left_context() {
        uint8[] buffer = {0x01, 0x02, 0x03, 0x04, 0x05};
        string result = FileComparator.print_left_context(buffer, 3, 0);

        assert(result == "0x01 0x02 0x03 ");
    }

    // Test function to check the right context printing
    private void test_print_right_context(){
        uint8[] buffer = {0x01, 0x02, 0x03, 0x04, 0x05};
        string result = FileComparator.print_right_context(buffer, 1, 5);

        assert(result == "0x03 0x04 0x05 ");
    }

    // Helper function to create a temporary file with content
    private File? create_temp_file(string template, string content) {
        FileIOStream stream;
        try {
            var temp_file = File.new_tmp(template, out stream);
            size_t bytes_written = 0;
            stream.output_stream.write_all(content.data, out bytes_written, null);
            stream.close();

            return temp_file;
        } catch (Error e) {
            stderr.printf("Error creating file for compare test: %s\n", e.message);
            return null;
        }
    }

    // Test function to compare two files
    private void test_compare_files() {
        // Create a MemoryInputStream for the original file data
        var original_stream = new MemoryInputStream();
        original_stream.add_data("hello".data, null);

        // Create a MemoryInputStream for the corrupted file data
        var corrupted_stream = new MemoryInputStream();
        corrupted_stream.add_data("hxllo".data, null);

        // Create temporary files for original and corrupted data
        var original_file = create_temp_file("original_XXXXXX", "hello");
        var corrupted_file = create_temp_file("corrupted_XXXXXX", "hxllo");

        //comparing the two files asynchronously
        FileComparator.compare_files.begin(original_file, corrupted_file, (obj, res) => {
            try {
                var results = FileComparator.compare_files.end(res);

                assert(results.size == 1);
                assert(results.get(0).contains("orig=0x65 corr=0x78"));
            } catch (Error e) {
                stderr.printf("Error in compare test: %s\n", e.message);
            }
        });
    }


        // Recursive function to compare files and directories
        public void compare_directory(File original_dir, File corrupted_dir, ArrayList<string> results) {
            try {
                // Enumerate children in the original directory
                var original_enumerator = original_dir.enumerate_children(
                    "standard::name,standard::type",
                    FileQueryInfoFlags.NONE
                );

                FileInfo? original_info;

                // Iterate through all files and directories
                while ((original_info = original_enumerator.next_file()) != null) {
                    var original_file_name = original_info.get_name();
                    var original_file = original_dir.get_child(original_file_name);
                    var corrupted_file = corrupted_dir.get_child(original_file_name);

                    // Skip symbolic links
                    if (original_info.get_file_type() == FileType.SYMBOLIC_LINK) {
                        stdout.printf("Skipping symbolic link: %s\n", original_file.get_path());
                        continue;
                    }

                    // Recursively handle directories
                    if (original_info.get_file_type() == FileType.DIRECTORY) {
                        compare_directory(original_file, corrupted_file, results);
                    } else {
                        if (!corrupted_file.query_exists()) {
                            stderr.printf("File missing in corrupted folder: " + original_file_name);
                            continue;
                        }

                        // Use asynchronous file comparison
                        var loop = new MainLoop();
                        compare_files.begin(original_file, corrupted_file, (obj, res) => {
                            try {
                                results = compare_files.end(res);
                            } catch (ThreadError e) {
                                stderr.printf("Thread error: %s\n", e.message);
                            }
                            loop.quit();
                        });
                        loop.run();
                    }
                }
            } catch (Error e) {
                stderr.printf("Error reading directory: %s\n", e.message);
            }
        }

        // Asynchronous function to compare files
        private async ArrayList<string> compare_files(File original_file, File corrupted_file) throws ThreadError {
            SourceFunc callback = compare_files.callback;
            var ress = new ArrayList<string>();

            // use multithreading
            ThreadFunc<bool> run = () => {
                var results = new ArrayList<string>();
                try {
                    // Open input streams
                    var original_stream = original_file.read();
                    var corrupted_stream = corrupted_file.read();

                    // Buffers for reading file data
                    uint8[] original_buffer = new uint8[1048576];
                    uint8[] corrupted_buffer = new uint8[1048576];

                    size_t original_read = 0;
                    size_t corrupted_read = 0;
                    size_t offset = 0;

                    string result = "";
                    bool is_last_corrupted = false;  // to check that few corrupted bytes together
                    string last_result = "";  //previous result before current

                    do {
                        original_read = original_stream.read(original_buffer);
                        corrupted_read = corrupted_stream.read(corrupted_buffer);

                        size_t min_read = (original_read < corrupted_read) ? original_read : corrupted_read;

                       /* Note: this "for" create a string with keywords.
                       it doesn't use ArrayList instead,
                       because in tests strings are much faster than ArrayLists*/
                        for (size_t i = 0; i < min_read; i++) {
                            if (original_buffer[i] != corrupted_buffer[i]) {   // Compare byte by byte
                                if (!is_last_corrupted) {
                                    // new result
                                    result = "File: " + original_file.get_basename() +
                                        " byte: " + (offset + i).to_string() +
                                        " orig=" + original_buffer[i].to_string("0x%02X") +
                                        " corr=" + corrupted_buffer[i].to_string("0x%02X") +
                                        " left: " + get_left_context(original_buffer, i, offset) +
                                        " right: " + get_right_context(original_buffer, i, corrupted_read);
                                    results.add(result);
                                } else {
                                    // Modify the previous result if we found few bytes together
                                    if (results.size > 0) {
                                        last_result = results.get(results.size - 1);
                                        if (last_result.contains(" byte:") && last_result.contains("orig=") && last_result.contains("corr=")) {
                                            result = last_result.split(" byte:")[0];
                                            string byte_section = last_result.split("byte: ")[1].split(" orig")[0];
                                            string orig_section = last_result.split("orig=")[1].split(" corr=")[0];
                                            string corr_section = last_result.split(" corr=")[1].split("left:")[0];

                                            result += " byte: " + byte_section + ", " +
                                                      (offset + i).to_string() +
                                                      " orig=" + orig_section + " " + original_buffer[i].to_string("0x%02X") +
                                                      " corr=" + corr_section + " " + corrupted_buffer[i].to_string("0x%02X") +
                                                      " left: " + last_result.split("left: ")[1].split("right")[0] +
                                                      " right: " + get_right_context(corrupted_buffer, offset + i, corrupted_read);
                                            results.set(results.size - 1, result);
                                        } else {
                                            stderr.printf("Warning: Unexpected format in last_result.\n");
                                        }
                                    }
                                }
                                is_last_corrupted = true;
                            } else {
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
                ress = results;
                Idle.add((owned) callback);
                return true;
            };

            new Thread<bool>("thread-compare", run);
            yield;
            return ress;
        }

        // context of bytes before the difference
        private string get_left_context(uint8[] buffer, size_t diff_index, size_t offset) {
            size_t start = 0;
            if (diff_index > CONTEXT_SIZE) {
                start = diff_index - CONTEXT_SIZE;
            }

            string context = "";
            for (size_t i = start; i < diff_index; i++) {
                context += buffer[i].to_string("0x%02X") + " ";
            }
            return context;
        }

        // context of bytes after the difference
        private string get_right_context(uint8[] buffer, size_t diff_index, size_t buffer_size) {
            size_t start = diff_index + 1;
            size_t end = start + CONTEXT_SIZE;
            if (end > buffer_size) {
                end = buffer_size;
            }

            string context = "";
            for (size_t i = start; i < end; i++) {
                context += buffer[i].to_string("0x%02X") + " ";
            }
            return context;
        }
    }
}

