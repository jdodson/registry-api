class CreateAhPackages < ActiveRecord::Migration[6.1]
  def change
    create_table :ah_packages, id: false do |t|
      t.uuid :package_id, primary_key: true
      
      # Top-level fields
      t.string :name
      t.string :normalized_name
      t.integer :category
      t.string :logo_image_id
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
      
      # Signatures (boolean columns)
      t.boolean :signature_prov, default: false
      t.boolean :signature_cosign, default: false

      t.timestamps
    end
  end
end
