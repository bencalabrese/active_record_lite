require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    source_options =
      through_options.model_class.assoc_options[source_name]


    define_method(name) do
      from_line = <<-SQL
        #{through_options.table_name}
        JOIN #{source_options.table_name}
        ON #{source_options.table_name}.#{through_options.primary_key} =
        #{through_options.table_name}.#{source_options.foreign_key}
      SQL

      where_line = <<-SQL
        #{through_options.table_name}.#{through_options.primary_key} =
        #{self.send(through_options.foreign_key)}
      SQL

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{from_line}
        WHERE
          #{where_line}
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
