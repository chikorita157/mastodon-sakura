# frozen_string_literal: true

# == Schema Information
#
# Table name: invites
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  code       :string           default(""), not null
#  expires_at :datetime
#  max_uses   :integer
#  uses       :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  autofollow :boolean          default(FALSE), not null
#  comment    :text
#

class Invite < ApplicationRecord
  include Expireable

  belongs_to :user, inverse_of: :invites
  has_many :users, inverse_of: :invite, dependent: nil

  scope :available, -> { where(expires_at: nil).or(where('expires_at >= ?', Time.now.utc)) }

  validates :comment, length: { maximum: 420 }

  before_validation :set_code

  def valid_for_use?
    (max_uses.nil? || uses < max_uses) && !expired? && user&.functional?
  end

  private

  def set_code
    loop do
      self.code = ([*('a'..'z'), *('A'..'Z'), *('0'..'9')] - %w(0 1 I l O)).sample(8).join
      break if Invite.find_by(code: code).nil?
    end
  end

  def created_by_moderator?
    self.user.can?(:manage_invites)
  end

  def th_use_invite_quota?
    TH_USE_INVITE_QUOTA
  end

  def expires_in_at_most_one_week?
    return if self.expires_in.to_i.seconds <= 1.week
    # FIXME: Localize this
    errors.add(:expires_in, 'must expire within one week')
  end

  def reasonable_outstanding_invite_count?
    valid_invites = self.user.invites.filter { |i| i.valid_for_use? }
    count = valid_invites.sum do |i|
      next i.max_uses unless i.max_uses.nil?

      errors.add(:max_uses, 'must not have any active unlimited-use invites')
      return
    end

    return if count + max_uses <= TH_ACTIVE_INVITE_SLOT_QUOTA
    errors.add(:max_uses, "must not exceed active invite slot quota of #{TH_ACTIVE_INVITE_SLOT_QUOTA}")
  end

end
