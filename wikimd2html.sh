for file in *.md; do ~/.cabal/bin/pandoc title.md -s --mathjax -o title.md.html; done
rename 's/\.md//' *.md.html 
git push --force origin gh-pages 
