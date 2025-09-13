# lib/tasks/import.rake
require "combine_pdf"
require "json"

namespace :import do
  desc "Import MPs financial interests using RubyLLM with PDF processing"
  task :serialize, [ :pdf_file ] => :environment do |t, args|
    unless args[:pdf_file]
      puts "Usage: rake import:source[path/to/pdf.pdf]"
      exit 1
    end

    keep = ENV.fetch("KEEP", "false") == "true"
    delay = ENV.fetch("DELAY", "0").to_i
    pdf_file = args[:pdf_file]
    output_file_path = args[:output_file] || File.basename(pdf_file, File.extname(pdf_file)) + ".jsonl"
    File.unlink(output_file_path) if File.exist?(output_file_path) && !keep
    output_file = File.open(output_file_path, "a")
    lookup_file = File.basename(pdf_file, File.extname(pdf_file)) + "_lookup.json"
    temp_dir = "tmp/mp_pages"

    unless File.exist?(pdf_file)
      puts "File not found: #{pdf_file}"
      exit 1
    end

    # Create temp directory for individual page PDFs
    FileUtils.mkdir_p(temp_dir)

    # puts "Step 1: Creating name-to-page lookup table using RubyLLM..."
    unless File.exist?(lookup_file)
      lookup_table = create_lookup_table(pdf_file) unless File.exist?(lookup_file)
      File.write(lookup_file, JSON.pretty_generate(lookup_table))
    end

    lookup_table = JSON.parse(File.read(lookup_file))
    puts "Lookup table saved to: #{lookup_file}"

    puts "Step 2: Processing individual MPs using RubyLLM..."
    all = process_individuals(pdf_file, lookup_table, temp_dir, keep) do |individual_data|
      output_file.puts(JSON.pretty_generate(individual_data))
      sleep delay
    end

    puts "Done — processed #{all.size} entries -> #{output_file_path}"

    # Clean up temp directory
    FileUtils.rm_rf(temp_dir)
  end

  private

  def lookup_table_schema
    @lookup_table_schema ||= {
      type: "object",
      properties: {
        name: { type: "string" },
        page_numbers: { type: "array", items: { type: "number" } }
      }
    }
  end

  def individual_data_schema
    @individual_data_schema ||= {
      type: "object",
      properties: {
        name: { type: "string" },
        party: { type: "string" },
        electorate: { type: "string" },
        sections: { type: "array", items: {
          type: "object",
          properties: {
            id: { type: "number" },
            label: { type: "string" },
            items: { type: "array", items: { type: "string" } }
          }
        } }
      }
    }
  end

  def create_lookup_table(pdf_file)
    prompt = <<~PROMPT
      I have a register of pecuniary interests PDF document.
      I need you to analyze the document structure and create a JSON lookup table mapping each individual's name to the page numbers where their information appears.

      Based on the document overview, please return a JSON object where:
      - Keys are the full names of individuals (as they appear in the document)
      - Values are arrays of page numbers where that MP's information appears

      Look for patterns like:
      - "Name (Location, Party, Electorate)" at the start of entries
      - Numbered sections (1, 2, 3, etc.) that follow each individual's name
      - Page breaks that separate different MPs

      The document is to be a register with individual entries spanning multiple pages.
      Each entry typically starts with their name and party/electorate information.
    PROMPT

    response = RubyLLM.chat.with_schema(lookup_table_schema).ask(prompt, with: pdf_file)
    parse_json_response(response.content)
  rescue JSON::ParserError => e
    puts "Error parsing lookup table response: #{e.message}"
    puts "Raw response: #{response.content}"
    {}
  end

  def process_individuals(pdf_file, lookup_table, temp_dir, keep, &block)
    all = []

    lookup_table.each do |name, page_numbers|
      # Create safe filename for individual
      safe_name = name.gsub(/[^a-zA-Z0-9\s]/, "").gsub(/\s+/, "_")
      individual_file_path = File.join(temp_dir, "#{safe_name}.json")

      # Check if individual file exists and keep is true
      if File.exist?(individual_file_path) && keep
        puts "Skipping #{name} - individual file exists and KEEP=true"
        # Still read the existing data to include in overall file
        begin
          existing_data = JSON.parse(File.read(individual_file_path))
          all << existing_data
          block.call(existing_data) if block_given?
        rescue JSON::ParserError => e
          puts "Error reading existing file for #{name}: #{e.message}"
        end
        next
      end

      puts "Processing: #{name} (pages: #{page_numbers.join(', ')})"

      # Extract specific pages as a new PDF
      individual_pdf_path = extract_individual_pages(pdf_file, page_numbers, name, temp_dir)

      # Use RubyLLM to extract structured data from the PDF
      individual_data = extract_individual_data_from_pdf(name, individual_pdf_path)
      puts "Individual data: #{individual_data}"
      individual_data["source_file"] = pdf_file
      individual_data["source_page_numbers"] = page_numbers

      # Write individual data to their own file
      File.write(individual_file_path, JSON.pretty_generate(individual_data))
      puts "Individual data saved to: #{individual_file_path}"

      all << individual_data
      block.call(individual_data) if block_given?

      # Clean up the temporary PDF
      File.delete(individual_pdf_path) if File.exist?(individual_pdf_path)
    end

    all
  end

  def extract_individual_pages(pdf_file, page_numbers, name, temp_dir)
    # Load the original PDF
    pdf = CombinePDF.load(pdf_file)

    # Create a new PDF with only the specified pages
    new_pdf = CombinePDF.new
    page_numbers.each do |page_num|
      page_index = page_num - 1 # Convert to 0-based index
      if page_index >= 0 && page_index < pdf.pages.length
        new_pdf << pdf.pages[page_index]
      end
    end

    # Save the extracted pages as a new PDF
    safe_name = name.gsub(/[^a-zA-Z0-9\s]/, "").gsub(/\s+/, "_")
    individual_pdf_path = File.join(temp_dir, "#{safe_name}_pages.pdf")
    new_pdf.save(individual_pdf_path)

    individual_pdf_path
  end

  def extract_individual_data_from_pdf(name, pdf_path)
    prompt = <<~PROMPT
      I have a PDF containing the financial interests information for an individual from a Register of Pecuniary Interests.

      Please analyze this PDF and extract the following information into a JSON object:

      Required fields:
      - name: The individual's full name
      - party: Their political party
      - electorate: Their electorate or "List" if they're a list MP
      - sections: An object containing their financial interests organized by category

      The categories are numbered 1-14 and represent:
      1. Company directorships and controlling interests
      2. Other companies and business entities
      3. Employment
      4. Trusts
      5. Organisations seeking Government funding
      6. Real property
      7. Retirement schemes
      8. Managed investment schemes
      9. Debts owed to you
      10. Debts owed by you
      11. Overseas travel
      12. Gifts
      13. Discharged debts
      14. Payments for activities

      For each category, include the category number, category label, and an array of items/descriptions. If a category has no entries, include an empty array.
      For example:
      {
        "company_directorships_and_controlling_interests": {
          "id": 1,
          "items": [ "Company 1", "Company 2" ]
        }
      }


      Individual Name: #{name}
    PROMPT

    # RubyLLM can process PDFs directly
    response = RubyLLM.chat.with_schema(individual_data_schema).ask(prompt, with: pdf_path)
    parse_json_response(response.content)
  rescue JSON::ParserError => e
    puts "Error parsing MP data for #{name}: #{e.message}"
    puts "Raw response: #{response.content}"
    nil
  end

  private

  # Helper method to safely parse JSON response, handling backticks
  def parse_json_response(response_content)
    return response_content if response_content.is_a?(Hash)

    JSON.parse(response_content)
  rescue JSON::ParserError
    json_match = response_content.match(/```(?:json)?\s*\n?(.*?)\n?```/m)
    JSON.parse(json_match[1].strip) if json_match
  end
end
