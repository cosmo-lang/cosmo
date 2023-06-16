---
description: This page will cover (for the most part) how to add your own grammars.
---

# 📝 Grammar



Warning: Creating new grammar for Cosmo is a process.

1. Check the [current syntax types](https://cosmo-lang.github.io/cosmo/Cosmo/Syntax.html) to make sure any characters you want to include in your grammar are already being lexed.

* If a character you want to include in your grammar is not in the list of syntax types, you will need to create your own syntax type and lex it. Lexing a syntax is straightforward, and you should be able to figure it out without a tutorial.

2. Create an AST node and a method inside of the parser to create the node. Don't forget to include the `visit_nodename_expr`/`visit_nodename_stmt` method in `Expression`/`Statement`'s `Visitor` abstract class.
3. Implement the `visit_nodename_expr`/`visit_nodename_stmt` method into the interpreter, and perform all necessary actions for your grammar.
4. Implement the `visit_nodename_expr`/`visit_nodename_stmt` into the resolver, and resolve any nodes associated with your new node.
