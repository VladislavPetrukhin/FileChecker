# filechecker

This application is written in gtk/adw in the vala language. The application uses a shared library libfilechecker.so. It compares files in directories (including nested dirs), finds corruption and displays them. The main screen displays a list of corrupted files. To view the corruption in detail, click on the name of the file. Symbolic links, not existing files and files requiring permission are skipped.<br /> 
The application has been tested and runs on Alr Regular GNOME. Problems with access to the libfilechecker.so may be only if the installation is incorrect. App tested with file_scrambler.py.
<br />
<br />
Dependencies:
<br />
sudo apt-get install meson vala gcc libgee0.8-devel gettext-devel libadwaita-devel appstream
<br />
<br />
Install:
<br />
cd FileChecker<br />
sudo mv libfilechecker.so /usr/local/lib<br />
export LD_LIBRARY_PATH="/usr/local/lib"<br />
meson setup builddir<br />
meson compile -C builddir<br />
./builddir/src/filechecker<br />
