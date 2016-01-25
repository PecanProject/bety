class Api::E2::SiteSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :sitename, :city, :state, :country

  has_many :citations, through: :citations_sites

end
