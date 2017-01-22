require 'dry/core/inflector'

module ROM
  module SQL
    class Relation < ROM::Relation
      # Query API for SQL::Relation
      #
      # @api public
      module Reading
        # Fetch a tuple identified by the pk
        #
        # @example
        #   users.fetch(1)
        #   # {:id => 1, name: "Jane"}
        #
        # @return [Relation]
        #
        # @raise [ROM::TupleCountMismatchError] When 0 or more than 1 tuples were found
        #
        # @api public
        def fetch(pk)
          by_pk(pk).one!
        end

        # Return relation count
        #
        # @example
        #   users.count
        #   # => 12
        #
        # @return [Relation]
        #
        # @api public
        def count
          dataset.count
        end

        # Get first tuple from the relation
        #
        # @example
        #   users.first
        #   # {:id => 1, :name => "Jane"}
        #
        # @return [Hash]
        #
        # @api public
        def first
          dataset.first
        end

        # Get last tuple from the relation
        #
        # @example
        #   users.last
        #   # {:id => 2, :name => "Joe"}
        #
        # @return [Hash]
        #
        # @api public
        def last
          dataset.last
        end

        # Prefix all columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.prefix(:user).to_a
        #   # {:user_id => 1, :user_name => "Jane"}
        #
        # @param [Symbol] name The prefix
        #
        # @return [Relation]
        #
        # @api public
        def prefix(name = Dry::Core::Inflector.singularize(schema.name.dataset))
          schema.prefix(name).(self)
        end

        # Qualifies all columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.qualified.dataset.sql
        #   # SELECT "users"."id", "users"."name" ...
        #
        # @return [Relation]
        #
        # @api public
        def qualified
          schema.qualified.(self)
        end

        # Return a list of qualified column names
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.qualified_columns
        #   # [:users__id, :users__name]
        #
        # @return [Array<Symbol>]
        #
        # @api public
        def qualified_columns
          schema.qualified.map(&:to_sym)
        end

        # Map tuples from the relation
        #
        # @example
        #   users.map { |user| user[:id] }
        #   # [1, 2, 3]
        #
        #   users.map(:id).to_a
        #   # [1, 2, 3]
        #
        # @param [Symbol] key An optional name of the key for extracting values
        #                     from tuples
        #
        # @api public
        def map(key = nil, &block)
          if key
            dataset.map(key, &block)
          else
            dataset.map(&block)
          end
        end

        # Pluck values from a specific column
        #
        # @example
        #   users.pluck(:id)
        #   # [1, 2, 3]
        #
        # @return [Array]
        #
        # @api public
        def pluck(name)
          map(name)
        end

        # Project a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.project(:id, :name) }
        #
        # @param [Symbol] *names A list of symbol column names
        #
        # @return [Relation]
        #
        # @api public
        def project(*names)
          schema.project(*names).(self)
        end

        # Rename columns in a relation
        #
        # This method is intended to be used internally within a relation object
        #
        # @example
        #   users.rename(name: :user_name).first
        #   # {:id => 1, :user_name => "Jane" }
        #
        # @param [Hash<Symbol=>Symbol>] options A name => new_name map
        #
        # @return [Relation]
        #
        # @api public
        def rename(options)
          schema.rename(options).(self)
        end

        # Select specific columns for select clause
        #
        # @overload select(*columns)
        #   Project relation using column names
        #
        #   @example using column names
        #     users.select(:id, :name).first
        #     # {:id => 1, :name => "Jane"}
        #
        #   @param [Array<Symbol>] columns A list of column names
        #
        # @overload select(*attributes)
        #   Project relation using schema attributes
        #
        #   @example using attributes
        #     users.select(:id, :name).first
        #     # {:id => 1, :name => "Jane"}
        #
        #   @example using schema
        #     users.select(*schema.project(:id)).first
        #     # {:id => 1}
        #
        #   @param [Array<SQL::Type>] columns A list of schema attributes
        #
        # @overload select(&block)
        #   Project relation using projection DSL
        #
        #   @example using attributes
        #     users.select { id.as(:user_id) }
        #     # {:user_id => 1}
        #
        #     users.select { [id, name] }
        #     # {:id => 1, :name => "Jane"}
        #
        #   @example using SQL functions
        #     users.select { string::concat(id, '-', name).as(:uid) }.first
        #     # {:uid => "1-Jane"}
        #
        # @overload select(*columns, &block)
        #   Project relation using column names and projection DSL
        #
        #   @example using attributes
        #     users.select(:id) { int::count(id).as(:count) }.group(:id).first
        #     # {:id => 1, :count => 1}
        #
        #     users.select { [id, name] }
        #     # {:id => 1, :name => "Jane"}
        #
        #   @param [Array<SQL::Type>] columns A list of schema attributes
        #
        # @return [Relation]
        #
        # @api public
        def select(*args, &block)
          schema.project(*args, &block).(self)
        end

        # Append specific columns to select clause
        #
        # @see Relation#select
        #
        # @return [Relation]
        #
        # @api public
        def select_append(*args, &block)
          schema.merge(self.class.schema.project(*args, &block)).(self)
        end

        # Returns a copy of the relation with a SQL DISTINCT clause.
        #
        # @overload distinct(*columns)
        #   Create a distinct statement from column names
        #
        #   @example
        #     users.distinct(:country)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload distinct(&block)
        #   Create a distinct statement from a block
        #
        #   @example
        #     users.distinct { func(id) }
        #     # SELECT DISTINCT ON (count("id")) "id" ...
        #
        # @return [Relation]
        #
        # @api public
        def distinct(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Returns a result of SQL SUM clause.
        #
        # @example
        #   users.sum(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return [Integer]
        #
        # @api public
        def sum(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL MIN clause.
        #
        # @example
        #   users.min(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def min(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL MAX clause.
        #
        # @example
        #   users.max(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def max(*args)
          dataset.__send__(__method__, *args)
        end

        # Returns a result of SQL AVG clause.
        #
        # @example
        #   users.avg(:age)
        #
        # @param [Array<Symbol>] *args A list with column names
        #
        # @return Number
        #
        # @api public
        def avg(*args)
          dataset.__send__(__method__, *args)
        end

        # Restrict a relation to match criteria
        #
        # @overload where(conditions)
        #   Restrict a relation using a hash with conditions
        #
        #   @example
        #     users.where(name: 'Jane', age: 30)
        #
        #   @param [Hash] conditions A hash with conditions
        #
        # @overload where(conditions, &block)
        #   Restrict a relation using a hash with conditions and restriction DSL
        #
        #   @example
        #     users.where(name: 'Jane') { age > 18 }
        #
        #   @param [Hash] conditions A hash with conditions
        #
        # @overload where(&block)
        #   Restrict a relation using restriction DSL
        #
        #   @example
        #     users.where { age > 18 }
        #     users.where { (id < 10) | (id > 20) }
        #
        # @return [Relation]
        #
        # @api public
        def where(*args, &block)
          if block
            new(dataset.where(*args).where(self.class.schema.restriction(&block)))
          else
            new(dataset.__send__(__method__, *args))
          end
        end

        # Restrict a relation to not match criteria
        #
        # @example
        #   users.exclude(name: 'Jane')
        #
        # @param [Hash] *args A hash with conditions for exclusion
        #
        # @return [Relation]
        #
        # @api public
        def exclude(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Restrict a relation to match grouping criteria
        #
        # @example
        #   users.
        #     qualified.
        #     left_join(tasks).
        #     select { [id, name, int::count(:tasks__id).as(:task_count)] }.
        #     group(users[:id].qualified).
        #     having { count(id.qualified) >= 1 }.
        #     first
        #   # {:id => 1, :name => "Jane", :task_count => 2}
        #
        # @param [Hash] *args An optional hash with conditions for HAVING clause
        #
        # @return [Relation]
        #
        # @api public
        def having(*args, &block)
          if block
            new(dataset.having(*args).having(self.class.schema.restriction(&block)))
          else
            new(dataset.__send__(__method__, *args, &block))
          end
        end

        # Inverts the current WHERE and HAVING clauses. If there is neither a
        # WHERE or HAVING clause, adds a WHERE clause that is always false.
        #
        # @example
        #   users.exclude(name: 'Jane').invert
        #
        #   # this is the same as:
        #   users.where(name: 'Jane')
        #
        # @return [Relation]
        #
        # @api public
        def invert
          new(dataset.invert)
        end

        # Set order for the relation
        #
        # @overload order(*columns)
        #   Return a new relation ordered by provided columns (ASC by default)
        #
        #   @example
        #     users.order(:name, :id)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload order(*attributes)
        #   Return a new relation ordered by provided schema attributes
        #
        #   @example
        #     users.order(self[:name].qualified.desc, self[:id].qualified.desc)
        #
        #   @param [Array<SQL::Type>] attributes A list with schema attributes
        #
        # @overload order(&block)
        #   Return a new relation ordered using order DSL
        #
        #   @example using attribute
        #     users.order { id.desc }
        #     users.order { price.desc(nulls: :first) }
        #
        #   @example using a function
        #     users.order { nullif(name.qualified, `''`).desc(nulls: :first) }
        #
        # @return [Relation]
        #
        # @api public
        def order(*args, &block)
          if block
            new(dataset.order(*args, *self.class.schema.order(&block)))
          else
            new(dataset.__send__(__method__, *args, &block))
          end
        end

        # Reverse the order of the relation
        #
        # @example
        #   users.order(:name).reverse
        #
        # @return [Relation]
        #
        # @api public
        def reverse(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Limit a relation to a specific number of tuples
        #
        # @overload limit(num)
        #   Return a new relation with the limit set to the provided num
        #
        #   @example
        #     users.limit(1)
        #
        #   @param [Integer] num The limit value
        #
        # @overload limit(num, offset)
        #   Return a new relation with the limit set to the provided num
        #
        #   @example
        #     users.limit(10, 2)
        #
        #   @param [Integer] num The limit value
        #   @param [Integer] offset The offset value
        #
        # @return [Relation]
        #
        # @api public
        def limit(*args)
          new(dataset.__send__(__method__, *args))
        end

        # Set offset for the relation
        #
        # @example
        #   users.limit(10).offset(2)
        #
        # @param [Integer] num The offset value
        #
        # @return [Relation]
        #
        # @api public
        def offset(num)
          new(dataset.__send__(__method__, num))
        end

        # Join with another relation using INNER JOIN
        #
        # @overload join(dataset, join_conditions)
        #   Join with another relation using dataset name and join conditions
        #
        #   @example
        #     users.join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Join table name
        #   @param [Hash] join_conditions A hash with join conditions
        #
        # @overload join(dataset, join_conditions, options)
        #   Join with another relation using dataset name and join conditions
        #   with additional join options
        #
        #   @example
        #     users.join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Join table name
        #   @param [Hash] join_conditions A hash with join conditions
        #   @param [Hash] options Additional join options
        #
        # @overload join(relation)
        #   Join with another relation
        #
        #   Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.join(tasks)
        #
        #   @param [Relation] relation A relation for join
        #
        # @return [Relation]
        #
        # @api public
        def join(*args, &block)
          __join__(__method__, *args, &block)
        end
        alias_method :inner_join, :join

        # Join with another relation using LEFT OUTER JOIN
        #
        # @overload left_join(dataset, left_join_conditions)
        #   Left_Join with another relation using dataset name and left_join conditions
        #
        #   @example
        #     users.left_join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Left_Join table name
        #   @param [Hash] left_join_conditions A hash with left_join conditions
        #
        # @overload left_join(dataset, left_join_conditions, options)
        #   Left_Join with another relation using dataset name and left_join conditions
        #   with additional left_join options
        #
        #   @example
        #     users.left_join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Left_Join table name
        #   @param [Hash] left_join_conditions A hash with left_join conditions
        #   @param [Hash] options Additional left_join options
        #
        # @overload left_join(relation)
        #   Left_Join with another relation
        #
        #   Left_Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.left_join(tasks)
        #
        #   @param [Relation] relation A relation for left_join
        #
        # @return [Relation]
        #
        # @api public
        def left_join(*args, &block)
          __join__(__method__, *args, &block)
        end

        # Join with another relation using RIGHT JOIN
        #
        # @overload right_join(dataset, right_join_conditions)
        #   Right_Join with another relation using dataset name and right_join conditions
        #
        #   @example
        #     users.right_join(:tasks, id: :user_id)
        #
        #   @param [Symbol] dataset Right_Join table name
        #   @param [Hash] right_join_conditions A hash with right_join conditions
        #
        # @overload right_join(dataset, right_join_conditions, options)
        #   Right_Join with another relation using dataset name and right_join conditions
        #   with additional right_join options
        #
        #   @example
        #     users.right_join(:tasks, { id: :user_id }, { table_alias: :tasks_1 })
        #
        #   @param [Symbol] dataset Right_Join table name
        #   @param [Hash] right_join_conditions A hash with right_join conditions
        #   @param [Hash] options Additional right_join options
        #
        # @overload right_join(relation)
        #   Right_Join with another relation
        #
        #   Right_Join conditions are automatically set based on schema association
        #
        #   @example
        #     users.right_join(tasks)
        #
        #   @param [Relation] relation A relation for right_join
        #
        # @return [Relation]
        #
        # @api public
        def right_join(*args, &block)
          __join__(__method__, *args, &block)
        end

        # Group by specific columns
        #
        # @overload group(*columns)
        #   Return a new relation grouped by provided columns
        #
        #   @example
        #     tasks.group(:user_id)
        #
        #   @param [Array<Symbol>] columns A list with column names
        #
        # @overload group(*attributes)
        #   Return a new relation grouped by provided schema attributes
        #
        #   @example
        #     tasks.group(tasks[:id], tasks[:title])
        #
        #   @param [Array<SQL::Type>] columns A list with column names
        #
        # @return [Relation]
        #
        # @api public
        def group(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Group by specific columns and count by group
        #
        # @example
        #   tasks.group_and_count(:user_id)
        #   # => [{ user_id: 1, count: 2 }, { user_id: 2, count: 3 }]
        #
        # @param [Array<Symbol>] *args A list of column names
        #
        # @return [Relation]
        #
        # @api public
        def group_and_count(*args, &block)
          new(dataset.__send__(__method__, *args, &block))
        end

        # Select and group by specific columns
        #
        # @example
        #   tasks.select_group(:user_id)
        #   # => [{ user_id: 1 }, { user_id: 2 }]
        #
        # @param [Array<Symbol>] *args A list of column names
        #
        # @return [Relation]
        #
        # @api public
        def select_group(*args, &block)
          new_schema = schema.project(*args, &block)
          new_schema.(self).group(*new_schema)
        end

        # Adds a UNION clause for relation dataset using second relation dataset
        #
        # @example
        #   users.where(id: 1).union(users.where(id: 2))
        #   # => [{ id: 1, name: 'Piotr' }, { id: 2, name: 'Jane' }]
        #
        # @param [Relation] relation Another relation
        #
        # @param [Hash] options Options for union
        # @option options [Symbol] :alias Use the given value as the #from_self alias
        # @option options [TrueClass, FalseClass] :all Set to true to use UNION ALL instead of UNION, so duplicate rows can occur
        # @option options [TrueClass, FalseClass] :from_self Set to false to not wrap the returned dataset in a #from_self, use with care.
        #
        # @return [Relation]
        #
        # @api public
        def union(relation, options = EMPTY_HASH, &block)
          new(dataset.__send__(__method__, relation.dataset, options, &block))
        end

        # Return if a restricted relation has 0 tuples
        #
        # @example
        #   users.unique?(email: 'jane@doe.org') # true
        #
        #   users.insert(email: 'jane@doe.org')
        #
        #   users.unique?(email: 'jane@doe.org') # false
        #
        # @param [Hash] criteria The condition hash for  WHERE clause
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def unique?(criteria)
          where(criteria).count.zero?
        end

        # Return a new relation from a raw SQL string
        #
        # @example
        #   users.read('SELECT name FROM users')
        #
        # @param [String] sql The SQL string
        #
        # @return [SQL::Relation]
        #
        # @api public
        def read(sql)
          new(dataset.db[sql])
        end

        private

        # Common join method used by other join methods
        #
        # @api private
        def __join__(type, other, join_cond = EMPTY_HASH, opts = EMPTY_HASH, &block)
          case other
          when Symbol, Association::Name
            new(dataset.__send__(type, other.to_sym, join_cond, opts, &block))
          when Relation
            __send__(type, other.name.dataset, join_keys(other))
          else
            raise ArgumentError, "+other+ must be either a symbol or a relation, #{other.class} given"
          end
        end

        # Return join key conditions for the provided relation
        #
        # @api private
        def join_keys(other)
          other.associations[name].join_keys(__registry__)
        end
      end
    end
  end
end
