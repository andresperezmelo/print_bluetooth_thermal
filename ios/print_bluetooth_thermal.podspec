Pod::Spec.new do |s|
  s.name             = 'print_bluetooth_thermal'
  s.version          = '0.0.1'
  s.summary          = 'Impresion de IOS'
  s.description      = <<-DESC
Impresion de IOS 
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  
  # Apunta únicamente al archivo o archivos Swift en la nueva estructura de SPM
  s.source_files = 'print_bluetooth_thermal/Sources/print_bluetooth_thermal/**/*.swift'
  
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end