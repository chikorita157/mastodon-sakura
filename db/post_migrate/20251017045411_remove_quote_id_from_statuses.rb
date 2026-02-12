# frozen_string_literal: true

class RemoveQuoteIdFromStatuses < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_column :statuses, :quote_id, :if_exists
      remove_index :statuses, name: :index_statuses_on_quote_id, if_exists: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
