# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::ProcessAccountService do
  subject { described_class.new }

  context 'with property values, an avatar, and a profile header' do
    let(:payload) do
      {
        id: 'https://foo.test',
        type: 'Actor',
        inbox: 'https://foo.test/inbox',
        attachment: [
          { type: 'PropertyValue', name: 'Pronouns', value: 'They/them' },
          { type: 'PropertyValue', name: 'Occupation', value: 'Unit test' },
          { type: 'PropertyValue', name: 'non-string', value: %w(foo bar) },
        ],
        image: {
          type: 'Image',
          mediaType: 'image/png',
          url: 'https://foo.test/image.png',
        },
        icon: {
          type: 'Image',
          url: [
            {
              mediaType: 'image/png',
              href: 'https://foo.test/icon.png',
            },
          ],
        },
      }.with_indifferent_access
    end

    before do
      stub_request(:get, 'https://foo.test/image.png').to_return(request_fixture('avatar.txt'))
      stub_request(:get, 'https://foo.test/icon.png').to_return(request_fixture('avatar.txt'))
    end

    it 'parses property values, avatar and profile header as expected' do
      account = subject.call('alice', 'example.com', payload)

      expect(account.fields)
        .to be_an(Array)
        .and have_attributes(size: 2)
      expect(account.fields.first)
        .to be_an(Account::Field)
        .and have_attributes(
          name: eq('Pronouns'),
          value: eq('They/them')
        )
      expect(account.fields.last)
        .to be_an(Account::Field)
        .and have_attributes(
          name: eq('Occupation'),
          value: eq('Unit test')
        )
      expect(account).to have_attributes(
        avatar_remote_url: 'https://foo.test/icon.png',
        header_remote_url: 'https://foo.test/image.png'
      )
    end
  end

  context 'when account is not suspended' do
    subject { described_class.new.call(account.username, account.domain, payload) }

    let!(:account) { Fabricate(:account, username: 'alice', domain: 'example.com') }

    let(:payload) do
      {
        id: 'https://foo.test',
        type: 'Actor',
        inbox: 'https://foo.test/inbox',
        suspended: true,
      }.with_indifferent_access
    end

    before do
      allow(Admin::SuspensionWorker).to receive(:perform_async)
    end

    it 'suspends account remotely' do
      expect(subject.suspended?).to be true
      expect(subject.suspension_origin_remote?).to be true
    end

    it 'queues suspension worker' do
      subject
      expect(Admin::SuspensionWorker).to have_received(:perform_async)
    end
  end

  context 'when account is suspended' do
    subject { described_class.new.call('alice', 'example.com', payload) }

    let!(:account) { Fabricate(:account, username: 'alice', domain: 'example.com', display_name: '') }

    let(:payload) do
      {
        id: 'https://foo.test',
        type: 'Actor',
        inbox: 'https://foo.test/inbox',
        suspended: false,
        name: 'Hoge',
      }.with_indifferent_access
    end

    before do
      allow(Admin::UnsuspensionWorker).to receive(:perform_async)

      account.suspend!(origin: suspension_origin)
    end

    context 'when locally' do
      let(:suspension_origin) { :local }

      it 'does not unsuspend it' do
        expect(subject.suspended?).to be true
      end

      it 'does not update any attributes' do
        expect(subject.display_name).to_not eq 'Hoge'
      end
    end

    context 'when remotely' do
      let(:suspension_origin) { :remote }

      it 'unsuspends it' do
        expect(subject.suspended?).to be false
      end

      it 'queues unsuspension worker' do
        subject
        expect(Admin::UnsuspensionWorker).to have_received(:perform_async)
      end

      it 'updates attributes' do
        expect(subject.display_name).to eq 'Hoge'
      end
    end
  end

  context 'when discovering many subdomains in a short timeframe' do
    subject do
      8.times do |i|
        domain = "test#{i}.testdomain.com"
        json = {
          id: "https://#{domain}/users/1",
          type: 'Actor',
          inbox: "https://#{domain}/inbox",
        }.with_indifferent_access
        described_class.new.call('alice', domain, json)
      end
    end

    before do
      stub_const 'ActivityPub::ProcessAccountService::SUBDOMAINS_RATELIMIT', 5
    end

    it 'creates accounts without exceeding rate limit' do
      expect { subject }
        .to create_some_remote_accounts
        .and create_fewer_than_rate_limit_accounts
    end
  end

  context 'when Accounts referencing other accounts' do
    let(:payload) do
      {
        '@context': ['https://www.w3.org/ns/activitystreams'],
        id: 'https://foo.test/users/1',
        type: 'Person',
        inbox: 'https://foo.test/inbox',
        featured: 'https://foo.test/users/1/featured',
        preferredUsername: 'user1',
      }.with_indifferent_access
    end

    before do
      stub_const 'ActivityPub::ProcessAccountService::DISCOVERIES_PER_REQUEST', 5

      8.times do |i|
        actor_json = {
          '@context': ['https://www.w3.org/ns/activitystreams'],
          id: "https://foo.test/users/#{i}",
          type: 'Person',
          inbox: 'https://foo.test/inbox',
          featured: "https://foo.test/users/#{i}/featured",
          preferredUsername: "user#{i}",
        }.with_indifferent_access
        status_json = {
          '@context': ['https://www.w3.org/ns/activitystreams'],
          id: "https://foo.test/users/#{i}/status",
          attributedTo: "https://foo.test/users/#{i}",
          type: 'Note',
          content: "@user#{i + 1} test",
          tag: [
            {
              type: 'Mention',
              href: "https://foo.test/users/#{i + 1}",
              name: "@user#{i + 1}",
            },
          ],
          to: ['as:Public', "https://foo.test/users/#{i + 1}"],
        }.with_indifferent_access
        featured_json = {
          '@context': ['https://www.w3.org/ns/activitystreams'],
          id: "https://foo.test/users/#{i}/featured",
          type: 'OrderedCollection',
          totalItems: 1,
          orderedItems: [status_json],
        }.with_indifferent_access
        webfinger = {
          subject: "acct:user#{i}@foo.test",
          links: [{ rel: 'self', href: "https://foo.test/users/#{i}" }],
        }.with_indifferent_access
        stub_request(:get, "https://foo.test/users/#{i}").to_return(status: 200, body: actor_json.to_json, headers: { 'Content-Type': 'application/activity+json' })
        stub_request(:get, "https://foo.test/users/#{i}/featured").to_return(status: 200, body: featured_json.to_json, headers: { 'Content-Type': 'application/activity+json' })
        stub_request(:get, "https://foo.test/users/#{i}/status").to_return(status: 200, body: status_json.to_json, headers: { 'Content-Type': 'application/activity+json' })
        stub_request(:get, "https://foo.test/.well-known/webfinger?resource=acct:user#{i}@foo.test").to_return(body: webfinger.to_json, headers: { 'Content-Type': 'application/jrd+json' })
      end
    end

    it 'creates accounts without exceeding rate limit', :sidekiq_inline do
      expect { subject.call('user1', 'foo.test', payload) }
        .to create_some_remote_accounts
        .and create_fewer_than_rate_limit_accounts
    end
  end

  context 'treehouse automod' do
    subject { described_class.new.call(account_username, 'foo.test', payload) }
    let(:account_username) { 'evil' }
    let(:account_display_name) { 'evil display name' }
    let(:account_payload_suspended) { false }

    let(:staff_user) { Fabricate(:moderator_user) }
    let(:automod_account_username) { staff_user.account.username }

    let(:payload) do
      {
        id: 'https://foo.test',
        type: 'Actor',
        inbox: 'https://foo.test/inbox',
        suspended: account_payload_suspended,
        name: account_display_name,
      }.with_indifferent_access
    end

    let(:name_hash_hash) do
      {
        # 'evil' => 'evil display name'
        '4034a346ccee15292d823416f7510a2f' => Set['225e44a7c4a792ee22a4ada2032da7cd']
      }
    end

    before do
      allow(Rails.configuration.x.th_automod).to receive(:account_service_heuristic_auto_suspend_active).and_return(true)
      allow(Rails.configuration.x.th_automod).to receive(:automod_account_username).and_return(automod_account_username)

      stub_const('::Treehouse::Automod::AccountServiceExt::HEURISTIC_NAMES', name_hash_hash)
      stub_const('::Treehouse::Automod::AccountServiceExt::HEURISTIC_MAX_LEN', 20)
    end

    context 'new account' do
      context 'heuristic matching' do
        it 'suspends the user locally' do
          expect(subject.suspended?).to be_truthy
          expect(subject.suspension_origin_local?).to be_truthy
        end
      end

      context 'heuristic not matching' do
        let(:account_display_name) { '' }
        it 'does nothing' do
          expect(subject.suspended?).to be_falsy
        end
      end
    end

    context 'existing account' do
      let!(:account) { Fabricate(:account, username: account_username, domain: 'foo.test', display_name: account_display_name) }

      before do
        allow(Admin::SuspensionWorker).to receive(:perform_async)
      end

      context 'heuristic matching' do
        it 'suspends the user locally' do
          expect(subject.suspended?).to be_truthy
          expect(subject.suspension_origin_local?).to be_truthy
        end
      end

      context 'heuristic not matching' do
        let(:account_display_name) { 'not evil display name' }

        it 'does nothing' do
          expect(subject.suspended?).to be_falsy
        end

        context 'suspended locally' do
          before do
            account.suspend!(origin: :local)
          end

          it 'does nothing' do
            expect(subject.suspended?).to be_truthy
          end
        end
      end
    end

    context 'tracking report' do
      let(:automod_account_username) { 'automod_test' }

      let!(:automod_user_role) { Fabricate(:user_role, name: 'Automod', permissions: UserRole::FLAGS[:administrator]) }

      let!(:automod_account) do
        account = Fabricate(:account, username: automod_account_username)
        account.user.role_id = automod_user_role.id
        account.user.save!
        account
      end

      it 'creates report' do
        expect(subject.targeted_reports.empty?).to be_falsy

        report = Report.find_by(target_account_id: subject.id, account_id: automod_account.id, assigned_account_id: automod_account.id)
        expect(report.comment.starts_with?('Tracking Report - automatically created by TreehouseAutomod')).to be_truthy
      end

      it 'creates account action' do
        subject
        expect(Admin::ActionLog.find_by(account_id: automod_account.id, target_id: subject.id)).not_to be nil
      end
    end
  end

  private

  def create_some_remote_accounts
    change(Account.remote, :count).by_at_least(2)
  end

  def create_fewer_than_rate_limit_accounts
    change(Account.remote, :count).by_at_most(5)
  end

end
