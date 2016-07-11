#require 'rgeo'
describe "RGeoInstallation" do
  it 'should be properly supported' do
    expect(RGeo::Geos.supported?).to eq(true)
  end
end

