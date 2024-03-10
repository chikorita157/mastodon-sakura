# == Schema Information
#
# Table name: external_verifications
#
#  id          :bigint(8)        not null, primary key
#  account_id  :bigint(8)        not null
#  type        :string
#  challenge   :string
#  external_id :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ExternalVerification < ApplicationRecord
  belongs_to :account
end
