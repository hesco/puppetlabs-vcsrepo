test_name 'C3478 - shallow clone repo minimal depth = 1 (ssh protocol, scp syntax)'

# Globals
repo_name = 'testrepo_shallow_clone'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    install_package(host, 'git')
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
  end
  step 'setup - establish ssh keys' do
    # create ssh keys
    on(host, 'ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N ""')

    # copy public key to authorized_keys
    on(host, 'echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config')
    on(host, 'chown -R root:root /root/.ssh')
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
      apply_manifest_on(host, "file{'/root/.ssh/id_rsa': ensure => absent, force => true }")
      apply_manifest_on(host, "file{'/root/.ssh/id_rsa.pub': ensure => absent, force => true }")
  end

  step 'shallow clone repo with puppet (scp syntax)' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "root@#{host}:#{tmpdir}/testrepo.git",
      provider => git,
      depth => 1,
    }
    EOS

    apply_manifest_on(host, pp)
    apply_manifest_on(host, pp)
  end

  step 'verify checkout is shallow and of the correct depth' do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('shallow not found') unless res.stdout.include? "shallow"
    end

    on(host, "wc -l #{tmpdir}/#{repo_name}/.git/shallow") do |res|
      fail_test('shallow not found') unless res.stdout.include? "2 #{tmpdir}/#{repo_name}/.git/shallow"
    end
  end

end