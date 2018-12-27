# coding: utf-8


require 'fileutils'
require 'kramdown'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class ArticleFileManager

  attr_reader :option

  ORIGINAL_DATA = File.read(File.dirname(__FILE__).encode("utf-8") + "/template.txt")

  def initialize(source_directory, output_directory, option)
    @source_directory = source_directory
    @output_directory = output_directory
    @files = []
    @option = option
    Dir.foreach(source_directory) do |path|
      if path != "." && path != ".." && path =~ /\.mdz$/
        file = ArticleFile.new(source_directory + "/" + path, self)
        @files << file
      end
    end
    @files.each do |file|
      file.determine_proof_file
      file.calculate_dependent_files
    end  
  end

  def sort_files
    sorted_files = []
    marks = {}
    visit = lambda do |file|
      if marks[file] == :temporary
        raise RuntimeError.new("[ERROR] The given graph has a cyclic path")
      end
      unless marks[file]
        marks[file] = :temporary
        file.dependent_files.each do |dependent_file, type|
          visit.call(dependent_file)
        end
        marks[file] = :permanent
        sorted_files.unshift(file)
      end
    end
    @files.each do |file|
      unless marks[file]
        visit.call(file)
      end
    end
    @files = sorted_files.reverse
  end

  def convert
    sort_files
    content = create_content
    node_script, edge_script = create_network
    File.open(@output_directory + "/result.html", "w") do |file|
      output = ORIGINAL_DATA.gsub(/#\{(.*?)\}/){self.instance_eval($1)}.gsub(/\r/, "")  
      file.print(output)
    end
  end

  def create_content
    content = ""
    @files.each do |file|
      if !file.hidden && (file.visible || @option[:comprehensive])
        content << file.full_output
      end
    end
    return content
  end

  def create_network
    node_scripts, edge_scripts = [], []
    @files.each do |file|
      if !file.hidden && (file.visible || @option[:comprehensive]) && file.box?
        node_script = ""
        node_script << "{"
        node_script << "  id: #{file.box_number},"
        node_script << "  label: \"#{file.box_number}\","
        node_script << "  title: $(\"#box-#{file.box_number}\").attr(\"explanation\"),"
        node_script << "  level: #{file.box_number} / 5,"
        node_script << "  color: {"
        node_script << "    background: $(\"#box-#{file.box_number}\").css(\"border-color\"),"
        node_script << "    highlight: {background: $(\"#box-#{file.box_number}\").css(\"border-color\")},"
        node_script << "  },"
        node_script << "}"
        node_scripts << node_script
        file.dependent_files.each do |dependent_file, type|
          if type == :actual
            edge_script = ""
            edge_script << "{"
            edge_script << "  from: #{file.box_number},"
            edge_script << "  to: #{dependent_file.box_number},"
            edge_script << "}"
            edge_scripts << edge_script
          end
        end
      end
    end
    return [node_scripts.join(","), edge_scripts.join(",")]
  end

  # query に与えられた検索クエリにマッチするファイルを 1 つ返します。
  # 現状では、検索クエリとしてはファイル名が使用できます。
  def search(query)
    @files.each do |file|
      if file.path.end_with?("/#{query}.mdz")
        return file
      end  
    end
    return nil
  end

  def search_reverse(target_file, type = nil)
    @files.each do |file|
      if !type || file.type == type
        if match = file.source.match(/^%\s*(#{type})<(.+?)>/)
          query = match[2]
          if search(query) == target_file
            return file
          end
        end
      end
    end
    return nil
  end

end


class ArticleFile

  attr_reader :path
  attr_reader :source
  attr_reader :type
  attr_reader :visible
  attr_reader :hidden
  attr_reader :box_number
  attr_reader :dependent_files

  PROVABLE_TYPES = ["THM", "PROP", "LEM", "COR"]
  PROOF_TYPE = "PROOF"
  BOX_TYPE_NAMES = {"DEF" => "定義", "THM" => "定理", "PROP" => "命題", "LEM" => "補題", "COR" => "系"}
  TEXT_TYPE_NAMES = {"SUPP" => "補足", "DIGR" => "余談"}

  @@box_number = 0
  @@proof_number = 0
  @@popup_number = 0

  def initialize(path, manager)
    @path = path
    @source = File.read(path)
    @title = nil
    @output = nil
    @type = nil
    @visible = true
    @hidden = false
    @box_number = -1
    @dependent_files = []
    @proof_file = nil
    @manager = manager
    detect_type
  end

  def detect_type
    if match = @source.match(/^%\s*([A-Z]+)(\?)?(?:<.+?>)?(?:\s*:\s*(.+))?$/)
      @type = match[1]
      @visible = !match[2]
      @title = match[3]
      if @type == PROOF_TYPE
        @hidden = true
      end
    end
  end

  def determine_proof_file
    if PROVABLE_TYPES.include?(@type)
      @proof_file = @manager.search_reverse(self, PROOF_TYPE)
    end
  end

  def calculate_dependent_files
    unless @type == PROOF_TYPE
      source = @source
      if @proof_file
        source += @proof_file.source
      end
      source.scan(/\[(.*?)\]<(.+?)>/) do |entry|
        preamble, query = entry
        dependent_file = @manager.search(query)
        if dependent_file
          type = (preamble.empty?) ? :provisional : :actual
          @dependent_files << [dependent_file, type]
        end
      end
      @dependent_files.uniq!
    end
  end

  def full_output
    full_output = "<div"
    if BOX_TYPE_NAMES.key?(@type)
      @box_number = @@box_number += 1
      full_output << " class=\"box box-#{@type.downcase} box-#{@box_number}\""
      full_output << " id=\"box-#{@box_number}\""
      if @title
        full_output << " before-content=\"#{BOX_TYPE_NAMES[@type]} #{@box_number}: #{@title}\" explanation=\"#{@title}\""
      else
        full_output << " before-content=\"#{BOX_TYPE_NAMES[@type]} #{@box_number}\""
      end
    elsif TEXT_TYPE_NAMES.key?(@type)
      full_output << " class=\"text text-#{@type.downcase}\""
      full_output << " before-content=\"#{TEXT_TYPE_NAMES[@type]}\""
    end
    full_output << ">"
    if @manager.option[:show_name]
      name = @path.match(/(?:\/|\\)(.+?)\.mdz/)[1]
      full_output << "<div class=\"name\">#{name}</div>"
    end
    full_output << self.output
    full_output << "</div>"
    return full_output
  end

  def output
    unless @output
      output = @source
      popup = ""
      output.gsub!(/^%\s*([A-Z]+)(\?)?(<.+?>)?.+$/, "")
      output.gsub!(/\[(.*?)\]<(.+?)>/) do
        text, query = $1, $2
        unless text.empty?
          matched_file = @manager.search(query)
          inner_output = ""
          if matched_file
            @@popup_number += 1
            popup << "<div class=\"popup\" id=\"popup-#{@@popup_number}\">"
            popup << matched_file.output
            popup << "</div>"
            inner_output << "<a onclick=\"showPopup($(this), #{@@popup_number})\">"
            inner_output << text
            if @manager.option[:show_popup_number]
              inner_output << "<span class=\"popup-number\">#{@@popup_number}</span>"
            end
            inner_output << "</a>"
          else
            inner_output << "<a>"
            inner_output << text
            inner_output << "</a>"
            $stderr.puts("[WARNING] The file '#{@path}' has an unmatched query: '#{query}'")
          end
          next inner_output
        else
          next ""
        end
      end
      output = Kramdown::Document.new(output).to_html
      output.gsub!("<script type=\"math/tex\">", "<script type=\"math/tex;mode=display\">")
      if @proof_file
        @@proof_number += 1
        output << "<div class=\"proof\">"
        output << "<a class=\"before\" onclick=\"toggleProof($(this), #{@@proof_number})\">証明:</a>"
        output << "<div class=\"proof-content\" id=\"proof-#{@@proof_number}\">"
        output << @proof_file.output
        output << "</div>"
        output << "</div>"
      end
      @output = output + popup
    end
    return @output
  end

  def box?
    return BOX_TYPE_NAMES.key?(@type)
  end

  def text?
    return TEXT_TYPE_NAMES.key?(@type)
  end

end