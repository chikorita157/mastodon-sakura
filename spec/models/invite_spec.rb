# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite do
  describe '#valid_for_use?' do
    it 'returns true when there are no limitations' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: nil)
      expect(invite.valid_for_use?).to be true
    end

    it 'returns true when not expired' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: 1.hour.from_now)
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when expired' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: 1.hour.ago)
      expect(invite.valid_for_use?).to be false
    end

    it 'returns true when uses still available' do
      invite = Fabricate(:invite, max_uses: 250, uses: 249, expires_at: nil)
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when maximum uses reached' do
      invite = Fabricate(:invite, max_uses: 250, uses: 250, expires_at: nil)
      expect(invite.valid_for_use?).to be false
    end

    it 'returns false when invite creator has been disabled' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: nil)
      invite.user.account.suspend!
      expect(invite.valid_for_use?).to be false
    end
  end

  context 'when th_use_invite_quota?' do
    let(:max_uses) { 25 }
    let(:expires_in) { 1.week.in_seconds }
    let(:regular_user) { Fabricate(:user) }
    let(:moderator_user) { Fabricate(:moderator_user) }
    let(:user) { regular_user }
    let(:created_at) { Time.at(0) }
    let(:expires_at) { Time.at(0) + expires_in }

    subject { Fabricate.build(:invite, user: user, max_uses: max_uses, created_at: created_at, expires_at: expires_at ) }

    before do
      stub_const('Invite::TH_USE_INVITE_QUOTA', true)
      stub_const('Invite::TH_INVITE_MAX_USES', 25)
      stub_const('Invite::TH_ACTIVE_INVITE_SLOT_QUOTA', 30)
    end

    it { is_expected.to be_valid }

    context 'and' do
      context 'max_uses exceeds quota' do
        let(:max_uses) { 26 }

        it { is_expected.not_to be_valid }
      end

      context 'expires_in exceeds quota' do
        let(:expires_in) { 1.week.in_seconds + 1 }

        it { is_expected.not_to be_valid }
      end

      context 'multiple values exceed quota' do
        let(:max_uses) { 26 }
        let(:expires_in) { 86401 }

        it { is_expected.not_to be_valid }
      end

      context 'an unlimited use invite' do
        before do
          Fabricate.build(:invite, user: user).save(validate: false)
        end

        it { is_expected.not_to be_valid }
      end

      context 'too many outstanding invites' do
        before do
          Fabricate.build(:invite, user: user, max_uses: 6).save(validate: false)
        end

        it { is_expected.not_to be_valid }
      end

      context 'a moderator created the invite' do
        let(:user) { moderator_user }

        it { is_expected.to be_valid }
      end
    end
  end
end
