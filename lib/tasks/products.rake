namespace :products do
  desc "Preview a product CSV import; add APPLY=1 to save. Usage: bin/rails \"products:import[path/to/file.csv]\""
  task :import, [ :path ] => :environment do |_task, args|
    path = args[:path] or abort 'Usage: bin/rails "products:import[path/to/file.csv]" [APPLY=1]'
    abort "File not found: #{path}" unless File.exist?(path)

    import = Product::Import.new(File.read(path))
    import.errors.each { |error| puts "ERROR  #{error}" }
    import.rows.each do |row|
      status = row.error? ? "ERROR" : row.action.to_s.upcase
      detail = row.error? ? row.errors : (row.changes.presence || [ "No changes" ])
      puts format("line %-4d %-9s %-20s %s", row.line, status, row.sku, detail.join("; "))
    end

    summary = import.summary
    puts "\n#{summary[:created]} to create, #{summary[:updated]} to update, " \
         "#{summary[:unchanged]} unchanged, #{summary[:failed]} with errors."

    abort "\nNothing was saved. Fix the errors above and try again." unless import.valid?

    if ENV["APPLY"] == "1"
      abort "\nNothing was saved:\n#{import.rows.flat_map(&:errors).join("\n")}" unless import.apply!
      puts "Saved."
    else
      puts "Preview only. Run again with APPLY=1 to save."
    end
  end
end
