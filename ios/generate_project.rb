require "xcodeproj"
require "fileutils"

project_path = File.join(__dir__, "Milestones.xcodeproj")
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, "Milestones", :ios, "17.0")

group = project.main_group.new_group("Milestones", "Milestones")
source_files = Dir[File.join(__dir__, "Milestones", "*.swift")].sort
source_files.each do |path|
  reference = group.new_file(File.basename(path))
  target.source_build_phase.add_file_reference(reference)
end
asset_catalog = group.new_file("Assets.xcassets")
target.resources_build_phase.add_file_reference(asset_catalog)

target.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.rampolisetti.milestones"
  settings["PRODUCT_NAME"] = "Milestones"
  settings["SWIFT_VERSION"] = "6.0"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["INFOPLIST_KEY_CFBundleDisplayName"] = "Milestones"
  settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.productivity"
  settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["DEVELOPMENT_TEAM"] = ""
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
end

project.recreate_user_schemes
project.save
