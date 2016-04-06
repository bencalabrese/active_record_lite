require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    relation = Relation.new(
      klass: self,
      where_pairs: params,
      from: table_name
    )
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end

class Relation
  attr_reader :opts

  def initialize(opts = {})
    defaults = {
      select: ["*"],
      from: [],
      where_pairs: {}
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
        #{where_line}
    SQL
  end

  def execute
    return cached_results[subquery] if cached_results[subquery]

    results = DBConnection.execute(subquery, where_vals)

    cached_results[subquery] = opts[:klass].parse_all(results)
  end

  def cached_results
    @cached_results ||= {}
  end

  def where_line
    opts[:where_pairs].map do |col, _|
      "#{opts[:from]}.#{col} = ?"
    end.join(" AND ")
  end

  def where_vals
    opts[:where_pairs].values
  end

# allows chaining
  def where(params)
    opts[:where_pairs].merge!(params)
  end

  def method_missing(*args)
    values = execute
    values.send(*args)
  end

  def ==(other_obj)
    values = execute
    values == other_obj
  end
end
