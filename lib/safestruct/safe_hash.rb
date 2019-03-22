# encoding: utf-8

module Safe

class SafeHash

  def self.debug?()      @debug ||= false; end
  def self.debug=(value) @debug = value; end


  ## e.g.
  ##  Hash.of( Address => Money )

  ##   note: need to create new class!! for every safe hash
  ##     make klass_key class and
  ##          klass_value class  into class instance variables
  ##     that can get used by zero
  ##       self.new returns a Hash.new/SafeHash.new like object

  def self.build_class( klass_key, klass_value )
    ## note: care for now only about value type / class

    ## note: keep a class cache
    cache = @@cache ||= {}
    klass = cache[ klass_value ]
    if debug?
      puts "[debug] SafeHash - build_class klass_value:"
      pp klass_value
      pp klass_value.to_s    ## note: for "anonymous" class something like #<Class:>
    end

    if klass.nil?
      if debug?
        puts "[debug] SafeHash - build_class new class (no cache hit)"
      end

      klass = Class.new( SafeHash )

      klass.define_singleton_method( :klass_key ) do
        @klass_key ||= klass_key
      end
      klass.define_singleton_method( :klass_value ) do
        @klass_value ||= klass_value
      end

      ### was:  - NOT working for "anonymous" classes e.g. klass_value.to_s starting with #<Class:>
      # klass.class_eval( <<RUBY )
      #  def self.klass_key
      #    @klass_key   ||= #{klass_key}
      #  end
      #  def self.klass_value
      #    @klass_value ||= #{klass_value}
      #  end
# RUBY

      ## add to cache for later (re)use
      cache[ klass_value ] = klass

      ## note: also add a Constant to Safe for easy debugging and (re)use - will "auto"name class
      ##   note: use X for now for key class name
      class_name = "Hash_X"

      name = klass_value.name
      name = name.sub( /\bSafe::/, '' )   ## remove safe module from name if present
      name = name.gsub( '::', '' )        ## remove module separator if present
      class_name << "_#{name}"
      if debug?
        puts "[debug] SafeHash - class_name >#{class_name}<"
      end
      Safe.const_set( class_name, klass )
    else
      if debug?
        puts "[debug] SafeHash - build_class bingo!! (re)use cached class:"
        pp klass
      end
    end

    klass
  end


  def self.new_zero()  new;  end
  def self.zero()      @zero ||= new_zero.freeze;  end

  def zero?() self == self.class.zero; end


  def initialize
    ## todo/check: if hash works if value is a (nested) hash
    @h = {}
  end

  def freeze
    super
    @h.freeze  ## note: pass on freeze to "wrapped" hash
    self   # return reference to self
  end

  def ==( other )
    if other.is_a?( self.class )                    ## note: must be same hash class
      @h == other.instance_variable_get( '@h' )    ## compare "wrapped" hash
    else
      false
    end
  end
  alias_method :eql?, :==




  def []=(key, value)
    @h[key] = value
  end

  def [](key)
    item = @h[ key ]
    if item.nil?
      ## pp self.class.klass_value
      ## pp self.class.klass_value.zero

      #####
      # todo/check:
      #    add zero to hash on lookup (increases size/length)
      #    why? why not?

      if self.class.klass_value.respond_to?( :new_zero )
        ## note: use a dup(licated) unfrozen copy of the zero object
        ##    changes to the object MUST be possible (new "empty" modifable object expected)
        item = @h[ key ] = self.class.klass_value.new_zero
      else  # assume value semantics e.g. Integer, Bool, etc. zero values gets replaced
        ## puts "use value semantics"
        item = @h[ key ] = self.class.klass_value.zero
      end
    end
    item
  end

  extend Forwardable
  def_delegators :@h, :has_key?, :key?, :delete, :clear

  ## note:  remove size and length for (safe) hash (for now) - follows solidity convention - why? why not?
  ##   :size, :length,

end # class SafeHash
end # module Safe
