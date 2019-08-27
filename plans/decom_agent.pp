# @summary A plan to purge an agent on the master
#
# @param master
#  The TargetSpec for the Master to use to run the node purge on
# @param nodes
#  The TargetSpec of one or more nodes to be removed from the environment
# @example Decommission a node
#  bolt plan run 'deploy_pe::decom_agent' --run-as 'root' --params '{"master":"pe-master"}' --nodes 'pe-agent'
plan deploy_pe::decom_agent (
  TargetSpec $master,
  TargetSpec $nodes,
) {
    # Build up an array of either the certname or guessed hostname of the targets
    $agents = get_targets($nodes).map |$target| {
      $target_certname = run_task(
          'puppet_conf',
          $target,
          'Finding the certname for the agent',
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
          $node_certname
        }
    }

    unless empty($agents) {
      run_task('purge_node', $master, agent_certnames => $agents.join(','))
    }
}
