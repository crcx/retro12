# User Interface

Welcome to RETRO, a Forth programming language and development environment.

The core interface has two panes. On the left (where you are reading this) is the editor. It's here that you'll write your code and documentation. The editor supports a subset of Markdown, including things like *italics* and **bold** and headers.

The language will ignore anything outside of a code block. These start and end with four backticks. For instance:

````
'Hello,_world! puts nl
````

The editor provides a quick access toolbar at the bottom of the screen. This provides one touch access to the fencing characters and various symbols used heavily in RETRO code.

On the right is the output and tools pane. This is where the results of running code are shown. It also contains two other areas.

Above the output is a toolbar. This has icons for (from left to right):

* Undo
* Redo
* File Manager
* Share
* Output
* Clear Output
* Run Program

Below the output is a single line for input and a button labeled **Eval**. The **Eval** button will run the code you enter in the area next to it. RETRO calls this the Listener. It's useful for quick tests and debugging.

The file manager will show a list of all files you have created. It also has two buttons. The first, **restore samples**, will restore any example files or documentation files you have deleted. The second, **+**, lets you create a new file. You can load a file into the editor by tapping on it. Deleting a file is done by swiping towards the left.

And that's the RETRO interface in a nutshell.