# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
Dir.glob(Rails.root.join("db/seeds/**/*.yml")).each do |file|
  data = YAML.load_file(file)
  data.each do |record|
    model = file.split("/").last.split(".").first.singularize.classify.constantize
    model.find_or_create_by!(record)
    puts "Created #{model.name} #{record[:name]}: #{record.inspect}"
  end
end
