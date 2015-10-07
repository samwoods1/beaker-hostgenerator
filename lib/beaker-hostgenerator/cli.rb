require 'beaker-hostgenerator/generator'
require 'optparse'

module Beaker
  module Host
    module Generator
      class CLI
        include Beaker::Host::Generator::Data

        attr_reader :options

        def initialize
          @options = {
            list_platforms_and_roles: false,
            disable_default_role: false,
            disable_role_config: false,
            hypervisor: 'vmpooler',
          }

          ARGV.push('--help') if ARGV.empty?

          optparse = OptionParser.new do |opts|
            opts.banner = <<-eos
Usage: beaker-hostgenerator2 [options] <layout>

 where <layout> takes the following form:
  <platform>-<arch><roles>[[-<platform>]-<arch>[[<arbitrary-roles>,[...]].]<roles>[...]]

 examples:
  centos6-64mdca-32a
   1 CentOS 6 64 bit node with roles = master, database, agent, dashboard
   1 CentOS 6 32 bit node with roles = agent

  debian8-64m-32ad-32ac-centos6-64a
   1 Debian 8 64 bit node with roles = master
   1 Debian 8 32 bit node with roles = agent, database
   1 Debian 8 32 bit node with roles = agent, dashboard
   1 CentOS 6 64 bit node with roles = agent

  debian8-64m-windows8-64a
   1 Debian 8 64 bit node with roles = master
   1 Windows 8 64 bit node with roles = agent

 example with arbitrary roles:
  centos6-32compile_master,another_role.ma
   1 CentOS 6 64 bit node with roles = master, agent, compile_master, another_role

 Generally, it is expected that beaker-hostgenerator output will be redirected to a file, for example:
  beaker-hostgenerator2 centos6-64ma > host.cfg

 This can then be used in a Beaker call instead of a static Beaker config.

            eos

            opts.on('-l',
                    '--list',
                    'List beaker-hostgenerator2 supported platforms and roles. ' <<
                    'Does not produce host config.') do
              @options[:list_platforms_and_roles] = true
            end

            opts.on('-t',
                    '--hypervisor HYPERVISOR',
                    'Set beaker-hostgenerator2 hypervisor. ') do |h|
              @options[:hypervisor] = h
            end

            opts.on('--disable-role-config',
                    "Do not include role-specific configuration.") do
              @options[:disable_role_config] = true
            end

            opts.on('--disable-default-role',
                    "Do not include the default /'agent/' role.") do
              @options[:disable_default_role] = true
            end

            opts.on('-h',
                    '--help',
                    'Display command help.') do
              puts opts
              exit
            end
          end

          optparse.parse!

          if @options[:list_platforms_and_roles]
            print_platforms_and_roles
            exit
          end

          # Tokenizing the config definition for great justice
          @tokens = ARGV[0].split('-')
        end

        def print_platforms_and_roles
            puts "valid beaker-hostgenerator platforms:  "
            osinfo = Beaker::Host::Generator::Utils.get_platforms
            osinfo.each do |k,v|
              puts "   #{k}"
            end

            puts "\n"

            roles = Beaker::Host::Generator::Utils.get_roles
            puts "valid beaker-hostgenerator host roles:  "
            roles.each do |k,v|
              puts "   #{k} => #{v}"
            end
        end

        def execute!
          generator = Beaker::Host::Generator::Generator.create @options
          yaml_string = generator.generate @tokens
          puts yaml_string
        end
      end
    end
  end
end