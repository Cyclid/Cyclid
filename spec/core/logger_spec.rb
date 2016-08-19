# frozen_string_literal: true
require 'spec_helper'

describe Logger do
  it 'should be a Logger instance' do
    expect(Cyclid.logger).to be_an_instance_of Logger
  end
end
