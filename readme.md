# Makefile-Blog

Makefile-Blog is a static blog website generator written in makefile with various tools. The makefile blog creates index, post index and rss files from the blog posts you wrote.

### Requirements

Makefile-Blog requires following packages for generating static files:

* coreutils - (tr, ls, cut, basename, stat, echo, cat)
* bash
* sed
* gettext - (envsubst)
* make

### Blogging

Running Makefile-Blog first requires you to create posts directory. After creating the posts directory, anything you put under it without an extension is a blog file. Spaces are not used, instead underscores are used which are later replaced.

```sh
$ mkdir posts
$ echo 'Hello World' > posts/My_First_Post
$ make
```

Also, building individual pages is parallelization compatible. So running with ```make -j8``` is possible.

### Configuration
Variables in the makefile can be either manually modified or given through environment such as ```make BLOGNAME='My First Blog'```. Some fields you may want to change as following:
```
BLOGNAME = My First Blog
BLOGDESC = hey
TEMPLATE = default
BLOGROOT = 
# You may set blogroot your domain for non relative urls.
# Also dont put / at the end
```
Any time you change the makefile itself or the configuration through variables, you may need to run ```make clean``` before you make again because makefile itself 
isn't watched for modifications.

### Templating

Do you want a custom template? Great!

Makefile Blog supports custom templates. All you need to do is satisfy files under default template and put your own custom template under templates. Don't forget to change TEMPLATE variable from the makefile. Also setting BLOGROOT to your absolute build directory might be helpful when testing locally.

The template files use environment variables set by makefile during the building process similar to ${TEMPLATE_POST_DATE_UPDATED} or ${TEMPLATE_POST_AUTHOR} to show content. 

### Contributing

Contributions and ideas are welcomed.

### Live Demo

A live demo with default template can be found at [here](https://metin.nextc.org/posts/The_Idea_Of_Makefile_Blog.html).