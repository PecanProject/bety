class Machine < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ machines.hostname }

  validates :hostname,
      presence: true,
      uniqueness: true,
      host: true

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  has_many :files, :class_name => 'DBFile'

  def select_default
    self.to_s
  end

  def to_s
    hostname
  end

  def hostid
    ActiveRecord::Base.connection.select_value("select cast(floor(nextval('users_id_seq') / 1e9) as bigint);").to_i
  end

  def host_start
    sync_host_id = hostid
    machine = Machine.where(sync_host_id: sync_host_id)
    if machine.empty?
      (sync_host_id * 1e9).to_i
    else
      machine[0][:sync_start].to_i
    end
  end

  def host_end
    sync_host_id = hostid
    machine = Machine.where(sync_host_id: sync_host_id)
    if machine.empty?
      ((sync_host_id + 1) * 1e9 - 1).to_i
    else
      machine[0][:sync_end].to_i
    end
  end
end
