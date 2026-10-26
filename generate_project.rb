# Generates SBFTrainer.xcodeproj (app, home-screen widget, unit tests).
#
#   gem install xcodeproj   # once
#   ruby generate_project.rb
#
# The project file is generated — edit this script instead of the .pbxproj.
require 'xcodeproj'

ROOT = __dir__
PROJECT_PATH = File.join(ROOT, 'SBFTrainer.xcodeproj')
TEAM = 'A86W8T79TR'
BUNDLE_ID = 'ai.biniam.SBFExamPrep'
DEPLOYMENT_TARGET = '17.0'
MARKETING_VERSION = '1.2'
BUILD_NUMBER = '6'

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.development_region = 'en'
project.root_object.known_regions = %w[en de Base]

app    = project.new_target(:application, 'SBFTrainer', :ios, DEPLOYMENT_TARGET)
widget = project.new_target(:app_extension, 'SBFWidget', :ios, DEPLOYMENT_TARGET)
tests  = project.new_target(:unit_test_bundle, 'SBFTrainerTests', :ios, DEPLOYMENT_TARGET)

RESOURCE_EXTENSIONS = %w[.xcassets .xcstrings .xcprivacy .json].freeze
REFERENCE_ONLY = %w[.plist .entitlements].freeze

# Adds a directory tree to `group`; Swift files are compiled into `source_targets`,
# resources are copied into `resource_target`.
def add_tree(group, dir, source_targets, resource_target, extra_source_targets = {})
  Dir.children(dir).sort.each do |entry|
    next if entry.start_with?('.')
    path = File.join(dir, entry)
    ext = File.extname(entry)
    if File.directory?(path) && ext != '.xcassets'
      sub = group.new_group(entry, entry)
      targets = source_targets + (extra_source_targets[entry] || [])
      add_tree(sub, path, targets, resource_target, extra_source_targets)
    elsif ext == '.swift'
      ref = group.new_file(entry)
      source_targets.each { |t| t.source_build_phase.add_file_reference(ref) }
    elsif RESOURCE_EXTENSIONS.include?(ext)
      ref = group.new_file(entry)
      resource_target&.resources_build_phase&.add_file_reference(ref)
    elsif REFERENCE_ONLY.include?(ext)
      group.new_file(entry)
    end
  end
end

main = project.main_group

# App — files in SBFTrainer/Shared are also compiled into the widget.
add_tree(main.new_group('SBFTrainer', 'SBFTrainer'), File.join(ROOT, 'SBFTrainer'), [app], app,
         { 'Shared' => [widget] })

# Shared data used by the iOS and Android apps.
shared = main.new_group('shared', 'shared')
questions = shared.new_file('sbf_exam_questions.json')
app.resources_build_phase.add_file_reference(questions)
navigation = shared.new_file('navigation_tasks.json')
app.resources_build_phase.add_file_reference(navigation)
assets = shared.new_file('assets')
assets.last_known_file_type = 'folder'          # folder reference keeps assets/<exam>/<id>.png
app.resources_build_phase.add_file_reference(assets)

add_tree(main.new_group('SBFWidget', 'SBFWidget'), File.join(ROOT, 'SBFWidget'), [widget], widget)
add_tree(main.new_group('SBFTrainerTests', 'SBFTrainerTests'), File.join(ROOT, 'SBFTrainerTests'), [tests], nil)

# Embed the widget in the app.
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13'   # PlugIns
embed.add_file_reference(widget.product_reference, true).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
app.add_dependency(widget)
tests.add_dependency(app)

common = {
  'DEVELOPMENT_TEAM' => TEAM,
  'CODE_SIGN_STYLE' => 'Automatic',
  'MARKETING_VERSION' => MARKETING_VERSION,
  'CURRENT_PROJECT_VERSION' => BUILD_NUMBER,
  'SWIFT_VERSION' => '5.0',
  'IPHONEOS_DEPLOYMENT_TARGET' => DEPLOYMENT_TARGET,
  'TARGETED_DEVICE_FAMILY' => '1,2',
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'LOCALIZATION_PREFERS_STRING_CATALOGS' => 'YES',
  'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES',
}

{
  app => {
    'PRODUCT_BUNDLE_IDENTIFIER' => BUNDLE_ID,
    'INFOPLIST_FILE' => 'SBFTrainer/Info.plist',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => 'SBFTrainer/SBFTrainer.entitlements',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
    'ENABLE_PREVIEWS' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks',
  },
  widget => {
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{BUNDLE_ID}.widget",
    'INFOPLIST_FILE' => 'SBFWidget/Info.plist',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => 'SBFWidget/SBFWidget.entitlements',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
  },
  tests => {
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{BUNDLE_ID}.tests",
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/SBFTrainer.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SBFTrainer',
    'BUNDLE_LOADER' => '$(TEST_HOST)',
  },
}.each do |target, settings|
  target.build_configurations.each do |config|
    config.build_settings.merge!(common).merge!(settings)
  end
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(PROJECT_PATH, 'SBFExamPrep', true)

project.save
puts "Generated #{File.basename(PROJECT_PATH)}"
