class Member < ActiveRecord::Base
  belongs_to :team
  validates :handle, presence: true
end
