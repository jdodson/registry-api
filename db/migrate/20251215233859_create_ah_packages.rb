class CreateAhPackages < ActiveRecord::Migration[6.1]
  def change
    create_table :ah_packages, id: false do |t|
      t.uuid :package_id, primary_key: true
      
      # Top-level fields
      t.string :name
      t.string :normalized_name
      t.integer :stars
      t.boolean :official, default: false
      t.boolean :cncf
      t.text :description
      t.string :version
      t.string :app_version
      t.string :license
      t.boolean :deprecated, default: false
      t.boolean :has_values_schema, default: false
      t.boolean :signed, default: false
      t.boolean :all_containers_images_whitelisted, default: false
      t.integer :production_organizations_count
      t.bigint :ts
      
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
