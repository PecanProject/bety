
describe Trait do
  it 'should be invalid if no attributes are given' do

    t = Trait.new
    expect(t.invalid?).to eq(true)
  end

  it 'should be valid if a valid mean, variable_id, and access_level are given' do
    t = Trait.new mean: 6, access_level: 1, variable_id: 1
    expect(t.invalid?).to eq(false)
  end

  it 'should be invalid if date_year has the wrong format' do
    t = Trait.new mean: 6, access_level: 1, variable_id: 1, date_year: "783"
    expect(t.invalid?).to eq(true)
  end
  
end
