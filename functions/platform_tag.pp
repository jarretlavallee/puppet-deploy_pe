function deploy_pe::platform_tag (
  Hash $node_facts,
  Boolean $underscores = false,
) >> String {
  $arch_default = 'x86_64'
  case $node_facts['os']['family'].downcase {
    'redhat': {
      $osname = 'el'
      $version = $node_facts['os']['release']['major']
      $arch = $node_facts['architecture'] ? { undef => $arch_default, default => $node_facts['architecture'] }
    }
    'debian': {
      $osname = $node_facts['os']['name'].downcase
      $arch = $node_facts['architecture'] ? {
        'i386' => 'i386',
        default => 'amd64',
        }
      $version = $osname ? {
        'ubuntu' => $node_facts['os']['release']['full'],
        default => $node_facts['os']['release']['major']
      }
    }
    /(suse|sles)/: {
      $osname = 'sles'
      $version = $node_facts['os']['release']['major']
      $arch = $node_facts['architecture'] ? { undef => $arch_default, default => $node_facts['architecture'] }
    }
    windows: {
      $osname = 'windows'
      $version = undef
      $arch = $node_facts['architecture'] ? {
        'x32' => 'i386',
        default => 'x86_64',
        }
    }
    default: {
      $osname = $node_facts['os']['name'].downcase
      $version = $node_facts['os']['release']['major']
      $arch = $node_facts['architecture'] ? { undef => $arch_default, default => $node_facts['architecture'] }
    }
  }
  $seperator = $underscores ? {
    true => '_',
    default => '-',
  }
  # Hacky way to do a compact in puppet without stdlib
  [$osname, $version, $arch].filter |$value| { $value != undef }.join($seperator)
}
