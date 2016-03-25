require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map do |col, _|
      "#{table_name}.#{col} = ?"
    end.join(" AND ")

    where_vals = params.values

    relation = Relation.new(
      where_line: where_line,
      where_vals: where_vals,
      from: table_name,
    )

    relation.execute.map { |result| new(result) }
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end

class Relation < SQLObject
  attr_reader :opts

  def initialize(opts = {})
    defaults = {
      select: ["*"],
      from: [],
      where_line: [],
      where_vals: [],
    }

    @opts = defaults.merge(opts)
  end

  def subquery
    <<-SQL
      SELECT
        #{opts[:select].join(", ")}
      FROM
        #{opts[:from]}
      WHERE
        #{opts[:where_line]}
    SQL
  end

  def table_name
    "(#{self.subquery})"
  end

  def execute
    return cached_results[subquery] if cached_results[subquery]

    results = DBConnection.execute(subquery, opts[:where_vals])

    cached_results[subquery] = results
  end

  def cached_results
    @cached_results ||= {}
  end
end
