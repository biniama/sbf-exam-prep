require 'xcodeproj'

PROJECT_NAME = 'SBFTrainer'
ROOT = File.dirname(__FILE__)
APP_DIR = File.join(ROOT, PROJECT_NAME)

project = Xcodeproj::Project.new("#{PROJECT_NAME}.xcodeproj")

target = project.new_target(:application, PROJECT_NAME, :ios, '17.0')

main_group = project.main_group
sources_group = main_group.new_group(PROJECT_NAME, PROJECT_NAME)

source_phase = target.source_build_phase
resources_phase = target.resources_build_phase

LEAF_EXTENSIONS = %w[.xcassets .lproj .bundle].freeze

def leaf_dir?(entry)
  LEAF_EXTENSIONS.any? { |ext| entry.end_with?(ext) }
end

def add_files(group, dir, source_phase, resources_phase)
  Dir.entries(dir).sort.each do |entry|
    next if entry.start_with?('.')
    full_path = File.join(dir, entry)

    if entry.end_with?('.swift')
      ref = group.new_file(entry)
      source_phase.add_file_reference(ref)
    elsif entry.end_with?('.json')
      ref = group.new_file(entry)
      resources_phase.add_file_reference(ref)
    elsif entry.end_with?('.plist')
      group.new_file(entry)  # reference only, not in resources phase
    elsif entry.end_with?('.xcassets')
      ref = group.new_file(entry)
      resources_phase.add_file_reference(ref)
    elsif File.directory?(full_path)
      subgroup = group.new_group(entry, entry)
      add_files(subgroup, full_path, source_phase, resources_phase)
    end
  end
end

add_files(sources_group, APP_DIR, source_phase, resources_phase)

# Add assets folder as folder reference (preserves directory structure)
assets_ref = main_group.new_file('SBFTrainer/Resources/assets')
assets_ref.last_known_file_type = 'folder'
resources_phase.add_file_reference(assets_ref)

target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'de.helloai.SBFTrainer'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['INFOPLIST_FILE'] = "#{PROJECT_NAME}/Info.plist"
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''   # Xcode fills this in from your Apple ID
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.launch_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(target)
scheme.save_as(File.join(ROOT, "#{PROJECT_NAME}.xcodeproj"), PROJECT_NAME)

project.save
puts "Project generated: #{PROJECT_NAME}.xcodeproj"
