# Admin Guide

You can find this repository here: [https://felbinger.github.io/AdminGuide](https://felbinger.github.io/AdminGuide)


### Contribute
Feel free to open issues / pull requests.  
Please validate that your changes work, you can start the mkdocs development server by running `mkdocs serve`.

You can install `mkdocs` using pip:
```shell
$ sudo pip3 install mkdocs
Collecting mkdocs
  Downloading mkdocs-1.1.2-py3-none-any.whl (6.4 MB)
     |████████████████████████████████| 6.4 MB 3.4 MB/s 
Collecting Markdown>=3.2.1
  Downloading Markdown-3.3.3-py3-none-any.whl (96 kB)
     |████████████████████████████████| 96 kB 2.6 MB/s 
Collecting lunr[languages]==0.5.8
  Downloading lunr-0.5.8-py2.py3-none-any.whl (2.3 MB)
     |████████████████████████████████| 2.3 MB 3.0 MB/s 
Requirement already satisfied: click>=3.3 in /usr/lib/python3/dist-packages (from mkdocs) (7.0)
Collecting livereload>=2.5.1
  Downloading livereload-2.6.3.tar.gz (25 kB)
Collecting tornado>=5.0
  Downloading tornado-6.1-cp38-cp38-manylinux2010_x86_64.whl (427 kB)
     |████████████████████████████████| 427 kB 3.7 MB/s 
Requirement already satisfied: PyYAML>=3.10 in /usr/lib/python3/dist-packages (from mkdocs) (5.3.1)
Collecting Jinja2>=2.10.1
  Downloading Jinja2-2.11.3-py2.py3-none-any.whl (125 kB)
     |████████████████████████████████| 125 kB 3.0 MB/s 
Collecting future>=0.16.0
  Downloading future-0.18.2.tar.gz (829 kB)
     |████████████████████████████████| 829 kB 3.0 MB/s 
Requirement already satisfied: six>=1.11.0 in /usr/lib/python3/dist-packages (from lunr[languages]==0.5.8->mkdocs) (1.14.0)
Collecting nltk>=3.2.5; python_version > "2.7" and extra == "languages"
  Downloading nltk-3.5.zip (1.4 MB)
     |████████████████████████████████| 1.4 MB 3.1 MB/s 
Requirement already satisfied: MarkupSafe>=0.23 in /usr/lib/python3/dist-packages (from Jinja2>=2.10.1->mkdocs) (1.1.0)
Collecting joblib
  Downloading joblib-1.0.0-py3-none-any.whl (302 kB)
     |████████████████████████████████| 302 kB 3.0 MB/s 
Collecting regex
  Downloading regex-2020.11.13-cp38-cp38-manylinux2014_x86_64.whl (738 kB)
     |████████████████████████████████| 738 kB 2.8 MB/s 
Collecting tqdm
  Downloading tqdm-4.56.0-py2.py3-none-any.whl (72 kB)
     |████████████████████████████████| 72 kB 738 kB/s 
Building wheels for collected packages: livereload, future, nltk
  Building wheel for livereload (setup.py) ... done
  Created wheel for livereload: filename=livereload-2.6.3-py2.py3-none-any.whl size=24713 sha256=c835f9b84cbb857fd16b0b47f8ebe65f64ea64e8c809979409545cc359947140
  Stored in directory: /root/.cache/pip/wheels/48/d7/34/372e0521bd5c9f6dcdff307e37ef6f9c00c1e1e2afc9707b5c
  Building wheel for future (setup.py) ... done
  Created wheel for future: filename=future-0.18.2-py3-none-any.whl size=491058 sha256=4f676273bcf19ec6dabcc892d8366c3277aed849e80297e75f9d53dd6336d8de
  Stored in directory: /root/.cache/pip/wheels/8e/70/28/3d6ccd6e315f65f245da085482a2e1c7d14b90b30f239e2cf4
  Building wheel for nltk (setup.py) ... done
  Created wheel for nltk: filename=nltk-3.5-py3-none-any.whl size=1434676 sha256=ad9dfd1565a60cf63f9f2774e87a0bbf838a14a03cbad80d666e9d4eaae14b8f
  Stored in directory: /root/.cache/pip/wheels/ff/d5/7b/f1fb4e1e1603b2f01c2424dd60fbcc50c12ef918bafc44b155
Successfully built livereload future nltk
Installing collected packages: Markdown, future, joblib, regex, tqdm, nltk, lunr, tornado, livereload, Jinja2, mkdocs
  Attempting uninstall: Markdown
    Found existing installation: Markdown 3.1.1
    Not uninstalling markdown at /usr/lib/python3/dist-packages, outside environment /usr
    Can't uninstall 'Markdown'. No files were found to uninstall.
Successfully installed Jinja2-2.11.3 Markdown-3.3.3 future-0.18.2 joblib-1.0.0 livereload-2.6.3 lunr-0.5.8 mkdocs-1.1.2 nltk-3.5 regex-2020.11.13 tornado-6.1 tqdm-4.56.0
```
