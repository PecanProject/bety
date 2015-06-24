class ModeltypesFormat < ActiveRecord::Base
  validates :tag,
      presence: { message: "tag can't be blank" },
      format: { with: /\A[a-z]+\z/,
                message: 'A tag must be a non-empty sequence of lowercase letters.' }

  validates_uniqueness_of :tag, scope: :modeltype_id

  belongs_to :modeltype
  belongs_to :format
  belongs_to :user
end
