class Api::E1::SiteSerializer < Api::E1::BaseSerializer
  attributes :sitename, :city, :state, :country, :id, :geometry, :geom_type

  def geom_type
    object[:geometry].geometry_type.type_name
  end

  format_keys :lower_camel

end
