# An example plan to clean an agent certificate
plan deploy_pe::decom_agent (
  TargetSpec $master,
  TargetSpec $nodes,
) {
    get_targets($nodes).each |$target| {
      $target_certname = run_task(
          'puppet_conf',
          $target,
          'Attempting the certname for the agent',
          action => 'get',
          setting => 'certname',
          '_catch_errors' => true
        ).find($target.name).value['status']
      # If the node is already gone, guess what the hostname is based on the name of the targetspec
      $node_certname = $target_certname ? {
          undef => $target.name,
          default => $target_certname,
      }
        unless $node_certname == undef {
          run_command(
            "/opt/puppetlabs/puppet/bin/puppet node purge ${node_certname}",
            $master,
            "Attempting to purge ${node_certname} from the master",
            '_catch_errors' => true
            )
        }
    }
}
