enum Cosmo::Syntax
  Identifier
  IntegerLiteral; FloatLiteral; StringLiteral; CharLiteral; BooleanLiteral; NoneLiteral
  IntegerType; FloatType; StringType; CharType; BoolType; NoneType;
  Public; ClassVisibility
  PlusPlus; MinusMinus;
  Plus; PlusEqual; Minus; MinusEqual
  Star; StarEqual; Slash; SlashEqual
  SlashSlash; SlashSlashEqual
  Carat; CaratEqual; Percent; PercentEqual
  Less; LessEqual; Greater; GreaterEqual
  Equal; EqualEqual; BangEqual
  Ampersand; Pipe; Tilde; RDoubleArrow; LDoubleArrow
  Not; And; Or; AndEqual; OrEqual;
  Question; QuestionColon; QuestionColonEqual
  Semicolon
  ColonColon; Colon; Dot; DotDot; HyphenArrow
  FatArrow;
  LBrace; RBrace;
  LBracket; RBracket; LParen; RParen
  Comma
  Hashtag
  Class; Mixin; New; Super
  Enum
  Function
  Try; Catch; Finally
  If; Unless
  Is; In; Of
  Else
  Every
  While; Until
  Mut
  Throw
  Break; Next
  Case; When
  Return
  Use; From; As
  EOF
end
