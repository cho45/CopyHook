CopyHook
========

An application for manipulating pasteboard.


Usage
-----

Create ~/.copyhook.js file like following:

    function onCopied() {
        console.log(pb.types);
        pb.copy(pb.string().replace(/^\s*|\s*$/g, ""));
    }


The function `onCopied` is called on copied.

Reference
---------

### `pasteboard` object (`pb` for shorthand)

#### `pasteboard.copy(str: String)`

Set `str` to pasteboard as type "public.utf8-plain-text".

#### `pasteboard.string() #=> String`

Get string from pasteboard by type "public.utf8-plain-text".

#### `pasteboard.stringByType(type: String) #=> String`

Get string by `type`.

#### `pasteboard.setStringForType(str: String, type: String)`

Set `str` for `type`.


### `pasteboard.dataByType(type: String) #=> String`

Get base64 encoded string by `type`

### `pasteboard.setDataForType(base64: String, type: String`

Set data by base64 encoded string `base64` for `type`.

#### `pasteboard.clearContents()`

Clear current pasteboard contents. You should call this before setting.

#### `pasteboard.types()`

Returnes current pasteboard types. 

See Also: https://developer.apple.com/library/mac/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

### `console` object

#### `console.log(str: String)`

Print `str` to system log.

### `require(path: String)` function

Load JavaScript file from `~/.copyhook/`.

### `utils` object

#### `utils.focusedApplicationBundleId() #=> String`

Returns bundle id of current focused application.

#### `utils.focusedWindowName() #=> String`

Returns title of focused window.

#### `utils.system(program: String, stdin: String) #=> String`

Execute external program by /bin/sh with supplied `stdin` as standard input for its process and returns standard out of executed external program.
