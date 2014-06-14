test_name 'C3476 - shallow clone repo minimal depth = 1 (file protocol)'

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

  teardown do
    on(host, "rm -fr #{tmpdir}")
  end

  step 'shallow clone repo with puppet' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "file://#{tmpdir}/testrepo.git",
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
