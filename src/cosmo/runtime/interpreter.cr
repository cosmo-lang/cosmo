MAX_FN_PARAMS = 255

require "../syntax/parser"
require "./hooked_exceptions"
require "./types/function"
require "./types/class"
require "./types/type"
require "./scope"
require "./operator"
require "./resolver"
require "./intrinsic"

class Cosmo::Interpreter
  include Expression::Visitor(ValueType)
  include Statement::Visitor(ValueType)

  private alias MetaType = String | ClassInstance

  getter globals = Scope.new
  getter scope : Scope
  getter meta = {} of String => MetaType
  getter file_path : String = ""
  setter max_recursion_depth : UInt32 = 1200
  property within_fn = false
  @locals = {} of Expression::Base => UInt32
  @importable_intrinsics = {} of String => Intrinsic::Lib
  @evaluating_fn_callee = false
  @loop_level : UInt32 = 0
  @recursion_depth : UInt32 = 1

  def initialize(
    @output_ast : Bool,
    @run_benchmarks : Bool
  )
    TypeChecker.register_intrinsics

    @scope = @globals
    declare_globals
  end

  private def declare_globals
    declare_intrinsic("func", "puts", Intrinsic::Puts.new(self))
    declare_intrinsic("func", "gets", Intrinsic::Gets.new(self))
    declare_intrinsic("func", "eval", Intrinsic::Eval.new(self))
    declare_intrinsic("func", "recursion_depth!", Intrinsic::RecursionDepth.new(self))

    import_file(File.join(File.dirname(__FILE__), "../../../libraries/intrinsic.⭐"), [] of Token)

    version = "Cosmo #{Version}"
    declare_intrinsic("string", "version$", version)

    Intrinsic::MathLib.new(self).inject
    declare_importable("http", Intrinsic::HttpLib.new(self))
    declare_importable("socket", Intrinsic::SocketLib.new(self))
    declare_importable("system", Intrinsic::SystemLib.new(self))
  end

  private def declare_importable(name : String, library : Intrinsic::Lib)
    @importable_intrinsics[name] = library
  end

  def fake_typedef(name : String, location : Location? = nil)
    Token.new(name, Syntax::TypeDef, name, location || Location.new(@file_path, 0, 0))
  end

  def fake_ident(name : String, location : Location? = nil)
    Token.new(name, Syntax::Identifier, name, location || Location.new(@file_path, 0, 0))
  end

  def declare_intrinsic(type : String, ident : String, value : ValueType)
    location = Location.new("intrinsic", 0, 0)
    ident_token = fake_ident(ident, location)
    typedef_token = fake_typedef(type, location)
    @globals.declare(typedef_token, ident_token, value, mutable: true)
  end

  def delete_meta(key : String) : Nil
    @meta.delete(key)
  end

  def set_meta(key : String, value : MetaType?) : Nil
    return if value.nil?
    @meta[key] = value
  end

  def start_recursion(token : Token)
    @recursion_depth += 1
    if @recursion_depth >= @max_recursion_depth
      Logger.report_error("Stack overflow", "Recursion depth of #{@max_recursion_depth} exceeded", token)
    end
  end

  def end_recursion(level : UInt32 = 1)
    @recursion_depth -= level
  end

  private def within_class_body? : Bool
    @meta.has_key?("this") && !@within_fn
  end

  def interpret(source : String, @file_path : String) : ValueType
    parser = Parser.new(source, @file_path, @run_benchmarks)
    statements = parser.parse

    statement_list_str = ""
    statements.each do |stmt|
      statement_list_str += stmt.to_s + "\n"
    end

    puts statement_list_str if @output_ast

    resolver = Resolver.new(self)
    resolver.resolve(statements)
    end_time = Time.monotonic
    puts "Resolver @#{@file_path} took #{get_elapsed(resolver.start_time, end_time)}." if @run_benchmarks

    start_time = Time.monotonic

    result = nil
    statements.each do |stmt|
      result = execute(stmt)
    end

    main_result = execute_main
    end_time = Time.monotonic
    puts "Interpreter @#{file_path} took #{get_elapsed(start_time, end_time)}." if @run_benchmarks

    if !main_result.nil? && @file_path != "test" && @file_path != "repl"
      code = main_result.not_nil!
      if code == 0 # success
        Process.exit(code)
      else
        raise "Process exited with code #{code}"
      end
    end

    result
  end

  def resolve(expr : Expression::Base, depth : UInt32) : Nil
    @locals[expr] = depth
  end

  # Check if a "main" fn exists and call it
  def execute_main : Int64?
    main_fn = @globals.lookup?("main")
    is_public = @globals.public?("main")
    found_main = !main_fn.nil? && main_fn.is_a?(Function)

    if found_main
      if is_public
        main_fn = main_fn.as(Function)
        return_typedef = main_fn.return_typedef
        unless TypeChecker.is?(return_typedef.lexeme, 1, return_typedef) # it's an integer
          Logger.report_error("Invalid main() function", "A main() function may only return 'int'", return_typedef)
        end

        main_result = main_fn.call([ARGV.map(&.as ValueType)])
        if main_result.nil?
          Logger.report_error("Invalid main() function", "Your main() function did not return an 'int'", return_typedef)
        end

        TypeChecker.assert("int", main_result, return_typedef)
        main_result.as Int64
      else
        puts "[WARNING]: Found main() function, but it is not public. It will not be called on program execution."
      end
    end
  end

  private def lookup_variable(identifier : Token, expr : Expression::Base) : ValueType
    distance : UInt32? = @locals[expr]?
    return @scope.lookup_at(distance, identifier) unless distance.nil?
    @globals.lookup(identifier)
  end

  def evaluate(expr : Expression::Base) : ValueType
    expr.accept(self)
  end

  def execute(stmt : Statement::Base) : ValueType
    stmt.accept(self)
  end

  def execute_block(block : Statement::Base, block_scope : Scope, is_fn : Bool = false) : ValueType
    enclosing = @scope
    begin
      @scope = block_scope

      unless @meta["this"]?.nil? || !@scope.lookup?("$").nil?
        this = @meta["this"].as(ClassInstance)
        @scope.declare(
          fake_typedef(this.name),
          fake_ident("$"),
          this,
          mutable: true
        )
      end

      if block.is_a?(Statement::Block)
        return nil if block.empty?
        unless block.nodes.empty?
          return_node = block.nodes.find { |node| node.is_a?(Statement::Return) } || block.nodes.last
          body_nodes = block.nodes[0..-2]
          body_nodes.each { |stmt| execute(stmt) }
          return_value = execute(return_node) unless return_node.nil?
        end
        if is_fn
          return_type = @meta["block_return_type"]
          token = return_node.nil? ? block.token : return_node.token
          unless return_type.to_s == "void"
            TypeChecker.assert(return_type.to_s, return_value, token)
          end
        end
      else
        return_value = execute(block)
      end

      return return_value unless return_type.to_s == "void"
      nil
    rescue ex : Exception
      raise ex
    ensure
      @scope = enclosing
    end
  end

  private def import_file(path : String, imports : Array(Token)) : Nil
    source = File.read(path)

    enclosing = @scope
    @scope = Scope.new(@scope)
    interpret(source, path)

    if imports.empty?
      globals.extend(@scope)
    else
      selected_scope = Scope.new
      imports.each do |import|
        selected_scope.declare(
          fake_typedef("any"),
          import,
          @scope.lookup(import),
          mutable: false,
          visibility: Visibility::Public
        ) if @scope.public?(import.lexeme)
      end

      globals.extend(selected_scope)
    end

    @scope = enclosing
  end

  def visit_use_stmt(stmt : Statement::Use) : Nil
    relative_module_path = stmt.module_path.lexeme
    Logger.push_trace(stmt.keyword)

    imports = stmt.imports
    unless relative_module_path.includes?("/")
      unless @importable_intrinsics.has_key?(relative_module_path)
        file_path = File.join File.dirname(__FILE__), "../../../libraries", relative_module_path
        path_with_ext = file_path + (File.exists?(file_path + ".cos") ? ".cos" : ".⭐")

        if File.exists?(path_with_ext)
          return import_file(path_with_ext, imports)
        end

        pkg_path = File.join File.dirname(__FILE__), "../../../pkg", relative_module_path
        if File.exists?(pkg_path)
          pkg_path = File.join(pkg_path, "src", relative_module_path)
          main_file = pkg_path + (File.exists?(pkg_path + ".cos") ? ".cos" : ".⭐")
          unless File.exists?(main_file)
            pkg_path = pkg_path.rchop(relative_module_path) + "main"
            main_file = pkg_path + (File.exists?(pkg_path + ".cos") ? ".cos" : ".⭐")
          end

          return import_file(main_file, imports)
        end

        Logger.report_error("Failed to resolve '#{relative_module_path}'", "Could not find package. Please run 'stars install' and try again.", stmt.module_path)
      else
        @importable_intrinsics[relative_module_path].inject
      end
    else
      if @file_path == "repl"
        Logger.report_error("Cannot import", "Local modules are not supported in the REPL", stmt.module_path)
      end

      full_module_path = File.join File.dirname(@file_path), relative_module_path
      ext_file_path = File.exists?(full_module_path + ".cos") ? full_module_path + ".cos" : full_module_path + ".⭐"
      if full_module_path.includes?("././")
        Logger.report_error("Recursive import detected", ext_file_path.gsub("./", ""), stmt.module_path)
      end

      module_path = ext_file_path.gsub("./", "")
      unless File.exists?(ext_file_path)
        Logger.report_error("Cannot import", "No such file '#{module_path.split('.', 2).first}.cos/⭐' exists", stmt.module_path)
      end

      import_file(ext_file_path, imports)
    end
  end

  def visit_case_stmt(stmt : Statement::Case) : ValueType
    value = evaluate(stmt.value)
    go_to_else = false

    stmt.comparisons.each do |when_stmt|
      condition = true
      when_stmt.conditions.each do |condition_expr|
        if condition_expr.is_a?(Expression::TypeRef)
          condition &= TypeChecker.is?(condition_expr.name.lexeme, value, when_stmt.token)
        else
          condition &= evaluate(condition_expr) == value
        end
      end

      return execute(when_stmt.block) if condition
      go_to_else = true
    end

    return execute(stmt.else.not_nil!) if !stmt.else.nil? && go_to_else
  end

  def visit_throw_stmt(stmt : Statement::Throw) : Nil
    err = evaluate(stmt.err)
    Logger.push_trace(stmt.keyword)

    unless TypeChecker.is?("Exception", err, stmt.token)
      Logger.report_error("Invalid throw argument", "Throw statement can only be invoked with Exception, or a subclass of it. Got: #{TypeChecker.get_mapped(err.class)}", stmt.token)
    end

    err = err.as ClassInstance
    level = err.get_field(
      "level",
      stmt.keyword,
      include_private: true
    ).as(Int).to_u
    message = err.get_field(
      "message",
      stmt.keyword,
      include_private: true
    ).to_s

    raise HookedExceptions::Throw.new(stmt.keyword, err) if @trying
    Logger.trace_level = level unless @trying
    Logger.report_error("Unhandled #{err.name}", message, stmt.token) # replace "Error" with exception class name
  end

  def visit_next_stmt(stmt : Statement::Next) : Nil
    raise HookedExceptions::Next.new(stmt.keyword, @loop_level)
  end

  def visit_break_stmt(stmt : Statement::Break) : Nil
    raise HookedExceptions::Break.new(stmt.keyword, @loop_level)
  end

  def visit_return_stmt(stmt : Statement::Return) : Nil
    value = evaluate(stmt.value)
    raise HookedExceptions::Return.new(stmt.keyword, value)
  end

  def visit_until_stmt(stmt : Statement::Until) : Nil
    @loop_level += 1
    level : UInt32 = 0

    until evaluate(stmt.condition)
      start_recursion(stmt.keyword)
      level += 1

      begin
        execute(stmt.block)
      rescue _break : HookedExceptions::Break
        break if @loop_level == _break.loop_level
      rescue _next : HookedExceptions::Next
        next if @loop_level == _next.loop_level
      end
    end

    @loop_level -= 1
    end_recursion(level)
  end

  def visit_while_stmt(stmt : Statement::While) : Nil
    @loop_level += 1
    level : UInt32 = 0

    while evaluate(stmt.condition)
      start_recursion(stmt.keyword)
      level += 1

      begin
        execute(stmt.block)
      rescue _break : HookedExceptions::Break
        break if @loop_level == _break.loop_level
      rescue _next : HookedExceptions::Next
        next if @loop_level == _next.loop_level
      end
    end

    @loop_level -= 1
    end_recursion(level)
  end

  def visit_every_stmt(stmt : Statement::Every) : Nil
    enclosing = @scope
    @scope = Scope.new(@scope)

    enumerable = evaluate(stmt.enumerable)
    @scope.declare(stmt.var.typedef, stmt.var.token, nil, mutable: true)

    @loop_level += 1
    level : UInt32 = 0

    if enumerable.is_a?(Int)
      enumerable = 0 .. (enumerable - 1)
    end

    if enumerable.is_a?(Array) || enumerable.is_a?(Range)
      enumerable.each do |value|
        @scope.assign(stmt.var.token, value)
        start_recursion(stmt.keyword)
        level += 1

        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break if @loop_level == _break.loop_level
        rescue _next : HookedExceptions::Next
          next if @loop_level == _next.loop_level
        end
      end
    elsif enumerable.is_a?(String)
      enumerable.chars.each do |value|
        @scope.assign(stmt.var.token, value)
        start_recursion(stmt.keyword)
        level += 1

        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break if @loop_level == _break.loop_level
        rescue _next : HookedExceptions::Next
          next if @loop_level == _next.loop_level
        end
      end
    elsif enumerable.is_a?(Callable)
      if enumerable.intrinsic?
        Logger.report_error("Invalid iterator", "An iterator cannot be an intrinsic function", stmt.enumerable.token)
      end
      unless enumerable.is_a?(Function)
        Logger.report_error("Invalid iterator", "An iterator must return a generator function", stmt.enumerable.token)
      end

      # keep looping until the iterator returns none
      until (value = enumerable.call([] of ValueType)).nil?
        @scope.assign(stmt.var.token, value)
        start_recursion(stmt.keyword)
        level += 1

        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break if @loop_level == _break.loop_level
        rescue _next : HookedExceptions::Next
          next if @loop_level == _next.loop_level
        end
      end
    else
      Logger.report_error("Invalid iterator type", TypeChecker.get_mapped(enumerable.class), stmt.token)
    end

    @loop_level -= 1
    end_recursion(level)
    @scope = enclosing
  end

  def visit_unless_stmt(stmt : Statement::Unless) : ValueType
    condition = evaluate(stmt.condition)
    unless condition
      execute(stmt.then)
    else
      execute(stmt.else.not_nil!) unless stmt.else.nil?
    end
  end

  def visit_if_stmt(stmt : Statement::If) : ValueType
    condition = evaluate(stmt.condition)
    if condition
      execute(stmt.then)
    else
      execute(stmt.else.not_nil!) unless stmt.else.nil?
    end
  end

  def visit_try_catch_stmt(stmt : Statement::TryCatch) : Nil
    trace_idx = Logger.push_trace(stmt.try_keyword)
    enclosing = @trying
    begin
      @trying = true
      execute(stmt.try_block)
    rescue ex : HookedExceptions::Throw
      @scope.declare(stmt.caught_exception.typedef, stmt.caught_exception.token, ex.value)
      execute(stmt.catch_block)
    ensure
      @trying = enclosing
      unless stmt.finally_block.nil?
        execute(stmt.finally_block.not_nil!)
      end
    end
    Logger.pop_trace(trace_idx)
  end

  def visit_class_def_stmt(stmt : Statement::ClassDef) : ValueType
    unless @scope.lookup?(stmt.identifier.lexeme).nil?
      Logger.report_error("Cannot redefine class", "Class '#{stmt.identifier.lexeme}' is already defined", stmt.identifier)
    end

    unless stmt.superclass.nil?
      superclass = evaluate(stmt.superclass.not_nil!)

      unless superclass.is_a?(Class)
        Logger.report_error(
          "Invalid superclass",
          "Expected class to extend '#{stmt.identifier.lexeme}', got '#{TypeChecker.get_mapped(superclass.class)}'",
          stmt.superclass.not_nil!.token
        )
      end
    end

    _class = Class.new(self, @scope, stmt, superclass)
    @scope.declare(
      fake_typedef("class"),
      stmt.identifier,
      _class,
      mutable: false,
      visibility: stmt.visibility
    )
  end

  def visit_fn_def_stmt(stmt : Statement::FunctionDef) : ValueType
    if @meta.has_key?("this")
      instance = @meta["this"].as ClassInstance
      instance.define_method(
        stmt.identifier.lexeme,
        Function.new(self, @scope, stmt, instance),
        token: stmt.token,
        visibility: stmt.visibility
      )
    else
      @scope.declare(
        fake_typedef("func"),
        stmt.identifier,
        Function.new(self, @scope, stmt),
        mutable: false,
        visibility: stmt.visibility
      )
    end
  end

  def visit_lambda_expr(expr : Expression::Lambda) : ValueType
    Function.new(self, @scope, expr)
  end

  def visit_access_expr(expr : Expression::Access) : ValueType
    object = evaluate(expr.object)
    return nil if object.nil? && expr.nullable?

    key = expr.key.lexeme
    if object.is_a?(Hash)
      value = object[key]?
      if value.nil?
        fn = Intrinsic::Table.new(self, object)
          .get_method(expr.key, required: false)

        unless fn.nil?
          return fn.arity.begin == 0 && !@evaluating_fn_callee ?
            fn.call([] of ValueType)
            : fn
        end
        Logger.report_error("Invalid table key", "'#{key}'", expr.key)
      else
        if value.is_a?(Callable) && value.arity.begin == 0 && !@evaluating_fn_callee
          value.call([] of ValueType)
        else
          value
        end
      end
    elsif object.is_a?(Array)
      fn = Intrinsic::Vector.new(self, object)
        .get_method(expr.key)

      fn.arity.begin == 0 && !@evaluating_fn_callee ?
        fn.call([] of ValueType)
        : fn
    elsif object.is_a?(String)
      fn = Intrinsic::Strings.new(self, object)
        .get_method(expr.key)

      fn.arity.begin == 0 && !@evaluating_fn_callee ?
        fn.call([] of ValueType)
        : fn
    elsif object.is_a?(Range)
      fn = Intrinsic::Ranges.new(self, object)
        .get_method(expr.key)

      fn.arity.begin == 0 && !@evaluating_fn_callee ?
        fn.call([] of ValueType)
        : fn
    elsif object.is_a?(Number)
      fn = Intrinsic::Numbers.new(self, object)
        .get_method(expr.key)

      return fn unless fn.arity.begin == 0 && !@evaluating_fn_callee
      begin
        fn.call([] of ValueType)
      rescue ex : OverflowError
        Logger.report_error("Arithmetic overflow", "Number exceeded its bounds", expr.token)
      end
    elsif object.is_a?(ClassInstance)
      value = object.get_member(
        key, expr.key,
        include_private: @meta.has_key?("this"),
        field_required: key != "to_string" # expand into base object type methods
      )

      if value.is_a?(Callable) && value.arity.begin == 0 && !@evaluating_fn_callee
        value.call([] of ValueType)
      else # did not find a function
        key == "to_string" ? object.name : value # it's a field, so return the value if it's not to_string
      end
    else
      Logger.report_error("Attempt to index", TypeChecker.get_mapped(object.class), expr.token)
    end
  end

  def visit_index_expr(expr : Expression::Index) : ValueType
    object = evaluate(expr.object)
    key = evaluate(expr.key)

    if object.is_a?(String) || object.is_a?(Array)
      unless key.is_a?(Int) || key.is_a?(Range)
        Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), expr.key.token)
      end

      value = object[key]?
      if value.nil? && !expr.nullable?
        Logger.report_error("Index out of bounds", "Index #{key}, array size #{object.size}", expr.key.token)
      end
      value
    elsif object.is_a?(Hash)
      value = object[key]?
      if value.nil? && !expr.nullable?
        Logger.report_error("Invalid table key", "'#{key}'", expr.key.token)
      end
      value
    elsif object.is_a?(ClassInstance)
      Logger.report_error("Attempt to index class instance", expr.token.lexeme, expr.token)
    else
      Logger.report_error("Attempt to index", TypeChecker.get_mapped(object.class), expr.token)
    end
  end

  def visit_new_expr(expr : Expression::New) : ClassInstance
    class_obj = @scope.lookup(expr.operand.token)
    trace_idx = Logger.push_trace(expr.token)

    args = [] of Expression::Base
    unless class_obj.is_a?(Class)
      Logger.report_error("Invalid 'new' invocation", "Expected a class name, got '#{expr.operand.token.lexeme}'", expr.operand.token)
    end
    if expr.operand.is_a?(Expression::FunctionCall)
      args = expr.operand.as(Expression::FunctionCall).arguments
    end

    TypeChecker.assert("class", class_obj, expr.operand.token)
    arg_values = args.map { |arg| evaluate(arg) }
    instance = class_obj.construct(arg_values)

    Logger.pop_trace(trace_idx)
    instance
  end

  def visit_this_expr(expr : Expression::This) : ClassInstance
    instance = @scope.lookup?("$").as ClassInstance?

    if instance.nil?
      Logger.report_error("Invalid '$'", expr.token.lexeme, expr.token)
    end

    instance
  end

  def visit_cast_expr(expr : Expression::Cast) : ValueType
    value = evaluate(expr.value)
    TypeChecker.cast(value, expr.type.name)
  end

  def visit_is_in_expr(expr : Expression::IsIn) : Bool
    value = evaluate(expr.value)
    object = evaluate(expr.object)
    is_in = false

    if object.is_a?(Array)
      is_in = object.includes?(value)
    else
      ## expected vector or table
      Logger.report_error("Invalid 'is in' operand", "Expected vector, got '#{TypeChecker.get_mapped(value.class)}'", expr.token)
    end

    expr.inversed? ? !is_in : is_in
  end

  def visit_is_expr(expr : Expression::Is) : Bool
    value = evaluate(expr.value)
    is = TypeChecker.is?(expr.type.name.lexeme, value, expr.token)
    expr.inversed? ? !is : is
  end

  def visit_type_ref_expr(expr : Expression::TypeRef) : Type
    TypeChecker.get_registered_type(expr.name.lexeme, expr.name)
  end

  def visit_type_alias_expr(expr : Expression::TypeAlias) : Nil
    value = evaluate(expr.value)
    @scope.declare(expr.type_token, expr.token, value, expr.mutable?, expr.visibility)
  end

  def visit_fn_call_expr(expr : Expression::FunctionCall) : ValueType
    enclosing = @evaluating_fn_callee
    @evaluating_fn_callee = true

    token = expr.token.dup
    if expr.callee.is_a?(Expression::Access)
      token.lexeme = expr.callee.as(Expression::Access).full_path
    end
    token.lexeme += "(#{expr.arguments.empty? ? "" : "..."})"

    if expr.callee.is_a?(Expression::Access) || expr.callee.is_a?(Expression::Index)
      object_node = expr.callee.is_a?(Expression::Access) ?
        expr.callee.as(Expression::Access).object
        : expr.callee.as(Expression::Index).object

      object = evaluate(object_node)
      if object.is_a?(ClassInstance)
        instance_override = object
      end
    end

    fn = evaluate(expr.callee)
    @evaluating_fn_callee = enclosing

    unless fn.is_a?(Callable)
      Logger.report_error("Attempt to call", TypeChecker.get_mapped(fn.class), expr.token)
    end

    arg_values = expr.arguments.map { |arg| evaluate(arg) }
    unless fn.arity.includes?(arg_values.size) || !arg_values.select(&.is_a?(Spread)).empty?
      arg_size = fn.arity.begin == fn.arity.end ? fn.arity.begin : fn.arity
      Logger.report_error("Expected #{arg_size.to_s} arguments, got", arg_values.size.to_s, expr.token)
    end

    trace_idx = Logger.push_trace(token)
    if fn.is_a?(Function)
      result = fn.call(arg_values, class_instance_override: instance_override)
    else
      result = fn.call(fn.expand_args(arg_values))
    end

    Logger.pop_trace(trace_idx)
    result
  end

  def visit_var_expr(expr : Expression::Var) : ValueType
    value = @scope.lookup(expr.token)
    if value.is_a?(Callable) && value.arity.begin == 0 && !@evaluating_fn_callee
      value = value.call([] of ValueType)
    end
    value
  end

  def visit_var_declaration_expr(expr : Expression::VarDeclaration) : ValueType
    if @meta.has_key?("this") && expr.class_field?
      instance = @meta["this"].as ClassInstance
      instance.define_field(
        expr.var.token.lexeme,
        evaluate(expr.value),
        expr.token,
        visibility: expr.visibility,
        mutable: expr.mutable?,
        typedef: expr.typedef
      )
    else
      @scope.declare(
        expr.typedef,
        expr.var.token,
        evaluate(expr.value),
        mutable: expr.mutable?,
        visibility: expr.visibility
      )
    end
  end

  def visit_multiple_declaration_expr(expr : Expression::MultipleDeclaration) : Array(ValueType)
    resultant_values = [] of ValueType

    expr.declarations.each do |declaration|
      resultant_values << evaluate(declaration)
    end

    resultant_values
  end

  def visit_var_assignment_expr(expr : Expression::VarAssignment) : ValueType
    value = expr.value.is_a?(Expression::Base) ? evaluate(expr.value.as Expression::Base) : expr.value
    @scope.assign(expr.var.token, TypeChecker.as_value_type(value))
  end

  def visit_multiple_assignment_expr(expr : Expression::MultipleAssignment) : Array(ValueType)
    values = [] of ValueType
    expr.assignments.each do |assignment|
      if assignment.is_a?(Expression::VarAssignment)
        if assignment.value.is_a?(Expression::Base)
          values << evaluate(assignment.value.as Expression::Base)
        else
          values << assignment.value.as ValueType
        end
      elsif assignment.is_a?(Expression::PropertyAssignment)
        if assignment.value.is_a?(Expression::Base)
          values << evaluate(assignment.value.as Expression::Base)
        else
          values << assignment.value.as ValueType
        end
      end
    end

    resolved_assignments = expr.assignments.map_with_index do |assignment, i|
      if assignment.is_a?(Expression::VarAssignment)
        assignment.value = values[i]
      elsif assignment.is_a?(Expression::PropertyAssignment)
        assignment.value = values[i]
      end
      assignment
    end

    resultant_values : Array(ValueType) = resolved_assignments.map do |assignment|
      evaluate(assignment)
    end

    resultant_values
  end

  def add_object_value(token : Token, object : V, key : ValueType, value : ValueType) : V forall V
    if object.is_a?(Array)
      unless key.is_a?(Int)
        Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), token)
      end
      if object[key]?.nil?
        object.insert(key, value)
      else
        object[key] = value
      end
    elsif object.is_a?(Hash)
      object[key] = value
    elsif object.is_a?(ClassInstance)
      unless key.is_a?(String)
        Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), token)
      end

      object.define_field(key, value, token, not_redefining: true)
    else
      Logger.report_error("Attempt to assign to index of", TypeChecker.get_mapped(object.class), token)
    end

    object
  end

  def visit_property_assignment_expr(expr : Expression::PropertyAssignment) : ValueType
    if expr.object.is_a?(Expression::Index)
      index = expr.object.as Expression::Index
      object_node = index.object
      key = evaluate(index.key)
      object = evaluate(object_node)
    else
      access = expr.object.as Expression::Access
      object_node = access.object
      key = access.key.lexeme
      object = evaluate(object_node)
    end

    value = expr.value.is_a?(Expression::Base) ?
      evaluate(expr.value.as Expression::Base)
      : expr.value.as ValueType

    if object_node.is_a?(Expression::Index) || object_node.is_a?(Expression::Access)
      object = add_object_value(expr.token, object, key, value)
      prop_assignment = Expression::PropertyAssignment.new(object_node, object)
      return visit_property_assignment_expr(prop_assignment)
    end

    object = add_object_value(expr.token, object, key, value)
    unless meta["this"]?.nil? || expr.token.lexeme != "$" || !object.is_a?(ClassInstance)
      value
    else
      @scope.assign(expr.token, object)
    end
  end

  def visit_compound_assignment_expr(expr : Expression::CompoundAssignment) : ValueType
    case expr.operator.type
    when Syntax::PlusEqual
      Operator::PlusAssign.new(self).apply(expr)
    when Syntax::MinusEqual
      Operator::MinusAssign.new(self).apply(expr)
    when Syntax::StarEqual
      Operator::MulAssign.new(self).apply(expr)
    when Syntax::SlashEqual
      Operator::DivAssign.new(self).apply(expr)
    when Syntax::PercentEqual
      Operator::ModAssign.new(self).apply(expr)
    when Syntax::CaratEqual
      Operator::PowAssign.new(self).apply(expr)
    when Syntax::AndEqual
      Operator::AndAssign.new(self).apply(expr)
    when Syntax::OrEqual
      Operator::OrAssign.new(self).apply(expr)
    when Syntax::QuestionColonEqual
      Operator::CoalesceAssign.new(self).apply(expr)
    end
  end

  def visit_ternary_op_expr(expr : Expression::TernaryOp) : ValueType
    condition = evaluate(expr.condition)

    return evaluate(expr.then) if condition
    evaluate(expr.else)
  end

  def visit_unary_op_expr(expr : Expression::UnaryOp) : ValueType
    operand = evaluate(expr.operand)
    case expr.operator.type
    when Syntax::Plus
      if operand.is_a?(ClassInstance)
        return Operator.call_meta_method(operand, nil, "unp$", expr.operator.lexeme, expr.operator)
      end
      if operand.is_a?(Float) || operand.is_a?(Int)
        operand.abs
      else
        Logger.report_error("Invalid '+' operand type", operand.class.to_s, expr.operator)
      end
    when Syntax::Minus
      if operand.is_a?(ClassInstance)
        return Operator.call_meta_method(operand, nil, "unm$", expr.operator.lexeme, expr.operator)
      end
      if operand.is_a?(Float) || operand.is_a?(Int) && !operand.is_a?(UInt)
        (-operand).as ValueType
      elsif operand.is_a?(String)
        operand.to_s.reverse
      else
        Logger.report_error("Invalid '-' operand type", operand.class.to_s, expr.operator)
      end
    when Syntax::PlusPlus
      op = Operator::PlusAssign.new(self)
      op.apply(expr, "++")
    when Syntax::MinusMinus
      op = Operator::MinusAssign.new(self)
      op.apply(expr, "--")
    when Syntax::Not
      !operand
    when Syntax::Tilde
      op = Operator::Bnot.new(self)
      op.apply(expr)
    when Syntax::Star
      if operand.is_a?(ClassInstance)
        return Operator.call_meta_method(operand, nil, "splat$", expr.operator.lexeme, expr.operator)
      elsif operand.is_a?(Array)
        Spread.new(operand)
      else
        Logger.report_error("Invalid '*' operand type", TypeChecker.get_mapped(operand.class), expr.operator)
      end
    when Syntax::Hashtag
      if operand.is_a?(ClassInstance)
        return Operator.call_meta_method(operand, nil, "size$", expr.operator.lexeme, expr.operator)
      end
      unless operand.is_a?(Array) || operand.is_a?(Hash) || operand.is_a?(String) || operand.is_a?(Range)
        Logger.report_error("Invalid '#' operand type", TypeChecker.get_mapped(operand.class), expr.operator)
      end
      operand.size
    end
  end

  def visit_binary_op_expr(expr : Expression::BinaryOp) : ValueType
    case expr.operator.type
    when Syntax::Plus
      op = Operator::Plus.new(self)
      op.apply(expr)
    when Syntax::Minus
      op = Operator::Minus.new(self)
      op.apply(expr)
    when Syntax::Star
      op = Operator::Mul.new(self)
      op.apply(expr)
    when Syntax::Slash
      op = Operator::Div.new(self)
      op.apply(expr)
    when Syntax::SlashSlash
      op = Operator::IntDiv.new(self)
      op.apply(expr)
    when Syntax::Carat
      op = Operator::Pow.new(self)
      op.apply(expr)
    when Syntax::Percent
      op = Operator::Mod.new(self)
      op.apply(expr)
    when Syntax::And
      evaluate(expr.left) && evaluate(expr.right)
    when Syntax::Or
      left = evaluate(expr.left)
      return left if left
      evaluate(expr.right)
    when Syntax::QuestionColon
      left = evaluate(expr.left)
      return left unless left.nil?
      evaluate(expr.right)
    when Syntax::EqualEqual
      evaluate(expr.left) == evaluate(expr.right)
    when Syntax::BangEqual
      evaluate(expr.left) != evaluate(expr.right)
    when Syntax::Less
      op = Operator::LT.new(self)
      op.apply(expr)
    when Syntax::LessEqual
      op = Operator::LTE.new(self)
      op.apply(expr)
    when Syntax::Greater
      op = Operator::GT.new(self)
      op.apply(expr)
    when Syntax::GreaterEqual
      op = Operator::GTE.new(self)
      op.apply(expr)
    when Syntax::Tilde
      op = Operator::Bxor.new(self)
      op.apply(expr)
    when Syntax::Pipe
      op = Operator::Bor.new(self)
      op.apply(expr)
    when Syntax::Ampersand
      op = Operator::Band.new(self)
      op.apply(expr)
    when Syntax::RDoubleArrow
      op = Operator::Bshr.new(self)
      op.apply(expr)
    when Syntax::LDoubleArrow
      op = Operator::Bshl.new(self)
      op.apply(expr)
    end
  end

  def visit_range_literal_expr(expr : Expression::RangeLiteral) : RangeType
    from = evaluate(expr.from)
    to = evaluate(expr.to)

    unless from.is_a?(Int)
      Logger.report_error("Invalid left side of range literal", "Ranges can only be of integers, got '#{TypeChecker.get_mapped(from.class)}'", expr.token)
    end
    unless to.is_a?(Int)
      Logger.report_error("Invalid right side of range literal", "Ranges can only be of integers, got '#{TypeChecker.get_mapped(to.class)}'", expr.token)
    end

    (from .. to).as RangeType
  end

  def visit_table_literal_expr(expr : Expression::TableLiteral) : Hash(ValueType, ValueType)
    hash = {} of  ValueType => ValueType
    expr.hashmap.each do |k, v|
      key = evaluate(k)
      value = evaluate(v)
      hash[key] = value
    end
    hash
  end

  def visit_vector_literal_expr(expr : Expression::VectorLiteral) : Array(ValueType)
    expr.values.map { |v| evaluate(v) }
  end

  def visit_string_interpolation_expr(expr : Expression::StringInterpolation) : ValueType
    expr.parts.map do |part|
      if part.is_a?(String)
        part
      else
        part_value = evaluate(part)
        part_value.nil? ? "none" : part_value.to_s
      end
    end.join
  end

  def visit_literal_expr(expr : Expression::Literal) : ValueType
    expr.value
  end

  def visit_single_expr_stmt(stmt : Statement::SingleExpression) : ValueType
    evaluate(stmt.expression)
  end

  def visit_block_stmt(stmt : Statement::Block) : ValueType
    execute_block(stmt, Scope.new(@scope))
  end
end
