require 'erb'
require 'fileutils'
require 'kramdown'
require 'listen'
require 'yaml'

ASSETS_DIR = './assets'
PAGES_DIR = './pages'
TEMPLATES_DIR = './templates'
BUILD_DIR = './site'
SHARED_DATA_FILE = './data.yml'

# Load shared data from YAML
def load_shared_data
  YAML.load_file(SHARED_DATA_FILE)
end

# Parse the front matter (YAML block) from a page file
def parse_front_matter(page_content)
  if page_content =~ /\A---\s*\n(.*?\n?)^---\s*$\n(.*)/m
    front_matter = YAML.safe_load($1)
    content = $2
  else
    front_matter = {}
    content = page_content
  end
  return front_matter, content
end

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
def process_page(page, shared_data)
  page_content = File.read(page)

  # Extract front matter and actual content
  page_data, content = parse_front_matter(page_content)

  # Convert Markdown content to HTML if applicable
  html_content = if File.extname(page) == '.md'
                   render_markdown(content)
                 else
                   content
                 end

  # Merge shared data and per-page data
  all_data = shared_data.merge(page_data)

  # Render the page using the layout template, passing in shared + page-specific data
  layout_content = render_template('layout.erb', all_data.merge(content: html_content))

  # Save the rendered content to the build directory
  output_filename = File.basename(page, '.*') + '.html'
  File.write(File.join(BUILD_DIR, output_filename), layout_content)

  puts "Generated: #{output_filename}"
end

# Copy static files from `assets/` to `site/`
def copy_static_files
  FileUtils.mkdir_p(BUILD_DIR)
  FileUtils.cp_r(ASSETS_DIR, BUILD_DIR) if Dir.exist?(ASSETS_DIR)
  puts 'Static files copied.'
end

# Process all pages
def process_all_pages
  FileUtils.mkdir_p(BUILD_DIR)

  # Load shared data
  shared_data = load_shared_data

  # Process each page
  Dir.glob("#{PAGES_DIR}/*").each do |page|
    process_page(page, shared_data)
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
