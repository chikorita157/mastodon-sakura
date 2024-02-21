module Treehouse
  module Automod
    COMMENT_HEADER = <<~EOS
      Tracking Report - automatically created by TreehouseAutomod
    EOS

    WARNING_TEXT = <<~EOS
      Tracking Infraction - automatically created by TreehouseAutomod
    EOS

    def self.silence_with_tracking_report!(account, status_ids: [], explanation: "")
      account.save!

      self.file_tracking_report!(account, status_ids: status_ids, type: 'silence') unless account.suspension_origin == "local"
    end

    def self.suspend_with_tracking_report!(account, status_ids: [], explanation: "")
      account.save!

      self.file_tracking_report!(account, status_ids: status_ids, type: 'suspend') unless account.suspension_origin == "local"
    end

    def self.file_tracking_report!(target_account, status_ids: [], explanation: "", type: 'suspend')
      reporter = self.staff_account
      return if reporter.nil?

      # status_ids is broken because of validation
      report = ReportService.new.call(
        reporter,
        target_account,
        {
          status_ids: status_ids,
          comment: explanation.blank? ? COMMENT_HEADER : "#{COMMENT_HEADER}\n\n#{EXPLANATION}",
          th_skip_notify_staff: true,
          th_skip_forward: true,
        }
      )
      report.save!
      report.assign_to_self!(reporter)

      account_action = Admin::AccountAction.new(
        type: type,
        report_id: report.id,
        target_account: target_account,
        current_account: reporter,
        send_email_notification: false,
        text: WARNING_TEXT,
      )
      account_action.save!

      Admin::ActionLog.create(
        account: reporter,
        action: account_action,
        target: target_account,
      )

      report.resolve!(reporter)
    end

    def self.staff_account
      username = Rails.configuration.x.th_automod.automod_account_username
      Account.find_local(username) unless username.blank?
    end

    def self.process_status!(status)
      ActivityPubActivityCreateExt.process!(status)
    end

    def self.process_account!(account)
      AccountServiceExt.process!(account)
    end

    module ActivityPubActivityCreateExt
      EXPLANATION = <<~EOS
        This account was automatically suspended by TreehouseAutomod, an unsupported feature.

        Currently, the account-only heuristic should only automatically suspend accounts with one specific username and display name.

        If this action is unexpected, please unset TH_MENTION_SPAM_HEURISTIC_AUTO_LIMIT_ACTIVE.
      EOS

      def self.is_spam?(status)
        return false unless Rails.configuration.x.th_automod.mention_spam_heuristic_auto_limit_active
        account = status.account
        minimal_effort = account.note.blank? && account.avatar_remote_url.blank? && account.header_remote_url.blank?
        return false if (account.local? ||
                         account.local_followers_count > 0 ||
                         !minimal_effort)

        # minimal effort account, check mentions and account-known age
        has_mention_spam = status.mentions.size >= Rails.configuration.x.th_automod.mention_spam_threshold
        is_new_account = account.created_at > (Time.now - Rails.configuration.x.th_automod.min_account_age_threshold)

        has_mention_spam && is_new_account
      end

      # check if the status should be considered spam
      # @return true if the status was reported and the account was infracted
      def self.process!(status)
        return false unless self.is_spam?(status)
        return true if status.account.silenced?

        Automod.silence_with_tracking_report!(status.account, explanation: EXPLANATION)

        true
      end
    end

    module AccountServiceExt
      # hardcoded for now
      # md5 because they don't deserve more mentions
      HEURISTIC_NAMES = {
        "0116a9deace3289b7092e945ef5ca0a5" => Set["57d3d0b932cc9cd01be6b2f4e82c1a4a"],
      }
      # probably mathematically impossible to collide, but just in case...
      HEURISTIC_MAX_LEN = 16

      EXPLANATION = <<~EOS
        This account was automatically suspended by TreehouseAutomod, an unsupported feature.

        Currently, the account-only heuristic should only automatically suspend accounts with one specific username and display name.

        If this action is unexpected, please unset TH_HEURISTIC_AUTO_SUSPEND.
      EOS

      # @return true if the account was infracted
      def self.process!(account)
        return false unless heuristic_auto_suspend?(account)

        Automod.suspend_with_tracking_report!(account, explanation: EXPLANATION) unless account.suspension_origin == "local"

        true
      end

      def self.matches_evil_hash?(account)
        username_md5 = Digest::MD5.hexdigest(account.username)
        display_name_md5 = Digest::MD5.hexdigest(account.display_name)

        HEURISTIC_NAMES[username_md5].include?(display_name_md5)
      end

      def self.heuristic_auto_suspend?(account)
        return false unless Rails.configuration.x.th_automod.account_service_heuristic_auto_suspend_active

        return unless account.username.length < HEURISTIC_MAX_LEN && account.display_name.length < HEURISTIC_MAX_LEN

        self.matches_evil_hash?(account)
      end
    end
  end
end
