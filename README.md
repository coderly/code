Code: The Coderly Toolbelt
==================

code is a command line tool that automates the Coderly workflow.

hub is best aliased as `c`, so you can type `$ c <command>` in the shell.


Installation
------------

Dependencies:

* **git 1.7.3** or newer
* **Ruby 2.0** or newer

Clone the repository to a directory of your choice and run bundle install
~~~ sh
$ git clone git@github.com:coderly/code.git
$ cd code
$ bundle install
~~~

Add the bin directory to the load paths by opening your `.bash_profile` and ensuring you havethe following
~~~ sh
PATH=$PATH:$HOME/path-to-git-repo/code/bin
export PATH #Add this if it doesn't already exist
~~~

New Feature Workflow
------------
1. Create a new feature branch
~~~ sh
$ code start name of my feature
~~~
or equivalently
~~~ sh
$ code start name-of-my-feature
~~~

2. When you are ready, publish your code in a pull request
~~~ sh
$ code publish my pull request message
~~~
Your pull request will be opened up in the browser

3. Ask someone to review your code by referencing them in a comment in the pull request

4. When someone gives you a :thumbsup: you can merge it from the pull request page. 
    * Make sure that the tests are passing.
    * If the code can't be automatically merged, merge development onto your branch and resolve the conflicts.
5. After the code has been merged get back to development and delete your branch
~~~ sh
$ code finish
~~~
