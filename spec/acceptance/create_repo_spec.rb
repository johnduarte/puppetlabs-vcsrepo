require 'spec_helper_acceptance'

tmpdir = default.tmpdir('vcsrepo')

describe 'create a repo' do
  # C3424
  context 'without a source' do
    it 'creates a blank repo' do
      pp = <<-EOS
      vcsrepo { "#{tmpdir}/testrepo_blank_repo":
        ensure => present,
        provider => git,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file("#{tmpdir}/testrepo_blank_repo/") do
      # may not be true if executed in existing dir or in existing repo
      it 'should have zero files' do
        shell("ls -1 #{tmpdir}/testrepo_blank_repo | wc -l") do |r|
          expect(r.stdout).to match(/^0\n$/)
        end
      end
    end

    # would .git/HEAD be a better test
    describe file("#{tmpdir}/testrepo_blank_repo/.git") do
      it { should be_directory }
    end
    # check against bare against formatting by querying git: 'git rev-parse --is-bare-repository'
  end
  # create repo that already exists

  # C3471
  context 'bare repo' do
    it 'creates a bare repo' do
      pp = <<-EOS
      vcsrepo { "#{tmpdir}/testrepo_bare_repo":
        ensure => bare,
        provider => git,
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file("#{tmpdir}/testrepo_bare_repo/config") do
      # protect against formatting by querying git: 'git rev-parse --is-bare-repository'
      it { should contain 'bare = true' }
    end

    describe file("#{tmpdir}/testrepo_bare_repo/.git") do
      it { should_not be_directory }
    end
  end

  # ????
  context 'bare repo with a revision' do
    it 'creates a bare repo' do
      pp = <<-EOS
      vcsrepo { "#{tmpdir}/testrepo_bare_repo_rev":
        ensure => bare,
        provider => git,
        revision => 'master',
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
    end

    describe file("#{tmpdir}/testrepo_bare_repo_rev/config") do
      it { should contain 'bare = true' }
    end

    describe file("#{tmpdir}/testrepo_bare_repo_rev/.git") do
      it { should_not be_directory }
    end
  end

  # create bare repo that already exists
end
