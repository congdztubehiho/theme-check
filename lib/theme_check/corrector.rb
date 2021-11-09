# frozen_string_literal: true

module ThemeCheck
  class Corrector
    def initialize(theme_file:)
      @theme_file = theme_file
    end

    def insert_after(node, content)
      @theme_file.rewriter.insert_after(node, content)
    end

    def insert_before(node, content)
      @theme_file.rewriter.insert_before(node, content)
    end

    def replace(node, content)
      @theme_file.rewriter.replace(node, content)
      node.markup = content
    end

    def replace_block_body(node, content)
      content = "\n  #{JSON.pretty_generate(content, array_nl: "\n  ", object_nl: "\n  ")}\n" if content.is_a?(Hash)
      @theme_file.rewriter.replace_body(node, content)
    end

    def wrap(node, insert_before, insert_after)
      @theme_file.rewriter.wrap(node, insert_before, insert_after)
    end

    def create(theme, relative_path, content)
      theme.storage.write(relative_path, content)
    end

    def create_default_locale_json(theme)
      create(theme, "locales/#{theme.default_locale}.default.json", {})
      theme.default_locale_json = JsonFile.new("locales/#{theme.default_locale}.default.json", theme.storage)
    end

    def remove(theme, relative_path)
      theme.storage.remove(relative_path)
    end

    def mkdir(theme, relative_path)
      theme.storage.mkdir(relative_path)
    end

    def add_default_translation_key(file, key, value)
      hash = file.content
      add_key(hash, key, value)
      file.update_contents(hash)
    end

    def remove_key(hash, key)
      key.reduce(hash) do |pointer, token|
        return pointer.delete(token) if token == key.last
        pointer[token]
      end
    end

    def add_key(hash, key, value)
      key.reduce(hash) do |pointer, token|
        return pointer[token] = value if token == key.last
        pointer[token] = {} unless pointer.key?(token)
        pointer[token]
      end
    end

    def schema_corrector(schema, key, value)
      return unless schema.is_a?(Hash)
      key.reduce(schema) do |pointer, token|
        case pointer
        when Array
          pointer.each do |item|
            schema_corrector(item, key.drop(1), value)
          end

        when Hash
          return pointer[token] = value if token == key.last
          pointer[token] = {} unless pointer.key?(token) || pointer.key?("id")
          pointer[token].nil? && pointer["id"] == token ? pointer : pointer[token]
        end
      end
    end
  end
end
