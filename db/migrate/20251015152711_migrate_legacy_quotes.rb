# frozen_string_literal: true

class MigrateLegacyQuotes < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      execute <<~SQL.squish
        INSERT INTO quotes
        (id, account_id, status_id, quoted_status_id, quoted_account_id, state, created_at, updated_at, legacy)
          (SELECT id, account_id, id,
            (SELECT id FROM statuses s2 WHERE statuses.quote_id = s2.id),
            (SELECT account_id FROM statuses s2 WHERE statuses.quote_id = s2.id),
            1, created_at, updated_at,
            COALESCE(
              NOT (SELECT local FROM statuses s2 WHERE statuses.quote_id = s2.id),
              false)
        FROM statuses WHERE quote_id IS NOT NULL);
        UPDATE statuses SET quote_approval_policy = 131702 WHERE "local" = TRUE
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
