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

  COMMENT_SIZE_LIMIT = 420
  ELIGIBLE_CODE_CHARACTERS = [*('a'..'z'), *('A'..'Z'), *('0'..'9')].freeze
  HOMOGLYPHS = %w(0 1 I l O).freeze
  VALID_CODE_CHARACTERS = ELIGIBLE_CODE_CHARACTERS - HOMOGLYPHS

  # FIXME: make this a rails cfg key or whatev?
  TH_USE_INVITE_QUOTA = !!ENV['TH_USE_INVITE_QUOTA']
  TH_INVITE_MAX_USES = ENV.fetch('TH_INVITE_MAX_USES', 25).to_i
  TH_ACTIVE_INVITE_SLOT_QUOTA = ENV.fetch('TH_ACTIVE_INVITE_SLOT_QUOTA', 40).to_i

  belongs_to :user, inverse_of: :invites
  has_many :users, inverse_of: :invite, dependent: nil

  scope :available, -> { where(expires_at: nil).or(where(expires_at: Time.now.utc..)) }

  validates :comment, length: { maximum: COMMENT_SIZE_LIMIT }

  with_options if: :th_use_invite_quota?, unless: :created_by_moderator? do |invite|
    invite.validates :expires_at, presence: true
    invite.validate :expires_in_at_most_one_week?
    invite.validates :max_uses, presence: true
    # In Rails 6.1, numericality doesn't support :in
    invite.validates :max_uses, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: TH_INVITE_MAX_USES }
    invite.validate :reasonable_outstanding_invite_count?
  end

  with_options if: :th_use_invite_quota?, unless: :created_by_moderator? do |invite|
    invite.validates :expires_at, presence: true
    invite.validate :expires_in_at_most_one_week?
    invite.validates :max_uses, presence: true
    # In Rails 6.1, numericality doesn't support :in
    invite.validates :max_uses, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: TH_INVITE_MAX_USES }
    invite.validate :reasonable_outstanding_invite_count?
  end

  before_validation :set_code, on: :create

  def valid_for_use?
    (max_uses.nil? || uses < max_uses) && !expired? && user&.functional?
  end

  private

  def set_code
    loop do
      self.code = VALID_CODE_CHARACTERS.sample(8).join
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
