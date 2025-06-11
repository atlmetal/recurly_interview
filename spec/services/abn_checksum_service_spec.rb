require 'rails_helper'

RSpec.describe AbnChecksumService, type: :service do
  it 'validates a correct ABN' do
    expect(described_class.valid?('10120000004')).to be true
  end

  it 'rejects an incorrect ABN' do
    expect(described_class.valid?('10120000005')).to be false
  end
end
