---
description: >-
  This page will cover how you can contribute new intrinsic libraries or globals
  to Cosmo.
---

# Intrinsics

First, let me define what I mean when I say "intrinsic". I am referring to anything that is available to Cosmo without having to install a package. For example: the `puts` and `gets` functions are global intrinsics, and the `HTTP` and `System` libraries are imported intrinsics.

## Written in Cosmo

If you want to write any code in Cosmo that will be intrinsic to Cosmo, just create a new Cosmo file in [`libraries/`](https://github.com/cosmo-lang/cosmo/tree/master/libraries) and code away. Each file in `libraries/` becomes an importable, except for `global.⭐`, which is injected into the global scope. When sqcreating an importable intrinsic in Cosmo, the name to import will be the file name without the extension. For example: if I created `libraries/colors.⭐`, it would be importable via `colors`.

```sql
use * from "colors"
```

## Written in Crystal

If you want to define Cosmo intrinsics that rely on Crystal to run (or are performance intensive), you can refer to [`src/cosmo/runtime/intrinsic`](https://github.com/cosmo-lang/cosmo/tree/master/src/cosmo/runtime/intrinsic). There are two types of intrinsics you can create via Cosmo's Crystal API: [`Lib`](https://cosmo-lang.github.io/cosmo/Cosmo/Intrinsic/Lib.html)s, and [`IFunction`](https://cosmo-lang.github.io/cosmo/Cosmo/Intrinsic/IFunction.html)s.

### Intrinsic::Lib

A `Lib` is just a table behind the scenes, and holds associated `IFunction`s or other values. It contains an `inject` method which assigns any associated values into the scope.\


<figure><img src="https://user-images.githubusercontent.com/49625808/245357242-9b5eda88-c93f-49bc-9d84-31bee4527241.png" alt=""><figcaption><p>The <a href="https://github.com/cosmo-lang/cosmo/blob/master/src/cosmo/runtime/intrinsic/lib/file.cr"><code>FileLib#inject</code></a> method</p></figcaption></figure>

As you can see, it defines a hash called `file` and assigns all of the `File` library's functions into it. It then assigns the `file` hash to the name `File` in the scope.

### Intrinsic::IFunction

An `IFunction` is just a regular function, just without a body node. They are called like normal functions, besides having to interpret the function body. Arity checks are done just like normal functions as well. The below example of an `IFunction` (taken from `Math::atan`) has an arity of 1, meaning that it will throw if any more or any less arguments are provided. It also uses the [`TypeChecker#assert`](https://cosmo-lang.github.io/cosmo/Cosmo/TypeChecker.html#assert%28typedef%3AString%2Cvalue%3AValueType%2Ctoken%3AToken%29%3ANil-instance-method) method to make sure the input is a float or an integer.&#x20;

<figure><img src="https://user-images.githubusercontent.com/49625808/245358559-c8a18f65-8eb2-4658-ad15-847ce6e82417.png" alt=""><figcaption></figcaption></figure>
