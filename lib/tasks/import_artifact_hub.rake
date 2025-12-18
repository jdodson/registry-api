require 'net/http'
require 'json'
require 'uri'

def flatten_package(pkg)
  repo = pkg['repository'] || {}

  {
    package_id: pkg['package_id'],
    name: pkg['name'],
    description: pkg['description'],
    version: pkg['version'],
    app_version: pkg['app_version'],
    license: pkg['license'],
    
    # Repository fields
    repository_url: repo['url'],
    repository_id: repo['repository_id'],
    repository_name: repo['name'],
    repository_display_name: repo['display_name'],
    repository_verified_publisher: repo['verified_publisher'],
    repository_official: repo['official'],
    repository_organization_name: repo['organization_name'],
    repository_organization_display_name: repo['organization_display_name']
  }
end

desc "Import packages from Artifact Hub API"
desc "Usage: rake import_artifact_hub[OFFSET] or OFFSET=1000 rake import_artifact_hub"
task :import_artifact_hub, [:offset] => :environment do |t, args|
  #base_url = 'http://localhost:8000/api/v1/packages/search'
  base_url = 'https://artifacthub.io/api/v1/packages/search'
  limit = 60
  offset = (args[:offset] || ENV['OFFSET'] || 0).to_i
  last_successful_offset = offset
  total_imported = 0
  total_updated = 0
  total_errors = 0

  puts "Starting import from Artifact Hub API..."
  puts "Starting offset: #{offset}"

  loop do
    # 29 is the kind for buildpacks
    uri = URI("#{base_url}?kind=0&limit=#{limit}&offset=#{offset}")
    
    begin
      response = Net::HTTP.get_response(uri)
      
      unless response.is_a?(Net::HTTPSuccess)
        puts "\n" + "="*60
        puts "ERROR: HTTP #{response.code} - #{response.message}"
        puts "="*60
        puts "Last successful offset: #{last_successful_offset}"
        puts ""
        puts "To resume, run: bundle exec rake 'import_artifact_hub[#{offset}]'"
        puts "="*60
        total_errors += 1
        break
      end

      data = JSON.parse(response.body)
      packages = data['packages'] || []

      break if packages.empty?

      packages.each do |pkg|
        begin
          # Flatten the package data
          flattened_data = flatten_package(pkg)
          
          # Find or initialize the record
          ah_package = AhPackage.find_or_initialize_by(package_id: flattened_data[:package_id])
          was_new = ah_package.new_record?
          
          # Update all attributes
          ah_package.assign_attributes(flattened_data)
          
          if ah_package.save
            if was_new
              total_imported += 1
            else
              total_updated += 1
            end
          else
            puts "Error saving package #{flattened_data[:package_id]}: #{ah_package.errors.full_messages.join(', ')}"
            total_errors += 1
          end
        rescue => e
          puts "Error processing package: #{e.message}"
          total_errors += 1
        end
      end

      puts "Processed #{packages.length} packages (offset: #{offset})"
      last_successful_offset = offset
      offset += limit

      # If we got fewer packages than the limit, we've reached the end
      break if packages.length < limit

    rescue => e
      puts "\n" + "="*60
      puts "ERROR: #{e.message}"
      puts "="*60
      puts "Last successful offset: #{last_successful_offset}"
      puts "Next offset to try: #{offset}"
      puts "To resume, run: rake import_artifact_hub[#{offset}]"
      puts "Or: OFFSET=#{offset} rake import_artifact_hub"
      puts "="*60
      total_errors += 1
      break
    end
  end

  puts "\n" + "="*60
  puts "Import complete!"
  puts "="*60
  puts "  New records: #{total_imported}"
  puts "  Updated records: #{total_updated}"
  puts "  Errors: #{total_errors}"
  puts "  Total processed: #{total_imported + total_updated}"
  puts "  Final offset: #{offset}"
  puts "="*60
end

