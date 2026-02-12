# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite do
  it_behaves_like 'Expireable'

  describe 'Associations' do
    it { is_expected.to belong_to(:user).inverse_of(:invites) }
    it { is_expected.to have_many(:users).inverse_of(:invite) }
  end

  describe 'Validations' do
    it { is_expected.to validate_length_of(:comment).is_at_most(described_class::COMMENT_SIZE_LIMIT) }
  end

  describe 'Scopes' do
    describe '.available' do
      let!(:no_expires) { Fabricate :invite, expires_at: nil }
      let!(:past_expires) { Fabricate :invite, expires_at: 2.days.ago }
      let!(:future_expires) { Fabricate :invite, expires_at: 2.days.from_now }

      it 'returns future and non-epiring records' do
        expect(described_class.available)
          .to include(no_expires, future_expires)
          .and not_include(past_expires)
      end
    end
  end

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

  describe 'Callbacks' do
    describe 'Setting the invite code' do
      context 'when creating a new record' do
        subject { Fabricate.build :invite }

        it 'sets a code value' do
          expect { subject.save }
            .to change(subject, :code).from(be_blank).to(be_present)
        end
      end

      context 'when updating a record' do
        subject { Fabricate :invite }

        it 'does not change the code value' do
          expect { subject.update(max_uses: 123_456) }
            .to not_change(subject, :code)
        end
      end
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
