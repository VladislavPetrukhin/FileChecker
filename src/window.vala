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
    var dialog = new FileChooserDialog("Выберите папку", null, FileChooserAction.SELECT_FOLDER);

    dialog.add_button("Отмена", ResponseType.CANCEL);
    dialog.add_button("Выбрать", ResponseType.OK);

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
        var folder1 = dir_label1.get_text();
        var folder2 = dir_label2.get_text();

        if (folder1 == "" || folder2 == "") {
            info_label.set_text("Пожалуйста, выберите обе папки.");
            return;
        }

        int context_size = 10;

        var analyzer = new Analyzer();
        var results = analyzer.analyze_directories(folder1, folder2, context_size);

        foreach (var result in results) {
            info_label.set_text(info_label.get_text() + result);
        }



    }
}


