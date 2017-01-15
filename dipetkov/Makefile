
.PHONY: clean

all: analyze

gather:
	@echo Gather data:
	@echo I signed up and downloaded the data from:
	@echo http://www.drivendata.org/competitions/7/
	@echo The files are in the \"data\" directory:
	@echo `ls data`

process:
	@echo Process data
	Rscript -e "knitr::spin('read-data.R')"
	Rscript -e "knitr::spin('transform-data.R')"

analyze:
	@echo Analyze data 
	Rscript -e "knitr::spin('predict-data.R')"

clean:
	@echo Clean all
	rm -f *.md *.html
