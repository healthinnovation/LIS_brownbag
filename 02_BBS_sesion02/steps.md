
[Presentación](https://docs.google.com/presentation/d/13xTFwS2JkUhteIdoyCSytGA1Dx_6oSwlxUsaakSx29c/edit?usp=sharing)

```bash
mkdir bbs_IIS
cd bbs_IIS
mkdir test
touch test.txt
touch test/otrofile.txt
ls -la
```

## Empezamos con Git

``` bash
git init 
git status 
git add .
git commit -m "primer commit" 
git status
```
Exploremos el folder "git"

```bash
ls -la
ls .git #**todo se guarda aquí!**
```

```bash
echo nuevalinea >> test.txt
git status 
git add . 
git commit -m "second commit"
```

```bash
cat test.txt
git checkout [tab]
cat test.txt
git checkout master
```

```bash
git checkout -b jugando
echo otralinea >> text.txt
git add .
git commit -m "jugando primer commit"
git checkout master
cat test.txt
git merge jugando
cat test.txt
```

### Integracion Github

**Crear repo en github** 

```
git remote add origin https://github.com/jincio/test1.git
git branch -M main
git push 
```

### Paquete en R

```r 
#librerias: 
library(usethis)
library(devtools)
library(roxygen2)
#devtools::install_github("klutometis/roxygen")
```

```r
# Crea paquete y abre nuevo proyecto en Rstudio
create("miprimerPR")
usethis::use_r("funcion1") #creas nuevo script para funciones
devtools::document()
devtools::load_all()
use_mit_license()
devtools::check()
```

```
## Publicar
usethis::use_git()
usethis::browse_github_pat()
## Genera token

usethis::use_github(protocol="https",
                    auth_token = "xxxx")
usethis::use_readme_rmd()
```
