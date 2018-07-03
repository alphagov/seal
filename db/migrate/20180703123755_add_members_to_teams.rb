class AddMembersToTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :handle
      t.belongs_to :team, index: true
      t.timestamps null: false
    end
  end
end
