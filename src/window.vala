/* window.vala
 *
 * Copyright 2024 Unknown
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
using Gtk;
using Gee;
using FileCheck;

[GtkTemplate (ui = "/org/gnome/filechecker/window.ui")]
public class Filechecker.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Label dir_label1;

    [GtkChild]
    private unowned Gtk.Label dir_label2;

    [GtkChild]
    private unowned Gtk.Label info_label;

    [GtkChild]
    private unowned Gtk.Label files_label;

    [GtkChild]
    private unowned Gtk.Label bytes_label;

    [GtkChild]
    private unowned Gtk.Label orig_label;

    [GtkChild]
    private unowned Gtk.Label corr_label;

    [GtkChild]
    private unowned Gtk.Label context_label;

    [GtkChild]
    private unowned Gtk.Button folder_button1;

    [GtkChild]
    private unowned Gtk.Button folder_button2;

    [GtkChild]
    private unowned Gtk.Button action_button;


    public Window (Gtk.Application app) {
        Object (application: app);

        // Подключение сигналов
        folder_button1.clicked.connect(() => on_folder_button_clicked(1));
        folder_button2.clicked.connect(() => on_folder_button_clicked(2));
        action_button.clicked.connect(on_action_button_clicked);

    }


    void on_folder_button_clicked(int number) {
    // Создаем диалог выбора папки
    var dialog = new FileChooserDialog("Choose dir", null, FileChooserAction.SELECT_FOLDER);

    dialog.add_button("Cancel", ResponseType.CANCEL);
    dialog.add_button("Choose", ResponseType.OK);

    dialog.set_modal(true);

    // Отображаем диалог и обрабатываем ответ асинхронно
    dialog.present();

    dialog.response.connect((response) => {
        if (response == (int)ResponseType.OK) {
            string? folder = dialog.get_file()?.get_path();
            if (folder != null) {
                if(number == 1){
                        dir_label1.set_text(folder);
                    }else{
                        dir_label2.set_text(folder);
                        }
            }
        }
        dialog.close(); // Закрываем диалог после выбора
    });
}

    private void on_action_button_clicked() {
        info_label.set_text("");
        var original_folder = dir_label1.get_text();
        var corrupted_folder = dir_label2.get_text();

        if (original_folder == "" || corrupted_folder == "") {
            info_label.set_text("Please, choose both dirs");
            return;
        }

        var results = new ArrayList<string>();
        var original_dir = File.new_for_path(original_folder);
        var corrupted_dir = File.new_for_path(corrupted_folder);

        var analyzer = new Analyzer();
        // FileComparator.CONTEXT_SIZE = 8;

        if (!original_dir.query_exists() || !corrupted_dir.query_exists()) {
            info_label.set_text("Error: One of the directories does not exist");
        return;
        }

        analyzer.compare_directory(original_dir, corrupted_dir,results);

        string filename = "";
        string number_byte = "";
        string orig_byte = "";
        string corr_byte = "";
        string context_left = "";
        string context_right = "";

        foreach (var result in results) {
            info_label.set_text("Differences:");
            if(result.contains("byte")){
                filename = result.split("File ")[1].split(" byte")[0];
                number_byte = result.split("byte: ")[1].split(" orig")[0];
                orig_byte = result.split("orig=")[1].split(" corr")[0];
                corr_byte = result.split("corr=")[1].split(" left")[0];
                context_left = result.split("left: ")[1].split(" right")[0];
                context_right = result.split("right: ")[1];

                files_label.set_text(files_label.get_text() + "\n\n" + filename);
                bytes_label.set_text(bytes_label.get_text() + "\n\n" + number_byte);
                orig_label.set_text(orig_label.get_text() + "\n\n" + orig_byte);
                corr_label.set_text(corr_label.get_text() + "\n\n" + corr_byte);
                context_label.set_text(context_label.get_text() + "\n\n" + context_left + context_right);


}
        }
    }
}




