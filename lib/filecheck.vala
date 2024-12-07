using GLib;
using Gee;

namespace FileCheck {

    public class Analyzer {
        public Analyzer() {}

        public ArrayList<string> analyze_directories(string dir1, string dir2, int context_size) {
            var results = new ArrayList<string>();
            var files1 = get_files(dir1);
            var files2 = get_files(dir2);

            foreach (var file1 in files1) {
                string? file2 = null;
                foreach (var f in files2) {
                    if (Path.get_basename(f) == Path.get_basename(file1)) {
                        file2 = f;
                        break;
                    }
                }

                if (file2 != null) {
                    var corruption = find_corruption(file1, file2, context_size);
                    if (corruption != "No corruption found") {
                        results.add("Corruption found in " + Path.get_basename(file1) + ": " + corruption);
                    }
                } else {
                    results.add("File missing in dir2: " + file1);
                }
            }

            return results;
        }

        public ArrayList<string> get_files(string directory) {
            var file_list = new ArrayList<string>();
            try {
                var dir = File.new_for_path(directory);
                var enumerator = dir.enumerate_children(
                    FileAttribute.STANDARD_NAME,
                    FileQueryInfoFlags.NONE
                );

                FileInfo? info;
                while ((info = enumerator.next_file()) != null) {
                    var child = dir.resolve_relative_path(info.get_name());
                    if (child.query_file_type(FileQueryInfoFlags.NONE) == FileType.REGULAR) {
                        file_list.add(child.get_path());
                    }
                }
            } catch (Error e) {
                stderr.printf("Error reading directory: %s\n", e.message);
            }

            return file_list;
        }

        public string find_corruption(string file1, string file2, int context_size) {
            string content1, content2;
            try {
                FileUtils.get_contents(file1, out content1);
                FileUtils.get_contents(file2, out content2);
            } catch (Error e) {
                return "Error reading files: " + e.message;
            }
        
            int len = content1.length < content2.length ? content1.length : content2.length;
            for (int i = 0; i < len; i++) {
                if (content1[i] != content2[i]) {
                    int start = i - context_size;
                    int end = i + context_size;
        
                    // Корректируем индексы для обеих строк
                    if (start < 0) {
                        start = 0;
                    }
                    if (end > content1.length) {
                        end = content1.length;
                    }
                    if (end > content2.length) {
                        end = content2.length;
                    }
        
                    // Проверка корректности диапазона
                    if (start < end) {
                        return "Difference at position %d".printf(i);
                    } else {
                        return "Difference at position %d: context not available".printf(i);
                    }
                }
            }
        
            return "No corruption found";
        }
        
        
    }
}
