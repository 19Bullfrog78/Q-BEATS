Pod::Spec.new do |s|
  s.name           = 'QbeatsMetronome'
  s.version        = '1.0.0'
  s.summary        = 'Zero-drift metronome DSP core for Q-Beats'
  s.homepage       = ''
  s.license        = 'MIT'
  s.author         = 'Bullfrog'
  s.platforms      = { :ios => '16.0' }
  s.source         = { :git => '' }

  s.source_files   = 'ios/**/*.{h,m,mm,cpp,swift}'
  s.requires_arc   = true

  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY'           => 'libc++',
    'GCC_PREPROCESSOR_DEFINITIONS'=> 'NDEBUG=1'
  }

  s.dependency 'ExpoModulesCore'
end
