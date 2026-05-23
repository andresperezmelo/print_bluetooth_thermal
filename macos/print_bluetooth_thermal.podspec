Pod::Spec.new do |s|
  s.name             = 'print_bluetooth_thermal'
  s.version          = '0.0.1'
  s.summary          = 'Impresion de macOS'
  s.description      = <<-DESC
Impresion de macOS
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  
  # Apunta al nuevo directorio configurado para SPM
  s.source_files     = 'print_bluetooth_thermal/Sources/print_bluetooth_thermal/**/*.swift'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end