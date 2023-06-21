---
description: This page will cover (for the most part) how to add your own grammars.
---

# 📝 Grammar



Warning: Creating new grammar for Cosmo is a process.

1. Check the [current syntax types](https://cosmo-lang.github.io/cosmo/Cosmo/Syntax.html) to make sure any tokens you want to include in your grammar are already being lexed.
   * If a token you want to include in your grammar is not in the list of syntax types, you will need to create your own syntax type and lex it. Lexing a syntax is straightforward, and you should be able to figure it out without a tutorial.
2. Figure out what your expression/statement should be represented as. Are you adding an operator? Then you can just match your syntax in a binary operator parsing method (like `parse_additive`, including `parse_var_declaration` as well as `parse_assignment`) or if it's unary, the `parse_unary` method. **Otherwise**:
   * Create an AST node and a parser method. Naming is straightforward, your AST node should be named what it represents. The parsing method should be named `parse_(node_name)`. For example if you added an `if` statement, the node's file would be called `if.cr`, the node's class would be called `If`, and the parsing method would be called `parse_if_statement`. Don't forget to include the `visit_nodename_expr`/`visit_nodename_stmt` method in `Expression`/`Statement`'s `Visitor` abstract class. In the case of the `if` statement, it would be called `visit_if_stmt`.
3. Implement the `visit_nodename_expr`/`visit_nodename_stmt` method into the interpreter, and perform all necessary actions for your grammar.
4. Implement the `visit_nodename_expr`/`visit_nodename_stmt` into the resolver, and resolve any nodes associated with your new node.
