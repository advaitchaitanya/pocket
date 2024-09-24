require 'erb'
require 'fileutils'
require 'kramdown'
require 'listen'

ASSETS_DIR = './assets'
PAGES_DIR = './pages'
TEMPLATES_DIR = './templates'
BUILD_DIR = './site'

# Render ERB templates
def render_template(template, locals = {})
  template_file = File.read(File.join(TEMPLATES_DIR, template))
  ERB.new(template_file).result_with_hash(locals)
end

# Render ERB partials
def render(partial_name, locals = {})
  partial_file = File.read(File.join(TEMPLATES_DIR, 'partials', "_#{partial_name}.erb"))
  ERB.new(partial_file).result_with_hash(locals)
end

# Convert Markdown to HTML
def render_markdown(content)
  Kramdown::Document.new(content).to_html
end

# Process a single page
def process_page(page)
  page_content = File.read(page)
  html_content = if File.extname(page) == '.md'
                   render_markdown(page_content)
                 else
                   page_content
                 end

  # Render the page using the layout template
  layout_content = render_template('layout.erb', content: html_content)

  # Save the rendered content to the build directory
  output_filename = "#{File.basename(page, '.*')}.html"
  File.write(File.join(BUILD_DIR, output_filename), layout_content)

  puts "Generated: #{output_filename}"
end

# Copy static files from _assets/ to site/
def copy_static_files
  FileUtils.mkdir_p(BUILD_DIR)
  FileUtils.cp_r(ASSETS_DIR, BUILD_DIR) if Dir.exist?(ASSETS_DIR)
  puts 'Static files copied.'
end

# Process all pages
def process_all_pages
  FileUtils.mkdir_p(BUILD_DIR)

  Dir.glob("#{PAGES_DIR}/*").each do |page|
    process_page(page)
  end

  copy_static_files
end

# Watch for changes and reload
def live_reload
  listener = Listen.to(PAGES_DIR, TEMPLATES_DIR, ASSETS_DIR) do |modified, added, removed|
    puts "Changes detected: #{modified + added + removed}"
    process_all_pages
  end

  puts 'Listening for file changes . . .'
  listener.start
  sleep
end

# Build the site initially and start live reloading
process_all_pages
live_reload
