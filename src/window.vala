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
using Adw;


[GtkTemplate(ui = "/org/gnome/filechecker/window.ui")]
public class Filechecker.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.Label dir_label1;

    [GtkChild]
    private unowned Gtk.Label dir_label2;

    [GtkChild]
    private unowned Gtk.Label info_label;
    [GtkChild]
    private unowned Gtk.Button folder_button1;

    [GtkChild]
    private unowned Gtk.Button folder_button2;

    [GtkChild]
    private unowned Gtk.Button compare_button;

    [GtkChild]
    private unowned Gtk.Box button_container;

    [GtkChild]
    private unowned Gtk.SpinButton spin_button;

    private const int CONTEXT_SIZE_DEFAULT = 4;

    public Window(Gtk.Application app) {
        Object(application: app);

        // Connect signals
        folder_button1.clicked.connect(() => on_folder_button_clicked(1));
        folder_button2.clicked.connect(() => on_folder_button_clicked(2));
        compare_button.clicked.connect(on_compare_button_clicked);

        spin_button.set_value(CONTEXT_SIZE_DEFAULT);
    }

    void on_folder_button_clicked(int number) {
        // Create a folder chooser dialog
        var dialog = new FileChooserDialog("Choose dir", null, FileChooserAction.SELECT_FOLDER);

        dialog.add_button("Cancel", ResponseType.CANCEL);
        dialog.add_button("Select", ResponseType.OK);

        dialog.set_modal(true);

        // Show the dialog and handle the response asynchronously
        dialog.present();

        dialog.response.connect((response) => {
            if (response == (int) ResponseType.OK) {
                string? folder = dialog.get_file() ? .get_path();
                if (folder != null) {
                    if (number == 1) {
                        dir_label1.set_text(folder);
                    } else {
                        dir_label2.set_text(folder);
                    }
                }
            }
            dialog.close();
        });
    }

    //Compare func
    private void on_compare_button_clicked() {

        info_label.set_text("Analyzing...");
        var original_folder = dir_label1.get_text();
        var corrupted_folder = dir_label2.get_text();

        if (original_folder == "" || corrupted_folder == "") {
            info_label.set_text("Please, choose both dirs");
            return;
        }
        if (original_folder == corrupted_folder) {
            info_label.set_text("Please, choose different dirs");
            return;
        }

        var results = new ArrayList<string> ();
        var original_dir = File.new_for_path(original_folder);
        var corrupted_dir = File.new_for_path(corrupted_folder);

        var analyzer = new FileCheck.Analyzer(); //use Filecheck shared lib

        analyzer.CONTEXT_SIZE = (int) spin_button.get_value();

        if (!original_dir.query_exists() || !corrupted_dir.query_exists()) {
            info_label.set_text("Error: One of the directories does not exist");
            return;
        }

        // this is async task in lib
        analyzer.compare_directory(original_dir, corrupted_dir, results);

        if (results.size != 0) {
            info_label.set_text("Files with differences:");
            create_buttons(results, original_folder, corrupted_folder, analyzer.CONTEXT_SIZE);
        } else {
            info_label.set_text("No differences");
        }
    }

    private void create_buttons(ArrayList<string> results, string original_folder,
                                string corrupted_folder, int context_size) {
        // Clear existing buttons from the container
        while (button_container.get_first_child() != null) {
            button_container.remove(button_container.get_first_child());
        }

        // Add new button for each result
        for (int i = 0; i <= results.size - 1; i++) {
            int button_number = i;
            if (!results[i].contains("byte")) {
                continue;
            }
            //Get filename for button name
            var button = new Gtk.Button.with_label(results.get(i).split("File: ")[1].split(" byte")[0]);

            // Connect button click to open detailed view
            button.clicked.connect(() => on_button_clicked(
                     results.get(button_number), original_folder, corrupted_folder, context_size));

            button_container.append(button);
        }
    }

    private void on_button_clicked(string result, string original_folder,
                                   string corrupted_folder, int context_size) {
        // Open a new detail_window
        var new_window = new Filechecker.DetailWindow(
                       this.get_application(), result, original_folder, corrupted_folder, context_size);
        new_window.present();
    }
}
