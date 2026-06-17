# Templating - spaces

## Explanation 

  * {{- -> trim on left side / INCLUDING new lines 
  * -}} -> trim on right side / ALSO: new lines 
  * trim tabs, whitespaces a.s.o. (see ref)

## Walkthrough 

```
cd
mkdir -p helm-exercises
cd helm-exercises
```

```
# When ever we encounter error while parsing yaml, we can use comment !!!
helm create testenv
cd testenv/templates
rm -fR *.yaml
rm -fR tests
```

```
nano test.yaml
```

```
# "{{23 -}} < {{- 45}}"
```

```
helm template .. 
helm template --debug ..
```

```
# now with new lines
nano test2.yaml
```

```
# {{23 -}}
newline here
```

```
helm template ..
helm template --debug ..
```


## Reference:

  * https://pkg.go.dev/text/template#hdr-Text_and_spaces
