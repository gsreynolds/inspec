# Functional tests related to plugin facility
require 'functional/helper'


#=========================================================================================#
#                                Loader Errors
#=========================================================================================#
describe 'plugin loader' do
  include FunctionalHelper

  it 'handles an unloadable plugin correctly' do
    outcome = inspec_with_env('version',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'plugin_error_on_load'))
    outcome.exit_status.must_equal 2
    outcome.stdout.must_include('ERROR', 'Have an error on stdout')
    outcome.stdout.must_include('Could not load plugin inspec-divide-by-zero', 'Name the plugin in the stdout error')
    outcome.stdout.wont_include('ZeroDivisionError', 'No stacktrace in error by default')
    outcome.stdout.must_include('Errors were encountered while loading plugins', 'Friendly message in error')
    outcome.stdout.must_include('Plugin name: inspec-divide-by-zero', 'Plugin named in error')
    outcome.stdout.must_include('divided by 0', 'Exception message in error')

    outcome = inspec_with_env('version --debug',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'plugin_error_on_load'))
    outcome.exit_status.must_equal 2
    outcome.stdout.must_include('ZeroDivisionError', 'Include stacktrace in error with --debug')
  end
end

#=========================================================================================#
#                           CliCommand plugin type
#=========================================================================================#
describe 'cli command plugins' do
  include FunctionalHelper

  it 'is able to respond to a plugin-based cli subcommand' do
    outcome = inspec_with_env('meaningoflife answer',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'meaning_by_path'))
    outcome.stderr.wont_include 'Could not find command "meaningoflife"'
    outcome.stderr.must_equal ''
    outcome.stdout.must_equal ''
    outcome.exit_status.must_equal 42
  end

  it 'is able to respond to [help subcommand] invocations' do
    outcome = inspec_with_env('help meaningoflife',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'meaning_by_path'))
    outcome.exit_status.must_equal 0
    outcome.stderr.must_equal ''
    outcome.stdout.must_include 'inspec meaningoflife answer'
    # Full text:
    # 'Exits immediately with an exit code reflecting the answer to life the universe, and everything.'
    # but Thor will ellipsify based on the terminal width
    outcome.stdout.must_include 'Exits immediately'
  end

  # This is an important test; usually CLI plugins are only activated when their name is present in ARGV
  it 'includes plugin-based cli commands in top-level help' do
    outcome = inspec_with_env('help',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'meaning_by_path'))
    outcome.exit_status.must_equal 0
    outcome.stdout.must_include 'inspec meaningoflife'
  end
end

#=========================================================================================#
#                        attribute provider plugin_type
#=========================================================================================#
describe 'attribute_provider plugin type' do
  include FunctionalHelper

  let(:env) {{ INSPEC_CONFIG_DIR: File.join(config_dir_path, 'plugin_type_attribute_provider') }}
  let(:ap_profile_path) { File.join(profile_path, 'attributes-attr-prvdr') }
  let(:ap_attrs_path) { File.join(profile_path, 'attributes-attr-prvdr') }

  # When no attribute providers are present, and we cannot resolve the value of an attribute,
  # error 1 and graceful halt.
  describe 'when no attribute provider plugins are installed' do
    it 'aborts the run with an error message' do
      invocation = 'exec '
      invocation += File.join(ap_profile_path, 'case-01')
      invocation += ' --no-create-lockfile '
      invocation += ' --reporter=json '

      run_result = inspec(invocation)
      profiles = JSON.parse(run_result.stdout)['profiles']
      control_result = profiles[0]['controls'][0]['results'][0]
      control_result['status'].must_equal 'failed'
      control_result['message'].must_include 'does not have an attribute'
      control_result['message'].must_include 'case-01-attr-01'
    end
  end

  # When:
  #  * one test attribute_provider is present
  #  * and we cannot resolve the value using default values
  #  * and we cannot resolve the value using metadata values
  #  * and we cannot resolve the value using CLI --attrs
  #  then the attribute receives the value from the test attribute_provider
  describe 'when an attribute provider is available and nothing else provides a value' do
    it 'should obtain the value from the attribute provider' do
      invocation = 'exec '
      invocation += File.join(ap_profile_path, 'case-01')
      invocation += ' --no-create-lockfile '
      invocation += ' --reporter=json '

      run_result = inspec_with_env(invocation, env)
      profiles = JSON.parse(run_result.stdout)['profiles']
      control_result = profiles[0]['controls'][0]['results'][0]
      control_result['status'].must_equal 'success'
    end
  end

# When:
#  * one test attribute_provider is present
#  * and we can resolve the value using default values
#  * and we cannot resolve the value using metadata values
#  * and we cannot resolve the value using CLI --attrs
#  then the attribute recieves the value from the test attribute_provider

# When:
#  * one test attribute_provider is present
#  * and we can resolve the value using default values
#  * and we can resolve the value using metadata values
#  * and we cannot resolve the value using CLI --attrs
#  then the attribute recieves the value from the test attribute_provider (?????)


# When:
#  * one test attribute_provider is present
#  * and we can resolve the value using default values
#  * and we can resolve the value using metadata values
#  * and we can resolve the value using CLI --attrs
#  then the attribute recieves the value from the test CLI --attrs

# When:
#  * one test attribute_provider is present
#  * and the parent profile inherits from the child profile
#  * and the profiles have an attribute with the same name, but different values that identify where they came from
#  * and we cannot resolve the value using metadata values
#  * and we cannot resolve the value using CLI --attrs
#  * and the test attribute_provider provides a value for parent.attribute
#  * and the test attribute_provider does not provide a value for child.attribute
#  then the parent.attribute recieves the value from the test attribute_provider
#  then the child.attribute recieves the value from the child profile

# When:
#  * two test attribute_providers are present, Alpha and Beta
#  * and we cannot otherwise resolve the value
#  then the attribute recieves the value from (?????)
#    * could have a preference list in plugins.json
#    * could use alphabetical order
#    * could a ranking system in plugins.json
end

#=========================================================================================#
#                           inspec plugin command
#=========================================================================================#
# See lib/plugins/inspec-plugin-manager-cli/test

#=========================================================================================#
#                                CLI Usage Messaging
#=========================================================================================#
describe 'plugin cli usage message integration' do
  include FunctionalHelper

  [' help', ''].each do |invocation|
    it "includes v2 plugins in `inspec#{invocation}` output" do
      outcome = inspec(invocation)
      outcome.stderr.must_equal ''

      # These are some subcommands provided by core v2 plugins
      ['habitat', 'artifact'].each do |subcommand|
        outcome.stdout.must_include('inspec ' + subcommand)
      end
    end
  end
end

#=========================================================================================#
#                           Train Plugin Support
#=========================================================================================#

describe 'train plugin support'  do
  describe 'when a train plugin is installed' do
    include FunctionalHelper
    it 'can run inspec detect against a URL target' do
      outcome = inspec_with_env('detect -t test-fixture://',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'train-test-fixture'))
      outcome.exit_status.must_equal(0)
      outcome.stderr.must_be_empty
      lines = outcome.stdout.split("\n")
      lines.grep(/Name/).first.must_include('test-fixture')
      lines.grep(/Name/).first.wont_include('train-test-fixture')
      lines.grep(/Release/).first.must_include('0.1.0')
      lines.grep(/Families/).first.must_include('os')
      lines.grep(/Families/).first.must_include('windows')
      lines.grep(/Families/).first.must_include('unix')
      lines.grep(/Arch/).first.must_include('mock')
    end

    it 'can run inspec detect against a test-fixture backend' do
      outcome = inspec_with_env('detect -b test-fixture',  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'train-test-fixture'))
      outcome.exit_status.must_equal(0)
      outcome.stderr.must_be_empty
      lines = outcome.stdout.split("\n")
      lines.grep(/Name/).first.must_include('test-fixture')
      lines.grep(/Name/).first.wont_include('train-test-fixture')
      lines.grep(/Release/).first.must_include('0.1.0')
      lines.grep(/Families/).first.must_include('os')
      lines.grep(/Families/).first.must_include('windows')
      lines.grep(/Families/).first.must_include('unix')
      lines.grep(/Arch/).first.must_include('mock')
    end

    it 'can run inspec shell and read a file' do
      outcome = inspec_with_env("shell -t test-fixture:// -c 'file(\"any-path\").content'",  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'train-test-fixture'))
      outcome.exit_status.must_equal(0)
      outcome.stderr.must_be_empty
      outcome.stdout.chomp.must_equal 'Lorem Ipsum'
    end

    it 'can run inspec shell and run a command' do
      outcome = inspec_with_env("shell -t test-fixture:// -c 'command(\"echo hello\").exit_status'",  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'train-test-fixture'))
      outcome.exit_status.must_equal(0)
      outcome.stderr.must_be_empty
      outcome.stdout.chomp.must_equal "17"

      outcome = inspec_with_env("shell -t test-fixture:// -c 'command(\"echo hello\").stdout'",  INSPEC_CONFIG_DIR: File.join(config_dir_path, 'train-test-fixture'))
      outcome.exit_status.must_equal(0)
      outcome.stderr.must_be_empty
      outcome.stdout.chomp.must_equal "Mock Command Result stdout"
    end
  end
end