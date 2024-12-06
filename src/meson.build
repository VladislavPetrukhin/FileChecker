filechecker_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

filechecker_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
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
