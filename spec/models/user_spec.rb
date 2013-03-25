require 'spec_helper'

describe User do
  before { @user = User.new(login => "Example User", email => "user@example.com") }

  subject { @user }

  it { should respond_to(:login) }
  it { should respond_to(:email) }
  it { should respond_to(:page_access_level) }
  it { should respond_to(:access_level) }
  
end
