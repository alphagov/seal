class AddDetailsToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :use_labels, :boolean
    add_column :teams, :exclude_labels, :string
    add_column :teams, :exclude_titles, :string
    add_column :teams, :exclude_repos, :string
    add_column :teams, :include_repos, :string
  end
end
