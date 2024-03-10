# frozen_string_literal: true
class CreateExternalVerifications < ActiveRecord::Migration[7.1]
  def change
    create_table :external_verifications do |t|
      t.belongs_to :account, null: false, foreign_key: true
      t.string :external_type
      t.string :challenge, null: true
      t.string :external_id, null: true

      t.timestamps
    end

    add_index :external_verifications, [:external_type, :external_id], unique: true
  end
end
