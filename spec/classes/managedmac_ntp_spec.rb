require 'spec_helper'

describe 'managedmac::ntp', :type => 'class' do

  # The remainder of our specs will go inside this context block
  context "on a supported operating system and product version" do
    # On our target platform, we should have green lights.
    let :facts do
      {
        :osfamily => 'Darwin',
        :macosx_productversion_major => '10.9',
      }
    end
    
    context "when it is passed no params" do
      specify { expect { should compile }.to raise_error(Puppet::Error) }
    end
    
    context "when it is passed a BAD param" do
      let :hiera_data do
        { 'managedmac::ntp::options' => "Icanhazstring" }
      end
      specify { expect { should compile }.to raise_error(Puppet::Error) }
    end
    
    context "when passed a Hash parameter" do
      
      let :hiera_data do
        { 
          'managedmac::ntp::options' => options_ntp 
        }
      end
      
      specify do
        should contain_file('ntp_conf').that_notifies('Service[org.ntp.ntpd]').with(
        { 'content' => "server\stime.apple.com\nserver\stime1.google.com" })
      end
      
      specify do
        should contain_service('org.ntp.ntpd').that_requires('File[ntp_conf]').with(
        { 'ensure' => 'running', 'enable' => 'true' })
      end
      
      context "when max_offset is not exceeded" do
        let(:facts) { { :ntp_offset => 60, } }
        specify do
          should_not contain_exec('ntp_sync')
        end
      end
      
      context "when max_offset is exceeded" do
        let(:facts) { { :ntp_offset => 300, } }
        specify do
          should contain_exec('ntp_sync').that_requires(
            'File[ntp_conf]').that_notifies(
              'Service[org.ntp.ntpd]')
        end
      end
      
      it { should compile.with_all_deps }
    end
    
  end
  
end