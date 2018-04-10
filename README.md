# Radiquotes

Twitter app/bot for Aufhebung.
Posts pictures of quotes from radical authors.

## Process
 *quotes.orig* 	stores pre-formatted quote list  
 *quotes* 	stores formatted quote list via *format.vim*  
 *format.vim* 	vim script for formatting quote list  
 *tweet.sh* 	tweeter  
 *render.sh* 	renderer  
 *situation.sh*  quote image creator  
 
 1. `make quotes` turns *quotes.orig* into *quotes* with `format.vim`
 2. `./render.sh` use *quotes* to make quote images in *./Renders/* with `situation.sh`
 2. `./tweet.sh ./Renders/*` tweets random file from *./Renders/*
 
 Name format for rendered quote images: 	`{author}-{6 words}.png`  
 Example: `Karl_Marx-La_société_est_sauvée_aussi_souvent.png`  
 
 `quotes.orig` 	-> `quotes` 	-> `{render dir}/{author}-{6 words}.png`

## Format of *quotes.orig*
 Do not use double quotes (") in this file.  
 Must be formatted as follows:  
	# {comments}
	{text1}
	--- {author1}, {book1} [...]
	{text2}
	--- {author2}, {book2} [...]
	[...]

## Format of *quotes*
 Two `@`-separated fields, 1st is quote, 2nd is source.  
 Must be formatted as follows:  

	{text1}@{author1}, {book1} [...]
	{text2}@{author2}, {book2} [...]

## Authors
 Collectif Aufhebung: <http://aufhebung.fr>  
 Written by Sylvain Saubier (<http://SystemicResponse.com>)  
 Report bugs at: <feedback@sylsau.com>  
