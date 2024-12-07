filechecker_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

filechecker_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('glib-2.0'),        # Добавляем GLib
  dependency('gee-0.8'),        # Добавляем Gee
  meson.get_compiler('c').find_library('filecheck'),
  meson.get_compiler('vala').find_library('filecheck', dirs: vapi_dir),

]

filechecker_sources += gnome.compile_resources('filechecker-resources',
  'filechecker.gresource.xml',
  c_name: 'filechecker'
)

executable('filechecker', filechecker_sources,
  dependencies: filechecker_deps,
  include_directories: config_inc,
       install: true,
)
