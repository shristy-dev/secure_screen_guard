Pod::Spec.new do |s|
  s.name             = 'secure_screen_guard'
  s.version          = '0.0.1'
  s.summary          = 'Protect sensitive Flutter screens from screenshots and recording.'
  s.description      = 'Prevent on Android, Detect & Obfuscate on iOS.'
  s.homepage         = 'https://github.com/shristy-dev/secure_screen_guard'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'you@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
