---
description: >-
  Modules are used to separate Cosmo code into separate files and import them
  from another file.
---

# 🧱 Modules

{% hint style="danger" %}
Warning: There's currently a bug that makes it so that you cannot use types imported from other files. This includes classes. Sorry, this will be fixed soon hopefully.
{% endhint %}

Cosmo's module system is similar to TypeScript. Here is an example of how you might import a file in the same directory:

```sql
use member from "./mod_name"
```

You can import any intrinsics or Stars packages by just omitting the `./` and writing the name of the package/intrinsic.

