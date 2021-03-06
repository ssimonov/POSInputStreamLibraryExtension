Pod::Spec.new do |s|
  s.name         = 'POSInputStreamLibraryExtension'
  s.version      = '1.0.2'
  s.license      = 'MIT'
  s.summary      = 'NSInputStream implementation for ALAsset, NSFileHandle and other kinds of data source.'
  s.homepage     = 'https://github.com/VladiMihaylenko/POSInputStreamLibraryExtension.git'
  s.authors      = { 'Pavel Osipov' => 'posipov84@gmail.com', 'Vlad Mihaylenko' => 'vxmihaylenko@gmail.com' }
  s.source       = { :git => 'https://github.com/VladiMihaylenko/POSInputStreamLibraryExtension.git', :tag => '1.0.2' }
  s.platform     = :ios, '5.0'
  s.requires_arc = true
  s.source_files = 'POSInputStreamLibraryExtension/*.{h,m}'
  s.frameworks   = 'Foundation', 'AssetsLibrary'
end
