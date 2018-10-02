+++
title = "Cifratura file con openssl"
date = 2007-12-08
draft = false
tags = ["ssl", "openssl"]
+++
##### cifratura:
```bash
openssl bf -in chiaro.txt -out cifrato.txt
```
##### decifratura:
```bash
openssl bf -d -in cifrato.txt -out chiaro.txt
```