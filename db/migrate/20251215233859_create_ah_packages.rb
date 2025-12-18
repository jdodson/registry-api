class CreateAhPackages < ActiveRecord::Migration[6.1]
  def change
    create_table :ah_packages, id: false do |t|
      t.uuid :package_id, primary_key: true
      
      # Top-level fields
      t.string :name
      t.text :description
      t.string :version
      t.string :app_version
      t.string :license
      
      # Repository fields (flattened)
      t.string :repository_url
      t.uuid :repository_id
      t.string :repository_name
      t.string :repository_display_name
      t.boolean :repository_verified_publisher
      t.boolean :repository_official
      t.string :repository_organization_name
      t.string :repository_organization_display_name
      
      t.timestamps
    end
  end
end
