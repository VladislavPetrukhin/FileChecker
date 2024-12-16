# filechecker

This application is written in gtk/adw in the vala language using GNOME Builder. The application uses a shared library libfilechecker.so. 
<br/>
It compares files in directories (including nested dirs), finds corruption and displays them. The main screen displays a list of corrupted files. To view the corruption in detail, click on the name of the file. You can see the context as bytes and as text. Unreadable characters are replaced by "." <br/>
Symbolic links, not existing files and files requiring permission are skipped.<br/> 
The application has been tested and runs on Alt Regular GNOME. Problems with access to the libfilechecker.so may be only if the installation is incorrect. App tested with file_scrambler.py.
<br/>
<br/>
Dependencies:
<br/>
`sudo apt-get install meson vala gcc libgee0.8-devel gettext-devel libadwaita-devel appstream`
<br/>
<br/>
Install and run:
<br/>
`cd FileChecker`<br/>
`meson setup build`<br/>
`meson compile -C build`<br/>
`./build/src/filechecker`<br/>
