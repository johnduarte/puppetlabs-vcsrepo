test_name 'C3477 - shallow clone repo minimal depth = 1 (ssh protocol)'

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
    on(host, 'yes | ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N ""')

    # copy public key to authorized_keys
    on(host, 'cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys')
    on(host, 'echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config')
    on(host, 'chown -R root:root /root/.ssh')
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
    apply_manifest_on(host, "file{'/root/.ssh/id_rsa': ensure => absent, force => true }", :catch_failures => true)
    apply_manifest_on(host, "file{'/root/.ssh/id_rsa.pub': ensure => absent, force => true }", :catch_failures => true)
  end

  step 'shallow clone repo with puppet' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "ssh://root@#{host}#{tmpdir}/testrepo.git",
      provider => git,
      depth => 1,
    }
    EOS

    apply_manifest_on(host, pp, :catch_failures => true)
    apply_manifest_on(host, pp, :catch_changes  => true)
  end

  step 'verify checkout is shallow and of the correct depth' do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('shallow not found') unless res.stdout.include? "shallow"
    end

    on(host, "cd #{tmpdir}/#{repo_name}; git log --format=oneline | wc -l") do |res|
      assert_equal(1,res.stdout.chomp.to_i,'more than 1 commit shown in git log')
    end
  end

end
