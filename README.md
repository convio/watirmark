watirmark
=========

An MVC test framework for watir-webdriver. 

[![Build Status](https://secure.travis-ci.org/convio/watirmark.png)](http://travis-ci.org/convio/watirmark)

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/convio/watirmark)

Getting Started
---

Starting with watirmark is easy. We've taken advantage of code generators to give you a head start and create most of the scaffolding that we've found useful in developing tests against our own websites.

```bash
# example
gem install watirmark
watirmark my_test_project
```

Running the 'watirmark' command will create a small project in the current directory named `my_test_project`. Take a look at the files created. Sample cucumber test in /features shows how you can navigate to the home page of your project app.

```bash
# example
cd my_test_project
script/generate.rb mvc search homepage
```
On the command line change dir to your newly created project and run `script/generate.rb mvc` and provide your workflow name `search` and mvc basename for model view and controller files, in this example `homepage`. Take a look at the files generated in your project workflows directory. Type `script/generate.rb help` for more information.

```bash
#example
script/generate.rb mvc search/parts/widgets bigwidget
```

The above example creates lib/workflows/search/parts/widgets directory and mvc files.


Documentation
---

Home Page: <a href="http://convio.github.com/watirmark/">http://convio.github.com/watirmark/</a>

Wiki: <a href="https://github.com/convio/watirmark/wiki">https://github.com/convio/watirmark/wiki</a>


Copyright
---
Copyright (c) 2012-2013 Hugh McGowan and Bret Pettichord. See LICENSE for details.



